USE [QTasks]
GO
/****** Object:  StoredProcedure [dbo].[API_GetSigningKey]    Script Date: 9/17/2024 11:11:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[API_GetAllSigningKey]
AS
BEGIN
	SELECT ID, KeyValue [Key], AsOf, IsRevoked
	FROM API_SigningKey
END