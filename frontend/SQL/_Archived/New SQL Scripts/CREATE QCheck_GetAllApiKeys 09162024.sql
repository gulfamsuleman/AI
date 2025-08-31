USE [QTasks]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[QCheck_GetAllApiKeys]
@ApiKey NVARCHAR(100)
AS
BEGIN
 SELECT 
	 ApiKey
	,RequestingUser
	,ApprovedBy
	,Intent
	,IssuedDate
	,ExpiredDate
	,IsRevoked
FROM QCheck_APIKeyStore

END