CREATE OR ALTER PROC QStatus_GetSlimCommentsByIds
	@ReportID int,
	@UserID int,
	@RecordId RecordId readonly
AS
BEGIN
	SET NOCOUNT ON

	EXEC dbo.Audit_Set @userId, @recordId, 'Comment', 2

	SELECT DISTINCT
		 Id = c.ID
		,[Text] = c.Comments
	FROM
		QStatus_COMMENTS C
		INNER JOIN @RecordId R
			ON r.Id = c.ID

	UNION ALL

	SELECT DISTINCT
		 Id = c.ID
		,[Text] = c.Comments
	FROM
		QStatus_commentarchive C
		INNER JOIN @RecordId R
			ON R.Id = c.ID
END