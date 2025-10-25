-- SQL Server Database Initialization Script
-- This script creates the QTasks database and sets up initial configuration

USE master;
GO

-- Create the QTasks database if it doesn't exist
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'QTasks')
BEGIN
    CREATE DATABASE QTasks;
    PRINT 'Database QTasks created successfully.';
END
ELSE
BEGIN
    PRINT 'Database QTasks already exists.';
END
GO

-- Switch to the QTasks database
USE QTasks;
GO

-- Set database options for better performance and compatibility
ALTER DATABASE QTasks SET RECOVERY SIMPLE;
ALTER DATABASE QTasks SET AUTO_CREATE_STATISTICS ON;
ALTER DATABASE QTasks SET AUTO_UPDATE_STATISTICS ON;
GO

PRINT 'Database initialization complete.';
GO

