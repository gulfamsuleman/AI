/** ONLY RUN ONCE **/

-- Custom SQL Types
DROP TYPE IF EXISTS RecordId
CREATE TYPE RecordId AS TABLE (
	Id INT PRIMARY KEY 
)
-- If database support memory optimized option, better to use the below instead
-- this will avoid pounding the TempDB
--CREATE TYPE RecordId AS TABLE (
--	Id INT PRIMARY KEY NONCLUSTERED  HASH WITH (BUCKET_COUNT = 1000)
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
