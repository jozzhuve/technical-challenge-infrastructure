---
title: Pruebas y evidencias
---

# Pruebas y evidencias

La entrega puede verificarse sin depender de una explicación verbal. Dejé pruebas a nivel de código y una colección Postman preparada para ejecutar los flujos integrados a través de Apache APISIX.

## Validación funcional previa

Antes de incorporar el gateway se ejecutó la colección sobre ambos servicios con resultado exitoso:

```text
iterations      1 ejecutada / 0 fallidas
requests        6 ejecutadas / 0 fallidas
assertions      6 ejecutadas / 0 fallidas
average         24 ms
min              4 ms
max             74 ms
```

Estos tiempos corresponden únicamente a la ejecución local del reto y no se consideran benchmark.

## Validación actual con APISIX y JWT

La colección actual apunta al gateway:

```text
http://localhost:9080
```

Para generar un JWT temporal y ejecutar Newman:

```bash
TOKEN=$(./scripts/generate-jwt.sh)

npx --yes newman run postman/technical-challenge.postman_collection.json \
  --env-var jwtToken="$TOKEN"
```

La colección valida:

- health de Endorsement a través de APISIX;
- health de Routing a través de APISIX;
- operación protegida sin JWT y respuesta `401`;
- traducción de endosos con JWT válido;
- plantilla inexistente y respuesta `404`;
- ruta óptima con JWT válido;
- ruta no alcanzable y respuesta `422`.

No registro aquí un resultado numérico de esta segunda ejecución hasta conservar la evidencia final obtenida desde Newman.

## Seguridad demostrable

La configuración local permite comprobar estos comportamientos:

```text
sin JWT               -> 401
JWT válido             -> operación funcional
rate limit excedido    -> 429
backend directo host   -> no expuesto
```

Endorsement y Routing utilizan `expose` en Docker Compose y no `ports`, por lo que desde el host el acceso funcional queda centralizado en APISIX.

## Pruebas unitarias incluidas

### Endorsement

El servicio cuenta con pruebas sobre:

- orden de campos;
- aplicación de valores por defecto;
- plantilla inexistente.

Comandos:

```bash
npm run test
npm run test:coverage
npm run quality
```

### Routing

Las pruebas cubren:

- camino mínimo;
- selección entre múltiples depósitos;
- destino no alcanzable.

Comandos:

```bash
make test
make quality
make build
```

## Build de contenedores

El entorno integrado contiene:

```text
apisix
endorsement
routing
postgres
web
docs
```

Los dos backends permanecen accesibles internamente para el gateway y sus health checks, pero no se publican al host.

## Quality gates

Cada repositorio mantiene comandos locales reproducibles para lint, tests, coverage y build.

No hay CI/CD automático habilitado en esta etapa. La intención es que cualquier automatización futura reutilice esos mismos comandos y no mantenga una lógica diferente a la validación local.

## Qué faltaría para una validación productiva

Antes de considerar la solución preparada para producción agregaría:

- prueba de carga con volumetría acordada;
- pruebas de degradación de base de datos;
- pruebas distribuidas del rate limit;
- validación con IdP productivo y rotación de claves;
- validación de TLS y conectividad privada gateway -> Cloud Run;
- validación de migraciones sobre Cloud SQL;
- revisión de vulnerabilidades de imágenes y dependencias;
- validación de límites de concurrencia y escalado de Cloud Run.

Esta sección separa evidencia ya ejecutada, controles implementados y validaciones que pertenecen al despliegue productivo.