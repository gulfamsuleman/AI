<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="MobileMyStatus.aspx.cs" Inherits="QProcess.Mobile.MobileMyStatus" MasterPageFile="Mobile.master" %>

<asp:Content ID="head" runat="server" ContentPlaceHolderID="headContent">
    <style type="text/css">
        #main {
            padding-top: 16px;
        }

        .card-body {
            background-color: #fff;
        }

        .card-header {
            font-size: 15pt;
        }

        .collapsible-item .collapsed {
            display: none;
        }

        #task-container > .col-xs-12 {
            width: 100%;
        }

        #task-container {
            /*            border: 1px solid #ccc;
            border-radius: 5px;*/
            margin: -8px;
        }

        .recurring-indicator {
            position: absolute;
            right: 24px;
        }

        .view-controls {
            position: absolute;
            right: 18px;
            top: 12px;
        }

        .panel-heading {
            background-color: #ebebeb;
            padding: 8px;
            border-radius: 5px;
        }

            .panel-heading .actions {
                float: right;
            }

            .panel-heading h3 {
                margin-right: 50px;
                font-size: 16pt;
            }

        .main-heading .actions {
            margin-right: 40px;
        }

        .panel-default {
            border: 1px solid #ccc;
            margin-top: 10px;
            border-radius: 5px;
        }

            .panel-default .panel-body {
                padding: 8px;
            }

        .hidden {
            display: none;
            visibility: hidden;
        }

        a[data-role='dragndrop-dragpoint'] {
            display: none;
        }

        .panel-body input, .panel-body textarea, .panel-body select {
            margin-top: 3px;
            margin-bottom: 3px;
        }

        .panel-body fieldset {
            padding: 16px;
        }

        #name-panel input {
            margin-right: 40px;
        }

        #name-panel i {
            font-size: 20pt;
            position: absolute;
            right: 30px;
        }

        #controllers-panel button {
            position: absolute;
            margin-top: -24px;
        }

        #controllers-panel select {
            margin-left: 50px;
        }

        #checklist-items-panel select {
            width: 85%;
            margin-left: auto;
        }

        #checklist-items-panel button[data-action='preview'] {
            display: none;
        }

        .weekly-recurring-panel .row,
        .alert-type-panel .row {
            margin: 0;
        }

        .assignment-wrapper #Select1 {
            width: 85%;
            margin-left: auto;
        }

        @media (min-width: 321px) {
            .alerts-reminders-panel div.table-responsive {
                width: 335px;
            }
        }

        @media (max-width: 320px) {
            #checklist-items-panel select {
                width: 80%;
            }

            .alerts-reminders-panel div.table-responsive {
                width: 260px;
            }

            .assignment-wrapper #Select1 {
                width: 80%;
            }
        }

        a {
            color: #003366;
        }

        table {
            display: table !important;
        }

            table tr {
                display: block !important;
            }

                table tr.report-header-column {
                    display: none !important;
                }

                table tr.report-line-border {
                    border-color: #b2b26f;
                }

                table tr.report-line-content {
                    border-radius: 5px;
                    margin-bottom: 10px;
                    padding: 1px;
                    border: 1px solid #b2b26f;
                }

        tr.report-line-header {
            border-radius: 5px;
        }

        table tr.report-line-ender {
            display: none !important;
        }

        table tr td {
            display: block;
        }

        table.status-table tbody td {
            border: 0 !important;
        }

        td.report-line-subheader {
            font-size: 16pt;
            text-decoration: none !important;
        }

        .na-row {
            display: none;
        }

        span.data-label {
            display: block !important;
            visibility: visible !important;
            font-weight: bold;
        }

        span.overduespan {
            display: inline-block;
        }

        div[data-role=comment-buttons] > div {
            width: 67% !important;
            display: block !important;
            margin-left: auto;
            margin-right: auto;
        }

            div[data-role=comment-buttons] > div > button {
                width: 100% !important;
                margin: 4px 0;
                padding: 10px 0px;
                font-size: 14pt;
            }

                div[data-role=comment-buttons] > div > button[data-role=save] {
                    color: #fff;
                    background-color: #28a745;
                    border-color: #28a745;
                }

                div[data-role=comment-buttons] > div > button[data-role=response-requested] {
                    color: #fff;
                    background-color: #dc3545;
                    border-color: #dc3545;
                }

                div[data-role=comment-buttons] > div > button[data-role=cancel-comment] {
                    color: #fff;
                    background-color: #6c757d;
                    border-color: #6c757d;
                }

                div[data-role=comment-buttons] > div > button[data-role=add-link] {
                    color: #fff;
                    background-color: #17a2b8;
                    border-color: #17a2b8;
                }

        td.report-line-task-general-comment {
            height: auto !important;
        }

        tbody tr td[data-role=priority],
        tbody tr td[data-role=action] {
            background-color: #ece9d8;
        }

        table.status-table td[data-role=priority] {
            display: inline-block !important;
            position: relative;
            top: -58px;
            float: right;
            background-color: transparent;
        }

            table.status-table td[data-role=priority] input {
                padding: 0;
            }

        #ddlReportHeader {
            margin-bottom: 10px;
            border-color: #b2b26f;
            background-color: #ffffed;
        }

        #ddlReportHeader_dummy {
            display: none;
        }

        #navSlideLayer div.preview {
            width: 100% !important;
            overflow-x: auto;
            overflow-y: auto;
        }

            #navSlideLayer div.preview table {
                width: 100% !important;
            }

                #navSlideLayer div.preview table tr {
                    display: table-row !important;
                }

                #navSlideLayer div.preview table td {
                    display: table-cell !important;
                }

        body {
            overflow-x: unset;
        }

        .nav-scroller {
            position: sticky;
            top: 40px;
        }

        @media (max-width: 380px) {
            .nav-scroller {
                top: 66px !important;
            }
        }

        .search-bar-sticky {
            position: sticky;
            top: 80px;
            z-index: 3;
            background: #fff;
            border-bottom: 1px solid #eee;
            box-shadow: 0 2px 8px rgba(0,0,0,0.08);
        }

        #simple-task-form {
            width: auto !important;
            height: auto !important;
            border: 0 !important;
            background: white !important;
        }

        input[data-role=datepicker] {
            border-radius: 5px;
            border: 1px solid #ccc;
            padding: 4px 8px;
            width: 100px;
        }

        #task-controller-select,
        #task-controller2-select {
            margin-bottom: 10px;
        }

        #task-controller-me {
            position: absolute;
            left: 100px;
            margin-top: -31px;
        }

        #simple-controller-panel {
            margin-top: -25px;
        }

        button.btn-submit-simple {
            border-radius: 5px;
            padding: 8px 16px !important;
            color: #fff !important;
            background-color: #28a745 !important;
            font-weight: normal !important;
            border: 0 !important;
        }

        .notice-text {
            background-color: #eee;
            border: 1px solid #ccc;
            padding: 5px;
            border-radius: 5px;
        }

        fieldset {
            border-radius: 5px;
            margin-top: 10px;
            width: 100% !important;
        }

        select[name=due-time] {
            width: 114px;
            display: inline-block;
        }

        textarea {
            margin-bottom: 10px;
        }

        select[data-set=sections] {
            border: 1px solid #ccc;
            padding: 4px 8px;
            border-radius: 5px;
            margin-right: 5px;
        }

        select[data-set=folders] {
            margin-bottom: 5px;
        }

        #complex-task-panel select[data-set=controllers],
        #complex-task-panel select[data-set=controllers-with-groups],
        #complex-task-panel select[data-set=item-types] {
            margin-top: 5px;
        }

        #complex-task-panel .btn {
            font-size: 12pt !important;
            border-radius: 5px !important;
            padding: 4px 8px !important;
        }

            #complex-task-panel .btn.btn-submit-complex {
                font-size: 20pt !important;
                padding: 20px !important;
            }

        #Select1 {
            margin: 5px 0;
        }

        #link-url {
            border: 1px solid #ccc;
            border-radius: 5px;
            margin-left: 5px;
        }

        #btn-search.btn {
            user-select: none;
            padding: 0.375rem 0.75rem;
            font-size: 1rem;
            line-height: 1.5;
            border-radius: 0.25rem;
            font-weight: 400;
        }
        /*main.container { overflow-x: scroll; }*/

        div.nav-scroller span:not(:last-child) {
            margin-right: 3%;
        }

        .btn-check {
            position: absolute;
            clip: rect(0, 0, 0, 0);
            pointer-events: none;
        }

        #navSlideLayer h3 {
            font-size: 1.4rem;
        }

        #taskPlaceholder {
            height: calc(100vh - 14rem);
        }

        #available-tasks {
            height: calc(100vh - 21.5rem);
            margin-bottom: 6px !important;
        }

        #available-tasks-panel #search-box {
            display: inline-block;
            width: calc(100% - 64px);
        }

        #available-tasks-panel .btn[data-role=search] {
            height: 37.6px;
            position: relative;
            top: -2px;
        }

        #available-tasks-panel .btn {
            background: #ffffff;
            margin: 3px 0;
        }

            #available-tasks-panel .btn:hover,
            #available-tasks-panel .btn:active,
            #available-tasks-panel .btn:focus-visible {
                color: black !important;
            }

        #available-tasks-panel .search-bar {
            margin-bottom: 6px !important;
        }

        #available-tasks-table tr {
            display: table-row !important;
            border-bottom: solid 1px #cccccc;
        }

        #available-tasks-table td {
            display: inline-block;
            border-bottom: none;
        }

            #available-tasks-table td:first-child {
                display: table-cell;
            }

            #available-tasks-table td:nth-child(2) {
                width: calc(100% - 30px);
                font-weight: 500;
            }

            #available-tasks-table td:nth-child(3)::before {
                content: "Due: ";
            }

            #available-tasks-table td:nth-child(4)::before {
                content: "Assn: ";
            }

        #available-tasks-table span.highlight {
            background-color: yellow;
        }

        @media screen and (max-width: 452.98px) {
            #available-tasks {
                height: calc(100vh - 23rem);
            }
        }

        @media screen and (max-width: 401.98px) {
            #available-tasks {
                height: calc(100vh - 25.5rem);
            }
        }

        @media screen and (max-width: 326.98px) {
            #available-tasks {
                height: calc(100vh - 27.5rem);
            }
        }

        #changeReport, #addTask, #addTask, #emailComments, #supervisorPopup {
            cursor: pointer;
        }

        /* Keeps add button and supervisor dropdown next to each other */
        #supervisors-panel .form-inline {
            display: flex;
            flex-direction: row;
            align-items: center;
        }

            #supervisors-panel .form-inline button {
                margin-right: 10px;
            }

            #supervisors-panel .form-inline select {
                flex: 1;
            }

        #supervisors-panel td {
            display: table-cell;
            padding: 2px 5px 2px 5px;
        }

        #supervisors-panel tr {
            display: table-row !important;
        }

        #supervisors-panel table {
            width: auto;
            font-family: Tahoma, Verdana;
        }

        #supervisors-panel .table > :not(caption) > * > * {
            padding: 2px 5px 2px 5px;
        }

        #supervisor-select {
            max-width: 500px;
        }

        .filter-hide {
            display: none !important;
        }
    </style>

    <script>
        // Utility: Escape regex special characters
        function escapeRegExp(string) {
            return string.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
        }

        // Remove all highlights and restore original HTML
        function removeHighlighting(node) {
            if (!node) return;
            // Remove all highlight spans
            $(node).find('span.searchhighlight').each(function () {
                $(this).replaceWith($(this).text());
            });
            // Restore any data-original-html if present
            $(node).find('[data-original-html]').each(function () {
                $(this).html($(this).attr('data-original-html'));
                $(this).removeAttr('data-original-html');
            });
        }

        // Highlight all matches for the search string
        function highlightSearchResults(node, searchString) {
            if (!node || !searchString) return;
            removeHighlighting(node);

            // Split the search string into keywords
            const keywords = searchString.split(' ').filter(Boolean);

            keywords.forEach(keyword => {
                if (!keyword) return;
                const regex = new RegExp(`(${escapeRegExp(keyword)})`, 'gi');
                wrapMatches(node, regex);
            });
        }

        // Recursively wrap matches in all text nodes
        function wrapMatches(node, regex) {
            if (!node) return;
            if (node.nodeType === Node.TEXT_NODE) {
                if (regex.test(node.nodeValue)) {
                    const span = document.createElement('span');
                    span.innerHTML = node.nodeValue.replace(regex, '<span class="searchhighlight">$1</span>');
                    node.parentNode.replaceChild(span, node);
                }
                return;
            }
            node.childNodes.forEach(child => wrapMatches(child, regex));
        }


        var mobileTitle = "My Status";
        var queryChecklistId = "<%=Request.QueryString["checklistid"]%>";
        var clientLoadBegin = new Date(); //harmless; timespan calc for performance
        var Firm = "<%=QProcess.Configuration.AppSettings.Get("Firm")%>";
        var svrTz = <%=TimeZoneInfo.Local.BaseUtcOffset.TotalMilliseconds + (TimeZoneInfo.Local.IsDaylightSavingTime(QProcess.Session.CurrentSession.UserTimeZone.GetLocalTimeNow()) ? 3600000 : 0)%>;
        var clntTz = new Date().getTimezoneOffset() * 60 * -1000; //Necessary; avoids incorrect conversion of epoch-based datetime values
    </script>
</asp:Content>

<asp:Content ID="nav" runat="server" ContentPlaceHolderID="navContent">
  <div class="nav-scroller bg-white box-shadow text-center text-header">
        <span id="changeReport" style="font-size: 13pt">
            <i class="fa fa-sitemap"></i>
            Change Report
        </span>
        <span id="addTask" style="font-size: 13pt">
            <i class="fa fa-plus green"></i>
            Add Task
        </span>
        <span id="emailComments" style="font-size: 13pt">
            <i class="fa fa-envelope"></i>
            Email
        </span>
        <span id="supervisorPopup" style="font-size: 13pt">
            <i class="fa fa-users"></i>
            Supervisors
        </span>
        <span id="btn-search-tasks-status" style="font-size: 13pt; cursor: pointer; color: #000;">
            <i class="fa fa-search" style="color: #000;"></i>
            Search
        </span>
    </div>
    <!-- Mobile Search/Filter Bar for My Status -->
    <div id="searchBarMobileStatus" class="search-bar-sticky" style="display: none; padding: 8px 0; background: #fff; border-bottom: 1px solid #eee;">
        <div class="container-fluid">
            <div class="input-group mb-2">
                <input id="txtSearchInputMobileStatus" type="text" class="form-control" placeholder="Start typing to search..." />
            </div>
            <div class="d-flex align-items-center mb-2">
                <span style="margin-right: 8px;">From:</span>
                <input type="text" class="form-control form-control-sm" id="txtSearchFromDateMobile" readonly="readonly" style="width: 90px; margin-right: 8px;" />
                <span style="margin-right: 8px;">to</span>
                <input type="text" class="form-control form-control-sm" id="txtSearchToDateMobile" readonly="readonly" style="width: 90px; margin-right: 8px;" />
            </div>
            <div class="d-flex align-items-center justify-content-between mb-2">
                <div>
                    <button class="btn env-specific-btn btn-sm" id="btnTodayMobile" style="margin-right: 4px;">Today</button>
                    <button class="btn env-specific-btn btn-sm" id="btnThisWeekMobile" style="margin-right: 4px;">Week</button>
                    <button class="btn env-specific-btn btn-sm" id="btnThisMonthMobile">Month</button>
                </div>
                <div class="form-check" style="margin-bottom: 0;">
                    <input class="form-check-input" type="checkbox" id="chkIncludeArchiveMobile" />
                    <label class="form-check-label" for="chkIncludeArchiveMobile">Include archived</label>
                </div>
            </div>
            <div class="d-flex align-items-center justify-content-between" style="min-height: 32px;">
                <div id="searchResultsMobileStatus" class="flex-grow-1"></div>
                <div>
                    <button id="btnCloseSearchMobileStatus" class="btn env-specific-btn btn-sm" type="button" title="Close Search">Close</button>
                    <button id="btnResetSearchMobileStatus" class="btn env-specific-btn btn-sm" type="button" title="Reset Search">Reset</button>
                </div>
            </div>
        </div>
    </div>
</asp:Content>

<asp:Content ID="Content1" runat="server" ContentPlaceHolderID="mainContent">
    <select id="ddlReportHeader" class="form-control" style="display: none"></select>
    <%
        var metaItems = new List<string>();
        if (!string.IsNullOrWhiteSpace(ControllersList))
            metaItems.Add("<span class='meta-row' style='display:flex;align-items:center;padding:0 16px;font-size:14px;'><span class='meta-label' style='font-weight:bold;color:#000;margin-right:6px;'>Controllers:</span> <span class='meta-value' style='font-size:14px;'>" + ControllersList + "</span></span>");
        if (!string.IsNullOrWhiteSpace(SupervisorsList))
            metaItems.Add("<span class='meta-row' style='display:flex;align-items:center;padding:0 16px;font-size:14px;'><span class='meta-label' style='font-weight:bold;color:#000;margin-right:6px;'>Supervisors:</span> <span class='meta-value' style='font-size:14px;'>" + SupervisorsList + "</span></span>");
        if (!string.IsNullOrWhiteSpace(InterestedPartiesList))
            metaItems.Add("<span class='meta-row' style='display:flex;align-items:center;padding:0 16px;font-size:14px;'><span class='meta-label' style='font-weight:bold;color:#000;margin-right:6px;'>Interested Parties:</span> <span class='meta-value' style='font-size:14px;'>" + InterestedPartiesList + "</span></span>");
    %>
    <div id="report-meta" style="display: flex; flex-wrap: wrap; align-items: center; justify-content: center; gap: 0; text-align: center;">
        <%= string.Join("<span class='meta-divider' style='color:dimgray;font-weight:bold;font-size:18px;user-select:none;display:flex;align-items:center;padding:0 0 0 0;'>|</span>", metaItems) %>
    </div>
    <div id="status-report"></div>
    <input type="hidden" id="user-name" value="<%= CurrentSession.QUser.FullName %>" />
    <input type="hidden" id="user-id" value="<%= UserId %>" />
    <input type="hidden" id="report-id" value="<%= ReportId %>" />
    <input type="hidden" id="task-id" value="<%= TaskId %>" />
    <input type="hidden" id="is-archive" value="<%= IsArchive %>" />
    <input type="hidden" id="tasks-controlled" value="<%= TasksIControl %>" />
</asp:Content>

<asp:Content ID="script" runat="server" ContentPlaceHolderID="scriptContent">
    <script src="/Scripts/MyStatus.js?v=<%= System.IO.File.GetLastWriteTime(Server.MapPath($"/Scripts/MyStatus.js")).Ticks.ToString() %>"></script>
    <script type="text/javascript">
        let mobileSearchTimeout = null;

        $(function () {
            'use strict';
            var reportId = $("#report-id").val();
            var taskTypes = null;

            $("#changeReport").on("click", function () { $("#ddlReportHeader").click(); });
            Post("../Services/ControlService.asmx/StatusReportHeader_GET", "", function (msg) {
                var rsp = msg.d;
                if (rsp == null || rsp.length == 0) return;

                var ddl = $("#ddlReportHeader");
                var grp = "";
                var prt = 0;

                for (let i = 0; i < rsp.length; i++) {
                    var e = rsp[i];
                    if (parseInt(e.ID) < 0) {
                        if (grp != "") {
                            grp += "</optgroup>";
                            ddl.append(grp);
                        }

                        grp = `<optgroup label="${e.Name}">`;
                        prt = e.ID;
                    } else {
                        grp += `<option report-type="${prt}" value="${e.ID}">${e.Name}</option>`;
                    }
                }

                if (grp != "") {
                    grp += "</optgroup>";
                    ddl.append(grp);
                }

                $('#ddlReportHeader').mobiscroll().select({
                    theme: getMobileOperatingSystem(),
                    display: 'modal'
                });
            });

            $("#ddlReportHeader").on("change", function (e) {
                var opt = $(this);
                if (opt.val() == "0") return;

                if (opt.find("option:selected").attr("report-type") == "-1")
                    window.location = "MobileMyStatus.aspx?ReportID=" + opt.val();
                else {
                    window.location = "MobileInbox.aspx?ReportID=" + opt.val();
                }
            });

            $("#addTask").on("click", myStatusModule.showAddTaskPanel);

            $(document).on("click", "#btnCloseWindow", function (e) {
                slider.toggleClass('open');
            });

            $("#emailComments").on("click", myStatusModule.showEmailCommentsPanel);
            $("#supervisorPopup").on("click", function () {
                myStatusModule.showSupervisorPanel();
                waitForElementToBeVisible("#supervisor-select", function () {
                    $("button[data-role='add-supervisor']").trigger("click");

                    waitForElementToBeVisible("#btnCloseWindow", function () {
                        // Check if supervisors-table has any entries
                        var supervisorsTable = $("#supervisors-table");
                        if (supervisorsTable.length === 0 || supervisorsTable.find("tr").length <= 1) {
                            supervisorsTable.addClass("hidden"); // Hide the table if it is empty or only has the header row
                        }
                    });
                });
            });

            //// Event handler for checkboxes
            //$(document).on("change", "input[data-role='interested-party'], input[data-role='supervisor']", function () {
            //    var checkbox = $(this);
            //    var isChecked = checkbox.is(":checked");
            //    var supervisorId = checkbox.closest("tr").data("id");
            //    var role = checkbox.data("role");

            //    console.log("Checkbox changed:", role, "Supervisor ID:", supervisorId, "Checked:", isChecked);

            //    // Make an AJAX call to save the state
            //    $.ajax({
            //        url: "../Services/ControlService.asmx/SaveSupervisorState",
            //        method: "POST",
            //        data: JSON.stringify({ supervisorId: supervisorId, role: role, isChecked: isChecked }),
            //        contentType: "application/json; charset=utf-8",
            //        dataType: "json",
            //        beforeSend: function (xhr) {
            //            // Include authentication token if needed
            //            var authToken = getAuthToken(); // Implement this function to retrieve the token
            //            if (authToken) {
            //                xhr.setRequestHeader("Authorization", "Bearer " + authToken);
            //            }
            //        },
            //        success: function (response) {
            //            if (response.d) {
            //                console.log("Supervisor state saved successfully.");
            //            } else {
            //                console.log("Failed to save supervisor state.");
            //            }
            //        },
            //        error: function (xhr, status, error) {
            //            console.log("Error saving supervisor state:", error);
            //            console.log("Status:", status);
            //            console.log("Response Text:", xhr.responseText);
            //        }
            //    });
            //});

            // Event handler for adding a supervisor
            $(document).on("click", "button[data-role='add-supervisor']", function () {
                var supervisorName = $("#supervisor-name").val();
                if (!supervisorName) {
                    console.log("Supervisor name is required.");
                    return;
                }

                // Make an AJAX call to add the supervisor
                $.ajax({
                    url: "../Services/ControlService.asmx/AddSupervisor",
                    method: "POST",
                    data: JSON.stringify({ name: supervisorName }),
                    contentType: "application/json; charset=utf-8",
                    dataType: "json",
                    success: function (response) {
                        if (response.d) {
                            console.log("Supervisor added successfully:", response.d);
                            // Append the new supervisor to the table
                            var newSupervisor = response.d;
                            var newRow = `<tr data-id="${newSupervisor.ID}">
                            <td><a href="" data-role="delete-supervisor"><img src="/Images/delete.gif" title="Remove"></a></td>
                            <td data-item="name">${newSupervisor.Name}</td>
                            <td class="text-center"><input data-role="interested-party" type="checkbox"></td>
                            <td class="text-center"><input data-role="supervisor" type="checkbox" checked="checked"></td>
                          </tr>`;
                            $("#supervisors-table tbody").append(newRow);
                        } else {
                            console.log("Failed to add supervisor.");
                        }
                    },
                    error: function (xhr, status, error) {
                        alert('error');
                        console.log("Error adding supervisor:", error);
                        console.log("Status:", status);
                        console.log("Response Text:", xhr.responseText);
                    }
                });
            });
        });

        function waitForElementToBeVisible(selector, callback) {
            var checkVisibility = setInterval(function () {
                if ($(selector).is(':visible')) {
                    clearInterval(checkVisibility);
                    callback();
                }
            }, 100); // Check every 100 milliseconds
        }

        function getAuthToken() {
            // Implement this function to retrieve the authentication token
            // For example, from a cookie or local storage
            return document.cookie.replace(/(?:(?:^|.*;\s*)authToken\s*\=\s*([^;]*).*$)|^.*$/, "$1");
        }

        // Show the search bar
        $('#btn-search-tasks-status').on('click', function () {
            logFeatureUsage('MyStatusSearch', 'mobile');
            $('#searchBarMobileStatus').slideDown(150, function () {
                $('#txtSearchInputMobileStatus').val('').focus();
                $('#searchResultsMobileStatus').html('');
            });
        });

        // Hide the search bar
        $('#btnCloseSearchMobileStatus').on('click', function () {
            $('#searchBarMobileStatus').slideUp(150);
            resetMobileStatusSearch();
        });

        // Reset search
        $('#btnResetSearchMobileStatus').on('click', function () {
            $('#txtSearchInputMobileStatus').val('');
            $('#txtSearchFromDateMobile').val('');
            $('#txtSearchToDateMobile').val('');
            $('#chkIncludeArchiveMobile').prop('checked', false);
            $('#searchResultsMobileStatus').html('');
            resetMobileStatusSearch();
        });

        // Date pickers (using mobiscroll, as in mobile master)
        $('#txtSearchFromDateMobile, #txtSearchToDateMobile').mobiscroll().date({
            theme: getMobileOperatingSystem(),
            display: 'modal',
            onSelect: function () {
                triggerMobileStatusSearch();
            }
        });

        // Quick date buttons
        $('#btnTodayMobile').on('click', function () {
            var today = new Date();
            var dateStr = today.toLocaleDateString('en-US');
            $('#txtSearchFromDateMobile').val(dateStr);
            $('#txtSearchToDateMobile').val(dateStr);
            triggerMobileStatusSearch();
        });
        $('#btnThisWeekMobile').on('click', function () {
            var today = new Date();
            var weekAgo = new Date();
            weekAgo.setDate(today.getDate() - 7);
            $('#txtSearchFromDateMobile').val(weekAgo.toLocaleDateString('en-US'));
            $('#txtSearchToDateMobile').val(today.toLocaleDateString('en-US'));
            triggerMobileStatusSearch();
        });
        $('#btnThisMonthMobile').on('click', function () {
            var today = new Date();
            var monthAgo = new Date();
            monthAgo.setDate(today.getDate() - 30);
            $('#txtSearchFromDateMobile').val(monthAgo.toLocaleDateString('en-US'));
            $('#txtSearchToDateMobile').val(today.toLocaleDateString('en-US'));
            triggerMobileStatusSearch();
        });

        // Include archived checkbox
        $('#chkIncludeArchiveMobile').on('change', function () {
            triggerMobileStatusSearch();
        });

        // Search on input
        $('#txtSearchInputMobileStatus').off('input').on('input', function () {
            if (mobileSearchTimeout) clearTimeout(mobileSearchTimeout);
            mobileSearchTimeout = setTimeout(() => {
                triggerMobileStatusSearch();
            }, 400);
        });


        // Main search trigger
        function triggerMobileStatusSearch() {
            var criteria = $('#txtSearchInputMobileStatus').val();
            var fromDate = $('#txtSearchFromDateMobile').val();
            var toDate = $('#txtSearchToDateMobile').val();
            var includeArchive = $('#chkIncludeArchiveMobile').is(':checked');
            mobileStatusSearch(criteria, fromDate, toDate, includeArchive);
        }

        // Main search function (adapted from Search.js)
        function mobileStatusSearch(criteria, fromDate, toDate, includeArchive) {
            criteria = criteria || "";
            $('#searchResultsMobileStatus').html('<span>Searching...</span>');
            if (!criteria && !fromDate && !toDate && !includeArchive) {
                resetMobileStatusSearch();
                $('#searchResultsMobileStatus').html('');
                return;
            }
            $.ajax({
                url: "../DataService.asmx/SearchMyStatus",
                type: "POST",
                data: JSON.stringify({
                    criteria: criteria,
                    reportId: $("#report-id").val(),
                    logicAndOr: false,
                    includeTask: true,
                    includeItem: false,
                    includeComment: true,
                    includeArchive: includeArchive,
                    fromDate: fromDate,
                    toDate: toDate
                }),
                dataType: "json",
                contentType: "application/json",
                success: function (msg) {
                    var foundIds = msg.d || [];
                    var count = 0;
                    // Show/hide rows in your mobile status report
                    $("#status-report .status-table tr.report-line-content").each(function () {
                        var $row = $(this);
                        var id = $row.data("id");
                        var found = false;
                        for (var i = 0; i < foundIds.length; i++) {
                            if (foundIds[i].Id == id) {
                                found = true;
                                count++;
                                break;
                            }
                        }
                        if (found) {
                            $row.removeClass("filter-hide");
                            highlightSearchResults($row[0], criteria);
                        } else {
                            $row.addClass("filter-hide");
                        }
                    });
                    if (count === 0) {
                        $('#searchResultsMobileStatus').html('<span>No results found.</span>');
                    } else {
                        $('#searchResultsMobileStatus').html(
                            //`<span><i>Search criteria: <b>${criteria}</b>. Tasks Found: <b>${count}</b></i></span>`
                            '<span>Found ' + count + ' task(s).</span>'
                        );
                    }
                },
                error: function () {
                    $('#searchResultsMobileStatus').html('<span class="text-danger">Search failed. Please try again.</span>');
                }
            });
        }

        // Reset: show all rows
        function resetMobileStatusSearch() {
            $("#status-report .status-table tr.report-line-content").show();
            removeHighlighting(document.body);
        }

        $('#btn-search-tasks-status').on('click', function () {
            if ($(this).hasClass('disabled')) {
                // If already open, close the search bar
                $('#searchBarMobileStatus').slideUp(150, () => {
                    $('#btn-search-tasks-status').removeClass('disabled').css('opacity', 1);
                });
                resetMobileStatusSearch();
                return;
            }
            $('#searchBarMobileStatus').slideDown(150, () => {
                $('#txtSearchInputMobileStatus').val('').focus();
                $('#searchResultsMobileStatus').html('');
                $('#btn-search-tasks-status').addClass('disabled').css('opacity', 0.5);
            });
        });

        $('#btnCloseSearchMobileStatus').on('click', function () {
            $('#searchBarMobileStatus').slideUp(150, () => {
                $('#btn-search-tasks-status').removeClass('disabled').css('opacity', 1);
            });
            resetMobileStatusSearch();
        });
    </script>


    <!-- Copyright © 2024 Renegade Swish, LLC -->
</asp:Content>

