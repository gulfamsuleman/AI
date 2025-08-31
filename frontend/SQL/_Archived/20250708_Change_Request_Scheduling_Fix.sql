ALTER PROCEDURE [dbo].[QCheck_Approval_CRChanged_Natural] (
	@ChangeID INT,
	@TimeZone varchar(255) = NULL
) AS

BEGIN
	DECLARE @Change_ID INT = @ChangeID

	DECLARE @Out TABLE (
		Seq INT IDENTITY(1,1),
		Item VARCHAR(max),
		Requested VARCHAR(max),
		CRItemID INT,
		Approved BIT
	)

	SELECT @TimeZone = COALESCE(@TimeZone, u.TimeZoneOverride, u.LastTimeZone)
	FROM QCheck_Users u
	JOIN QCheck_Approval_ChangeRequests cr
		ON cr.RequestingUser = u.ID
		AND cr.ID = @Change_ID

	DECLARE @CurrentButton VARCHAR(max),
		@RequestButton VARCHAR(max),
		@ReorderCount int
	
	-- ===============================================================
	-- Active Checklists			
	-- Due date

	INSERT INTO @Out (Item, Requested, CRItemID, Approved)
		SELECT 'Due Date', 
			CASE WHEN DATEDIFF(YEAR, C.DueTime, R.DueTime) > 0 THEN 
				CASE WHEN DATEDIFF(HOUR, DATEPART(HOUR, C.DueTime), datepart(hour, R.DueTime)) > 0 THEN
					'Extend From ' 
					+ FORMAT(CAST(dbo.ConvertTimeFromUtc(C.DueTime, @TimeZone) AS DATETIME), 'M/dd/yyyy h:mm tt') +
					+ ' to ' 
					+ FORMAT(CAST(dbo.ConvertTimeFromUtc(R.DueTime, @TimeZone) AS DATETIME), 'M/dd/yyyy h:mm tt')
					--FORMAT(CAST(dbo.ConvertTimeFromUtc(R.DueTime, @TimeZone) AS DATETIME), 'MM/yyyy') + ' ' + SUBSTRING(CONVERT(VARCHAR, dbo.ConvertTimeFromUtc(R.DueTime, @TimeZone), 108),11, 9)
					--+ ' (' + @TimeZone + ')'
				ELSE
					'Extend From ' 
					+ FORMAT(CAST(dbo.ConvertTimeFromUtc(C.DueTime, @TimeZone) AS DATETIME), 'M/dd/yyyy') +
					+ ' to ' 
					+ FORMAT(CAST(dbo.ConvertTimeFromUtc(R.DueTime, @TimeZone) AS DATETIME), 'M/dd/yyyy')
					--+ ' (' + @TimeZone + ')'
				END
			ELSE 
			CASE WHEN DATEDIFF(HOUR, DATEPART(HOUR, C.DueTime), datepart(hour, R.DueTime)) > 0 THEN
					'Extend From ' 
					+ FORMAT(CAST(dbo.ConvertTimeFromUtc(C.DueTime, @TimeZone) AS DATETIME), 'M/dd h:mm tt') +
					+ ' to ' 
					+ FORMAT(CAST(dbo.ConvertTimeFromUtc(R.DueTime, @TimeZone) AS DATETIME), 'M/dd h:mm tt')
					--FORMAT(CAST(dbo.ConvertTimeFromUtc(R.DueTime, @TimeZone) AS DATETIME), 'MM/yyyy') + ' ' + SUBSTRING(CONVERT(VARCHAR, dbo.ConvertTimeFromUtc(R.DueTime, @TimeZone), 108),11, 9)
					--+ ' (' + @TimeZone + ')'
				ELSE
					'Extend From ' 
					+ FORMAT(CAST(dbo.ConvertTimeFromUtc(C.DueTime, @TimeZone) AS DATETIME), 'M/dd') +
					+ ' to ' 
					+ FORMAT(CAST(dbo.ConvertTimeFromUtc(R.DueTime, @TimeZone) AS DATETIME), 'M/dd')
					--+ ' (' + @TimeZone + ')'
				END
			END,
			CRI.[ID], CRI.Approved
		FROM QCheck_Approval_ActiveChecklists R
		INNER JOIN QCheck_ActiveChecklists C
			ON R.ActiveChecklistID = C.[ID] 
			--AND R.DueTime <> C.DueTime -- Don't filter this, it needs to show in the request even if it's the current deadline
 		INNER JOIN QCheck_Approval_ChangeRequestItems cri
 			ON R.CRItemID = cri.[ID]
		WHERE R.ChangeRequestID = @Change_ID
	
	-- ===============================================================
	-- Checklists
	
	-- Checklist name
	INSERT INTO @Out (Item, Requested, CRItemID, Approved)
		SELECT 'Checklist Name', 'Changing Checklist Name from "' + C.[Name] +'" to "' + R.[Name] + '"', CRI.[ID], CRI.Approved
		FROM QCheck_Approval_Checklists R
 		INNER JOIN QCheck_Approval_ChangeRequestItems cri
 			ON R.CRItemID = cri.[ID]
		INNER JOIN QCheck_Checklists C 
			ON R.ChecklistID = C.[ID] 
			AND R.[Name] <> C.[Name]
		WHERE R.ChangeRequestID = @Change_ID AND R.IsDeleted = 0 AND C.IsDeleted = 0
	
	
	-- ===============================================================
	-- Items
	
	-- Item Type
	DECLARE @Approval_Items TABLE (
		[ID] [int] NOT NULL,
		[ChangeRequestID] [int] NOT NULL,
		[ItemID] [int] NOT NULL,
		[ChecklistID] [int] NOT NULL,
		[SequenceNum] [int] NOT NULL,
		[ItemTypeID] [int] NOT NULL,
		[Text] [varchar](max) NOT NULL,
		[URL] [varchar](1000) NOT NULL,
		[IsDeleted] [bit] NOT NULL,
		[CRItemID] [int] NULL
	)
	INSERT INTO @Approval_Items
	SELECT [ID]
		  ,[ChangeRequestID]
		  ,[ItemID]
		  ,[ChecklistID]
		  ,[SequenceNum]
		  ,[ItemTypeID]
		  ,[Text]
		  ,[URL]
		  ,[IsDeleted]
		  ,[CRItemID]
	FROM [dbo].[QCheck_Approval_Items]
	WHERE ChangeRequestID = @Change_ID AND IsDeleted = 0

	DECLARE @Approval_ChangeRequestItems TABLE (
		[ID] [int] NOT NULL,
		[ChangeRequestID] [int] NULL,
		[Approved] [bit] NULL
	)
	INSERT INTO @Approval_ChangeRequestItems
	SELECT cri.ID, cri.ChangeRequestID, cri.Approved
	FROM QCheck_Approval_ChangeRequestItems cri
		JOIN @Approval_Items R
		ON R.CRItemID = cri.[ID]

	DECLARE @Items TABLE (
		[ID] [int] NOT NULL,
		[ChecklistID] [int] NOT NULL,
		[SequenceNum] [int] NOT NULL,
		[ItemTypeID] [int] NOT NULL,
		[Text] [varchar](max) NOT NULL,
		[URL] [varchar](1000) NOT NULL,
		[IsDeleted] [bit] NOT NULL
	)
	INSERT INTO @Items
	SELECT C.[ID]
		  ,C.[ChecklistID]
		  ,C.[SequenceNum]
		  ,C.[ItemTypeID]
		  ,C.[Text]
		  ,C.[URL]
		  ,C.[IsDeleted]
	FROM [dbo].[QCheck_Items] C
		JOIN @Approval_Items R
		ON R.ItemID = C.[ID] 
		AND R.ItemTypeID <> C.ItemTypeID

	INSERT INTO @Out (Item, Requested, CRItemID, Approved)
		SELECT 'Checklist Item Type', 
		'Changing Item Type of checklist item "'+CASE WHEN LEN(C.[Text]) <= 20 THEN C.[Text] ELSE LEFT(C.[Text], 20) + '...' END
		+'" from ' + CT.[Name] + ' to ' + RT.[Name], CRI.[ID], CRI.Approved
		FROM @Approval_Items R
 		INNER JOIN @Approval_ChangeRequestItems cri
 			ON R.CRItemID = cri.[ID]
		INNER JOIN @Items C 
			ON R.ItemID = C.[ID] 
			AND R.ItemTypeID <> C.ItemTypeID
		INNER JOIN QCheck_ItemTypes CT
			ON C.ItemTypeID = CT.[ID]
		INNER JOIN QCheck_ItemTypes RT
			ON R.ItemTypeID = RT.[ID]
		WHERE R.ChangeRequestID = @Change_ID AND R.IsDeleted = 0 AND C.IsDeleted = 0
	
	-- Name
	INSERT INTO @Out (Item, Requested, CRItemID, Approved)
		SELECT 'Item Text', 'Changing text of checklist item "' + C.[Text] + '" to read "' + R.[Text] + '"', CRI.[ID], CRI.Approved
		FROM @Approval_Items R
 		INNER JOIN @Approval_ChangeRequestItems cri
 			ON R.CRItemID = cri.[ID]
		INNER JOIN QCheck_Items C 
			ON R.ItemID = C.[ID] 
			AND R.[Text] <> C.[Text]
		WHERE R.ChangeRequestID = @Change_ID AND R.IsDeleted = 0 AND C.IsDeleted = 0
	
	-- URL
	INSERT INTO @Out (Item, Requested, CRItemID, Approved)
		SELECT 'Item URL', 'Changing "More Info" URL of checklist item "'+CASE WHEN LEN(C.[Text]) <= 20 THEN C.[Text] ELSE LEFT(C.[Text], 20) + '...' END
		+'" from "' + C.[URL] + '" to "' + R.[URL] + '"', CRI.[ID], CRI.Approved
		FROM @Approval_Items R
 		INNER JOIN @Approval_ChangeRequestItems cri
 			ON R.CRItemID = cri.[ID]
		INNER JOIN @Items C 
			ON R.ItemID = C.[ID] 
			AND R.[URL] <> C.[URL]
		WHERE R.ChangeRequestID = @Change_ID AND R.IsDeleted = 0 AND C.IsDeleted = 0
	
	
	-- Sequence reordering
	-- Old Way - doesn't work, because sequence numbers almost always change, but the order doesn't always

	--IF EXISTS (
	--	SELECT 'Y'
	--	FROM QCheck_Approval_Items R
	--	INNER JOIN QCheck_Items C 
	--		ON R.ItemID = C.[ID] 
	--		AND R.[SequenceNum] <> C.[SequenceNum]
	--	WHERE R.ChangeRequestID = @ChangeID AND R.IsDeleted = 0 AND C.IsDeleted = 0
	--) BEGIN

		--SET @CurrentButton = '<input type="button" class="btn btn-default" value="Preview Current" onclick="DoPreview(-1, ' + CONVERT(VARCHAR(20), dbo.QCheck_Approval_CRChecklistID(@ChangeID)) + ', ''' + dbo.QCheck_Approval_CRChecklistName(@ChangeID) + ''');"/>'
		--SET @RequestButton = '<input type="button" class="btn btn-default" value="Preview Requested" onclick="DoPreview(' + CONVERT(VARCHAR(20), @ChangeID) + ', ' + CONVERT(VARCHAR(20), dbo.QCheck_Approval_CRChecklistID(@ChangeID)) + ', ''' + dbo.QCheck_Approval_CRChecklistName(@ChangeID) + ''');"/>'
		
		--SELECT @ReorderCount = COUNT(*)
		--FROM QCheck_Approval_Items R
		--INNER JOIN QCheck_Items C 
		--	ON R.ItemID = C.[ID] 
		--	AND R.[SequenceNum] <> C.[SequenceNum]
		--WHERE R.ChangeRequestID = @ChangeID AND R.IsDeleted = 0 AND C.IsDeleted = 0

		--New Way		
		--Basic idea; get all items not being added or deleted (doesn't count as a reorder),
		--then line them up row by row, and count all lines where the item IDs don't match 
		SELECT @ReorderCount = COUNT(*)
		FROM (
			SELECT ROW_NUMBER() OVER (ORDER BY i2.SequenceNum) Row, i2.ID 
				FROM @Items i2
				JOIN @Approval_Items ai2
					ON ai2.ChangeRequestID = @Change_ID
					AND ai2.ItemID = i2.ID			
				WHERE i2.IsDeleted = 0
					AND ai2.IsDeleted = 0 --no newly-deleted rows
			) i
		FULL JOIN (
			SELECT ROW_NUMBER() OVER (ORDER BY ai2.SequenceNum) Row, ai2.ItemID ID
				FROM @Approval_Items ai2
				WHERE ai2.ChangeRequestID = @Change_ID
				AND ai2.ItemID <> -1 --no newly-added rows
				AND ai2.IsDeleted = 0
			) ai
			ON ai.Row = i.Row
		WHERE ai.ID <> i.ID

		SET @ReorderCount = ISNULL(@ReorderCount, 0)

		IF(@ReorderCount > 0)
			INSERT INTO @Out (Item, Requested, CRItemID, Approved) VALUES ('Reorder', 'Reordering ' + CAST(@ReorderCount as varchar) + ' items within the checklist', -1, 1)

	--END
	
	-- ===============================================================
	-- Schedule
	
	INSERT INTO @Out (Item, Requested, CRItemID, Approved)
		SELECT 'Schedule', 'Changing schedule from "' + isnull(dbo.QCheck_ScheduleString(C.[ID]), 'no schedule') + '" to "' + dbo.QCheck_Approval_ScheduleString(@Change_ID, R.ScheduleID, CI.ID) + '"', CRI.[ID], CRI.Approved
		FROM QCheck_Approval_Schedule R
 		INNER JOIN QCheck_Approval_ChangeRequestItems cri
 			ON R.CRItemID = cri.[ID]
		INNER JOIN QCheck_Schedule C 
			ON R.ScheduleID = C.[ID] 
			AND (
				ISNULL(R.FirstDueDate,'') <> ISNULL(C.FirstDueDate,'')
				OR ISNULL(R.LastDueDate, '') <> ISNULL(C.LastDueDate, '')
				OR R.FreqType <> C.FreqType
				OR R.FreqInterval <> C.FreqInterval
				OR R.FreqRecurrance <> C.FreqRecurrance
				OR ISNULL(R.DueTime,'') <> ISNULL(C.DueTime,'')
				OR R.BusDayBehavior <> C.BusDayBehavior
				OR R.SoftDueOffsetDays <> C.SoftDueOffsetDays
				OR R.TimeZone <> C.TimeZone
			)
		INNER JOIN QCheck_ChecklistInstances CI
			ON CI.ScheduleID = R.ScheduleID 
		WHERE R.ChangeRequestID = @Change_ID
	
	
	-- ===============================================================
	-- Get the output
	SELECT 
		Seq,
		Item,
		Requested,
		CRItemID,
		Approved
	FROM 
		@Out
	WHERE Requested IS NOT NULL

END