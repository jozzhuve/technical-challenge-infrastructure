---
title: Arquitectura de la solución
---

# Arquitectura de la solución

La arquitectura busca mantener límites simples entre experiencia, capacidades de negocio, seguridad de entrada e infraestructura. No intenté convertir el reto en una plataforma sobredimensionada; prioricé que cada decisión tuviera una razón concreta.

## Vista lógica

```text
                         Usuario
                            |
                            v
                  React + Nginx (web)
                            |
                            v
                     Apache APISIX
                  JWT + rate limiting
                     /          \
                    /            \
                   v              v
        Endorsement API        Routing API
        Node + Hapi            Go
             |                  |
             v                  v
        PostgreSQL           Dijkstra

                Documentación: Docusaurus
                Ejecución local: Docker Compose
                Infra objetivo: Terraform / GCP
```

APISIX es el único punto de entrada local hacia las operaciones funcionales. Endorsement y Routing dejaron de publicar sus puertos al host, por lo que el gateway no es solamente un proxy visual: evita el acceso directo desde fuera de la red Docker.

## API Gateway

Elegí Apache APISIX para centralizar controles que no pertenecen al dominio de Endorsement ni al algoritmo de Routing.

La configuración actual incorpora:

- `jwt-auth` para validar el token antes de alcanzar el backend;
- `limit-count` para limitar solicitudes por ventana de tiempo;
- routing hacia los servicios internos;
- endpoints de health sin autenticación para probes.

Para el reto se utiliza modo standalone declarativo. No agregué etcd, Dashboard ni un control plane porque no son necesarios para demostrar la capacidad del gateway y aumentarían la carga operativa local sin aportar al caso.

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

Docker Compose integra seis servicios:

```text
web          -> localhost:3000
docs         -> localhost:3001
apisix       -> localhost:9080
postgres     -> localhost:5433
endorsement  -> solo red Docker: 8080
routing      -> solo red Docker: 8081
```

Dentro de la red de Docker, Endorsement se conecta a PostgreSQL por `postgres:5432`. El puerto `5433` existe únicamente para acceso desde la máquina host y evita colisionar con una instalación local de PostgreSQL.

## Arquitectura objetivo en GCP

La base Terraform contempla Artifact Registry, Cloud Run, Cloud SQL y Secret Manager. Endorsement y Routing permanecen planteados como servicios no anónimos.

```text
                    Entrada pública
                         |
                         v
                    Apache APISIX
                         |
              +----------+----------+
              |                     |
              v                     v
      Cloud Run privado      Cloud Run privado
        Endorsement              Routing
              |
              v
       Cloud SQL PostgreSQL
              |
        Secret Manager
```

La topología final de APISIX en GCP todavía debe cerrarse antes de ejecutar `terraform apply`. No considero correcto asumir que el mismo patrón de Docker Compose puede trasladarse sin revisar IAM, conectividad privada, TLS, DNS y operación del gateway.

## Principios utilizados

- Un único punto de entrada para las operaciones funcionales.
- Seguridad y políticas HTTP fuera de la lógica de negocio.
- Separación de responsabilidades por componente.
- Configuración dinámica donde existe variabilidad de negocio.
- Algoritmos de dominio desacoplados del transporte.
- Servicios stateless cuando es posible.
- Secretos fuera de imágenes y código.
- Errores funcionales controlados.
- Infraestructura reproducible.
- Decisiones pendientes documentadas en lugar de ocultarlas.
