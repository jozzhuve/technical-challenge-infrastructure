---
title: Repositorios y responsabilidades
---

# Repositorios y responsabilidades

Separé la solución en cuatro repositorios. La razón no fue dividir por dividir, sino mantener responsabilidades claras y evitar que infraestructura, frontend y servicios con runtimes distintos queden acoplados en un único artefacto.

## `technical-challenge-endorsement`

Responsable del ejercicio de traducción de endosos.

### Qué contiene

- Node.js 22.
- TypeScript.
- Hapi.
- TypeORM.
- PostgreSQL.
- Validación de entrada.
- Manejo de errores funcionales.
- Plantillas configurables.
- Pruebas unitarias.
- Dockerfile.
- OpenAPI.

### Qué resuelve

Recibe una solicitud plana y genera la estructura esperada por el core. La combinación `producto + tipoEndoso` determina qué plantilla utilizar.

La plantilla define:

- campos dinámicos;
- etiqueta de salida;
- campo origen;
- valor por defecto;
- obligatoriedad;
- orden;
- eventos aplicados y su secuencia.

El servicio no contiene lógica específica del tipo `if producto == X`. Esa fue una decisión consciente para que la evolución ocurra principalmente en configuración.

## `technical-challenge-routing`

Responsable del ejercicio de rutas óptimas.

### Qué contiene

- Go.
- API HTTP.
- dominio de grafo;
- implementación de Dijkstra;
- caso de uso para múltiples depósitos;
- errores controlados;
- pruebas unitarias;
- Dockerfile;
- OpenAPI.

### Qué resuelve

A partir de un grafo ponderado, una ubicación de accidente y una lista de depósitos, calcula qué depósito puede llegar con la menor distancia y devuelve la ruta encontrada.

El algoritmo está separado del handler HTTP. Esto permite probarlo sin levantar servidor y evita mezclar transporte con lógica algorítmica.

## `technical-challenge-web`

Responsable de la experiencia de prueba de los dos ejercicios.

### Qué contiene

- React.
- TypeScript.
- Vite.
- Nginx para ejecución en contenedor.
- editor de JSON de entrada;
- visualización de respuesta;
- ejemplos precargados;
- integración con ambos servicios.

### Qué resuelve

Permite ejecutar los dos casos desde una sola interfaz sin depender únicamente de Postman.

En local, Nginx funciona como reverse proxy hacia los nombres internos de Docker Compose. Esta configuración no se toma como diseño definitivo para Cloud Run.

## `technical-challenge-infrastructure`

Es el repositorio transversal de la solución.

### Qué contiene

- `docker-compose.yml`;
- Terraform para GCP;
- módulo reutilizable de Cloud Run;
- scripts de soporte;
- colección Postman;
- documentación Docusaurus;
- propuesta de arquitectura del ejercicio de préstamos.

### Qué resuelve

Centraliza todo lo relacionado con ejecución, despliegue y documentación sin contaminar los repositorios aplicativos con detalles de infraestructura.

## Relación entre repositorios

```text
technical-challenge-web
      |        |
      |        +----> technical-challenge-routing
      |
      +-------------> technical-challenge-endorsement
                              |
                              v
                          PostgreSQL

technical-challenge-infrastructure
      |
      +---- Docker Compose
      +---- Terraform
      +---- Postman
      +---- Docusaurus
```

Los cuatro repositorios pueden evolucionar de manera independiente, pero el repositorio de infraestructura mantiene la vista integral de la solución.