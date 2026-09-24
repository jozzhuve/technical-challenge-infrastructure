---
title: Seguridad y resiliencia
---

# Seguridad y resiliencia

No traté seguridad como una capa que se agrega al final. En la ejecución local ya existe un punto de entrada controlado y los backends dejaron de exponerse directamente al host.

## Seguridad de entrada

Apache APISIX queda delante de Endorsement y Routing.

```text
Cliente / Frontend
        |
        | Authorization: Bearer <JWT>
        v
    Apache APISIX
        |
        +---- valida JWT
        +---- aplica rate limit
        +---- enruta por path
        |
        v
 Backend dentro de la red Docker
```

Las operaciones funcionales requieren JWT. Los endpoints de health se mantienen sin autenticación para permitir probes operacionales.

## Por qué APISIX

Preferí un gateway desacoplado del proveedor cloud para centralizar autenticación y políticas de entrada sin duplicarlas en Node y Go.

Para este alcance lo ejecuté en modo standalone con configuración declarativa. No incorporé etcd, Dashboard ni Admin API porque no son necesarios para el reto.

Esto permite demostrar el control de acceso sin convertir el entorno local en una plataforma operativa más grande de lo necesario.

## JWT local

El consumidor configurado en APISIX se identifica con la clave `challenge-web` y utiliza HS256 para el entorno de demostración.

El secreto se genera localmente:

```bash
./scripts/bootstrap-security.sh
```

Se guarda en `.env`, archivo excluido de Git.

El JWT de prueba se genera con:

```bash
./scripts/generate-jwt.sh
```

El token tiene una vigencia corta y el frontend lo conserva únicamente en `sessionStorage`.

No considero este mecanismo local como el modelo definitivo de identidad. En producción el token debería provenir de un IdP corporativo y APISIX debería validar la identidad con el esquema acordado para la organización.

## Backends sin exposición directa

Endorsement y Routing usan `expose` dentro de Docker Compose y no `ports`.

Eso significa que desde el host no existen:

```text
localhost:8080
localhost:8081
```

como accesos públicos. Las operaciones entran por:

```text
localhost:9080
```

a través de APISIX.

## Rate limiting

Las rutas funcionales aplican `limit-count` en APISIX. La política local actual permite 60 solicitudes por ventana de 60 segundos y responde `429` al superar el límite.

Para una solución distribuida con múltiples instancias del gateway revisaría una política compartida, por ejemplo respaldada por Redis, porque el contador local no representa un límite global entre nodos.

## Secretos

Los secretos no deben quedar en código ni imágenes.

En local:

- `APISIX_JWT_SECRET` vive en `.env`;
- `.env` está fuera de Git;
- el script genera el valor con `openssl`.

En la infraestructura objetivo, la contraseña de PostgreSQL ya está planteada con Secret Manager. El secreto definitivo del mecanismo de autenticación deberá seguir el mismo criterio.

## Seguridad en GCP

Endorsement y Routing están definidos en Terraform como servicios no anónimos. La incorporación local de APISIX cierra el patrón de gateway, pero todavía queda por definir la topología productiva del gateway antes de ejecutar `terraform apply`.

Ese cierre debe considerar:

- identidad del runtime de APISIX;
- `roles/run.invoker` o mecanismo equivalente hacia Cloud Run;
- conectividad privada;
- TLS y dominio;
- gestión del secreto o clave pública del emisor JWT;
- alta disponibilidad del gateway;
- observabilidad y auditoría.

## Validación de entrada

Endorsement valida el contrato recibido antes de ejecutar el caso de uso. Routing valida el grafo y rechaza pesos negativos.

El gateway no reemplaza esas validaciones. APISIX controla acceso y políticas HTTP; cada servicio sigue siendo responsable de validar su contrato funcional.

## Errores

Los errores funcionales se distinguen de los errores técnicos.

Ejemplos:

- JWT ausente o inválido: `401` en APISIX;
- límite excedido: `429` en APISIX;
- plantilla no encontrada: `404` en Endorsement;
- ruta no alcanzable: `422` en Routing;
- falla no controlada: `5xx`.

## Resiliencia

Para Endorsement y Routing la primera medida es mantenerlos stateless y poder escalar horizontalmente.

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
consumidor autenticado
servicio
endpoint / caso de uso
duración
resultado
código de error
```

Además, para préstamos mediría operaciones aceptadas, completadas, fallidas, reintentos, mensajes en DLQ, latencia de INARI y tiempo total de procesamiento.
