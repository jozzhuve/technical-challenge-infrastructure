---
title: Arquitectura de la solución
---

# Arquitectura de la solución

La arquitectura busca mantener límites simples entre experiencia, capacidades de negocio e infraestructura. No intenté convertir el reto en una plataforma sobredimensionada; prioricé que cada decisión tuviera una razón concreta.

## Vista lógica

```text
                         Usuario
                            |
                            v
                  React + Nginx (web)
                     /           \
                    /             \
                   v               v
        Endorsement API         Routing API
        Node + Hapi             Go
             |                   |
             v                   v
        PostgreSQL            Dijkstra

                Documentación: Docusaurus
                Ejecución local: Docker Compose
                Infra objetivo: Terraform / GCP
```

## Endorsement API

El servicio de endosos se separa en capas porque el dato variable pertenece al dominio/configuración y no al framework HTTP.

```text
Hapi Route
   |
Controller
   |
Application Service
   |
Repository Port
   |
TypeORM Adapter
   |
PostgreSQL
```

El caso de uso recibe una solicitud plana, obtiene la plantilla activa por producto y tipo de endoso, resuelve valores, aplica defaults, respeta el orden configurado y arma la respuesta final.

La intención de esta separación es que Hapi y TypeORM sean detalles reemplazables. La regla principal del traductor no necesita conocer ninguno de los dos.

## Routing API

```text
HTTP Handler
    |
Application Service
    |
Dijkstra
    |
Graph Domain
```

Dijkstra se mantiene independiente del handler. El caso de uso recorre los depósitos informados, calcula el camino mínimo cuando existe y selecciona la menor distancia válida.

Esto evita que la implementación del algoritmo quede mezclada con validación HTTP, serialización o códigos de respuesta.

## Ejecución local

Docker Compose integra cinco servicios:

```text
web          -> localhost:3000
docs         -> localhost:3001
endorsement  -> localhost:8080
routing      -> localhost:8081
postgres     -> localhost:5433
```

Dentro de la red de Docker, Endorsement se conecta a PostgreSQL por `postgres:5432`. El puerto `5433` existe únicamente para acceso desde la máquina host y evita colisionar con una instalación local de PostgreSQL.

## Arquitectura objetivo en GCP

La base Terraform contempla:

```text
Artifact Registry
      |
      +-------------------+
      |                   |
      v                   v
Cloud Run             Cloud Run
Endorsement            Routing
      |
      v
Cloud SQL PostgreSQL
      |
Secret Manager

Cloud Run Web
```

Endorsement y Routing están definidos como servicios no anónimos. El frontend sí está definido como público. Esto deja pendiente una decisión necesaria antes de aplicar Terraform: incorporar API Gateway/JWT y hacer que el frontend consuma un punto de entrada válido para servicios privados.

No considero correcto reutilizar en GCP el proxy de Nginx local basado en nombres de servicio Docker. Ese mecanismo sirve para Compose, no representa el mecanismo final de descubrimiento/autenticación en Cloud Run.

## Principios utilizados

- Separación de responsabilidades por componente.
- Configuración dinámica donde existe variabilidad de negocio.
- Algoritmos de dominio desacoplados del transporte.
- Servicios stateless cuando es posible.
- Secretos fuera de imágenes y código.
- Errores funcionales controlados.
- Infraestructura reproducible.
- Decisiones pendientes documentadas en lugar de ocultarlas.