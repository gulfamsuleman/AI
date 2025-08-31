USE [PHIProcess]
GO

/****** Object:  StoredProcedure [dbo].[Util_GradeTest_Breakdown]    Script Date: 7/16/2024 10:01:24 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



ALTER     PROCEDURE [dbo].[Util_GradeTest_Breakdown] (
--DECLARE
      @TesterGroupID INT,-- = 352,
      @TestDate DATETIME-- = '2024-02-16'
) AS
BEGIN

      DECLARE @RawScore FLOAT = 0,
                  @TesterUserID INT,
                  @Username VARCHAR(50),
                  @Fullname varchar(100),
                  @TesterReportID INT,
                  @Count INT,
                  @TestGraders INT,
                  @TestAssignee INT,
                  @Prefix varchar(50)

      SELECT @Prefix = AppName from QCheck_AppSettings
      
      --SELECT @Prefix

      SELECT
            @TesterUserID = u.ID,
            @Username = u.ShortName,
            @Fullname = u.fullname,
            @TesterReportID = r.ID
      FROM
            QCheck_Users u
            INNER JOIN QCheck_GroupMembership gm
                  ON u.ID = gm.UserID
            INNER JOIN QCheck_Groups g
                  ON gm.GroupID = g.ID
            INNER JOIN QStatus_Report r
                  ON u.FullName = r.Name
                  AND r.IsDeleted = 0
      WHERE
            g.ID = @TesterGroupID
            AND u.IsDeleted = 0
            AND g.SingleMemberGroup = 1
            AND u.FullName = g.Name

      SELECT @Prefix Prefix,
            @TesterGroupID TesterGroupID,
            @TesterUserID TesterUserID,
            @Username Username,
            @Fullname Fullname,
            @TesterReportID TesterReportID,
            @TestDate TestDate
            

      declare
            @checklistcount int,
            @itemcount int,
            @reportcount int,
            @sectioncount int,
            @prioritiescount int,
            @commentscount int,
            @groupscount int

      select *
      from qcheck_checklists
      where owner = @testerUserID
            and CreateDate > @TestDate
            and name like @Prefix + '%test%'

      select @checklistcount = isnull(count(id), 0)
      from qcheck_checklists
      where owner = @testerUserID
            and CreateDate > @TestDate
            and name like @Prefix + '%test%'

      --select @checklistcount checklistcount

      if @checklistcount > 0 set @checklistcount = @checklistcount + 1
      if @checklistcount > 14 set @checklistcount = 14

      select *
      from qcheck_checklists c
            inner join qcheck_items i
                  on i.checklistid = c.id
      where c.owner = @testerUserID
            and c.CreateDate > @TestDate
            and c.name like @Prefix + '%test%5%'

      select @itemcount = isnull(count(i.id), 0)
      from qcheck_checklists c
            inner join qcheck_items i
                  on i.checklistid = c.id
      where c.owner = @testerUserID
            and c.CreateDate > @TestDate
            and c.name like @Prefix + '%test%5%'

      --select @itemcount itemcount

      --if @itemcount > 0 set @itemcount = @itemcount + 2

      if @itemcount > 8 set @itemcount = 8

      --Making sure there are 4 types of checklist items
      IF (
            SELECT COUNT(DISTINCT ItemTypeID) from qcheck_checklists c
                  inner join qcheck_items i
                        on i.checklistid = c.id
            where c.owner = @testerUserID
                  AND c.CreateDate > @TestDate
                  AND c.name like @Prefix + '%test%5%'                  
      ) = 4
            set @itemcount = @itemcount + 1

      --Specifically looking for URL added to "Step 2"
      IF EXISTS (
            SELECT 'Y' from qcheck_checklists c
                  inner join qcheck_items i
                        on i.checklistid = c.id
            where c.owner = @testerUserID
                  AND c.CreateDate > @TestDate
                  AND c.name like @Prefix + '%test%5%'
                  AND i.Text = 'Step 2'
                  AND i.URL LIKE 'http%google%com%'
      )
            set @itemcount = @itemcount + 1     

      --Looking for two assignments on *Process Test 6
      IF (
            select COUNT(*) from QCheck_ActiveAssignments aa
                  JOIN QCheck_ActiveChecklists ac
                        ON ac.ID = aa.ActiveChecklistID
                  JOIN QCheck_ChecklistInstances ci
                        ON ci.ID = ac.InstanceID
                  JOIN QCheck_Checklists c
                        ON c.ID = ci.ChecklistID
            WHERE c.owner = @testerUserID
                  AND c.CreateDate > @TestDate
                  AND c.name like @Prefix + '%test%6'
      ) = 2
            set @itemcount = @itemcount + 1

      set @itemcount = CASE WHEN @itemcount > 10 THEN 10 ELSE @itemcount END

      select *  
      from qstatus_report r
            inner join qstatus_groupreport gr
                  on r.id = gr.reportid
                  AND gr.AsOf > @TestDate
            inner join qcheck_groupmembership gm
                  on gm.groupid = gr.groupid
                        and gm.userid = @testerUserID
                        and r.name like '%' + @Prefix + '%report%'

      SET @reportcount = 0

      select @reportcount = @reportcount + isnull(count(r.id), 0)  
      from qstatus_report r
            inner join qstatus_groupreport gr
                  on r.id = gr.reportid
                  AND gr.AsOf > @TestDate
            inner join qcheck_groupmembership gm
                  on gm.groupid = gr.groupid
                        and gm.userid = @testerUserID
                        and r.name like '%' + @Prefix + '%report'
            WHERE r.IsDeleted = 0

      select @reportcount = @reportcount + isnull(count(r.id), 0)  
      from qstatus_report r
            inner join qstatus_groupreport gr
                  on r.id = gr.reportid
                  AND gr.AsOf > @TestDate
            inner join qcheck_groupmembership gm
                  on gm.groupid = gr.groupid
                        and gm.userid = @testerUserID
                        and r.name like '%' + @Prefix + '%report%2'
            WHERE r.IsDeleted = 0

      select @reportcount = @reportcount + isnull(count(r.id), 0)  
      from qstatus_report r
            inner join qstatus_groupreport gr
                  on r.id = gr.reportid
                  AND gr.AsOf > @TestDate
            inner join qcheck_groupmembership gm
                  on gm.groupid = gr.groupid
                        and gm.userid = @testerUserID
                        and r.name like '%' + @Prefix + '%report%3'
            WHERE r.IsDeleted = 1

      --select @reportcount reportcount
                  
      if @reportcount > 3 set @reportcount = 3  

      select @sectioncount = count(tt.id)
      from qstatus_report r
            inner join qstatus_groupreport gr
                  on r.id = gr.reportid
            inner join qcheck_groupmembership gm
                  on gm.groupid = gr.groupid
                        and gm.userid = @testerUserID
                        and r.name like '%' + @Prefix + '%rep%'
            inner join qstatus_tasktypes tt
                  on tt.reportid = r.id
                  and tt.description like '%task%'

      if @sectioncount > 3 set @sectioncount = 3

      --select @sectioncount sectioncount
      
      select *
      from Priorities_ListItems li
            JOIN Priorities_Lists pl
                  ON pl.ID = li.ListID
                  AND pl.IsDefaultList = 1
            inner join qcheck_activechecklists ac
                  on ac.id = li.activechecklistid
            inner join qcheck_checklistinstances ci
                  on ci.id = ac.instanceid
            inner join qcheck_checklists c
                  on c.id= ci.checklistid
                  and c.name like @Prefix + '%test%'
      where userid = @testerUserID

      select @prioritiescount = count(pl.id)
      from Priorities_ListItems li
            JOIN Priorities_Lists pl
                  ON pl.ID = li.ListID
                  AND pl.IsDefaultList = 1
            inner join qcheck_activechecklists ac
                  on ac.id = li.activechecklistid
            inner join qcheck_checklistinstances ci
                  on ci.id = ac.instanceid
            inner join qcheck_checklists c
                  on c.id= ci.checklistid
                  and c.name like @Prefix + '%test%'
      where userid = @testerUserID

      --select @prioritiescount prioritiescount

      if @prioritiescount > 10 set @prioritiescount = 10

      select *
      from qstatus_comments comm
            inner join qcheck_activechecklists ac
                  on ac.id = comm.foreignkeyid
                  and comm.specialtask = 0
                  and comm.userid = @testerUserID
            inner join qcheck_checklistinstances ci
                  on ci.id = ac.instanceid
            inner join qcheck_checklists c
                  on c.id= ci.checklistid
                  and c.name like @Prefix + '%test%'
                  and c.owner = @testerUserID
                  and c.CreateDate > @TestDate

      select @commentscount = count(c.id)
      from qstatus_comments comm
            inner join qcheck_activechecklists ac
                  on ac.id = comm.foreignkeyid
                  and comm.specialtask = 0
                  and comm.userid = @testerUserID
            inner join qcheck_checklistinstances ci
                  on ci.id = ac.instanceid
            inner join qcheck_checklists c
                  on c.id= ci.checklistid
                  and c.name like @Prefix + '%test%'
                  and c.owner = @testerUserID
                  and c.CreateDate > @TestDate

      --select @commentscount commentscount
            
      if @commentscount > 0 set @commentscount = @commentscount
      if @commentscount > 5 set @commentscount = 5

      select @groupscount = count(id) from qcheck_groups
      where owner = @testerUserID
      and name like '%' + @Prefix + '%test%'

      --select @groupscount groupscount

      if @groupscount > 1 set @groupscount = 1

      --SELECT
      --    sectioncount = @sectioncount,
      --    reportcount = @reportcount,
      --    itemcount = @itemcount,
      --    checklistcount = @checklistcount,
      --    prioritiescount = @prioritiescount,
      --    commentscount = @commentscount,
      --    groupscount = @groupscount

      --New "Written Section" - worth a max of 9 points with opportunity for makeup credit
      DECLARE @writtenSection int = 0

      SELECT *
      from qcheck_checklists
      where owner = @testerUserID
            and CreateDate > @TestDate
            and (name like @Prefix + '% Tasks%'
            OR name like @Prefix + '% Change Requests%'
            OR name like @Prefix + '% Group%'
            OR name like @Prefix + '% Search%'
            OR name like @Prefix + '% Help%')
      
      --"Total Tasks" = 12 (*could* be 13 if within two weeks of a calendar quarter - no points off for that)
      IF(SELECT isnull(count(id), 0)
            from qcheck_checklists
            where owner = @testerUserID
                  and CreateDate > @TestDate
                  and (name like @Prefix + ' Total Tasks%') --12 or 13
      ) = 1
            SET @writtenSection = @writtenSection + 1

      --"Calendar Tasks" = 10
      IF(SELECT isnull(count(id), 0)
            from qcheck_checklists
            where owner = @testerUserID
                  and CreateDate > @TestDate
                  and (name like @Prefix + ' Calendar Tasks% 1%')---10
      ) = 1
            SET @writtenSection = @writtenSection + 1

      --"Controlled Tasks" = 4
      IF(SELECT isnull(count(id), 0)
            from qcheck_checklists
            where owner = @testerUserID
                  and CreateDate > @TestDate
                  and (name like @Prefix + ' Controlled Tasks%') --4
      ) = 1
            SET @writtenSection = @writtenSection + 1

      --"Report Tasks" = 3
      IF(SELECT isnull(count(id), 0)
            from qcheck_checklists
            where owner = @testerUserID
                  and CreateDate > @TestDate
                  and (name like @Prefix + ' Report Tasks%')--3
      ) = 1
            SET @writtenSection = @writtenSection + 1

      --"Priority Tasks" = 4
      IF(SELECT isnull(count(id), 0)
            from qcheck_checklists
            where owner = @testerUserID
                  and CreateDate > @TestDate
                  and (name like @Prefix + ' Priority Tasks%')--4
      ) = 1
            SET @writtenSection = @writtenSection + 1

      --"Change Requests" = 3
      IF(SELECT isnull(count(id), 0)
            from qcheck_checklists
            where owner = @testerUserID
                  and CreateDate > @TestDate
                  and (name like @Prefix + ' Change Requests% 3')
      ) = 1
            SET @writtenSection = @writtenSection + 1

      --"Timeline Tasks" = 0
      IF(SELECT isnull(count(id), 0)
            from qcheck_checklists
            where owner = @testerUserID
                  and CreateDate > @TestDate
                  and (name like @Prefix + ' Timeline Tasks% 0')
      ) = 1
            SET @writtenSection = @writtenSection + 1

      --"Process Group - Sample Process"
      IF(SELECT isnull(count(id), 0)
            from qcheck_checklists
            where owner = @testerUserID
                  and CreateDate > @TestDate
                  and (name like @Prefix + ' Group%Sample%')
      ) = 1
            SET @writtenSection = @writtenSection + 1

      --"Process Search - Choose AND Logic if..."
      IF(SELECT isnull(count(id), 0)
            from qcheck_checklists
            where owner = @testerUserID
                  and CreateDate > @TestDate
                  and (name like @Prefix + ' Search%Choose AND logic%')
      ) = 1
            SET @writtenSection = @writtenSection + 1


      --"Process Help - Every task needs to be assigned..."
      IF(SELECT isnull(count(id), 0)
            from qcheck_checklists
            where owner = @testerUserID
                  and CreateDate > @TestDate
                  and (name like @Prefix + ' Help%Every task needs to be assigned%')
      ) = 1

            SET @writtenSection = @writtenSection + 1


      if @writtenSection > 9 set @writtenSection = 9

      SELECT
            "Checklists (14) x2" = @checklistcount,
            "Items (10) x2" = @itemcount,
            "Reports (3) x2" = @reportcount,
            "Sections (3) x2" = @sectioncount,
            "Priorities (10) x2" = @prioritiescount,
            "Comments (5) x2" = @commentscount,
            "Groups (1)" = @groupscount,
            "Written (9)" = @writtensection

      SELECT @RawScore  = 2 * (@sectioncount + @reportcount + @itemcount + @checklistcount + @prioritiescount + @commentscount) + @groupscount + @writtenSection

      --insert into Grading_QProcessTests (employee, grade, gradeddt)
      --values (@Fullname,@RawScore, getdate());

      select @RawScore AS Score

END
GO


