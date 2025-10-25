#!/bin/bash

# Wait for SQL Server to start
echo "Waiting for SQL Server to start..."
sleep 30s

# SQL Server tools path (new in SQL Server 2022)
SQLCMD="/opt/mssql-tools18/bin/sqlcmd"
SQLPACKAGE="/opt/mssql-tools18/bin/sqlpackage"

# Check if .bacpac file exists
BACPAC_FILE="/var/opt/mssql/backups/Qtasks.bacpac"

# Check if database already exists
DB_EXISTS=$($SQLCMD -S localhost -U sa -P $SA_PASSWORD -C -Q "SET NOCOUNT ON; SELECT DB_ID('QTasks')" -h -1 2>/dev/null)

if [ ! -z "$DB_EXISTS" ] && [ "$DB_EXISTS" != "NULL" ]; then
    echo "✓ QTasks database already exists. Skipping initialization."
elif [ -f "$BACPAC_FILE" ]; then
    echo "Found QTasks.bacpac file. Restoring database..."
    
    # Import the .bacpac file using SqlPackage (if available)
    if [ -f "$SQLPACKAGE" ]; then
        $SQLPACKAGE \
            /Action:Import \
            /SourceFile:"$BACPAC_FILE" \
            /TargetDatabaseName:QTasks \
            /TargetServerName:localhost \
            /TargetUser:sa \
            /TargetPassword:$SA_PASSWORD \
            /TargetTrustServerCertificate:True
        
        if [ $? -eq 0 ]; then
            echo "✓ Successfully restored QTasks database from .bacpac"
        else
            echo "✗ Error restoring database from .bacpac - check if file is valid"
        fi
    else
        echo "✗ SqlPackage not available. Cannot import .bacpac file."
        echo "Creating empty database instead..."
        $SQLCMD -S localhost -U sa -P $SA_PASSWORD -C -Q \
            "CREATE DATABASE QTasks;"
    fi
else
    echo "No .bacpac file found. Running SQL initialization scripts..."
    
    # Run the initialization scripts
    for script in /docker-entrypoint-initdb.d/*.sql
    do
        if [ -f "$script" ]; then
            echo "Executing $script..."
            $SQLCMD -S localhost -U sa -P $SA_PASSWORD -C -d master -i "$script"
            
            if [ $? -eq 0 ]; then
                echo "✓ Successfully executed $script"
            else
                echo "✗ Error executing $script"
            fi
        fi
    done
fi

echo "Database initialization complete!"

