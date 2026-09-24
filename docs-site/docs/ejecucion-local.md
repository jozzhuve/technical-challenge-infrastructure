---
title: Ejecución local
---

# Ejecución local

La solución está pensada para poder revisarse desde una carpeta raíz que contenga los cuatro repositorios como hermanos.

```text
RETO-TECNICO-LT/
├── technical-challenge-endorsement/
├── technical-challenge-routing/
├── technical-challenge-web/
└── technical-challenge-infrastructure/
```

## Preparar seguridad

Antes de levantar el compose por primera vez:

```bash
cd technical-challenge-infrastructure
./scripts/bootstrap-security.sh
```

Esto genera `.env` con un secreto JWT local que no se versiona.

## Levantar todo

Desde `technical-challenge-infrastructure`:

```bash
docker compose up --build -d
```

El compose construye y levanta:

| Servicio | URL / puerto |
| --- | --- |
| Frontend | `http://localhost:3000` |
| Documentación | `http://localhost:3001` |
| Apache APISIX | `http://localhost:9080` |
| PostgreSQL | `localhost:5433` |
| Endorsement API | solo red Docker `8080` |
| Routing API | solo red Docker `8081` |

Endorsement y Routing no publican puertos al host. Las operaciones funcionales pasan por APISIX.

PostgreSQL usa internamente el puerto `5432`. El mapeo `5433:5432` existe para evitar conflictos con una instancia local que ya utilice `5432`.

## Verificar contenedores

```bash
docker compose ps
```

## Health checks por gateway

```bash
curl http://localhost:9080/health/endorsement
curl http://localhost:9080/health/routing
```

## Generar JWT de prueba

```bash
TOKEN=$(./scripts/generate-jwt.sh)
echo "$TOKEN"
```

El token tiene una vigencia de una hora por defecto. Puede cambiarse para una ejecución puntual:

```bash
JWT_TTL_SECONDS=600 ./scripts/generate-jwt.sh
```

## Comprobar seguridad

Sin token, una operación funcional debe responder `401`:

```bash
curl -i \
  -X POST http://localhost:9080/api/v1/routes/optimal \
  -H 'Content-Type: application/json' \
  -d '{}'
```

El frontend utiliza el mismo gateway. Abre `http://localhost:3000`, pega el JWT generado en la sección de acceso por API Gateway y guarda el token para la sesión actual.

## Validar con Postman / Newman

```bash
TOKEN=$(./scripts/generate-jwt.sh)
npx --yes newman run postman/technical-challenge.postman_collection.json \
  --env-var jwtToken="$TOKEN"
```

La colección valida:

- health de ambos backends a través de APISIX;
- `401` cuando falta JWT;
- traducción de endosos;
- plantilla inexistente;
- ruta óptima;
- ruta no alcanzable.

## Ver logs

```bash
docker compose logs -f
```

Por servicio:

```bash
docker compose logs -f apisix
docker compose logs -f endorsement
docker compose logs -f routing
docker compose logs -f web
docker compose logs -f docs
docker compose logs -f postgres
```

## Detener

```bash
docker compose down
```

Si se necesita reinicializar por completo la base local y volver a ejecutar los scripts de `docker-entrypoint-initdb.d`:

```bash
docker compose down -v
docker compose up --build -d
```

El `-v` elimina el volumen local de PostgreSQL. No debe usarse si se quiere conservar la información cargada en ese entorno.

## Docusaurus

La documentación queda disponible en:

```text
http://localhost:3001
```

También puede ejecutarse de forma independiente:

```bash
cd docs-site
npm install
npm run start -- --port 3001
```

## Dependencias locales

Para la ejecución con Docker Compose no es necesario instalar Node.js, Go o PostgreSQL directamente para correr los servicios.

En la máquina host se utiliza `openssl` para generar el secreto y firmar el JWT de demostración. Node/npm solo son necesarios si se quiere ejecutar Newman mediante `npx` o correr Docusaurus fuera de Docker.
