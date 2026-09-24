---
title: Ejercicio 3 - Préstamos TO-BE
---

# Ejercicio 3 - Préstamos TO-BE

## Problema del AS-IS

El punto crítico que veo en el flujo actual es que la respuesta HTTP no representa necesariamente el estado real del desembolso.

El cliente llama de forma síncrona. INARI puede tardar lo suficiente como para que un proxy responda `502`, aunque el procesamiento interno continúe y termine desembolsando correctamente. Desde el punto de vista del cliente la operación falló, por lo que un reintento puede generar una segunda intención de desembolso.

```text
Cliente
  |
  | solicitud 1
  v
Backend --------> INARI
  |                 |
  | 502             | sigue procesando
  v                 v
Cliente          desembolso OK
  |
  | reintento
  v
Backend --------> INARI
                    |
                    v
              segundo desembolso
```

Aumentar el timeout puede reducir la frecuencia del síntoma, pero no elimina el problema de fondo. Sigue existiendo una ventana en la que el cliente no conoce el resultado real y puede reintentar.

## Propuesta

La operación debe tener una identidad propia e independiente de cada intento HTTP.

```text
Cliente
  |
  | POST solicitud + Idempotency-Key
  v
Loan API
  |
  | transacción
  +----> operación
  +----> estado
  +----> outbox
  |
  +----> 202 Accepted + operationId
              |
              v
            Broker
              |
              v
            Worker
              |
              v
            INARI
```

El cliente recibe que la operación fue aceptada y deja de depender del tiempo que tarde INARI.

## Idempotencia

La `Idempotency-Key` identifica la intención de negocio. Debe persistirse con una restricción única.

Si el mismo cliente reenvía la solicitud con la misma clave:

```text
misma Idempotency-Key
        |
        v
buscar operación existente
        |
        +--> existe: devolver misma operación
        |
        +--> no existe: crear operación
```

No se crea una nueva intención de desembolso simplemente porque hubo un timeout, un refresh o un doble click.

La restricción única en base de datos es importante porque la verificación únicamente en memoria no protege frente a concurrencia ni frente a múltiples instancias del servicio.

## Outbox transaccional

No separaría la persistencia de la operación y la publicación del evento en dos acciones independientes.

La operación y el registro del outbox deben guardarse en la misma transacción:

```text
BEGIN
  INSERT loan_operation
  INSERT outbox_event
COMMIT
```

Luego un publicador toma los eventos pendientes y los envía al broker.

Esto evita dos estados peligrosos:

- operación persistida pero evento nunca publicado;
- evento publicado pero operación no confirmada en base de datos.

## Estados

Propongo un conjunto pequeño de estados:

```text
PENDING
PROCESSING
COMPLETED
FAILED
```

No agregaría más estados hasta que exista una necesidad operacional concreta.

## Consulta de estado

El cliente puede consultar:

```text
GET /api/v1/loan-operations/{operationId}
```

La UX puede mostrar que la solicitud está en proceso y actualizar el resultado sin mantener una conexión HTTP esperando a INARI.

## Reintentos técnicos

Los reintentos contra INARI pertenecen al worker, no al navegador.

Deben ser acotados y considerar backoff. Una operación que supera el máximo de reintentos debe pasar a `FAILED` o a una DLQ para tratamiento controlado.

El reintento técnico siempre trabaja sobre la misma operación. No debe generar una nueva.

## Concurrencia

Las barreras contra duplicados quedan en más de un nivel:

1. `Idempotency-Key` recibida desde el cliente.
2. Restricción única en persistencia.
3. Estado de la operación antes de ejecutar el desembolso.
4. Consumidor idempotente en el worker.
5. Correlación del intento enviado a INARI.

Si INARI soportara una clave idempotente propia, la propagaría de extremo a extremo. Si no la soporta, mantendría el control en nuestra capa y registraría el identificador de la llamada externa para conciliación.

## Seguridad y operación

Para este flujo consideraría como mínimo:

- autenticación del cliente;
- autorización por operación;
- cifrado en tránsito;
- secretos administrados fuera del código;
- logs sin datos sensibles;
- `traceId` y `operationId` en toda la cadena;
- métricas de tiempo de procesamiento, reintentos, fallos y DLQ;
- auditoría de cambios de estado.

## Resultado del rediseño

La mejora principal no es que INARI responda más rápido. El cambio importante es que una latencia o un error de transporte dejan de definir si existe una nueva intención de desembolso.

La operación de negocio pasa a tener identidad, estado y control de reintentos propios. Con eso se elimina la dependencia directa entre la experiencia del usuario y el tiempo de procesamiento de INARI.