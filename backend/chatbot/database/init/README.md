# Database Initialization Scripts

This directory contains SQL scripts that run automatically when the SQL Server container is first created.

## Automatic Execution

The scripts in this directory are executed in alphabetical order when the SQL Server container starts for the first time:

1. `01-create-database.sql` - Creates the QTasks database
2. `02-create-user.sql` - Sets up database users (optional)

## Manual Script Execution

If you need to run scripts manually after the container is already running:

```bash
# Copy a SQL script to the container
docker cp your-script.sql qprocess_sqlserver:/tmp/

# Execute the script
docker exec -it qprocess_sqlserver /opt/mssql-tools/bin/sqlcmd \
  -S localhost -U sa -P YourStrong@Passw0rd \
  -i /tmp/your-script.sql
```

## Django Migrations

Note that Django will create all the necessary tables through migrations. These scripts only:
- Create the database
- Set up users and permissions
- Configure database options

Django migrations handle:
- Creating tables
- Creating indexes
- Setting up relationships
- Data migrations

## Adding Custom Scripts

To add your own initialization scripts:

1. Create a new `.sql` file in this directory
2. Prefix it with a number to control execution order (e.g., `03-my-script.sql`)
3. Rebuild the SQL Server container:
   ```bash
   docker-compose down
   docker volume rm chatbot_sqlserver_data
   docker-compose up -d sqlserver
   ```

## Important Notes

- Scripts only run on **first startup** (when the data volume is empty)
- To re-run scripts, you must delete the volume: `docker volume rm chatbot_sqlserver_data`
- Always backup your data before removing volumes
- The SA password is set via environment variables in docker-compose.yml

