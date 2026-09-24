---
title: Riesgos y evolución
---

# Riesgos y evolución

La solución cubre el alcance funcional del reto, pero antes de considerarla lista para producción cerraría varios puntos. Prefiero dejarlos visibles porque forman parte de la decisión de arquitectura.

## 1. Exposición de APIs en GCP

Actualmente Terraform deja Endorsement y Routing como servicios no anónimos. Falta cerrar el punto de entrada mediante API Gateway/JWT y definir cómo el frontend obtiene y propaga identidad.

**Acción:** terminar el contrato de autenticación antes de ejecutar `terraform apply`.

## 2. Proxy local del frontend

Nginx funciona en Docker Compose porque puede resolver los nombres internos `endorsement` y `routing`.

Eso no aplica automáticamente a Cloud Run.

**Acción:** el frontend desplegado debe consumir el gateway o URLs configuradas para el entorno. No trasladaría el proxy local tal cual a GCP.

## 3. Migraciones de PostgreSQL

Los scripts locales se ejecutan al crear el contenedor de PostgreSQL, pero Cloud SQL no utiliza `docker-entrypoint-initdb.d`.

**Acción:** convertir esquema y seed necesarios en migraciones versionadas o en un job controlado de inicialización.

## 4. Gobierno de plantillas

La flexibilidad del traductor depende de la calidad de la configuración almacenada.

**Riesgo:** una plantilla mal publicada puede afectar la estructura enviada al core sin requerir un cambio de código.

**Acción:** incorporar versionado, auditoría, validación previa y eventualmente un backoffice con flujo de publicación.

## 5. Disponibilidad de PostgreSQL

El traductor necesita consultar la plantilla para procesar la solicitud.

**Acción:** definir disponibilidad requerida, pool de conexiones, timeouts y estrategia de recuperación. Si la lectura de plantillas se convierte en un cuello de botella, evaluaría caché con invalidación controlada, pero no la agregaría antes de medir.

## 6. Volumetría de Routing

El grafo viaja actualmente en cada request porque así se mantiene flexible el ejercicio.

**Riesgo:** para grafos grandes, serializar y procesar toda la red en cada llamada deja de ser eficiente.

**Acción:** en una evolución real movería el grafo a una fuente persistida o proveedor geoespacial y revisaría el algoritmo según el tamaño y tipo de datos.

## 7. Préstamos e idempotencia extremo a extremo

La propuesta controla duplicados en nuestra capa, pero el nivel más fuerte de protección se obtiene si INARI también acepta una clave idempotente o referencia única.

**Acción:** validar capacidades de INARI. Si no existen, mantener correlación y conciliación para detectar estados ambiguos.

## 8. Terraform state

La contraseña generada para PostgreSQL forma parte del state de Terraform aunque luego se almacene en Secret Manager.

**Acción:** utilizar backend remoto con cifrado, control de acceso y versionado antes de trabajar con ambientes reales.

## 9. Hardening de seguridad

Para local se permite CORS abierto y se publican puertos directamente.

**Acción:** restringir orígenes, revisar headers, límites de payload, rate limiting y políticas del gateway según el entorno real.

## 10. Pruebas de carga y resiliencia

La validación actual demuestra funcionalidad, no capacidad.

**Acción:** definir volumetría esperada y medir:

- latencia p50/p95/p99;
- concurrencia;
- consumo de CPU y memoria;
- pool de conexiones;
- comportamiento ante base lenta;
- timeouts;
- retry storms;
- escalado de Cloud Run.

## Orden en el que continuaría

Si tuviera que llevar esta solución al siguiente nivel, seguiría este orden:

1. Cerrar API Gateway/JWT y comunicación del frontend.
2. Implementar migraciones controladas.
3. Validar Terraform con `plan` y desplegar un ambiente de prueba.
4. Ejecutar pruebas E2E sobre GCP.
5. Incorporar observabilidad y alertas.
6. Ejecutar pruebas de carga.
7. Ajustar sizing y costos con evidencia.
8. Recién después activar automatización de despliegue.

Ese orden mantiene el foco en riesgos reales antes de agregar más componentes.