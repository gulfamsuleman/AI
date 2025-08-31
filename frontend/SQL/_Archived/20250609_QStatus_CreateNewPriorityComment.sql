CREATE OR ALTER PROCEDURE [dbo].[QStatus_CreateNewPriorityComment]
    @TaskID int,
    @UserID int,
    @Comments varchar(1500),
    @StartTime datetime,
    @IsNew bit = 0
AS
BEGIN
    DECLARE @NewID int,
            @CommentsInitials varchar(100),
            @FullName varchar(50),
            @TimeZone varchar(100)

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
END
