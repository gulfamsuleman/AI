-- Create additional database user (optional)
-- By default, we use 'sa' account for Docker setup
-- Uncomment and modify if you want to create a specific user

USE master;
GO

-- Uncomment to create a specific user for the application
/*
IF NOT EXISTS (SELECT name FROM sys.sql_logins WHERE name = 'qprocess_user')
BEGIN
    CREATE LOGIN qprocess_user WITH PASSWORD = 'YourUserPassword123!';
    PRINT 'Login qprocess_user created successfully.';
END
GO

USE QTasks;
GO

IF NOT EXISTS (SELECT name FROM sys.database_principals WHERE name = 'qprocess_user')
BEGIN
    CREATE USER qprocess_user FOR LOGIN qprocess_user;
    ALTER ROLE db_owner ADD MEMBER qprocess_user;
    PRINT 'User qprocess_user added to QTasks database.';
END
GO
*/

PRINT 'User setup complete (using sa account by default).';
GO

