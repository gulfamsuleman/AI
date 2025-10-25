# Docker Setup for QProcess Chatbot Backend

This document provides instructions for running the QProcess Chatbot backend using Docker.

## Prerequisites

- Docker installed on your system
- Docker Compose installed (usually comes with Docker Desktop)
- SQL Server database accessible from the container
- Anthropic API key

## Quick Start

### 1. Configure Environment Variables

Copy the example environment file and update it with your configuration:

```bash
cp .env.example .env
```

Edit `.env` and set:
- `ANTHROPIC_API_KEY`: Your Claude API key
- `DB_HOST`: Database host (use `host.docker.internal` to access SQL Server on your host machine)
- `DB_NAME`, `DB_USER`, `DB_PASSWORD`: Database credentials
- `SECRET_KEY`: Django secret key for production

### 2. Build and Run with Docker Compose

```bash
# Build the image
docker-compose build

# Start the container
docker-compose up -d

# View logs
docker-compose logs -f backend
```

The backend will be available at `http://localhost:8000`

### 3. Stop the Container

```bash
docker-compose down
```

## Alternative: Using Dockerfile Directly

### Build the Docker Image

```bash
docker build -t qprocess-chatbot-backend .
```

### Run the Container

```bash
docker run -d \
  -p 8000:8000 \
  -e ANTHROPIC_API_KEY=your-api-key \
  -e DB_HOST=host.docker.internal \
  -e DB_NAME=QTasks \
  --name qprocess-backend \
  --add-host host.docker.internal:host-gateway \
  qprocess-chatbot-backend
```

## Connecting to SQL Server on Host Machine

### Windows

When running Docker on Windows and connecting to SQL Server on the host:

1. Use `host.docker.internal` as the `DB_HOST` in your `.env` file
2. Ensure SQL Server is configured to accept TCP/IP connections
3. Configure SQL Server to allow remote connections:
   - Open SQL Server Configuration Manager
   - Enable TCP/IP protocol for SQL Server
   - Restart SQL Server service
4. If using Windows Authentication, you'll need to use SQL Server Authentication instead in Docker

### SQL Server Configuration

For SQL Server Authentication (recommended for Docker):

```env
DB_USER=your_sql_username
DB_PASSWORD=your_sql_password
DB_HOST=host.docker.internal
```

## Useful Docker Commands

```bash
# View running containers
docker ps

# View container logs
docker logs qprocess_chatbot_backend

# Execute commands in the container
docker exec -it qprocess_chatbot_backend python manage.py shell

# Run migrations
docker exec -it qprocess_chatbot_backend python manage.py migrate

# Create superuser
docker exec -it qprocess_chatbot_backend python manage.py createsuperuser

# Stop the container
docker stop qprocess_chatbot_backend

# Remove the container
docker rm qprocess_chatbot_backend

# Remove the image
docker rmi qprocess-chatbot-backend
```

## Volume Mounts

The following directories are mounted as volumes:
- `./logs`: Application logs
- `./sessions`: Session data
- `./staticfiles`: Static files

These persist even when the container is removed.

## Troubleshooting

### Cannot connect to database

1. Verify SQL Server is running and accessible
2. Check that TCP/IP is enabled in SQL Server Configuration Manager
3. Ensure firewall allows connections on port 1433
4. Try using SQL Server Authentication instead of Windows Authentication

### Permission issues with volumes

On Linux/Mac, you may need to adjust permissions:

```bash
chmod -R 777 logs sessions staticfiles
```

### Container exits immediately

Check the logs:

```bash
docker logs qprocess_chatbot_backend
```

Common issues:
- Missing environment variables
- Database connection failures
- Missing dependencies

## Production Considerations

For production deployment:

1. Use a proper web server (Gunicorn/uWSGI) instead of Django's development server
2. Set `DEBUG=False` in environment variables
3. Configure proper `ALLOWED_HOSTS`
4. Use secrets management for sensitive data
5. Set up proper logging and monitoring
6. Use a reverse proxy (nginx) in front of Django
7. Consider using managed database services

### Production Dockerfile Example

Update the CMD in Dockerfile to use Gunicorn:

```dockerfile
# Install gunicorn
RUN pip install gunicorn

# Update CMD
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "4", "chatbot.wsgi:application"]
```

## Environment Variables Reference

| Variable | Description | Default |
|----------|-------------|---------|
| `DEBUG` | Enable debug mode | `True` |
| `SECRET_KEY` | Django secret key | (required) |
| `ALLOWED_HOSTS` | Comma-separated allowed hosts | `*` |
| `DB_ENGINE` | Database engine | `mssql` |
| `DB_NAME` | Database name | `QTasks` |
| `DB_USER` | Database user | (empty for trusted connection) |
| `DB_PASSWORD` | Database password | (empty for trusted connection) |
| `DB_HOST` | Database host | `host.docker.internal` |
| `DB_PORT` | Database port | `1433` |
| `ANTHROPIC_API_KEY` | Claude API key | (required) |
| `CORS_ALLOWED_ORIGINS` | Allowed CORS origins | (optional) |

