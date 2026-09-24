---
slug: /
title: Visión general
---

# Reto técnico - Arquitectura de Solución

La propuesta la enfoqué como una solución ejecutable y no solo como una respuesta teórica al reto. El objetivo fue resolver los dos ejercicios de desarrollo, dejar una base de infraestructura reproducible y plantear el rediseño del tercer ejercicio desde una mirada de arquitectura de solución.

Trabajé sobre cuatro repositorios separados porque cada componente tiene una responsabilidad y un ciclo de vida distinto:

- `technical-challenge-endorsement`: traductor de endosos.
- `technical-challenge-routing`: cálculo de rutas óptimas.
- `technical-challenge-web`: interfaz para probar ambos casos.
- `technical-challenge-infrastructure`: Docker Compose, Terraform, Postman y esta documentación.

La solución local se levanta completa con Docker Compose. Actualmente se validó el flujo integrado con PostgreSQL, los dos servicios, el frontend y la documentación.

## Qué busqué resolver

En el ejercicio de endosos, el problema principal no era convertir un JSON en otro. El punto que consideré importante fue evitar que la evolución por producto y tipo de endoso terminara llena de condicionales. Por eso moví orden, etiquetas, valores por defecto y eventos a plantillas persistidas en PostgreSQL.

En el ejercicio de rutas, separé el algoritmo de Dijkstra del transporte HTTP. El servicio puede recibir distintos grafos y múltiples bases, calcular las alternativas alcanzables y devolver la de menor distancia sin acoplar el algoritmo al handler.

En el ejercicio de préstamos, el problema que tomé como central fue el doble desembolso provocado por reintentos después de un `502`. La propuesta TO-BE cambia la operación síncrona por una aceptación idempotente y procesamiento asíncrono, manteniendo control sobre concurrencia, reintentos y trazabilidad.

## Estado actual

La parte funcional ya está operativa en local:

| Componente | Estado local | Puerto |
| --- | --- | ---: |
| Frontend | operativo | 3000 |
| Docusaurus | operativo | 3001 |
| Endorsement API | healthy | 8080 |
| Routing API | healthy | 8081 |
| PostgreSQL | healthy | 5433 |

La colección Postman se ejecutó sobre la solución levantada en Docker con el siguiente resultado observado:

```text
requests:    6
assertions:  6
failed:      0
average:     24 ms
max:         74 ms
```

Estos tiempos corresponden únicamente a la ejecución local realizada para el reto; no los tomo como una medición de capacidad ni como un benchmark de producción.

## Criterio de arquitectura

Preferí mantener la solución pequeña y explicable. No agregué Kubernetes, service mesh, Kafka, Redis ni otros componentes que no fueran necesarios para demostrar el caso.

La infraestructura objetivo está preparada en Terraform sobre GCP usando Cloud Run, Cloud SQL, Artifact Registry y Secret Manager. No ejecuté `terraform apply` todavía porque antes de desplegar considero necesario cerrar el ingreso por API Gateway/JWT y resolver de forma explícita cómo se conectará el frontend con APIs privadas en Cloud Run.

La documentación deja diferenciadas tres cosas: lo que ya está implementado y probado, lo que está preparado como infraestructura y lo que propongo como evolución para un escenario productivo.