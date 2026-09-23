# Arquitectura general

La solución se separa en cuatro repositorios porque existen tres runtimes distintos y un ciclo de vida independiente para infraestructura y documentación.

```text
Usuario
  |
  v
React + Nginx
  |------------------------|
  v                        v
Endorsement API          Routing API
Node + Hapi              Go
  |                        |
  v                        v
PostgreSQL             Dijkstra
```

## Ejecución local

Docker Compose levanta PostgreSQL, ambos backends y el frontend. El frontend actúa como reverse proxy hacia los servicios para evitar acoplar la UI a nombres de contenedor o puertos internos.

## Objetivo GCP

La primera versión de infraestructura contempla Artifact Registry, Cloud Run, Cloud SQL y Secret Manager. API Gateway y el esquema de autenticación JWT se incorporarán antes del despliegue final para que los backends no queden expuestos directamente.

La prioridad actual es validar la solución funcional y obtener un `terraform plan` reproducible antes de aplicar cambios sobre la cuenta GCP.
