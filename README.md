# Infraestructura y documentación del reto

Repositorio transversal para ejecución local, Apache APISIX, Terraform, colección Postman y documentación de arquitectura.

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

## Seguridad local

APISIX funciona en modo standalone y protege las operaciones funcionales con JWT. El secreto de firma no se versiona.

Antes de levantar la solución por primera vez:

```bash
cd technical-challenge-infrastructure
./scripts/bootstrap-security.sh
```

El script genera `.env` con `APISIX_JWT_SECRET` y el archivo queda excluido de Git.

Para generar un JWT de prueba con una vigencia de una hora:

```bash
TOKEN=$(./scripts/generate-jwt.sh)
echo "$TOKEN"
```

## Levantar toda la solución

Desde `technical-challenge-infrastructure`:

```bash
docker compose up --build -d
```

Servicios disponibles:

- Frontend: `http://localhost:3000`
- Docusaurus: `http://localhost:3001`
- Apache APISIX: `http://localhost:9080`
- PostgreSQL: `localhost:5433`

Endorsement y Routing ya no publican puertos al host. Solo son alcanzables dentro de la red de Docker y APISIX es el punto de entrada para las operaciones funcionales.

Health checks a través del gateway:

```bash
curl http://localhost:9080/health/endorsement
curl http://localhost:9080/health/routing
```

Una operación sin JWT debe ser rechazada:

```bash
curl -i \
  -X POST http://localhost:9080/api/v1/routes/optimal \
  -H 'Content-Type: application/json' \
  -d '{}'
```

Respuesta esperada: `401 Unauthorized`.

## Frontend

El frontend también consume las APIs por APISIX. Genera un token con `./scripts/generate-jwt.sh`, abre `http://localhost:3000` y pégalo en la sección de acceso por API Gateway. El token se guarda únicamente en `sessionStorage` y se elimina al cerrar la sesión del navegador.

## Postman / Newman

Importar `postman/technical-challenge.postman_collection.json` o ejecutar:

```bash
TOKEN=$(./scripts/generate-jwt.sh)
npx --yes newman run postman/technical-challenge.postman_collection.json \
  --env-var jwtToken="$TOKEN"
```

La colección valida health checks por APISIX, rechazo sin JWT, casos exitosos y errores funcionales controlados.

## APISIX

Se utiliza Apache APISIX 3.18 en modo standalone declarativo, sin etcd ni Admin API. La configuración se encuentra en:

```text
apisix/config.yaml
apisix/apisix.yaml
```

Las rutas funcionales tienen:

- validación JWT mediante `jwt-auth`;
- rate limiting mediante `limit-count`;
- routing hacia Endorsement y Routing dentro de la red Docker.

Los endpoints de health permanecen sin JWT para facilitar probes operacionales.

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

No se ejecuta `terraform apply` hasta revisar el plan y cerrar la topología final de APISIX en GCP, IAM y conectividad privada hacia los backends.

## Docusaurus

Docusaurus se construye y publica como sitio estático dentro del mismo Docker Compose mediante Nginx.

Con toda la solución levantada está disponible en:

```text
http://localhost:3001
```

También puede ejecutarse de forma independiente para edición local:

```bash
cd docs-site
npm install
npm run start -- --port 3001
```

Para detener la solución:

```bash
docker compose down
```
