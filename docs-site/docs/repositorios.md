---
title: Repositorios y responsabilidades
---

# Repositorios y responsabilidades

Separé la solución en cuatro repositorios para mantener responsabilidades claras y evitar que infraestructura, frontend y servicios con runtimes distintos queden acoplados en un único artefacto.

## `technical-challenge-endorsement`

Responsable del ejercicio de traducción de endosos.

### Qué contiene

- Node.js 22;
- TypeScript;
- Hapi;
- TypeORM;
- PostgreSQL;
- validación de entrada;
- manejo de errores funcionales;
- plantillas configurables;
- pruebas unitarias;
- Dockerfile;
- OpenAPI.

### Qué resuelve

Recibe una solicitud plana y genera la estructura esperada por el core. La combinación `producto + tipoEndoso` determina qué plantilla utilizar.

La plantilla define campos dinámicos, etiquetas, campo origen, valor por defecto, obligatoriedad, orden y eventos aplicados.

El servicio no contiene condicionales específicos por producto. La intención es que la evolución ocurra principalmente en configuración.

## `technical-challenge-routing`

Responsable del ejercicio de rutas óptimas.

### Qué contiene

- Go;
- API HTTP;
- dominio de grafo;
- Dijkstra;
- caso de uso para múltiples depósitos;
- errores controlados;
- pruebas unitarias;
- Dockerfile;
- OpenAPI.

### Qué resuelve

A partir de un grafo ponderado, una ubicación de accidente y una lista de depósitos, calcula qué depósito puede llegar con la menor distancia y devuelve la ruta encontrada.

El algoritmo está separado del handler HTTP para mantener desacoplada la lógica algorítmica del transporte.

## `technical-challenge-web`

Responsable de la experiencia de prueba de ambos ejercicios.

### Qué contiene

- React;
- TypeScript;
- Vite;
- Nginx para servir el artefacto estático;
- editor de JSON;
- visualización de respuesta;
- ejemplos precargados;
- soporte para JWT de prueba en `sessionStorage`.

### Qué resuelve

Permite ejecutar los dos casos desde una sola interfaz. El frontend ya no enruta directamente hacia Endorsement y Routing: consume Apache APISIX como punto único de entrada.

## `technical-challenge-infrastructure`

Es el repositorio transversal de la solución.

### Qué contiene

- `docker-compose.yml`;
- Apache APISIX en modo standalone;
- configuración JWT y rate limiting;
- scripts para generar secreto y JWT local;
- Terraform para GCP;
- módulo reutilizable de Cloud Run;
- colección Postman/Newman;
- documentación Docusaurus;
- propuesta de arquitectura del ejercicio de préstamos.

### Qué resuelve

Centraliza ejecución, seguridad de entrada, infraestructura y documentación sin contaminar los repositorios aplicativos con detalles operativos.

## Relación entre repositorios

```text
technical-challenge-web
          |
          v
      Apache APISIX
       /        \
      v          v
Endorsement    Routing
     |
     v
PostgreSQL

technical-challenge-infrastructure
      |
      +---- Docker Compose
      +---- APISIX / JWT / Rate Limit
      +---- Terraform
      +---- Postman
      +---- Docusaurus
```

Los cuatro repositorios pueden evolucionar de manera independiente, mientras infraestructura mantiene la vista integral de la solución.