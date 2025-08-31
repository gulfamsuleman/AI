<%@ Control Language="C#" AutoEventWireup="true" CodeBehind="ChecklistHistory.ascx.cs" Inherits="QProcess.Controls.Controls_Shared_ChecklistHistory" %>
<%@ Import Namespace="QProcess.Repositories" %>
<%@ Register TagPrefix="mytasks" TagName="ItemBase" Src="~/Controls/Shared/ItemBase.ascx" %>
<%@ Register TagPrefix="QPH" Namespace="QProcess.Helpers" Assembly="QProcess" %>

<div id="checklistHistoryDiv" class="active-checklist collapsible-item row" data-collapse-state="collapsed" data-status="<%=CompletionCssClass %>" data-role="checklist"
    data-unique-id="<%=Checklist.UniqueId %>"
    data-identifier="<%=Checklist.Identifier %>"
    data-task-stage="<%=Checklist.TaskStage %>"
    data-checklist-id="<%=Checklist.ChecklistId %>">
    <input class="is-daily" type="hidden" value="<%= IsDaily %>" />
    <style>
        .table-cleanup {
            border-collapse: collapse;
            border: 0;
        }

            .table-cleanup td {
                padding: 4px 8px;
            }

            .table-cleanup .right-align {
                text-align: right;
                padding-right: 10px;
            }

        .table-container thead th {
            text-align: center !important;
        }

        .table-container tbody td {
            text-align: left;
        }

        .modal-content {
            max-width: 100%;
            width: auto;
            overflow: hidden; /* Prevent overflow */
        }

        #deadlineHistoryTable, #changeHistoryTable, #commentHistoryTable {
            width: 100%;
            table-layout: fixed;
            overflow-x: auto;
        }

        @media (min-width: 892px) {
            .modal-dialog {
                width: 90%;
                margin: 30px auto;
            }
        }

        pre {
            white-space: pre-wrap;
            word-wrap: break-word;
            max-height: 300px;
            overflow-y: scroll;
        }

        pre, table {
            font-family: Tahoma, Verdana;
            font-size: 10pt;
        }

        .tab {
            display: inline-block;
            width: 2em; /* Adjust the width as needed */
        }

        .bold {
            font-weight: bold;
        }

        b {
            color: black !important;
        }

        .table-cleanup td {
            background-color: transparent !important;
            border: none !important;
        }

        table, tr {
            cursor: default;
        }
    </style>
    <script>
        // On doc ready, do the following
        $(document).ready(function () {
            let checklistId = $("#checklistHistoryDiv").data("checklistId");
            let uniqueId = $("#checklistHistoryDiv").data("uniqueId");

            Promise.all([
                loadDeadlineHistory(checklistId, uniqueId),
                loadChangeHistory(checklistId)
            ]).then(([deadlineData, changeData]) => {
                populateDeadlineHistoryGrid(deadlineData);
                populateChangeHistoryGrid(changeData);
            }).catch(error => {
                console.error("Error loading history data:", error);
            });
        });
        function loadCommentHistory(checklistId) {
            return new Promise((resolve, reject) => {
                $.ajax({
                    url: "../DataService.asmx/GetCommentHistoryList",
                    type: "POST",
                    data: JSON.stringify({ checklistId: checklistId }),
                    dataType: "json",
                    contentType: "application/json",
                    success: function (response) {
                        var data = response.d;
                        if (data && Array.isArray(data)) {
                            resolve(data);
                        } else {
                            reject("Unexpected data format");
                        }
                    },
                    error: function (error) {
                        reject("AJAX error: " + error);
                    }
                });
            });
        }

        function loadDeadlineHistory(checklistId, uniqueId) {
            return new Promise((resolve, reject) => {
                $.ajax({
                    url: "../DataService.asmx/GetDeadlineHistoryList",
                    type: "POST",
                    data: JSON.stringify({ checklistId: checklistId, uniqueId: uniqueId }),
                    dataType: "json",
                    contentType: "application/json",
                    success: function (response) {
                        var data = response.d;
                        if (data && Array.isArray(data)) {
                            resolve(data);
                        } else {
                            reject("Unexpected data format");
                        }
                    },
                    error: function (error) {
                        reject("AJAX error: " + error);
                    }
                });
            });
        }

        function loadChangeHistory(checklistId) {
            return new Promise((resolve, reject) => {
                $.ajax({
                    url: "../DataService.asmx/GetChangeHistoryList",
                    type: "POST",
                    data: JSON.stringify({ checklistId: checklistId }),
                    dataType: "json",
                    contentType: "application/json",
                    success: function (response) {
                        var data = response.d;
                        if (data && Array.isArray(data)) {
                            resolve(data);
                        } else {
                            reject("Unexpected data format");
                        }
                    },
                    error: function (error) {
                        reject("AJAX error: " + error);
                    }
                });
            });
        }


        function populateGrids(values) {
            let dataTable = `
        <div style="text-align: center;">
            <label for="commentHistoryTable" style="font-size: 15pt"><b>Comment History</b></label>
            <table id="commentHistoryTable" class="display compact" style="width:100%"></table><br>
        </div>`;


            $("#commmentsHistoryTable").html(dataTable);

            var newTable = new DataTable("#commentHistoryTable", {
                dom: '<"top"B>ltp',
                paging: false,
                lengthChange: false,
                searching: true,
                autoFill: false,
                columnDefs: [
                    { targets: 0, orderable: true, width: '78%' },
                    { targets: 1, orderable: true, width: '10%' },
                    { targets: 2, orderable: true, width: '12%' }
                ],
                responsive: true,
                data: values,
                columns: [
                    { title: "Comment", data: 'Comments' },
                    { title: "Date", data: 'CommentDt' },
                    { title: "Author", data: 'Initials' }
                    //{ title: "Controllers", data: 'Controllers' },
                    //{ title: "Report", data: 'StatusReportString' }
                ],
                order: [[1, 'asc']],
                drawCallback: function () {
                    $('#commentHistoryTable td').each(function () {
                        var fullText = $(this).text();
                        $(this).attr('title', fullText);
                    });
                }
            });

            //$("#commmentsHistoryProgress").hide();

            $('#commmentsHistoryTable table td').each(function () {
                var fullText = $(this).text();
                $(this).attr('title', fullText);
            });
        }

        function populateDeadlineHistoryGrid(values) {
            let dataTable = `
    <div style="text-align: center;">
        <label for="deadlineHistoryTable" style="font-size: 15pt"><b>Deadline History</b></label>
        <table id="deadlineHistoryTable" class="display compact" style="width:100%"></table><br>
    </div>`;

            $("#deadlinesHistoryTable").html(dataTable);

            if ($.fn.DataTable.isDataTable("#deadlineHistoryTable")) {
                $('#deadlineHistoryTable').DataTable().destroy();
            }

            setTimeout(() => {
                var newTable = new DataTable("#deadlineHistoryTable", {
                    dom: '<"top"B>ltp',
                    paging: false,
                    lengthChange: false,
                    searching: true,
                    autoFill: false,
                    columnDefs: [
                        { targets: 0, orderable: true, width: '30%' },
                        { targets: 1, orderable: true, width: '8%' },
                        { targets: 2, orderable: true, width: '8%' },
                        { targets: 3, orderable: true, width: '8%' },
                        { targets: 4, orderable: true, width: '10%' },
                        { targets: 5, orderable: true, width: '8%' },
                        { targets: 6, orderable: true, width: '10%' },
                        { targets: 7, orderable: true, width: '8%' },
                        { targets: 8, orderable: true, width: '10%' }
                    ],
                    responsive: true,
                    data: values,
                    columns: [
                        { title: "Comment", data: 'Comment' },
                        {
                            title: "Due (Old)",
                            data: 'OrigDueTime',
                            render: function (data, type, row) {
                                if (type === 'display') {
                                    return row.OrigDueTimeStr || '';
                                }
                                if (type === 'sort') {
                                    return parseDotNetDate(data);
                                }
                                return data;
                            }
                        },
                        {
                            title: "Due",
                            data: 'DueTime',
                            render: function (data, type, row) {
                                if (type === 'display') {
                                    return row.DueTimeStr || '';
                                }
                                if (type === 'sort') {
                                    return parseDotNetDate(data);
                                }
                                return data;
                            }
                        },
                        {
                            title: "Req.",
                            data: 'RequestDate',
                            render: function (data, type, row) {
                                if (type === 'display') {
                                    return row.RequestDateStr || '';
                                }
                                if (type === 'sort') {
                                    return parseDotNetDate(data);
                                }
                                return data;
                            }
                        },
                        { title: "Req. By", data: 'Requestor' },
                        {
                            title: "App.",
                            data: 'ApprovedDate',
                            render: function (data, type, row) {
                                if (type === 'display') {
                                    return row.ApprovedDateStr || '';
                                }
                                if (type === 'sort') {
                                    return parseDotNetDate(data);
                                }
                                return data;
                            }
                        },
                        { title: "App. By", data: 'Approver' },
                        {
                            title: "Completed",
                            data: 'CompletedDate',
                            render: function (data, type, row) {
                                if (type === 'display') {
                                    return row.CompletedDateStr || '';
                                }
                                if (type === 'sort') {
                                    return parseDotNetDate(data);
                                }
                                return data;
                            }
                        },
                        { title: "Done By", data: 'CompletedBy' }
                    ],
                    order: [[3, 'asc']], // Default sorting by the "Req." column
                    drawCallback: function () {
                        $('#deadlineHistoryTable td').each(function () {
                            var fullText = $(this).text();
                            $(this).attr('title', fullText);  // Set title for tooltip on hover

                            // Apply ellipsis styling to overflow text
                            $(this).css({
                                'white-space': 'nowrap',
                                'overflow': 'hidden',
                                'text-overflow': 'ellipsis'
                            });
                        });
                    }
                });
            }, 0);
        }

        // Helper function to parse .NET serialized dates
        function parseDotNetDate(dotNetDate) {
            if (!dotNetDate) return -Infinity;
            const match = /\/Date\((\d+)\)\//.exec(dotNetDate);
            return match ? parseInt(match[1], 10) : -Infinity;
        }

        function populateChangeHistoryGrid(values) {
            const tableContainer = $("#changesHistoryTable");

            // Ensure the container exists
            if (!tableContainer.length) {
                console.error("Element #changesHistoryTable does not exist in the DOM.");
                return;
            }

            // Update the table container with new HTML
            let dataTable = `
        <div style="text-align: center;">
            <label for="changeHistoryTable" style="font-size: 15pt"><b>Change History</b></label>
            <table id="changeHistoryTable" class="display compact" style="width:100%"></table><br>
        </div>`;

            tableContainer.html(dataTable);

            // Destroy the existing DataTable instance if it exists
            if ($.fn.DataTable.isDataTable("#changeHistoryTable")) {
                $('#changeHistoryTable').DataTable().destroy();
            }

            // Reinitialize the DataTable after ensuring the DOM is updated
            setTimeout(() => {
                const newTable = new DataTable("#changeHistoryTable", {
                    dom: '<"top"B>ltp',
                    paging: false,
                    lengthChange: false,
                    searching: true,
                    autoFill: false,
                    columnDefs: [
                        { targets: 0, orderable: true, width: '43%' },
                        { targets: 1, orderable: true, width: '6%' },
                        { targets: 2, orderable: true, width: '12%' },
                        { targets: 3, orderable: true, width: '6%' },
                        { targets: 4, orderable: true, width: '10%' },
                        { targets: 5, orderable: true, width: '6%' },
                        { targets: 6, orderable: true, width: '17%' }
                    ],
                    responsive: true,
                    data: values,
                    columns: [
                        { title: "Change", data: 'ChangeRequest' },
                        {
                            title: "Req.",
                            data: null,
                            render: function (data, type, row) {
                                if (type === 'display') {
                                    return row.RequestDateStr;
                                }
                                if (type === 'sort') {
                                    return row.RequestDate ? new Date(row.RequestDate).getTime() : 0; // Sort by the DateTime value
                                }
                                return row.RequestDate;
                            }
                        },
                        { title: "Req. By", data: 'Requestor' },
                        { title: "Status", data: 'Result' },
                        { title: "By", data: 'ResultPerson' },
                        {
                            title: "Date",
                            data: null,
                            render: function (data, type, row) {
                                if (type === 'display') {
                                    return row.ResultDateStr;
                                }
                                if (type === 'sort') {
                                    return row.ResultDate ? new Date(row.ResultDate).getTime() : -Infinity; // Sort null values to the top
                                }
                                return row.ResultDate;
                            }
                        },
                        { title: "Comment", data: 'Comment' },
                    ],
                    order: [[1, 'asc']],
                    drawCallback: function () {
                        $('#changeHistoryTable td').each(function () {
                            const fullText = $(this).text();
                            $(this).attr('title', fullText);

                            // Apply ellipsis styling to overflow text
                            $(this).css({
                                'white-space': 'nowrap',
                                'overflow': 'hidden',
                                'text-overflow': 'ellipsis'
                            });
                        });
                    }
                });
            }, 0); // Use a timeout of 25 to ensure DOM updates are complete
        }
    </script>
    <table class="table-cleanup">
        <tr>
            <td class="right-align">Controllers:</td>
            <td><%=Checklist.Controllers %></td>
        </tr>
        <% if (!String.IsNullOrEmpty(Checklist.StatusReportString))
            { %>
        <tr>
            <td class="right-align">Status Reports:</td>
            <td><%=Checklist.StatusReportString %></td>
        </tr>
        <% }%>
        <tr>
            <td class="right-align">Assigned To:</td>
            <td><%=Checklist.Assignees %></td>
        </tr>
        <tr>
            <td class="right-align">Created:</td>
            <td><%= Checklist.CreateDate == DateTime.MinValue ? "" : Checklist.CreateDate.ToShortDateString() %></td>
        </tr>
        <%if (Checklist.RecurranceSchedule != "One Time")
            {%>
        <tr>
            <td class="right-align">Schedule:</td>
            <td><%=Checklist.RecurranceSchedule %></td>
        </tr>
        <% } %>
    </table>
    <div style="text-align: center;">
        <label style="font-size: 15pt;"><b>Comment History</b></label>
    </div>
    <asp:Literal ID="CommentHistory" runat="server" />

    <%--    <div class="table-container">
        <asp:Literal ID="Literal1" runat="server" />
        <div id="commmentsHistoryProgress">
            <img src="images/searching.gif" />
            Loading...please wait
        </div>
        <div id="commmentsHistoryTable"></div>
    </div>--%>

    <div class="table-container">
        <%--        <div id="deadlineHistoryProgress">
            <img src="images/searching.gif" />
            Loading...please wait
       
        </div>--%>
        <div id="deadlinesHistoryTable"></div>
    </div>

    <div class="table-container">
        <%--        <div id="changeHistoryProgress">
            <img src="images/searching.gif" />
            Loading...please wait
       
        </div>--%>
        <div id="changesHistoryTable"></div>
    </div>
</div>
<QPH:DOMInjector runat="server" InjectInto="ScriptContent">
    <script src="Scripts/Checklist.js?v=16"></script>
</QPH:DOMInjector>
