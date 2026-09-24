---
title: Pruebas y evidencias
---

# Pruebas y evidencias

Quise que la entrega pudiera verificarse sin depender de una explicación verbal. Por eso dejé pruebas a nivel de código y una colección Postman para ejecutar los flujos integrados.

## Validación integrada

Con los contenedores levantados mediante Docker Compose se ejecutó:

```bash
npx --yes newman run postman/technical-challenge.postman_collection.json
```

Resultado observado en la ejecución local:

```text
iterations      1 ejecutada / 0 fallidas
requests        6 ejecutadas / 0 fallidas
assertions      6 ejecutadas / 0 fallidas
average         24 ms
min              4 ms
max             74 ms
```

No utilizo estos tiempos como benchmark. Solo sirven como evidencia de que los contratos respondieron correctamente dentro del entorno local.

## Casos cubiertos por Postman

### Endorsement

```text
GET  /health
POST /api/v1/endorsements/translate
POST /api/v1/endorsements/translate con plantilla inexistente
```

Se valida:

- disponibilidad del servicio;
- respuesta `200` del flujo principal;
- respeto del orden de eventos de la plantilla;
- respuesta `404` cuando no existe configuración.

### Routing

```text
GET  /health
POST /api/v1/routes/optimal
POST /api/v1/routes/optimal con destino no alcanzable
```

Se valida:

- disponibilidad del servicio;
- selección de `Miraflores` para el ejemplo configurado;
- distancia esperada de `7`;
- respuesta `422` cuando ninguna ruta es alcanzable.

## Pruebas unitarias incluidas

### Endorsement

El servicio cuenta con pruebas sobre la lógica de traducción, especialmente para:

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

Las pruebas cubren el algoritmo y el caso de uso:

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

La ejecución integrada también valida de forma práctica que las imágenes de los tres componentes aplicativos pueden construirse y arrancar juntas.

Estado observado:

```text
endorsement   running (healthy)
postgres      running (healthy)
routing       running (healthy)
web           running
docs          running
```

## Quality gates

Dejé scripts locales reproducibles en cada repositorio para lint, tests, coverage y build.

No hay CI/CD automático habilitado en esta etapa. La intención es que cualquier automatización futura llame exactamente a esos mismos comandos y no mantenga una lógica diferente a la ejecución local.

## Qué faltaría para una validación productiva

Antes de considerar la solución lista para una carga real agregaría:

- prueba de carga con volumetría acordada;
- pruebas de degradación de base de datos;
- pruebas de timeout y retry de integraciones;
- pruebas de autenticación/autorización una vez definido API Gateway/JWT;
- validación de migraciones sobre Cloud SQL;
- revisión de vulnerabilidades de imágenes y dependencias;
- validación de límites de concurrencia y escalado de Cloud Run.

La intención de esta sección es diferenciar evidencia ejecutada de controles que todavía forman parte de una siguiente fase.