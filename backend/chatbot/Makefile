.PHONY: help build up down restart logs shell migrate test clean

help: ## Show this help message
	@echo "Available commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

build: ## Build the Docker image
	docker-compose build

build-prod: ## Build production Docker image
	docker-compose -f docker-compose.prod.yml build

up: ## Start the containers
	docker-compose up

up-d: ## Start containers in detached mode (background)
	docker-compose up -d

up-prod: ## Start production containers
	docker-compose -f docker-compose.prod.yml up -d

down: ## Stop and remove containers
	docker-compose down

down-prod: ## Stop production containers
	docker-compose -f docker-compose.prod.yml down

restart: ## Restart containers
	docker-compose restart

restart-prod: ## Restart production containers
	docker-compose -f docker-compose.prod.yml restart

logs: ## Show container logs
	docker-compose logs -f backend

logs-prod: ## Show production container logs
	docker-compose -f docker-compose.prod.yml logs -f backend

shell: ## Open a shell in the container
	docker-compose exec backend bash

shell-prod: ## Open shell in production container
	docker-compose -f docker-compose.prod.yml exec backend bash

django-shell: ## Open Django shell
	docker-compose exec backend python manage.py shell

migrate: ## Run database migrations
	docker-compose exec backend python manage.py migrate

migrate-prod: ## Run migrations in production
	docker-compose -f docker-compose.prod.yml exec backend python manage.py migrate

makemigrations: ## Create new migrations
	docker-compose exec backend python manage.py makemigrations

createsuperuser: ## Create Django superuser
	docker-compose exec backend python manage.py createsuperuser

collectstatic: ## Collect static files
	docker-compose exec backend python manage.py collectstatic --noinput

test: ## Run tests
	docker-compose exec backend python manage.py test

clean: ## Remove all containers, volumes, and images
	docker-compose down -v
	docker rmi qprocess-chatbot-backend 2>/dev/null || true

clean-all: ## Complete cleanup including production
	docker-compose down -v
	docker-compose -f docker-compose.prod.yml down -v
	docker rmi qprocess-chatbot-backend 2>/dev/null || true

rebuild: ## Rebuild and restart containers
	docker-compose down
	docker-compose build
	docker-compose up -d

ps: ## Show running containers
	docker-compose ps

status: ps ## Alias for ps

inspect: ## Show container details
	docker-compose exec backend python manage.py showmigrations
	docker-compose exec backend python manage.py check

health: ## Check container health
	docker-compose ps
	docker-compose logs --tail=50 backend

# Database specific commands
db-logs: ## Show SQL Server logs
	docker-compose logs -f sqlserver

db-shell: ## Open SQL Server shell (sqlcmd)
	docker-compose exec sqlserver /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P $${SA_PASSWORD}

db-backup: ## Backup database
	@echo "Creating database backup..."
	docker-compose exec sqlserver /opt/mssql-tools/bin/sqlcmd \
		-S localhost -U sa -P $${SA_PASSWORD} \
		-Q "BACKUP DATABASE QTasks TO DISK = '/var/opt/mssql/backups/qtasks_$$(date +%Y%m%d_%H%M%S).bak' WITH FORMAT"
	@echo "Backup complete. Check ./database/backups/ directory"

db-restore: ## Restore database from latest backup
	@echo "Restoring from latest backup..."
	docker-compose exec sqlserver bash -c "\
		latest=\$$(ls -t /var/opt/mssql/backups/*.bak 2>/dev/null | head -1); \
		if [ -n \"\$$latest\" ]; then \
			/opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P $${SA_PASSWORD} \
				-Q \"RESTORE DATABASE QTasks FROM DISK = '\$$latest' WITH REPLACE\"; \
			echo \"Restored from \$$latest\"; \
		else \
			echo \"No backup files found\"; \
		fi"

db-reset: ## Reset database (WARNING: Deletes all data!)
	@echo "WARNING: This will delete all database data!"
	@read -p "Are you sure? (yes/no): " confirm && [ "$$confirm" = "yes" ]
	docker-compose down
	docker volume rm chatbot_sqlserver_data
	docker-compose up -d sqlserver
	@echo "Waiting for SQL Server to initialize..."
	@sleep 40
	docker-compose up -d backend
	docker-compose exec backend python manage.py migrate

clean-db: ## Remove database volume only (WARNING: Deletes all data!)
	docker volume rm chatbot_sqlserver_data 2>/dev/null || true

