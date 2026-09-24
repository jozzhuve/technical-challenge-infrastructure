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

En préstamos, el problema central es el doble desembolso provocado por reintentos después de un `502`. La propuesta TO-BE cambia la operación síncrona por una aceptación idempotente y procesamiento asíncrono, manteniendo control sobre concurrencia, reintentos, estado y trazabilidad.

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

## Evidencia integrada

La validación final con Newman se ejecutó contra APISIX utilizando JWT.

```text
requests        7 ejecutadas / 0 fallidas
assertions      9 ejecutadas / 0 fallidas
duración total  454 ms
average         51 ms
min              4 ms
max            219 ms
```

La ejecución incluye health checks, validación de `401` sin JWT y los casos funcionales de Endorsement y Routing con autenticación válida.

Estos tiempos corresponden únicamente al entorno local utilizado para el reto y no se consideran una medición de capacidad.

## Seguridad

Para la demostración local implementé un consumidor JWT en APISIX con HS256. El secreto se genera localmente, queda fuera de Git y los tokens de prueba tienen expiración.

Este mecanismo permite demostrar de forma real el control de acceso requerido por el reto sin duplicar lógica de autenticación entre Node y Go. El modelo productivo de identidad queda separado: en cloud el token debe provenir de un IdP confiable y APISIX debe validar el esquema definido por la organización.

## Ejercicio 3

La propuesta TO-BE incorpora idempotencia persistida, Cloud SQL, outbox transaccional, publicación asíncrona, Pub/Sub, Worker, reintentos controlados, DLQ y consulta de estado mediante `operationId`.

Todas las llamadas del cliente pasan por APISIX. INARI / ADMWR se mantiene como sistema externo a la plataforma GCP y el Worker es el responsable de ejecutar la integración de desembolso y actualizar el estado de la operación.

## Criterio de arquitectura

Preferí mantener la solución pequeña y explicable. No agregué Kubernetes, service mesh, Kafka, Redis ni otros componentes que no fueran necesarios para demostrar el caso.

La infraestructura objetivo está preparada en Terraform sobre GCP usando Cloud Run, Cloud SQL, Artifact Registry y Secret Manager. La seguridad local ya está demostrada con APISIX y JWT.

El siguiente punto pendiente del reto es obtener evidencia real de despliegue cloud para los ejercicios 1 y 2. Antes de ejecutar `terraform apply` debe cerrarse la topología cloud definitiva del gateway, IAM, conectividad, TLS/DNS y el mecanismo de identidad productivo.

La documentación diferencia tres cosas: lo implementado y validado localmente, la infraestructura preparada y lo que todavía requiere evidencia en GCP.