var reportToolbarModule = (function () {
    var self = {};
    var modal = null;
    var reportId;

    self.init = function () {
        modal = window.modalModule;
        reportId = $("#report-id").val();
        self.reportId = reportId;
        $('.dropdown-toggle').dropdownHover();
    };

    $().ready(function () {
        $(document).on("click", "a[data-action='change-report']", function (e) { changeReport(e); });
        $(document).on("click", "a[data-action='supervisors']", function () { getSupervisors(); });
        $(document).on("click", "a[data-action='sections']", function () { getAllSections(); });
        $(document).on("click", "a[data-action='controllers']", function () { getControllers(); });
        $(document).on("click", "a[data-action='manage-reports']", function () { openManageReports(); });
        $(document).on("click", "a[data-action='attorney-client']", function () { getAttorneyClient(); });
        $(document).on("click", "a[data-action='new-task']", function (e) { statusReportModule.rightClickTaskTypeId = ""; self.addNewTaskModal(e); });
        $(document).on("click", "a[data-action='existing-task']", function (e) { statusReportModule.rightClickTaskTypeId = ""; self.addExistingTaskModal(e); });
        $(document).on("click", "a[data-action='mark-read']", function () { markReportAsRead(); });
        $(document).on("click", "a[data-action='email-comments']", function () { emailComments(); });
        $(document).on("click", "a[data-action='timeline']", function () { getTimeline(); });
        $(document).on("click", "a[data-action='assignees']", function (e) { self.toggleAssignees(e, true); });
        $(document).on("click", "a[data-action='tool-delete']", function () { removeTask(); });
        $(document).on("click", "a[data-action='email-all']", function () { emailReport(); });
        $(document).on("click", "a[data-action='email-today']", function () { emailTodaysComments(); });
        $(document).on("click", "a[data-action='export']", function () { getExportWindow(); });
        $(document).on("click", "a[data-action='due-date-changes']", function () { openDueDateChangesModal(); });
        $(document).on("click", "a[data-action='visibility']", function () { openVisibilityModal(); });
        $(document).on("click", "a[data-action='manage-emails']", function () { openManageEmails(); });
        $(document).on("click", "a[data-action='change-fonts']", function () { changeFonts(); });
        $(document).on("click", "a[data-action='manage-confidential-email']", function () { openManageConfidentialEmails(); });
        $(document).on("click", "a[data-action='bulk-update']", function () { openBulkUpdateModal(); });
        $(document).on("click", "a[data-action='supervisors-list']", function () { getSupervisorsList(); });
        $(document).on("click", "a[data-action='interested-party-list']", function () { getInterestedPartiesList(); });
        $(document).on("click", "a[data-action='all-firm-list']", function () { getAllFirmReportsList(); });
        $(document).on("click", "a[data-action='my-favorites-list']", function () { getMyFavoritesList(); });
        $(document).on("click", "a[data-action='print']", function () { printCss(); });
        $(document).on("click", "a[data-action='printBW']", function () { printCssBW(); });
        $(document).on("click", "a[data-action='printXL']", function () { printCssXL(); });
        $(document).on("click", "a[data-action='printXLBW']", function () { printCssXLBW(); });
        $(document).on("click", "a[data-action='single-checklist']", function (e) { openSingleChecklist(e); });
        $(document).on("click", "a[data-action='taskFilter']", toggleTaskFilter);
        self.init();
    });

    // function toggleTaskFilter
    function toggleTaskFilter() {
        if ($("#filters").hasClass("hidden"))
            $("#filters").removeClass("hidden");
        else
            $("#filters").addClass("hidden");
    }

    // Change Reports
    function changeReport(e) {
        var target = $(e.target);
        var reportType = target.data("report-type");
        var id = target.data("id");
        switch (reportType) {
            case "my-report":
                window.location = "MyStatus.aspx?ReportID=" + id;
                break;
            case "ip-report": case "sup-report":
                window.location = "MyInbox.aspx?ReportID=" + id;
                break;
        }
    }

    // Supervisors		
    function getSupervisors() {
        $(document).one("modalModuleContentLoad", function () {
            supervisorsModule.reportId = reportId;
            supervisorsModule.getSupervisors();
        });
        modal.init({
            titleText: "Supervisors",
            controlName: "Controls/Shared/Supervisors.ascx",
            remoteParams: { ReportId: reportId }
        });
    }

    // Sections
    function getAllSections() {
        modal.init({
            titleText: "Sections",
            controlName: "Controls/MyStatus/Sections.ascx",
            remoteParams: { ReportId: reportId }
        });
    }

    // Controllers
    function getControllers() {
        $(document).one("modalModuleContentLoad", function () {
            controllersModule.reportId = reportId;
            controllersModule.getControllers();
        });
        modal.init({
            titleText: "Controllers",
            controlName: "Controls/Shared/Controllers.ascx"
        });
    }

    // Add / Delete / Edit Reports
    function openManageReports() {
        modal.init({
            titleText: "My Reports",
            controlName: "Controls/MyStatus/ManageReports.ascx"
        });
    }

    // Attorney Client
    function getAttorneyClient() {
        $(document).one("modalModuleContentLoad", function () {
            statusAttorneyClient.populateAttorneyClientCheckbox(statusReportModule.isConfidential);
        });
        modal.init({
            titleText: "Attorney Client",
            controlName: "Controls/MyStatus/AttorneyClient.ascx",
            initFunction: function () {
                if (self.isConfidential)
                    $("#attorney-client-setter").attr("checked", "checked");
            }
        });
    }

    // Manage Single Checklist
    function openSingleChecklist(e) {
        var taskId = $(e.target).closest("tr").data("id");
        var isArchive = $("#IsArchive").val();
        var taskStage = isArchive ? 2 : 1;
        window.open("ManageSingleChecklist.aspx?taskId=" + taskId + "&taskStage=" + taskStage);
    }

    // Print CSS
    function addPrintCss(path) {
        $("<link>").attr({
            rel: "stylesheet",
            href: path,
            media: "print",
            type: "text/css"
        }).appendTo("head");
    }

    function removePrintCss() {
        $("head").find("link[rel='stylesheet'][media='print']").remove();
    }


	self.printTask = function() {
		$("[data-role='expand-task']").click();
		printCss();
	}

    function printCss() {
        removePrintCss();
        addPrintCss("Content/PrintBase.css");
        window.print();
    }

    function printCssBW() {
        removePrintCss();
        addPrintCss("Content/PrintBase.css");
        addPrintCss("Content/PrintBlackAndWhite.css");
        window.print();
    }

    function printCssXL() {
        removePrintCss();
        addPrintCss("Content/PrintBase.css");
        addPrintCss("Content/PrintLargeFont.css");
        window.print();
    }

    function printCssXLBW() {
        removePrintCss();
        addPrintCss("Content/PrintBase.css");
        addPrintCss("Content/PrintBlackAndWhite.css");
        addPrintCss("Content/PrintLargeFont.css");
        window.print();
    }

    // Tasks
    function removeTask() {
        var editRows = $(".status-table tr[data-state='edit']");
        var sectionTable = editRows.closest(".status-table");
        if (editRows.length == 0)
            notifier.setMessage("Select a table row for editing before using this functionality", "red", "10000");
        else {
            $.ajax({
                url: "/DataService.asmx/RemoveTaskFromReport",
                type: "POST",
                data: JSON.stringify({
                    reportId: reportId,
                    activeChecklistId: editRows.data("id")
                }),
                contentType: "application/json",
                success: function (data) {
                    editRows.remove();
                    if (sectionTable.find("tr[data-state=view]").length == 0) {
                        sectionTable.remove();
                    }
                }
            });
        }
    }

    self.addNewTaskModal = function (e) {
        var taskType = statusReportModule.rightClickTaskTypeId;
        if (taskType == "") {
            taskType = $(e.target).attr("data-id");
        }
        modal.init({
            titleText: "New Task",
            controlName: "Controls/Shared/NewTask.ascx",
            remoteParams: { ShowPriority: true, TaskType: taskType }
        });
    };

    self.addExistingTaskModal = function (e) {
        var taskType = statusReportModule.rightClickTaskTypeId;
        if (taskType == "") {
            taskType = $(e.target).attr("data-id");
        }
        modal.init({
            titleText: "Existing Tasks",
            controlName: "Controls/MyStatus/AddExistingTask.ascx",
            remoteParams: { Section: taskType, Sort: "duetime", ReportId: reportId }
        });
    };

    self.addExistingTaskModalSort = function (taskType, sort) {
        modal.init({
            titleText: "Existing Tasks",
            controlName: "Controls/MyStatus/AddExistingTask.ascx",
            remoteParams: { Section: taskType, Sort: sort, ReportId: reportId }
        });
    };

    self.moveTask = function () {
        modal.init({
            titleText: "Move Task",
            controlName: "Controls/MyStatus/MoveTask.ascx",
            remoteParams: { TaskId: statusReportModule.rightClickTaskId, CopyMove: "Move" }
        });
    };

    self.copyTask = function () {
        modal.init({
            titleText: "Copy Task",
            controlName: "Controls/MyStatus/CopyTask.ascx",
            remoteParams: { TaskId: statusReportModule.rightClickTaskId, CopyMove: "Copy" }
        });
    };

    // Email Comments
    function emailComments() {
        var inbox = false;
        if (window.myInboxModule) { inbox = true; }
        var params = {
            mode: "comments",
            ReportId: reportId,
            isUrgent: false,
            inbox: inbox
        };
        openEmailModal(params, "Email Comments");
    }

    // Email All Comments
    function emailReport() {
        var params = {
            mode: "all",
            ReportId: reportId,
            isUrgent: false
        };
        openEmailModal(params, "Email All");
    }

    // Email Todays Comments
    function emailTodaysComments() {
        var params = {
            mode: "todays-comments",
            ReportId: reportId,
            isUrgent: false
        };
        openEmailModal(params, "Email Today's Comments");
    }

    function openEmailModal(params, title) {
        modal.init({
            titleText: title,
            controlName: "Controls/MyStatus/EmailComments.ascx",
            remoteParams: params
        });

        //$("#comments-date").lwDatepicker();
    }

    self.openEmailModal = openEmailModal;

    // Export 
    function getExportWindow() {
        $(document).one("modalModuleContentLoad", function () {
            $.ajax({
                url: "/DataService.asmx/GetMyReportsList",
                type: "POST",
                contentType: "application/json",
                success: function (data) {
                    var reports = data.d;
                    for (var i = 0; i < reports.length; i++) {
                        statusExport.addExportTableRow(reports[i]);
                    }
                }
            });

            $.ajax({
                url: "/DataService.asmx/GetMySupervisedReportsList",
                type: "POST",
                contentType: "application/json",
                success: function (data) {
                    var reports = data.d;
                    for (var i = 0; i < reports.length; i++) {
                        statusExport.addExportTableRow(reports[i]);
                    }
                }
            });

            $.ajax({
                url: "/DataService.asmx/GetMyInterestedPartyReportsList",
                type: "POST",
                contentType: "application/json",
                success: function (data) {
                    var reports = data.d;
                    for (var i = 0; i < reports.length; i++) {
                        statusExport.addExportTableRow(reports[i]);
                    }
                }
            });
        });
        modal.init({
            titleText: "Export Options:",
            controlName: "Controls/MyStatus/Export.ascx"
        });
    }

    // Bulk Update
    function openBulkUpdateModal() {
        modal.init({
            titleText: "Update Soft Due Dates / Add Comments",
            controlName: "Controls/MyStatus/BulkUpdate.ascx",
            remoteParams: { ReportId: reportId }
        });
    }

    // Change Fonts
    function changeFonts() {
        $.ajax({
            url: "/DataService.asmx/ChangeFonts",
            type: "POST",
            success: function (data) {
                if (window.location.href.indexOf("MyInbox") >= 0)
                    $("#my-inbox-panel  #main-content").toggleClass("serif-fonts");
                else
                    $("#status-report #main-content").toggleClass("serif-fonts");
            }
        });
    }

    // Timeline
    function getTimeline() {
        modal.init({
            titleText: "Timeline",
            controlName: "Controls/MyStatus/Timeline.ascx",
            remoteParams: { Controller: 1, ReportId: reportId }
        });
    }

    // Hide/show assignees column in tables that have the asignees column.
    self.toggleAssignees = function (e, persist) {
        var heading = $('.report-line-headings-assignees');
        var content = $('.report-line-assignees-content');
        var toggle = $("[data-action='assignees']");
        if (!persist || toggle.attr('assigneesHidden') == "true") {
            heading.removeClass("hidden");
            content.removeClass("hidden");
            toggle.attr('assigneesHidden', "false");
        } else {
            heading.addClass("hidden");
            content.addClass("hidden");
            toggle.attr('assigneesHidden', "true");
        }
        // [ST] 11/25/14 - persist perference to database
        if (persist)
            asyncPost("ToggleAssigneeVisibility", JSON.stringify({ reportID: self.reportId }));
    }

    // My Inbox
    // Get Supervisors List
    function getSupervisorsList() {
        if (window.myInboxModule)
            window.myInboxModule.loadReport(1);
    }

    // Get Interested Parties List
    function getInterestedPartiesList() {
        if (window.myInboxModule)
            window.myInboxModule.loadReport(2);
    }

    // Get All Firm Reports List
    function getAllFirmReportsList() {
        if (window.myInboxModule)
            window.myInboxModule.loadReport(3);
    }

    // Get My Favorites List
    function getMyFavoritesList() {
        if (window.myInboxModule)
            window.myInboxModule.loadReport(4);
    }

    // Open the Manage Emails Control
    function openManageEmails() {
        modal.init({
            controlName: "Controls/MyInbox/ManageEmails.ascx",
            titleText: "Manage Email Settings"
        });
    }

    // Mark As Read
    function markReportAsRead() {
        if (window.myInboxModule)
            window.myInboxModule.markReportAsRead($("#report-id").val());
    }

    // Open Due Date Changes Modal
    function openDueDateChangesModal() {
        modal.init({
            controlName: "Controls/MyInbox/DueDateChanges.ascx",
            titleText: "Due Date Changes",
            remoteParams: { ReportId: reportId }
        });
    }

    // Open Visibility Modal
    function openVisibilityModal() {
        modal.init({
            controlName: "Controls/MyInbox/Visibility.ascx",
            titleText: "Visibility",
            remoteParams: { ReportId: reportId }
        });
    }

    // Open the Manage Confidential Email Modal
    function openManageConfidentialEmails() {
        modal.init({
            controlName: "Controls/MyInbox/ConfidentialReports.ascx",
            titleText: "Confidential Reports"
        });
    }

    return self;
})();
/* Copyright © 2024 Renegade Swish, LLC */

