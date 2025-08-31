/** ONLY RUN ONCE **/

-- Custom SQL Types
DROP TYPE IF EXISTS RecordId
CREATE TYPE RecordId AS TABLE (
	Id INT PRIMARY KEY 
)
-- If database support memory optimized option, better to use the below instead
-- this will avoid pounding the TempDB
--CREATE TYPE RecordId AS TABLE (
--	Id INT PRIMARY KEY NONCLUSTERED HASH WITH (BUCKET_COUNT = 1000)
--) WITH ( MEMORY_OPTIMIZED = ON )
GO

DROP TABLE IF EXISTS dbo.Audit_Type
CREATE TABLE dbo.Audit_Type (
	AuditTypeId TINYINT IDENTITY(1, 1) NOT NULL PRIMARY KEY,
	[Name] VARCHAR(255) NOT NULL
)
GO
INSERT INTO dbo.Audit_Type ([Name])
VALUES ('CREATE'), ('READ'), ('UPDATE'), ('DELETE')
GO

/** RERUNNABLE **/

-- For QStatus_Comments
DROP TABLE IF EXISTS dbo.Audit_Comment
CREATE TABLE dbo.Audit_Comment (
	[UID] BIGINT IDENTITY(1, 1) NOT NULL,
	UserId INT NOT NULL,
	CommentId INT NOT NULL,
	AuditTypeId TINYINT NOT NULL
		CONSTRAINT FK_AuditType_Comment
 REFERENCES Audit_Type(AuditTypeId),
	AuditDt DATETIME DEFAULT(GETDATE()) NOT NULL
)
GO
DROP TABLE IF EXISTS dbo.Audit_CommentArchived
CREATE TABLE dbo.Audit_CommentArchived (
	[UID] BIGINT IDENTITY(1, 1) NOT NULL,
	UserId INT NOT NULL,
	CommentArchivedId INT NOT NULL,
	AuditTypeId TINYINT NOT NULL
		CONSTRAINT FK_AuditType_CommentArchived
 REFERENCES Audit_Type(AuditTypeId),
	AuditDt DATETIME DEFAULT(GETDATE()) NOT NULL
)
GO
-- For QCheck_Checklists
DROP TABLE IF EXISTS dbo.Audit_Checklist
CREATE TABLE dbo.Audit_Checklist (
	[UID] BIGINT IDENTITY(1, 1) NOT NULL,
	UserId INT NOT NULL,
	ChecklistId INT NOT NULL,
	AuditTypeId TINYINT NOT NULL
		CONSTRAINT FK_AuditType_Checklist
 REFERENCES Audit_Type(AuditTypeId),
	AuditDt DATETIME DEFAULT(GETDATE()) NOT NULL
)
GO
-- For QCheck_Items
DROP TABLE IF EXISTS dbo.Audit_Item
CREATE TABLE dbo.Audit_Item (
	[UID] BIGINT IDENTITY(1, 1) NOT NULL,
	UserId INT NOT NULL,
	ItemId INT NOT NULL,
	AuditTypeId TINYINT NOT NULL
		CONSTRAINT FK_AuditType_Item
 REFERENCES Audit_Type(AuditTypeId),
	AuditDt DATETIME DEFAULT(GETDATE()) NOT NULL
)
GO
-- For QCheck_Approval_ChangeRequests
DROP TABLE IF EXISTS dbo.Audit_ChangeRequest
CREATE TABLE dbo.Audit_ChangeRequest (
	[UID] BIGINT IDENTITY(1, 1) NOT NULL,
	UserId INT NOT NULL,
	ChangeRequestId INT NOT NULL,
	AuditTypeId TINYINT NOT NULL
		CONSTRAINT FK_AuditType_ChangeRequest
 REFERENCES Audit_Type(AuditTypeId),
	AuditDt DATETIME DEFAULT(GETDATE()) NOT NULL
)
GO
-- For QCheck_Approval_Checklists
DROP TABLE IF EXISTS dbo.Audit_ApprovalChecklist
CREATE TABLE dbo.Audit_ApprovalChecklist (
	[UID] BIGINT IDENTITY(1, 1) NOT NULL,
	UserId INT NOT NULL,
	ApprovalChecklistId INT NOT NULL,
	AuditTypeId TINYINT NOT NULL
		CONSTRAINT FK_AuditType_ApprovalChecklist
 REFERENCES Audit_Type(AuditTypeId),
	AuditDt DATETIME DEFAULT(GETDATE()) NOT NULL
)
GO
-- For QCheck_Approval_Items
DROP TABLE IF EXISTS dbo.Audit_ApprovalItem
CREATE TABLE dbo.Audit_ApprovalItem (
	[UID] BIGINT IDENTITY(1, 1) NOT NULL,
	UserId INT NOT NULL,
	ApprovalItemId INT NOT NULL,
	AuditTypeId TINYINT NOT NULL
		CONSTRAINT FK_AuditType_ApprovalItem
 REFERENCES Audit_Type(AuditTypeId),
	AuditDt DATETIME DEFAULT(GETDATE()) NOT NULL
)
GO
-- For QCheck_ActiveItems (comments for checklist item)
DROP TABLE IF EXISTS dbo.Audit_ActiveItem
CREATE TABLE dbo.Audit_ActiveItem (
	[UID] BIGINT IDENTITY(1, 1) NOT NULL,
	UserId INT NOT NULL,
	ActiveItemId INT NOT NULL,
	AuditTypeId TINYINT NOT NULL
		CONSTRAINT FK_AuditType_ActiveItem
 REFERENCES Audit_Type(AuditTypeId),
	AuditDt DATETIME DEFAULT(GETDATE()) NOT NULL
)
GO
-- For QCheck_ActiveChecklists 
DROP TABLE IF EXISTS dbo.Audit_ActiveChecklist
CREATE TABLE dbo.Audit_ActiveChecklist (
	[UID] BIGINT IDENTITY(1, 1) NOT NULL,
	UserId INT NOT NULL,
	ActiveChecklistId INT NOT NULL,
	AuditTypeId TINYINT NOT NULL
		CONSTRAINT FK_AuditType_ActiveChecklist
 REFERENCES Audit_Type(AuditTypeId),
	AuditDt DATETIME DEFAULT(GETDATE()) NOT NULL
)
GO
-- For QStatus_TaskTypes 
DROP TABLE IF EXISTS dbo.Audit_TaskType
CREATE TABLE dbo.Audit_TaskType (
	[UID] BIGINT IDENTITY(1, 1) NOT NULL,
	UserId INT NOT NULL,
	TaskTypeId INT NOT NULL,
	AuditTypeId TINYINT NOT NULL
		CONSTRAINT FK_AuditType_TaskType
 REFERENCES Audit_Type(AuditTypeId),
	AuditDt DATETIME DEFAULT(GETDATE()) NOT NULL
)
GO
-- For QStatus_Report 
DROP TABLE IF EXISTS dbo.Audit_Report
CREATE TABLE dbo.Audit_Report (
	[UID] BIGINT IDENTITY(1, 1) NOT NULL,
	UserId INT NOT NULL,
	ReportId INT NOT NULL,
	AuditTypeId TINYINT NOT NULL
		CONSTRAINT FK_AuditType_Report
 REFERENCES Audit_Type(AuditTypeId),
	AuditDt DATETIME DEFAULT(GETDATE()) NOT NULL
)
GO
DROP TABLE IF EXISTS dbo.Audit_ArchiveApprovalChecklist
CREATE TABLE dbo.Audit_ArchiveApprovalChecklist (
	[UID] BIGINT IDENTITY(1, 1) NOT NULL,
	ArchiveDt DATETIME DEFAULT(GETDATE()) NOT NULL,
	ID INT NOT NULL,
	ChangeRequestID INT NOT NULL,
	ChecklistID INT NOT NULL,
	[Name] VARCHAR(500) NOT NULL,
	IsDeleted BIT NOT NULL,
	[Owner] INT NULL,
	Template BIT NOT NULL,
	CRItemID INT NULL,
)
GO
DROP TABLE IF EXISTS dbo.Audit_ArchiveApprovalItem
CREATE TABLE dbo.Audit_ArchiveApprovalItem (
	[UID] BIGINT IDENTITY(1, 1) NOT NULL,
	ArchiveDt DATETIME DEFAULT(GETDATE()) NOT NULL,
	ID INT NOT NULL,
	[ChangeRequestID] [int] NOT NULL,
	[ItemID] [int] NOT NULL,
	[ChecklistID] [int] NOT NULL,
	[SequenceNum] [int] NOT NULL,
	[ItemTypeID] [int] NOT NULL,
	[Text] [varchar](max) NOT NULL,
	[URL] [varchar](1000) NOT NULL,
	[IsDeleted] [bit] NOT NULL,
	[CRItemID] [int] NULL,
)
GO
DROP TABLE IF EXISTS dbo.Audit_ArchiveActiveItem
CREATE TABLE dbo.Audit_ArchiveActiveItem (
	[UID] BIGINT IDENTITY(1, 1) NOT NULL,
	ArchiveDt DATETIME DEFAULT(GETDATE()) NOT NULL,
	ID INT NOT NULL,
	ActiveChecklistID INT NOT NULL,
	ChecklistItemID INT NOT NULL,
	[Text] VARCHAR(1000) NULL,
	CompletedDate DATETIME NULL,
	CompletedBy INT NULL,
)
GO
DROP TABLE IF EXISTS dbo.Audit_ArchiveActiveChecklist
CREATE TABLE dbo.Audit_ArchiveActiveChecklist (
	[UID] BIGINT IDENTITY(1, 1) NOT NULL,
	ArchiveDt DATETIME DEFAULT(GETDATE()) NOT NULL,
	ID INT NOT NULL,
	InstanceID INT NOT NULL,
	DueTime DATETIME NOT NULL,
	OrigDueTime DATETIME NOT NULL,
	ReminderDate DATETIME NULL,
	CompletedDate DATETIME NULL,
	HasNaggedDue INT NOT NULL,
	CompletedBy INT NULL,
	IsNA BIT NULL,
	NAReason VARCHAR(MAX) NULL,
)
GO
DROP TABLE IF EXISTS dbo.Audit_ArchiveItem
CREATE TABLE dbo.Audit_ArchiveItem (
	[UID] BIGINT IDENTITY(1, 1) NOT NULL,
	ArchiveDt DATETIME DEFAULT(GETDATE()) NOT NULL,
	ID INT NOT NULL,
	ChecklistID INT NOT NULL,
	SequenceNum INT NOT NULL,
	ItemTypeID INT NOT NULL,
	[Text] VARCHAR(max) NOT NULL,
	[URL] VARCHAR(1000) NOT NULL,
	IsDeleted BIT NOT NULL
)
GO
DROP TABLE IF EXISTS dbo.Audit_ArchiveChecklist
CREATE TABLE dbo.Audit_ArchiveChecklist (
	[UID] BIGINT IDENTITY(1, 1) NOT NULL,
	ArchiveDt DATETIME DEFAULT(GETDATE()) NOT NULL,
	ID INT NOT NULL,
	[Name] VARCHAR(500) NOT NULL,
	IsDeleted BIT NOT NULL,
	[Owner] INT NULL,
	Template BIT NOT NULL,
	CreateDate DATETIME NULL
)
GO
DROP TABLE IF EXISTS dbo.Audit_ArchiveComment
CREATE TABLE dbo.Audit_ArchiveComment (
	[UID] BIGINT IDENTITY(1, 1) NOT NULL,
	ArchiveDt DATETIME DEFAULT(GETDATE()) NOT NULL,
	ID INT NOT NULL,
	[ForeignKeyID] INT NOT NULL,
	Comments VARCHAR(1500) NOT NULL,
	DisplayOrder INT NOT NULL,
	TabIn INT NOT NULL,
	CommentDt DATETIME NOT NULL,
	Initials VARCHAR(100) NOT NULL,
	UserID INT NOT NULL,
	ReplyID INT NULL,
	SpecialTask BIT NOT NULL
)
GO
CREATE OR ALTER PROC dbo.Audit_Set
	@userId INT,
	@recordIds RecordId READONLY,
	@recordType VARCHAR(50),
	@auditTypeId TINYINT
AS
BEGIN
	SET NOCOUNT ON

	IF @recordType = 'ActiveItem' BEGIN
		INSERT INTO dbo.Audit_ActiveItem (UserId, ActiveItemId, AuditTypeId)
			SELECT @userId, Id, @auditTypeId FROM @recordIds

		IF @auditTypeId IN (3, 4) BEGIN
			INSERT INTO dbo.Audit_ArchiveActiveItem (
			 ID
			 ,ActiveChecklistID
			 ,ChecklistItemID
			 ,[Text]
			 ,CompletedDate
			 ,CompletedBy
			)
			SELECT 
			 itm.ID
			 ,ActiveChecklistID
			 ,ChecklistItemID
			 ,[Text]
			 ,CompletedDate
			 ,CompletedBy
			FROM dbo.QCheck_ActiveItems itm
			INNER JOIN @recordIds src ON src.Id = itm.ID
		END
	END ELSE IF @recordType = 'ActiveChecklist' BEGIN
		INSERT INTO dbo.Audit_ActiveChecklist (UserId, ActiveChecklistId, AuditTypeId)
			SELECT @userId, Id, @auditTypeId FROM @recordIds

		IF @auditTypeId IN (3, 4) BEGIN
			INSERT INTO dbo.Audit_ArchiveActiveChecklist (
			 ID
			 ,InstanceID
			 ,DueTime
			 ,OrigDueTime
			 ,ReminderDate
			 ,CompletedDate
			 ,HasNaggedDue
			 ,CompletedBy
			 ,IsNA
			 ,NAReason
			)
			SELECT 
			 itm.ID
			 ,InstanceID
			 ,DueTime
			 ,OrigDueTime
			 ,ReminderDate
			 ,CompletedDate
			 ,HasNaggedDue
			 ,CompletedBy
			 ,IsNA
			 ,NAReason
			FROM dbo.QCheck_ActiveChecklists itm
			INNER JOIN @recordIds src ON src.Id = itm.ID
		END
	END ELSE IF @recordType = 'Item' BEGIN
		INSERT INTO dbo.Audit_Item (UserId, ItemId, AuditTypeId)
			SELECT @userId, Id, @auditTypeId FROM @recordIds

		IF @auditTypeId IN (3, 4) BEGIN
			INSERT INTO dbo.Audit_ArchiveItem (
			 ID
			 ,ChecklistID
			 ,SequenceNum
			 ,ItemTypeID
			 ,[Text]
			 ,[URL]
			 ,IsDeleted
			)
			SELECT 
			 itm.ID
			 ,ChecklistID
			 ,SequenceNum
			 ,ItemTypeID
			 ,[Text]
			 ,[URL]
			 ,IsDeleted
			FROM dbo.QCheck_Items itm
			INNER JOIN @recordIds src ON src.Id = itm.ID
		END
	END ELSE IF @recordType = 'Checklist' BEGIN
		INSERT INTO dbo.Audit_Checklist (UserId, ChecklistId, AuditTypeId)
			SELECT @userId, Id, @auditTypeId FROM @recordIds

		IF @auditTypeId IN (3, 4) BEGIN
			INSERT INTO dbo.Audit_ArchiveChecklist (
			 ID
			 ,[Name]
			 ,IsDeleted
			 ,[Owner]
			 ,Template
			 ,CreateDate
			)
			SELECT 
			 itm.ID
			 ,[Name]
			 ,IsDeleted
			 ,[Owner]
			 ,Template
			 ,CreateDate
			FROM dbo.QCheck_Checklists itm
			INNER JOIN @recordIds src ON src.Id = itm.ID
		END
	END ELSE IF @recordType = 'Comment' BEGIN
		INSERT INTO dbo.Audit_Comment (UserId, CommentId, AuditTypeId)
			SELECT @userId, Id, @auditTypeId FROM @recordIds

		IF @auditTypeId IN (3, 4) BEGIN
			INSERT INTO dbo.Audit_ArchiveComment(
			 ID
			 ,ForeignKeyID
			 ,Comments
			 ,DisplayOrder
			 ,TabIn
			 ,CommentDt
			 ,Initials
			 ,UserID
			 ,ReplyID
			 ,SpecialTask
			)
			SELECT 
			 itm.ID
			 ,ForeignKeyID
			 ,Comments
			 ,DisplayOrder
			 ,TabIn
			 ,CommentDt
			 ,Initials
			 ,UserID
			 ,ReplyID
			 ,SpecialTask
			FROM dbo.QStatus_Comments itm
			INNER JOIN @recordIds src ON src.Id = itm.ID
		END
	END ELSE IF @recordType = 'ApprovalChecklist' BEGIN
		INSERT INTO dbo.Audit_ApprovalChecklist(UserId, ApprovalChecklistId, AuditTypeId)
			SELECT @userId, Id, @auditTypeId FROM @recordIds

		IF @auditTypeId IN (3, 4) BEGIN
			INSERT INTO dbo.Audit_ArchiveApprovalChecklist(
			 ID
			 ,ChangeRequestID
			 ,ChecklistID
			 ,[Name]
			 ,IsDeleted
			 ,[Owner]
			 ,Template
			 ,CRItemID
			)
			SELECT 
			 itm.ID
			 ,ChangeRequestID
			 ,ChecklistID
			 ,[Name]
			 ,IsDeleted
			 ,[Owner]
			 ,Template
			 ,CRItemID
			FROM dbo.QCheck_Approval_Checklists itm
			INNER JOIN @recordIds src ON src.Id = itm.ID
		END
	END ELSE IF @recordType = 'ApprovalItem' BEGIN
		INSERT INTO dbo.Audit_ApprovalItem (UserId, ApprovalItemId, AuditTypeId)
			SELECT @userId, Id, @auditTypeId FROM @recordIds

		IF @auditTypeId IN (3, 4) BEGIN
			INSERT INTO dbo.Audit_ArchiveApprovalItem(
			 ID
			 ,[ChangeRequestID]
			 ,[ItemID]
			 ,[ChecklistID]
			 ,[SequenceNum]
			 ,[ItemTypeID]
			 ,[Text]
			 ,[URL]
			 ,[IsDeleted]
			 ,[CRItemID]
			)
			SELECT 
			 itm.ID
			 ,[ChangeRequestID]
			 ,[ItemID]
			 ,[ChecklistID]
			 ,[SequenceNum]
			 ,[ItemTypeID]
			 ,[Text]
			 ,[URL]
			 ,[IsDeleted]
			 ,[CRItemID]
			FROM dbo.QCheck_Approval_Items itm
			INNER JOIN @recordIds src ON src.Id = itm.ID
		END
	END ELSE IF @recordType = 'TaskType' BEGIN
		INSERT INTO dbo.Audit_TaskType(UserId, TaskTypeId, AuditTypeId)
			SELECT @userId, Id, @auditTypeId FROM @recordIds
	END ELSE IF @recordType = 'Report' BEGIN
		INSERT INTO dbo.Audit_Report(UserId, ReportId, AuditTypeId)
			SELECT @userId, Id, @auditTypeId FROM @recordIds
	END ELSE IF @recordType = 'CommentArchived' BEGIN
		INSERT INTO dbo.Audit_CommentArchived(UserId, CommentArchivedId, AuditTypeId)
			SELECT @userId, Id, @auditTypeId FROM @recordIds
	END ELSE IF @recordType = 'ChangeRequest' BEGIN
		INSERT INTO dbo.Audit_ChangeRequest(UserId, ChangeRequestId, AuditTypeId)
			SELECT @userId, Id, @auditTypeId FROM @recordIds
	END
END
GO


CREATE OR ALTER PROC [dbo].[PriorityList_Get]
	@UserID int
AS
BEGIN
	SET NOCOUNT ON

	EXEC PriorityList_Refresh @UserID

	SELECT DISTINCT p.ID, 
		convert(varchar(10)
		, p.Priority) as Priority
		, p.ActiveChecklistID
		, c.[Name]
		, convert(varchar, ac.duetime, 101) as due
		, isnull('['+convert(varchar, qc.commentdt, 101) + '] [' + qc.initials + '] ' + replace(qc.comments, '''', ''), 'No Comments') as comments
		, @UserID as UserId
		, CASE WHEN convert(integer, p.Priority) > 0 THEN 0 ELSE 1 END AS PriorityRank --active ones first
		, convert(integer, p.Priority) AS PriorityNbr
		, ac.duetime
		, c.ID AS ChecklistId
		, qc.ID AS CommentId
	INTO #result
	FROM 
		PriorityList p
		INNER JOIN QCheck_ActiveChecklists ac
			ON ac.id = p.ActiveChecklistID
		INNER JOIN QCheck_ChecklistInstances ci
			ON ci.id = ac.instanceid
		INNER JOIN QCheck_Checklists c
			ON c.id = ci.checklistid
		LEFT OUTER JOIN
			(select foreignkeyid, max(ID) as ID from qstatus_comments
			where specialtask = 0
			group by foreignkeyid
			) com ON com.foreignkeyid = ac.ID
		LEFT OUTER JOIN qstatus_comments qc
			ON qc.ID = com.ID
	WHERE p.UserID = @UserID
	and (ac.completeddate is null
	or ac.completeddate > convert(datetime, convert(varchar, getdate() - 1, 1)))

	DECLARE @recordIds AS RecordId
	INSERT INTO @recordIds
		SELECT DISTINCT ActiveChecklistID FROM #result WHERE ActiveChecklistID IS NOT NULL
	EXEC dbo.Audit_Set @userId, @recordIds, 'ActiveChecklist', 2

	DELETE @recordIds 
	INSERT INTO @recordIds
		SELECT DISTINCT ChecklistId FROM #result WHERE ChecklistId IS NOT NULL
	EXEC dbo.Audit_Set @userId, @recordIds, 'Checklist', 2

	DELETE @recordIds 
	INSERT INTO @recordIds
		SELECT DISTINCT CommentId FROM #result WHERE CommentId IS NOT NULL
	EXEC dbo.Audit_Set @userId, @recordIds, 'Comment', 2

	ALTER TABLE #result DROP COLUMN ChecklistId
	ALTER TABLE #result DROP COLUMN CommentId

	SELECT *
	FROM #result
	ORDER BY PriorityRank, PriorityNbr, DueTime
END
GO

CREATE OR ALTER PROC [dbo].[PriorityListSet_GetComments]
	@SetID int,
	@UserID int,
	@StartTime datetime,
	@AllUsers bit = 0
AS
BEGIN
	SET NOCOUNT ON

	select 
		u.userid, 
		l.activechecklistid, 
		--'[' + c.initials + '] '+ case when c.comments like '%href%' then c.comments else replace(c.comments, '''', '''''') end as comments,--commented by venkat 11/02/2017
		'[' + c.initials + '] '+ c.comments as comments,
		l.id,
		c.id as CommentId,
		c.DisplayOrder
	into #result
	from prioritylistusers u
	inner join prioritylist l
	on l.userid = u.userid
	inner join qstatus_comments c
	on c.foreignkeyid = l.activechecklistid
	and c.specialtask = 0
	and (c.userid = @userid OR @AllUsers = 1)
	and c.commentdt > @starttime
	where u.setid = @setid
	and len(c.comments) > 0
	order by u.userid, c.displayorder

	DECLARE @recordIds AS RecordId
	INSERT INTO @recordIds
		SELECT DISTINCT CommentId FROM #result WHERE CommentId IS NOT NULL

	EXEC dbo.Audit_Set @userId, @recordIds, 'Comment', 2

	SELECT userid, activechecklistid, comments, id
	FROM #result
	ORDER BY UserID, DisplayOrder
END
GO

CREATE OR ALTER PROCEDURE [dbo].[QCheck_ActiveInstanceAlert_SingleUser](
	@ActiveInstanceID int,
	@ChecklistName varchar(500),
	@Alertee int,
	@AlertType varchar(10)
)
AS

BEGIN
	SET NOCOUNT ON

	DECLARE @mail_to VARCHAR(500)
	DECLARE @mail_from VARCHAR(500)
	DECLARE @mail_subject VARCHAR(500)
	
	DECLARE @imgURL VARCHAR(50)
	
	-- Get app configuration
	DECLARE @AppURL VARCHAR(50), @ImagesURL VARCHAR(50), @ExternalURL VARCHAR(50), @BaseDomain VARCHAR(50), 
		@FromAddress VARCHAR(50), @AppName VARCHAR(50), @GradingAddress VARCHAR(50), @AutomationAddress VARCHAR(50)		
	SELECT @AppURL = AppURL, 
		@ImagesURL = ImagesURL, 
		@ExternalURL = ExternalURL, 
		@BaseDomain = BaseDomain, 
		@FromAddress = FromAddress, 
		@Appname = AppName, 
		@GradingAddress = GradingAddress, 
		@AutomationAddress = AutomationAddress 
		FROM QCheck_AppSettings 
		WHERE ID = 1
	
	-- 3/24/2014 dalvarado - The code above has always been buggy because @Alertee is a group id, not a user id. Instead just using
	-- the values from the app configuration section.
	SET @imgURL = @ImagesURL

	SELECT @mail_to = ''

	SELECT @mail_to = @mail_to + Email + ';' FROM QCheck_Users u
	inner join qcheck_groupmembership gm
	on gm.userid = u.id
	where gm.groupID = @Alertee AND u.IsDeleted = 0

	--If there are no recipients, don't bother sending
	if(len(@mail_to) = 0) RETURN	

	-- AUDIT BEGIN
	DECLARE @userIds AS RecordId, @recordIds AS RecordId, @userId AS INT

	INSERT INTO @userIds
		SELECT u.ID 
		FROM QCheck_Users u
		INNER JOIN qcheck_groupmembership gm ON gm.userid = u.id
		WHERE gm.groupID = @Alertee AND u.IsDeleted = 0

	SELECT DISTINCT 
		 ActiveChecklistId = a.ID
		,ChecklistId = c.ID
		,ItemId = k.ID
		,ActiveItemId = ai.ID 
	INTO #auditId
	FROM QCheck_ActiveChecklists a
	INNER JOIN QCheck_ActiveAssignments b ON b.ActiveChecklistID = a.ID
	INNER JOIN QCheck_Assignments c ON b.AssignmentsID = c.ID and c.IsDeleted = 0
	INNER JOIN QCheck_ChecklistInstances e ON a.InstanceID = e.ID and e.isDeleted = 0
	INNER JOIN QCheck_Checklists f ON e.ChecklistID = f.ID and f.isDeleted = 0
	INNER JOIN QCheck_Items k on k.checklistID = f.ID AND k.IsDeleted = 0
	LEFT OUTER JOIN QCheck_ActiveItems ai on ai.ActiveChecklistID = a.ID and ai.ChecklistItemID = k.ID
	WHERE a.ID = @ActiveInstanceID

	DECLARE oCursor CURSOR FOR
		SELECT DISTINCT Id FROM @userIds

	OPEN oCursor
	FETCH NEXT FROM oCursor INTO @userId
	WHILE @@FETCH_STATUS = 0 BEGIN
		DELETE @recordIds
		INSERT INTO @recordIds
			SELECT DISTINCT ChecklistId
			FROM #auditId
			WHERE ChecklistId IS NOT NULL
		EXEC dbo.Audit_Set @userId, @recordIds, 'Checklist', 2

		DELETE @recordIds
		INSERT INTO @recordIds
			SELECT DISTINCT ItemID
			FROM #auditId
			WHERE ItemID IS NOT NULL
		EXEC dbo.Audit_Set @userId, @recordIds, 'Item', 2

		DELETE @recordIds
		INSERT INTO @recordIds
			SELECT DISTINCT ActiveItemId
			FROM #auditId
			WHERE ActiveItemId IS NOT NULL
		EXEC dbo.Audit_Set @userId, @recordIds, 'ActiveItem', 2

		DELETE @recordIds
		INSERT INTO @recordIds
			SELECT DISTINCT ActiveChecklistId
			FROM #auditId
			WHERE ActiveChecklistId IS NOT NULL
		EXEC dbo.Audit_Set @userId, @recordIds, 'ActiveChecklist', 2

		FETCH NEXT FROM oCursor INTO @userId
	END
	CLOSE oCursor
	DEALLOCATE oCursor
	-- AUDIT END
	
	SET @mail_from = @FromAddress
	
	If @AlertType = 'Start' SET @mail_subject = 'Alert - ' + @ChecklistName + ' has started'
	If @AlertType = 'Complete' SET @mail_subject = ' Alert - ' + @ChecklistName + ' has been completed'

	declare @html table (id int identity(1,1), html varchar(max))
	insert into @html exec QCheck_ActiveInstanceAlert_SingleUser_HTML @ActiveInstanceID, @AlertType, @appURL, @imgURL
	declare @htmlstr varchar(max), @onerow varchar(max), @rowid int
	while exists (select 1 from @html)
	begin
		select top 1 @rowid = id from @html order by id asc
		select @onerow = html from @html where id = @rowid
		select @htmlstr = isnull(@htmlstr, '') + isnull(@onerow, '') 
		delete from @html where id = @rowid
	end
	
	
	exec [master].[dbo].[xp_smtp_sendmail]
			@to = @mail_to,
			@from = @mail_from,
			@subject = @mail_subject,
			@message = @htmlstr
END
GO

CREATE OR ALTER PROC [dbo].[QCheck_ActiveTasksAssigned] 
	@UserID As Int,
	@WithStatus As Bit = 0
AS
BEGIN
	SET NOCOUNT ON

	SELECT Distinct
		i.ID As instanceID,
		udt.ID As upcomingID,
		CASE WHEN ac.CompletedDate IS NULL THEN
			1
		ELSE
			2
		END AS HistoryType,
		ISNULL(ac.ID, aca.ID) As HistoryID,
		c.Name as 'Checklist Name', 
		dbo.QCheck_AssigneesList(isNull(i.ID,0)) as Assignees,
		dbo.QCheck_ManagersList(isNull(c.ID,0)) as Managers,
		CASE WHEN s.FreqType = 1 THEN
			'ONE TIME'
		WHEN s.FreqType = 2 THEN
			'DAILY'
		WHEN s.FreqType = 3 THEN
			'WEEKLY'
		WHEN s.FreqType = 4 THEN
			CASE WHEN s.FreqRecurrance = 4 THEN
				'QUARTERLY'
			ELSE
				'MONTHLY'
			END
		WHEN s.FreqType = 5 THEN
			'YEARLY'
		END As Frequency,
		isNull(ac.CompletedDate, aca.CompletedDate) as 'Last Completed',
		active.DueTime as 'Current Due Time', 
		active.ID as ActiveID,
		udt.duetime as nextduedate,
		c.ID AS ChecklistId
	INTO #result
	FROM
		QCheck_Checklists c
	LEFT OUTER JOIN
		QCheck_ChecklistInstances i 
	ON
		i.ChecklistID = c.ID
 AND
		i.IsDeleted = 0
	INNER JOIN
		(SELECT ID, DueTime, InstanceID FROM QCheck_ActiveChecklists WHERE ID IN
		(SELECT MIN(ID) as ID
		FROM 
			QCheck_ActiveChecklists
		--WHERE
			--completedDate is null
		GROUP BY InstanceID)) active
	ON
		active.InstanceID = i.ID
	LEFT OUTER JOIN
		(
			SELECT 
				actt.ActiveChecklistID
			FROM
				QStatus_GroupReport gr
			INNER JOIN
				QStatus_Report r
			ON
				r.IsDeleted = 0
			AND
				gr.ReportID = r.ID
			INNER JOIN
				QCheck_Groups g
			ON
				g.ID = gr.GroupID
			INNER JOIN 
				QCheck_GroupMembership gm
			ON
				gm.GroupID = g.ID
			AND 
				gm.UserID = @UserID
			INNER JOIN
				QStatus_TaskTypes tt
			on
				tt.ReportID = r.ID
			AND
				tt.IsDeleted = 0
			INNER JOIN
				QStatus_ActiveChecklistTaskType actt
			on
				actt.TaskType = tt.ID
		) mytasktypes
	ON
		mytasktypes.ActiveChecklistID = active.ID
	LEFT OUTER JOIN
		QCheck_Schedule s
	ON
		s.ID = i.ScheduleID
	LEFT OUTER JOIN
		(
		SELECT a1.ID, a1.InstanceID, a1.completedDate
		FROM
			QCheck_ActiveChecklists a1
		INNER JOIN
			(
			SELECT 
				InstanceID, MAX(completeddate) as completedDate
			FROM
				QCheck_ActiveChecklists a
			GROUP BY
				 InstanceID
			) a2
		ON a1.InstanceID = a2.InstanceID and a1.completeddate = a2.completeddate
		) ac
	ON
		ac.InstanceID = i.ID
	LEFT OUTER JOIN
		(SELECT a1.ID, a1.InstanceID, a1.completedDate
		FROM
			QCheck_ActiveChecklistArchive a1
		INNER JOIN
			(SELECT 
				InstanceID, MAX(completeddate) as completedDate
			FROM
				QCheck_ActiveChecklistArchive a
			GROUP BY
				 InstanceID
			) a2
		ON a1.InstanceID = a2.InstanceID and a1.completeddate = a2.completeddate
		) aca
	ON
		aca.InstanceID = i.ID
	INNER JOIN
		QCheck_GroupMembership gm
	ON
		gm.UserID = @UserID
	INNER JOIN
		QCheck_Groups g
	ON
		g.ID = gm.GroupID
	INNER JOIN 
		QCheck_Assignments assignedTo
	ON
		assignedTo.IsDeleted = 0
	 AND 
		assignedTo.GroupID = g.ID
	 AND
		assignedTo.InstanceID = i.ID
	LEFT OUTER JOIN
		QCheck_UpcomingDueTimes udt
	ON
		udt.InstanceID = i.ID
	AND
		udt.duetime <> active.duetime
	LEFT OUTER JOIN
		QCheck_UpcomingDueTimes udt2
	ON
		udt2.InstanceID = i.ID
	AND
		udt2.duetime < udt.duetime
	WHERE
		udt2.id is null
	and 
		mytasktypes.ActiveChecklistID is null

	DECLARE @recordIds AS RecordId
	INSERT INTO @recordIds
		SELECT DISTINCT ChecklistId FROM #result WHERE ChecklistId IS NOT NULL

	EXEC dbo.Audit_Set @userId, @recordIds, 'Checklist', 2

	DELETE @recordIds
	INSERT INTO @recordIds
		SELECT DISTINCT ActiveID FROM #result WHERE ActiveID IS NOT NULL

	EXEC dbo.Audit_Set @userId, @recordIds, 'ActiveChecklist', 2

	SELECT * FROM #result ORDER BY Assignees
END
GO

CREATE OR ALTER PROC [dbo].[QCheck_ActiveTasksManaged] 
	@UserID As Int
AS
BEGIN
	SET NOCOUNT ON
	SELECT
		Distinct
		i.ID As instanceID,
		udt.ID As upcomingID,
		CASE WHEN ac.CompletedDate IS NULL THEN
			1
		ELSE
			2
		END AS HistoryType,
		ISNULL(ac.ID, aca.ID) As HistoryID,
		c.Name as 'Checklist Name', 
		dbo.QCheck_AssigneesList(isNull(i.ID,0)) as Assignees,
		dbo.QCheck_ManagersList(isNull(c.ID,0)) as Managers,
		CASE WHEN s.FreqType = 1 THEN
			'ONE TIME'
		WHEN s.FreqType = 2 THEN
			'DAILY'
		WHEN s.FreqType = 3 THEN
			'WEEKLY'
		WHEN s.FreqType = 4 THEN
			CASE WHEN s.FreqRecurrance = 4 THEN
				'QUARTERLY'
			ELSE
				'MONTHLY'
			END
		WHEN s.FreqType = 5 THEN
			'YEARLY'
		END As Frequency,
		isNull(ac.CompletedDate, aca.CompletedDate) as 'Last Completed',
		active.DueTime as 'Current Due Time', 
		active.ID as ActiveID,
		udt.duetime as nextduedate,
		c.ID AS ChecklistId
	INTO #result
	FROM
		QCheck_Checklists c
	LEFT OUTER JOIN
		QCheck_ChecklistInstances i 
	ON
		i.ChecklistID = c.ID
 AND
		i.IsDeleted = 0
	INNER JOIN
		(SELECT * FROM QCheck_ActiveChecklists WHERE ID IN
		(SELECT MIN(ID) as ID
		FROM 
			QCheck_ActiveChecklists
		--WHERE
			--completedDate is null
		GROUP BY InstanceID)) active
	ON
		active.InstanceID = i.ID
	LEFT OUTER JOIN
		(
			SELECT 
				actt.ActiveChecklistID
			FROM
				QStatus_GroupReport gr
			INNER JOIN
				QStatus_Report r
			ON
				r.IsDeleted = 0
			AND
				gr.ReportID = r.ID
			INNER JOIN
				QCheck_Groups g
			ON
				g.ID = gr.GroupID
			INNER JOIN 
				QCheck_GroupMembership gm
			ON
				gm.GroupID = g.ID
			AND 
				gm.UserID = @UserID
			INNER JOIN
				QStatus_TaskTypes tt
			on
				tt.ReportID = r.ID
			AND
				tt.IsDeleted = 0
			INNER JOIN
				QStatus_ActiveChecklistTaskType actt
			on
				actt.TaskType = tt.ID
		) mytasktypes
	ON
		mytasktypes.ActiveChecklistID = active.ID
	LEFT OUTER JOIN
		QCheck_Schedule s
	ON
		s.ID = i.ScheduleID
	LEFT OUTER JOIN
		(
		SELECT a1.ID, a1.InstanceID, a1.completedDate
		FROM
			QCheck_ActiveChecklists a1
		INNER JOIN
			(
			SELECT 
				InstanceID, MAX(completeddate) as completedDate
			FROM
				QCheck_ActiveChecklists a
			GROUP BY
				 InstanceID
			) a2
		ON a1.InstanceID = a2.InstanceID and a1.completeddate = a2.completeddate
		) ac
	ON
		ac.InstanceID = i.ID
	LEFT OUTER JOIN
		(SELECT a1.ID, a1.InstanceID, a1.completedDate
		FROM
			QCheck_ActiveChecklistArchive a1
		INNER JOIN
			(SELECT 
				InstanceID, MAX(completeddate) as completedDate
			FROM
				QCheck_ActiveChecklistArchive a
			GROUP BY
				 InstanceID
			) a2
		ON a1.InstanceID = a2.InstanceID and a1.completeddate = a2.completeddate
		) aca
	ON
		aca.InstanceID = i.ID
	INNER JOIN
		QCheck_GroupMembership gm
	ON
		gm.UserID = @UserID
	INNER JOIN QCheck_Groups g
	ON
		g.ID = gm.GroupID
	INNER JOIN
		QCheck_ChecklistManagers m
	ON
		c.ID = m.ChecklistID
	 AND
		m.ManagerGroupID = g.ID
	 AND
		m.IsDeleted = 0
	INNER JOIN 
		QCheck_Assignments assignedTo
	ON
		assignedTo.IsDeleted = 0
	 AND 
		NOT (assignedTo.GroupID = g.ID)
	 AND
		assignedTo.InstanceID = i.ID
	LEFT OUTER JOIN
		QCheck_UpcomingDueTimes udt
	ON
		udt.InstanceID = i.ID
	AND
		udt.duetime <> active.dueTime
	LEFT OUTER JOIN
		QCheck_UpcomingDueTimes udt2
	ON
		udt2.InstanceID = i.ID
	AND
		udt2.duetime < udt.duetime
	WHERE
		
		c.IsDeleted = 0
	and
		udt2.id is null
	and 
		mytasktypes.ActiveChecklistID is null

	DECLARE @recordIds AS RecordId
	INSERT INTO @recordIds
		SELECT DISTINCT ChecklistId FROM #result WHERE ChecklistId IS NOT NULL

	EXEC dbo.Audit_Set @userId, @recordIds, 'Checklist', 2

	DELETE @recordIds
	INSERT INTO @recordIds
		SELECT DISTINCT ActiveID FROM #result WHERE ActiveID IS NOT NULL

	EXEC dbo.Audit_Set @userId, @recordIds, 'ActiveChecklist', 2

	SELECT * FROM #result ORDER BY Assignees
END
GO

CREATE OR ALTER PROC[dbo].[QCheck_AddItem]
	@ChecklistID INT,
	@SequenceNum INT = null,
	@ItemTypeID INT,
	@Text	varchar(max),
	@URL	varchar(1000),
	@UserId int
AS
BEGIN
	SET NOCOUNT ON
	DECLARE @recordIds AS RecordId, @itemId INT

	If @SequenceNum is null 
	BEGIN
		SELECT @SequenceNum = isnull(max([SequenceNum]),0) + 1
		FROM QCheck_Items
		WHERE [ChecklistID] = @ChecklistID
		AND IsDeleted = 0	
	END
	ELSE
	BEGIN
		-- if any item exists with the current sequence, then
		-- move everything up one to put it in place
		INSERT INTO @recordIds
			SELECT ID 
			FROM QCheck_Items
			WHERE [SequenceNum] >= @SequenceNum
			AND EXISTS (
				SELECT ID FROM QCheck_Items 
				WHERE [ChecklistID] = @ChecklistID
				AND [SequenceNum] = @SequenceNum
			)
		EXEC dbo.Audit_Set @userId, @recordIds, 'Item', 3
	
		UPDATE QCheck_Items
		SET [SequenceNum] = [SequenceNum] + 1
		WHERE [SequenceNum] >= @SequenceNum
		AND EXISTS
		(
			SELECT ID FROM QCheck_Items 
			WHERE [ChecklistID] = @ChecklistID
			AND [SequenceNum] = @SequenceNum
		)
	END
	

	-- now insert the new item directly into the table
	INSERT INTO QCheck_Items ([ChecklistID], [SequenceNum], [ItemTypeID], [Text], [URL])
	VALUES (@ChecklistID,@SequenceNum,@ItemTypeID,@Text,@URL)
	SET @itemId = SCOPE_IDENTITY()

	DELETE @recordIds
	INSERT INTO @recordIds VALUES(@itemId)
	EXEC dbo.Audit_Set @userId, @recordIds, 'Item', 1
END
GO


CREATE OR ALTER PROC [dbo].[QCheck_Approval_AddItem]
	@ChangeID INT,
	@ChecklistID INT,
	@SequenceNum INT = null,
	@ItemTypeID INT,
	@Text	varchar(max),
	@URL	varchar(1000),
	@UserId INT,
	@ReturnID INT = NULL OUTPUT
AS
BEGIN
	SET NOCOUNT ON
	DECLARE @recordIds AS RecordId

	IF @SequenceNum IS NULL BEGIN

		SELECT @SequenceNum = isnull(max([SequenceNum]),0) + 1
		FROM QCheck_Approval_Items
		WHERE 
			ChangeRequestID = @ChangeID
			AND [ChecklistID] = @ChecklistID
			AND IsDeleted = 0

	END ELSE BEGIN
		-- if any item exists with the current sequence, then
		-- move everything up one to put it in place	
		INSERT INTO @recordIds
			SELECT ID 
			FROM QCheck_Approval_Items
			WHERE 
				[SequenceNum] >= @SequenceNum
				AND EXISTS (
					SELECT [ID] 
					FROM QCheck_Approval_Items 
					WHERE 
						ChangeRequestID = @ChangeID
						AND ChecklistID = @ChecklistID
						AND SequenceNum = @SequenceNum
				)
		EXEC dbo.Audit_Set @userId, @recordIds, 'ApprovalItem', 3

		UPDATE QCheck_Approval_Items
		SET [SequenceNum] = [SequenceNum] + 1
		WHERE 
			[SequenceNum] >= @SequenceNum
			AND EXISTS (
				SELECT [ID] 
				FROM QCheck_Approval_Items 
				WHERE 
					ChangeRequestID = @ChangeID
					AND ChecklistID = @ChecklistID
					AND SequenceNum = @SequenceNum
			)
	END
	
	-- now insert the new item into the holding table
	INSERT INTO QCheck_Approval_Items (
		ChangeRequestID,
		ItemID,
		ChecklistID, 
		SequenceNum, 
		ItemTypeID, 
		[Text], 
		URL,
		IsDeleted
	) VALUES (
		@ChangeID,
		-1,
		@ChecklistID,
		@SequenceNum,
		@ItemTypeID,
		@Text,
		@URL,
		0
	)
	
	SELECT @ReturnID = @@IDENTITY

	DELETE @recordIds
	INSERT INTO @recordIds VALUES(@ReturnID)
	EXEC dbo.Audit_Set @userId, @recordIds, 'ApprovalItem', 1
END
GO

-- This stored procedure will delete an item from a checklist (mark isDeleted - true).
CREATE OR ALTER PROC [dbo].[QCheck_Approval_DelItem]
	@ID INT,
	@UserId INT
AS
BEGIN
	SET NOCOUNT ON	
	
	--basic update here - checklist ID is not needed here but left for redundancy
	DECLARE @ItemID INT, @recordIds AS RecordId
	INSERT INTO @recordIds VALUES(@ID)

	SELECT @ItemID = ItemID
	FROM QCheck_Approval_Items
	WHERE [ID] = @ID

	IF @ItemID = -1 BEGIN
		EXEC dbo.Audit_Set @userId, @recordIds, 'ApprovalItem', 4

		-- This was a new item added for the change, just delete it from the change
		DELETE FROM QCheck_Approval_Items
		WHERE [ID] = @ID

	END ELSE BEGIN	
		EXEC dbo.Audit_Set @userId, @recordIds, 'ApprovalItem', 3

		-- This is an existing checklist item that is being requested to remove from the checklist
		UPDATE QCheck_Approval_Items
		SET IsDeleted = 1
		WHERE [ID] = @ID

	END
END
GO

CREATE OR ALTER PROC [dbo].[QCheck_Approval_GetChecklistName] (
	@ChangeID INT,
	@UserId INT,
	@ChecklistName VARCHAR(500) OUTPUT
) AS

BEGIN
	SET NOCOUNT ON

	DECLARE @recordIds AS RecordId
	INSERT INTO @recordIds VALUES(@ChangeID)

	EXEC dbo.Audit_Set @userId, @recordIds, 'ChangeRequest', 2

	SET @ChecklistName = NULL

	SELECT 
		@ChecklistName = [Name]
	FROM 
		QCheck_Approval_Checklists c
		INNER JOIN QCheck_Approval_ChangeRequestItems CRI
			ON c.CRItemID = CRI.[ID]
			AND CRI.Approved = 1
	WHERE 
		c.ChangeRequestID = @ChangeID

	IF @ChecklistName IS NULL BEGIN

		SELECT @ChecklistName = dbo.QCheck_Approval_CRChecklistName(@ChangeID)

	END

END
GO

CREATE OR ALTER PROC [dbo].[QCheck_Approval_GetSupervisorChangeRequests] 
	@UserID INT, -- The UserID of the controller,
	@ID INT = NULL,
	@Sort int = 0 --0 = by request date, 1= by name, 2 = by new deadline
AS
BEGIN
	SET NOCOUNT ON
	-- Pulls back the list of change requests requiring the given supervisor's approval or rejection
	SELECT 
		CR.[ID],
		CR.RequestingUser,
		RU.FullName,
		Ru.Email,
		CR.RequestDate,
		CR.Comment,
		crc.ID AS ChecklistID,
		c.Name AS ChecklistName,
		'' as Controllers,--dbo.QCheck_ManagersList(crc.ID) AS Controllers,
		'' as Assignees,--dbo.QCheck_AssigneesList(ci.InstanceID) AS Assignees
		dbo.QCheck_Approval_ExtensionLength(cr.id) as extensiondays,
		dbo.QCheck_Approval_ExtensionCount(cr.id) as extensioncount,
		deadlinechecklist.completeddate,
		case when ac.id is not null and ac.duetime <> ac.origduetime and ac.duetime < getdate() 
			then 
			'** Requested deadline has passed! Upon approval, deadline will be set to ' +CONVERT(VARCHAR, dateadd(hour, datepart(hour,ac.duetime), dbo.Util_addofficedays(getdate(), 1)), 101)+ ' instead**'
			else ''
		end as DatePassedMessage,
		AC.DueTime
	INTO #result
	FROM 
		QCheck_Approval_ChangeRequests CR
		inner join qcheck_approval_changerequestchecklist crc
			on crc.changerequestid = cr.id
		inner join qcheck_checklists c
			on c.id = crc.id
		INNER JOIN QCheck_ChecklistManagers CM
			ON CM.ChecklistID = c.ID
			AND CM.IsDeleted = 0
		INNER JOIN QCheck_Groups G
			ON CM.ManagerGroupID = G.[ID]
		INNER JOIN QCheck_GroupMembership GM
			ON G.[ID] = GM.GroupID
		INNER JOIN QCheck_Users CU
			ON GM.UserID = CU.[ID]
		INNER JOIN QCheck_Users RU
			ON CR.RequestingUser = RU.[ID]
		LEFT OUTER JOIN QCheck_Approval_ActiveChecklists AC
			ON AC.ChangeRequestID = CR.ID
		OUTER APPLY 
				(
					SELECT id, completeddate FROM QCheck_ActiveChecklists_All
					WHERE id = AC.activechecklistID
				) deadlinechecklist
	WHERE
		CR.IsActive = 1
		AND CR.Approved = 0
		AND CR.Rejected = 0
		AND CR.ReadyForSupervisor = 1
		AND CU.[ID] = @UserID	
		AND (CR.ID = @ID or @ID is null)

	DECLARE @recordIds AS RecordId
	INSERT INTO @recordIds
		SELECT DISTINCT ChecklistId FROM #result WHERE ChecklistId IS NOT NULL
	EXEC dbo.Audit_Set @userId, @recordIds, 'Checklist', 2

	DELETE @recordIds
	INSERT INTO @recordIds
		SELECT DISTINCT ID FROM #result WHERE ID IS NOT NULL
	EXEC dbo.Audit_Set @userId, @recordIds, 'ChangeRequest', 2

	SELECT *
	FROM #result
	ORDER BY
		CASE 
		 WHEN @Sort = 0 then convert(varchar,RequestDate, 120) 
		 WHEN @Sort = 1 then FullName
		 ELSE convert(varchar, duetime, 120)
		END
END
GO

CREATE OR ALTER PROC [dbo].[QCheck_Approval_UpdateChecklistName] 
	@ChangeID INT,
	@ChecklistID INT,
	@Name VARCHAR(500),
	@UserId INT
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @recordIds AS RecordId

	IF EXISTS(SELECT * FROM QCheck_Approval_Checklists WHERE ChangeRequestID = @ChangeID AND ChecklistID = @ChecklistID) BEGIN
		INSERT INTO @recordIds 
			SELECT ID
			FROM QCheck_Approval_Checklists
			WHERE ChangeRequestID = @ChangeID AND ChecklistID = @ChecklistID
		EXEC dbo.Audit_Set @userId, @recordIds, 'ApprovalChecklist', 3

		UPDATE QCheck_Approval_Checklists
		SET [Name] = @Name
		WHERE ChangeRequestID = @ChangeID
		AND ChecklistID = @ChecklistID
	END ELSE BEGIN
		DECLARE @approvalRequestId INT

		INSERT INTO QCheck_Approval_Checklists (
			ChangeRequestID,
			ChecklistID,
			[Name],
			IsDeleted,
			Owner,
			Template
		)
			SELECT
				@ChangeID,
				@ChecklistID,
				@Name,
				IsDeleted,
				Owner,
				Template
			FROM
				QCheck_Checklists
			WHERE
				[ID] = @ChecklistID

		SET @approvalRequestId = SCOPE_IDENTITY()
		INSERT INTO @recordIds VALUES(@approvalRequestId)
		EXEC dbo.Audit_Set @userId, @recordIds, 'ApprovalChecklist', 1
	END

END
GO

CREATE OR ALTER PROC [dbo].[QCheck_Approval_UpdateItem]
	@ChangeID INT,
	@ID INT,
	@ChecklistID INT,
	@SequenceNum INT = null,
	@ItemTypeID INT = null,
	@Text	varchar(1000) = null,
	@URL	varchar(1000) = null,
	@UserId INT
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @recordIds AS RecordId

	-- move everything up if there is already one at that sequence
	IF NOT @SequenceNum IS NULL BEGIN
		INSERT INTO @recordIds
			SELECT ID FROM QCheck_Approval_Items
			WHERE [SequenceNum] >= @SequenceNum
			AND EXISTS (
				SELECT [ID] FROM QCheck_Approval_Items 
				WHERE 
					ChangeRequestID = @ChangeID
					AND ChecklistID = @ChecklistID
					AND SequenceNum = @SequenceNum
			)
		EXEC dbo.Audit_Set @userId, @recordIds, 'ApprovalItem', 3

		UPDATE QCheck_Approval_Items
		SET [SequenceNum] = [SequenceNum] + 1
		WHERE [SequenceNum] >= @SequenceNum
		AND EXISTS (
			SELECT [ID] FROM QCheck_Approval_Items 
			WHERE 
				ChangeRequestID = @ChangeID
				AND ChecklistID = @ChecklistID
				AND SequenceNum = @SequenceNum
		)
	END

	-- update the item itself
	DELETE @recordIds
	INSERT INTO @recordIds VALUES(@ID)
	EXEC dbo.Audit_Set @userId, @recordIds, 'ApprovalItem', 3
	
	UPDATE QCheck_Approval_Items
	SET
		SequenceNum = IsNull(@SequenceNum, SequenceNum),
		ItemTypeID = IsNull(@ItemTypeID, ItemTypeID),
		[Text] = IsNull(@Text, [Text]),
		URL = IsNull(@URL, URL)
	WHERE 
		[ID] = @ID
END
GO

-- This stored procedure will mark a checklist as Complete
-- ID is the checklist ID
-- if all items are not marked as complete, then it will not be completed
-- and a 0 will be returned

CREATE OR ALTER PROCEDURE [dbo].[QCheck_CompleteChecklist](
	@ID INT,
	@CompletedBy int,
	@IsNA bit = 0,
	@NAReason varchar(max) = '',
	@isComplete bit output,
	@UpcomingDueTimeID INT = -1 OUTPUT,
	@NewActiveChecklistID INT = -1 OUTPUT
)
 AS

BEGIN
	SET NOCOUNT ON

	DECLARE @numChecks int,
			@numDone int,
			@numLeft int,
			@AssignedToChecklist INT,
			@ControlsChecklist INT, 
			@AlreadyComplete BIT = 0,
			@recordIds AS RecordId
			
	SET @AssignedToChecklist = 0
	SET @ControlsChecklist = 0
	
	SELECT 
		@AssignedToChecklist = gm.UserID,
		@AlreadyComplete = case when ac.CompletedDate is null then 0 else 1 end
	FROM
		QCheck_ActiveChecklists ac
		INNER JOIN QCheck_Assignments a
			ON a.InstanceID = ac.InstanceID
		INNER JOIN QCheck_Groups g
			ON g.ID = a.GroupId
		INNER JOIN QCheck_GroupMembership gm
			ON gm.GroupID = g.ID
			AND gm.UserID = @CompletedBy
			AND ac.ID = @ID
	
	SELECT
		@ControlsChecklist = gm.UserID
	FROM
		QCheck_ActiveChecklists ac
		INNER JOIN QCheck_ChecklistInstances ci
			ON ac.InstanceID = ci.ID
		INNER JOIN QCheck_Checklists c
			ON ci.ChecklistID = c.ID
		INNER JOIN QCheck_ChecklistManagers cm
			ON c.ID = cm.ChecklistID
			AND cm.IsDeleted = 0
		INNER JOIN QCheck_Groups g
			ON cm.ManagerGroupID = g.ID
		INNER JOIN QCheck_GroupMembership gm
			ON g.ID = gm.GroupID
			AND gm.UserID = @CompletedBy
			AND ac.ID = @ID
	
	SET @isComplete = 0

	--find the number of checks that must be completed
	SELECT 
		@numChecks = count(d.[ID]) 
	FROM
		QCheck_ActiveChecklists a
		INNER JOIN QCheck_ChecklistInstances b
			ON a.InstanceID = b.[ID]
		INNER JOIN QCheck_Checklists c
			ON b.ChecklistID = c.[ID]
		INNER JOIN QCheck_Items d
			ON d.ChecklistID = c.ID
	WHERE 
		a.[ID] = @ID
		AND d.ItemTypeID = 1
		AND d.IsDeleted = 0

	--find the number of checks that are done
	SELECT 
		@numDone = count(d.[ID]) 
	FROM
		QCheck_ActiveChecklists a
		INNER JOIN QCheck_ChecklistInstances b
			ON a.InstanceID = b.[ID]
		INNER JOIN QCheck_Checklists c
			ON b.ChecklistID = c.[ID]
		INNER JOIN QCheck_Items d
			ON d.ChecklistID = c.ID
		INNER JOIN QCheck_ActiveItems e
			ON d.[ID] = e.ChecklistItemID AND e.ActiveChecklistID = a.[ID]
	WHERE 
		a.[ID] = @ID
		AND d.ItemTypeID = 1
		AND d.IsDeleted = 0
		AND e.CompletedDate is not null

	--num left = total - done
	SET @numLeft = @numChecks - @numDone

	-- Mark individual checklist items complete. Assignees can mark complete if there is one step
	-- to the checklist (or one step left). Controllers can mark multiple step checklists complete
	-- per GPR 2/5/2014
	IF (@numChecks = 1 and @numLeft = 1) OR (@ControlsChecklist = 1 AND @AssignedToChecklist = 0) OR (@IsNA = 1)
	BEGIN
		DELETE @recordIds
		INSERT INTO @recordIds
			SELECT DISTINCT ID 
			FROM QCheck_ActiveItems
			WHERE ActiveChecklistID = @ID AND CompletedDate IS NULL

		EXEC dbo.Audit_Set @CompletedBy, @recordIds, 'ActiveItem', 3

		UPDATE 
			QCheck_ActiveItems
		SET 
			Completedby = @CompletedBy, 
			CompletedDate = getdate(),
			[Text] = CASE WHEN @IsNA = 1 THEN 'N/A' ELSE '' END
		WHERE 
			ActiveChecklistID = @ID
			AND CompletedDate IS NULL
		
		SELECT 
			ActiveChecklistID = @ID, 
			ChecklistItemID = i.ID, 
			[Text] = CASE WHEN @IsNA = 1 THEN 'N/A' ELSE '' END, 
			CompletedDate = GETDATE(), 
			CompletedBy = @CompletedBy
		INTO #tmp
		FROM 
			QCheck_ActiveChecklists ac
			INNER JOIN QCheck_ChecklistInstances ci
				ON ac.InstanceID = ci.ID
			INNER JOIN QCheck_Checklists c
				ON ci.ChecklistID = c.ID
			INNER JOIN QCheck_Items i
				ON i.ChecklistId = c.ID
				AND i.ItemTypeID = 1
				AND i.IsDeleted = 0
			LEFT OUTER JOIN QCheck_ActiveItems ai
				ON ai.ActiveChecklistID = @ID
				AND ai.ChecklistItemID = i.ID
		WHERE 
			ac.ID = @ID
			AND ai.ID IS NULL

		INSERT INTO QCheck_ActiveItems
			SELECT * FROM #tmp

		IF @@ROWCOUNT > 0 BEGIN
			DELETE @recordIds
			INSERT INTO @recordIds
				SELECT DISTINCT ID
				FROM dbo.QCheck_ActiveItems a
				INNER JOIN #tmp b ON b.ActiveChecklistID = a.ActiveChecklistID 
					AND b.ChecklistItemID = a.ChecklistItemID

			EXEC dbo.Audit_Set @CompletedBy, @recordIds, 'ActiveItem', 1
		END
	END
	-- if it is zero, then update the active checklist
	If @numLeft <= 0 OR (@numChecks = 1 and @numLeft = 1) OR (@ControlsChecklist = 1 AND @AssignedToChecklist = 0) OR (@IsNA = 1)
	BEGIN
		DELETE @recordIds
		INSERT INTO @recordIds
			SELECT DISTINCT ID 
			FROM QCheck_ActiveChecklists
			WHERE [ID] = @ID AND CompletedDate IS NULL

		EXEC dbo.Audit_Set @CompletedBy, @recordIds, 'ActiveChecklist', 3

		UPDATE QCheck_ActiveChecklists
		SET 
			CompletedBy = @CompletedBy,
			CompletedDate = getDate(),
			IsNA = @IsNA,
			NAReason = @NAReason
		WHERE 
			[ID] = @ID
			AND CompletedDate is null

		SET @isComplete = 1

		Declare @Priority int=0
		select @Priority=[Priority] from PriorityList where ActiveChecklistID= @ID and UserID=@CompletedBy

		if @AlreadyComplete = 0
		BEGIN
			EXEC QCheck_ActiveInstanceAlert @ID, 'Complete'

			IF @ID in (select ac.id 
					from qcheck_activechecklists ac
						inner join qcheck_checklistinstances ci
							on ci.id = ac.InstanceID
						inner join QCheck_CompletionTriggers ct
							on ct.checklistid = ci.ChecklistID and ct.isActive = 1)
			BEGIN
			 --process any triggered sp that need to be run
 DECLARE @sp varchar(255)
 DECLARE CompletionTriggers_CURS CURSOR FOR 
 select sp 
					 from qcheck_activechecklists ac
						inner join qcheck_checklistinstances ci
							on ci.id = ac.InstanceID
						inner join QCheck_CompletionTriggers ct
							on ct.checklistid = ci.ChecklistID
 where ac.ID = @ID and ct.isActive = 1
 Open CompletionTriggers_CURS
 FETCH NEXT FROM CompletionTriggers_CURS INTO @sp
 WHILE @@FETCH_STATUS = 0 BEGIN

					if @sp = 'util_CT_GuardCameraCheck'
					begin
						exec [util_CT_GuardCameraCheck] @ID
					end

 FETCH NEXT FROM CompletionTriggers_CURS INTO @sp
 END
 CLOSE CompletionTriggers_CURS
 DEALLOCATE CompletionTriggers_CURS
			END
		END

		EXEC QCheck_ActivateFutureInstancesAfterCompleted @ID, @UpcomingDueTimeID OUTPUT, @NewActiveChecklistID OUTPUT

		if Exists(select 1 from PriorityList where ActiveChecklistID= @ID and UserID=@CompletedBy)--check if this taks is in PriorityList
		 Begin
		 if(select IsNull(s.freqType,0) from QCheck_ChecklistInstances ci
		 inner JOIN QCheck_Schedule s 
			ON ci.ScheduleID = s.ID 
	 where ci.ID = (select InstanceID from QCheck_ActiveChecklists where ID=@ID))>1 --check if it's recurring
		Begin
		if (@NewActiveChecklistID is not NULL)
		--Stored proc for adding task to priority
 exec PriorityList_AddTask @UserID=@CompletedBy,@ActiveChecklistID=@NewActiveChecklistID,@Priority=@Priority
		End

		 End

	END	
	--default is @isComplete = 0

	SET NOCOUNT OFF

END
GO

-- Add a new active item. This is done when user checks a checkbox or adds comments
-- initiated from MyChecklists.aspx

CREATE OR ALTER PROC [dbo].[QCheck_CreateActiveItem]
	@ActiveChecklistID INT,
	@ChecklistItemID Int,
	@IsCompleted bit = 0,
	@CompletedBy int = null,
	@UserText varchar(1000),
	@CompletedByName varchar(50) = null output,
	@CompletedOn datetime = null output
AS
BEGIN
	SET NOCOUNT ON
	DECLARE @numChecks As Int
			,@numDone As Int
			,@numLeft As Int
			,@existID As Int
			,@prevText As VARCHAR(1000)
			,@prevIsCompleted bit 
			,@recordIds AS RecordId
	
	-- Update if it exists, insert if not
	SELECT @existID = [ID]
			,@prevText = IsNull([Text],'')
			,@prevIsCompleted = CASE WHEN [CompletedDate] IS NULL THEN 0 ELSE 1 END
	FROM QCheck_ActiveItems
	WHERE ActiveChecklistID = @ActiveChecklistID
	AND ChecklistItemID = @ChecklistItemID
	
	INSERT INTO @RowNums
	SELECT ROW_NUMBER() OVER(ORDER BY I.SequenceNum ASC) as RowNum, AI.ChecklistItemID
	FROM QCheck_ActiveItems AI
	LEFT OUTER JOIN QCheck_Items I
		ON AI.ChecklistItemID = I.ID
	WHERE AI.ActiveChecklistID = @ActiveChecklistID

	SELECT @StepNumber = RowNum
	FROM @RowNums
	WHERE ChecklistItemID = @ChecklistItemID

	IF @existID is not null 
	BEGIN
		IF NOT (@IsCompleted = @prevIsCompleted AND ISNULL(@UserText, '') = @prevText) BEGIN
			INSERT INTO @recordIds
				SELECT @existID

			EXEC dbo.Audit_Set @CompletedBy, @recordIds, 'ActiveItem', 3

			-- If it was completed, then mark completed fields
			If @IsCompleted = 1 BEGIN
				UPDATE QCheck_ActiveItems
				SET [Text] =@UserText, 
				[CompletedBy] = @CompletedBy
				WHERE [ID] = @existID
				AND (CompletedBy IS NULL OR [CompletedBy] = @CompletedBy)
			
				UPDATE QCheck_ActiveItems
				SET [CompletedDate] = getdate()
				WHERE (CompletedDate Is Null OR IsNull(@UserText,'') <> @prevText)
				AND CompletedBy = @CompletedBy
				AND [ID] = @existID
			END ELSE BEGIN
				UPDATE QCheck_ActiveItems
				SET [Text] = @UserText,
				[CompletedBy] = null,
				[CompletedDate] = null
				WHERE [ID] = @existID
				AND (CompletedBy IS NULL OR [CompletedBy] = @CompletedBy)
			END
		END
	END ELSE BEGIN
		IF NOT (@IsCompleted = 0 AND ISNULL(@UserText, '') = '') BEGIN
			-- insert since no record exists
			If @IsCompleted = 1 BEGIN
				INSERT INTO QCheck_ActiveItems
				([ActiveChecklistID],[ChecklistItemID], [Text], [CompletedBy], [CompletedDate])
				SELECT @ActiveChecklistID, @ChecklistItemID, @UserText, @CompletedBy, getdate()
				WHERE NOT EXISTS(
				SELECT ID FROM QCheck_ActiveItems
				WHERE ActiveChecklistID = @ActiveChecklistID
				AND ChecklistItemID = @ChecklistItemID
				)
				SET @existID = SCOPE_IDENTITY()
			END ELSE BEGIN
				INSERT INTO QCheck_ActiveItems
				([ActiveChecklistID],[ChecklistItemID], [Text])
				SELECT @ActiveChecklistID, @ChecklistItemID, @UserText
				WHERE NOT EXISTS(
				SELECT ID FROM QCheck_ActiveItems
				WHERE ActiveChecklistID = @ActiveChecklistID
				AND ChecklistItemID = @ChecklistItemID
				)
				SET @existID = SCOPE_IDENTITY()
			END

			INSERT INTO @recordIds
				SELECT @existID

			EXEC dbo.Audit_Set @CompletedBy, @recordIds, 'ActiveItem', 1
		END
	END

	SELECT
		@CompletedByName = isnull(QCheck_Users.[FullName], ''),
		@CompletedOn = [CompletedDate]
	FROM 
		QCheck_ActiveItems
		LEFT JOIN QCheck_Users
			ON QCheck_Users.ID = QCheck_ActiveItems.CompletedBy
	WHERE 
		QCheck_ActiveItems.ID = @existID
END
GO

CREATE OR ALTER PROC [dbo].[QCheck_CreateSimple_part1]
	@ID INT OUTPUT,
	@Name varchar(500),
	@Priority int = 1,
	@DueDate datetime,
	@CreatedBy int,
	@TaskType int = null,
	@PrevFreqType int = 0 output,
	@RowsUpdated int = 0 output,
	@NewInstanceID int output,
	@NewActiveID int output,
	@GroupID int,
	@Activate bit = 1,
	@IsReminder bit = 0,
	@ReminderDate datetime = NULL,
	@AddToPriorityList bit=0--added by venkat 04/20/2017
AS
BEGIN
	SET NOCOUNT ON
	
	if @ReminderDate is null set @ReminderDate = @DueDate

	DECLARE @UserID int,
			@FolderID int,
			@FolderName varchar(50),
			@DueTime int,
			@recordIds AS RecordId,
			@PrevSchedule bit = 0,
			@ReportID int = 0

	SELECT @DueTime = duetime FROM QCheck_UserDefaultTimes WHERE UserID = @CreatedBy

	IF @DueTime IS NULL
		SELECT @DueTime = duetime from QCheck_UserDefaultTimes WHERE UserID = -1
	
	SELECT @ReportID = reportID
	FROM QStatus_TaskTypes
	WHERE ID = @TaskType

	INSERT INTO QCheck_Checklists ([Name], Owner) VALUES (@Name, @CreatedBy)
	SELECT @ID = @@IDENTITY	

	INSERT INTO @recordIds VALUES(@ID)
	EXEC dbo.Audit_Set @CreatedBy, @recordIds, 'Checklist', 1

	-- 2011 dalvarado
	-- Changed up the rules a bit. Before, if this task was created from a status
	-- report then all report controllers were controllers of the task. Now, the
	-- rules are the same no matter where a task was created. The task creator is
	-- always the controller. If this is a supervisor controlled task, then the 
	-- task controller will be overridden by whoever was chosen in the interface.

	-- Creator is the controller
	DECLARE @ControllerGroupID int
	SELECT @ControllerGroupID = ID
	FROM QCheck_Groups
	WHERE owner = @CreatedBy
	AND SingleMemberGroup = 1

	INSERT INTO QCheck_ChecklistManagers
	(ChecklistID, ManagerGroupID)
	VALUES (@ID, @ControllerGroupID)

	-- Do the report stuff if this task was created from a status report
	IF @ReportID > 0 BEGIN

		DELETE FROM QStatus_ReportFolders
		WHERE folderid not in (SELECT ID FROM QCheck_Folders)

		DECLARE FOLDERCREATE CURSOR FOR 	
			SELECT DISTINCT 
				u.ID, 
				CASE 
					WHEN len(r.Name) > 41 THEN 'Status - ' + LEFT(r.Name, 38)+'...'
					ELSE 'Status - ' + r.Name
				END
			FROM 
				QStatus_GroupReport gr
				INNER JOIN QCheck_Groups g
					ON g.ID = gr.GroupID
				INNER JOIN QCheck_Groupmembership gm
					ON gm.GroupID = g.ID
				INNER JOIN Qstatus_Report r
					ON gr.ReportID = r.ID
					AND r.ID = @ReportID
				INNER JOIN QCheck_Users u
					ON u.ID = gm.UserID 
					AND u.IsDeleted = 0
				LEFT OUTER JOIN (
					SELECT f.UserID, rf.ReportID
					FROM QCheck_Folders f
					INNER JOIN QStatus_ReportFolders rf
					ON f.ID = rf.FolderID
				) folders
					ON folders.reportID = r.ID
				AND folders.UserID = u.ID
			WHERE 
				folders.UserID is null 
		
		OPEN FOLDERCREATE

		FETCH NEXT FROM FOLDERCREATE INTO @UserID, @FolderName
		WHILE @@FETCH_STATUS = 0 BEGIN
			INSERT INTO QCheck_Folders
			SELECT @UserID, @FolderName, 0
			
			SELECT @FolderID = SCOPE_IDENTITY()

			INSERT INTO QStatus_ReportFolders
			SELECT @ReportID, @FolderID

			FETCH NEXT FROM FOLDERCREATE INTO @UserID, @FolderName
		END
		CLOSE FOLDERCREATE
		DEALLOCATE FOLDERCREATE

		INSERT INTO QCheck_FolderChecklists
			SELECT 
				@ID, rf.FolderID
			FROM 
				QStatus_ReportFolders rf
				INNER JOIN QCheck_Folders f
					ON rf.FolderID = f.ID
				INNER JOIN QCheck_Users u
					ON u.ID = f.UserID
					AND u.IsDeleted = 0
			WHERE 
				rf.ReportID = @ReportID
		
	END	

	EXEC QCheck_AddItem @ID, null, 1, @Name, '', @CreatedBy

	EXEC QCheck_CreateInstance @NewInstanceID output, @ID, '', @CreatedBy

	EXEC QCheck_AddAssignedTo @NewInstanceID, @GroupID, @CreatedBy

	---- KVS 2017-09-26 - Removing these default alerts per GPR/Nelson;
	----	Users who want them can add them manually
	---- Reminder 1 day before due
	--EXEC QCheck_AddAlert
	--		@InstanceID = @NewInstanceID, 
	--		@nagBeforeDays = 1,
	--		@nagTime = 17,
	--		@alertType = 'Reminder'
			
	---- 2/11/2014 dalvarado - Also set a reminder for 1 hour before due
	--EXEC QCheck_AddAlert
	--		@InstanceID = @NewInstanceID, 
	--		@nagBeforeDays = NULL,
	--		@nagTime = -1,
	--		@alertType = 'Reminder'
	

	EXEC QCheck_UpdateSchedule_part1 
			@InstanceID = @NewInstanceID, 
			@firstDueDate = @DueDate,
			@freqType = 1, 
			@dueTime = @DueTime,
			@PrevFreqType = @PrevFreqType output,
			@RowsUpdated = @RowsUpdated output,
			@Activate = @Activate

	IF @DueDate <> ISNULL(@ReminderDate, @DueDate) BEGIN
	
		DECLARE @SoftDueOffsetDays INT
		SELECT @SoftDueOffsetDays = DATEDIFF(DAY, @ReminderDate, @DueDate)
		
		IF @SoftDueOffsetDays > 0 BEGIN
		
			UPDATE QCheck_Schedule
			SET SoftDueOffsetDays = @SoftDueOffsetDays
			WHERE ID = (
				SELECT ScheduleID
				FROM QCheck_ChecklistInstances 
				WHERE ID = @NewInstanceID
			)
			
		END
	
	END

	SELECT @NewActiveID = ID
	FROM QCheck_ActiveChecklists
	WHERE InstanceID = @NewInstanceID

	DELETE @recordIds
	INSERT INTO @recordIds VALUES(@NewActiveID)
	EXEC dbo.Audit_Set @userId, @recordIds, 'ActiveChecklist', 3

	-- Set the reminder date to whatever was passed in, if it's not past the due time
	UPDATE QCheck_ActiveChecklists
	SET ReminderDate = @ReminderDate
	WHERE 
		[ID] = @NewActiveID
		AND @ReminderDate <= DueTime

	IF @TaskType IS NOT NULL BEGIN
		DECLARE @NewTaskTypeID int
		EXEC QCheck_AddInstanceTaskType @NewInstanceID, @TaskType, @Priority, @NewTaskTypeID OUTPUT
	END 
	

	if (@AddToPriorityList=1)
	Begin
	 
		IF OBJECT_ID('tempdb.dbo.#UserList', 'U') IS NOT NULL
		DROP TABLE #UserList;

		Create table #UserList
		(
			seq INT IDENTITY(1,1),
			UserID int	
		)
	
		Insert into #UserList
		select UserID From QCheck_GroupMembership where GroupID=@GroupID

		Declare @userListCount int
		
		SELECT @userListCount = Count(*) FROM #UserList
		
		Declare @counter int=1
		Declare @AssignedToUserID int
		
		WHILE @counter <= @userListCount
		BEGIN
			set @AssignedToUserID=(select UserID from #UserList where seq=@counter)
			exec PriorityList_AddTask @UserID=@AssignedToUserID,@ActiveChecklistID=@NewActiveID
	 		
			SET @counter=@counter+1
		End		
	End
	--If the task isn't going on every assignee's priority list, if Brandon is an assignee, put it on his.
	ELSE IF EXISTS (
			SELECT 'Y' from QCheck_Users u 
				JOIN QCheck_GroupMembership gm ON gm.UserID = u.ID AND gm.GroupID = @GroupID
			WHERE u.ID = 10
		) AND @NewActiveID IS NOT NULL
	BEGIN
		exec PriorityList_AddTask 10, @NewActiveID
	END
	
	-- rebuild cache
 EXEC QCheck_ChecklistControllersList_Refresh @ID
END
GO

CREATE OR ALTER PROC [dbo].[QCheck_DelItem]
	@ItemID INT,
	@UserId INT
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @recordIds AS RecordId
	INSERT INTO @recordIds VALUES(@ItemID)
	EXEC dbo.Audit_Set @userId, @recordIds, 'Item', 3

	Update
		QCheck_Items
	Set 
		IsDeleted = 1
	WHERE
		[ID] = @ItemID
END
GO

CREATE OR ALTER PROC [dbo].[QCheck_GetActiveChecklistTaskTypes]
	@taskId int,
	@userId int = 0
AS
BEGIN
	SET NOCOUNT ON

	SELECT 
		tt.ID, r.Name as Report, tt.Description as TaskType, r.ID as ReportID
	INTO #result
	FROM
		QStatus_ActiveChecklistTaskType actt
		INNER JOIN QStatus_TaskTypes tt
			ON actt.TaskType = tt.ID
		INNER JOIN QStatus_Report r
			ON r.ID = tt.ReportID
		INNER JOIN QCheck_ActiveChecklists ac
			ON actt.activechecklistID = ac.ID
	WHERE ac.ID = @taskId
	
	UNION

	SELECT 
		st.ID, r.Name as Report, tt.Description as TaskType, r.ID as ReportID
	FROM
		QStatus_SpecialTasks st
		INNER JOIN
			QStatus_TaskTypes	tt
			ON st.TaskType = tt.ID
		INNER JOIN QStatus_Report r
			ON r.ID = tt.ReportID
	WHERE st.ID = @taskId
	
	IF @userId <> 0 BEGIN
		DECLARE @recordIds AS RecordId
		INSERT INTO @recordIds
			SELECT DISTINCT ID FROM #result

		EXEC dbo.Audit_Set @userId, @recordIds, 'TaskType', 2

		DELETE @recordIds
		INSERT INTO @recordIds
			SELECT DISTINCT ReportID FROM #result

		EXEC dbo.Audit_Set @userId, @recordIds, 'Report', 2
	END

	SELECT * FROM #result
END
GO

CREATE OR ALTER PROC [dbo].[QCheck_GetCalendarChecklists]
	@UserID int,
	@startDate datetime,
	@endDate datetime,
	@ID varchar(8000),
	@ShowStatusCalendar bit = 0,
	@ShowAlertEmails bit = 1
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @IDs table(
		ID int
	)

	INSERT INTO @IDs SELECT CAST(Data as int) FROM dbo.Util_Split(@ID,',')
	
	DECLARE @tblAssigned table(
		ID int
	)

	DECLARE @tblAssignee table(
		ID int
	)

	DECLARE @tblManaged table(
		ID int
	)
	
	DECLARE @tblStatusControlled table(
		ID int
	)	

	DECLARE @tblStatusSupervised table(
		ID int
	)

	DECLARE @tblScheduledAlerts table(
		ID int,
		AlertID int
	)

	DECLARE @tblPendingChanges table(
		ActiveChecklistID INT,
		ChangeID INT,
		NewDeadline DATETIME
	)
	
	DECLARE @tblResults table(
		objID int, 
		ChecklistID int, 
		ChecklistName varchar(500), 
		DueTime datetime, 
		ReminderDate datetime,
		type int,
		active int,
		assignedto int,
		ismanager int,
		isRecurring bit,
		PendingChange bit,
		ChangeID int,
		NewDeadline datetime,
		IsNA bit,
		isAlert bit,
		AlertID int,
		isEmailScheduled bit,
		MultiStep bit,
		IsPriority bit,
		OriginalDeadline datetime
	)
	
	IF @UserID <> 5000 BEGIN

		INSERT INTO @tblPendingChanges (
			ActiveChecklistID,
			ChangeID,
			NewDeadline
		)
			SELECT 
				AAC.ActiveChecklistID,
				CR.[ID],
				AAC.DueTime
			FROM 
				QCheck_Approval_ChangeRequests CR
				INNER JOIN QCheck_Approval_ActiveChecklists AAC
					ON AAC.ChangeRequestID = CR.[ID]
				-- 3/25/2013 dalvarado - Created this view and joined it here to eliminate duplicate entries
				-- on the calendar view when you have multiple outstanding change requests for a task.
				INNER JOIN QCheck_MostRecentDeadlineRequests MRDR
					ON AAC.ActiveChecklistID = MRDR.ActiveChecklistID
					AND CR.ID = MRDR.ChangeRequestID
			WHERE 
				CR.IsActive = 1
				AND CR.Approved = 0
				AND CR.Rejected = 0
				AND CR.ReadyForSupervisor = 1
	
		INSERT INTO @tblAssigned
		SELECT a.InstanceID
		FROM 
			QCheck_Assignments a
			INNER JOIN QCheck_Groups g
				on g.ID = a.GroupID
			INNER JOIN QCheck_Groupmembership gm
				on gm.GroupID = g.ID
				and gm.UserID = @UserID
		WHERE a.IsDeleted = 0

		INSERT INTO @tblAssignee
		SELECT a.InstanceID
		FROM 
			QCheck_Assignments a
			INNER JOIN QCheck_Groups g
				on g.ID = a.GroupID
			INNER JOIN QCheck_Groupmembership gm
				on gm.GroupID = g.ID
				and gm.UserID IN (SELECT ID FROM @IDs)
			--Failsafe against query string hacking; @UserID and @ID must have a supervisor/report relationship
			INNER JOIN (
				SELECT u.ID
				FROM QCheck_Users U
					INNER JOIN QStatus_Report R
						ON U.FullName = R.[Name]	
						AND r.IsDeleted = 0
					INNER JOIN QStatus_Supervisors S
						ON R.[ID] = S.ReportID			
						AND s.AsOf < GETDATE()
						AND (s.DirectSupervisor = 1 OR s.InterestedParty = 1)
					INNER JOIN QCheck_Groups G
						ON S.SupervisorGroupID = G.[ID]			
					INNER JOIN QCheck_Users SU
						ON G.Owner = SU.[ID]
						AND su.IsDeleted = 0
						AND SU.[ID] = @UserID
					WHERE
						U.IsDeleted = 0
						AND U.ID IN (SELECT ID FROM @IDs)
			) X ON x.ID = gm.UserID
		WHERE a.IsDeleted = 0		
	
		INSERT INTO @tblManaged
		SELECT ci.ID
		FROM 
			QCheck_ChecklistInstances ci
			INNER JOIN QCheck_Checklists c
				on c.ID = ci.ChecklistID
				and c.IsDeleted = 0
				and ci.IsDeleted = 0
			INNER JOIN QCheck_ChecklistManagers cm
				on cm.ChecklistID = c.ID
				and cm.IsDeleted = 0
			INNER JOIN QCheck_Groups g
				on g.ID = cm.ManagerGroupID
			INNER JOIN QCheck_Groupmembership gm
				on gm.GroupID = g.ID
				and gm.UserID = @UserID

		INSERT INTO @tblStatusControlled
		SELECT r.ID 
		FROM 
			QStatus_Report r
			INNER JOIN QStatus_GroupReport gr
				ON gr.ReportID = r.ID
			INNER JOIN QCheck_Groups g
				ON g.ID = gr.GroupID
			INNER JOIN QCheck_GroupMembership gm
				ON gm.GroupID = g.ID
				AND gm.UserID = @UserID			
		WHERE
			r.IsDeleted = 0
			AND (
				r.ID IN (SELECT ID FROM @IDs)
				or -1 IN (SELECT ID FROM @IDs)		
			)
	
		INSERT INTO @tblStatusSupervised
		SELECT r.ID 
		FROM 
			QStatus_Report r
			INNER JOIN QStatus_Supervisors sup
				ON sup.ReportID = r.ID
				AND sup.DirectSupervisor = 1
			INNER JOIN QCheck_Groups g
				ON g.ID = sup.SupervisorGroupID
			INNER JOIN QCheck_GroupMembership gm
				ON gm.GroupID = g.ID
				AND gm.UserID = @UserID	
		WHERE
			r.IsDeleted = 0
			AND EXISTS (SELECT 'Y' FROM @IDs WHERE ID IN(-1, r.ID))			

		--KVS 2017-10-30 - Adding alerts as a viewable calendar item
		INSERT INTO @tblScheduledAlerts
		SELECT a.InstanceID,
			al.ID
		FROM 
			QCheck_Assignments a
			INNER JOIN QCheck_Alerts al
				ON al.InstanceID = a.InstanceID
				AND al.IsDeleted = 0				
			INNER JOIN QCheck_Groups g
				ON (al.AlerteeGroupID IS NULL AND g.ID = a.GroupID)
				OR al.AlerteeGroupID = g.ID
			INNER JOIN QCheck_Groupmembership gm
				on gm.GroupID = g.ID
				and gm.UserID = @UserID
		WHERE a.IsDeleted = 0 
		
		-- ****************************************
		-- All or assigned to me
		IF EXISTS (SELECT 'Y' FROM @IDs WHERE ID IN(-1, 0)) 
		BEGIN

			-- Current tasks assigned to me
			INSERT INTO @tblResults
			SELECT 
				ac.ID as objID, 
				c.ID as ChecklistID, 
				c.Name as ChecklistName, 
				ac.DueTime,
				ac.ReminderDate,
				1 AS type, --meaning current
				case when ac.completeddate is null then 1 else 0 end as active,
				1,
				CASE WHEN tm.ID is null then 0 else 1 end as ismanager,
				CASE WHEN s.freqType > 1 THEN 1 ELSE 0 END as isRecurring,
				CASE WHEN pc.ActiveChecklistID IS NULL THEN 0 ELSE 1 END AS PendingChange,
				ISNULL(pc.ChangeID, -1) AS ChangeID,
				ISNULL(pc.NewDeadline, ac.DueTime) AS NewDeadline,
				ISNULL(ac.IsNA, 0) AS IsNA,
				0 as IsAlert,
				aa.ID as AlertID,
				CASE WHEN a.ID IS NULL OR @ShowAlertEmails = 0 THEN 0 ELSE 1 END as IsEmailScheduled,
				case when ms.checklistid is null then 0 else 1 end as MultiStep,
				case when p.activechecklistid is null then 0 else 1 end as IsPriority,
				ac.OrigDueTime
			FROM 
				QCheck_ChecklistInstances ci
				INNER JOIN QCheck_Checklists c 
					on ci.checklistID = c.ID 
					AND c.IsDeleted = 0
					and ci.IsDeleted = 0
				INNER JOIN QCheck_ActiveChecklists ac 
					on ac.InstanceID = ci.ID 
					AND (
						ac.DueTime BETWEEN @startDate and @endDate
						OR ac.ReminderDate BETWEEN @startDate and @endDate
					)
				INNER JOIN @tblAssigned ta
					on ta.ID = ci.ID
				LEFT OUTER JOIN @tblManaged tm
					on tm.ID = ci.ID
				LEFT OUTER JOIN QCheck_Schedule s 
					ON ci.ScheduleID = s.ID 
				LEFT OUTER JOIN @tblPendingChanges pc
					ON ac.[ID] = pc.ActiveChecklistID
				LEFT OUTER JOIN @tblScheduledAlerts al
					ON al.ID = ci.ID
				LEFT OUTER JOIN QCheck_Alerts a
					ON al.AlertID = a.ID
					AND a.AlertType = 'Overdue'
				LEFT OUTER JOIN QCheck_ActiveAlerts aa
					ON aa.ActiveChecklistID = ac.ID
					AND aa.AlertID = a.ID		
				LEFT OUTER JOIN QCheck_MultiStep ms on ms.checklistid = c.ID	
				LEFT OUTER JOIN PriorityList p on p.activechecklistid = ac.ID and p.UserID = @UserID		
			WHERE
				EXISTS (SELECT 'Y' FROM @IDs WHERE ID IN(-1, 0)) 

			-- Future tasks assigned to me
			INSERT INTO @tblResults
			SELECT 
				ac.ID as objID, 
				c.ID as ChecklistID, 
				c.Name as ChecklistName, 
				ac.DueTime, 
				NULL AS ReminderDate,
				3 AS type, --meaning future
				1 as active,
				1,
				CASE WHEN tm.ID is null then 0 else 1 end as ismanager,
				CASE WHEN s.freqType > 1 THEN 1 ELSE 0 END as isRecurring,
				0 AS PendingChange,
				-1 AS ChangeID,
				ac.DueTime AS NewDeadline,
				0 As IsNA,
				0 as IsAlert,
				aa.ID as AlertID,
				CASE WHEN a.ID IS NULL OR @ShowAlertEmails = 0 THEN 0 ELSE 1 END as IsEmailScheduled,
				case when ms.checklistid is null then 0 else 1 end as MultiStep,
				case when p.activechecklistid is null then 0 else 1 end as IsPriority,
				null as OrigDueTime
			FROM 
				QCheck_ChecklistInstances ci
				INNER JOIN QCheck_Checklists c 
					on ci.checklistID = c.ID 
					AND c.IsDeleted = 0
					and ci.IsDeleted = 0
				INNER JOIN QCheck_UpcomingDueTimes ac 
					on ac.InstanceID = ci.ID 
					AND ac.DueTime BETWEEN @startDate and @endDate
				INNER JOIN @tblAssigned ta
					on ta.ID = ci.ID
				LEFT OUTER JOIN @tblManaged tm
					on tm.ID = ci.ID
				LEFT OUTER JOIN QCheck_Schedule s 
					ON ci.ScheduleID = s.ID
				LEFT OUTER JOIN @tblScheduledAlerts al
					ON al.ID = ci.ID
				LEFT OUTER JOIN QCheck_Alerts a
					ON al.AlertID = a.ID
					AND a.AlertType = 'Overdue'
				LEFT OUTER JOIN QCheck_ActiveAlerts aa
					ON aa.ActiveChecklistID = ac.ID
					AND aa.AlertID = a.ID		
				LEFT OUTER JOIN QCheck_MultiStep ms on ms.checklistid = c.ID
				LEFT OUTER JOIN PriorityList p on p.activechecklistid = ac.ID and p.UserID = @UserID		
			WHERE
				EXISTS (SELECT 'Y' FROM @IDs WHERE ID IN(-1, 0)) 
	
			-- Past tasks assigned to me
			INSERT INTO @tblResults
			SELECT 
				ac.ID as objID, 
				c.ID as ChecklistID, 
				c.Name as ChecklistName, 
				ac.DueTime,
				ac.ReminderDate,
				2 AS type, --meaning past
				0 as active,
				1,
				CASE WHEN tm.ID is null then 0 else 1 end as ismanager,
				CASE WHEN s.freqType > 1 THEN 1 ELSE 0 END as isRecurring,
				0 AS PendingChange,
				-1 AS ChangeID,
				ac.DueTime AS NewDeadline,
				ISNULL(ac.IsNA, 0) AS IsNA,
				0 as IsAlert,
				a.ID as AlertID,
				CASE WHEN a.ID IS NULL OR @ShowAlertEmails = 0 THEN 0 ELSE 1 END as IsEmailScheduled,
				case when ms.checklistid is null then 0 else 1 end as MultiStep,
				case when p.activechecklistid is null then 0 else 1 end as IsPriority,
				ac.OrigDueTime
			FROM 
				QCheck_ChecklistInstances ci
				INNER JOIN QCheck_Checklists c 
					on ci.checklistID = c.ID 
					AND c.IsDeleted = 0
					and ci.IsDeleted = 0
				INNER JOIN QCheck_ActiveChecklistArchive ac 
					on ac.InstanceID = ci.ID 
					AND CAST(GETDATE() as date) > @startDate
					AND (
						ac.DueTime BETWEEN @startDate and @endDate
						OR ac.ReminderDate BETWEEN @startDate and @endDate
					)
				INNER JOIN @tblAssigned ta
					on ta.ID = ci.ID
				LEFT OUTER JOIN @tblManaged tm
					on tm.ID = ci.ID
				LEFT OUTER JOIN QCheck_Schedule s 
					ON ci.ScheduleID = s.ID
				LEFT OUTER JOIN @tblScheduledAlerts al
					ON al.ID = ci.ID
				LEFT OUTER JOIN QCheck_Alerts a
					ON al.AlertID = a.ID
					AND a.AlertType = 'Overdue'
				LEFT OUTER JOIN QCheck_ActiveAlerts aa
					ON aa.ActiveChecklistID = ac.ID
					AND aa.AlertID = a.ID		
				LEFT OUTER JOIN QCheck_MultiStep ms on ms.checklistid = c.ID
				LEFT OUTER JOIN PriorityList p on p.activechecklistid = ac.ID and p.UserID = @UserID		
			WHERE
				EXISTS (SELECT 'Y' FROM @IDs WHERE ID IN(-1, 0)) 
		END

		-- ****************************************
		-- Managed by me
		IF EXISTS (SELECT 'Y' FROM @IDs WHERE ID IN(-1, -2)) 
			OR (EXISTS (SELECT 'Y' FROM @IDs WHERE ID > 0) and @ShowStatusCalendar = 0)
		BEGIN

			-- IF @ID = -2, *only* show tasks controlled by the user (ignore supervisor or group membership)
			-- IF ID > 0, show any task where the assignee's status report is visible to the user
			
			-- Current tasks managed by me
			INSERT INTO @tblResults
			SELECT 
				ac.ID as objID, 
				c.ID as ChecklistID, 
				c.Name as ChecklistName, 
				ac.DueTime, 
				ac.ReminderDate,
				1 AS type, --meaning current
				case when ac.completeddate is null then 1 else 0 end as active,
				CASE WHEN ta.ID is null then 0 else 1 end as assignedto,
				CASE WHEN tm.ID is null then 0 else 1 end as isManager,
				CASE WHEN s.freqType > 1 THEN 1 ELSE 0 END as isRecurring,
				CASE WHEN pc.ActiveChecklistID IS NULL THEN 0 ELSE 1 END AS PendingChange,
				ISNULL(pc.ChangeID, -1) AS ChangeID,
				ISNULL(pc.NewDeadline, ac.DueTime) AS NewDeadline,
				ISNULL(ac.IsNA, 0) AS IsNA,
				0 as isAlert,
				NULL as AlertID,
				0 as isEmailScheduled,
				case when ms.checklistid is null then 0 else 1 end as MultiStep,
				case when p.activechecklistid is null then 0 else 1 end as IsPriority,
				ac.OrigDueTime
			FROM 
				QCheck_ChecklistInstances ci
				INNER JOIN QCheck_Checklists c 
					on ci.checklistID = c.ID 
					AND c.IsDeleted = 0
					and ci.IsDeleted = 0
				INNER JOIN QCheck_ActiveChecklists ac 
					on ac.InstanceID = ci.ID 
					AND (
						ac.DueTime BETWEEN @startDate and @endDate
						OR ac.ReminderDate BETWEEN @startDate and @endDate
					)
				INNER JOIN QCheck_ActiveAssignments aa
					on aa.ActiveChecklistID = ac.ID
				INNER JOIN QCheck_Assignments a
					on a.ID = aa.AssignmentsID
					and a.isdeleted = 0
				INNER JOIN QCheck_Groups g
					on g.ID = a.GroupID
				INNER JOIN QCheck_Groupmembership gm
					on gm.GroupID = g.ID
					and (
						EXISTS (SELECT 'Y' FROM @IDs WHERE ID IN(-1, -2)) 
						OR (
							EXISTS (SELECT 'Y' FROM @IDs WHERE ID > 0) 
							and @ShowStatusCalendar = 0
							and gm.UserID IN (select ID FROM @IDs)
						)
					)
				LEFT OUTER JOIN @tblAssigned ta
					on ta.ID = ci.ID
				LEFT OUTER JOIN @tblAssignee ta2
					on ta2.ID = ci.ID
				LEFT OUTER JOIN @tblManaged tm 
					on tm.ID = ci.ID
				LEFT OUTER JOIN QCheck_Schedule s 
					ON ci.ScheduleID = s.ID 
				LEFT OUTER JOIN @tblPendingChanges pc
					ON ac.[ID] = pc.ActiveChecklistID		
				LEFT OUTER JOIN QCheck_MultiStep ms on ms.checklistid = c.ID
				LEFT OUTER JOIN PriorityList p on p.activechecklistid = ac.ID and p.UserID = @UserID	
			WHERE
				(tm.ID is not null OR (-2 NOT IN (SELECT ID FROM @IDs) AND ta2.ID IS NOT NULL))
	
			-- Future tasks managed by me
			INSERT INTO @tblResults
			SELECT 
				ac.ID as objID, 
				c.ID as ChecklistID, 
				c.Name as ChecklistName, 
				ac.DueTime, 
				NULL AS ReminderDate,
				3 AS type, --meaning current
				1 as active,
				CASE WHEN ta.ID is null then 0 else 1 end as assignedto,
				CASE WHEN tm.ID is null then 0 else 1 end as isManager,
				CASE WHEN s.freqType > 1 THEN 1 ELSE 0 END as isRecurring,
				0 AS PendingChange,
				-1 AS ChangeID,
				ac.DueTime AS NewDeadline,
				0 AS IsNA,
				0 as isAlert,
				NULL as AlertID,
				0 as isEmailScheduled,
				case when ms.checklistid is null then 0 else 1 end as MultiStep,
				case when p.activechecklistid is null then 0 else 1 end as IsPriority,
				null as OrigDueTime
			FROM 
				QCheck_ChecklistInstances ci
				INNER JOIN QCheck_Checklists c 
					on ci.checklistID = c.ID 
					AND c.IsDeleted = 0
					and ci.IsDeleted = 0
				INNER JOIN QCheck_UpcomingDueTimes ac 
					on ac.InstanceID = ci.ID 
					AND ac.DueTime BETWEEN @startDate and @endDate
				INNER JOIN QCheck_Assignments a
					on a.InstanceID = ci.ID
					and a.isdeleted = 0
				INNER JOIN QCheck_Groups g
					on g.ID = a.GroupID
				INNER JOIN QCheck_Groupmembership gm
					on gm.GroupID = g.ID
					and (
						EXISTS (SELECT 'Y' FROM @IDs WHERE ID IN(-1, -2)) 
						OR (
							EXISTS (SELECT 'Y' FROM @IDs WHERE ID > 0) 
							and @ShowStatusCalendar = 0
							and gm.UserID IN (select ID FROM @IDs)
						)
					)
				LEFT OUTER JOIN @tblAssigned ta
					on ta.ID = ci.ID
				LEFT OUTER JOIN @tblAssignee ta2
					on ta2.ID = ci.ID
				LEFT OUTER JOIN @tblManaged tm 
					on tm.ID = ci.ID
				LEFT OUTER JOIN QCheck_Schedule s 
					ON ci.ScheduleID = s.ID 		
				LEFT OUTER JOIN QCheck_MultiStep ms on ms.checklistid = c.ID
				LEFT OUTER JOIN PriorityList p on p.activechecklistid = ac.ID and p.UserID = @UserID
			WHERE
				(tm.ID is not null OR (-2 NOT IN (SELECT ID FROM @IDs) AND ta2.ID IS NOT NULL))	

			-- Past tasks managed by me
			INSERT INTO @tblResults
			SELECT 
				ac.ID as objID, 
				c.ID as ChecklistID, 
				c.Name as ChecklistName, 
				ac.DueTime, 
				ac.ReminderDate,
				2 AS type, --meaning past
				0 as active,
				CASE WHEN ta.ID is null then 0 else 1 end as assignedto,
				CASE WHEN tm.ID is null then 0 else 1 end as isManager,
				CASE WHEN s.freqType > 1 THEN 1 ELSE 0 END as isRecurring,
				0 AS PendingChange,
				-1 AS ChangeID,
				ac.DueTime AS NewDeadline,
				ISNULL(ac.IsNA, 0) AS IsNA,
				0 as isAlert,
				NULL as AlertID,
				0 as isEmailScheduled,
				case when ms.checklistid is null then 0 else 1 end as MultiStep,
				case when p.activechecklistid is null then 0 else 1 end as IsPriority,
				ac.OrigDueTime
			FROM 
				QCheck_ChecklistInstances ci
				INNER JOIN QCheck_Checklists c 
					on ci.checklistID = c.ID 
					AND c.IsDeleted = 0
					and ci.IsDeleted = 0
				INNER JOIN QCheck_ActiveChecklistArchive ac 
					on ac.InstanceID = ci.ID 
					AND CAST(GETDATE() as date) > @startDate			
					AND (
						ac.DueTime BETWEEN @startDate and @endDate
						OR ac.ReminderDate BETWEEN @startDate and @endDate
					)
				INNER JOIN QCheck_Assignments a
					on a.InstanceID = ci.ID
					and a.isdeleted = 0
				INNER JOIN QCheck_Groups g
					on g.ID = a.GroupID
				INNER JOIN QCheck_Groupmembership gm
					on gm.GroupID = g.ID
					and (
						EXISTS (SELECT 'Y' FROM @IDs WHERE ID IN(-1, -2)) 
						OR (
							EXISTS (SELECT 'Y' FROM @IDs WHERE ID > 0) 
							and @ShowStatusCalendar = 0
							and gm.UserID IN (select ID FROM @IDs)
						)
					)
				LEFT OUTER JOIN @tblAssigned ta
					on ta.ID = ci.ID
				LEFT OUTER JOIN @tblAssigned ta2
					on ta2.ID = ci.ID
				left outer JOIN @tblManaged tm 
					on tm.ID = ci.ID
				LEFT OUTER JOIN QCheck_Schedule s 
					ON ci.ScheduleID = s.ID 		
				LEFT OUTER JOIN QCheck_MultiStep ms on ms.checklistid = c.ID
				LEFT OUTER JOIN PriorityList p on p.activechecklistid = ac.ID and p.UserID = @UserID
			WHERE
				(tm.ID is not null OR (-2 NOT IN (SELECT ID FROM @IDs) AND ta2.ID IS NOT NULL))	

		END
	
		-- ****************************************
		-- Status
		IF EXISTS (SELECT 'Y' FROM @IDs WHERE ID = -1) OR @ShowStatusCalendar = 1
		BEGIN
			
			-- Current tasks on status report
			INSERT INTO @tblResults
			SELECT 
				ac.ID as objID, 
				c.ID as ChecklistID, 
				c.Name as ChecklistName, 
				ac.DueTime, 
				ac.ReminderDate,
				1 AS type, --meaning current
				case when ac.completeddate is null then 1 else 0 end as active,
				CASE WHEN ta.ID is null then 0 else 1 end,
				CASE WHEN tm.ID is null then 0 else 1 end,
				CASE WHEN s.freqType > 1 THEN 1 ELSE 0 END as isRecurring,
				CASE WHEN pc.ActiveChecklistID IS NULL THEN 0 ELSE 1 END AS PendingChange,
				ISNULL(pc.ChangeID, -1) AS ChangeID,
				ISNULL(pc.NewDeadline, ac.DueTime) AS NewDeadline,
				ISNULL(ac.IsNA, 0) AS IsNA,
				0 as isAlert,
				NULL as AlertID,
				0 as isEmailScheduled,
				case when ms.checklistid is null then 0 else 1 end as MultiStep,
				case when p.activechecklistid is null then 0 else 1 end as IsPriority,
				ac.OrigDueTime
			FROM 
				QCheck_ChecklistInstances ci
				INNER JOIN QCheck_Checklists c 
					on ci.checklistID = c.ID 
					AND c.IsDeleted = 0
					and ci.IsDeleted = 0
				INNER JOIN QCheck_ActiveChecklists ac 
					on ac.InstanceID = ci.ID 
					AND (
						ac.DueTime BETWEEN @startDate and @endDate
						OR ac.ReminderDate BETWEEN @startDate and @endDate
					)
				INNER JOIN QStatus_ActiveChecklistTaskType actt
					on actt.ActiveChecklistID = ac.ID
				INNER JOIN QStatus_TaskTypes tt
					ON tt.ID = actt.TaskType
				LEFT OUTER JOIN @tblStatusControlled tc
					ON tc.ID = tt.ReportID
				LEFT OUTER JOIN @tblStatusSupervised tss
					ON tss.ID = tt.ReportID
				LEFT OUTER JOIN @tblAssigned ta
					on ta.ID = ci.ID
				LEFT OUTER JOIN @tblManaged tm
					on tm.ID = ci.ID
				LEFT OUTER JOIN QCheck_Schedule s 
					ON ci.ScheduleID = s.ID 
				LEFT OUTER JOIN @tblPendingChanges pc
					ON ac.[ID] = pc.ActiveChecklistID		
				LEFT OUTER JOIN QCheck_MultiStep ms on ms.checklistid = c.ID
				LEFT OUTER JOIN PriorityList p on p.activechecklistid = ac.ID and p.UserID = @UserID		
			WHERE 
				NOT (
					tc.ID is null 
					and tss.ID is null
				)
	
			-- Future tasks on status report
			INSERT INTO @tblResults
			SELECT 
				ac.ID as objID, 
				c.ID as ChecklistID, 
				c.Name as ChecklistName, 
				ac.DueTime, 
				NULL AS ReminderDate,
				3 AS type, --meaning future
				1 as active,
				CASE WHEN ta.ID is null then 0 else 1 end,
				CASE WHEN tm.ID is null then 0 else 1 end,
				CASE WHEN s.freqType > 1 THEN 1 ELSE 0 END as isRecurring,
				0 AS PendingChange,
				-1 AS ChangeID,
				ac.DueTime AS NewDeadline,
				0 AS IsNA,
				0 as isAlert,
				NULL as AlertID,
				0 as isEmailScheduled,
				case when ms.checklistid is null then 0 else 1 end as MultiStep,
				case when p.activechecklistid is null then 0 else 1 end as IsPriority,
				null as OrigDueTime
			FROM 
				QCheck_ChecklistInstances ci
				INNER JOIN QCheck_Checklists c 
					on ci.checklistID = c.ID 
					AND c.IsDeleted = 0
					and ci.IsDeleted = 0
				INNER JOIN QCheck_UpcomingDueTimes ac 
					on ac.InstanceID = ci.ID 
					AND (
						ac.DueTime BETWEEN @startDate and @endDate
						OR ac.DueTime BETWEEN @startDate and @endDate
					)
				INNER JOIN QStatus_InstanceTaskType itt
					on itt.InstanceID = ci.ID
				INNER JOIN QStatus_TaskTypes tt
					ON tt.ID = itt.TaskType
				LEFT OUTER JOIN @tblStatusControlled tc
					ON tc.ID = tt.ReportID
				LEFT OUTER JOIN @tblStatusSupervised tss
					ON tss.ID = tt.ReportID
				LEFT OUTER JOIN @tblAssigned ta
					on ta.ID = ci.ID
				LEFT OUTER JOIN @tblManaged tm
					on tm.ID = ci.ID
				LEFT OUTER JOIN QCheck_Schedule s 
					ON ci.ScheduleID = s.ID 		
				LEFT OUTER JOIN QCheck_MultiStep ms on ms.checklistid = c.ID
				LEFT OUTER JOIN PriorityList p on p.activechecklistid = ac.ID and p.UserID = @UserID		
			WHERE 
				NOT (
					tss.ID is null 
					and tc.ID is null
				)
	
			-- Past tasks on status report
			INSERT INTO @tblResults
			SELECT 
				ac.ID as objID, 
				c.ID as ChecklistID, 
				c.Name as ChecklistName, 
				ac.DueTime, 
				ac.ReminderDate,
				2 AS type, --meaning past
				0 as active,
				CASE WHEN ta.ID is null then 0 else 1 end,
				CASE WHEN tm.ID is null then 0 else 1 end,
				CASE WHEN s.freqType > 1 THEN 1 ELSE 0 END as isRecurring,
				0 AS PendingChange,
				-1 AS ChangeID,
				ac.DueTime AS NewDeadline,
				ISNULL(ac.IsNA, 0) AS IsNA,
				0 as isAlert,
				NULL as AlertID,
				0 as isEmailScheduled,
				case when ms.checklistid is null then 0 else 1 end as MultiStep,
				case when p.activechecklistid is null then 0 else 1 end as IsPriority,
				ac.OrigDueTime
			FROM 
				QCheck_ChecklistInstances ci
				INNER JOIN QCheck_Checklists c 
					on ci.checklistID = c.ID 
					AND c.IsDeleted = 0
					and ci.IsDeleted = 0
				INNER JOIN QCheck_ActiveChecklistArchive ac 
					on ac.InstanceID = ci.ID
					AND CAST(GETDATE() as date) > @startDate		
					AND (
						ac.DueTime BETWEEN @startDate and @endDate
						OR ac.ReminderDate BETWEEN @startDate and @endDate
					)
				INNER JOIN QStatus_InstanceTaskType itt
					on itt.InstanceID = ci.ID
				INNER JOIN QStatus_TaskTypes tt
					ON tt.ID = itt.TaskType
				LEFT OUTER JOIN @tblStatusControlled tc
					ON tc.ID = tt.ReportID
				LEFT OUTER JOIN @tblStatusSupervised tss
					ON tss.ID = tt.ReportID
				LEFT OUTER JOIN @tblAssigned ta
					on ta.ID = ci.ID
				LEFT OUTER JOIN @tblManaged tm
					on tm.ID = ci.ID
				LEFT OUTER JOIN QCheck_Schedule s 
					ON ci.ScheduleID = s.ID		
				LEFT OUTER JOIN QCheck_MultiStep ms on ms.checklistid = c.ID
				LEFT OUTER JOIN PriorityList p on p.activechecklistid = ac.ID and p.UserID = @UserID		 
			WHERE 
				NOT (
					tss.ID is null 
					and tc.ID is null
				)

		END

		-- ****************************************
		-- Overdue tasks
		
		-- All or assigned to me
		IF EXISTS (SELECT 'Y' FROM @IDs WHERE ID IN(-1, 0)) BEGIN

			-- Overdue tasks assigned to me
			INSERT INTO @tblResults
			SELECT 
				ac.ID as objID, 
				c.ID as ChecklistID, 
				c.Name as ChecklistName, 
				ac.DueTime,
				ac.ReminderDate,
				1 AS type, --meaning current
				case when ac.completeddate is null then 1 else 0 end as active,
				1,
				CASE WHEN tm.ID is null then 0 else 1 end as ismanager,
				CASE WHEN s.freqType > 1 THEN 1 ELSE 0 END as isRecurring,
				CASE WHEN pc.ActiveChecklistID IS NULL THEN 0 ELSE 1 END AS PendingChange,
				ISNULL(pc.ChangeID, -1) AS ChangeID,
				ISNULL(pc.NewDeadline, ac.DueTime) AS NewDeadline,
				ISNULL(ac.IsNA, 0) AS IsNA,
				0 as IsAlert,
				aa.ID as AlertID,
				CASE WHEN a.ID IS NULL THEN 0 ELSE 1 END as IsEmailScheduled,
				case when ms.checklistid is null then 0 else 1 end as MultiStep,
				case when p.activechecklistid is null then 0 else 1 end as IsPriority,
				ac.OrigDueTime
			FROM 
				QCheck_ChecklistInstances ci
				INNER JOIN QCheck_Checklists c 
					on ci.checklistID = c.ID 
					AND c.IsDeleted = 0
					and ci.IsDeleted = 0
				INNER JOIN QCheck_ActiveChecklists ac 
					on ac.InstanceID = ci.ID 
					AND ac.DueTime < @startDate
					AND ac.DueTime < GETDATE() -- Only overdue stuff, not active tasks in future weeks
					AND ac.CompletedDate IS NULL
				INNER JOIN @tblAssigned ta
					on ta.ID = ci.ID
				LEFT OUTER JOIN @tblManaged tm
					on tm.ID = ci.ID
				LEFT OUTER JOIN QCheck_Schedule s 
					ON ci.ScheduleID = s.ID 
				LEFT OUTER JOIN @tblPendingChanges pc
					ON ac.[ID] = pc.ActiveChecklistID
				LEFT OUTER JOIN @tblScheduledAlerts al
					ON al.ID = ci.ID
				LEFT OUTER JOIN QCheck_Alerts a
					ON al.AlertID = a.ID
					AND a.AlertType = 'Overdue'
				LEFT OUTER JOIN QCheck_ActiveAlerts aa
					ON aa.ActiveChecklistID = ac.ID
					AND aa.AlertID = a.ID		
				LEFT OUTER JOIN QCheck_MultiStep ms on ms.checklistid = c.ID
				LEFT OUTER JOIN PriorityList p on p.activechecklistid = ac.ID and p.UserID = @UserID		
			WHERE
				EXISTS (SELECT 'Y' FROM @IDs WHERE ID IN(-1, 0))
				
		END
		
		-- Managed by me
		IF EXISTS (SELECT 'Y' FROM @IDs WHERE ID IN(-1, -2)) 
			OR (EXISTS (SELECT 'Y' FROM @IDs WHERE ID > 0) and @ShowStatusCalendar = 0)		
		BEGIN
			-- Overdue tasks managed by me
			INSERT INTO @tblResults
			SELECT 
				ac.ID as objID, 
				c.ID as ChecklistID, 
				c.Name as ChecklistName, 
				ac.DueTime, 
				ac.ReminderDate,
				1 AS type, --meaning current
				case when ac.completeddate is null then 1 else 0 end as active,
				CASE WHEN ta.ID is null then 0 else 1 end as assignedto,
				CASE WHEN tm.ID is null then 0 else 1 end as isManager,
				CASE WHEN s.freqType > 1 THEN 1 ELSE 0 END as isRecurring,
				CASE WHEN pc.ActiveChecklistID IS NULL THEN 0 ELSE 1 END AS PendingChange,
				ISNULL(pc.ChangeID, -1) AS ChangeID,
				ISNULL(pc.NewDeadline, ac.DueTime) AS NewDeadline,
				ISNULL(ac.IsNA, 0) AS IsNA,
				0 as IsAlert,
				NULL as AlertID,
				0 as IsEmailScheduled,
				case when ms.checklistid is null then 0 else 1 end as MultiStep,
				case when p.activechecklistid is null then 0 else 1 end as IsPriority,
				ac.OrigDueTime
			FROM 
				QCheck_ChecklistInstances ci
				INNER JOIN QCheck_Checklists c 
					on ci.checklistID = c.ID 
					AND c.IsDeleted = 0
					and ci.IsDeleted = 0
				INNER JOIN QCheck_ActiveChecklists ac 
					on ac.InstanceID = ci.ID 
					AND ac.DueTime < @startDate
					AND ac.DueTime < GETDATE() -- Only overdue stuff, not active tasks in future weeks
					AND ac.CompletedDate IS NULL
				INNER JOIN QCheck_ActiveAssignments aa
					on aa.ActiveChecklistID = ac.ID
				INNER JOIN QCheck_Assignments a
					on a.ID = aa.AssignmentsID
					and a.isdeleted = 0
				INNER JOIN QCheck_Groups g
					on g.ID = a.GroupID
				INNER JOIN QCheck_Groupmembership gm
					on gm.GroupID = g.ID
					and (
						EXISTS (SELECT 'Y' FROM @IDs WHERE ID IN(-1, -2)) 
						OR (
							EXISTS (SELECT 'Y' FROM @IDs WHERE ID > 0) 
							and @ShowStatusCalendar = 0
							and gm.UserID IN (select ID FROM @IDs)
						)
					)
				LEFT OUTER JOIN @tblAssigned ta
					on ta.ID = ci.ID
				LEFT OUTER JOIN @tblAssignee ta2
					on ta2.ID = ci.ID
				LEFT OUTER JOIN @tblManaged tm
					on tm.ID = ci.ID
				LEFT OUTER JOIN QCheck_Schedule s 
					ON ci.ScheduleID = s.ID 
				LEFT OUTER JOIN @tblPendingChanges pc
					ON ac.[ID] = pc.ActiveChecklistID		
				LEFT OUTER JOIN QCheck_MultiStep ms on ms.checklistid = c.ID
				LEFT OUTER JOIN PriorityList p on p.activechecklistid = ac.ID and p.UserID = @UserID		
			WHERE
				(tm.ID is not null OR (-2 NOT IN (SELECT ID FROM @IDs) AND ta2.ID IS NOT NULL))		
		END
		
		-- Status
		IF EXISTS (SELECT 'Y' FROM @IDs WHERE ID = -1) OR @ShowStatusCalendar = 1
		BEGIN
			
			-- Overdue tasks on status report
			INSERT INTO @tblResults
			SELECT 
				ac.ID as objID, 
				c.ID as ChecklistID, 
				c.Name as ChecklistName, 
				ac.DueTime, 
				ac.ReminderDate,
				1 AS type, --meaning current
				case when ac.completeddate is null then 1 else 0 end as active,
				CASE WHEN ta.ID is null then 0 else 1 end,
				CASE WHEN tm.ID is null then 0 else 1 end,
				CASE WHEN s.freqType > 1 THEN 1 ELSE 0 END as isRecurring,
				CASE WHEN pc.ActiveChecklistID IS NULL THEN 0 ELSE 1 END AS PendingChange,
				ISNULL(pc.ChangeID, -1) AS ChangeID,
				ISNULL(pc.NewDeadline, ac.DueTime) AS NewDeadline,
				ISNULL(ac.IsNA, 0) AS IsNA,
				0 as IsAlert,
				NULL as AlertID,
				0 as IsEmailScheduled,
				case when ms.checklistid is null then 0 else 1 end as MultiStep,
				case when p.activechecklistid is null then 0 else 1 end as IsPriority,
				ac.OrigDueTime
			FROM 
				QCheck_ChecklistInstances ci
				INNER JOIN QCheck_Checklists c 
					on ci.checklistID = c.ID 
					AND c.IsDeleted = 0
					and ci.IsDeleted = 0
				INNER JOIN QCheck_ActiveChecklists ac 
					on ac.InstanceID = ci.ID 
					AND ac.DueTime < @startDate
					AND ac.DueTime < GETDATE() -- Only overdue stuff, not active tasks in future weeks
					AND ac.CompletedDate IS NULL
				INNER JOIN QStatus_ActiveChecklistTaskType actt
					on actt.ActiveChecklistID = ac.ID
				INNER JOIN QStatus_TaskTypes tt
					ON tt.ID = actt.TaskType
				LEFT OUTER JOIN @tblStatusControlled tc
					ON tc.ID = tt.ReportID
				LEFT OUTER JOIN @tblStatusSupervised tss
					ON tss.ID = tt.ReportID
				LEFT OUTER JOIN @tblAssigned ta
					on ta.ID = ci.ID
				LEFT OUTER JOIN @tblManaged tm
					on tm.ID = ci.ID
				LEFT OUTER JOIN QCheck_Schedule s 
					ON ci.ScheduleID = s.ID 
				LEFT OUTER JOIN @tblPendingChanges pc
					ON ac.[ID] = pc.ActiveChecklistID
				LEFT OUTER JOIN QCheck_MultiStep ms on ms.checklistid = c.ID
				LEFT OUTER JOIN PriorityList p on p.activechecklistid = ac.ID and p.UserID = @UserID	
			WHERE 
				NOT (
					tc.ID is null 
					and tss.ID is null
				)
				
		END

		-- ****************************************
		-- Email reminders - Assigned ONLY
		IF EXISTS (SELECT 'Y' FROM @IDs WHERE ID IN(-1, 0)) and @ShowAlertEmails = 1 BEGIN
			-- Current tasks assigned to me
			INSERT INTO @tblResults
			SELECT 
				ac.ID as objID, 
				c.ID as ChecklistID, 
				c.Name + (CASE WHEN a.AlertText IS NOT NULL AND a.AlertText <> '' THEN ' - ' + a.AlertText
							WHEN a.AlertType IN ('Reminder') THEN ' - Reminder'
							WHEN a.AlertType IN ('Hours') THEN ' - Overdue Reminder' 
							ELSE ' - Alert' END) as ChecklistName, 
				CASE
					WHEN a.AlertType = 'Hours' OR a.AlertTime < 0 
						THEN DATEADD(minute, IsNull(a.AlertTime * 60, 0), ac.DueTime)
					ELSE DATEADD(minute, IsNull(a.AlertTime * 60, 0),
							DATEADD(day, IsNull(a.DaysBefore, 0) * -1, 
								DateAdd(day, DATEDIFF(day, 0, ac.DueTime),0)))
				END as DueTime,
				NULL as ReminderDate,
				1 AS type, --meaning current
				case when ac.completeddate is null then 1 else 0 end as active,
				1,
				CASE WHEN tm.ID is null then 0 else 1 end as ismanager,
				CASE WHEN s.freqType > 1 THEN 1 ELSE 0 END as isRecurring,
				CASE WHEN pc.ActiveChecklistID IS NULL THEN 0 ELSE 1 END AS PendingChange,
				ISNULL(pc.ChangeID, -1) AS ChangeID,
				ISNULL(pc.NewDeadline, ac.DueTime) AS NewDeadline,
				ISNULL(ac.IsNA, 0) AS IsNA,
				1 as IsAlert,
				aa.ID as AlertID,
				CASE WHEN ae.ID IS NULL THEN 1 ELSE 0 END as IsEmailScheduled,
				case when ms.checklistid is null then 0 else 1 end as MultiStep,
				case when p.activechecklistid is null then 0 else 1 end as IsPriority,
				ac.OrigDueTime
			FROM 
				QCheck_ChecklistInstances ci
				INNER JOIN QCheck_Checklists c 
					on ci.checklistID = c.ID 
					AND c.IsDeleted = 0
					and ci.IsDeleted = 0
				INNER JOIN QCheck_ActiveChecklists ac 
					on ac.InstanceID = ci.ID 
					AND (
						ac.DueTime BETWEEN @startDate and @endDate
						OR ac.ReminderDate BETWEEN @startDate and @endDate
					)
				INNER JOIN @tblAssigned ta
					on ta.ID = ci.ID
				LEFT OUTER JOIN @tblManaged tm
					on tm.ID = ci.ID
				LEFT OUTER JOIN QCheck_Schedule s 
					ON ci.ScheduleID = s.ID 
				LEFT OUTER JOIN @tblPendingChanges pc
					ON ac.[ID] = pc.ActiveChecklistID
				INNER JOIN @tblScheduledAlerts al
					ON al.ID = ci.ID
				INNER JOIN QCheck_Alerts a
					ON al.AlertID = a.ID
					AND a.AlertType IN ('Reminder', 'Custom', 'Hours')
				INNER JOIN QCheck_ActiveAlerts aa
					ON aa.ActiveChecklistID = ac.ID
					AND aa.AlertID = a.ID
				LEFT OUTER JOIN QCheck_AlertExceptions ae
					ON ae.ActiveAlertID = aa.ID
					AND ae.UserID = @UserID
					AND ae.IsActive = 1		
				LEFT OUTER JOIN QCheck_MultiStep ms on ms.checklistid = c.ID
				LEFT OUTER JOIN PriorityList p on p.activechecklistid = ac.ID and p.UserID = @UserID							
			WHERE
				EXISTS (SELECT 'Y' FROM @IDs WHERE ID IN(-1, 0))

			-- Future tasks assigned to me
			INSERT INTO @tblResults
			SELECT 
				ac.ID as objID, 
				c.ID as ChecklistID, 
				c.Name + IsNull(' - ' + a.AlertText, (CASE 
							WHEN a.AlertType IN ('Reminder') THEN ' - Reminder'
							WHEN a.AlertType IN ('Hours') THEN ' - Overdue Reminder' 
							ELSE ' - Alert' END)) as ChecklistName, 
				CASE 
					WHEN a.AlertType = 'Hours' OR a.AlertTime < 0 
						THEN DATEADD(hour, IsNull(a.AlertTime, 0), ac.DueTime)
					ELSE DATEADD(hour, IsNull(a.AlertTime, 0),
							DATEADD(day, IsNull(a.DaysBefore, 0) * -1, 
								DateAdd(day, DATEDIFF(day, 0, ac.DueTime),0)))
				END as DueTime,
				NULL AS ReminderDate,
				3 AS type, --meaning future
				1 as active,
				1,
				CASE WHEN tm.ID is null then 0 else 1 end as ismanager,
				CASE WHEN s.freqType > 1 THEN 1 ELSE 0 END as isRecurring,
				0 AS PendingChange,
				-1 AS ChangeID,
				ac.DueTime AS NewDeadline,
				0 As IsNA,
				1 as IsAlert,
				a.ID as AlertID,
				CASE WHEN ae.ID IS NULL THEN 1 ELSE 0 END as IsEmailScheduled,
				case when ms.checklistid is null then 0 else 1 end as MultiStep,
				case when p.activechecklistid is null then 0 else 1 end as IsPriority,
				null as OrigDueTime
			FROM 
				QCheck_ChecklistInstances ci
				INNER JOIN QCheck_Checklists c 
					on ci.checklistID = c.ID 
					AND c.IsDeleted = 0
					and ci.IsDeleted = 0
				INNER JOIN QCheck_UpcomingDueTimes ac 
					on ac.InstanceID = ci.ID 
					AND ac.DueTime BETWEEN @startDate and @endDate
				INNER JOIN @tblAssigned ta
					on ta.ID = ci.ID
				LEFT OUTER JOIN @tblManaged tm
					on tm.ID = ci.ID
				LEFT OUTER JOIN QCheck_Schedule s 
					ON ci.ScheduleID = s.ID
				INNER JOIN @tblScheduledAlerts al
					ON al.ID = ci.ID
				INNER JOIN QCheck_Alerts a
					ON al.AlertID = a.ID
					AND a.AlertType IN ('Reminder', 'Custom', 'Hours')
				INNER JOIN QCheck_ActiveAlerts aa
					ON aa.ActiveChecklistID = ac.ID
					AND aa.AlertID = a.ID
				LEFT OUTER JOIN QCheck_AlertExceptions ae
					ON ae.ActiveAlertID = aa.ID
					AND ae.UserID = @UserID
					AND ae.IsActive = 1		
				LEFT OUTER JOIN QCheck_MultiStep ms on ms.checklistid = c.ID
				LEFT OUTER JOIN PriorityList p on p.activechecklistid = ac.ID and p.UserID = @UserID					
			WHERE
				EXISTS (SELECT 'Y' FROM @IDs WHERE ID IN(-1, 0))
	
			-- Past tasks assigned to me
			INSERT INTO @tblResults
			SELECT 
				ac.ID as objID, 
				c.ID as ChecklistID, 
				c.Name + IsNull(' - ' + a.AlertText, (CASE 
							WHEN a.AlertType IN ('Reminder') THEN ' - Reminder'
							WHEN a.AlertType IN ('Hours') THEN ' - Overdue Reminder' 
							ELSE ' - Alert' END)) as ChecklistName, 
				CASE 
					WHEN a.AlertType = 'Hours' OR a.AlertTime < 0 
						THEN DATEADD(hour, IsNull(a.AlertTime, 0), ac.DueTime)
					ELSE DATEADD(hour, IsNull(a.AlertTime, 0),
							DATEADD(day, IsNull(a.DaysBefore, 0) * -1, 
								DateAdd(day, DATEDIFF(day, 0, ac.DueTime),0)))
				END as DueTime,
				NULL as ReminderDate,
				2 AS type, --meaning past
				0 as active,
				1,
				CASE WHEN tm.ID is null then 0 else 1 end as ismanager,
				CASE WHEN s.freqType > 1 THEN 1 ELSE 0 END as isRecurring,
				0 AS PendingChange,
				-1 AS ChangeID,
				ac.DueTime AS NewDeadline,
				ISNULL(ac.IsNA, 0) AS IsNA,
				1 as IsAlert,
				a.ID as AlertID,
				CASE WHEN ae.ID IS NULL THEN 1 ELSE 0 END as IsEmailScheduled,
				case when ms.checklistid is null then 0 else 1 end as MultiStep,
				case when p.activechecklistid is null then 0 else 1 end as IsPriority,
				ac.OrigDueTime
			FROM 
				QCheck_ChecklistInstances ci
				INNER JOIN QCheck_Checklists c 
					on ci.checklistID = c.ID 
					AND c.IsDeleted = 0
					and ci.IsDeleted = 0
				INNER JOIN QCheck_ActiveChecklistArchive ac 
					on ac.InstanceID = ci.ID 
					AND CAST(GETDATE() as date) > @startDate
					AND (
						ac.DueTime BETWEEN @startDate and @endDate
						OR ac.ReminderDate BETWEEN @startDate and @endDate
					)
				INNER JOIN @tblAssigned ta
					on ta.ID = ci.ID
				LEFT OUTER JOIN @tblManaged tm
					on tm.ID = ci.ID
				LEFT OUTER JOIN QCheck_Schedule s 
					ON ci.ScheduleID = s.ID
				INNER JOIN @tblScheduledAlerts al
					ON al.ID = ci.ID
				INNER JOIN QCheck_Alerts a
					ON al.AlertID = a.ID
					AND a.AlertType IN ('Reminder', 'Custom', 'Hours')
				INNER JOIN QCheck_ActiveAlerts aa
					ON aa.ActiveChecklistID = ac.ID
					AND aa.AlertID = a.ID
				LEFT OUTER JOIN QCheck_AlertExceptions ae
					ON ae.ActiveAlertID = aa.ID
					AND ae.UserID = @UserID
					AND ae.IsActive = 1		
				LEFT OUTER JOIN QCheck_MultiStep ms on ms.checklistid = c.ID
				LEFT OUTER JOIN PriorityList p on p.activechecklistid = ac.ID and p.UserID = @UserID				
			WHERE
				EXISTS (SELECT 'Y' FROM @IDs WHERE ID IN(-1, 0))
		END
	END
	
	DECLARE @recordIds AS RecordId
	INSERT INTO @recordIds
		SELECT DISTINCT ChecklistId FROM @tblResults WHERE ChecklistId IS NOT NULL

	EXEC dbo.Audit_Set @userId, @recordIds, 'Checklist', 2

	DELETE @recordIds
	INSERT INTO @recordIds
		SELECT DISTINCT objID FROM @tblResults WHERE objID IS NOT NULL

	EXEC dbo.Audit_Set @userId, @recordIds, 'ActiveChecklist', 2

	-- Get the output
	SELECT DISTINCT * 
	FROM 
		@tblResults
	ORDER BY 
		DueTime,
		objID, 
		ChecklistName
END
GO

CREATE OR ALTER PROC [dbo].[QCheck_GetChecklistItems]
	@ChecklistID INT,
	@UserId INT
AS
BEGIN
	SET NOCOUNT ON
	
	--retrieve from items and itemtypes by checklistID. Ensure isDeleted = 0 for deleted items
	SELECT a.[ID],[SequenceNum], b.[ID] as [TypeID], [Name] as [Type], [Text],[URL]
	INTO #result
	FROM
		QCheck_Items a, QCheck_ItemTypes b
	WHERE
		a.ItemTypeID = b.ID
	AND
		a.ChecklistID = @ChecklistID
	AND 	
		a.IsDeleted = 0

	DECLARE @recordIds AS RecordId
	INSERT INTO @recordIds 
		SELECT DISTINCT ID FROM #result
	EXEC dbo.Audit_Set @userId, @recordIds, 'Item', 2

	SELECT * FROM #result ORDER BY SequenceNum
END
GO

CREATE OR ALTER PROC [dbo].[QCheck_GetMyChecklistsByFolder](
	@UserID int,
	@memberGroupID int = 0,
	@managerGroupID int = 0,
	@isAdmin bit = 0,
	@search varchar(200) = ''
) AS

BEGIN

	SET NOCOUNT ON
	DECLARE @recordIds AS RecordId
	DECLARE @tblResults TABLE(
		ID int
	)

	DECLARE @tblAssigned TABLE(
		ID int
	)

	DECLARE @tblManaged TABLE(
		ID int
	)

	DECLARE @tblActive TABLE(
		ID int
	)

	-- Get all the ChecklistIDs the user is assigned to
	INSERT INTO @tblAssigned
		SELECT DISTINCT 
			c.ID
		FROM	
			QCheck_Checklists c (nolock)
			INNER JOIN QCheck_ChecklistInstances ci (nolock)
				ON c.[ID] = ci.ChecklistID
				AND c.IsDeleted = 0
				AND ci.IsDeleted = 0
			INNER JOIN QCheck_Assignments a (nolock)
				ON ci.[ID] = a.InstanceID
				AND a.IsDeleted = 0
			INNER JOIN QCheck_Groups g (nolock)
				ON a.GroupID = g.[ID]
			INNER JOIN QCheck_GroupMembership gm (nolock)
				ON g.[ID] = gm.GroupID
				AND (
					gm.UserID = @UserID 
					OR @isAdmin = 1
				)

	-- Get all the ChecklistIDs the user controls
	INSERT INTO @tblManaged
		SELECT DISTINCT 
			c.[ID]
		FROM	
			QCheck_Checklists c (nolock)
			INNER JOIN QCheck_ChecklistManagers cm (nolock)
				ON cm.ChecklistID = c.[ID]
				AND cm.IsDeleted = 0
				AND c.IsDeleted = 0
			INNER JOIN QCheck_Groups g (nolock)
				ON g.[ID] = cm.ManagerGroupID
			INNER JOIN QCheck_GroupMembership gm (nolock)
				ON gm.GroupID = g.[ID]
				AND (
					gm.UserID = @UserID 
					OR @isAdmin = 1
				)
				

	-- Get all active checklists
	INSERT INTO @tblActive
		SELECT DISTINCT 
			c.id
		FROM 
			qcheck_checklists c (nolock)
		INNER JOIN qcheck_checklistinstances ci (nolock)
			ON ci.checklistid = c.id
		INNER JOIN qcheck_activechecklists ac (nolock)
			ON ac.instanceid = ci.id

	-- If no group filter was supplied, the result set is everything assigned/managed through any group
	IF @memberGroupID = 0 AND @managergroupID = 0 BEGIN

		INSERT INTO @tblResults
			SELECT DISTINCT 
				c.ID
			FROM 
				qcheck_checklists c (nolock)
				INNER JOIN @tblAssigned tm
					ON tm.ID = c.ID

			UNION

			SELECT DISTINCT 
				c.ID
			FROM 
				qcheck_checklists c (nolock)
				INNER JOIN @tblManaged tm
					ON tm.ID = c.ID

	-- If a group filter was supplied, the result set is everything assigned to the user through that group
	END ELSE BEGIN

		INSERT INTO @tblResults
			SELECT DISTINCT 
				c.ID
			FROM 
				qcheck_checklists c (nolock)
				INNER JOIN (select ID from @tblManaged union all select ID from @tblAssigned) tm
					ON tm.ID = c.ID
				LEFT OUTER JOIN QCheck_ChecklistInstances ci (nolock)
					ON ci.ChecklistID = c.ID
					AND ci.IsDeleted = 0
				LEFT OUTER JOIN QCheck_Assignments a (nolock)
					ON a.InstanceID = ci.ID
					AND a.IsDeleted = 0
					AND a.GroupID = @memberGroupID
			WHERE
				(
					@memberGroupID = 0 OR
					a.ID IS NOT NULL
				)
				AND 
				(
					@managerGroupID = 0 OR
					c.id in (
					 select cm.checklistid from 
						QCheck_ChecklistManagers cm (nolock)
					 inner JOIN QCheck_Groups managerg (nolock)
								 ON managerg.ID = cm.ManagerGroupID
					 inner join QCheck_GroupMembership managergm (nolock)
								 ON managergm.GroupID = managerg.ID
								 AND managergm.GroupID = @managergroupID
					 where cm.IsDeleted = 0) 
				)

	END
		
	-- If no search string was supplied, return the full result set with folders
	IF LEN(LTRIM(RTRIM(@search))) = 0 BEGIN

		SELECT DISTINCT 
			c.Name as NodeName, 
			c.ID,
			c.ID as FolderID,
			isNull(fc.FolderID, 0) as ParentID,
			1 as Type,
			case when ac.ID IS NULL THEN 0 ELSE 1 END As Active,
			c.Template
		INTO #result
		FROM 
			@tblResults tr
			INNER JOIN qcheck_checklists c (nolock)
				ON tr.ID = c.ID
			LEFT OUTER JOIN @tblActive ac
				ON ac.ID = c.ID
			LEFT OUTER JOIN QCheck_FolderChecklists fc (nolock)
				ON fc.ChecklistID = c.ID
				AND fc.FolderID IN (
					SELECT ID 
					FROM QCheck_Folders 
					WHERE UserID = @UserID
				)
		
		UNION ALL
		
		SELECT 
			'All Tasks' as NodeName, 
			0 As ID,
			0 as FolderID,
			null as ParentID,
			2 as Type,
			0 as Active,
			0 as Template
	
		UNION ALL
			
		SELECT 
			FolderName as NodeName,
			ID,
			ID as FolderID,
			ParentFolder as ParentID,
			3 as Type,
			0 as Active,
			0 as Template
		FROM
			QCheck_Folders (nolock)
		WHERE
			UserID = @UserID		

	INSERT INTO @recordIds
		SELECT DISTINCT ID FROM #result WHERE ID > 0
	EXEC dbo.Audit_Set @userId, @recordIds, 'Checklist', 2

	SELECT * FROM #result ORDER BY [Type] DESC, NodeName
	-- If a search string was supplied, filter the result set by that search string
	END ELSE BEGIN

		SELECT DISTINCT 
			c.Name as NodeName, 
			c.ID,
			c.ID as FolderID,
			isNull(fc.FolderID, 0) as ParentID,
			1 as Type,
			case when ac.ID IS NULL THEN 0 ELSE 1 END As Active,
			c.Template
		INTO #result2
		FROM 
			@tblResults tr
			INNER JOIN qcheck_checklists c (nolock)
				ON tr.ID = c.ID
			LEFT OUTER JOIN	QCheck_Items i (nolock)
				ON i.ChecklistID = c.ID
			LEFT OUTER JOIN @tblActive ac
				ON ac.ID = c.ID
			LEFT OUTER JOIN QCheck_FolderChecklists fc (nolock)
				ON fc.ChecklistID = c.ID
				AND fc.FolderID IN (
					SELECT ID 
					FROM QCheck_Folders 
					WHERE UserID = @UserID
				)
		WHERE
			c.Name LIKE ('%'+@search+'%') 
			OR i.Text like ('%'+@search+'%')
		
		UNION ALL
		
		SELECT 
			'All Tasks' as NodeName, 
			0 As ID,
			0 as FolderID,
			null as ParentID,
			2 as Type,
			0 as Active,
			0 as Template
	
		UNION ALL
			
		SELECT 
			FolderName as NodeName,
			ID,
			ID as FolderID,
			ParentFolder as ParentID,
			3 as Type,
			0 as Active,
			0 as Template
		FROM
			QCheck_Folders (nolock)
		WHERE
			UserID = @UserID		

		INSERT INTO @recordIds
			SELECT DISTINCT ID FROM #result2 WHERE ID > 0
		EXEC dbo.Audit_Set @userId, @recordIds, 'Checklist', 2

		SELECT * FROM #result2 ORDER BY [Type] DESC, NodeName
	END
END
GO

CREATE OR ALTER PROC [dbo].[QCheck_GetName]
	@ChecklistID int,
	@UserId int
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @recordIds AS RecordId
	INSERT INTO @recordIds VALUES(@ChecklistID)

	EXEC dbo.Audit_Set @userId, @recordIds, 'Checklist', 2

	SELECT [Name] FROM QCheck_Checklists
	WHERE ID = @ChecklistID
END
GO

USE [PHIProcess]
GO
CREATE OR ALTER PROCEDURE [dbo].[QCheck_GetOverdueTasks]
@userId int
AS
BEGIN
	SET NOCOUNT ON

	SELECT 
		a.DueTime,
		c.[Name] AS ChecklistName,
		MAX(c.ID) AS ChecklistId
	INTO #result
	FROM
		QCheck_ActiveChecklists a 
		INNER JOIN QCheck_ChecklistInstances b ON a.InstanceID = b.ID AND b.IsDeleted = 0
		INNER JOIN QCheck_Schedule s ON b.ScheduleID = s.ID 
		INNER JOIN QCheck_Checklists c on b.checklistID = c.ID AND c.IsDeleted = 0
		INNER JOIN QCheck_Items d on d.checklistID = c.ID AND d.IsDeleted = 0
		INNER JOIN QCheck_ItemTypes j on d.ItemTypeID = j.ID
		INNER JOIN QCheck_ActiveAssignments k on k.ActiveChecklistID = a.ID 
		INNER JOIN QCheck_GroupMembership gm on gm. UserID = @userId
		INNER JOIN QCheck_Groups g on g.ID = gm.GroupID
		INNER JOIN QCheck_Assignments f on f.GroupID = gm.GroupID And f.IsDeleted = 0 and f.InstanceID = b.ID
		LEFT OUTER JOIN QCheck_ActiveItems e on e.ActiveChecklistID = a.ID
		LEFT OUTER JOIN QCheck_Users u on e.CompletedBy = u.ID
	WHERE
		a.CompletedDate is null
		AND a.dueTime < getdate()
	GROUP BY 
		c.[Name], a.dueTime

	DECLARE @recordIds AS RecordId
	INSERT INTO @recordIds
		SELECT DISTINCT ChecklistId
		FROM #result
	EXEC dbo.Audit_Set @userId, @recordIds, 'Checklist', 2

	-- return result
	SELECT DueTime, ChecklistName
	FROM #result
END
GO

CREATE OR ALTER PROC [dbo].[QCheck_GetPotentialNATasks]
	@controller int,
	@start datetime,
	@end datetime,
	@assigned int
AS
BEGIN
	SET NOCOUNT ON

	select ac.id, c.name, ac.duetime, dbo.QCheck_AssigneesList(ci.id) as assignees, c.ID AS ChecklistId
	INTO #result
	from
	qcheck_checklists c
	inner join qcheck_checklistmanagers cm
		on cm.isdeleted = 0
		and cm.checklistid = c.id
	inner join qcheck_groupmembership gm
		on gm.groupid = cm.managergroupid
		and gm.userid = @controller
	inner join qcheck_checklistinstances ci
		on ci.checklistid = c.id
		and ci.id not in (
			select ci.id from qcheck_assignments a
			inner join qcheck_checklistinstances ci
				on a.instanceid = ci.id
			inner join qcheck_groupmembership gm
				on gm.groupid = a.groupid
				and gm.userid = @controller
		)
	inner join qcheck_activechecklists ac
		on ac.instanceid = ci.id
		and ac.duetime between @start and dateadd(day, 1, @end)
		and ac.completeddate is null
	where (
		@assigned = -1
		or 
		ci.id in (
			select ci.id from qcheck_assignments a
			inner join qcheck_checklistinstances ci
				on a.instanceid = ci.id
				and a.groupid = @assigned
		)
	)

	DECLARE @recordIds AS RecordId
	INSERT INTO @recordIds
		SELECT DISTINCT ChecklistId FROM #result WHERE ChecklistId IS NOT NULL

	EXEC dbo.Audit_Set @controller, @recordIds, 'Checklist', 2 

	DELETE @recordIds
	INSERT INTO @recordIds
		SELECT DISTINCT ID FROM #result WHERE ID IS NOT NULL

	EXEC dbo.Audit_Set @controller, @recordIds, 'ActiveChecklist', 2

	SELECT * FROM #result ORDER BY [Name]
END
GO

CREATE OR ALTER PROCEDURE [dbo].[QCheck_GetSingleChecklist](
	@loginID int,
	@type int, 
	@id int
)
 AS

BEGIN

	SET NOCOUNT ON

	DECLARE @tblAssigned table(
			InstanceID int,
			AssignmentID int,
			AssignedTo int
		)
	INSERT INTO @tblAssigned
	SELECT a.InstanceID, a.ID, @loginID
	FROM QCheck_Assignments a
	INNER JOIN QCheck_Groups g
		on
			g.ID = a.GroupID
	INNER JOIN QCheck_Groupmembership gm
		on
			gm.GroupID = g.ID
			and gm.UserID = @loginID
	WHERE a.IsDeleted = 0
	
	
	IF @type = 1
	BEGIN
		-- get current checklists
		SELECT Distinct c.Name as ChecklistName
			, c.ID AS ChecklistID
			, c.CreateDate
			, j.Name as ItemType
			, d.Text
			, d.URL
			, e.Text UserText
			, u.FullName As CompletedBy
			, convert(varchar,e.CompletedDate,1) + Right(convert(varchar,e.CompletedDate,0), charindex(' ',reverse(convert(varchar,e.CompletedDate,0)))) as CompletedDate
			, d.ID as ItemID
			, a.ID As Identifier
			, a.ID as UniqueID
			, d.SequenceNum
			, a.DueTime
			, a.ReminderDate
			, a.CompletedDate As ActiveChkCompletedDate
			, CASE WHEN ta.AssignmentID is null then null else 1 end as AssignmentID
			, 1 As ChkType
			, e.CompletedBy as CompletedByID
			, ta.AssignedTo
			, 0 as UpcomingID
			, CASE WHEN s.freqType > 1 THEN 1 ELSE 0 END as Recurring
			, CASE WHEN s.freqType = 1 THEN 'One Time' 
				 WHEN s.freqType = 2 THEN CASE WHEN s.freqRecurrance = 1 THEN 'Daily' ELSE 'Every ' + CONVERT(varchar,s.freqRecurrance) + ' days' END 
				 WHEN s.freqType = 3 THEN 
						CASE WHEN s.freqRecurrance = 1 THEN 
								'Weekly' 
						ELSE 
								'Every ' + CONVERT(varchar,s.freqRecurrance) + ' weeks' 
						END + CASE WHEN s.freqInterval > 0 THEN ' on ' + dbo.QCheck_GetDaysFromInterval(s.freqInterval) ELSE '' END
				 WHEN s.freqType = 4 and s.freqRecurrance <> 3 THEN CASE WHEN s.freqRecurrance = 1 THEN 'Monthly' ELSE 'Every ' + CONVERT(varchar,s.freqRecurrance) + ' months' END
				 WHEN s.freqType = 4 and s.freqRecurrance = 3 THEN 'Quarterly' 
 				 WHEN s.freqType = 5 THEN 
						CASE WHEN s.freqRecurrance = 1 THEN 
								'Yearly' 
						ELSE 
								'Every ' + CONVERT(varchar,s.freqRecurrance) + ' years' 
						END + CASE WHEN s.freqInterval > 0 THEN ' in ' + dbo.QCheck_GetMonthsFromInterval(s.freqInterval) ELSE '' END
				ELSE '' END as ScheduleString
			, dbo.QStatus_GetChecklistControllers(c.ID) AS Controllers
			, dbo.QStatus_GetChecklistReports(a.ID, @loginID) as StatusReportString
			, isnull(al.assignees,'') as Assignees
			, CASE WHEN (freqType = 2 AND freqRecurrance = 1) OR (freqType = 3 AND freqRecurrance = 1 AND (freqInterval & 62) = 62) THEN 1 ELSE 0 END as IsDaily
			, case when cai.id is null then 0 else 1 end as ControllerPartOfAssignee
			, isnull(a.isna, 0) as isna
			, isnull(a.nareason, '') as nareason
			, case when aac.DueTime IS NOT NULL THEN 1 ELSE 0 END PendingChange
			, aac.DueTime NewDeadline
			, e.ID AS ActiveItemId
		INTO #result
		FROM
			QCheck_ActiveChecklists a 
			INNER JOIN QCheck_ChecklistInstances b ON a.InstanceID = b.ID AND b.IsDeleted = 0
			INNER JOIN QCheck_Checklists c on b.checklistID = c.ID AND c.IsDeleted = 0
			INNER JOIN QCheck_Items d on d.checklistID = c.ID AND d.IsDeleted = 0
			LEFT OUTER JOIN QCheck_ItemTypes j on d.ItemTypeID = j.ID
			LEFT OUTER JOIN @tblAssigned ta on ta.InstanceID = b.ID
			LEFT OUTER JOIN QCheck_ActiveItems e on e.ActiveChecklistID = a.ID and e.ChecklistItemID = d.ID
			LEFT OUTER JOIN QCheck_Users u on e.CompletedBy = u.ID
			LEFT OUTER JOIN QCheck_Schedule s ON b.ScheduleID = s.ID
			LEFT OUTER JOIN	dbo.QCheck_AssigneeLookup AL on a.InstanceID=al.InstanceID
			LEFT OUTER JOIN QCheck_ControllerAssigneeInstances cai on cai.id = b.id
			LEFT OUTER JOIN QCheck_MostRecentDeadlineRequests mrdr
					ON a.ID = mrdr.ActiveChecklistID
			LEFT OUTER JOIN QCheck_Approval_ChangeRequests cr
				ON cr.ID = mrdr.ChangeRequestID
			LEFT OUTER JOIN QCheck_Approval_ActiveChecklists aac
					ON aac.ChangeRequestID = CR.[ID]
					AND aac.ActiveChecklistID = mrdr.ActiveChecklistID
			WHERE
			a.ID = @id
		ORDER BY 
			SequenceNum

		DECLARE @recordIds AS RecordId
		INSERT INTO @recordIds
			SELECT DISTINCT ChecklistId
			FROM #result
			WHERE ChecklistId IS NOT NULL
		EXEC dbo.Audit_Set @loginID, @recordIds, 'Checklist', 2

		DELETE @recordIds
		INSERT INTO @recordIds
			SELECT DISTINCT ItemID
			FROM #result
			WHERE ItemID IS NOT NULL
		EXEC dbo.Audit_Set @loginID, @recordIds, 'Item', 2

		DELETE @recordIds
		INSERT INTO @recordIds
			SELECT DISTINCT ActiveItemId
			FROM #result
			WHERE ActiveItemId IS NOT NULL
		EXEC dbo.Audit_Set @loginID, @recordIds, 'ActiveItem', 2

		-- return result
		SELECT * FROM #result ORDER BY SequenceNum
	END

	IF @type = 2
	BEGIN
		SELECT distinct c.Name as ChecklistName
			, c.ID AS ChecklistID
			, c.CreateDate
			, j.Name as ItemType
			, d.Text
			, d.URL
			, e.Text UserText
			, uu.FullName AS CompletedBy
			, convert(varchar,e.CompletedDate,1) + Right(convert(varchar,e.CompletedDate,0),charindex(' ',reverse(convert(varchar,e.CompletedDate,0)))) as CompletedDate
			, d.ID as ItemID
			, a.ID As Identifier
			, a.ID As UniqueID
			, d.SequenceNum
			, CASE WHEN a.ArchiveDate IS NULL Then a.dueTime Else NULL End As DueTime
			, CASE WHEN a.ArchiveDate IS NULL Then a.ReminderDate Else NULL End As ReminderDate
			, a.CompletedDate As ActiveChkCompletedDate
			, null as AssignmentID
			, 1 As ChkType
			, null As Members
			, 0 as CompletedByID
			, 0 As AssignedTo
			, 0 as UpcomingID
			, CASE WHEN s.freqType > 1 THEN 1 ELSE 0 END as Recurring
			, CASE WHEN s.freqType = 1 THEN 'One Time' 
				 WHEN s.freqType = 2 THEN CASE WHEN s.freqRecurrance = 1 THEN 'Daily' ELSE 'Every ' + CONVERT(varchar,s.freqRecurrance) + ' days' END 
				 WHEN s.freqType = 3 THEN 
						CASE WHEN s.freqRecurrance = 1 THEN 
								'Weekly' 
						ELSE 
								'Every ' + CONVERT(varchar,s.freqRecurrance) + ' weeks' 
						END + CASE WHEN s.freqInterval > 0 THEN ' on ' + dbo.QCheck_GetDaysFromInterval(s.freqInterval) ELSE '' END
				 WHEN s.freqType = 4 and s.freqRecurrance <> 3 THEN CASE WHEN s.freqRecurrance = 1 THEN 'Monthly' ELSE 'Every' + CONVERT(varchar,s.freqRecurrance) + ' months' END
				 WHEN s.freqType = 4 and s.freqRecurrance = 3 THEN 'Quarterly' 
 				 WHEN s.freqType = 5 THEN 
						CASE WHEN s.freqRecurrance = 1 THEN 
								'Yearly' 
						ELSE 
								'Every ' + CONVERT(varchar,s.freqRecurrance) + ' years' 
						END + CASE WHEN s.freqInterval > 0 THEN ' in ' + dbo.QCheck_GetMonthsFromInterval(s.freqInterval) ELSE '' END
				ELSE '' END as ScheduleString
			, dbo.QStatus_GetChecklistControllers(c.ID) AS Controllers
			, '' as StatusReportString
			, isnull(al.assignees,'') as Assignees
			, CASE WHEN (freqType = 2 AND freqRecurrance = 1) OR (freqType = 3 AND freqRecurrance = 1 AND (freqInterval & 62) = 62) THEN 1 ELSE 0 END as IsDaily
			, case when cai.id is null then 0 else 1 end as ControllerPartOfAssignee
			, isnull(a.isna, 0) as isna
			, isnull(a.nareason, '') as nareason
	FROM
		QCheck_ActiveChecklistArchive a 
		INNER JOIN 
			(
			SELECT 
				ID, ChecklistID, ScheduleID, null as ArchiveDate
			FROM QCheck_ChecklistInstances chkInst
			UNION ALL
			SELECT 
				ID, ChecklistID, ScheduleID, ArchiveDate
			FROM 
				QCheck_ChecklistInstanceArchive 

			) b
		 ON a.InstanceID = b.ID 
		INNER JOIN QCheck_Checklists_All c
		 on b.checklistID = c.ID 
		INNER JOIN 
			QCheck_Items d
		 on d.checklistID = c.ID 
		INNER JOIN 
			QCheck_ItemTypes j 
		 on d.ItemTypeID = j.ID
		left outer JOIN QCheck_ActiveItemArchive e
			
		 on 
			e.ActiveChecklistID = a.ID 
			and e.ChecklistItemID = d.ID 
		LEFT OUTER JOIN QCheck_Users uu 
			ON 
			uu.ID = e.CompletedBy
		LEFT OUTER JOIN QCheck_Schedule s ON b.ScheduleID = s.ID
		LEFT OUTER JOIN	dbo.QCheck_AssigneeLookup AL on a.InstanceID=al.InstanceID
		LEFT OUTER JOIN QCheck_ControllerAssigneeInstances cai on cai.id = b.id
 WHERE
		a.ID = @ID
 ORDER BY 
		SequenceNum
	END

	IF @type = 3
	BEGIN
		-- get future checklists
		SELECT Distinct 
			c.Name as ChecklistName
			, c.ID AS ChecklistID
			, c.CreateDate
			, j.Name as ItemType
			, d.Text
			, d.URL
			, null As UserText
			, null As CompletedBy
			, null As CompletedDate
			, d.ID as ItemID
			, b.ID As Identifier
			, uc.ID As UniqueID
			, d.SequenceNum
			, uc.DueTime
			, NULL AS ReminderDate
			, null As ActiveChkCompletedDate
			, CASE WHEN ta.AssignmentID is null then null else 1 end as AssignmentID
			, 2 As ChkType
			, 0 As AssignedTo
			, uc.ID as UpcomingID
			, CASE WHEN s.freqType > 1 THEN 1 ELSE 0 END as Recurring
			, CASE WHEN s.freqType = 1 THEN 'One Time' 
				 WHEN s.freqType = 2 THEN CASE WHEN s.freqRecurrance = 1 THEN 'Daily' ELSE 'Every ' + CONVERT(varchar,s.freqRecurrance) + ' days' END 
				 WHEN s.freqType = 3 THEN 
						CASE WHEN s.freqRecurrance = 1 THEN 
								'Weekly' 
						ELSE 
								'Every ' + CONVERT(varchar,s.freqRecurrance) + ' weeks' 
						END + CASE WHEN s.freqInterval > 0 THEN ' on ' + dbo.QCheck_GetDaysFromInterval(s.freqInterval) ELSE '' END
				 WHEN s.freqType = 4 and s.freqRecurrance <> 3 THEN CASE WHEN s.freqRecurrance = 1 THEN 'Monthly' ELSE 'Every' + CONVERT(varchar,s.freqRecurrance) + ' months' END
				 WHEN s.freqType = 4 and s.freqRecurrance = 3 THEN 'Quarterly' 
 				 WHEN s.freqType = 5 THEN 
						CASE WHEN s.freqRecurrance = 1 THEN 
								'Yearly' 
						ELSE 
								'Every ' + CONVERT(varchar,s.freqRecurrance) + ' years' 
						END + CASE WHEN s.freqInterval > 0 THEN ' in ' + dbo.QCheck_GetMonthsFromInterval(s.freqInterval) ELSE '' END
				ELSE '' END as ScheduleString
			, dbo.QStatus_GetChecklistControllers(c.ID) AS Controllers
			, '' as StatusReportString
			, isnull(al.assignees,'') as Assignees
			, CASE WHEN (freqType = 2 AND freqRecurrance = 1) OR (freqType = 3 AND freqRecurrance = 1 AND (freqInterval & 62) = 62) THEN 1 ELSE 0 END as IsDaily
			, case when cai.id is null then 0 else 1 end as ControllerPartOfAssignee
			, 0 as isna
			, '' as nareason
		FROM
			QCheck_ChecklistInstances b
			INNER JOIN QCheck_Checklists c on b.checklistID = c.ID AND c.IsDeleted = 0
			INNER JOIN QCheck_Items d on d.checklistID = c.ID AND d.IsDeleted = 0
			INNER JOIN QCheck_ItemTypes j on d.ItemTypeID = j.ID
			LEFT OUTER JOIN @tblAssigned ta on ta.InstanceID = b.ID
			INNER JOIN QCheck_UpcomingDueTimes uc on uc.InstanceID = b.ID and uc.ID = @id
			LEFT OUTER JOIN QCheck_Schedule s ON b.ScheduleID = s.ID
			LEFT OUTER JOIN	dbo.QCheck_AssigneeLookup AL on b.ID=al.InstanceID
			LEFT OUTER JOIN QCheck_ControllerAssigneeInstances cai on cai.id = b.id
		ORDER BY 
			SequenceNum
	END
	
	SET NOCOUNT OFF

END
GO

CREATE OR ALTER PROCEDURE [dbo].[QCheck_GetUserChecklists](
	@UserID int,
	@activeChecklistID int = 0,
	@instanceID int = 0,
	@startDate datetime = null,
	@endDate datetime = null,
	@recurrance int = 0
) AS
BEGIN
	SET NOCOUNT ON
	
	-- get current checklists
	SELECT 
		c.ID as ChecklistID,
		c.Name as ChecklistName, 
		c.CreateDate,
		j.Name as ItemType, 
		d.Text, 	
		d.URL, 
		e.Text UserText, 
		u.FullName As CompletedBy, 
		convert(varchar,e.CompletedDate,1) + 
		Right(convert(varchar,e.CompletedDate,0),
		charindex(' ',reverse(convert(varchar,e.CompletedDate,0)))) 
		as CompletedDate, 
		d.ID as ItemID, 
		a.ID As Identifier, 
		a.ID as UniqueID, 
		d.SequenceNum, 
		a.dueTime, 
		0 as UpcomingID, 
		a.CompletedDate As ActiveChkCompletedDate, 
		--f.ID as AssignmentID, 
		isNull(a.CompletedDate,'12/12/9999') As Computed, 	
		1 As ChkType, 
		e.CompletedBy as CompletedByID,
		a.dueTime as dueSort,
		CASE WHEN s.freqType > 1 THEN 1 ELSE 0 END as Recurring,
		CASE WHEN s.freqType = 1 THEN 'One Time' 
			 WHEN s.freqType = 2 THEN CASE WHEN s.freqRecurrance = 1 THEN 'Daily' ELSE 'Every ' + CONVERT(varchar,s.freqRecurrance) + ' days' END 
			 WHEN s.freqType = 3 THEN 
					CASE WHEN s.freqRecurrance = 1 THEN 
							'Weekly' 
					ELSE 
							'Every ' + CONVERT(varchar,s.freqRecurrance) + ' weeks' 
					END + CASE WHEN s.freqInterval > 0 THEN ' on ' + dbo.QCheck_GetDaysFromInterval(s.freqInterval) ELSE '' END
			 WHEN s.freqType = 4 and s.freqRecurrance <> 3 THEN CASE WHEN s.freqRecurrance = 1 THEN 'Monthly' ELSE 'Every' + CONVERT(varchar,s.freqRecurrance) + ' months' END
			 WHEN s.freqType = 4 and s.freqRecurrance = 3 THEN 'Quarterly' 
 			 WHEN s.freqType = 5 THEN 
					CASE WHEN s.freqRecurrance = 1 THEN 
							'Yearly' 
					ELSE 
							'Every ' + CONVERT(varchar,s.freqRecurrance) + ' years' 
					END + CASE WHEN s.freqInterval > 0 THEN ' in ' + dbo.QCheck_GetMonthsFromInterval(s.freqInterval) ELSE '' END
			ELSE '' END as ScheduleString,
		--dbo.QStatus_GetActiveChecklistControllers(a.ID) AS Controllers,
		--dbo.QStatus_GetChecklistReports(a.ID, @UserID) as StatusReportString
		isnull(ccl.controllers, '') as Controllers,
		isnull(trl.reportslist, '') as StatusReportString,
		isnull(al.assignees,'') as Assignees,
		case when ms.checklistid is null then 0 else 1 end as MultiStep,
		case when cai.id is null then 0 else 1 end as ControllerPartOfAssignee,
		al.assigneecount,
		case when aac.ActiveChecklistID is null then 0 else 1 end as PendingChange, 
		aac.DueTime as NewDeadline,
		isnull(a.isna, 0) as isna, 
		isnull(a.nareason, '') as nareason,
		e.ID AS ActiveItemId
	INTO #result
	FROM
		QCheck_ActiveChecklists a 
		INNER JOIN QCheck_ChecklistInstances b ON a.InstanceID = b.ID AND b.IsDeleted = 0
		INNER JOIN QCheck_Schedule s ON b.ScheduleID = s.ID and Not (s.freqType = 1 and @recurrance = 2) and Not (s.freqType > 1 and @recurrance = 1)
		INNER JOIN QCheck_Checklists c on b.checklistID = c.ID AND c.IsDeleted = 0
		INNER JOIN QCheck_Items d on d.checklistID = c.ID AND d.IsDeleted = 0
		INNER JOIN QCheck_ItemTypes j on d.ItemTypeID = j.ID
		INNER JOIN QCheck_ActiveAssignments k on k.ActiveChecklistID = a.ID 
		INNER JOIN QCheck_GroupMembership gm on gm. UserID = @UserID
		INNER JOIN QCheck_Groups g on g.ID = gm.GroupID
		INNER JOIN QCheck_Assignments f on f.GroupID = gm.GroupID And f.IsDeleted = 0 and f.InstanceID = b.ID
		LEFT OUTER JOIN QCheck_ActiveItems e on e.ActiveChecklistID = a.ID and e.ChecklistItemID = d.ID
		LEFT OUTER JOIN QCheck_Users u on e.CompletedBy = u.ID
		LEFT OUTER JOIN QStatus_TaskReportList trl on trl.activechecklistid = a.id and trl.userid = @UserID
	 LEFT OUTER JOIN QCheck_ChecklistControllersList ccl on ccl.checklistid = c.id
		LEFT OUTER JOIN	dbo.QCheck_AssigneeLookup AL on a.InstanceID=al.InstanceID
		LEFT OUTER JOIN QCheck_MultiStep ms on ms.checklistid = c.ID
		LEFT OUTER JOIN QCheck_ControllerAssigneeInstances cai on cai.id = b.id
		--LEFT OUTER JOIN QCheck_PendingApprovals pa on pa.activechecklistid = a.id
		LEFT OUTER JOIN QCheck_MostRecentDeadlineRequests mrdr
				ON a.ID = mrdr.ActiveChecklistID
		LEFT OUTER JOIN QCheck_Approval_ChangeRequests cr
			ON cr.ID = mrdr.ChangeRequestID
		LEFT OUTER JOIN QCheck_Approval_ActiveChecklists aac
				ON aac.ChangeRequestID = CR.[ID]
				AND aac.ActiveChecklistID = mrdr.ActiveChecklistID
	 WHERE
		-- 3/30/2016 dalvarado - removing this filter so you can see past completed items
		--(a.CompletedDate is null or (DatePart(month,a.CompletedDate) = DatePart(month,getDate()) and DatePart(day,a.CompletedDate) = DatePart(day,getDate()) and DatePart(year,a.CompletedDate) = DatePart(year,getDate()))) AND 
		(@activeChecklistID = 0 or a.ID = @activeChecklistID)
		AND @instanceID = 0
		AND a.dueTime between @startDate and @endDate

	UNION 
	
	-- get future checklists
	SELECT 
		c.ID As ChecklistID,
		c.Name as ChecklistName, 
		c.CreateDate,
		j.Name as ItemType, 
		d.Text, 
		d.URL, 
		null As UserText, 
		null As CompletedBy, 
		null As CompletedDate,
		d.ID as ItemID,
		b.ID As Identifier,
		upcoming1.ID as UniqueID, 
		d.SequenceNum, 
		upcoming1.DueTime as dueTime, 
		upcoming1.ID as UpcomingID,
		null As ActiveChkCompletedDate, 
		--f.ID as AssignmentID, 
		'12/12/9999' As Computed, 	
		2 As ChkType, 
		0 as CompletedByID,
		upcoming1.DueTime as dueSort,
		CASE WHEN s.freqType > 1 THEN 1 ELSE 0 END as Recurring,
		CASE WHEN s.freqType = 1 THEN 'One Time' 
			 WHEN s.freqType = 2 THEN CASE WHEN s.freqRecurrance = 1 THEN 'Daily' ELSE 'Every ' + CONVERT(varchar,s.freqRecurrance) + ' days' END 
			 WHEN s.freqType = 3 THEN 
					CASE WHEN s.freqRecurrance = 1 THEN 
							'Weekly' 
					ELSE 
							'Every ' + CONVERT(varchar,s.freqRecurrance) + ' weeks' 
					END + CASE WHEN s.freqInterval > 0 THEN ' on ' + dbo.QCheck_GetDaysFromInterval(s.freqInterval) ELSE '' END
			 WHEN s.freqType = 4 and s.freqRecurrance <> 3 THEN CASE WHEN s.freqRecurrance = 1 THEN 'Monthly' ELSE 'Every' + CONVERT(varchar,s.freqRecurrance) + ' months' END
			 WHEN s.freqType = 4 and s.freqRecurrance = 3 THEN 'Quarterly' 
 			 WHEN s.freqType = 5 THEN 
					CASE WHEN s.freqRecurrance = 1 THEN 
							'Yearly' 
					ELSE 
							'Every ' + CONVERT(varchar,s.freqRecurrance) + ' years' 
					END + CASE WHEN s.freqInterval > 0 THEN ' in ' + dbo.QCheck_GetMonthsFromInterval(s.freqInterval) ELSE '' END
			ELSE '' END as ScheduleString,
		--dbo.QStatus_GetChecklistControllers(c.ID) AS Controllers,
		isnull(ccl.controllers, '') as Controllers,
		'' as StatusReportString,
		isnull(al.assignees,'') as Assignees,
		case when ms.checklistid is null then 0 else 1 end as MultiStep,
		case when cai.id is null then 0 else 1 end as ControllerPartOfAssignee,
		AL.assigneecount,
		0 as PendingChange, 
		null as NewDeadline,
		0 as isna, 
		'' as nareason,
		CAST(NULL AS INT) AS ActiveItemId
	FROM
		QCheck_ChecklistInstances b
		INNER JOIN QCheck_UpcomingDueTimes upcoming1
			ON b.ID = upcoming1.instanceID
			and upcoming1.DueTime between @StartDate and @EndDate
		INNER JOIN QCheck_Schedule s 
			ON b.ScheduleID = s.ID 
			and Not (s.freqType = 1 and @recurrance = 2) 
			and Not (s.freqType > 1 and @recurrance = 1)
		INNER JOIN QCheck_Checklists c 
			on b.checklistID = c.ID 
			AND c.IsDeleted = 0
		INNER JOIN QCheck_Items d 
			on d.checklistID = c.ID 
			AND d.IsDeleted = 0
		INNER JOIN QCheck_ItemTypes j 
			on d.ItemTypeID = j.ID
		INNER JOIN QCheck_GroupMembership gm 
			on gm. UserID = @UserID
		INNER JOIN QCheck_Groups g
			on g.ID = gm.GroupID
		INNER JOIN QCheck_Assignments f 
			on f.GroupID = gm.GroupID
			And f.IsDeleted = 0 
			and f.InstanceID = b.ID
		LEFT OUTER JOIN QCheck_ActiveChecklists ac
			ON ac.InstanceID = upcoming1.InstanceID
			AND ac.OrigDueTime = upcoming1.DueTime
		LEFT OUTER JOIN QCheck_ChecklistControllersList ccl on ccl.checklistid = c.id
		LEFT OUTER JOIN	dbo.QCheck_AssigneeLookup AL on b.ID=al.InstanceID
		LEFT OUTER JOIN QCheck_MultiStep ms on ms.checklistid = c.ID
		LEFT OUTER JOIN QCheck_ControllerAssigneeInstances cai on cai.id = b.id
	WHERE 
		not b.isDeleted = 1 
		AND (@instanceID = 0 or b.ID = @instanceID)
		AND @activeChecklistID = 0
		AND ac.ID is null
		AND @recurrance < 3
		
	ORDER BY --ChkType,
		Computed desc,
		dueSort,
		ChecklistName,
		Identifier,
		SequenceNum

	DECLARE @recordIds AS RecordId
	INSERT INTO @recordIds
		SELECT DISTINCT ChecklistId
		FROM #result
		WHERE ChecklistId IS NOT NULL
	EXEC dbo.Audit_Set @userId, @recordIds, 'Checklist', 2

	DELETE @recordIds
	INSERT INTO @recordIds
		SELECT DISTINCT ItemID
		FROM #result
		WHERE ItemID IS NOT NULL
	EXEC dbo.Audit_Set @userId, @recordIds, 'Item', 2

	DELETE @recordIds
	INSERT INTO @recordIds
		SELECT DISTINCT ActiveItemId
		FROM #result
		WHERE ActiveItemId IS NOT NULL
	EXEC dbo.Audit_Set @userId, @recordIds, 'ActiveItem', 2

	DELETE @recordIds
	INSERT INTO @recordIds
		SELECT DISTINCT UniqueID
		FROM #result
		WHERE UniqueID IS NOT NULL
	EXEC dbo.Audit_Set @userId, @recordIds, 'ActiveChecklist', 2

	-- return result
	SELECT * FROM #result
END
GO

CREATE OR ALTER PROC [dbo].[QCheck_SlimGetUserChecklists](
	@UserID int,
	@activeChecklistID int = 0,
	@instanceID int = 0,
	@startDate datetime = null,
	@endDate datetime = null,
	@recurrance int = 0
) AS
BEGIN
	SET NOCOUNT ON
	
	-- get current checklists
	SELECT 
		c.ID as ChecklistID,
		c.Name as ChecklistName, 
		c.CreateDate,
		a.ID As Identifier, 
		a.ID as UniqueID, 
		a.dueTime, 
		0 as UpcomingID, 
		a.CompletedDate As ActiveChkCompletedDate, 
		--f.ID as AssignmentID, 
		isNull(a.CompletedDate,'12/12/9999') As Computed, 	
		1 As ChkType, 
		a.dueTime as dueSort,
		CASE WHEN s.freqType > 1 THEN 1 ELSE 0 END as Recurring,
		CASE WHEN s.freqType = 1 THEN 'One Time' 
			 WHEN s.freqType = 2 THEN CASE WHEN s.freqRecurrance = 1 THEN 'Daily' ELSE 'Every ' + CONVERT(varchar,s.freqRecurrance) + ' days' END 
			 WHEN s.freqType = 3 THEN 
					CASE WHEN s.freqRecurrance = 1 THEN 
							'Weekly' 
					ELSE 
							'Every ' + CONVERT(varchar,s.freqRecurrance) + ' weeks' 
					END + CASE WHEN s.freqInterval > 0 THEN ' on ' + dbo.QCheck_GetDaysFromInterval(s.freqInterval) ELSE '' END
			 WHEN s.freqType = 4 and s.freqRecurrance <> 3 THEN CASE WHEN s.freqRecurrance = 1 THEN 'Monthly' ELSE 'Every' + CONVERT(varchar,s.freqRecurrance) + ' months' END
			 WHEN s.freqType = 4 and s.freqRecurrance = 3 THEN 'Quarterly' 
 			 WHEN s.freqType = 5 THEN 
					CASE WHEN s.freqRecurrance = 1 THEN 
							'Yearly' 
					ELSE 
							'Every ' + CONVERT(varchar,s.freqRecurrance) + ' years' 
					END + CASE WHEN s.freqInterval > 0 THEN ' in ' + dbo.QCheck_GetMonthsFromInterval(s.freqInterval) ELSE '' END
			ELSE '' END as ScheduleString,
		--dbo.QStatus_GetActiveChecklistControllers(a.ID) AS Controllers,
		--dbo.QStatus_GetChecklistReports(a.ID, @UserID) as StatusReportString
		isnull(ccl.controllers, '') as Controllers,
		isnull(trl.reportslist, '') as StatusReportString,
		isnull(al.assignees,'') as Assignees,
		case when ms.checklistid is null then 0 else 1 end as MultiStep,
		case when cai.id is null then 0 else 1 end as ControllerPartOfAssignee,
		al.assigneecount,
		case when aac.ActiveChecklistID is null then 0 else 1 end as PendingChange, 
		aac.DueTime as NewDeadline,
		isnull(a.isna, 0) as isna, 
		isnull(a.nareason, '') as nareason
	INTO #result
	FROM
		QCheck_ActiveChecklists a 
		INNER JOIN QCheck_ChecklistInstances b ON a.InstanceID = b.ID AND b.IsDeleted = 0
		INNER JOIN QCheck_Schedule s ON b.ScheduleID = s.ID and Not (s.freqType = 1 and @recurrance = 2) and Not (s.freqType > 1 and @recurrance = 1)
		INNER JOIN QCheck_Checklists c on b.checklistID = c.ID AND c.IsDeleted = 0
		INNER JOIN QCheck_ActiveAssignments k on k.ActiveChecklistID = a.ID 
		INNER JOIN QCheck_GroupMembership gm on gm. UserID = @UserID
		INNER JOIN QCheck_Groups g on g.ID = gm.GroupID
		INNER JOIN QCheck_Assignments f on f.GroupID = gm.GroupID And f.IsDeleted = 0 and f.InstanceID = b.ID
		LEFT OUTER JOIN QStatus_TaskReportList trl on trl.activechecklistid = a.id and trl.userid = @UserID
	 LEFT OUTER JOIN QCheck_ChecklistControllersList ccl on ccl.checklistid = c.id
		LEFT OUTER JOIN	dbo.QCheck_AssigneeLookup AL on a.InstanceID=al.InstanceID
		LEFT OUTER JOIN QCheck_MultiStep ms on ms.checklistid = c.ID
		LEFT OUTER JOIN QCheck_ControllerAssigneeInstances cai on cai.id = b.id
		--LEFT OUTER JOIN QCheck_PendingApprovals pa on pa.activechecklistid = a.id
		LEFT OUTER JOIN QCheck_MostRecentDeadlineRequests mrdr
				ON a.ID = mrdr.ActiveChecklistID
		LEFT OUTER JOIN QCheck_Approval_ChangeRequests cr
			ON cr.ID = mrdr.ChangeRequestID
		LEFT OUTER JOIN QCheck_Approval_ActiveChecklists aac
				ON aac.ChangeRequestID = CR.[ID]
				AND aac.ActiveChecklistID = mrdr.ActiveChecklistID
	 WHERE
		-- 3/30/2016 dalvarado - removing this filter so you can see past completed items
		--(a.CompletedDate is null or (DatePart(month,a.CompletedDate) = DatePart(month,getDate()) and DatePart(day,a.CompletedDate) = DatePart(day,getDate()) and DatePart(year,a.CompletedDate) = DatePart(year,getDate()))) AND 
		(@activeChecklistID = 0 or a.ID = @activeChecklistID)
		AND @instanceID = 0
		AND a.dueTime between @startDate and @endDate

	UNION 
	
	-- get future checklists
	SELECT 
		c.ID As ChecklistID,
		c.Name as ChecklistName, 
		c.CreateDate,
		b.ID As Identifier,
		upcoming1.ID as UniqueID, 
		upcoming1.DueTime as dueTime, 
		upcoming1.ID as UpcomingID,
		null As ActiveChkCompletedDate, 
		--f.ID as AssignmentID, 
		'12/12/9999' As Computed, 	
		2 As ChkType, 
		upcoming1.DueTime as dueSort,
		CASE WHEN s.freqType > 1 THEN 1 ELSE 0 END as Recurring,
		CASE WHEN s.freqType = 1 THEN 'One Time' 
			 WHEN s.freqType = 2 THEN CASE WHEN s.freqRecurrance = 1 THEN 'Daily' ELSE 'Every ' + CONVERT(varchar,s.freqRecurrance) + ' days' END 
			 WHEN s.freqType = 3 THEN 
					CASE WHEN s.freqRecurrance = 1 THEN 
							'Weekly' 
					ELSE 
							'Every ' + CONVERT(varchar,s.freqRecurrance) + ' weeks' 
					END + CASE WHEN s.freqInterval > 0 THEN ' on ' + dbo.QCheck_GetDaysFromInterval(s.freqInterval) ELSE '' END
			 WHEN s.freqType = 4 and s.freqRecurrance <> 3 THEN CASE WHEN s.freqRecurrance = 1 THEN 'Monthly' ELSE 'Every' + CONVERT(varchar,s.freqRecurrance) + ' months' END
			 WHEN s.freqType = 4 and s.freqRecurrance = 3 THEN 'Quarterly' 
 			 WHEN s.freqType = 5 THEN 
					CASE WHEN s.freqRecurrance = 1 THEN 
							'Yearly' 
					ELSE 
							'Every ' + CONVERT(varchar,s.freqRecurrance) + ' years' 
					END + CASE WHEN s.freqInterval > 0 THEN ' in ' + dbo.QCheck_GetMonthsFromInterval(s.freqInterval) ELSE '' END
			ELSE '' END as ScheduleString,
		--dbo.QStatus_GetChecklistControllers(c.ID) AS Controllers,
		isnull(ccl.controllers, '') as Controllers,
		'' as StatusReportString,
		isnull(al.assignees,'') as Assignees,
		case when ms.checklistid is null then 0 else 1 end as MultiStep,
		case when cai.id is null then 0 else 1 end as ControllerPartOfAssignee,
		AL.assigneecount,
		0 as PendingChange, 
		null as NewDeadline,
		0 as isna, 
		'' as nareason
	FROM
		QCheck_ChecklistInstances b
		INNER JOIN QCheck_UpcomingDueTimes upcoming1
			ON b.ID = upcoming1.instanceID
			and upcoming1.DueTime between @StartDate and @EndDate
		INNER JOIN QCheck_Schedule s 
			ON b.ScheduleID = s.ID 
			and Not (s.freqType = 1 and @recurrance = 2) 
			and Not (s.freqType > 1 and @recurrance = 1)
		INNER JOIN QCheck_Checklists c 
			on b.checklistID = c.ID 
			AND c.IsDeleted = 0
		INNER JOIN QCheck_GroupMembership gm 
			on gm. UserID = @UserID
		INNER JOIN QCheck_Groups g
			on g.ID = gm.GroupID
		INNER JOIN QCheck_Assignments f 
			on f.GroupID = gm.GroupID
			And f.IsDeleted = 0 
			and f.InstanceID = b.ID
		LEFT OUTER JOIN QCheck_ActiveChecklists ac
			ON ac.InstanceID = upcoming1.InstanceID
			AND ac.OrigDueTime = upcoming1.DueTime
		LEFT OUTER JOIN QCheck_ChecklistControllersList ccl on ccl.checklistid = c.id
		LEFT OUTER JOIN	dbo.QCheck_AssigneeLookup AL on b.ID=al.InstanceID
		LEFT OUTER JOIN QCheck_MultiStep ms on ms.checklistid = c.ID
		LEFT OUTER JOIN QCheck_ControllerAssigneeInstances cai on cai.id = b.id
	WHERE 
		not b.isDeleted = 1 
		AND (@instanceID = 0 or b.ID = @instanceID)
		AND @activeChecklistID = 0
		AND ac.ID is null
		AND @recurrance < 3
		
	ORDER BY --ChkType,
		Computed desc,
		dueSort,
		ChecklistName,
		Identifier

	DECLARE @recordIds AS RecordId
	INSERT INTO @recordIds
		SELECT DISTINCT ChecklistId
		FROM #result
		WHERE ChecklistId IS NOT NULL
	EXEC dbo.Audit_Set @userId, @recordIds, 'Checklist', 2

	-- return result
	SELECT * FROM #result
END
GO

CREATE OR ALTER PROC [dbo].[QCheck_UpdateChecklistName]
	@ID INT,
	@Name VARCHAR(500),
	@UserId INT
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @recordIds AS RecordId
	INSERT INTO @recordIds VALUES(@ID)
	EXEC dbo.Audit_Set @userId, @recordIds, 'Checklist', 3

	UPDATE
		QCheck_Checklists
	SET
		Name = @Name
	WHERE [ID] = @ID
END
GO

CREATE OR ALTER PROC [dbo].[QCheck_UpdateItem]
	@ID INT,
	@ChecklistID INT,
	@SequenceNum INT = null,
	@ItemTypeID INT = null,
	@Text	varchar(max) = null,
	@URL	varchar(1000) = null,
	@UserId INT
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @recordIds AS RecordId

	-- move everything up if there is already one at that sequence
	If Not @SequenceNum is null
	BEGIN
		INSERT INTO @recordIds
			SELECT ID FROM QCheck_Items
			WHERE [SequenceNum] >= @SequenceNum
			AND EXISTS (
				SELECT ID FROM QCheck_Items 
				WHERE [ChecklistID] = @ChecklistID
				AND [SequenceNum] = @SequenceNum
			)
		EXEC dbo.Audit_Set @userId, @recordIds, 'Item', 3

		UPDATE QCheck_Items
		SET [SequenceNum] = [SequenceNum] + 1
		WHERE [SequenceNum] >= @SequenceNum
		AND EXISTS
		(
			SELECT ID FROM QCheck_Items 
			WHERE [ChecklistID] = @ChecklistID
			AND [SequenceNum] = @SequenceNum
		)
	END

	-- update the item itself
	DELETE @recordIds
	INSERT INTO @recordIds VALUES(@ID)
	EXEC dbo.Audit_Set @userId, @recordIds, 'Item', 3

	UPDATE
			QCheck_Items
		SET
			SequenceNum = IsNull(@SequenceNum, SequenceNum),
			ItemTypeID = IsNull(@ItemTypeID, ItemTypeID),
			[Text] = IsNull(@Text, [Text]),
			URL = IsNull(@URL, URL)
		WHERE [ID] = @ID	
END
GO

-- This stored procedure will Add an item to a checklist
--ChecklistID identifies the checklist
--SequenceNum is the order they show up in
--ItemTypeID is the foreign key to the itemtype table
-- which identifies what type of item this is
--Text is the text that is shown for this item
--URL is the more info link that will appear

CREATE OR ALTER PROCEDURE [dbo].[QCheck2_AddItem]
	@ChecklistID INT,
	@SequenceNum INT = null,
	@ItemTypeID INT,
	@Text	varchar(max),
	@URL	varchar(1000),
	@UserId INT,
	@ReturnID INT OUTPUT
AS
BEGIN
	SET NOCOUNT ON
	DECLARE @recordIds AS RecordId

	If @SequenceNum is null 
	BEGIN
		SELECT @SequenceNum = isnull(max([SequenceNum]),0) + 1
		FROM QCheck_Items
		WHERE [ChecklistID] = @ChecklistID
		AND IsDeleted = 0	
	END
	ELSE
	BEGIN
		-- if any item exists with the current sequence, then
		-- move everything up one to put it in place
		INSERT INTO @recordIds
			SELECT ID 
			FROM QCheck_Items
			WHERE [SequenceNum] >= @SequenceNum
			AND EXISTS (
				SELECT ID FROM QCheck_Items 
				WHERE [ChecklistID] = @ChecklistID
				AND [SequenceNum] = @SequenceNum
			)
		EXEC dbo.Audit_Set @userId, @recordIds, 'Item', 3
	
		UPDATE QCheck_Items
		SET [SequenceNum] = [SequenceNum] + 1
		WHERE [SequenceNum] >= @SequenceNum
		AND EXISTS
		(
			SELECT ID FROM QCheck_Items 
			WHERE [ChecklistID] = @ChecklistID
			AND [SequenceNum] = @SequenceNum
		)
	END
	
	-- now insert the new item directly into the table
	INSERT INTO
		QCheck_Items
	([ChecklistID], [SequenceNum], [ItemTypeID], [Text], [URL])
	VALUES
	(@ChecklistID,@SequenceNum,@ItemTypeID,@Text,@URL)
	SELECT @ReturnID = @@IDENTITY

	DELETE @recordIds
	INSERT INTO @recordIds VALUES(@ReturnID)
	EXEC dbo.Audit_Set @userId, @recordIds, 'Item', 1
END
GO

CREATE OR ALTER PROC [dbo].[QStatus_GetArchive]
	@ReportID int,
	@UserId int
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @Seed int
	INSERT INTO QStatus_Seed
	SELECT 1

	SELECT @Seed = scope_identity()

	DELETE FROM QStatus_Seed

	INSERT INTO QStatus_TempTasks (ID, keyID, specialTask)
	SELECT @Seed, t.id, 0
	FROM
		(
			SELECT *, null as archivedate, 0 as deleted FROM 
				QCheck_ActiveChecklists 
			UNION
			SELECT *, 1 as deleted FROM 
				QCheck_ActiveChecklistArchive 
			--where archivedate > dateadd(day, -56, getdate())
		) t
	INNER JOIN
		(
			SELECT *, null as archivedate, 0 as deleted FROM 
				QStatus_ActiveChecklistTaskType 
			UNION
			SELECT *, 1 as deleted FROM 
				QStatus_ActiveChecklistTaskTypeArchive 
		) actt
	ON
		actt.ActiveChecklistID = t.ID
	INNER JOIN
		QStatus_TaskTypes tt
	ON
		tt.ID = actt.TaskType
	INNER JOIN
		(
			SELECT *, null as archivedate, 0 as deleted FROM 
				QCheck_ChecklistInstances 
			UNION
			SELECT *, 1 as deleted FROM 
				QCheck_ChecklistInstanceArchive 
		) i
	ON
		i.ID = t.InstanceID
	INNER JOIN
		(
			SELECT *, null as archivedate, 0 as deleted FROM 
				QCheck_Checklists 
			UNION
			SELECT *, 1 as deleted FROM 
				QCheck_ChecklistArchive 
		) c
	ON
		c.ID = i.ChecklistID
	WHERE
		tt.ReportID = @ReportID
	AND
		(t.deleted = 1 or i.deleted = 1 or c.deleted = 1)

	--START HEADER
	SELECT
		r.ID as ID, 
		'Archive - ' + r.Name as Description,
		dateadd(day, -1, getdate()) as DueDate,
		null as ReminderDate,
		null as SortDate,
		null as Priority,
		null as Comments,
		null as UpdatedDate,
		'Header Row' as Type,
		-1 As NativeType,
		1 As ReturnOrder,
		'0' as TaskType,
		null as AssignedTo,
		null as Controllers,
		null as isRecurring,
		null as IsDaily,
		CAST(NULL AS INT) AS ChecklistId 
	INTO #result
	FROM
		QStatus_Report r
	WHERE
		r.ID = @ReportID
	
	--END OF HEADER

	UNION ALL

	SELECT DISTINCT
		null as ID, 
		null as Description,
		null as DueDate,
		null as ReminderDate,
		null as SortDate,
		null as Priority,
		null as Comments,
		null as UpdatedDate,
		'EnderType' as Type,
		-1,
		2 As ReturnOrder,
		'0' as TaskType,
		null as AssignedTo,
		null as Controllers,
		null as isRecurring,
		null as IsDaily,
		NULL AS ChecklistId

	UNION ALL

	-- SECTION HEADS
	SELECT null as ID, 
		'Archive' as Description,
		null as DueDate,
		null as ReminderDate,
		null as SortDate,
		null as Priority,
		null as Comments,
		null as UpdatedDate,
		'Sub Header Row' as Type,
		0 As NativeType,
		3 As ReturnOrder,
		'0' as TaskType,
		null as AssignedTo,
		null as Controllers,
		null as isRecurring,
		null as IsDaily,
		NULL AS ChecklistId
	--END SECTION HEADS

	UNION ALL

	--START SECTION HEADINGS
	SELECT null as ID, 
		null as Description,
		null as DueDate,
		null as ReminderDate,
		null as SortDate,
		null as Priority,
		null as Comments,
		null as UpdatedDate,
		'Headings Row' as Type,
		0 As NativeType,
		4 As ReturnOrder,
		'0' as TaskType,
		null as AssignedTo,
		null as Controllers,
		null as isRecurring,
		null as IsDaily,
		NULL AS ChecklistId
	--END SECTION HEADINGS

	UNION ALL

	--START SECTION ENDERS
	SELECT null as ID, 
		null as Description,
		null as DueDate,
		null as ReminderDate,
		null as SortDate,
		null as Priority,
		null as Comments,
		null as UpdatedDate,
		'EnderType' as Type,
		0 As NativeType,
		99999 As ReturnOrder,
		'0' as TaskType,
		null as AssignedTo,
		null as Controllers,
		null as isRecurring,
		null as IsDaily,
		NULL AS ChecklistId
	--END SECTION ENDERS

	UNION ALL
	
	--START SECTION
	SELECT 
		t.ID, 
		c.Name as Description,
		Convert(varchar, DueTime, 101) as DueDate,
		Convert(varchar, t.ReminderDate, 101) as ReminderDate,
		Convert(varchar, ISNULL(t.ReminderDate, t.DueTime), 101) as SortDate,
		actt.Priority,
		t.ID as Comments,
		null as UpdatedDate,
		'Archive' As Type,
		3 As NativeType,
		100 + cast(duetime as integer) as ReturnOrder, 
		'0' as TaskType,
		dbo.QCheck_FullAssigneesList(i.id) as AssignedTo,
		isnull(dbo.QCheck_ManagersList(c.[id]), '') as Controllers,
		null as isRecurring,
		null as IsDaily,
		c.ID AS ChecklistId
	FROM
		(
			SELECT *, null as archivedate, 0 as deleted FROM 
				QCheck_ActiveChecklists 
			UNION
			SELECT *, 1 as deleted FROM 
				QCheck_ActiveChecklistArchive 
			--where archivedate > dateadd(day, -56, getdate())
		) t
	INNER JOIN
		(
			SELECT *, null as archivedate, 0 as deleted FROM 
				QStatus_ActiveChecklistTaskType 
			UNION
			SELECT *, 1 as deleted FROM 
				QStatus_ActiveChecklistTaskTypeArchive 
		) actt
	ON
		actt.ActiveChecklistID = t.ID
	INNER JOIN
		QStatus_TaskTypes tt
	ON
		tt.ID = actt.TaskType
	INNER JOIN
		(
			SELECT *, null as archivedate, 0 as deleted FROM 
				QCheck_ChecklistInstances 
			UNION
			SELECT *, 1 as deleted FROM 
				QCheck_ChecklistInstanceArchive 
		) i
	ON
		i.ID = t.InstanceID
	INNER JOIN
		(
			SELECT *, null as archivedate, 0 as deleted FROM 
				QCheck_Checklists 
			UNION
			SELECT *, 1 as deleted FROM 
				QCheck_ChecklistArchive 
		) c
	ON
		c.ID = i.ChecklistID
	WHERE
		tt.ReportID = @ReportID
	AND
		(t.deleted = 1 or i.deleted = 1 or c.deleted = 1)
	
	--END SECTION

	DECLARE @recordIds AS RecordId
	INSERT INTO @recordIds
		SELECT DISTINCT ChecklistId FROM #result WHERE ChecklistId IS NOT NULL

	EXEC dbo.Audit_Set @userId, @recordIds, 'Checklist', 2

	SELECT * FROM #result ORDER BY ReturnOrder 

	SELECT 
		IsConfidential 
	FROM
		QStatus_Report
	WHERE
		ID = @ReportID

	
	SELECT @Seed
END
GO

CREATE OR ALTER PROC [dbo].[QStatus_GetCommentsAll]
	@Seed int,
	@ReportID int,
	@UserId int
AS
BEGIN

	--DECLARE @HasRelatedComments bit
	--SET @HasRelatedComments = 0

	SET NOCOUNT ON

	SELECT 
		Distinct null as archiveid, C.*, null as archivedt, 
		tt.keyID as TaskID,
		CASE WHEN gr.USERID IS NOT NULL THEN 
			0 --red
		ELSE
			CASE WHEN supcolor.colorNum is not null THEN
				supcolor.colorNum
			ELSE
				CASE WHEN sup.interestedParty = 0 THEN
					3 --green
				ELSE
					50 --purple
				END
			END
		END as colornum, 
		u.FullName,
		2147483647 as CommentSort
	INTO #result
	FROM
		QStatus_COMMENTS C
	INNER JOIN
		QStatus_TempTasks tt
	ON
		tt.ID = @Seed
	AND
		c.ForeignKeyID = abs(tt.KeyID)
	AND
		c.SpecialTask = tt.SpecialTask
	INNER JOIN 
		QCheck_Users u
	ON
		u.ID = C.UserID
	LEFT OUTER JOIN 
		(SELECT gm.UserID, s.InterestedParty
		FROM QStatus_SUPERVISORS s
		INNER JOIN QCheck_GroupMembership gm
		ON gm.GroupID = s.supervisorGroupID
		INNER JOIN QCheck_Groups g
		ON g.ID = gm.GroupID
		AND s.ReportID = @ReportID
	) sup
	ON sup.UserId = c.UserID
	LEFT OUTER JOIN 
		(SELECT gm.UserID
		FROM QStatus_GroupReport gr
		INNER JOIN QCheck_GroupMembership gm
		ON gm.GroupID = gr.GroupID
		INNER JOIN QCheck_Groups g
		ON g.ID = gm.GroupID
		AND gr.ReportID = @ReportID
	) gr
	ON gr.UserId = c.UserID
	LEFT OUTER JOIN
		QStatus_SupervisorColors supcolor
	ON
		supcolor.supervisorUserID = u.ID

	union all 

	SELECT 
		Distinct C.*,
		tt.keyID as TaskID,
		CASE WHEN gr.USERID IS NOT NULL THEN 
			0 --red
		ELSE
			CASE WHEN supcolor.colorNum is not null THEN
				supcolor.colorNum
			ELSE
				CASE WHEN sup.interestedParty = 0 THEN
					3 --green
				ELSE
					50 --purple
				END
			END
		END as colornum, 
		u.FullName,
		C.ArchiveID as CommentSort
	FROM
		QStatus_commentarchive C
	INNER JOIN
		QStatus_TempTasks tt
	ON
		tt.ID = @Seed
	AND
		c.ForeignKeyID = abs(tt.KeyID)
	AND
		c.SpecialTask = tt.SpecialTask
	INNER JOIN 
		QCheck_Users u
	ON
		u.ID = C.UserID
	LEFT OUTER JOIN 
		(SELECT gm.UserID, s.InterestedParty
		FROM QStatus_SUPERVISORS s
		INNER JOIN QCheck_GroupMembership gm
		ON gm.GroupID = s.supervisorGroupID
		INNER JOIN QCheck_Groups g
		ON g.ID = gm.GroupID
		AND s.ReportID = @ReportID
	) sup
	ON sup.UserId = c.UserID
	LEFT OUTER JOIN 
		(SELECT gm.UserID
		FROM QStatus_GroupReport gr
		INNER JOIN QCheck_GroupMembership gm
		ON gm.GroupID = gr.GroupID
		INNER JOIN QCheck_Groups g
		ON g.ID = gm.GroupID
		AND gr.ReportID = @ReportID
	) gr
	ON gr.UserId = c.UserID
	LEFT OUTER JOIN
		QStatus_SupervisorColors supcolor
	ON
		supcolor.supervisorUserID = u.ID
	
	DECLARE @recordIds AS RecordId
	INSERT INTO @recordIds
		SELECT DISTINCT ID FROM #result WHERE ID IS NOT NULL

	EXEC dbo.Audit_Set @userId, @recordIds, 'Comment', 2

	DELETE @recordIds
	INSERT INTO @recordIds
		SELECT DISTINCT archiveid FROM #result WHERE archiveid IS NOT NULL

	EXEC dbo.Audit_Set @userId, @recordIds, 'CommentArchived', 2

	SELECT * FROM #result ORDER BY CommentSort, DisplayOrder

	SELECT distinct ac2.ID
	FROM 
		QStatus_COMMENTS C
	INNER JOIN
		--QCheck_ActiveChecklists
	(
		select id, instanceid from QCheck_ActiveChecklists
		union all
		select id, instanceid from QCheck_ActiveChecklistArchive
	)
	 AC
	ON
		C.ForeignKeyID = AC.ID
	INNER JOIN
		--QCheck_ChecklistInstances
		(
		select id, checklistid from QCheck_ChecklistInstances
		union all
		select id, checklistid from QCheck_ChecklistInstanceArchive
	) 
	CI
	ON
		CI.ID = AC.InstanceID
	INNER JOIN
		QCheck_ChecklistInstances CI2
	ON
		CI.ChecklistID = CI2.ChecklistID
	INNER JOIN
		QCheck_ActiveChecklists AC2
	ON
		CI2.ID = AC2.InstanceID
	AND
		AC2.ID <> AC.ID
	INNER JOIN
		QStatus_TempTasks tt
	ON
		tt.ID = @Seed
	AND
		ac2.ID = tt.KeyID
	WHERE c.specialtask = 0
	

	--delete from QStatus_TempTasks where id = @Seed OR input_date < dateadd(mi, -1, getdate())
END
GO



CREATE OR ALTER PROC [dbo].[QStatus_GetLatestComments]
	@ReportID int,
	@TaskID int,
	@UserID int = null,
	@selectedComments varchar(1000) = null,
	@CommentsSince DATETIME = NULL
AS

	IF @CommentsSince IS NULL SET @CommentsSince = DATEADD(HOUR, -1, GETDATE())
	If @CommentsSince > getdate() SET @CommentsSince = DATEADD(HOUR, -1, GETDATE()) --time zone issue

	--if only specific comments were requested, parse them out into a table
	DECLARE @selectedCommentsTbl TABLE (commentID int)

	IF @selectedComments IS NOT NULL BEGIN
		INSERT INTO @selectedCommentsTbl
		SELECT n from dbo.Util_fn_List_To_Table(@selectedComments,',')
		
		INSERT INTO @selectedCommentsTbl
			SELECT DISTINCT
				C2.ID
			FROM 
				@SelectedCommentsTbl st
				INNER JOIN QStatus_Comments c1
					ON st.CommentID = c1.ID
				INNER JOIN QStatus_Comments c2
					ON c1.ForeignKeyID = c2.ForeignKeyID
					AND c1.ID <> c2.ID
					AND c2.CommentDt > c1.CommentDt
	END

	DECLARE @results TABLE
	(
		ID	int,
		ForeignKeyID	int,
		Comments	varchar(1500),
		DisplayOrder	int,
		TabIn	int,
		CommentDt	datetime,
		Initials	varchar(100),
		UserID	int,
		ReplyID	int,
		SpecialTask	bit,
		TaskID	int,
		ColorNum int,
		FullName varchar(100)
	)

	INSERT INTO @results
	SELECT 
		Distinct C.*, 
		task.taskID as TaskID,
	 	CASE WHEN gr.USERID IS NOT NULL THEN 
			0 --red
		ELSE
			CASE WHEN supcolor.colorNum is not null THEN
				supcolor.colorNum
			ELSE
				CASE WHEN sup.interestedParty = 0 THEN
					3 --green
				ELSE
					50 --purple
				END
			END
		END as colornum, 
		u.FullName
	FROM
		QStatus_COMMENTS C
	INNER JOIN 
	(
			SELECT actt.ActiveChecklistID as taskID, actt.ActiveChecklistID as [ID], actt.TaskType, 0 As SpecialTask
			FROM
				(SELECT *, null as archivedate FROM QCheck_ActiveChecklists 
				where ID = @TaskID
				union all
				select * FROM QCheck_ActiveChecklistArchive 
				where ID = @TaskID)
				T
			INNER JOIN
				QStatus_ActiveChecklistTaskType actt
			ON
				actt.ActiveChecklistID = t.ID
			
			
			UNION
		
			SELECT 
				-1 * ST.ID As taskID, ST.ID, ST.TaskType, 1 As SpecialTask
			FROM
				QStatus_SpecialTasks st
			WHERE
				ST.ID = ABS(@TaskID)	
			AND
				@TaskID < 0
		) task
	ON
		task.SpecialTask = c.SpecialTask
	AND
		c.ForeignKeyID = task.[ID]
	INNER JOIN
		QStatus_TaskTypes tt
	ON
		task.TaskType = tt.ID
	AND
		tt.ReportID = @ReportID
	INNER JOIN 
		QCheck_Users u
	ON
		u.ID = C.UserID
	LEFT OUTER JOIN 
		(SELECT gm.UserID, s.InterestedParty
		FROM QStatus_SUPERVISORS s
		INNER JOIN QCheck_GroupMembership gm
		ON gm.GroupID = s.supervisorGroupID
		INNER JOIN QCheck_Groups g
		ON g.ID = gm.GroupID
		AND s.ReportID = @ReportID
	) sup
	ON sup.UserId = c.UserID
	LEFT OUTER JOIN 
		(SELECT gm.UserID
		FROM QStatus_GroupReport gr
		INNER JOIN QCheck_GroupMembership gm
		ON gm.GroupID = gr.GroupID
		INNER JOIN QCheck_Groups g
		ON g.ID = gm.GroupID
		AND gr.ReportID = @ReportID
	) gr
	ON gr.UserId = c.UserID
	LEFT OUTER JOIN
		QStatus_SupervisorColors supcolor
	ON
		supcolor.supervisorUserID = u.ID
	
	WHERE
	 (
		c.ID in (
				SELECT ID FROM QStatus_comments 
				where 
					--USERID = @UserID AND 
					LEN(Comments)>0 AND 
					CommentDt > @CommentsSince
				)
			OR 
		c.ID in (
				SELECT ReplyID FROM QStatus_comments 
				where 
					--USERID = @UserID AND 
					LEN(Comments)>0 AND 
					CommentDt > @CommentsSince
				)
	)
	ORDER BY C.DisplayOrder

	IF @selectedComments IS NOT NULL
		DELETE FROM @results
		WHERE ID NOT IN (SELECT CommentID FROM @selectedCommentsTbl)

	DECLARE @recordIds AS RecordId
	INSERT INTO @recordIds
		SELECT DISTINCT ID FROM @results

	EXEC dbo.Audit_Set @userId, @recordIds, 'Comment', 2

	SELECT * FROM @results
GO

CREATE OR ALTER PROC [dbo].[QStatus_GetRelatedComments]
	@TaskID int,
	@UserId int,
	@OnlyCount bit = 0
AS

	SELECT Distinct C.*, u.FullName, AC.ID AS TaskID, AC.DueTime
	INTO #result
	FROM 
		QStatus_COMMENTS C
	INNER JOIN
		(
			SELECT 
				ID, InstanceID, DueTime
			FROM QCheck_ActiveChecklists
			UNION ALL
			SELECT 
				ID, InstanceID, DueTime
			FROM 
				QCheck_ActiveChecklistArchive 

		) AC
	ON
		C.ForeignKeyID = AC.ID
	AND
		AC.ID <> @TaskID
	INNER JOIN
		(
			SELECT 
				ID, ChecklistID
			FROM QCheck_ChecklistInstances chkInst
			UNION ALL
			SELECT 
				ID, ChecklistID
			FROM 
				QCheck_ChecklistInstanceArchive 

		) CI
	ON
		CI.ID = AC.InstanceID
	INNER JOIN
		QCheck_ChecklistInstances CI2
	ON
		CI.ChecklistID = CI2.ChecklistID
	INNER JOIN
		QCheck_ActiveChecklists AC2
	ON
		CI2.ID = AC2.InstanceID
	AND
		AC2.ID = @TaskID
	INNER JOIN 
		QCheck_Users u
	ON
		u.ID = C.UserID
	
	IF @OnlyCount = 1 BEGIN
		SELECT COUNT(*) FROM #result		
	END
	ELSE
	BEGIN	
		DECLARE @recordIds AS RecordId
		INSERT INTO @recordIds
			SELECT DISTINCT ID FROM #result WHERE ID IS NOT NULL
	
		EXEC dbo.Audit_Set @userId, @recordIds, 'Comment', 2
		
		SELECT * FROM #result
		ORDER BY DueTime, TaskID, DisplayOrder
	END
GO

CREATE OR ALTER PROC [dbo].[QStatus_GetReport] (
	@UserID int,
	@ReportID int,
	@deletedDate datetime = null,
	@MoveCompleted bit = 0,
	@DueFilter datetime = null,
	@AssignedTo int = -1,
	@PriorityListSetID INT = -1

/*
set @UserID = 24
set @ReportID = 1100843
set @MoveCompleted = 0
set @AssignedTo = -1
set @PriorityListSetID = 149
--set @PriorityListSetID = -1
*/
) AS

BEGIN
	
	--exec sp_recompile 'QStatus_GetReport'
 
	SET NOCOUNT ON
	
	DECLARE @ReportUserID int
	DECLARE @LastReadDate datetime
	DECLARE @CompletedType varchar(50)
	DECLARE @CompletedOrder int
	DECLARE @Seed int
	DECLARE @PriorityListSetName VARCHAR(50)
	
	INSERT INTO QStatus_Seed
		SELECT 1

	SELECT @Seed = scope_identity()

	DELETE FROM QStatus_Seed
	--find all the tasks

	DECLARE @ForeignKeyIDs TABLE (
		ForeignKeyID INT PRIMARY KEY
	)

	INSERT INTO @ForeignKeyIDs 
		SELECT distinct activechecklistid 
		FROM qstatus_commentedreporttasks
		WHERE reportID = @reportID 

	--add a day to whatever was passed in (takes care of default to midnight)
	IF @DueFilter is not null
		SET @DueFilter = DateAdd(day, 1, @DueFilter)
	
	SELECT @CompletedType = 'Completed'
	--find out if they are a user or supervisor/ip

	SET @ReportUserID = 0

	SELECT 
		@ReportUserID = UserID
	FROM
		QStatus_GroupReport gr
		INNER JOIN QCheck_Groups g
			ON g.ID = gr.GroupID
		INNER JOIN QCheck_GroupMembership gm
			ON gm.GroupID = g.ID
			AND gr.ReportID = @ReportID
			AND gm.UserID = @UserID

	--default to 60 days ago
	SELECT @LastReadDate = getdate() - 60
	
	--find last time it was marked read by you if you are supervisor/ip
	SELECT 
		@LastReadDate = LastViewed
	FROM 
		QStatus_SupervisorsLastViewed
	WHERE
		ReportID = @ReportID 
		AND SupervisorUserID = @UserID
	
	--if it is your report, just use yesterday
	IF @ReportUserID = @UserID
		SELECT @LastReadDate = dateadd(day, -1, getdate())

	DECLARE @tasks table(
		ID int PRIMARY KEY,
		DueTime datetime,
		ReminderDate datetime,
		InstanceID int,
		assignees varchar(1000),
		controllers VARCHAR(1000),
		tasktype int,
		taskdescription varchar(1000),
		nativetype int,
		tasktypeorder int,
		priority int,
		prioritychanged bit,
		duedatechanged bit,
		newtask bit,
		CompletedDate datetime,
		Archived bit,
		description varchar(1000),
		tasknamechanged bit,
		isDeleted bit,
		isRecurring bit,
		isPriority bit,
		isDaily bit
	)

	declare @instances table(
		ID int PRIMARY KEY,
		ChecklistID int,
		isRecurring bit
	)

	declare @checklists table(
		ID int PRIMARY KEY,
		Description varchar(1000),
		tasknamechanged bit
	)

	-- 02/23/2011 dalvarado - priorities section
	declare @priorities table (
		ID int PRIMARY KEY IDENTITY(1,1),
		InstanceID INT,
		Priority INT
	)

	INSERT INTO @priorities (
		InstanceID,
		Priority
	)
		SELECT 
			ac.InstanceID,
			pl.Priority
		FROM
			PriorityListUsers plu
			INNER JOIN PriorityList pl
				ON plu.UserID = pl.UserID
			INNER JOIN QCheck_ActiveChecklists ac
				ON pl.ActiveChecklistID = ac.[ID]
		WHERE 
			PLU.[SetID] = @PriorityListSetID

	SELECT @PriorityListSetName = [Name]
	FROM PriorityListSet
	WHERE [ID] = @PriorityListSetID

	insert into @tasks (
		ID ,
		DueTime,
		ReminderDate,
		InstanceID ,
		assignees ,
		controllers,
		tasktype ,
		taskdescription ,
		nativetype ,
		tasktypeorder ,
		priority ,
		prioritychanged ,
		duedatechanged ,
		newtask ,
		CompletedDate ,
		Archived,
		IsDeleted,
		IsPriority,
		IsDaily
	)
		SELECT distinct
			ac.ID, 
			ac.DueTime,
			CASE WHEN CONVERT(VARCHAR(10), ac.ReminderDate, 101) <> CONVERT(VARCHAR(10), ac.DueTime, 101) THEN ac.ReminderDate ELSE NULL END,
			ac.InstanceID,
			isnull(al.assignees, ''),
			isnull(dbo.QCheck_ManagersList(c.[id]), ''),
			--dbo.QCheck_FullAssigneesList(ac.instanceid),
			tt.ID,
			tt.Description,
			tt.NativeType,
			tt.DisplayOrder,
			actt.Priority,
			0 as PriorityChanged,
			0 as DueDateChanged,
			CASE WHEN actt.CreateDt > @deletedDate THEN 1 ELSE 0 END as NewTask,
			CompletedDate, 
			0,
			c.IsDeleted,
			CASE WHEN p.InstanceID IS NULL THEN 0 ELSE 1 END AS IsPriority,
			CASE WHEN (freqType = 2 AND freqRecurrance = 1) OR (freqType = 3 AND freqRecurrance = 1 AND (freqInterval & 62) = 62) THEN 1 ELSE 0 END as IsDaily
		FROM
			QStatus_ActiveChecklistTaskType actt
			INNER JOIN QStatus_TaskTypes	tt
				ON actt.TaskType = tt.ID
				AND
					tt.IsDeleted = 0
			INNER JOIN QCheck_ActiveChecklists ac
				ON ac.ID = actt.ActiveChecklistID
			INNER JOIN qcheck_checklistinstances ci
				ON ci.ID = ac.InstanceID
			INNER JOIN qcheck_checklists c
				ON ci.ChecklistID = c.ID
			INNER JOIN QCheck_Assignments a
				ON a.instanceID = ci.ID
				AND (
					a.GroupID = @AssignedTo 
					or @AssignedTo = -1
				)
				AND a.IsDeleted = 0
			left outer join qcheck_assigneelookup al
				on al.instanceid = ac.instanceid
			left outer join QCheck_Schedule s 
				ON ci.ScheduleID = s.ID 
			left outer join @Priorities p
				ON ac.InstanceID = p.InstanceID
			
		WHERE
			tt.ReportID = @ReportID
			AND (
				@DueFilter is null 
				OR ac.DueTime < @DueFilter
				OR isnull(ac.ReminderDate, ac.DueTime) < @DueFilter
				OR ac.ID in (
					SELECT ForeignKeyID 
					FROM @ForeignKeyIDs
				)
			)

	insert into @tasks (
		ID ,
		DueTime,
		ReminderDate,
		InstanceID ,
		assignees ,
		controllers,
		tasktype ,
		taskdescription ,
		nativetype ,
		tasktypeorder ,
		priority ,
		prioritychanged ,
		duedatechanged ,
		newtask ,
		CompletedDate ,
		Archived ,
		IsPriority,
		IsDaily
	)
		SELECT distinct 
			ac.ID, 
			ac.DueTime,
			CASE WHEN CONVERT(VARCHAR(10), ac.ReminderDate, 101) <> CONVERT(VARCHAR(10), ac.DueTime, 101) THEN ac.ReminderDate ELSE NULL END,
			ac.InstanceID, 
			isnull(al.assignees, ''),
			isnull(dbo.QCheck_ManagersList(ISNULL(cia.ChecklistID, ci.ChecklistID)), ''),
			--dbo.QCheck_FullAssigneesList(ac.instanceid),
			tt.ID,
			tt.Description,
			tt.NativeType,
			tt.DisplayOrder,
			actt.Priority,
			0 as PriorityChanged,
			0 as DueDateChanged,
			CASE WHEN actt.CreateDt > @deletedDate THEN 1 ELSE 0 END as NewTask,
			CompletedDate, 
			1,
			0,
			0
		FROM
			QStatus_ActiveChecklistTaskType actt
			INNER JOIN QStatus_TaskTypes	tt
				ON actt.TaskType = tt.ID
				AND tt.IsDeleted = 0
			INNER JOIN QCheck_ActiveChecklistArchive ac
				ON ac.ID = actt.ActiveChecklistID
				AND ac.archivedate > @deleteddate 
				AND @deleteddate is not null
			INNER JOIN QCheck_ActiveAssignmentArchive aa
				ON aa.ActiveChecklistID = ac.ID
			LEFT OUTER JOIN QCheck_ChecklistInstanceArchive cia
				ON ac.InstanceID = cia.[ID]
			-- 2/26/2013 dalvarado - found cases where the instance wasn't archived with the active checklist, so need to look
			-- in both checklistinstances and checklistinstancearchive.
			left outer join qcheck_checklistinstances ci
				ON ac.InstanceID = ci.ID
			left outer join qcheck_assigneelookup al
				on al.instanceid = ac.instanceid
		WHERE
			tt.ReportID = @ReportID
			AND (
				@DueFilter is null 
				OR ac.DueTime < @DueFilter 
				OR isnull(ac.ReminderDate, ac.DueTime) < @DueFilter 
				OR ac.ID in (
					SELECT ForeignKeyID 
					FROM @ForeignKeyIDs
				)
			)
			AND (
				@AssignedTo = -1
				OR aa.AssignmentsID in (
					SELECT ID 
					FROM QCheck_Assignments
					WHERE 
						GroupID = @AssignedTo 
						and isdeleted = 0
				)
				OR aa.AssignmentsID in (
					SELECT ID 
					FROM QCheck_AssignmentArchive
					WHERE 
						GroupID = @AssignedTo 
						and isdeleted = 0
				)
			)

	update 
		@tasks
	set 
		DueDateChanged = 1
	from 
		@tasks t
		inner join QStatus_DueDateChanges ddc
			on ddc.ActiveChecklistID =t.ID
			AND ddc.UpdateDt > @deletedDate
	
	update 
		@tasks
	set 
		PriorityChanged = 1
	from 
		@tasks t
		inner join QStatus_PriorityChanges pc
			on pc.ActiveChecklistID =t.ID
			AND pc.UpdateDt > @deletedDate

	-- 02/23/2011 dalvarado
	IF @PriorityListSetID <> -1 BEGIN

		UPDATE 
			@tasks
		SET 
			TaskType = -1000,
			TaskDescription = 'Top Priorities' + ISNULL(' - ' + @PriorityListSetName, ''),
			TaskTypeOrder = 10,
			Priority = p.Priority
		FROM 
			@tasks t
			inner join @priorities p
				on t.InstanceID = p.InstanceID

	END

	insert into @instances

		SELECT distinct
			ci.ID,
			ci.ChecklistID,
			CASE 
				WHEN s.freqType > 1 THEN 1 
				ELSE 0 
			END as isRecurring
		FROM 
			QCheck_ChecklistInstances ci
			INNER JOIN @tasks t
				ON t.InstanceID = ci.ID
			LEFT OUTER JOIN QCheck_Schedule s 
				ON ci.ScheduleID = s.ID 
		WHERE
			ci.IsDeleted = 0 
			OR @deleteddate is not null

		UNION ALL

		SELECT distinct
			ci.ID,
			ci.ChecklistID,
			CASE 
				WHEN s.freqType > 1 THEN 1 
				ELSE 0 
			END as isRecurring
		FROM 
			QCheck_ChecklistInstanceArchive ci
			INNER JOIN @tasks t
				ON t.InstanceID = ci.ID
			LEFT OUTER JOIN QCheck_Schedule s 
				ON ci.ScheduleID = s.ID 
		WHERE
			(
				ci.IsDeleted = 0 
				OR @deleteddate is not null
			)
			AND ci.archivedate > @deleteddate 
			AND @deleteddate is not null
	

	insert into @checklists

		SELECT DISTINCT
			c.ID,
			c.Name,
			CASE 
				WHEN tnc.ChecklistID IS NULL THEN 0 
				ELSE 1 
			END as TaskNameChanged
		FROM 
			QCheck_Checklists c
			INNER JOIN @instances ci
				ON c.ID = ci.ChecklistID
			LEFT OUTER JOIN QStatus_TaskNameChanges tnc
				ON tnc.ChecklistID = c.ID
				AND tnc.UpdateDt > @deletedDate
		WHERE
			c.IsDeleted = 0 
			OR @deleteddate is not null

		UNION ALL

		SELECT DISTINCT
			c.ID,
			c.Name,
			CASE 
				WHEN tnc.ChecklistID IS NULL THEN 0 
				ELSE 1 
			END as TaskNameChanged
		FROM 
			QCheck_ChecklistArchive c
			INNER JOIN @instances ci
				ON c.ID = ci.ChecklistID
			LEFT OUTER JOIN QStatus_TaskNameChanges tnc
				ON tnc.ChecklistID = c.ID
				AND tnc.UpdateDt > @deletedDate
		WHERE
			(
				c.IsDeleted = 0 
				OR @deleteddate is not null
			)
			AND c.archivedate > @deleteddate 
			AND @deleteddate is not null

	DELETE FROM @instances where checklistid not in (select id from @checklists)
	DELETE FROM @tasks where instanceid not in (select id from @instances)

	update @tasks
	set 
		description = c.description,
		tasknamechanged = c.tasknamechanged,
		isRecurring = i.isRecurring
	from 
		@tasks t
		inner join @instances i
			on i.id = t.instanceid
		inner join @checklists c
			on c.id = i.checklistid

	INSERT INTO QStatus_TempTasks (
		ID, 
		keyID, 
		specialTask
	)
		SELECT 
			@Seed, 
			id, 
			0
		FROM 
			@Tasks
	
	INSERT INTO QStatus_TempTasks (
		ID, 
		keyID, 
		specialTask
	)
		SELECT 
			@Seed, 
			-1 * st.id, 
			1
		FROM
			QStatus_SpecialTasks st
			INNER JOIN QStatus_TaskTypes tt
				ON st.TaskType = tt.ID
				AND tt.IsDeleted = 0
				AND tt.ReportID = @ReportID
				AND st.IsDeleted = 0

	DECLARE @recordIds AS RecordId
	INSERT INTO @recordIds
		SELECT DISTINCT ID FROM @checklists

	EXEC dbo.Audit_Set @userId, @recordIds, 'Checklist', 2

	--START HEADER
	SELECT
		null as ID, 
		dbo.QStatus_GetUserNames(r.ID) + 
			r.Name + ' - Status Report - '
			+ CASE 
				WHEN r.LastReportDate = 0 THEN 
					'No Status'
				ELSE 
					ISNULL(datename(dw, r.LastReportDate) + ' ', '') 
					+ ISNULL(CONVERT(varchar, r.LastReportDate, 101) + ' ', '') 
					+ ltrim(isnull(right(convert(varchar, r.LastReportDate, 100), 7), ''))
			END as Description,
		@LastReadDate as DueDate,
		@LastReadDate AS ReminderDate,
		@LastReadDate AS SortDate,
		null as Priority,
		null as Comments,
		null as UpdatedDate,
		'Header Row' as Type,
		-1 As NativeType,
		null as IsDeleted,
		1 As ReturnOrder,
		'0' as TaskType,
		0 as PriorityChanged,
		0 as DueDateChanged,
		0 as TaskNameChanged,
		0 as NewTask,
		null as AssignedTo,
		null as Controllers,
		null as isRecurring,
		null as IsDaily
	FROM
		QStatus_Report r
	WHERE
		r.ID = @ReportID
	--END OF HEADER
	
	UNION ALL

	SELECT DISTINCT
		null as ID, 
		null as Description,
		null as DueDate,
		null as ReminderDate,
		null as SortDate,
		null as Priority,
		null as Comments,
		null as UpdatedDate,
		'EnderType' as Type,
		-1,
		null as IsDeleted,
		2 As ReturnOrder, 
		'0' As TaskType,
		0 as PriorityChanged,
		0 as DueDateChanged,
		0 as TaskNameChanged,
		0 as NewTask,
		null as AssignedTo,
		null as Controllers,
		null as isRecurring,
		null as isDaily

	UNION ALL

	-- SECTION HEADS
	SELECT DISTINCT
		CASE WHEN t.CompletedDate IS Not Null then Null ELSE t.TaskType END AS ID, 
		CASE WHEN t.CompletedDate IS Not Null then @CompletedType +' - '+ taskdescription ELSE taskdescription END AS Description,
		null as DueDate,
		null as ReminderDate,
		null as SortDate,
		null as Priority,
		null as Comments,
		null as UpdatedDate,
		'Sub Header Row' as Type,
		CASE WHEN t.CompletedDate IS Not Null then 2 else t.NativeType end as NativeType,
		null as IsDeleted,
		CASE WHEN t.CompletedDate IS Not Null then t.tasktypeorder * 1000 * 2 + 1000 Else t.tasktypeorder * 1000 * 2 END As ReturnOrder,
		CASE WHEN t.CompletedDate IS Not Null then 'C' else '' END + CAST(t.tasktype as varchar) As TaskType,
		0 as PriorityChanged,
		0 as DueDateChanged,
		0 as TaskNameChanged,
		0 as NewTask,
		null as AssignedTo,
		null as Controllers,
		null as isRecurring,
		null as IsDaily
	FROM
		@tasks t
		-- 02/23/2011 dalvarado
--		LEFT OUTER JOIN @priorities p
--			ON t.[id] = p.TaskID
--	WHERE
--		p.[TaskID] IS NULL
	
	
	UNION ALL

	--START SECTION HEADINGS
	SELECT DISTINCT
		null as ID, 
		null as Description,
		null as DueDate,
		null as ReminderDate,
		null as SortDate,
		null as Priority,
		null as Comments,
		null as UpdatedDate,
		'Headings Row' as Type,
		CASE WHEN t.CompletedDate IS Not Null then 2 else t.NativeType end as NativeType,
		null as IsDeleted,
		CASE WHEN t.CompletedDate IS Not Null then t.tasktypeorder * 1000 * 2 + 1000 Else t.tasktypeorder * 1000 * 2 END + 1 As ReturnOrder,
		CASE WHEN t.CompletedDate IS Not Null then 'C' else '' END + CAST(t.tasktype as varchar) As TaskType,
		0 as PriorityChanged,
		0 as DueDateChanged,
		0 as TaskNameChanged,
		0 as NewTask,
		null as AssignedTo,
		null as Controllers,
		null as isRecurring,
		null as IsDaily
	FROM
		@tasks t
		-- 02/23/2011 dalvarado
--		LEFT OUTER JOIN @priorities p
--			ON t.[id] = p.TaskID
--	WHERE
--		p.[TaskID] IS NULL

	UNION ALL

	--START SECTION ENDERS
	SELECT DISTINCT
		null as ID, 
		CASE WHEN t.CompletedDate IS Not Null then @CompletedType else t.taskdescription end as Description,
		null as DueDate,
		null as ReminderDate,
		null as SortDate,
		null as Priority,
		null as Comments,
		null as UpdatedDate,
		'EnderType' as Type,
		CASE WHEN t.CompletedDate IS Not Null then 2 else t.NativeType end as NativeType,
		null as IsDeleted,
		CASE WHEN t.CompletedDate IS Not Null then t.tasktypeOrder * 1000 * 2 + 1000 Else t.tasktypeOrder * 1000 * 2 END + 999 As ReturnOrder,
		CASE WHEN t.CompletedDate IS Not Null then 'C' else '' END + CAST(tasktype as varchar) As TaskType,
		0 as PriorityChanged,
		0 as DueDateChanged,
		0 as TaskNameChanged,
		0 as NewTask,
		null as AssignedTo,
		null as Controllers,
		null as isRecurring,
		null as IsDaily
	FROM
		@tasks t
		-- 02/23/2011 dalvarado
--		LEFT OUTER JOIN @priorities p
--			ON t.[id] = p.TaskID
--	WHERE
--		p.[TaskID] IS NULL

	--END SECTION ENDERS

	UNION ALL
	
	--START SECTION
	SELECT 
		DISTINCT
		t.ID, 
		t.description + 
		CASE WHEN t.CompletedDate IS NULL THEN
			CASE WHEN t.archived = 1 THEN
				' (DELETED)'
			ELSE
				''
			END
		ELSE
			''
		END as Description,
		Convert(varchar, t.DueTime, 101) as DueDate,
		Convert(varchar, t.ReminderDate, 101) as ReminderDate,
		Convert(varchar, ISNULL(t.ReminderDate, t.DueTime), 101) as SortDate,
		t.Priority,
		CAST(t.ID as varchar) As Comments,
		0 as UpdatedDate,
		CASE WHEN t.CompletedDate IS Not Null then @CompletedType else t.taskDescription end As Type,
		CASE WHEN t.CompletedDate IS Not Null then 2 else
			CASE WHEN t.archived = 1 THEN
				3
			ELSE
				t.NativeType
			END
		END as NativeType,
		CASE WHEN t.CompletedDate IS NULL THEN
			CASE WHEN t.archived = 1 THEN
				1
			ELSE
				IsDeleted
			END
		ELSE
			IsDeleted
		END as IsDeleted,
		--0 as IsDeleted,
		CASE WHEN t.CompletedDate IS Not Null then t.tasktypeOrder * 1000 * 2 + 1000 Else t.tasktypeOrder * 1000 * 2 END + 100 + t.Priority As ReturnOrder,
		CASE WHEN t.CompletedDate IS Not Null then 'C' else '' END + CAST(tasktype as varchar) As TaskType,
		PriorityChanged,
		DueDateChanged,
		TaskNameChanged,
		NewTask,
		Assignees as AssignedTo,
		Controllers,
		t.isRecurring as isRecurring,
		t.IsDaily as isDaily
	FROM
		@tasks t
		-- 02/23/2011 dalvarado
--		LEFT OUTER JOIN @priorities p
--			ON t.[id] = p.TaskID
--	WHERE
--		p.[TaskID] IS NULL

	UNION ALL

	SELECT 
		DISTINCT
		t.ID, 
		t.description + 
		CASE WHEN t.CompletedDate IS NULL THEN
			CASE WHEN t.archived = 1 THEN
				' (DELETED)'
			ELSE
				''
			END
		ELSE
			''
		END as Description,
		Convert(varchar, t.DueTime, 101) as DueDate,
		Convert(varchar, t.ReminderDate, 101) as ReminderDate,
		Convert(varchar, ISNULL(t.ReminderDate, t.DueTime), 101) as SortDate,
		t.Priority,
		CAST(t.ID as varchar) As Comments,
		0 as UpdatedDate,
		'Comments' As Type,
		999 as NativeType,
		CASE WHEN t.CompletedDate IS NULL THEN
			CASE WHEN t.archived = 1 THEN
				1
			ELSE
				IsDeleted
			END
		ELSE
			IsDeleted
		END as IsDeleted,
		--0 as IsDeleted,
		CASE WHEN t.CompletedDate IS Not Null then t.tasktypeOrder * 1000 * 2 + 1000 Else t.tasktypeOrder * 1000 * 2 END + 100 + t.Priority As ReturnOrder,
		CASE WHEN t.CompletedDate IS Not Null then 'C' else '' END + CAST(tasktype as varchar) As TaskType,
		PriorityChanged,
		DueDateChanged,
		TaskNameChanged,
		NewTask,
		Assignees as AssignedTo,
		Controllers,
		null as isRecurring,
		null as IsDaily
	FROM
		@tasks t
		-- 02/23/2011 dalvarado
--		LEFT OUTER JOIN @priorities p
--			ON t.[id] = p.TaskID
--	WHERE
--		p.[TaskID] IS NULL

	UNION ALL
 
	-- SECTION HEADS SPECIAL (General Comments, etc)
	SELECT DISTINCT
		null as ID, 
		tt.Description,
		null as DueDate,
		null as ReminderDate,
		null as SortDate,
		null as Priority,
		null as Comments,
		null as UpdatedDate,
		'Sub Header Row' as Type,
		tt.NativeType ,
		null as IsDeleted,
		tt.DisplayOrder * 1000 * 2 As ReturnOrder,
		CAST(tt.ID As varchar) As TaskType,
		0 as PriorityChanged,
		0 as DueDateChanged,
		0 as TaskNameChanged,
		0 as NewTask,
		null as AssignedTo,
		null as Controllers,
		null as isRecurring,
		null as IsDaily
	FROM
		QStatus_SpecialTasks st
		INNER JOIN QStatus_TaskTypes	tt
			ON st.TaskType = tt.ID
			AND tt.IsDeleted = 0
			AND tt.ReportID = @ReportID
			AND st.IsDeleted = 0
	--END SECTION HEADS SPECIAL 

	UNION ALL

	-- SECTION ENDERS SPECIAL (General Comments, etc)
	SELECT DISTINCT
		null as ID, 
		tt.Description,
		null as DueDate,
		null as ReminderDate,
		null as SortDate,
		null as Priority,
		null as Comments,
		null as UpdatedDate,
		'EnderType' as Type,
		tt.NativeType ,
		null as IsDeleted,
		tt.DisplayOrder * 1000 * 2 + 999 As ReturnOrder,
		CAST(tt.ID AS varchar) AS TaskType,
		0 as PriorityChanged,
		0 as DueDateChanged,
		0 as TaskNameChanged,
		0 as NewTask,
		null as AssignedTo,
		null as Controllers,
		null as isRecurring, 
		null as IsDaily
	FROM
		QStatus_SpecialTasks st
		INNER JOIN QStatus_TaskTypes	tt
			ON st.TaskType = tt.ID
			AND tt.IsDeleted = 0
			AND tt.ReportID = @ReportID
			AND st.IsDeleted = 0
	--END SECTION ENDERS SPECIAL 
	
	UNION ALL

	-- SECTION SPECIAL (General Comments, etc)
	SELECT DISTINCT
		st.ID * -1 as ID, -- negative for special sections
		tt.Description,
		0 as DueDate,
		0 as ReminderDate,
		0 as SortDate,
		st.Priority as Priority,
		CAST((st.ID * -1) as varchar) As Comments,
		0 as UpdatedDate,
		tt.Description as Type,
		tt.NativeType ,
		0 as IsDeleted,
		tt.DisplayOrder * 1000 * 2 + 100 + st.Priority As ReturnOrder,
		CAST(tt.ID AS varchar) As TaskType,
		0 as PriorityChanged,
		0 as DueDateChanged,
		0 as TaskNameChanged,
		0 as NewTask,
		null as AssignedTo,
		null as Controllers,
		null as isRecurring,
		null as IsDaily
		--0 As ShowSupervisor
	FROM
		QStatus_SpecialTasks st
		INNER JOIN QStatus_TaskTypes	tt
			ON st.TaskType = tt.ID
			AND tt.IsDeleted = 0
			AND tt.ReportID = @ReportID
			AND st.IsDeleted = 0
	--END SECTION SPECIAL 
	
	ORDER BY 
		ReturnOrder,
		SortDate asc,
		ReminderDate asc, 
		DueDate asc, 
		description, 
		NativeType asc

	SELECT 
		IsConfidential 
	FROM
		QStatus_Report
	WHERE
		ID = @ReportID

	SELECT @Seed
END
GO

CREATE OR ALTER PROC [dbo].[QStatus_GetReportLatestComments]
	@UserID int,
	@ReportID int,
	@deletedDate datetime = null,
	@MoveCompleted bit = 0,
	@selectedComments varchar(1000) = null,
	@CommentsSince DATETIME = NULL,
	@IncludeAllTasks BIT = 0
/*
set @UserID = 50
set @ReportID = 1100996
set @deletedDate = null
set @MoveCompleted = 0
set @selectedComments = null
set @CommentsSince = '4/10/2016 10:00'
set @IncludeAllTasks = 1
*/
AS

BEGIN
	SET NOCOUNT ON
	
	IF @CommentsSince IS NULL SET @CommentsSince = DATEADD(HOUR, -1, GETDATE())
	If @CommentsSince > getdate() SET @CommentsSince = DATEADD(HOUR, -1, GETDATE()) --time zone issue

	DECLARE @CompletedType varchar(10)
	
	SELECT @CompletedType = 'Completed'
	
	--waitfor delay '00:00:10'

	--if only specific comments were requested, parse them out into a table
	DECLARE @selectedCommentsTbl TABLE (commentID int)

	IF @selectedComments IS NOT NULL
		INSERT INTO @selectedCommentsTbl
		SELECT n from dbo.Util_fn_List_To_Table(@selectedComments,',')

	--find all the tasks
	DECLARE @ForeignKeyIDs TABLE (
		ForeignKeyID INT PRIMARY KEY,
		SpecialTask int
	)

	IF @selectedComments IS NOT NULL
	BEGIN
		INSERT INTO @ForeignKeyIDs 
			SELECT distinct 
				actt.activechecklistid, 
				specialTask 
			FROM 
				QStatus_ActiveChecklistTaskType actt
				inner join qstatus_tasktypes tt
					on tt.id = actt.tasktype
					and tt.reportID = @reportID
				inner join qstatus_comments c
					on c.foreignkeyid = actt.activechecklistid
					and c.specialtask = 0
					and c.UserID = @UserID
					AND LEN(Comments)>0 
					AND CommentDT > @CommentsSince
				INNER JOIN @selectedCommentsTbl sc 
					ON c.id = sc.commentID

		INSERT INTO @ForeignKeyIDs
			SELECT distinct 
				st.ID, 1
			FROM 
				QStatus_SpecialTasks st
				inner join qstatus_tasktypes tt
					ON tt.ID = st.TaskType
					AND tt.ReportID = @ReportID
				inner join qstatus_comments c
					on c.foreignkeyid = st.ID
					AND LEN(Comments)>0 
					AND CommentDT > @CommentsSince
					and specialtask=1
					and c.UserID = @UserID
				INNER JOIN @selectedCommentsTbl sc 
					ON c.id = sc.commentID
	END
	ELSE
	BEGIN
		INSERT INTO @ForeignKeyIDs 
			SELECT distinct 
				actt.activechecklistid, 
				ISNULL(specialTask, 0)
			FROM 
				QStatus_ActiveChecklistTaskType actt
				INNER JOIN qstatus_tasktypes tt
					ON tt.id = actt.tasktype
					AND tt.reportID = @reportID
				LEFT OUTER JOIN qstatus_comments c
					ON c.foreignkeyid = actt.activechecklistid
					AND c.specialtask = 0
			WHERE
				(c.UserID = @UserID OR @IncludeAllTasks = 1)
				AND (LEN(Comments) > 0 OR @IncludeAllTasks = 1)
				AND ISNULL(CommentDT, '12/31/2199') > @CommentsSince
				AND (c.ID IS NOT NULL OR @IncludeAllTasks = 1) --Basically want an inner join if not showing all tasks

			UNION

			-- If we're showing all tasks, make sure every task on the status report is included. The query above will only pull
			-- tasks that have active comments within the date range or don't have comments from the user at all.
			SELECT distinct 
				actt.activechecklistid,
				0
			FROM 
				QStatus_ActiveChecklistTaskType actt
				INNER JOIN qstatus_tasktypes tt
					ON tt.id = actt.tasktype
					AND tt.reportID = @reportID
			WHERE
				@IncludeAllTasks = 1 

		INSERT INTO @ForeignKeyIDs
			SELECT distinct 
				st.ID, 
				1
			FROM 
				QStatus_SpecialTasks st
				INNER JOIN qstatus_tasktypes tt
					ON tt.ID = st.TaskType
					AND tt.ReportID = @ReportID
				LEFT OUTER JOIN qstatus_comments c
					ON c.foreignkeyid = st.ID
					AND specialtask=1
			WHERE
				(LEN(Comments) > 0 OR @IncludeAllTasks = 1)
				AND ISNULL(CommentDT, '12/31/2199') > @CommentsSince
				AND (c.UserID = @UserID OR @IncludeAllTasks = 1)
				AND (c.ID IS NOT NULL OR @IncludeAllTasks = 1) --Basically want an inner join if not showing all tasks

			UNION

			SELECT distinct 
				st.ID, 
				1
			FROM 
				QStatus_SpecialTasks st
				INNER JOIN qstatus_tasktypes tt
					ON tt.ID = st.TaskType
					AND tt.ReportID = @ReportID
			WHERE
				@IncludeAllTasks = 1

	END

	DECLARE @tasks table(
		ID int PRIMARY KEY,
		DueTime datetime,
		InstanceID int,
		assignees varchar(1000),
		tasktype int,
		taskdescription varchar(1000),
		nativetype int,
		tasktypeorder int,
		priority int,
		prioritychanged bit,
		duedatechanged bit,
		newtask bit,
		CompletedDate datetime,
		Archived bit,
		description varchar(1000),
		tasknamechanged bit
	)

		
	declare @instances table(
		ID int PRIMARY KEY,
		ChecklistID int
	)
	declare @checklists table(
		ID int PRIMARY KEY,
		Description varchar(1000),
		tasknamechanged bit
	)
	
	insert into @tasks (
		ID ,
		DueTime,
		InstanceID ,
		assignees ,
		tasktype ,
		taskdescription ,
		nativetype ,
		tasktypeorder ,
		priority ,
		prioritychanged ,
		duedatechanged ,
		newtask ,
		CompletedDate ,
		Archived 
	)
		SELECT distinct
			ac.ID, 
			ac.DueTime,
			ac.InstanceID,
			isnull(REPLACE(al.assignees, '&nbsp;', ' '), ''),
			--dbo.QCheck_FullAssigneesList(ac.instanceid),
			tt.ID,
			tt.Description,
			tt.NativeType,
			tt.DisplayOrder,
			actt.Priority,
			0 as PriorityChanged,
			0 as DueDateChanged,
			CASE WHEN actt.CreateDt > @deletedDate THEN 1 ELSE 0 END as NewTask,
			CompletedDate, 
			0
		FROM
			QStatus_ActiveChecklistTaskType actt
			INNER JOIN QStatus_TaskTypes	tt
				ON actt.TaskType = tt.ID
				AND tt.IsDeleted = 0
				AND tt.ReportID = @ReportID
			INNER JOIN QCheck_ActiveChecklists ac
				ON ac.ID = actt.ActiveChecklistID
			left outer join qcheck_assigneelookup al
				on al.instanceid = ac.instanceid
			inner join @ForeignKeyIDs f
				ON f.ForeignKeyID = ac.ID
				AND f.SpecialTask = 0	

	
	insert into @tasks (
		ID ,
		DueTime,
		InstanceID ,
		assignees ,
		tasktype ,
		taskdescription ,
		nativetype ,
		tasktypeorder ,
		priority ,
		prioritychanged ,
		duedatechanged ,
		newtask ,
		CompletedDate ,
		Archived 
	)
		SELECT distinct 
			ac.ID, 
			ac.DueTime,
			ac.InstanceID, 
			isnull(REPLACE(al.assignees, '&nbsp;', ' '), ''),
			--dbo.QCheck_FullAssigneesList(ac.instanceid),
			tt.ID,
			tt.Description,
			tt.NativeType,
			tt.DisplayOrder,
			actt.Priority,
			0 as PriorityChanged,
			0 as DueDateChanged,
			CASE WHEN actt.CreateDt > @deletedDate THEN 1 ELSE 0 END as NewTask,
			CompletedDate, 
			1
		FROM
			QStatus_ActiveChecklistTaskType actt
			INNER JOIN QStatus_TaskTypes	tt
				ON actt.TaskType = tt.ID
				AND tt.ReportID = @ReportID
				AND tt.IsDeleted = 0
			INNER JOIN QCheck_ActiveChecklistArchive ac
				ON ac.ID = actt.ActiveChecklistID
				--AND ac.archivedate > @deleteddate 
				--AND @deleteddate is not null
			left outer join qcheck_assigneelookup al
				on al.instanceid = ac.instanceid
			inner join @ForeignKeyIDs f
				ON f.ForeignKeyID = ac.ID
				AND f.SpecialTask = 0	

	
	update @tasks
	set DueDateChanged = 1
	from 
		@tasks t
		inner join QStatus_DueDateChanges ddc
			on ddc.ActiveChecklistID =t.ID
			AND ddc.UpdateDt > @deletedDate

	
	update @tasks
	set PriorityChanged = 1
	from 
		@tasks t
		inner join QStatus_PriorityChanges pc
			on pc.ActiveChecklistID =t.ID
			AND pc.UpdateDt > @deletedDate
	
	insert into @instances
		SELECT distinct
			ci.ID,
			ci.ChecklistID
		FROM 
			QCheck_ChecklistInstances ci
			INNER JOIN @tasks t
			ON t.InstanceID = ci.ID
		WHERE
			ci.IsDeleted = 0 
			OR @deleteddate is not null

		UNION ALL

		SELECT distinct
			ci.ID,
			ci.ChecklistID
		FROM 
			QCheck_ChecklistInstanceArchive ci
			INNER JOIN @tasks t
			ON t.InstanceID = ci.ID
		WHERE
			(ci.IsDeleted = 0 OR @deleteddate is not null)
			AND ci.archivedate > @deleteddate 
			AND @deleteddate is not null
	
	insert into @checklists
		SELECT DISTINCT
			c.ID,
			c.Name,
			CASE WHEN tnc.ChecklistID IS NULL THEN 0 ELSE 1 END as TaskNameChanged
		FROM 
			QCheck_Checklists c
			INNER JOIN @instances ci
				ON c.ID = ci.ChecklistID
			LEFT OUTER JOIN QStatus_TaskNameChanges tnc
				ON tnc.ChecklistID = c.ID
				AND tnc.UpdateDt > @deletedDate
		WHERE
			c.IsDeleted = 0 
			OR @deleteddate is not null

		UNION ALL

		SELECT DISTINCT
			c.ID,
			c.Name,
			CASE WHEN tnc.ChecklistID IS NULL THEN 0 ELSE 1 END as TaskNameChanged
		FROM 
			QCheck_ChecklistArchive c
			INNER JOIN @instances ci
				ON c.ID = ci.ChecklistID
			LEFT OUTER JOIN QStatus_TaskNameChanges tnc
				ON tnc.ChecklistID = c.ID
				AND tnc.UpdateDt > @deletedDate
		WHERE
			(c.IsDeleted = 0 OR	@deleteddate is not null)
			AND c.archivedate > @deleteddate 
			AND @deleteddate is not null

	DELETE FROM @instances where checklistid not in (select id from @checklists)
	DELETE FROM @tasks where instanceid not in (select id from @instances)

	update @tasks
	set 
		description = c.description,
		tasknamechanged = c.tasknamechanged
	from 
		@tasks t
		inner join @instances i
			on i.id = t.instanceid
		inner join @checklists c
			on c.id = i.checklistid

	DECLARE @specialtasks table(
		ID int,
		priority int,
		tasktypeid int,
		tasktypedescription varchar(1000), 
		tasktypenativetype int,
		tasktypedisplayorder int
	)

	insert into @specialtasks
		select st.ID,
			st.priority,
			tt.id,
			tt.description,
			tt.nativetype,
			tt.displayorder
		from 
			QStatus_SpecialTasks st
			INNER JOIN QStatus_TaskTypes	tt
				ON st.TaskType = tt.ID
				AND tt.IsDeleted = 0
				AND st.IsDeleted = 0
				AND tt.ReportID = @ReportID
			INNER JOIN @ForeignKeyIDs f
				ON f.ForeignKeyID = st.ID
				AND f.SpecialTask = 1

	DECLARE @recordIds AS RecordId
	INSERT INTO @recordIds
		SELECT DISTINCT ID FROM @checklists

	EXEC dbo.Audit_Set @userId, @recordIds, 'Checklist', 2

	--START HEADER
	SELECT
		null as ID, 
		dbo.QStatus_GetUserNames(r.ID) + r.Name + ' - Status Report - '
		+ CASE WHEN r.LastReportDate = 0 THEN
			'No Status'
		ELSE
			ISNULL(datename(dw, r.LastReportDate) + ' ', '') 
			+ ISNULL(CONVERT(varchar, r.LastReportDate, 101) + ' ', '') 
			+ ltrim(isnull(right(convert(varchar, r.LastReportDate, 100), 7), ''))
		END 
		as Description,
		null as DueDate,
		null as Priority,
		null as Comments,
		null as UpdatedDate,
		'Header Row' as Type,
		-1 As NativeType,
		null as IsDeleted,
		1 As ReturnOrder,
		'0' as TaskType,
		0 as PriorityChanged,
		0 as DueDateChanged,
		0 as TaskNameChanged,
		0 as NewTask,
		null as AssignedTo
	FROM
		QStatus_Report r
	WHERE
		r.ID = @ReportID
	--END OF HEADER

	
	UNION ALL

	SELECT DISTINCT
		null as ID, 
		null as Description,
		null as DueDate,
		null as Priority,
		null as Comments,
		null as UpdatedDate,
		'EnderType' as Type,
		-1,
		null as IsDeleted,
		2 As ReturnOrder, 
		'0' As TaskType,
		0 as PriorityChanged,
		0 as DueDateChanged,
		0 as TaskNameChanged,
		0 as NewTask,
		null as AssignedTo

	UNION ALL

	-- SECTION HEADS
	SELECT DISTINCT
		CASE WHEN t.CompletedDate IS Not Null then Null ELSE t.TaskType END AS ID, 
		CASE WHEN t.CompletedDate IS Not Null then @CompletedType +' - '+ taskdescription ELSE taskdescription END AS Description,
		null as DueDate,
		null as Priority,
		null as Comments,
		null as UpdatedDate,
		'Sub Header Row' as Type,
		CASE WHEN t.CompletedDate IS Not Null then 2 else t.NativeType end as NativeType,
		null as IsDeleted,
		CASE WHEN t.CompletedDate IS Not Null then t.tasktypeorder * 1000 * 2 + 1000 Else t.tasktypeorder * 1000 * 2 END As ReturnOrder,
		CASE WHEN t.CompletedDate IS Not Null then 'C' else '' END + CAST(t.tasktype as varchar) As TaskType,
		0 as PriorityChanged,
		0 as DueDateChanged,
		0 as TaskNameChanged,
		0 as NewTask,
		null as AssignedTo
	FROM
		@tasks t
		
	UNION ALL

	--START SECTION HEADINGS
	SELECT DISTINCT
		null as ID, 
		null as Description,
		null as DueDate,
		null as Priority,
		null as Comments,
		null as UpdatedDate,
		'Headings Row' as Type,
		CASE WHEN t.CompletedDate IS Not Null then 2 else t.NativeType end as NativeType,
		null as IsDeleted,
		CASE WHEN t.CompletedDate IS Not Null then t.tasktypeorder * 1000 * 2 + 1000 Else t.tasktypeorder * 1000 * 2 END + 1 As ReturnOrder,
		CASE WHEN t.CompletedDate IS Not Null then 'C' else '' END + CAST(t.tasktype as varchar) As TaskType,
		0 as PriorityChanged,
		0 as DueDateChanged,
		0 as TaskNameChanged,
		0 as NewTask,
		null as AssignedTo
	FROM
		@tasks t

	UNION ALL

	--START SECTION ENDERS
	SELECT DISTINCT
		null as ID, 
		CASE WHEN t.CompletedDate IS Not Null then @CompletedType else t.taskdescription end as Description,
		null as DueDate,
		null as Priority,
		null as Comments,
		null as UpdatedDate,
		'EnderType' as Type,
		CASE WHEN t.CompletedDate IS Not Null then 2 else t.NativeType end as NativeType,
		null as IsDeleted,
		CASE WHEN t.CompletedDate IS Not Null then t.tasktypeOrder * 1000 * 2 + 1000 Else t.tasktypeOrder * 1000 * 2 END + 999 As ReturnOrder,
		CASE WHEN t.CompletedDate IS Not Null then 'C' else '' END + CAST(tasktype as varchar) As TaskType,
		0 as PriorityChanged,
		0 as DueDateChanged,
		0 as TaskNameChanged,
		0 as NewTask,
		null as AssignedTo
	FROM
		@tasks t

	--END SECTION ENDERS

	UNION ALL
	
	--START SECTION
	SELECT 
		DISTINCT
		t.ID, 
		t.description + 
		CASE WHEN t.archived = 1 THEN
			--' (DELETED)'
			''
		ELSE
			''
		END
		 as Description,
		Convert(varchar, t.DueTime, 101) as DueDate,
		t.Priority,
		CAST(t.ID as varchar) As Comments,
		0 as UpdatedDate,
		CASE WHEN t.CompletedDate IS Not Null then @CompletedType else t.taskDescription end As Type,
		CASE WHEN t.CompletedDate IS Not Null then 2 else t.NativeType end as NativeType,
		0 as IsDeleted,
		CASE WHEN t.CompletedDate IS Not Null then t.tasktypeOrder * 1000 * 2 + 1000 Else t.tasktypeOrder * 1000 * 2 END + 100 + t.Priority As ReturnOrder,
		CASE WHEN t.CompletedDate IS Not Null then 'C' else '' END + CAST(tasktype as varchar) As TaskType,
		PriorityChanged,
		DueDateChanged,
		TaskNameChanged,
		NewTask,
		Assignees as AssignedTo
	FROM
		@tasks t
		
	UNION ALL
/*	
	-- COMMENTS
	SELECT 
		DISTINCT
		t.ID, 
		t.description + 
		CASE WHEN t.CompletedDate IS NULL THEN
			CASE WHEN t.archived = 1 THEN
				' (DELETED)'
			ELSE
				''
			END
		ELSE
			''
		END as Description,
		Convert(varchar, t.DueTime, 101) as DueDate,
		t.Priority,
		CAST(t.ID as varchar) As Comments,
		0 as UpdatedDate,
		'Comments' As Type,
		999 as NativeType,
		0 as IsDeleted,
		CASE WHEN t.CompletedDate IS Not Null then t.tasktypeOrder * 1000 * 2 + 1000 Else t.tasktypeOrder * 1000 * 2 END + 100 + t.Priority As ReturnOrder,
		CASE WHEN t.CompletedDate IS Not Null then 'C' else '' END + CAST(tasktype as varchar) As TaskType,
		PriorityChanged,
		DueDateChanged,
		TaskNameChanged,
		NewTask,
		Assignees as AssignedTo
	FROM
		@tasks t

	UNION ALL
*/ 
	-- SECTION HEADS SPECIAL (General Comments, etc)
	SELECT DISTINCT
		null as ID, 
		tasktypedescription as Description,
		null as DueDate,
		null as Priority,
		null as Comments,
		null as UpdatedDate,
		'Sub Header Row' as Type,
		tasktypenativetype as NativeType ,
		null as IsDeleted,
		tasktypedisplayorder * 1000 * 2 As ReturnOrder,
		CAST(tasktypeid As varchar) As TaskType,
		0 as PriorityChanged,
		0 as DueDateChanged,
		0 as TaskNameChanged,
		0 as NewTask,
		null as AssignedTo
	FROM
		@specialtasks st
	--END SECTION HEADS SPECIAL 
	
	UNION ALL
	
	-- COLUMN HEADS SPECIAL (General Comments, etc)
	SELECT DISTINCT
		null as ID, 
		tasktypedescription as Description,
		null as DueDate,
		null as Priority,
		null as Comments,
		null as UpdatedDate,
		'Special Headings Row' as Type,
		tasktypenativetype as NativeType ,
		null as IsDeleted,
		tasktypedisplayorder * 1000 * 2 + 1 As ReturnOrder,
		CAST(tasktypeid As varchar) As TaskType,
		0 as PriorityChanged,
		0 as DueDateChanged,
		0 as TaskNameChanged,
		0 as NewTask,
		null as AssignedTo
	FROM
		@specialtasks st
	--END SECTION HEADS SPECIAL 

	UNION ALL

	-- SECTION ENDERS SPECIAL (General Comments, etc)
	SELECT DISTINCT
		null as ID, 
		tasktypedescription as Description,
		null as DueDate,
		null as Priority,
		null as Comments,
		null as UpdatedDate,
		'EnderType' as Type,
		tasktypenativetype as NativeType ,
		null as IsDeleted,
		tasktypedisplayorder * 1000 * 2 + 999 As ReturnOrder,
		CAST(tasktypeid AS varchar) AS TaskType,
		0 as PriorityChanged,
		0 as DueDateChanged,
		0 as TaskNameChanged,
		0 as NewTask,
		null as AssignedTo
	FROM
		@specialtasks st
	--END SECTION ENDERS SPECIAL 
	
	
	
	UNION ALL

	-- SECTION SPECIAL (General Comments, etc)
	SELECT DISTINCT
		st.ID * -1 as ID, -- negative for special sections
		st.tasktypedescription as description,
		null as DueDate,
		st.Priority as Priority,
		CAST((st.ID * -1) as varchar) As Comments,
		0 as UpdatedDate,
		st.tasktypedescription as Type,
		st.tasktypenativetype as NativeType ,
		0 as IsDeleted,
		st.tasktypedisplayorder * 1000 * 2 + 100 + st.Priority As ReturnOrder,
		CAST(st.tasktypeid AS varchar) As TaskType,
		0 as PriorityChanged,
		0 as DueDateChanged,
		0 as TaskNameChanged,
		0 as NewTask,
		null as AssignedTo
	FROM
		@specialtasks st
	--END SECTION SPECIAL 
	

	ORDER BY 
		ReturnOrder,
		DueDate asc, 
		description, 
		NativeType asc

	SELECT 
		IsConfidential 
	FROM
		QStatus_Report
	WHERE
		ID = @ReportID

	SET NOCOUNT OFF
END
GO

CREATE OR ALTER PROC [dbo].[QStatus_GetReportList]
	@UserID int,
	@IncludeDefault bit = 1
AS
BEGIN
	SET NOCOUNT ON

		SELECT 
			DISTINCT r.[ID],
				r.name,
		 	replace(replace(r.Name, '&', '&amp;'),'"', '&quot;') 
			+ case when @IncludeDefault = 0 then '' else 	isnull(
				' (' + 
				
				case (datediff(day, convert(datetime, convert(varchar, commentdt, 101)), convert(datetime, convert(varchar, getdate(), 101))))
				when 0 then 'today'
				when 1 Then '1 day ago'
				else
					convert(varchar, datediff(day, convert(datetime, convert(varchar, commentdt, 101)), convert(datetime, convert(varchar, getdate(), 101)))) + ' days ago'
				end
				+ ')'
				, '') end
			AS [Description]
		INTO #result
		FROM 
			QStatus_Report r
		INNER JOIN
			QStatus_GroupReport gr
		ON
			gr.ReportID = r.ID
		INNER JOIN
			QCheck_Groups g
		ON
			g.ID = gr.GroupID
		INNER JOIN
			QCheck_GroupMembership gm
		ON
			gm.GroupID = g.ID
		AND
			gm.UserID = @UserID
		LEFT OUTER JOIN QStatus_ReportLastestComments lastcomment
			on lastcomment.reportID = r.ID
			and lastcomment.userID = @UserID
		WHERE
			r.IsDeleted = 0

		DECLARE @recordIds AS RecordId
		INSERT INTO @recordIds
			SELECT DISTINCT ID FROM #result

		EXEC dbo.Audit_Set @userId, @recordIds, 'Report', 2
		
		SELECT * FROM #result 
		ORDER BY [Name]
END
GO

CREATE OR ALTER PROC [dbo].[QStatus_GetReportList_Supervised]
	@UserID int,
	@InterestedParty bit = 0,
	@NamesOnly bit = 0
AS
BEGIN
	SET NOCOUNT ON

		SELECT 
			DISTINCT r.[ID],
				r.name,
		 	replace(replace(r.Name, '&', '&amp;'),'"', '&quot;') 
			+	CASE WHEN @NamesOnly = 0 THEN isnull(
				' (' + 
				
				case (datediff(day, convert(datetime, convert(varchar, commentdt, 101)), convert(datetime, convert(varchar, getdate(), 101))))
				when 0 then 'today'
				when 1 Then '1 day ago'
				else
					convert(varchar, datediff(day, convert(datetime, convert(varchar, commentdt, 101)), convert(datetime, convert(varchar, getdate(), 101)))) + ' days ago'
				end
				+ ')'
				, '') ELSE '' END as [description],
				g.Name as GroupName,
				gr.ID as QStatusSupervisorID
		INTO #result
		FROM 
			QStatus_Report r
			INNER JOIN QStatus_Supervisors gr
				ON gr.ReportID = r.ID
				AND gr.InterestedParty = @InterestedParty
			INNER JOIN QCheck_Groups g
				ON g.ID = gr.SupervisorGroupID
			INNER JOIN QCheck_GroupMembership gm
				ON gm.GroupID = g.ID
				AND gm.UserID = @UserID
			LEFT OUTER JOIN QStatus_ReportLastestComments lastcomment
				ON lastcomment.reportID = r.ID
				AND lastcomment.userID = @UserID
		WHERE 
			r.IsDeleted = 0
		
		DECLARE @recordIds AS RecordId
		INSERT INTO @recordIds
			SELECT DISTINCT ID FROM #result

		EXEC dbo.Audit_Set @userId, @recordIds, 'Report', 2
		
		SELECT * FROM #result ORDER BY [Name]
END
GO

CREATE OR ALTER PROC [dbo].[QStatus_GetReportName]
	@ReportID int,
	@UserId int,
	@ReportName varchar(100) output
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @recordIds AS RecordId
	INSERT INTO @recordIds VALUES(@ReportID)

	EXEC dbo.Audit_Set @userId, @recordIds, 'Report', 2
	
	SELECT @ReportName = dbo.QStatus_GetUserNames(r.ID) + r.Name
	FROM
		QStatus_Report r
	WHERE r.ID = @ReportID
END
GO

CREATE OR ALTER PROC [dbo].[QStatus_GetReportTaskListByUser]
	@UserID int
AS
BEGIN
	SET NOCOUNT ON
	
	--START HEADER
	SELECT distinct
		null as ID, 
			dbo.QStatus_GetUserNames(r.ID) + r.Name + ' - Status Report - '
			+ CASE WHEN r.LastReportDate = 0 THEN
				'No Status'
			ELSE
				ISNULL(datename(dw, r.LastReportDate) + ' ', '') 
				+ ISNULL(CONVERT(varchar, r.LastReportDate, 101) + ' ', '') 
				+ ltrim(isnull(right(convert(varchar, r.LastReportDate, 100), 7), ''))
			END 
		as Description,
		null as DueDate,
		null as Priority,
		null as Comments,
		null as UpdatedDate,
		'Header Row' as Type,
		-1 As NativeType,
		null as IsDeleted,
		1 As ReturnOrder,
		r.ID as ReportID,
		null As InstanceID,
		null As Assignees,
		null As Managers,
		null As Frequency,
		null As [Last Completed],
		null As nextduedate,
		null As UpcomingID,
		null As HistoryType,
		null As HistoryID
	INTO #result
	FROM
		QStatus_Report r
	INNER JOIN
		QStatus_GroupReport gr
	ON
		gr.ReportID = r.ID
	INNER JOIN
		QCheck_Groups g
	ON
		g.ID = gr.GroupID
	INNER JOIN
		QCheck_GroupMembership gm
	ON
		gm.GroupID = g.ID
	AND
		gm.UserID = @UserID
	AND
		r.IsDeleted = 0
	
	--END OF HEADER

	UNION ALL

	SELECT DISTINCT
		null as ID, 
		null as Description,
		null as DueDate,
		null as Priority,
		null as Comments,
		null as UpdatedDate,
		'EnderType' as Type,
		-1,
		null as IsDeleted,
		2 As ReturnOrder,
		r.ID as ReportID,
		null As InstanceID,
		null As Assignees,
		null As Managers,
		null As Frequency,
		null As [Last Completed],
		null As nextduedate,
		null As UpcomingID,
		null As HistoryType,
		null As HistoryID
	FROM
		QStatus_Report r
	INNER JOIN
		QStatus_GroupReport gr
	ON
		gr.ReportID = r.ID
	INNER JOIN
		QCheck_Groups g
	ON
		g.ID = gr.GroupID
	INNER JOIN
		QCheck_GroupMembership gm
	ON
		gm.GroupID = g.ID
	AND
		gm.UserID = @UserID
	AND
		r.IsDeleted = 0

	UNION ALL

	SELECT DISTINCT
		null as ID, 
		null as Description,
		null as DueDate,
		null as Priority,
		null as Comments,
		null as UpdatedDate,
		'SpacerType' as Type,
		-1,
		null as IsDeleted,
		999999 As ReturnOrder,
		r.ID as ReportID,
		null As InstanceID,
		null As Assignees,
		null As Managers,
		null As Frequency,
		null As [Last Completed],
		null As nextduedate,
		null As UpcomingID,
		null As HistoryType,
		null As HistoryID
	FROM
		QStatus_Report r
	INNER JOIN
		QStatus_GroupReport gr
	ON
		gr.ReportID = r.ID
	INNER JOIN
		QCheck_Groups g
	ON
		g.ID = gr.GroupID
	INNER JOIN
		QCheck_GroupMembership gm
	ON
		gm.GroupID = g.ID
	AND
		gm.UserID = @UserID
	AND
		r.IsDeleted = 0

	UNION ALL

	-- SECTION HEADS
	SELECT DISTINCT
		CASE WHEN AC.CompletedDate IS Not Null then Null ELSE tt.ID END AS ID, 
		CASE WHEN AC.CompletedDate IS Not Null then 'Completed - '+ tt.Description ELSE tt.Description END AS Description,
		null as DueDate,
		null as Priority,
		null as Comments,
		null as UpdatedDate,
		'Sub Header Row' as Type,
		CASE WHEN AC.CompletedDate IS Not Null then 2 else tt.NativeType end as NativeType,
		null as IsDeleted,
		CASE WHEN AC.CompletedDate IS Not Null then tt.DisplayOrder * 1000 * 2 + 1000 Else tt.DisplayOrder * 1000 * 2 END As ReturnOrder,
		r.ID as ReportID,
		null As InstanceID,
		null As Assignees,
		null As Managers,
		null As Frequency,
		null As [Last Completed],
		null As nextduedate,
		null As UpcomingID,
		null As HistoryType,
		null As HistoryID
		--0 As ShowSupervisor
	FROM
		QStatus_ActiveChecklistTaskType actt
	INNER JOIN
		QCheck_ActiveChecklists ac
	ON
		ac.ID = actt.ActiveChecklistID
	INNER JOIN
		QCheck_ChecklistInstances ci
	ON
		ci.ID = ac.InstanceID
	AND
		(ci.IsDeleted = 0)
	INNER JOIN
		QCheck_Checklists c
	ON	
		c.ID = ci.ChecklistID
	AND 
		(c.IsDeleted = 0)
	INNER JOIN
		QStatus_TaskTypes	tt
	ON
		actt.TaskType = tt.ID
	AND
		tt.IsDeleted = 0

	INNER JOIN
		QStatus_GroupReport gr
	ON
		gr.ReportID = tt.ReportID
	INNER JOIN
		QCheck_Groups grg
	ON
		grg.ID = gr.GroupID
	INNER JOIN
		QCheck_GroupMembership grgm
	ON
		grgm.GroupID = grg.ID
	AND
		grgm.UserID = @UserID
	INNER JOIN
		QStatus_Report r
	ON
		gr.ReportID = r.ID
	AND
		r.IsDeleted = 0
	INNER JOIN
		QCheck_Assignments a
	ON
		a.InstanceID = ci.ID
	INNER JOIN
		QCheck_GroupMembership gm
	ON
		gm.GroupID = a.GroupID
	AND
		gm.UserID = @UserID
	INNER JOIN 
		QCheck_Groups g
	ON
		g.ID = gm.GroupID
	
	--END SECTION HEADS

	UNION ALL

	-- SECTION HEADS Not Shown
	SELECT DISTINCT
		tt.ID, 
		tt.Description,
		--'blah' as Description,
		null as DueDate,
		null as Priority,
		null as Comments,
		null as UpdatedDate,
		'Sub Header Row' as Type,
		tt.NativeType as NativeType,
		null as IsDeleted,
		tt.DisplayOrder * 1000 * 2 As ReturnOrder,
		r.ID as ReportID,
		null As InstanceID,
		null As Assignees,
		null As Managers,
		null As Frequency,
		null As [Last Completed],
		null As nextduedate,
		null As UpcomingID,
		null As HistoryType,
		null As HistoryID
	FROM
		QStatus_TaskTypes tt
	INNER JOIN
		QStatus_GroupReport gr
	ON
		gr.ReportID = tt.ReportID
	INNER JOIN
		QCheck_Groups g
	ON
		g.ID = gr.GroupID
	INNER JOIN
		QCheck_GroupMembership gm
	ON
		gm.GroupID = g.ID
	AND
		gm.UserID = @UserID
	AND
		tt.NativeType = 0
	AND
		tt.IsDeleted = 0
	INNER JOIN
		QStatus_Report r
	ON
		gr.ReportID = r.ID
	AND
		r.IsDeleted = 0
	WHERE
		tt.ID NOT IN
	(
		SELECT tt.ID
		FROM
			QStatus_ActiveChecklistTaskType actt
		INNER JOIN
			QCheck_ActiveChecklists ac
		ON
			ac.ID = actt.ActiveChecklistID
		INNER JOIN
			QCheck_ChecklistInstances ci
		ON
			ci.ID = ac.InstanceID
		AND
			(ci.IsDeleted = 0)
		INNER JOIN
			QCheck_Checklists c
		ON	
			c.ID = ci.ChecklistID
		AND 
			(c.IsDeleted = 0)
		INNER JOIN
			QStatus_TaskTypes	tt
		ON
			actt.TaskType = tt.ID
		AND
			tt.IsDeleted = 0

		INNER JOIN
			QStatus_GroupReport rgr
		ON
			rgr.ReportID = tt.ReportID
		INNER JOIN
			QCheck_Groups rg
		ON
			rg.ID = rgr.GroupID
		INNER JOIN
			QCheck_GroupMembership rgm
		ON
			rgm.GroupID = rg.ID
		AND
			rgm.UserID = @UserID

		INNER JOIN
			QCheck_Assignments a
		ON
			a.InstanceID = ci.ID
		AND
			ac.CompletedDate is null
		INNER JOIN
			QCheck_GroupMembership gm
		ON
			gm.GroupID = a.GroupID
		AND
			gm.UserID = @UserID
		INNER JOIN
			QCheck_Groups g
		ON
			g.ID = gm.GroupID
		
	)
	--END SECTION HEADS Not Shown

	
	UNION ALL

	--START SECTION HEADINGS
	SELECT DISTINCT
		tt.ID as ID, 
		null as Description,
		null as DueDate,
		null as Priority,
		null as Comments,
		null as UpdatedDate,
		'Headings Row' as Type,
		CASE WHEN AC.CompletedDate IS Not Null then 2 else tt.NativeType end as NativeType,
		null as IsDeleted,
		CASE WHEN AC.CompletedDate IS Not Null then tt.DisplayOrder * 1000 * 2 + 1000 Else tt.DisplayOrder * 1000 * 2 END + 1 As ReturnOrder--,
		,
		r.ID as ReportID,
		null As InstanceID,
		null As Assignees,
		null As Managers,
		null As Frequency,
		null As [Last Completed],
		null As nextduedate,
		null As UpcomingID,
		null As HistoryType,
		null As HistoryID
	FROM
		QStatus_ActiveChecklistTaskType actt
	INNER JOIN
		QCheck_ActiveChecklists ac
	ON
		ac.ID = actt.ActiveChecklistID
	INNER JOIN
		QCheck_ChecklistInstances ci
	ON
		ci.ID = ac.InstanceID
	AND
		(ci.IsDeleted = 0 )
	INNER JOIN
		QCheck_Checklists c
	ON	
		c.ID = ci.ChecklistID
	AND 
		(c.IsDeleted = 0)
	INNER JOIN
		QStatus_TaskTypes	tt
	ON
		actt.TaskType = tt.ID
	AND
		tt.IsDeleted = 0

	INNER JOIN
		QStatus_GroupReport rgr
	ON
		rgr.ReportID = tt.ReportID
	INNER JOIN
		QCheck_Groups rg
	ON
		rg.ID = rgr.GroupID
	INNER JOIN
		QCheck_GroupMembership rgm
	ON
		rgm.GroupID = rg.ID
	AND
		rgm.UserID = @UserID

	INNER JOIN
		QStatus_Report r
	ON
		rgr.ReportID = r.ID
	AND
		r.IsDeleted = 0
	INNER JOIN
		QCheck_Assignments a
	ON
		a.InstanceID = ci.ID
	INNER JOIN
		QCheck_GroupMembership gm
	ON
		gm.GroupID = a.GroupID
	AND
		gm.UserID = @UserID
	INNER JOIN
		QCheck_Groups g
	ON
		g.ID = gm.GroupID
	--END SECTION HEADINGS

	
	UNION ALL

	--START SECTION ENDERS
	SELECT DISTINCT
		null as ID, 
		CASE WHEN AC.CompletedDate IS Not Null then 'Completed' else tt.Description end as Description,
		null as DueDate,
		null as Priority,
		null as Comments,
		null as UpdatedDate,
		'EnderType' as Type,
		CASE WHEN AC.CompletedDate IS Not Null then 2 else tt.NativeType end as NativeType,
		null as IsDeleted,
		CASE WHEN AC.CompletedDate IS Not Null then tt.DisplayOrder * 1000 * 2 + 1000 Else tt.DisplayOrder * 1000 * 2 END + 999 As ReturnOrder--,
		,
		r.ID as ReportID,
		null As InstanceID,
		null As Assignees,
		null As Managers,
		null As Frequency,
		null As [Last Completed],
		null As nextduedate,
		null As UpcomingID,
		null As HistoryType,
		null As HistoryID
	FROM
		QStatus_ActiveChecklistTaskType actt
	INNER JOIN
		QCheck_ActiveChecklists ac
	ON
		ac.ID = actt.ActiveChecklistID
	INNER JOIN
		QCheck_ChecklistInstances ci
	ON
		ci.ID = ac.InstanceID
	AND
		(ci.IsDeleted = 0)
	INNER JOIN
		QCheck_Checklists c
	ON	
		c.ID = ci.ChecklistID
	AND 
		(c.IsDeleted = 0)
	INNER JOIN
		QStatus_TaskTypes	tt
	ON
		actt.TaskType = tt.ID
	AND
		tt.IsDeleted = 0

	
	INNER JOIN
		QStatus_GroupReport rgr
	ON
		rgr.ReportID = tt.ReportID
	INNER JOIN
		QCheck_Groups rg
	ON
		rg.ID = rgr.GroupID
	INNER JOIN
		QCheck_GroupMembership rgm
	ON
		rgm.GroupID = rg.ID
	AND
		rgm.UserID = @UserID

	INNER JOIN
		QStatus_Report r
	ON
		rgr.ReportID = r.ID
	AND
		r.IsDeleted = 0
	INNER JOIN
		QCheck_Assignments a
	ON
		a.InstanceID = ci.ID
	
	INNER JOIN
		QCheck_GroupMembership gm
	ON
		gm.GroupID = a.GroupID
	AND
		gm.UserID = @UserID
	INNER JOIN
		QCheck_Groups g
	ON
		g.ID = gm.GroupID
	
	UNION ALL
	
	--START SECTION
	SELECT DISTINCT
		ac.ID, 
		 c.Name as Description,
		--Convert(varchar, ac.DueTime, 101) as DueDate,
		ac.DueTime as DueDate,
		actt.Priority,
		CAST(itt.ID as varchar) As Comments,
		--Convert(varchar, UpdatedDate, 101) 
		0 as UpdatedDate,
		CAST(tt.ID as varchar) As Type,
		CASE WHEN AC.CompletedDate IS Not Null then 2 else tt.NativeType end as NativeType,
		0 as IsDeleted,
		CASE WHEN AC.CompletedDate IS Not Null then tt.DisplayOrder * 1000 * 2 + 1000 Else tt.DisplayOrder * 1000 * 2 END + 100 + actt.Priority As ReturnOrder--,
		,
		r.ID as ReportID,
		ci.ID As InstanceID,
		dbo.QCheck_AssigneesList(isNull(ci.ID,0)) as Assignees,
		dbo.QCheck_ManagersList(isNull(c.ID,0)) as Managers,
		CASE 
			WHEN s.FreqType = 1 THEN
				'ONE TIME'
			WHEN s.FreqType = 2 THEN
				'DAILY'
			WHEN s.FreqType = 3 THEN
				'WEEKLY'
			WHEN s.FreqType = 4 THEN
				CASE WHEN s.FreqRecurrance = 4 THEN
					'QUARTERLY'
				ELSE
					'MONTHLY'
				END
			WHEN s.FreqType = 5 THEN
				'YEARLY'
		END As Frequency,
		isNull(ac.CompletedDate, aca.CompletedDate) as 'Last Completed',
		udt.duetime
		As nextduedate,
		udt.ID as upcomingID,
		CASE WHEN ac.CompletedDate IS NULL THEN
			2
		ELSE
			1
		END AS HistoryType,
		CASE WHEN ac.CompletedDate is null then
			aca.ID 
		ELSE
			ac.ID
		END As HistoryID
		--actt.ShowSupervisor
	FROM
		QStatus_ActiveChecklistTaskType actt
	INNER JOIN
		QCheck_ActiveChecklists ac
	ON
		ac.ID = actt.ActiveChecklistID
	INNER JOIN
		QCheck_ChecklistInstances ci
	ON
		ci.ID = ac.InstanceID
	AND
		(ci.IsDeleted = 0)
	INNER JOIN
		QCheck_Schedule s
	ON
		s.ID = ci.ScheduleID
	LEFT OUTER JOIN
		(SELECT a1.ID, a1.InstanceID, a1.completedDate
		FROM
			QCheck_ActiveChecklistArchive a1
		INNER JOIN
			(SELECT 
				InstanceID, MAX(completeddate) as completedDate
			FROM
				QCheck_ActiveChecklistArchive a
			GROUP BY
				 InstanceID
			) a2
		ON a1.InstanceID = a2.InstanceID and a1.completeddate = a2.completeddate
		) aca
	ON
		aca.InstanceID = ci.ID
	LEFT OUTER JOIN
		QCheck_UpcomingDueTimes udt
	ON
		udt.InstanceID = ci.ID
	AND
		udt.duetime <> ac.duetime
	LEFT OUTER JOIN
		QCheck_UpcomingDueTimes udt2
	ON
		udt2.InstanceID = ci.ID
	AND
		udt2.duetime < udt.duetime
	
	-- AND
		--udt.StartTime = ci.NextStartTime
	INNER JOIN
		QCheck_Checklists c
	ON	
		c.ID = ci.ChecklistID
	AND 
		(c.IsDeleted = 0)
	INNER JOIN
		QStatus_TaskTypes	tt
	ON
		actt.TaskType = tt.ID
	AND
		tt.IsDeleted = 0
	INNER JOIN
		QStatus_InstanceTaskType itt
	ON
		itt.InstanceID = ci.ID
	AND
		itt.TaskType = tt.ID

	
	INNER JOIN
		QStatus_GroupReport rgr
	ON
		rgr.ReportID = tt.ReportID
	INNER JOIN
		QCheck_Groups rg
	ON
		rg.ID = rgr.GroupID
	INNER JOIN
		QCheck_GroupMembership rgm
	ON
		rgm.GroupID = rg.ID
	AND
		rgm.UserID = @UserID

	INNER JOIN
		QStatus_Report r
	ON
		rgr.ReportID = r.ID
	AND
		r.IsDeleted = 0
	INNER JOIN
		QCheck_Assignments a
	ON
		a.InstanceID = ci.ID
	INNER JOIN
		QCheck_GroupMembership gm
	ON
		gm.GroupID = a.GroupID
	AND
		gm.UserID = @UserID
	INNER JOIN
		QCheck_Groups g
	ON
		g.ID = gm.GroupID
	WHERE
		udt2.id is null
	--WHERE
		--tt.ReportID = @ReportID
	--AND (@showPersonalTasks = 1 OR actt.ShowSupervisor = 1)
	--END SECTION

	
	DECLARE @recordIds AS RecordId
	INSERT INTO @recordIds
		SELECT DISTINCT ReportID FROM #result

	EXEC dbo.Audit_Set @userId, @recordIds, 'Report', 2
	

	SELECT * FROM #result ORDER BY ReportId, ReturnOrder
END
GO

CREATE OR ALTER PROC [dbo].[QStatus_GetSlimCommentsAll]
	@Seed int,
	@ReportID int,
	@UserId int
AS
	SET NOCOUNT ON

	SELECT DISTINCT
		 null AS ArchiveID
		, C.ID
		, tt.keyID AS TaskID
		, DisplayOrder
		, c.TabIn
		, c.Initials
		, u.FullName
		, c.CommentDt
		, c.UserID
		, CASE WHEN gr.USERID IS NOT NULL THEN 
			0 --red
		 ELSE
			CASE WHEN supcolor.colorNum is not null THEN
				supcolor.colorNum
			ELSE
				CASE WHEN sup.interestedParty = 0 THEN
					3 --green
				ELSE
					50 --purple
				END
			END
		 END as colornum
	FROM
		QStatus_COMMENTS C
		INNER JOIN
		QStatus_TempTasks tt
			ON tt.ID = @Seed
			AND c.ForeignKeyID = abs(tt.KeyID)
			AND c.SpecialTask = tt.SpecialTask
		INNER JOIN QCheck_Users u
			ON u.ID = C.UserID
		LEFT OUTER JOIN 
			(SELECT gm.UserID, s.InterestedParty
			FROM QStatus_SUPERVISORS s
			INNER JOIN QCheck_GroupMembership gm
			ON gm.GroupID = s.supervisorGroupID
			INNER JOIN QCheck_Groups g
			ON g.ID = gm.GroupID
			AND s.ReportID = @ReportID
		) sup
		ON sup.UserId = c.UserID
		LEFT OUTER JOIN 
			(SELECT gm.UserID
			FROM QStatus_GroupReport gr
			INNER JOIN QCheck_GroupMembership gm
			ON gm.GroupID = gr.GroupID
			INNER JOIN QCheck_Groups g
			ON g.ID = gm.GroupID
			AND gr.ReportID = @ReportID
		) gr ON gr.UserId = c.UserID
		LEFT OUTER JOIN QStatus_SupervisorColors supcolor
			ON supcolor.supervisorUserID = u.ID

	UNION ALL

	SELECT DISTINCT
		 C.ArchiveID
		, c.ID
		, tt.keyID AS TaskID
		, DisplayOrder
		, c.TabIn
		, c.Initials
		, u.FullName
		, c.CommentDt
		, c.UserID
		, CASE WHEN gr.USERID IS NOT NULL THEN 
			0 --red
		 ELSE
			CASE WHEN supcolor.colorNum is not null THEN
				supcolor.colorNum
			ELSE
				CASE WHEN sup.interestedParty = 0 THEN
					3 --green
				ELSE
					50 --purple
				END
			END
		 END as colornum
	FROM
		QStatus_commentarchive C
		INNER JOIN QStatus_TempTasks tt
			ON tt.ID = @Seed
			AND c.ForeignKeyID = ABS(tt.KeyID)
			AND c.SpecialTask = tt.SpecialTask
		INNER JOIN QCheck_Users u
			ON u.ID = C.UserID
		LEFT OUTER JOIN 
			(SELECT gm.UserID, s.InterestedParty
			FROM QStatus_SUPERVISORS s
			INNER JOIN QCheck_GroupMembership gm
			ON gm.GroupID = s.supervisorGroupID
			INNER JOIN QCheck_Groups g
			ON g.ID = gm.GroupID
			AND s.ReportID = @ReportID
		) sup ON sup.UserId = c.UserID
		LEFT OUTER JOIN 
			(SELECT gm.UserID
			FROM QStatus_GroupReport gr
			INNER JOIN QCheck_GroupMembership gm
			ON gm.GroupID = gr.GroupID
			INNER JOIN QCheck_Groups g
			ON g.ID = gm.GroupID
			AND gr.ReportID = @ReportID
		) gr ON gr.UserId = c.UserID
		LEFT OUTER JOIN QStatus_SupervisorColors supcolor
			ON supcolor.supervisorUserID = u.ID

	SELECT distinct ac2.ID
	FROM 
		QStatus_COMMENTS C
	INNER JOIN
		--QCheck_ActiveChecklists
	(
		select id, instanceid from QCheck_ActiveChecklists
		union all
		select id, instanceid from QCheck_ActiveChecklistArchive
	)
	 AC
	ON
		C.ForeignKeyID = AC.ID
	INNER JOIN
		--QCheck_ChecklistInstances
		(
		select id, checklistid from QCheck_ChecklistInstances
		union all
		select id, checklistid from QCheck_ChecklistInstanceArchive
	) 
	CI
	ON
		CI.ID = AC.InstanceID
	INNER JOIN
		QCheck_ChecklistInstances CI2
	ON
		CI.ChecklistID = CI2.ChecklistID
	INNER JOIN
		QCheck_ActiveChecklists AC2
	ON
		CI2.ID = AC2.InstanceID
	AND
		AC2.ID <> AC.ID
	INNER JOIN
		QStatus_TempTasks tt
	ON
		tt.ID = @Seed
	AND
		ac2.ID = tt.KeyID
	WHERE c.specialtask = 0
GO

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
GO

CREATE OR ALTER PROC [dbo].[QStatus_GetTaskTypes]
	@ReportID int,
	@userId int
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @recordIds AS RecordId
	INSERT INTO @recordIds
		SELECT DISTINCT ID FROM QStatus_TaskTypes WHERE ReportId = @ReportID

	EXEC dbo.Audit_Set @userId, @recordIds, 'TaskType', 2

	SELECT 
		ID As ValStr,
		Replace(Replace(Replace(Replace(Description, '&', '&amp;'), '"', '&quot;'), '>', '&gt;'), '<', '&lt;') As KeyStr
	FROM
		QStatus_TaskTypes tt
	WHERE
		ReportID = @ReportID
	AND
		tt.IsDeleted = 0
	AND
		tt.NativeType = 0
	ORDER BY DisplayOrder
END
GO

