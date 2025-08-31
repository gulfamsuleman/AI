USE [QTasks]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Util_Log3rdPartyAccessAttempt](
	@KeyValue NVARCHAR(100),
	@KeyType NVARCHAR(100),
	@Source NVARCHAR(100),
	@MethodName NVARCHAR(100),
	@Success BIT,
	@AttemptedDate DATETIME
)AS

BEGIN

	INSERT INTO QCheck_ThirdPartyAuthAudit
	VALUES (@KeyValue, @KeyType, @Source, @MethodName, @Success, @AttemptedDate)

END