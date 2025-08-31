
-- add preference flag to Automation Email Preferences table, default to 0 for disabled state
if NOT EXISTS (select 'Y' from syscolumns c JOIN sysobjects o ON o.ID = c.ID where c.name = 'WeeklySummaryEmail' and o.name = 'QStatus_AutomationEmailPreferences')
ALTER TABLE dbo.QStatus_AutomationEmailPreferences ADD WeeklySummaryEmail BIT DEFAULT(0) NOT NULL
GO

CREATE OR ALTER PROC dbo.QCheck_WeeklySummaryEmail AS
BEGIN
	SET NOCOUNT ON

	DECLARE	
		@now DATETIME = GETUTCDATE(),
		@userNow DATETIME,
		@today DATE,
		@dayOfWeek INT,	 
		@monday DATE,
		@startDate DATETIME,
		@endDate DATETIME,
		@userTz VARCHAR(255),
		@userId INT,
		@userEmail VARCHAR(255),
		@html VARCHAR(MAX),
		@crlf CHAR(2) = CHAR(13) + CHAR(10),
		-- default to include overdue tasks
		@includOverdue BIT = 1,
		-- default timezone if not defined
		@defaultTz VARCHAR(255) = 'America/Chicago'

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

	-- get all users signed up for weekly email summary
	DECLARE oCursor CURSOR FOR
		SELECT u.ID, Tz = COALESCE(TimeZoneOverride, LastTimeZone, @defaultTz), Email
		FROM dbo.QCheck_Users u
		JOIN dbo.QStatus_AutomationEmailPreferences aep ON aep.UserID = u.ID
		WHERE aep.WeeklySummaryEmail = 1

	OPEN oCursor
	FETCH NEXT FROM oCursor INTO @userId, @userTz, @userEmail
	WHILE @@FETCH_STATUS = 0 BEGIN
		
		-- filter based on user's timezone
		SET @userNow = dbo.ConvertTimeFromUtc(@now, @userTz)
		-- get current user's Monday 12:00AM in UTC time
		SET @today = CAST(@userNow as date)
		SET @dayOfWeek = DATEPART(dw, @today)
		SET @monday = DATEADD(day, (@dayOfWeek - 2) * -1, @today)		
		
		SET @startDate = dbo.ConvertTimeToUtc(@monday, @userTz)
		SET @endDate = DATEADD(MINUTE, -1, DATEADD(DAY, 7, @startDate)) --get the next 7 days' tasks (incl. Sat/Sun)

		--select @userId, @userTz, @userEmail, @startDate, @endDate

		DELETE @tblResults
		INSERT INTO @tblResults
			EXEC QCheck_GetCalendarChecklists 
				@UserID=@userId,
				@ID=N'0',
				@ShowStatusCalendar=0,
				@startDate=@startDate,
				@endDate=@endDate

		-- remove overdue items (prior to Monday) if overriden
		IF @includOverdue = 0 DELETE @tblResults WHERE DueTime < @startDate

		-- convert UTC result back to user's timezone
		UPDATE @tblResults SET 
			DueTime = dbo.ConvertTimeFromUtc(DueTime, @userTz),
			ReminderDate = dbo.ConvertTimeFromUtc(ReminderDate, @userTz)

		--select * from @tblResults
		
		-- html start with inline CSS (required for Outlook compatibility)
		SET @html = 
		'<html>' + @crlf +
		'<body>' + @crlf +
		'<table cellpadding="5" cellspacing="0" border="0" style="border-collapse:collapse; font-family:Arial, sans-serif; font-size:14px; width:100%;">' + @crlf

			--SELECT 
			--	ChecklistName, 
			--	DueTime,
			--	CAST(DueTime AS DATE) AS DueDate,
			--	FORMAT(DueTime, 'hh:mm tt') AS DueTimeOnly,
			--	Active,
			--	Type,
			--	IsAlert
			--FROM @tblResults
			--WHERE DueTime <= @endDate --'cause of course the SP doesn't pay attention to end date
			--UNION ALL
			--	SELECT 
			--	ChecklistName, 
			--	ReminderDate,
			--	CAST(ReminderDate AS DATE) AS DueDate,
			--	FORMAT(ReminderDate, 'hh:mm tt') AS DueTimeOnly,
			--	Active,
			--	Type = -1,
			--	IsAlert
			--FROM @tblResults
			--WHERE ReminderDate BETWEEN @startDate AND @endDate 
			--	and DueTime > @endDate 
			--	and active = 1

		-- table content
		;WITH SortedResults AS (
			SELECT 
				ChecklistName, 
				DueTime,
				CAST(DueTime AS DATE) AS DueDate,
				FORMAT(DueTime, 'hh:mm tt') AS DueTimeOnly,
				Active,
				Type,
				IsAlert
			FROM @tblResults
			WHERE DueTime <= @endDate --'cause of course the SP doesn't pay attention to end date
			UNION ALL
				SELECT 
				ChecklistName, 
				ReminderDate,
				CAST(ReminderDate AS DATE) AS DueDate,
				FORMAT(ReminderDate, 'hh:mm tt') AS DueTimeOnly,
				Active,
				Type = -1,
				IsAlert
			FROM @tblResults
			WHERE ReminderDate BETWEEN @startDate AND @endDate 
				and DueTime > @endDate 
				and active = 1
		),
		DateGroups AS (
			SELECT DISTINCT DueDate FROM SortedResults
		)
		SELECT @html = @html +
			-- date subheader 
			'<tr style="background-color:#b9d4e8; color:#024376; font-weight:bold;"><td colspan="1">' + 
			DATENAME(dw, DueDate) + ', ' + CONVERT(VARCHAR(10), DueDate, 101) + 
			'</td></tr>' + @crlf +
    
			-- rows under date subheader, ordered by time
			(
				SELECT
					-- alternating row BG color
					--'<tr style="background-color:' + 
					--CASE WHEN ROW_NUMBER() OVER (PARTITION BY DueDate ORDER BY DueTime) % 2 = 0 
					--     THEN '#f9f9f9' ELSE '#ffffff' END +
					--';"><td>' + 
			
					-- all white row BG color
					'<tr style="background-color:#ffffff;'
					+ CASE 
						WHEN IsAlert = 1 THEN 'color:#00a0ff;'
						WHEN Active = 0 THEN 'color:#aaaaaa;text-decoration:line-through' 
						WHEN Type = 3 THEN 'color:#aaaaaa;font-style:italic;'
						WHEN Type = -1 THEN 'color:#00aa00;'
						WHEN r2.DueTime < dbo.ConvertTimeFromUtc(GETUTCDATE(), @userTz) THEN 'color:red' 
						ELSE '' 
						END
					+ '"><td>' + 
					DueTimeOnly + ' - ' + ChecklistName + 
					'</td></tr>' + @crlf
				FROM SortedResults r2
				WHERE r2.DueDate = r1.DueDate
				ORDER BY DueTime
				FOR XML PATH(''), TYPE
			).value('.', 'VARCHAR(MAX)')
		FROM DateGroups r1
		ORDER BY r1.DueDate

		-- close table and html
		SET @html = @html + '</table>' + @crlf + '</body>' + @crlf + '</html>'

		--select @html
		DECLARE @appName varchar(100), @fromAddr varchar(255)
		SELECT TOP 1 @appName = AppName, @fromAddr = FromAddress from QCheck_AppSettings

		-- send email
		EXEC dbo.xp_smtp_sendmail 
			@from = @fromAddr, 
			@from_name = @appName,
			@to = @userEmail, 
			@bcc = '',
			@subject = 'Weekly Task Summary',
			@message = @html
	
		FETCH NEXT FROM oCursor INTO @userId, @userTz, @userEmail
	END

	CLOSE oCursor
	DEALLOCATE oCursor
END
GO

USE [msdb]
GO

DECLARE @dbName NVarchar(25) = 'QTasks'

/****** Object:  Job [QTasks - Weekly Task Summary Email]    Script Date: 7/22/2025 4:49:18 PM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 7/22/2025 4:49:18 PM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
	EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
END

DECLARE @jobId BINARY(16)
DECLARE @jobName NVARCHAR(1000) = @dbName + N' - Weekly Task Summary Email'
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name= @jobName, 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [QCheck_WeeklySummaryEmail]    Script Date: 7/22/2025 4:49:18 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'QCheck_WeeklySummaryEmail', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'exec QCheck_WeeklySummaryEmail', 
		@database_name=@dbName, 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Mondays at 8 AM', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=2, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20250722, 
		@active_end_date=99991231, 
		@active_start_time=80000, 
		@active_end_time=235959, 
		@schedule_uid=N'7cc07c03-bd73-4430-ba3e-a85b432433e6'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO