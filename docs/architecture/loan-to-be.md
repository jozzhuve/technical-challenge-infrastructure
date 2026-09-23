# Préstamos de renta particular - propuesta TO BE

## Problema

El flujo actual confunde un timeout de transporte con un fallo de negocio. Un 502 puede llegar al cliente mientras el backend continúa procesando y termina desembolsando. El reintento manual del usuario puede generar desembolsos duplicados.

## Propuesta

```text
Cliente
  |
  v
API Gateway
  |
  v
Loan API ---- Idempotency Store
  |
  +---- Transaction DB
  |        |
  |        +---- Loan Operation
  |        +---- Outbox
  |
  v
202 Accepted + operationId

Outbox -> Broker -> Loan Worker -> INARI
                         |
                         +-> retry controlado
                         +-> DLQ
                         +-> actualización de estado

Cliente -> GET /loans/{operationId}
          PENDING | PROCESSING | COMPLETED | FAILED
```

## Decisiones principales

1. **Idempotencia:** cada intención de desembolso debe tener una clave idempotente única. Repetir la misma solicitud devuelve la operación existente y no crea un segundo desembolso.
2. **Desacoplamiento:** el cliente no permanece esperando la respuesta de INARI. La creación de la operación responde `202 Accepted` con un `operationId`.
3. **Transactional Outbox:** la operación y el evento pendiente de publicación se guardan en la misma transacción para evitar inconsistencias entre base de datos y broker.
4. **Reintentos:** el worker puede reintentar fallos transitorios, pero siempre sobre la misma operación idempotente.
5. **Control de concurrencia:** restricción única por clave idempotente y actualización optimista/pesimista según el punto crítico del desembolso.
6. **DLQ:** los errores no recuperables se aíslan para revisión operativa sin bloquear el procesamiento normal.
7. **Observabilidad:** `operationId`, `policyNumber` anonimizado, `traceId`, estado y duración deben ser correlacionables extremo a extremo.
8. **Seguridad:** autenticación en gateway, autorización por alcance, secretos en Secret Manager, cifrado TLS y mínimo privilegio entre componentes.

La arquitectura evita interpretar un error de comunicación como autorización para volver a ejecutar una operación financiera.
