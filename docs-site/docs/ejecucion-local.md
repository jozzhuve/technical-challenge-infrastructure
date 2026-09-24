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

## Levantar todo

Desde la carpeta raíz:

```bash
docker compose \
  -f technical-challenge-infrastructure/docker-compose.yml \
  up --build -d
```

El compose construye y levanta:

| Servicio | URL / puerto |
| --- | --- |
| Frontend | `http://localhost:3000` |
| Documentación | `http://localhost:3001` |
| Endorsement API | `http://localhost:8080` |
| Routing API | `http://localhost:8081` |
| PostgreSQL | `localhost:5433` |

PostgreSQL usa internamente el puerto `5432`. El mapeo `5433:5432` existe para evitar conflictos con una instancia local que ya utilice `5432`.

## Verificar contenedores

```bash
cd technical-challenge-infrastructure
docker compose ps
```

Los servicios con healthcheck deben quedar como `healthy`.

## Health checks

```bash
curl http://localhost:8080/health
curl http://localhost:8081/health
```

Respuesta esperada:

```json
{
  "status": "UP"
}
```

## Validar con Postman / Newman

Desde `technical-challenge-infrastructure`:

```bash
npx --yes newman run postman/technical-challenge.postman_collection.json
```

La colección contiene casos exitosos y errores controlados para ambos servicios.

## Ver logs

```bash
docker compose logs -f
```

Por servicio:

```bash
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

La documentación ya está incluida en Docker Compose y queda disponible en:

```text
http://localhost:3001
```

También puede ejecutarse de forma independiente:

```bash
cd technical-challenge-infrastructure/docs-site
npm install
npm run start -- --port 3001
```

## Nota sobre dependencias locales

Para la ejecución con Docker Compose no es necesario instalar Node.js, Go o PostgreSQL directamente para correr los servicios. Docker se encarga de construir cada runtime.

Node/npm sí son necesarios si se quiere ejecutar Newman mediante `npx` desde la máquina host o correr Docusaurus fuera de Docker.