USE [QTasks]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[QCheck_RetrieveJwtKeys]
AS
BEGIN
 SELECT 
	BearerToken
,Issued
,Expires
,RefreshToken
,RefreshExpires
FROM QCheck_JwtStore

END