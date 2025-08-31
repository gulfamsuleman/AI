<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="MobilePriorities.aspx.cs" Inherits="QProcess.Mobile.MobilePriorities" MasterPageFile="Mobile.master" %>

<%@ Register TagPrefix="priority" TagName="PriorityList" Src="~/Controls/Priorities/PriorityList.ascx" %>

<asp:Content ID="head" runat="server" ContentPlaceHolderID="headContent">	
	<link href="../Content/Priorities.css?v=<%=System.IO.File.GetLastWriteTime(Server.MapPath("Content/Priorities.css"))%>" rel="stylesheet" />
	<style type="text/css">
		button[data-role=change-fonts]{
			display: none;
		}
		.text-header {
			height: 10px;
		}
		.fa-gear {
			float: right;
			font-size: 20pt;
			margin-right: 20px;
			margin-top: 10px;
		}
		#priorities-toolbar {
			margin-top: 0;
			padding-top: 0;
			padding-bottom: 0;
		}
		.buttons button {
			width: 100%;
			margin: 4px 0;
			background-color: white;
			border: 1px solid #cccccc;
		}
		#timer {
			margin-top: -20px;
			text-align: right;
			padding-right: 10px;
		}
		table[data-table=task-table] { margin-bottom: 0;}
		table[data-table=task-table] thead { display: none; }
		table[data-table=task-table] tbody tr td:first-child {
			background-color: #D4D0C8;
			border-top-left-radius: 5px;
			border-top-right-radius: 5px;
		}
		table[data-table=task-table] tbody tr {
	        border: 1px solid #ccc;
			border-radius: 5px;
			margin-bottom: 10px;
			display: block;
			padding: 1px;
        }
		table[data-table=task-table] tbody tr.hidden {
	        display: none;
        }
		table[data-table=task-table] tbody tr td {
	        display: block;
			width: 100% !important;
			border: 0 !important;
			background-color: #ffffed;
			text-align: left !important;
			padding: 5px;
        }
		table[data-table=task-table] tbody tr:last-child { margin-bottom: 0 }
		#priority-list { margin-bottom: 16px; }
		#priority-lists-center > table > tbody > tr {
			 display: table-row !important; 
			 padding-bottom: 0; 
		}
		#priority-lists-center > table table > tbody {
			background: #fff;
		}
		#priority-lists-center { padding: 10px; }
        span.data-label:not(.priority-col span.hidden.data-label) {
            display: block !important;
            visibility: visible !important;
            font-weight: bold;
        }
		div.priorities-title {
			padding-left: 10px;
		}
		#email-priority-list-panel {
			background-color: #fff;
		}
		div.additional-recipients {
			float: none !important;
		}
		div.additional-recipients select {
			width: calc(100% - 60px) !important;
			display: inline-block;
		}
		#include-comments > span { display: block; }
		#include-comments > span:nth-child(2) { margin-left: -13px; }
		#comments-since { width: 88px; padding-left: 0; padding-right: 0; }

		.email-add-button {
			position: initial;
			vertical-align: baseline;
		}
		hr { margin: 8px 0; }

    	hr {
    		margin: 8px 0;
    	}

    	span.actions {
    		float: right;
    		font-size: 15pt;
    	}

    	.priority-card {
    		border: 1px solid #ccc;
    		margin-top: 10px;
    		border-radius: 5px;
    	}

    	.priority-card-header {
    		background-color: #ebebeb;
    		padding: 8px;
    		border-radius: 5px;
    	}

    		.priority-card-header h4 {
    			margin-right: 50px;
    			font-size: 16pt;
    		}

    	.priority-section {
    		padding: 8px;
    	}

    		.priority-section b {
    			display: block;
    			margin-bottom: 3px;
    		}

    	.move-cursor td:first-child {
    		touch-action: none;
    	}

    	i.fa.fa-arrows-v {
    		height: 21px;
    		width: 21px;
    		border: 1px solid rgb(192,185,171);
    		border-radius: 3px;
    		text-align: center;
    		padding-top: 2px;
    	}

    	/* add Tasks stuff */
        #navSlideLayer h3 { font-size: 1.4rem; }

    	#taskPlaceholder {
    		height: calc(100vh - 14rem);
    	}

    	#available-tasks {
    		height: calc(100vh - 18rem);
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
    		background: white;
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

    	@media screen and (max-width: 521.98px) {
    		#available-tasks {
    			height: calc(100vh - 19.5rem);
    		}
    	}

        .fa-gear:hover {
            cursor: pointer;
        }

        .buttons button:hover,
        .buttons button:focus {
            background-color: #f0f4fa; /* highlight color */
            color: #333;
            border-color: #b3c6e0;
            transition: background 0.2s, color 0.2s;
        }

        .buttons button:active {
            background-color: #e2e8f5 !important; /* slightly deeper blue */
            color: #222;
            border-color: #8fa8c9;
            box-shadow: 0 1px 2px rgba(0,0,0,0.03);
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

        td.priority-col {
            cursor: move !important;
        }
        td.priority-col:active,
        td.priority-col:hover {
            cursor: move !important;
        }

        /* Optional: keep the background highlight for mobile if you like */
        @media (pointer: coarse) {
            td.priority-col {
                background: #f0f4fa;
            }
            td.priority-col:active {
                background: #e2e8f5;
            }
        }

        .btn{
            border-color: black;
        }
        .btn:hover,
        .btn:focus,
        .btn:active,
        .btn:focus:active,
        .btn:first-child:active{
            color: var(--bs-btn-hover-color, #222);
            background-color: var(--bs-btn-hover-bg, #f0f4fa);
            border-color: black;
            box-shadow: 0 0 0 2px black;
            transition: background 0.2s, color 0.2s, border-color 0.2s;
        }
        .priority-comment div.task-comment {
            color: #777;
        }
        .priority-comment .hidden {
            display: none !important;
        }
        .priority-comment div.task-comment.override-hidden {
            display: block !important;
            /* color: #777;  -- not needed, already set above */
            visibility: visible !important;
        }
        .yellow-background {
            background-color: yellow;
        }
        .red { color: red !important; }
        tr.webview div.tab-1 {
            padding-left: 30px;
        }
        tr.webview div.tab-2 {
            padding-left: 60px;
        }
        tr.webview div.tab-3 {
            padding-left: 90px;
        }
        .priority-comment .comment-line:hover {
            text-decoration: underline;
            cursor: pointer !important;
        }
    </style>
    <script>
        var mobileTitle = "Priorities";

        function checkchars(tb) {
            if (tb.value.length > 1499) {
                tb.value = tb.value.substring(0, 1499)
            }
        }
    </script>
</asp:Content>

<asp:Content ID="main" runat="server" ContentPlaceHolderID="mainContent">
    <div id="priorities-panel">
        <% if (UsesPriorities)
            { %>
        <div id="priorities-toolbar">
            <div class="col-xs-12 priorities-title">
                Priorities: <span id="label-name"><%= Info.LabelName %></span>
                <% if (!Info.IsSingleUserList && Info.IsMyList && Info.IsSupervisor) { %>
                <span id="expand-collapse" style="margin-left: 12px;">
                    <a data-role="collapse-all" style="vertical-align:middle;">
                        <img class="expandCollapseAllBtn expandCollapseAllIcon" id="Img2" src="/Images/minus.gif" style="width:23px;height:23px;cursor:pointer;" alt="Collapse all comments" />
                    </a>
                    <a data-role="expand-all" style="vertical-align:middle;">
                        <img class="expandCollapseAllBtn expandCollapseAllIcon" id="Img1" src="/Images/plus.gif" style="width:23px;height:23px;cursor:pointer;" alt="Expand all comments" />
                    </a>
                </span>
                <% } %>
                <i class="fa fa-gear mr-3"></i>
            </div>
            <div class="buttons hidden">
                <% if (!SetLocked)
                    { %>

                <button data-role="email-priorities" class="btn btn-sm btn-default">
                    <img alt="" src="/Images/inbox.gif" />
                    Email Priorities</button>
                <button data-role="add-task" class="btn btn-sm btn-default">
                    <img alt="" src="/Images/plus.gif" />
                    Add Task</button>
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
                <% } %>
                <% } %>
                <% } %>
                <button data-role="sort-priorities" class="btn btn-sm btn-default">
                    <img height="16" width="16" alt="" src="/Images/Nags/up.png" style="vertical-align:middle; position:relative; top:-2px; left:3px; margin-right:6px;">
                    Prioritize By Date
                </button>
            </div>
        </div>
        <% if (!SetLocked)
            { %>
        <div id="timer" class="red italic">Session will timeout in <span id="time"></span></div>
        <% } %>
        <% } %>
        <div id="priority-lists">
            <div id="priority-lists-center">
                <% if (!SetLocked)
                    { %>
                    <table id="userTable" <%= !Info.IsSingleUserList ? "data-role='dragndrop-reorderable'" : ""  %>
                        data-table="task-table">
                    <priority:PriorityList ID="PriorityListControl" IsMobile="true" runat="server" />

                    <%--					    <tr data-id="-1" data-role="delete-row" class="delete-row hidden">
						    <td class="recycle-large" style="line-height:100px;background:transparent url('images/recycle.jpg') left center no-repeat;min-width:200px;">&nbsp;</td>
					    </tr>--%>
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
    
        <div id="sort-confirm-modal" class="modal" style="display:none; position:fixed; left:0; top:0; width:100vw; height:100vh; background:rgba(0,0,0,0.3); z-index:9999; align-items:center; justify-content:center;">
            <div style="background:#fff; padding:24px; border-radius:6px; max-width:400px; margin:auto; box-shadow:0 2px 8px rgba(0,0,0,0.2);">
                <div style="margin-bottom:16px;">
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
                <div class="text-right" style="display: flex; justify-content: flex-end; gap: 8px;">
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
</asp:Content>

<asp:Content ID="script" runat="server" ContentPlaceHolderID="scriptContent">
    <script src="../Scripts/Priorities.js?v=<%= System.IO.File.GetLastWriteTime(Server.MapPath($"/Scripts/Priorities.js")).Ticks.ToString() %>"></script>
    <script type="text/javascript">
        $(".fa-gear").on('click', function () {
            $(".buttons").toggleClass('hidden');
        });
        var listOfTime = `
			<option>12:00 AM</option>
			<option>12:30 AM</option>
			<option>1:00 AM</option>
			<option>1:30 AM</option>
			<option>2:00 AM</option>
			<option>2:30 AM</option>
			<option>3:00 AM</option>
			<option>3:30 AM</option>
			<option>4:00 AM</option>
			<option>4:30 AM</option>
			<option>5:00 AM</option>
			<option>5:30 AM</option>
			<option>6:00 AM</option>
			<option>6:30 AM</option>
			<option>7:00 AM</option>
			<option>7:30 AM</option>
			<option>8:00 AM</option>
			<option>8:30 AM</option>
			<option>9:00 AM</option>
			<option>9:30 AM</option>
			<option>10:00 AM</option>
			<option>10:30 AM</option>
			<option>11:00 AM</option>
			<option>11:30 AM</option>
			<option>12:00 PM</option>
			<option>12:30 PM</option>
			<option>1:00 PM</option>
			<option>1:30 PM</option>
			<option>2:00 PM</option>
			<option>2:30 PM</option>
			<option>3:00 PM</option>
			<option>3:30 PM</option>
			<option>4:00 PM</option>
			<option>4:30 PM</option>
			<option>5:00 PM</option>
			<option>5:30 PM</option>
			<option>6:00 PM</option>
			<option>6:30 PM</option>
			<option>7:00 PM</option>
			<option>7:30 PM</option>
			<option>8:00 PM</option>
			<option>8:30 PM</option>
			<option>9:00 PM</option>
			<option>9:30 PM</option>
			<option>10:00 PM</option>
			<option>10:30 PM</option>
			<option>11:00 PM</option>
			<option>11:30 PM</option>
        `;
        prioritiesModule.isTouch = <%= (QProcess.Extensions.ExtensionMethods.IsMobileBrowser(Request) || QProcess.Session.CurrentSession.ForceMobile(Request)).ToString().ToLowerInvariant()%>
            prioritiesModule.isTouch = true;

        $("#addTask").on("click", prioritiesModule.showAddTaskPanel);

        $(document).on("click", "#btnCloseWindow", function (e) {
            slider.toggleClass('open');
        });

        document.addEventListener("DOMContentLoaded", function () {
            // Modal logic for Sort Priorities
            var sortModal = document.getElementById("sort-confirm-modal");
            var sortYes = document.getElementById("sort-confirm-yes");
            var sortNo = document.getElementById("sort-confirm-no");
            var sortBtn = document.querySelector('button[data-role="sort-priorities"]');

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

            // Attach sortTable logic for mobile
            var table = document.querySelector('table[data-table="task-table"]');
            if (table) {
                function parseDate(dateString) {
                    if (!dateString) return new Date(0);
                    var cleanedDate = dateString.replace("Due", "").trim();
                    var parts = cleanedDate.split("/");
                    if (parts.length !== 3) return new Date(0);
                    // MM/DD/YYYY
                    return new Date(parts[2], parts[0] - 1, parts[1]);
                }

                function isCompletedRow(row) {
                    return row.getAttribute("data-priority") === "-1";
                }

                function updatePriorityNumbers(rows) {
                    var priority = 1;
                    rows.forEach(function (row) {
                        var priorityCell = row.querySelector("td.priority-col");
                        if (priorityCell) {
                            if (!isCompletedRow(row)) {
                                priorityCell.innerHTML =
                                    '<span class="hidden data-label">Priority</span>' +
                                    '<span class="nbr">' + priority + '</span>' +
                                    '&nbsp;' +
                                    '<span class="draggable" data-role="dragndrop-dragpoint"></span>';
                                row.setAttribute("data-priority", priority);
                                priority++;
                            } else {
                                priorityCell.innerHTML = "";
                                row.setAttribute("data-priority", "-1");
                            }
                        }
                    });
                }

                function saveNewOrder(rows) {
                    var order = rows.map(function (row, idx) {
                        return {
                            TaskId: row.getAttribute("data-id"),
                            DisplayOrder: idx + 1
                        };
                    });

                    fetch("../DataService.asmx/SaveEntirePriorityOrder", {
                        method: "POST",
                        headers: { "Content-Type": "application/json" },
                        body: JSON.stringify({
                            order: order,
                            setId: document.getElementById("set-id").value,
                            userId: document.getElementById("set-locked-by-id").value
                        })
                    }).catch(function (error) {
                        console.error("Error saving order:", error);
                    });
                }

                function sortTable(ascending) {
                    // Find all inner task tables on the page
                    var taskTables = document.querySelectorAll('table[data-role="dragndrop-reorderable"][data-table="task-table"]');
                    taskTables.forEach(function (table) {
                        var rows = Array.from(table.querySelectorAll("tbody tr[data-id]"));

                        // Separate incomplete and completed rows
                        var incompleteRows = rows.filter(function (row) { return row.getAttribute("data-priority") !== "-1"; });
                        var completedRows = rows.filter(function (row) { return row.getAttribute("data-priority") === "-1"; });

                        // Sort only incomplete rows by due date
                        incompleteRows.sort(function (a, b) {
                            var dueA = a.querySelector("[data-column='due']");
                            var dueB = b.querySelector("[data-column='due']");
                            if (!dueA || !dueB) return 0;
                            var dateA = parseDate(dueA.textContent.trim());
                            var dateB = parseDate(dueB.textContent.trim());
                            return ascending ? dateA - dateB : dateB - dateA;
                        });

                        var tbody = table.querySelector("tbody");
                        // Append incomplete rows first, then completed rows
                        [].concat(incompleteRows, completedRows).forEach(function (row) {
                            row.setAttribute("data-role", "dragndrop-dragpoint");
                            tbody.appendChild(row);
                        });

                        updatePriorityNumbers([].concat(incompleteRows, completedRows));
                        saveNewOrder([].concat(incompleteRows, completedRows));
                    });
                }

                // Expose for modal use
                window.mainTaskTableSort = sortTable;
            }
        });

    </script>

    
<!-- Copyright © 2024 Renegade Swish, LLC -->
</asp:Content>

