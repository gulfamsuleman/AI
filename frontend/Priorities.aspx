<%@ Page Language="C#" AutoEventWireup="true" EnableSessionState="True" CodeBehind="Priorities.aspx.cs" Inherits="QProcess.Priorities" MasterPageFile="Site.master" %>

<%@ Register TagPrefix="priority" TagName="PriorityList" Src="~/Controls/Priorities/PriorityList.ascx" %>
<%@ Import Namespace="QProcess.Extensions" %>

<asp:Content ID="Content1" runat="server" ContentPlaceHolderID="HeadContent">
    <link href="Content/Priorities.css?v=<%=System.IO.File.GetLastWriteTime(Server.MapPath("Content/Priorities.css"))%>" rel="stylesheet" />
    <link href="Content/jquery.timepicker.css?<%= System.IO.File.GetLastWriteTime(Server.MapPath("Content/jquery.timepicker.css")).Ticks.ToString() %>" rel="stylesheet" />
    <style>
        #priorities-panel {
            font-size: <%=PriorityFont%>pt;
        }

        #userTable .btn-sm {
            padding: 0 2px 0 2px;
        }

        div.override-hidden {
			display: block !important;
			color: black;
			visibility: visible !important;
		}
		div.task-comment {
			cursor: pointer;
		}
		tr.webview div.tab-1 {
			padding-left: 30px;
		}
		tr.webview div.tab-2 {
			padding-left: 60px;
		}
		tr.webview div.tab-3 {
			padding-left: 90px;
		}
		.draggable {
			margin-left: 5px;
			cursor: move;

			display: inline-block;
			font: normal normal normal 10px FontAwesome;
			font-size: inherit;
			text-rendering: auto;
			-webkit-font-smoothing: antialiased;
			-moz-osx-font-smoothing: grayscale;
		}
		.draggable:before {
			content: "\f047";
		}
		.yellow-background {
			background-color: yellow;
		}
    @media print {
        #userTable .btn, .expand-collapse-placeholder, .expandCollapseAllBtn
        {
            display: none !important;
        }
    }

    .expand-collapse-placeholder {
        display: inline-flex;
        align-items: center;
        justify-content: center;
    }

    .priority-comment .comment-line:hover {
        text-decoration: underline;
        cursor: pointer !important;
    }
	</style>
</asp:Content>

<asp:Content ID="Content2" runat="server" ContentPlaceHolderID="ScriptContent">
    <script src="Scripts/Priorities.js?v=<%= System.IO.File.GetLastWriteTime(Server.MapPath("Scripts/Priorities.js")).Ticks.ToString() %>"></script>

    <script src="Scripts/jquery.timepicker.js?v=<%= System.IO.File.GetLastWriteTime(Server.MapPath("Scripts/jquery.timepicker.js")).Ticks.ToString() %>"></script>
    <script src="Scripts/common.js"></script>
    <%--added by venkat 09/22/2017--%>
    <script>
        function moveDeleteRowToEnd(table) {
            var $table = $(table);
            var $deleteRow = $table.find('tr[data-role="delete-row"]');
            if ($deleteRow.length) {
                $deleteRow.appendTo($table.find('tbody'));
            }
        }

        function checkchars(tb) {
            if (tb.value.length > 1499) {
                tb.value = tb.value.substring(0, 1499)
            }
        }
        document.addEventListener("DOMContentLoaded", function (event) {
            var scrollpos = sessionStorage.getItem('scrollpos');
            if (scrollpos) {
                $("#site-main").scrollTop(scrollpos);
                sessionStorage.removeItem('scrollpos');
            }
        });

        window.addEventListener("beforeunload", function (e) {
            sessionStorage.setItem('scrollpos', $("#site-main").scrollTop());
        });

        prioritiesModule.isTouch = <%= (QProcess.Extensions.ExtensionMethods.IsMobileBrowser(Request) || QProcess.Session.CurrentSession.ForceMobile(Request)).ToString().ToLowerInvariant()%>

            document.addEventListener("DOMContentLoaded", function () {
                // Restore scroll position
                var scrollpos = sessionStorage.getItem('scrollpos');
                if (scrollpos) {
                    $("#site-main").scrollTop(scrollpos);
                    sessionStorage.removeItem('scrollpos');
                }

                // Table sorting and drag-and-drop logic
                const tables = document.querySelectorAll('table[data-table="task-table"]');

                tables.forEach(table => {
                    const listId = table.closest('tr').getAttribute('data-list-id');
                    const sortAscButton = document.getElementById(`sort-asc-${listId}`);
                    const sortDescButton = document.getElementById(`sort-desc-${listId}`);

                    function parseDate(dateString) {
                        if (!dateString) return new Date(0);
                        const cleanedDate = dateString.replace("Due", "").trim();
                        const [month, day, year] = cleanedDate.split("/");
                        return new Date(`${year}-${month}-${day}`);
                    }

                    function isCompletedRow(row) {
                        return row.getAttribute("data-priority") === "-1";
                    }

                    function updatePriorityNumbers(rows) {
                        let priority = 1;
                        rows.forEach(row => {
                            const priorityCell = row.querySelector("td.priority-col");
                            if (priorityCell) {
                                if (!isCompletedRow(row)) {
                                    row.setAttribute("data-priority", priority);
                                    // Update the cell content to match the new priority
                                    priorityCell.innerHTML =
                                        '<span class="hidden data-label">Priority</span>' +
                                        '<span class="nbr">' + priority + '</span> ' +
                                        '<span class="draggable" data-role="dragndrop-dragpoint"></span>';
                                    priority++;
                                } else {
                                    row.setAttribute("data-priority", "-1");
                                    priorityCell.innerHTML =
                                        '<span class="hidden data-label">Priority</span>' +
                                        '<span class="nbr">&nbsp;</span> ' +
                                        '<span class="draggable" data-role="dragndrop-dragpoint"></span>';
                                }
                            }
                        });
                    }

                    function sortTable(ascending) {
                        const rows = Array.from(table.querySelectorAll("tbody tr[data-id]"))
                            .filter(row => {
                                const id = row.getAttribute("data-id");
                                // Only include real task rows (not header, not delete row, not null/empty)
                                return id && id !== "-1";
                            });

                        // Separate incomplete and completed rows
                        const incompleteRows = rows.filter(row => !isCompletedRow(row));
                        const completedRows = rows.filter(row => isCompletedRow(row));

                        // Sort only incomplete rows by due date
                        incompleteRows.sort((a, b) => {
                            const dueA = a.querySelector("[data-column='due']");
                            const dueB = b.querySelector("[data-column='due']");

                            if (!dueA || !dueB) return 0;

                            const dateA = parseDate(dueA.textContent.trim());
                            const dateB = parseDate(dueB.textContent.trim());

                            return ascending ? dateA - dateB : dateB - dateA;
                        });

                        const tbody = table.querySelector("tbody");

                        // Append incomplete rows first, then completed rows
                        [...incompleteRows, ...completedRows].forEach(row => tbody.appendChild(row));

                        updatePriorityNumbers([...incompleteRows, ...completedRows]);

                        saveNewOrder([...incompleteRows, ...completedRows]);
                        moveDeleteRowToEnd(table);
                    }

                    if (!window.mainTaskTableSort) {
                        window.mainTaskTableSort = sortTable;
                    }

                    function saveNewOrder(rows) {
                        const order = rows.map(row => ({
                            TaskId: row.getAttribute("data-id"),
                            DisplayOrder: Array.from(rows).indexOf(row) + 1
                        }));

                        fetch("../DataService.asmx/SaveEntirePriorityOrder", {
                            method: "POST",
                            headers: { "Content-Type": "application/json" },
                            body: JSON.stringify({
                                order,
                                setId: document.getElementById("set-id").value,
                                userId: document.getElementById("set-locked-by-id").value
                            })
                        }).catch(error => {
                            console.error("Error saving order:", error);
                        });
                    }

                    function handleRowDragAndDrop() {
                        const rows = Array.from(table.querySelectorAll("tbody tr[data-id]"))
                            .filter(row => {
                                const id = row.getAttribute("data-id");
                                // Only include real task rows (not header, not delete row, not null/empty)
                                return id && id !== "-1";
                            });
                        rows.forEach(row => {
                            row.addEventListener("dragend", () => {
                                const updatedRows = Array.from(table.querySelectorAll("tbody tr[data-id]"));
                                updatePriorityNumbers(updatedRows); // Update priority numbers after drag-and-drop
                                saveNewOrder(updatedRows); // Save the new order
                            });
                        });
                    }

                    // Event listeners for sorting
                    if (sortAscButton) sortAscButton.addEventListener("click", () => sortTable(true));
                    if (sortDescButton) sortDescButton.addEventListener("click", () => sortTable(false));

                    // Enable drag-and-drop tracking
                    handleRowDragAndDrop();

                    // Expose sortTable for modal use (optional, if you want to call it directly)
                    table.sortTable = sortTable;
                });

                // Modal logic for Sort Priorities
                const sortModal = document.getElementById("sort-confirm-modal");
                const sortYes = document.getElementById("sort-confirm-yes");
                const sortNo = document.getElementById("sort-confirm-no");
                const sortBtn = document.querySelector('button[data-role="sort-priorities"]');

                if (sortBtn && sortModal && sortYes && sortNo) {
                    sortBtn.addEventListener("click", function () {
                        sortModal.style.display = "flex";
                    });

                    sortNo.addEventListener("click", function () {
                        sortModal.style.display = "none";
                    });

                    sortYes.addEventListener("click", function () {
                        if (window.mainTaskTableSort) {
                            window.mainTaskTableSort(true); // true = ascending
                        }
                        sortModal.style.display = "none";
                    });
                }
            });

    </script>
</asp:Content>

<asp:Content ID="Content3" runat="server" ContentPlaceHolderID="MainContent">
    <div id="priorities-panel">
        <% if (UsesPriorities)
            { %>
        <div id="priorities-toolbar" class="row clearfix">
            <div class="col-xs-4 priorities-title">Priorities: <span id="label-name"><%= Info.LabelName %></span></div>
            <div class="col-xs-8 text-right">
                <button data-role="sort-priorities" class="btn btn-sm btn-default">
                    <img heigh="16px" width="16" alt="" src="/Images/Nags/up.png">
                    Prioritize By Date
                </button>
                <% if (!SetLocked)
                    { %>
                <button data-role="print-priorities" class="btn btn-sm btn-default">
                    <img alt="" src="/Images/print.gif" />
                    Print Priorities</button>
                <button data-role="email-priorities" class="btn btn-sm btn-default">
                    <img alt="" src="/Images/inbox.gif" />
                    Email Priorities</button>
                <% if (ShowComments)
                    { %>
                <button data-role="hide-comments" class="btn btn-sm btn-default"><i class="fa fa-caret-up" style="color: green;"></i>Hide Comments</button>
                <button data-role="show-comments" class="btn btn-sm btn-default hidden"><i class="fa fa-caret-down" style="color: green;"></i>Show Comments</button>
                <% }
                else
                { %>
                <button data-role="hide-comments" class="btn btn-sm btn-default hidden"><i class="fa fa-caret-up" style="color: green;"></i>Hide Comments</button>
                <button data-role="show-comments" class="btn btn-sm btn-default"><i class="fa fa-caret-down" style="color: green;"></i>Show Comments</button>
                <% } %>
                <% if (!Info.IsSingleUserList && Info.IsMyList && Info.IsSupervisor)
                    { %>
                <button data-role="add-names" class="btn btn-sm btn-default"><i class="fa fa-users"></i>Add Names</button>
                <% } %>
                <button data-role="create-list" class="btn btn-sm btn-default"><i class="fa fa-plus" style="color: green;"></i>Create Priority List</button>
                <% if (Info.IsMyList && !Info.IsDefaultList)
                    {
                        if (Info.IsSingleUserList)
                        { %>
                <button data-role="default-list" class="btn btn-sm btn-default"><i class="fa fa-check" style="color: green;"></i>Set Default List</button>
                <% } %>
                <button data-role="delete-list" class="btn btn-sm btn-default"><i class="fa fa-times" style="color: red;"></i>Delete Priority List</button>
                <% } %>
                <% } %>

                <% if (Info.IsSupervisor)
                    { %>
                <button class="btn btn-default btn-sm" onclick="prioritiesModule.GetPriorityScheduleReport();">Priority Scheduling</button>
                <% } %>
                <button data-role="switch-list" class="btn btn-sm btn-default"><i class="fa fa-star" style="color: #F6B200;"></i>Switch Priority Lists</button>
                <% if (!SetLocked)
                    { %>
                <button data-role="change-fonts" class="btn btn-sm btn-default"><i class="fa fa-font"></i>Fonts</button>

                <% if (!Info.IsSingleUserList && Info.IsMyList)
                    { %>
                <% if (Info.IsSupervisor)
                    { %>
                <span id="expand-collapse">
                    <a data-role="collapse-all">
                        <img id="Img2" src="/Images/minus.gif" runat="server" /></a>
                    <a data-role="expand-all">
                        <img id="Img1" src="/Images/plus.gif" runat="server" /></a>
                </span>
                <% } %>
                <% } %>
                <div id="timer" class="red italic">Session will timeout in <span id="time"></span></div>
                <% } %>
            </div>
        </div>
        <% } %>
        <div id="priority-lists">
            <div id="priority-lists-center">
                <% if (!SetLocked)
                    { %>
                <table id="userTable" <%= !Info.IsSingleUserList ? "data-role='dragndrop-reorderable'" : ""  %>
                    data-table="user-table" style="width: 1000px; margin-left: auto; margin-right: auto; display: block;">
                    <priority:PriorityList ID="PriorityListControl" runat="server" />
                    <tr data-id="-1" data-role="delete-row" class="delete-row hidden">
                        <td class="recycle-large" style="line-height: 100px; background: transparent url('images/recycle.jpg') left center no-repeat; min-width: 200px;">&nbsp;</td>
                    </tr>
                </table>
                <% }
                else
                { %>
                <div class="center">
                    <% if (UserId == Info.LockedByUserId)
                        { %>
                    <span class="red bold">Priority list locked by you in a different window. Please only use one window at a time.</span>
                    <% }
                    else
                    { %>
                    <span class="red bold">Priority list locked by <%=Info.LockedByUserName %>.</span>
                    <br />
                    <br />
                    <button data-role="open-message" class="btn btn-sm btn-default"><i class="fa fa-envelope"></i>Send Message</button>
                    <% } %>
                </div>
                <% } %>
            </div>
            <div id="prioritySchedule" style="width: 400px; margin-left: 450px;">
                <%-- added by venkat on 09/20/2017--%>
            </div>
        </div>
        <%-- <div  id="prioritySchedule" style="width:400px;margin-left:450px;"> </div>added by venkat on 09/20/2017--%>





        <div class="hidden" id="comment-panel">
            <textarea style="width: 100%; color: red;" id="taskComments" onkeyup="checkchars(this)" data-role="comment"></textarea>
            <div data-role="comment-buttons">
                <input name="browse" id="browse" style="display: none;" onclick="event.cancelBubble=true;" type="file">
                <button class="btn btn-default btn-sm" onclick="prioritiesModule.saveComment();">Save</button>
                <button class="btn btn-default btn-sm" onclick="prioritiesModule.cancelComment();">Cancel</button>
            </div>
            <input type="hidden" id="acid" value="" />
        </div>
        <div class="hidden" id="timeout-panel">
            <br />
            <br />
            <span class="red bold">Your session has timed out due to inactivity.</span>
            <br />
            <br />
            <button onclick="window.location.reload()" class="btn btn-sm btn-default"><i class="fa fa-envelope"></i>Start New Session</button>
        </div>
        <input id="font-size" type="hidden" value="<%= PriorityFont %>" />
        <input id="set-id" type="hidden" value="<%= SetId %>" />
        <input id="set-locked" type="hidden" value="<%= SetLocked %>" />
        <input id="set-locked-by-id" type="hidden" value="<%= Info.LockedByUserId %>" />
        <input id="set-locked-by-name" type="hidden" value="<%= Info.LockedByUserName %>" />
        <input type="hidden" id="app-name" value="<%= QProcess.Configuration.AppSettings.AppName %>" />
        <input type="hidden" id="initials" value="<%= Initials %>" />
        <div id="error" style="display: none;"></div>
        <div id="err" style="width: 1000px; height: 500px; display: none;"></div>
        <!-- Sort Priorities Confirmation Modal -->
        <div id="sort-confirm-modal" class="modal" style="display: none; position: fixed; left: 0; top: 0; width: 100vw; height: 100vh; background: rgba(0,0,0,0.3); z-index: 9999; align-items: center; justify-content: center;">
            <div style="background: #fff; padding: 24px; border-radius: 6px; max-width: 400px; margin: auto; box-shadow: 0 2px 8px rgba(0,0,0,0.2);">
                <div style="margin-bottom: 16px;">
                    <strong>
                        <span style="color: black;">Warning: </span>
                        <span class="red">
                            Priority lists are for communicating to your supervisor what your most important project is. This could be the one due tomorrow or the one due next week that requires significant effort. Priorities are not solely based on due dates… 
                        </span>
                        <span style="color: black;">
                            SO by pushing this button and sorting by "due date" your priorities will reorder by the closest due date which may or may not be an accurate reflection of what you should be prioritizing. You can reorder at any time by manually clicking and dragging each task.
                        </span>
                        <br /><br />
                        <span style="color: black;">
                            Do you still want to re-order this list by deadline?
                        </span>
                    </strong>
                </div>
                <div class="text-right">
                    <button id="sort-confirm-yes" class="btn btn-sm btn-primary">Yes</button>
                    <button id="sort-confirm-no" class="btn btn-sm btn-default">No</button>
                </div>
            </div>
        </div>

    </div>

    <menu id="priority-menu" type="context" style="display: none" class="showcase">
        <command label="Add Tasks" onclick="prioritiesModule.addTasks()" icon="fa fa-plus" />
        <command label="Clear List" onclick="prioritiesModule.clearList()" icon="fa fa-reply" />
        <command label="Email" onclick="prioritiesModule.openEmailPrioritiesModal()" icon="fa fa-envelope" />

        <hr />
        <command label="View Status Report" onclick="prioritiesModule.viewStatusReport()" icon="fa fa-user" />
    </menu>

    <!-- Copyright © 2024 Renegade Swish, LLC -->
</asp:Content>

