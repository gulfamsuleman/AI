USE [QTasks]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[QCheck_RetrieveAPIKey]
	@ID NVARCHAR(100) = null,
	@ApiKey NVARCHAR(100) = null
AS
BEGIN
	 SELECT ID 
		,Api_Key
		,Requestor
		,Approver
		,OnBehalfOf
		,Intent
		,Issued
		,Expires
		,NotBefore
		,IsRevoked
	FROM QCheck_APIKeyStore
	WHERE (@ApiKey IS NULL OR Api_Key = @ApiKey)
		AND (@ID IS NULL OR ID = @ID)
END