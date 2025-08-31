ALTER PROC [dbo].[PriorityListSet_GetComments_UTC]
    @SetID int,
    @UserID int,
    @StartTime datetime,
    @AllUsers bit = 0
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @TimeZone VARCHAR(MAX) = NULL;
    SET @TimeZone = (SELECT ISNULL(TimeZoneOverride, LastTimeZone) FROM QCheck_Users WHERE ID = @UserID);

    DECLARE @UseInitials BIT;
    SELECT TOP 1 @UseInitials = ISNULL([StatusCommentsInitials], 0) FROM [dbo].[QCheck_AppSettings];

    -- Calculate timezone offset once
    DECLARE @SampleUtc DATETIME = GETUTCDATE();
    DECLARE @LocalSample NVARCHAR(255) = dbo.ConvertTimeFromUtc(@SampleUtc, @TimeZone);
    DECLARE @OffsetMinutes INT = DATEDIFF(MINUTE, @SampleUtc, CAST(@LocalSample AS DATETIME));

    DECLARE @checklists TABLE (
        ActiveChecklistID int,
        [Priority] int,
        ListID int,
        ID int,
        UserID int
    )

    INSERT INTO @checklists
    SELECT li.ActiveChecklistID, li.[Priority], lsl.ListID, li.ID, l.UserID
    FROM 
        Priorities_ListSetLists lsl
        INNER JOIN Priorities_Lists l ON l.ID = lsl.ListID            
        INNER JOIN Priorities_ListItems li ON li.ListID = l.ID
    WHERE lsl.setid = @setid;

    -- Supervisor and group report subqueries

    SELECT 
        l.UserID,
        l.ListID,
        l.ActiveChecklistID,
        '[' + CONVERT(VARCHAR(10), c.CommentDt, 101) + '] [' +
            CASE 
                WHEN @UseInitials = 1 THEN 
                    UPPER(LEFT(SUBSTRING(u.ShortName, CHARINDEX('-', u.ShortName) + 1, LEN(u.ShortName)), 2))
                ELSE u.FullName
            END
        + '] ' + c.Comments AS Comments,
        l.ID,
        CAST(CASE WHEN c.commentdt > @starttime THEN 0 ELSE 1 END AS BIT) AS IsHidden,
        c.DisplayOrder,
        c.TabIn,
        c.UserID AS CommentUserID,
        c.ID AS CommentId,
        DATEADD(MINUTE, @OffsetMinutes, c.CommentDt) AS CommentDt,
        0 AS ColorNum
    FROM 
        QStatus_Comments c
        INNER JOIN QCheck_Users u ON u.ID = c.UserID
        INNER JOIN @checklists l ON l.ActiveChecklistID = c.ForeignKeyID
    WHERE (c.UserID = @UserID OR @AllUsers = 1)

    UNION ALL

    SELECT 
        l.UserID,
        l.ListID,
        l.ActiveChecklistID,
        '[' + CONVERT(VARCHAR(10), c.CommentDt, 101) + '] [' +
            CASE 
                WHEN @UseInitials = 1 THEN 
                    UPPER(LEFT(SUBSTRING(u.ShortName, CHARINDEX('-', u.ShortName) + 1, LEN(u.ShortName)), 2))
                ELSE u.FullName
            END
        + '] ' + c.Comments AS Comments,
        l.ID,
        CAST(CASE WHEN c.commentdt > @starttime THEN 0 ELSE 1 END AS BIT) AS IsHidden,
        c.DisplayOrder,
        c.TabIn,
        c.UserID AS CommentUserID,
        c.ID AS CommentId,
        DATEADD(MINUTE, @OffsetMinutes, c.CommentDt) AS CommentDt,
        0 AS ColorNum
    FROM 
        QStatus_CommentArchive c
        INNER JOIN QCheck_Users u ON u.ID = c.UserID
        INNER JOIN @checklists l ON l.ActiveChecklistID = c.ForeignKeyID
    WHERE (c.UserID = @UserID OR @AllUsers = 1)

    ORDER BY UserID, DisplayOrder;

END
