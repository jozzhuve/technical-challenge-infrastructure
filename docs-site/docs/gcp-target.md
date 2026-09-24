---
title: Arquitectura objetivo en GCP
---

# Arquitectura objetivo en GCP

La infraestructura está modelada con Terraform para GCP. La intención fue dejar una base pequeña, reproducible y coherente con el alcance del reto, sin asumir como cerradas decisiones que todavía requieren validación operativa.

## Componentes considerados

```text
Artifact Registry
Cloud Run - Web
Cloud Run - Endorsement
Cloud Run - Routing
Cloud SQL - PostgreSQL 16
Secret Manager
Service Accounts / IAM
Apache APISIX como gateway
```

## Artifact Registry

Se utiliza como repositorio de imágenes Docker.

La idea es que cada aplicación genere su propia imagen y Terraform reciba la referencia a la imagen ya construida. De esta manera la infraestructura no necesita conocer cómo se compila cada runtime.

## Cloud Run

Elegí Cloud Run para los servicios aplicativos porque son stateless a nivel de aplicación y no existe, para este reto, una necesidad que justifique administrar Kubernetes.

Los servicios actualmente definidos son:

- `technical-challenge-web`;
- `endorsement-service`;
- `routing-service`.

Endorsement y Routing se definieron sin acceso anónimo. El frontend sí queda público.

## Cloud SQL

Endorsement requiere persistencia para las plantillas dinámicas. La base está definida como PostgreSQL 16.

La aplicación se conecta mediante el socket de Cloud SQL expuesto al servicio Cloud Run:

```text
/cloudsql/<connection_name>
```

La service account del servicio Endorsement recibe `roles/cloudsql.client`.

Para el ejercicio dejé una instancia pequeña y zonal. No asumiría esa configuración como sizing productivo: la selección final debe responder a volumetría, RTO/RPO, disponibilidad requerida y costo aceptable.

## Secret Manager

La contraseña de base de datos no se inyecta como valor plano dentro de la definición de Cloud Run.

Terraform genera una contraseña, crea el secreto y el módulo de Cloud Run lo consume como variable de entorno referenciada desde Secret Manager.

Hay un punto operativo importante: el valor generado sigue formando parte del state de Terraform. Por eso, en una implementación real, el state debe mantenerse en un backend remoto con acceso restringido y controles acordes al entorno.

## Punto de entrada de APIs

La decisión de gateway ya se cerró para el diseño: utilizar Apache APISIX para centralizar autenticación JWT, rate limiting y routing.

```text
Internet
   |
   v
Web / Cliente
   |
   v
Apache APISIX
   |
   +----> Endorsement privado
   |
   +----> Routing privado
```

Lo que todavía no doy por cerrado es el runtime productivo de APISIX en GCP. En local corre en modo standalone porque es suficiente para el reto, pero antes de provisionar cloud hay que definir una topología que resuelva correctamente alta disponibilidad, IAM, conectividad privada, TLS, DNS, observabilidad y gestión de configuración.

No considero correcto afirmar que basta con trasladar el contenedor de APISIX de Docker Compose a Cloud Run sin revisar esas condiciones.

## Identidad

El JWT local utiliza un consumidor y un secreto HS256 únicamente para demostrar el control de acceso.

En producción el token debería ser emitido por un IdP confiable. APISIX validaría esos tokens utilizando la configuración correspondiente al proveedor de identidad definido por la organización.

El secreto local no debe reutilizarse en cloud.

## Inicialización del esquema

En local, PostgreSQL ejecuta `001-schema.sql` y `002-seed.sql` mediante `docker-entrypoint-initdb.d`.

Ese mecanismo no aplica a Cloud SQL. Antes del despliegue real migraría esos scripts a un mecanismo controlado de migraciones o a un job de inicialización ejecutado explícitamente durante el release.

No dejaría el esquema productivo dependiendo de `synchronize=true` de TypeORM.

## Qué está listo y qué no

### Listo

- APIs base de GCP requeridas;
- Artifact Registry;
- Cloud SQL;
- base y usuario;
- Secret Manager;
- Cloud Run para los tres componentes aplicativos;
- service accounts;
- permiso Cloud SQL Client para Endorsement;
- patrón de gateway implementado localmente con APISIX;
- JWT y rate limiting demostrables localmente.

### Antes de `terraform apply`

- definir runtime y alta disponibilidad de APISIX en GCP;
- definir IAM y conectividad privada gateway -> Cloud Run;
- definir IdP definitivo y validación de tokens;
- definir TLS y DNS;
- definir URL pública consumida por el frontend;
- definir estrategia de migración de base de datos;
- revisar networking de Cloud SQL según requerimientos de seguridad;
- definir backend remoto del state;
- revisar sizing, región y política de backups.

Por esa razón Terraform se considera una base de despliegue y no una infraestructura ya provisionada.
