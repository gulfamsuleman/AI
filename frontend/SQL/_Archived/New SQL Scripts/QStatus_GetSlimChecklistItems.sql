CREATE OR ALTER PROC QStatus_GetSlimChecklistItems
	@uniqueId int
AS
BEGIN
	SET NOCOUNT ON

	SELECT
		  e.Text UserText
		, u.FullName As CompletedBy
		, convert(varchar,e.CompletedDate,1) + Right(convert(varchar,e.CompletedDate,0), charindex(' ',reverse(convert(varchar,e.CompletedDate,0)))) as CompletedDate
		, d.Text
		, d.ID as ItemID
		, j.Name as ItemType
		, d.URL
	FROM
		QCheck_ActiveChecklists a 
		INNER JOIN QCheck_ChecklistInstances b 
			ON a.InstanceID = b.ID AND b.IsDeleted = 0
		INNER JOIN QCheck_Items d 
			ON d.checklistID = b.checklistID AND d.IsDeleted = 0
		LEFT OUTER JOIN QCheck_ItemTypes j 
			ON d.ItemTypeID = j.ID
		LEFT OUTER JOIN QCheck_ActiveItems e 
			ON e.ActiveChecklistID = a.ID and e.ChecklistItemID = d.ID
		LEFT OUTER JOIN QCheck_Users u 
			ON e.CompletedBy = u.ID
	WHERE
		a.ID = @uniqueId
	ORDER BY 
		d.SequenceNum DESC
END