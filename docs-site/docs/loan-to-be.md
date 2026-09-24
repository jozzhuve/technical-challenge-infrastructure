---
title: Ejercicio 3 - Préstamos TO-BE
---

# Ejercicio 3 - Préstamos TO-BE

## Problema del AS-IS

El problema principal del flujo actual no es solamente el timeout. El punto crítico es que la respuesta HTTP no necesariamente representa el estado real del desembolso.

INARI puede continuar procesando una operación aunque el cliente haya recibido un `502`. Si el usuario interpreta esa respuesta como un fallo definitivo y vuelve a enviar la solicitud, puede generarse una segunda intención de desembolso.

```text
Cliente
  |
  | solicitud
  v
Backend
  |
  | llamada síncrona
  v
INARI
  |
  | continúa procesando
  v
Desembolso

El cliente puede haber recibido 502 antes de conocer este resultado.
```

Aumentar el timeout reduce la frecuencia del síntoma, pero no resuelve la ambigüedad sobre el resultado de negocio. La solución debe desacoplar la aceptación de la solicitud del tiempo que necesita INARI para procesarla.

## Arquitectura TO-BE

La propuesta introduce una operación con identidad propia, idempotencia persistida, procesamiento asíncrono y consulta de estado.

Los componentes principales son:

- Apache APISIX como único punto de entrada;
- Loan API para validar y registrar la operación;
- Cloud SQL como persistencia transaccional;
- tabla `outbox_event` para publicación confiable;
- publicador del outbox;
- Pub/Sub para desacoplar el procesamiento;
- Loan Processor Worker;
- INARI / ADMWR como sistema externo de desembolso.

La operación y el evento del outbox se guardan en la misma base de datos y dentro de la misma transacción. El publicador del outbox toma posteriormente los eventos pendientes y los envía a Pub/Sub.

## Flujo de la solución

Los números corresponden al diagrama de arquitectura.

| Paso | Interacción | Descripción |
| ---: | --- | --- |
| **1** | Usuario con APISIX | El usuario consume la solución mediante operaciones `POST` o `GET`. Todo el tráfico ingresa por APISIX como único punto de entrada. |
| **2** | APISIX con Loan API | APISIX valida el JWT, aplica las políticas de tráfico, genera o propaga el identificador de correlación y enruta la solicitud hacia Loan API. |
| **3** | Loan API con Cloud SQL | Loan API valida la solicitud y controla la idempotencia. Para una nueva operación registra `loan_operation` y `outbox_event` en la misma transacción. Para una consulta obtiene el estado asociado al `operationId`. |
| **4** | Cloud SQL / Outbox con Pub/Sub | El publicador del outbox obtiene los eventos pendientes y los publica en Pub/Sub. Esto desacopla la aceptación de la solicitud del procesamiento efectivo del desembolso. |
| **5** | Pub/Sub con Loan Processor Worker | Pub/Sub entrega el evento al Worker para continuar el procesamiento de manera asíncrona, sin mantener bloqueada la solicitud original del usuario. |
| **6** | Loan Processor Worker con INARI / ADMWR | El Worker invoca el sistema de desembolso manteniendo la correlación con la operación original. |
| **7** | Loan Processor Worker con Pub/Sub | Si el procesamiento falla, el mensaje no se confirma y Pub/Sub aplica la política de reintentos configurada. El reintento trabaja siempre sobre la misma operación. |
| **8** | Loan Processor Worker con Cloud SQL | El Worker actualiza el estado intermedio o final de la operación para que pueda consultarse posteriormente mediante el mismo `operationId`. |

El flujo evita que un timeout o un error de comunicación signifique volver a ejecutar un desembolso. La operación se identifica de forma única, continúa procesándose de manera asíncrona y su estado puede consultarse posteriormente.

## Creación de una operación

La creación utiliza una `Idempotency-Key` que representa la intención de negocio.

```text
POST /loans
Authorization: Bearer <JWT>
Idempotency-Key: <valor-unico>
```

Loan API valida la solicitud y registra en Cloud SQL, dentro de una sola transacción:

```text
loan_operation
idempotency
outbox_event
```

Si la operación es aceptada, la API responde sin esperar a INARI:

```text
HTTP 202 Accepted
operationId
```

El `operationId` se convierte en el identificador de seguimiento de la solicitud.

## Idempotencia

La `Idempotency-Key` debe persistirse con una restricción única.

Si llega nuevamente la misma clave, Loan API busca la operación existente y devuelve el mismo contexto en lugar de crear una segunda intención de desembolso.

La validación no debe depender únicamente de memoria porque debe mantenerse frente a concurrencia, reinicios y múltiples instancias del servicio.

## Outbox transaccional

La operación y el evento se registran en la misma transacción:

```text
BEGIN
  INSERT loan_operation
  INSERT outbox_event
COMMIT
```

El publicador del outbox procesa posteriormente los registros pendientes y los publica en Pub/Sub.

Con esto se evita que la operación quede confirmada sin un evento asociado o que se publique un evento cuya operación no fue persistida correctamente.

## Procesamiento asíncrono

Pub/Sub entrega el evento al Loan Processor Worker. El Worker cambia el estado de la operación, invoca INARI / ADMWR y persiste el resultado.

Estados considerados:

```text
PENDING
PROCESSING
COMPLETED
FAILED
```

No agregaría estados adicionales hasta que exista una necesidad operacional concreta.

## Consulta de estado

La consulta también ingresa por APISIX. No existe acceso directo del cliente hacia Loan API.

```text
GET /loans/{operationId}
Authorization: Bearer <JWT>
```

Loan API consulta Cloud SQL y devuelve el estado actual de la operación. De esta manera la experiencia del usuario deja de depender de mantener una conexión HTTP abierta mientras INARI procesa el desembolso.

## Reintentos y DLQ

Los reintentos técnicos no pertenecen al navegador.

Ante un error del Worker, el mensaje no se confirma y Pub/Sub aplica la política de retry y backoff configurada. Si se supera el número máximo de entregas, el mensaje debe enviarse a una Dead Letter Queue o Dead Letter Topic para tratamiento controlado.

El reintento siempre conserva el mismo `operationId`; no representa una nueva solicitud de desembolso.

## Concurrencia

Las barreras contra duplicados quedan en varios niveles:

1. `Idempotency-Key` recibida desde el cliente.
2. Restricción única en Cloud SQL.
3. Estado actual de la operación antes de ejecutar el desembolso.
4. Consumidor idempotente en el Worker.
5. Correlación del intento enviado a INARI.

Si INARI soporta una clave idempotente propia, la propagaría de extremo a extremo. Si no la soporta, mantendría el control en nuestra capa y registraría el identificador de la llamada externa para conciliación.

## Seguridad y operación

Para este flujo considero como mínimo:

- autenticación mediante el gateway;
- autorización por operación;
- cifrado en tránsito;
- secretos fuera del código;
- logs sin datos sensibles;
- `traceId`, `correlationId` y `operationId` en la cadena;
- métricas de procesamiento, reintentos, fallos y DLQ;
- auditoría de cambios de estado.

INARI / ADMWR se representa fuera del boundary de GCP porque forma parte de la plataforma existente y la solución propuesta se integra con él, no lo reemplaza.

## Resultado del rediseño

La mejora principal no consiste en hacer que INARI responda más rápido. El cambio es que una latencia o un error de transporte deja de determinar si debe existir una nueva intención de desembolso.

La operación de negocio pasa a tener identidad, estado, idempotencia y control de reintentos propios. Esto elimina la dependencia directa entre la experiencia del usuario y el tiempo de procesamiento de INARI.