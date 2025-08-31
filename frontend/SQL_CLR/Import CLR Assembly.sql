--DROPS

/*
USE QTasks_DEV20241014

GO
DROP Function dbo.ConvertTimeToUtc;
DROP Function dbo.ConvertTimeFromUtc;
DROP Function dbo.ConvertTime;
DROP Function dbo.FormatTime;
DROP ASSEMBLY TimeZoneProcs;
DROP ASSEMBLY TimeZoneConverter;
DROP ASSEMBLY [System.Runtime.InteropServices.RuntimeInformation];
GO
*/

/*
USE [master]
GO

ALTER AUTHORIZATION ON DATABASE::PFSProcess TO sa;

ALTER DATABASE QTasks_DEV20241014 SET TRUSTWORTHY OFF
GO

PRINT 'Making sure that SQLCLR is enabled...';
IF (EXISTS(
            SELECT *
            FROM   sys.configurations sc
            WHERE  sc.[configuration_id] = 1562 -- "clr enabled"
            AND    sc.[value_in_use] = 0
    ))
BEGIN
    PRINT 'Enabling SQLCLR...';
    EXEC sp_configure N'clr enabled', 1; RECONFIGURE;
END;

PRINT 'Making sure that SQLCLR "strict security" is enabled...';
IF (EXISTS(
            SELECT *
            FROM   sys.configurations sc
            WHERE  sc.[configuration_id] = 518 -- "show advanced options"
            AND    sc.[value_in_use] = 0
    ))
BEGIN
    PRINT ' Showing advanced options...';
    EXEC sp_configure N'show advanced options', 1; RECONFIGURE;
END;
 
 
IF (EXISTS(
            SELECT *
            FROM   sys.configurations sc
            WHERE  sc.[configuration_id] = 1587 -- "clr strict security"
            AND    sc.[value_in_use] = 0
    ))
BEGIN
    PRINT ' Enabling CLR strict security...';
    EXEC sp_configure N'clr strict security', 1; RECONFIGURE;
END
GO

*/
/*
USE _Util
GO

PRINT ' TEMPORARILY Altering Database to set TRUSTWORTHY=ON (to get assembly in place)...';
ALTER DATABASE _Util
    SET TRUSTWORTHY ON;

PRINT 'Creating Assemblies...';

CREATE ASSEMBLY [System.Runtime.InteropServices.RuntimeInformation]
Authorization [dbo]
FROM '\\awsc-sql-02\c$\Windows\Microsoft.NET\assembly\GAC_MSIL\System.Runtime.InteropServices.RuntimeInformation\v4.0_4.0.0.0__b03f5f7f11d50a3a\System.Runtime.InteropServices.RuntimeInformation.dll'
WITH PERMISSION_SET = UNSAFE
GO

CREATE ASSEMBLY TimeZoneConverter
Authorization [dbo]
FROM 'c:\scripts\SQL_CLR\TimeZoneConverter.dll'
WITH PERMISSION_SET = UNSAFE
GO

CREATE ASSEMBLY TimeZoneProcs
Authorization [dbo]
FROM 'c:\scripts\SQL_CLR\TimeZoneSqlProcs.dll'
WITH PERMISSION_SET = UNSAFE
GO

PRINT ' Altering Database to set TRUSTWORTHY back to OFF...';
ALTER DATABASE _Util
    SET TRUSTWORTHY OFF
GO

PRINT ' Creating Certificate...';
--DROP CERTIFICATE [CLR-QTrustedAssemblies-Cert]
GO
CREATE CERTIFICATE [CLR-QTrustedAssemblies-Cert]
    ENCRYPTION BY PASSWORD = 'Show Closer Went $everal'
    WITH SUBJECT = 'SQL CLR Assembly Signing',
    EXPIRY_DATE = '2099-12-31';
GO


ADD SIGNATURE
TO ASSEMBLY::[System.Runtime.InteropServices.RuntimeInformation]
BY CERTIFICATE [CLR-QTrustedAssemblies-Cert]
WITH PASSWORD = 'Show Closer Went $everal'
GO
ADD SIGNATURE
TO ASSEMBLY::[TimeZoneConverter]
BY CERTIFICATE [CLR-QTrustedAssemblies-Cert]
WITH PASSWORD = 'Show Closer Went $everal'
GO
ADD SIGNATURE
TO ASSEMBLY::[TimeZoneProcs]
BY CERTIFICATE [CLR-QTrustedAssemblies-Cert]
WITH PASSWORD = 'Show Closer Went $everal'
GO


PRINT ' Copying the Certificate to [master]...';
DECLARE @PublicKey VARBINARY(MAX),
        @SQL NVARCHAR(MAX);
 
SET @PublicKey = CERTENCODED(CERT_ID(N'CLR-QTrustedAssemblies-Cert'));
 
SET @SQL = N'
DROP LOGIN [CLR-QTrustedAssemblies-Login];
DROP CERTIFICATE [CLR-QTrustedAssemblies-Cert];
CREATE CERTIFICATE [CLR-QTrustedAssemblies-Cert]
    FROM BINARY = ' + CONVERT(NVARCHAR(MAX), @PublicKey, 1) + N';';
 
EXEC [master].[sys].[sp_executesql] @SQL;
GO

PRINT ' Creating permissions Login...';
    EXEC [master].[sys].[sp_executesql] N'
CREATE LOGIN [CLR-QTrustedAssemblies-Login]
    FROM CERTIFICATE [CLR-QTrustedAssemblies-Cert]';
GO

EXEC [master].[sys].[sp_executesql] N'GRANT UNSAFE ASSEMBLY TO [CLR-QTrustedAssemblies-Login]'
GO


CREATE OR ALTER FUNCTION dbo.ConvertTimeToUtc (
	@date nvarchar(255),
	@srcTz nvarchar(255)
) RETURNS NVARCHAR(255)   
AS EXTERNAL NAME [TimeZoneProcs].[TimeZoneSqlProcs.TimeZoneSqlProcs].ConvertTimeToUtc;   
GO

CREATE OR ALTER FUNCTION dbo.ConvertTimeFromUtc (
	@date nvarchar(255),
	@dstTz nvarchar(255)[PHIProcess - Daily Overdue Email]
) RETURNS NVARCHAR(255)   
AS EXTERNAL NAME [TimeZoneProcs].[TimeZoneSqlProcs.TimeZoneSqlProcs].ConvertTimeFromUtc;   
GO

CREATE OR ALTER FUNCTION dbo.ConvertTime (
	@date nvarchar(255),
	@srcTz nvarchar(255),
	@dstTz nvarchar(255)
) RETURNS NVARCHAR(255)   
AS EXTERNAL NAME [TimeZoneProcs].[TimeZoneSqlProcs.TimeZoneSqlProcs].ConvertTime;   
GO

CREATE OR ALTER FUNCTION dbo.FormatTime (
	@date nvarchar(255),
	@localTz nvarchar(255),
	@timezones nvarchar(4000)
) RETURNS NVARCHAR(4000)   
AS EXTERNAL NAME [TimeZoneProcs].[TimeZoneSqlProcs.TimeZoneSqlProcs].FormatTime;   
GO
*/

Use QTasks_DEV20241014
GO

CREATE OR ALTER FUNCTION dbo.ConvertTimeToUtc (
	@date nvarchar(255),
	@srcTz nvarchar(255)
) RETURNS NVARCHAR(255)   
AS BEGIN
	RETURN _Util.dbo.ConvertTimeToUtc(@date, @srcTz);   
END
GO

CREATE OR ALTER FUNCTION dbo.ConvertTimeFromUtc (
	@date nvarchar(255),
	@dstTz nvarchar(255)
) RETURNS NVARCHAR(255)   
AS BEGIN
	RETURN _Util.dbo.ConvertTimeFromUtc(@date, @dstTz);   
END
GO

CREATE OR ALTER FUNCTION dbo.ConvertTime (
	@date nvarchar(255),
	@srcTz nvarchar(255),
	@dstTz nvarchar(255)
) RETURNS NVARCHAR(255)   
AS BEGIN
	RETURN _Util.dbo.ConvertTime(@date, @srcTz, @dstTz);   
END
GO

CREATE OR ALTER FUNCTION dbo.FormatTime (
	@date nvarchar(255),
	@localTz nvarchar(255),
	@timezones nvarchar(4000)
) RETURNS NVARCHAR(4000)   
AS BEGIN
	RETURN _Util.dbo.FormatTime(@date, @localTz, @timezones);   
END
GO


select GETUTCDATE() Expected, dbo.ConvertTimeToUtc(GETDATE(), 'America/Chicago') Actual
UNION ALL
select GETDATE(), dbo.ConvertTimeFromUtc(GETUTCDATE(), 'America/Chicago')
UNION ALL
select DateAdd(hour, 1, GETDATE()), dbo.ConvertTime(GETDATE(), 'America/Chicago', 'America/New_York')
UNION ALL
select DateAdd(hour, -1, GETDATE()), dbo.ConvertTime(GETDATE(), 'America/Chicago', 'America/Denver')
UNION ALL
select GETDATE(), dbo.FormatTime(GETUTCDATE(), N'America/Chicago', NULL) N'America/New_York,America/Chicago,America/Denver,America/Phoenix,America/Los_Angeles,Europe/London,Europe/Rome,Australia/Perth')
