---
title: Seguridad y resiliencia
---

# Seguridad y resiliencia

No traté seguridad como una capa que se agrega al final. La propuesta ya deja algunas decisiones implementadas y otras explícitamente pendientes antes de un despliegue real.

## Seguridad de entrada

Para desarrollo local los servicios están expuestos por puertos de Docker Compose. Eso facilita la prueba, pero no representa la postura final.

En GCP, Endorsement y Routing están definidos como servicios no anónimos. La intención es colocar un API Gateway delante de ellos y validar JWT en el punto de entrada.

```text
Cliente
   |
   v
API Gateway
   |
   +---- validar identidad/token
   +---- aplicar políticas de entrada
   |
   v
Cloud Run privado
```

No activé todavía esa pieza porque prefiero cerrar primero el contrato de autenticación y la forma en que el frontend obtendrá y propagará credenciales.

## Secretos

La contraseña de PostgreSQL se administra mediante Secret Manager en la infraestructura objetivo.

No se guarda en:

- código fuente;
- imagen Docker;
- variables hardcodeadas en la aplicación.

En local se utilizan credenciales simples únicamente para el entorno Docker aislado del reto.

## Identidades de servicio

Cada servicio Cloud Run puede ejecutar con su propia service account. Endorsement necesita acceso a Cloud SQL y al secreto de base de datos; Routing no necesita esos permisos.

La idea es mantener permisos por responsabilidad y evitar una identidad común con privilegios innecesarios.

## Validación de entrada

Endorsement valida el contrato recibido antes de ejecutar el caso de uso. Routing valida el grafo y rechaza pesos negativos.

Esto no reemplaza controles perimetrales, pero evita que datos inválidos lleguen a la lógica central.

## CORS

El servicio Hapi actualmente tiene CORS habilitado para facilitar el ejercicio local. En un entorno real lo restringiría a los orígenes esperados y no lo dejaría abierto de forma general.

## Errores

Los errores funcionales se distinguen de los errores técnicos.

Ejemplos:

- plantilla no encontrada: `404`;
- ruta no alcanzable: `422`;
- validación de request: `4xx`;
- falla no controlada: `5xx`.

Evito devolver detalles internos de infraestructura al cliente.

## Resiliencia

Para los servicios implementados, la primera medida es mantenerlos stateless y poder escalar horizontalmente.

En el ejercicio de préstamos la resiliencia necesita un tratamiento adicional porque existe una dependencia lenta y con impacto financiero. Ahí la propuesta incorpora:

- idempotencia;
- outbox transaccional;
- procesamiento asíncrono;
- reintentos con backoff;
- DLQ;
- control de concurrencia;
- consulta de estado de operación.

## Timeouts y reintentos

No considero correcto solucionar una integración lenta únicamente aumentando timeouts. Un timeout debe tener un valor acotado y los reintentos deben ocurrir en el componente que conoce el estado de la operación.

En el caso de préstamos, ese componente es el worker. El navegador no debe decidir cuándo volver a ejecutar un desembolso.

## Observabilidad mínima que llevaría a producción

La base que considero necesaria sería:

```text
traceId
operationId / correlationId
servicio
endpoint / caso de uso
duración
resultado
código de error
```

Además, para préstamos mediría:

- operaciones aceptadas;
- completadas;
- fallidas;
- reintentos por operación;
- mensajes en DLQ;
- latencia de INARI;
- tiempo total de procesamiento.

No agregué una plataforma completa de observabilidad al reto porque no era necesaria para demostrar el problema, pero sí dejo claro qué señales operativas necesitaría antes de producción.