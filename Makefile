.PHONY: up down logs ps validate fmt plan

up:
	docker compose up --build -d

down:
	docker compose down

logs:
	docker compose logs -f

ps:
	docker compose ps

validate:
	terraform -chdir=terraform/environments/dev init -backend=false
	terraform -chdir=terraform/environments/dev validate

fmt:
	terraform fmt -recursive terraform

plan:
	terraform -chdir=terraform/environments/dev plan
