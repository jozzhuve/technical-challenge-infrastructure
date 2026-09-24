---
title: Decisiones de arquitectura
---

# Decisiones de arquitectura

Esta sección resume las decisiones que considero más relevantes y el motivo detrás de cada una. No las planteo como reglas universales; responden al alcance y al tipo de problema de este reto.

## 1. Plantillas en base de datos para endosos

**Decisión:** mover orden, etiquetas, campos origen, defaults y eventos a PostgreSQL.

**Motivo:** la variabilidad pertenece al producto/tipo de endoso. Si se codifica con condicionales, cada alta o ajuste de configuración obliga a modificar y desplegar el servicio.

**Trade-off:** la flexibilidad aumenta, pero también aparece la necesidad de gobernar versiones y cambios de plantilla. En un escenario real agregaría administración y auditoría.

## 2. PostgreSQL en lugar de configuración estática

**Decisión:** persistir plantillas en PostgreSQL y no en archivos JSON dentro de la imagen.

**Motivo:** permite versionar, consultar, activar y evolucionar configuraciones sin reconstruir el artefacto.

**Trade-off:** el traductor pasa a depender de una base de datos y debe manejar su disponibilidad.

## 3. Dijkstra desacoplado del HTTP

**Decisión:** mantener el algoritmo en una capa independiente.

**Motivo:** el cálculo de caminos no debe conocer status codes, JSON ni handlers. Esto simplifica pruebas y permite reutilización.

## 4. Go para Routing

**Decisión:** implementar el segundo ejercicio como un servicio Go independiente.

**Motivo:** es el stack solicitado para el ejercicio y permite mantener una implementación simple para el algoritmo, con bajo overhead de runtime.

No elegí Go porque Node no pudiera resolverlo; lo utilicé como parte del límite tecnológico planteado por el reto.

## 5. Cloud Run y no Kubernetes

**Decisión:** plantear el despliegue sobre Cloud Run.

**Motivo:** los servicios son pequeños y stateless. Administrar un clúster no aporta valor para este alcance.

**Trade-off:** si aparecieran necesidades avanzadas de networking, sidecars, workloads persistentes o controles específicos de scheduling, revisaría la decisión.

## 6. Secret Manager

**Decisión:** separar secretos de código e imágenes.

**Motivo:** la contraseña de base de datos debe ser referenciada por el runtime y no quedar hardcodeada en el repositorio.

## 7. APIs privadas detrás de un punto de entrada

**Decisión:** Endorsement y Routing quedan no anónimos en Terraform.

**Motivo:** no quiero que los backends sean públicos de manera directa.

**Pendiente:** cerrar API Gateway/JWT y el flujo de autenticación antes de aplicar Terraform.

## 8. Asincronía para préstamos

**Decisión:** desacoplar la aceptación de la solicitud del procesamiento contra INARI.

**Motivo:** el problema funcional es que el cliente confunde un timeout de transporte con el resultado de la operación de negocio.

La operación debe poder continuar y consultarse sin mantener el request esperando.

## 9. Idempotencia persistida

**Decisión:** utilizar `Idempotency-Key` más restricción única en persistencia.

**Motivo:** un chequeo en memoria no protege frente a concurrencia ni múltiples instancias.

## 10. Outbox transaccional

**Decisión:** guardar operación y evento de publicación en la misma transacción.

**Motivo:** evitar inconsistencias entre persistencia y mensajería.

## 11. Docker Compose como evidencia local

**Decisión:** integrar servicios, base, frontend y documentación en un solo compose.

**Motivo:** facilitar la revisión del reto y demostrar que los componentes realmente funcionan en conjunto.

No considero Docker Compose como la arquitectura productiva; es el mecanismo de ejecución local.

## 12. No activar CI/CD automático en esta etapa

**Decisión:** mantener los quality gates como comandos locales reproducibles.

**Motivo:** el pipeline no es necesario para demostrar la funcionalidad actual y no forma parte del alcance que quise automatizar en esta etapa.

Los repositorios ya exponen comandos de lint, tests, coverage y build que pueden reutilizarse cuando se habilite automatización.