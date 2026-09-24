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
- `technical-challenge-infrastructure`: Docker Compose, APISIX, Terraform, Postman y documentación.

## Qué busqué resolver

En endosos, el problema principal no era convertir un JSON en otro. El punto importante era evitar que la evolución por producto y tipo de endoso terminara llena de condicionales. Por eso moví orden, etiquetas, valores por defecto y eventos a plantillas persistidas en PostgreSQL.

En rutas, separé el algoritmo de Dijkstra del transporte HTTP. El servicio puede recibir distintos grafos y múltiples bases, calcular las alternativas alcanzables y devolver la de menor distancia sin acoplar el algoritmo al handler.

En préstamos, el problema central es el doble desembolso provocado por reintentos después de un `502`. La propuesta TO-BE cambia la operación síncrona por una aceptación idempotente y procesamiento asíncrono, manteniendo control sobre concurrencia, reintentos y trazabilidad.

## Estado actual

La solución local queda expuesta de esta manera:

| Componente | Estado local | Acceso |
| --- | --- | --- |
| Frontend | operativo | `http://localhost:3000` |
| Docusaurus | operativo | `http://localhost:3001` |
| Apache APISIX | gateway | `http://localhost:9080` |
| PostgreSQL | persistencia | `localhost:5433` |
| Endorsement API | interno | solo red Docker `8080` |
| Routing API | interno | solo red Docker `8081` |

Las operaciones funcionales de los ejercicios 1 y 2 pasan por APISIX. El gateway valida JWT, aplica rate limiting y enruta hacia los backends. Endorsement y Routing ya no publican sus puertos al host.

## Seguridad

Para la demostración local implementé un consumidor JWT en APISIX con HS256. El secreto se genera localmente, queda fuera de Git y los tokens de prueba tienen expiración.

Este mecanismo permite demostrar de forma real el control de acceso requerido por el reto sin duplicar lógica de autenticación entre Node y Go. El modelo productivo de identidad queda deliberadamente separado: en cloud el token debe provenir de un IdP confiable y APISIX debe validar el esquema definido por la organización.

## Criterio de arquitectura

Preferí mantener la solución pequeña y explicable. No agregué Kubernetes, service mesh, Kafka, Redis ni otros componentes que no fueran necesarios para demostrar el caso.

La infraestructura objetivo está preparada en Terraform sobre GCP usando Cloud Run, Cloud SQL, Artifact Registry y Secret Manager. La decisión de gateway ya está cerrada con APISIX; antes de ejecutar `terraform apply` todavía falta definir su topología productiva en GCP, IAM, conectividad privada, TLS/DNS, alta disponibilidad y el IdP definitivo.

La documentación diferencia tres cosas: lo implementado localmente, la infraestructura preparada y las decisiones que todavía requieren cierre antes de producción.