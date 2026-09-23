---
sidebar_position: 2
---

# Arquitectura de la solución

```text
React / Nginx
   |------------------------|
   v                        v
Endorsement API          Routing API
Node + Hapi              Go
   |                        |
   v                        v
PostgreSQL              Dijkstra
```

La separación por repositorios responde a runtimes y ciclos de vida distintos. La infraestructura se mantiene fuera del código aplicativo para evitar acoplamiento con el proveedor cloud.

## GCP

El objetivo de despliegue utiliza Cloud Run, Cloud SQL, Artifact Registry y Secret Manager. Antes del despliegue final se incorporará API Gateway con validación JWT para evitar exposición directa de los backends.
