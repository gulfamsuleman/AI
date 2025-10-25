#!/bin/bash

# Exit on error
set -e

echo "Starting Django application..."

# Wait for database to be ready (optional, uncomment if needed)
# python manage.py wait_for_db

# Run database migrations
echo "Running database migrations..."
python manage.py migrate --noinput || echo "Migrations failed or not needed"

# Collect static files
echo "Collecting static files..."
python manage.py collectstatic --noinput || echo "Static files collection failed or not needed"

# Create logs directory if it doesn't exist
mkdir -p logs

# Start server
echo "Starting Django development server..."
exec python manage.py runserver 0.0.0.0:8000

