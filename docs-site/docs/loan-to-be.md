---
sidebar_position: 3
---

# Préstamos de renta particular

El problema del AS-IS consiste en que un timeout o 502 puede llegar al cliente mientras el desembolso continúa ejecutándose. Un nuevo intento del cliente puede generar otro movimiento financiero.

La propuesta separa aceptación y procesamiento mediante una operación idempotente, `202 Accepted`, outbox transaccional, broker y worker. Los reintentos se realizan sobre la misma operación y no crean una nueva intención de desembolso.

Estados sugeridos: `PENDING`, `PROCESSING`, `COMPLETED` y `FAILED`.

La clave idempotente y una restricción única en persistencia constituyen la última barrera contra ejecuciones concurrentes duplicadas.
