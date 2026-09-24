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

**Decisión:** plantear los servicios aplicativos sobre Cloud Run.

**Motivo:** Endorsement y Routing son pequeños y stateless. Administrar un clúster no aporta valor para este alcance.

**Trade-off:** la incorporación de un gateway autogestionado obliga a revisar con más detalle dónde ejecutarlo y cómo resolver networking, IAM y alta disponibilidad en GCP. Esa decisión se mantiene abierta hasta cerrar el diseño productivo.

## 6. Secret Manager

**Decisión:** separar secretos de código e imágenes.

**Motivo:** credenciales y claves de firma no deben quedar hardcodeadas en el repositorio.

En local, el secreto JWT se genera en `.env` y queda fuera de Git. Para cloud, los secretos deben administrarse con Secret Manager.

## 7. Apache APISIX como punto único de entrada

**Decisión:** incorporar APISIX delante de Endorsement y Routing.

**Motivo:** autenticación, rate limiting y routing son preocupaciones transversales. No quería implementar JWT de una manera en Hapi y de otra distinta en Go.

**Implementación local:** APISIX corre en modo standalone declarativo, sin etcd, Dashboard ni Admin API. Las rutas funcionales usan `jwt-auth` y `limit-count`. Los backends ya no publican puertos al host.

**Trade-off:** un gateway autogestionado ofrece portabilidad y flexibilidad, pero transfiere al equipo responsabilidades de operación que un API Gateway PaaS asumiría. En producción evaluaría esa carga antes de cerrar la topología definitiva.

## 8. JWT de demostración solo para local

**Decisión:** utilizar HS256 y un consumidor de prueba para demostrar el control de acceso local.

**Motivo:** permite comprobar realmente `401`/`200` sin introducir un proveedor de identidad adicional que no forma parte del problema principal del reto.

**Límite:** no considero este script como el emisor de identidad productivo. En producción el token debe provenir de un IdP confiable y el gateway validar la identidad según el estándar acordado.

## 9. Rate limiting en el gateway

**Decisión:** aplicar `limit-count` en APISIX y no dentro de cada backend.

**Motivo:** evita duplicar una política HTTP transversal.

La política local usa contador por instancia. Si APISIX escala horizontalmente, el límite debe respaldarse en almacenamiento compartido para conservar semántica global.

## 10. Asincronía para préstamos

**Decisión:** desacoplar la aceptación de la solicitud del procesamiento contra INARI.

**Motivo:** el problema funcional es que el cliente confunde un timeout de transporte con el resultado de la operación de negocio.

La operación debe poder continuar y consultarse sin mantener el request esperando.

## 11. Idempotencia persistida

**Decisión:** utilizar `Idempotency-Key` más restricción única en persistencia.

**Motivo:** un chequeo en memoria no protege frente a concurrencia ni múltiples instancias.

## 12. Outbox transaccional

**Decisión:** guardar operación y evento de publicación en la misma transacción.

**Motivo:** evitar inconsistencias entre persistencia y mensajería.

## 13. Docker Compose como evidencia local

**Decisión:** integrar gateway, servicios, base, frontend y documentación en un solo compose.

**Motivo:** facilitar la revisión del reto y demostrar que los componentes realmente funcionan en conjunto.

No considero Docker Compose como la arquitectura productiva; es el mecanismo de ejecución local.

## 14. No activar CI/CD automático en esta etapa

**Decisión:** mantener los quality gates como comandos locales reproducibles.

**Motivo:** el pipeline no es necesario para demostrar la funcionalidad actual y no forma parte del alcance que quise automatizar en esta etapa.

Los repositorios ya exponen comandos de lint, tests, coverage y build que pueden reutilizarse cuando se habilite automatización.
