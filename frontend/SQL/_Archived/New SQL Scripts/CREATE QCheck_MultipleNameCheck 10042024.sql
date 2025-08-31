
GO
/****** Object:  StoredProcedure [dbo].[QCheck_DuplicateNameCheck]    Script Date: 10/4/2024 9:41:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[QCheck_MultipleNameCheck] (
	@Name VARCHAR(500),
	@OKToUse BIT OUTPUT
) AS

BEGIN
	
	DECLARE @Count INT

	SELECT 
		@Count = COUNT(*)
	FROM 
		QCheck_Checklists
	WHERE 
		[Name] = @Name
		AND IsDeleted = 0
		
	IF @Count > 0 AND @Count < 2 BEGIN

		SET @OkToUse = 1

	END ELSE BEGIN

		SET @OkToUse = 0

	END

END