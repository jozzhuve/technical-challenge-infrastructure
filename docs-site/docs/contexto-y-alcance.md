---
title: Contexto y alcance
---

# Contexto y alcance

Para resolver el reto separé claramente los tres problemas planteados y traté de no mezclarlos entre sí. Dos requieren implementación ejecutable y el tercero requiere una propuesta de arquitectura orientada a eliminar una falla operativa concreta.

## Ejercicio 1 - Endosos

El cliente envía una estructura plana y el core espera una estructura ordenada cuya forma depende del producto y del tipo de endoso. La solución debía considerar orden de campos dinámicos, etiquetas, valores por defecto y secuencia de eventos aplicados.

Mi decisión fue modelar esa variabilidad como configuración persistida. El traductor no conoce reglas específicas de `Rumbo`, `CambioFrecuencia` u otro producto futuro; conoce una plantilla y sabe cómo interpretarla.

Esto permite que una nueva combinación de producto y tipo de endoso se resuelva principalmente agregando datos de configuración, sin abrir el servicio para incorporar un nuevo bloque de lógica condicional.

## Ejercicio 2 - Rutas óptimas

El segundo problema consiste en encontrar la ruta mínima desde la base de grúas más conveniente hasta el lugar de un accidente, trabajando sobre un grafo ponderado y soportando múltiples bases.

La solución usa Dijkstra y mantiene el algoritmo aislado del transporte HTTP. El caso de uso evalúa las bases disponibles, descarta las que no pueden alcanzar el destino y selecciona la alternativa de menor distancia.

## Ejercicio 3 - Préstamos

El AS-IS presenta un problema distinto. El cliente puede recibir un `502` mientras el procesamiento interno continúa. Si el usuario reintenta, se puede generar una segunda intención de desembolso aunque la primera haya terminado correctamente.

Para este caso no planteé aumentar timeouts como solución principal. El rediseño separa la aceptación de la solicitud del procesamiento contra INARI, incorpora una clave idempotente y mantiene una única operación de negocio durante reintentos técnicos o reenvíos del cliente.

## Alcance implementado

Quedó implementado:

- Endorsement API en Node.js, TypeScript y Hapi.
- Persistencia de plantillas de endosos en PostgreSQL.
- Routing API en Go.
- Implementación de Dijkstra con soporte de múltiples depósitos.
- Frontend React para probar ambos servicios.
- Dockerización de los componentes.
- Docker Compose para ejecución local integrada.
- Colección Postman con happy path y errores controlados.
- Base de Terraform para GCP.
- Documentación en Docusaurus.

## Fuera del alcance ejecutado

No considero como ejecutado aquello que todavía no se ha validado realmente. En particular:

- No se ha realizado `terraform apply` en GCP.
- API Gateway y validación JWT están planteados, pero no provisionados.
- No se ha realizado una prueba de carga formal.
- No se ha desplegado el esquema de PostgreSQL mediante una estrategia de migraciones en GCP.
- No se ha habilitado CI/CD automático. Las validaciones se mantienen reproducibles de forma local.

Prefiero dejar estos puntos explícitos antes que presentar como terminado algo que todavía requiere una decisión o una prueba adicional.