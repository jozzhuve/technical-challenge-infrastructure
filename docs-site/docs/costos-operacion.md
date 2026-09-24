---
title: Costos y operación
---

# Costos y operación

No hice una estimación monetaria cerrada porque todavía no existe una volumetría acordada ni se ha ejecutado el despliegue. Sí dejé identificados los componentes que realmente mueven el costo y cómo los controlaría.

## Cloud Run

Para Web, Endorsement y Routing el costo depende principalmente de:

- cantidad de requests;
- tiempo de CPU y memoria por request;
- concurrencia configurada;
- instancias mínimas;
- tráfico de salida.

Para este reto no fijaría instancias mínimas salvo que exista un requisito de latencia que justifique eliminar cold starts. Mantener `min instances = 0` reduce costo en ambientes de baja demanda, a cambio de aceptar latencia de arranque.

## Cloud SQL

Es el componente con costo más constante porque mantiene capacidad provisionada aunque no haya tráfico.

La configuración actual usa una instancia pequeña y zonal como base de desarrollo. No asumiría ese sizing para producción.

Antes de dimensionar revisaría:

- número de plantillas y frecuencia de lectura;
- conexiones concurrentes;
- necesidad de alta disponibilidad;
- RPO/RTO;
- almacenamiento y crecimiento;
- backups y retención.

## Secret Manager

El volumen de secretos de esta solución es bajo. Lo importante no es optimizar unos pocos accesos sino evitar duplicar secretos o consultarlos innecesariamente en cada operación si el runtime puede resolverlos al iniciar la instancia.

## Artifact Registry

El costo depende del almacenamiento de imágenes y del tráfico asociado. Mantendría políticas de retención para evitar acumular imágenes antiguas que ya no tienen valor operativo.

## API Gateway

Antes de incorporarlo revisaría el volumen esperado, pero en este caso su valor principal es centralizar autenticación y exposición de APIs. No lo usaría solo como una caja adicional en el diagrama.

## Decisiones orientadas a costo

La arquitectura evita componentes administrados que no son necesarios para el alcance actual:

- no hay clúster Kubernetes;
- no hay Redis sin un caso medido;
- no hay broker para los ejercicios 1 y 2;
- no hay service mesh;
- no hay motor de reglas externo.

En el ejercicio 3 sí planteo mensajería porque resuelve un problema concreto de desacoplamiento y reintentos. Ahí el costo adicional tiene una justificación funcional.

## Qué mediría después del despliegue

```text
requests por servicio
CPU / memoria
latencia p95 y p99
instancias activas
conexiones a PostgreSQL
almacenamiento Cloud SQL
tráfico de salida
errores / retries
```

Con esas métricas ajustaría concurrencia, memoria, CPU y tamaño de base. Prefiero hacer ese sizing con evidencia antes que sobreaprovisionar desde el inicio.