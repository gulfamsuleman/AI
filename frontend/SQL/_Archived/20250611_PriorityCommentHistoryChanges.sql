/* [QStatus_CreateNewPriorityComment] */

CREATE OR ALTER PROCEDURE [dbo].[QStatus_CreateNewPriorityComment]
    @TaskID int,
    @UserID int,
    @Comments varchar(1500),
    @StartTime datetime,
    @IsNew bit = 0,
    @NewID int OUTPUT,
    @CommentsInitials varchar(100) OUTPUT,
    @FullName varchar(50) OUTPUT
AS
BEGIN
    DECLARE @TimeZone varchar(100)

    SELECT @TimeZone = COALESCE(TimeZoneOverride, LastTimeZone, SystemTimeZone) 
        FROM QCheck_Users 
        CROSS APPLY (SELECT TOP 1 SystemTimeZone FROM QCheck_AppSettings) stz
        WHERE ID = @UserID

    --convert utc date coming in back to local, back to beginning of day
    select @StartTime = cast(dbo.ConvertTimeFromUTC(@StartTime, @TimeZone) as date)
    --convert back to UTC
    select @StartTime = dbo.ConvertTimeToUtc(@StartTime, @TimeZone)

    IF (@IsNew = 1)
    BEGIN
        -- Always insert a new comment
        EXEC [dbo].[QStatus_CreateNewComment]
            @TaskID = @TaskID,
            @UserID = @UserID,
            @Comments = @Comments,
            @NewID = @NewID OUTPUT,
            @CommentsInitials = @CommentsInitials OUTPUT,
            @FullName = @FullName OUTPUT
    END
    ELSE
    BEGIN
        -- Old logic: update if exists today, else insert
        IF EXISTS (SELECT 1 FROM QStatus_Comments WHERE ForeignKeyID=@taskID AND UserID=@UserID AND CommentDt>@StartTime)
        BEGIN
            UPDATE QStatus_Comments
            SET Comments=@Comments
            WHERE ID=(SELECT MAX(ID) FROM QStatus_Comments WHERE ForeignKeyID=@taskID AND UserID=@UserID AND CommentDt>@StartTime)
        END
        ELSE
        BEGIN
            EXEC [dbo].[QStatus_CreateNewComment]
                @TaskID = @TaskID,
                @UserID = @UserID,
                @Comments = @Comments,
                @NewID = @NewID OUTPUT,
                @CommentsInitials = @CommentsInitials OUTPUT,
                @FullName = @FullName OUTPUT
        END
    END

    DELETE FROM QStatus_Comments WHERE ForeignKeyID=@taskID AND UserID=@UserID AND CommentDt>@StartTime AND LEN(LTRIM(RTRIM(Comments))) = 0

	SELECT @NewID AS NewID, @CommentsInitials AS CommentsInitials, @FullName AS FullName
END

GO

/* [QCheck_GetStatusCommentsInitials] */

CREATE OR ALTER PROCEDURE [dbo].[QCheck_GetStatusCommentsInitials]
AS
BEGIN
    SET NOCOUNT ON;

    SELECT StatusCommentsInitials
    FROM dbo.QCheck_AppSettings;
END

GO

/* [PriorityListSet_GetComments_UTC] */

CREATE OR ALTER   PROC [dbo].[PriorityListSet_GetComments_UTC]
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

    SELECT li.ActiveChecklistID, li.[Priority], lsl.ListID, li.ID, l.UserID
    INTO #checklists
    FROM 
        Priorities_ListSetLists lsl
        INNER JOIN Priorities_Lists l ON l.ID = lsl.ListID            
        INNER JOIN Priorities_ListItems li ON li.ListID = l.ID
    WHERE lsl.setid = @setid;

    -- Supervisor and group report subqueries
    ;WITH Sup AS (
        SELECT gm.UserID, s.InterestedParty
        FROM QStatus_SUPERVISORS s
        INNER JOIN QCheck_GroupMembership gm ON gm.GroupID = s.supervisorGroupID
        INNER JOIN QCheck_Groups g ON g.ID = gm.GroupID
    ),
    Gr AS (
        SELECT gm.UserID
        FROM QStatus_GroupReport gr
        INNER JOIN QCheck_GroupMembership gm ON gm.GroupID = gr.GroupID
        INNER JOIN QCheck_Groups g ON g.ID = gm.GroupID
    )

    SELECT DISTINCT
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
        CASE 
            WHEN gr.USERID IS NOT NULL THEN 0
            ELSE
                CASE WHEN supcolor.colorNum IS NOT NULL THEN supcolor.colorNum
                ELSE
                    CASE WHEN sup.interestedParty = 0 THEN 3
                    ELSE 50
                    END
                END
        END AS ColorNum
    FROM 
        QStatus_Comments c
        INNER JOIN QCheck_Users u ON u.ID = c.UserID
        INNER JOIN #checklists l ON l.ActiveChecklistID = c.ForeignKeyID
        LEFT OUTER JOIN Sup sup ON sup.UserId = c.UserID
        LEFT OUTER JOIN Gr gr ON gr.UserId = c.UserID
        LEFT OUTER JOIN QStatus_SupervisorColors supcolor ON supcolor.supervisorUserID = c.UserID

    UNION ALL

    SELECT DISTINCT
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
        CASE 
            WHEN gr.USERID IS NOT NULL THEN 0
            ELSE
                CASE WHEN supcolor.colorNum IS NOT NULL THEN supcolor.colorNum
                ELSE
                    CASE WHEN sup.interestedParty = 0 THEN 3
                    ELSE 50
                    END
                END
        END AS ColorNum
    FROM 
        QStatus_CommentArchive c
        INNER JOIN QCheck_Users u ON u.ID = c.UserID
        INNER JOIN #checklists l ON l.ActiveChecklistID = c.ForeignKeyID
        LEFT OUTER JOIN Sup sup ON sup.UserId = c.UserID
        LEFT OUTER JOIN Gr gr ON gr.UserId = c.UserID
        LEFT OUTER JOIN QStatus_SupervisorColors supcolor ON supcolor.supervisorUserID = c.UserID

    ORDER BY UserID, DisplayOrder;

END

GO