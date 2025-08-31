USE [QTasks]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Util_AddApiKey](
	@Key NVARCHAR(100),
	@Requestor NVARCHAR(100),
	@Approver NVARCHAR(100),
	@OnBehalfOf NVARCHAR(100),
	@Intent NVARCHAR(100),
	@Issued DATETIME,
	@Expires DATETIME,
	@NotBefore DATETIME,
	@IsRevoked BIT
)AS

BEGIN

	INSERT INTO QCheck_APIKeyStore
	VALUES (@Key, @Requestor, @Approver, @OnBehalfOf, @Intent, @Issued, @Expires, @NotBefore, @IsRevoked)

END