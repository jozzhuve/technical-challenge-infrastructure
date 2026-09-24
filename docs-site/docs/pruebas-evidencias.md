---
title: Pruebas y evidencias
---

# Pruebas y evidencias

La entrega puede verificarse sin depender de una explicación verbal. Dejé pruebas a nivel de código y una colección Postman preparada para ejecutar los flujos integrados a través de Apache APISIX.

## Validación funcional previa

Antes de incorporar el gateway se ejecutó la colección directamente sobre ambos servicios con resultado exitoso:

```text
iterations      1 ejecutada / 0 fallidas
requests        6 ejecutadas / 0 fallidas
assertions      6 ejecutadas / 0 fallidas
average         24 ms
min              4 ms
max             74 ms
```

Estos tiempos corresponden únicamente a la ejecución local del reto y no se consideran benchmark.

## Validación final con APISIX y JWT

La colección actual apunta al gateway:

```text
http://localhost:9080
```

La ejecución final se realizó generando un JWT temporal y ejecutando Newman:

```bash
TOKEN=$(./scripts/generate-jwt.sh)

npx --yes newman run postman/technical-challenge.postman_collection.json \
  --env-var jwtToken="$TOKEN"
```

Resultado observado:

```text
iterations      1 ejecutada / 0 fallidas
requests        7 ejecutadas / 0 fallidas
assertions      9 ejecutadas / 0 fallidas
duración total  454 ms
average         51 ms
min              4 ms
max            219 ms
```

Los tiempos corresponden únicamente al entorno local utilizado para el reto y no representan una prueba de capacidad.

## Casos validados

| Caso | Resultado esperado | Resultado observado |
| --- | ---: | ---: |
| Health Endorsement por APISIX | `200` | `200` |
| Health Routing por APISIX | `200` | `200` |
| Operación protegida sin JWT | `401` | `401` |
| Traducción de endoso con JWT válido | `200` | `200` |
| Plantilla inexistente | `404` | `404` |
| Cálculo de ruta óptima con JWT válido | `200` | `200` |
| Ruta no alcanzable | `422` | `422` |

Además de los códigos HTTP, la colección valida que el traductor respete la plantilla configurada y que Routing seleccione `Miraflores` con distancia `7` para el caso de prueba.

## Seguridad demostrada

La ejecución permite comprobar de forma directa que:

| Control | Evidencia |
| --- | --- |
| JWT obligatorio | una operación funcional sin token responde `401` |
| JWT válido | las operaciones autenticadas alcanzan los backends y responden según el caso funcional |
| Gateway único | las pruebas funcionales utilizan `localhost:9080` |
| Backends no expuestos | Endorsement y Routing utilizan `expose` y no publican `8080` ni `8081` al host |
| Rate limiting | las rutas funcionales tienen `limit-count` configurado en APISIX con respuesta `429` al superar la política |

Los endpoints de health permanecen sin autenticación para permitir probes operacionales.

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

Estado validado durante la ejecución local:

```text
apisix        running
endorsement   running (healthy)
routing       running (healthy)
postgres      running (healthy)
web           running
docs          running (healthy)
```

Los dos backends permanecen accesibles dentro de la red Docker para APISIX, pero no se publican directamente al host.

## Quality gates

Cada repositorio mantiene comandos locales reproducibles para lint, tests, coverage y build.

No hay CI/CD automático habilitado en esta etapa. Cualquier automatización posterior debería reutilizar los mismos comandos de validación y no mantener una lógica diferente a la ejecución local.

## Qué falta validar en cloud

La evidencia local de funcionalidad y seguridad ya está cerrada. El siguiente punto del reto es demostrar el despliegue de los ejercicios 1 y 2 en GCP.

Antes de considerar la solución preparada para producción también revisaría:

- prueba de carga con volumetría acordada;
- pruebas de degradación de base de datos;
- pruebas distribuidas del rate limit;
- integración con un IdP productivo y rotación de claves;
- TLS, DNS e IAM del gateway;
- conectividad privada hacia Cloud Run;
- migraciones sobre Cloud SQL;
- vulnerabilidades de imágenes y dependencias;
- límites de concurrencia y escalado de Cloud Run.

Esta sección separa la evidencia ya ejecutada de los controles que todavía pertenecen al despliegue cloud y a una preparación productiva.