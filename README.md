# Infraestructura y documentación del reto

Repositorio transversal para ejecución local, Terraform, colección Postman y documentación de arquitectura.

## Estructura esperada de clones

Los cuatro repositorios deben quedar como carpetas hermanas:

```text
technical-challenge/
├── technical-challenge-endorsement/
├── technical-challenge-routing/
├── technical-challenge-web/
└── technical-challenge-infrastructure/
```

Desde `technical-challenge/` valida la estructura:

```bash
./technical-challenge-infrastructure/scripts/check-layout.sh
```

## Levantar toda la solución

Desde la carpeta que contiene los cuatro clones:

```bash
docker compose -f technical-challenge-infrastructure/docker-compose.yml up --build -d
```

Servicios disponibles:

- Frontend: `http://localhost:3000`
- Endorsement API: `http://localhost:8080`
- Routing API: `http://localhost:8081`
- PostgreSQL: `localhost:5432`

Para detener todo:

```bash
docker compose -f technical-challenge-infrastructure/docker-compose.yml down
```

## Postman

Importar `postman/technical-challenge.postman_collection.json`. La colección incluye health checks, casos exitosos y escenarios de error controlado para ambos servicios.

## Terraform

La infraestructura objetivo utiliza GCP con Cloud Run, Cloud SQL, Artifact Registry y Secret Manager. La contraseña de PostgreSQL se genera en Terraform, se almacena en Secret Manager y se inyecta en Cloud Run mediante referencia al secreto.

```bash
cd terraform/environments/dev
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform fmt -check -recursive
terraform validate
terraform plan
```

No se ejecuta `terraform apply` hasta revisar el plan y cerrar API Gateway/JWT.

## Docusaurus

```bash
cd docs-site
npm install
npm run start
```

La documentación contiene la visión general, arquitectura y propuesta TO-BE del ejercicio de préstamos.
