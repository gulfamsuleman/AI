var myStatusModule = (function () {
    var self = {};
    var throbber = $("#throbber");
    var datepicker = $("input[data-role='datepicker']");
    var reportId = $("#report-id").val();
    var taskId = $("#task-id").val();
    var isArchive = $("#is-archive").val();
    var statusReport = $("#status-report");

    $().ready(function () {
        self.loadStatusReport();
        $("[data-role='comments-false']").click(allCommentsFalse);
        $("[data-role='comments-true']").click(allCommentsTrue);

        if (typeof slider !== 'undefined') return;

        resize();
        window.onresize = resize;

        // Add event listeners for task actions
        $(document).on('click', 'a[data-action="complete"]', function (e) {
            var task = $(e.target).closest("tr");
            completeTask(task);
        });

        $(document).on('click', 'a[data-action="reopen"]', function (e) {
            var task = $(e.target).closest("tr");
            reopenTask(task);
        });

        $(document).on('click', 'button[data-action="delete"]', function (e) {
            var task = $(e.target).closest("tr");
            deleteTask(task);
        });

        // Listen for messages from the ManageSingleChecklist.aspx window
        window.addEventListener("message", function (event) {
            if (event.data.action === "reopen") {
                reopenTaskFromPopup(event.data.taskId);
            }
        });
    });

    self.loadStatusReport = function () {
        showThrobber();
        var params = {
            ReportId: reportId,
            IsArchive: isArchive,
            LastViewed: datepicker.val()
        };
        statusReport.load("../JQueryHandler.ashx?ControlName=" + encodeURI("Controls/Shared/StatusReport.ascx"), params, function () {
            throbber.addClass("hidden");
            statusReport.removeClass("hidden");
            datepicker.val($("#last-viewed").val());
            $("#expand-collapse").removeClass("hidden");
            $("#all-comments-flag").removeClass("hidden");

            // [ST] 11/25/14 - check to see if assignee column should be hidden or not
            syncPost("GetAssigneeVisibility", JSON.stringify({ reportID: reportId }));
            if (syncPostResult) {
                if (typeof slider !== 'undefined') {
                    $('.report-line-headings-assignees, .report-line-assignees-content').removeClass('hidden');
                } else {
                    window.reportToolbarModule.toggleAssignees(this, false);
                }
            }

            // [ST] 12/01/14 - hide "take control" button for completed task
            $("table.status-table").each(function () {
                var tbl = $(this);
                if (tbl.find("td.completed-task").length > 0) {
                    tbl.find("input[data-role=take-control]").remove();
                }
            });

            $(".status-table").each(function () {
                var section = $(this);
                var sectionHeader = section.find("td.report-line-subheader");
                if (sectionHeader.length > 0) {
                    var sectionName = sectionHeader.find("a[data-role='section-head']").text().split('(')[0].trim();
                    if (sectionName !== "General Comments") {
                        var itemCount = section.find("tbody tr").filter(function () {
                            return !$(this).hasClass("report-line-header") &&
                                !$(this).hasClass("report-line-ender") &&
                                !$(this).hasClass("report-line-task-general-comment") &&
                                !$(this).hasClass("report-header-column");
                        }).length;
                        sectionHeader.contents().filter(function () {
                            return this.nodeType === 3; // Get the text node
                        }).remove(); // Remove the existing text node
                        sectionHeader.append(`<span style="display: inline-block;">&nbsp;(${itemCount})</span>`);
                    }
                }
                // Add a CSS class to the collapsing icon
                section.find("i[data-collapse-target]").addClass("collapsible-icon-margin");
            });

            if (taskId > 0) {
                $.find("tr[data-id=" + taskId + "] > td > a[data-action=add-comment]")[0].click();
                $.find("tr[data-id=" + taskId + "]")[0].scrollIntoView();
            }

            var $headerTable = $('#statusReportHeader');
            var $meta = $('#report-meta');
            if ($headerTable.length && $meta.length) {
                $headerTable.after($meta);
                $meta.show();
            }
        });
    }

    function showThrobber() {
        if (throbber.hasClass("hidden")) {
            throbber.removeClass("hidden");
            statusReport.addClass("hidden");
        }
    }

    function allCommentsFalse() {
        window.location.href = "./MyStatus.aspx?getAllComments=false";
    }

    function allCommentsTrue() {
        window.location.href = "./MyStatus.aspx?getAllComments=true";
    }

    self.showAddTaskPanel = function () {
        if (typeof slider !== 'undefined') {
            slider.toggleClass('open');
        }

        var htmlToAppend = `<div class="task-container">
								<h3>Add Task</h3>
								<div class="radio-btn">
									<input id="newTask" type="radio" class="btn btn-check" checked="checked" name="taskType" autocomplete="off" />
									<label class="btn btn-outline-secondary" for="newTask">New Task</label>
									<input id="existingTask" type="radio" class="btn btn-check" name="taskType" autocomplete="off" />
									<label class="btn btn-outline-secondary" for="existingTask">Existing Task</label>
								</div>
                                <div id="sectionSelect"></div>
                                <div class="panel-content" id="taskPlaceholder"></div>
                           </div>`;

        slider.html(htmlToAppend);


        $.ajax({
            url: "../DataService.asmx/GetTaskTypesForReport",
            type: "POST",
            data: JSON.stringify({ reportId: reportId }),
            dataType: "json",
            async: false,
            contentType: "application/json",
            success: function (response) {
                var taskTypes = response.d;
                var htmlToAppend = `<label for="taskTypeSelect">Select A Section</label>
                                    <select id="taskTypeSelect"></select>`;
                $("#sectionSelect").html(htmlToAppend);
                taskTypes.forEach((tt) => {
                    $("#taskTypeSelect").append(`<option value="${tt.Id}">${tt.Name}</option>`);
                });
            },
            error: function (xhr, status, e) {
                return;
            }
        });
        $(".task-container input[name=taskType]", slider).on("change",
            function (e) {
                var ctl = $(this);
                if (ctl.prop("checked") == false) return;

                switch (ctl.prop("id")) {
                    case "newTask":
                        $("#taskPlaceholder").empty();
                        $("#taskPlaceholder").load("../JQueryHandler.ashx?ControlName=" + encodeURI("Controls/Shared/NewTask.ascx"), {},
                            function () {
                                $("#taskPlaceholder", slider).html($("#taskPlaceholder", slider).html().replace(/^.*NewTask\.css.*$/gm, ""));
                                var div = $("#taskPlaceholder", slider).find("#create").closest("div");
                                div.append(`<button id="btnCloseWindow" class="btn btn-secondary">Close Window</button>`);
                                div.css({ 'display': 'flex', 'justify-content': 'space-evenly', 'margin-bottom': '6px' });
                            });

                        break;

                    case "existingTask":
                        var selectedSection = $("#taskTypeSelect").val();
                        var remoteParams = { Section: selectedSection, Sort: "duetime", ReportId: reportId };
                        $("#taskPlaceholder").empty();
                        $("#taskPlaceholder").load("../JQueryHandler.ashx?ControlName=" + encodeURI("Controls/MyStatus/AddExistingTask.ascx"), remoteParams, function () {
                            $("#taskPlaceholder", slider).append(`<div class="text-center mt-3"><button id="btnCloseWindow" class="btn btn-secondary">Close Window</button></div>`);
                        });
                        break;
                    default:
                        break;
                }
            });

        $("#taskTypeSelect", slider).on("change",
            function (e) {
                var ctl = $(this);
                if (ctl.prop("checked") == false) return;

                $("#existingTask", slider).trigger("change");

            });

        $("#newTask", slider).trigger("change");
    }

    self.showSupervisorPanel = function () {
        if (typeof slider !== 'undefined') {
            slider.toggleClass('open');
        }

        var htmlToAppend = `<div class="supervisor-container">
                            <h3>Supervisors</h3>
                            <div class="panel-content" id="supervisorPlaceholder"></div>
                        </div>`;

        slider.html(htmlToAppend);

        var params = { ReportId: reportId };

        $("#supervisorPlaceholder").load("../JQueryHandler.ashx?ControlName=" + encodeURI("Controls/Shared/Supervisors.ascx"), params, function () {
            $(".supervisor-container", slider).append("<button id='btnCloseWindow' class='btn btn-secondary'>Close Window</button>");
        });
    }

    self.showEmailCommentsPanel = function () {
        if (typeof slider === 'undefined')
            return;

        var html = `<div class='emailModes'>
				<h3>Email Comments</h3>
				<input id="emailCommentsMode" data-mode="comments" type="radio" class="btn btn-check" checked="checked" name="emailModes" autocomplete="off" />
				<label class="btn btn-outline-secondary" for="emailCommentsMode">Since...</label>
				<input id="emailTodayMode" data-mode="todays-comments" type="radio" class="btn btn-check" name="emailModes" autocomplete="off" />
				<label class="btn btn-outline-secondary" for="emailTodayMode">Today</label>
				<input id="emailAllMode" data-mode="all" type="radio" class="btn btn-check" name="emailModes" autocomplete="off" />
				<label class="btn btn-outline-secondary" for="emailAllMode">All</label>
			</div>
			<div class='emailControl'></div>`;

        //default
        var params = {
            mode: "comments",
            ReportId: reportId,
            isUrgent: false
        };

        $(".buttons").toggleClass("hidden");
        slider.html(html);

        $(".emailModes input[name=emailModes]", slider).on("change",
            function (e) {
                var ctl = $(this);
                if (ctl.prop("checked") == false) return;

                var mode = ctl.data("mode");

                var params = {
                    mode: mode,
                    ReportId: reportId,
                    isUrgent: false
                };

                $(".emailControl", slider).html(`<div style="margin:50px auto;text-align:center">Loading...please wait <img src="../images/loading.gif" /></div>`);
                $(".emailControl", slider).load("../JQueryHandler.ashx?ControlName=" + encodeURI("Controls/MyStatus/EmailComments.ascx"), params,
                    function () {
                        $(".emailControl", slider).html($(".emailControl", slider).html().replace(/h3/g, "h4"));
                        $(".emailControl", slider).append("&nbsp;&nbsp;&nbsp;&nbsp;<button id='btnCloseWindow' class='btn btn-secondary'>Close Window</button>");
                        $(".emailControl button[data-action=send-email]", slider).addClass("btn btn-success")
                        $(".emailControl button[data-action=prev-email]", slider).addClass("btn btn-info")
                    });
            });

        slider.toggleClass('open');
        $("#emailCommentsMode", slider).trigger("change");
    }

    function completeTask(task) {
        var sectionId = task.closest("td[data-section]").data("section");
        var newSectionId = "C" + sectionId;
        moveTask(task, newSectionId, true);
    }

    function reopenTask(task) {
        var sectionId = task.closest("td[data-section]").data("section");
        var newSectionId = sectionId.substring(1);
        moveTask(task, newSectionId, false);
    }

    function reopenTaskFromPopup(taskId) {
        var task = $("tr[data-id='" + taskId + "']");
        var sectionId = task.closest("td[data-section]").data("section");
        var newSectionId = sectionId.substring(1);
        moveTask(task, newSectionId, false);
    }

    function deleteTask(task) {
        var sectionId = task.closest("td[data-section]").data("section");
        task.remove();
        updateTaskCount(sectionId);
    }

    function moveTask(task, newSectionId, isComplete) {
        var sectionTable = $("td[data-section='" + newSectionId + "']").closest("table");
        var oldSectionId = task.closest("td[data-section]").data("section");

        if (sectionTable.length != 0) {
            var taskPriority = task.data("priority");
            var taskRows = sectionTable.find("tr[data-priority]");
            for (var i = taskRows.length - 1; i >= 0; i--) {
                var currentRowPriority = $(taskRows[i]).data("priority");
                if (taskPriority == currentRowPriority) {
                    var taskDate = new Date(task.data("due-date"));
                    var currentDate = new Date($(taskRows[i]).data("due-date"));
                    if (taskDate > currentDate) {
                        $(taskRows[i]).after(task);
                        updateTaskCount(newSectionId);
                        updateTaskCount(oldSectionId);
                        return;
                    }
                } else if (currentRowPriority < taskPriority) {
                    $(taskRows[i]).after(task);
                    updateTaskCount(newSectionId);
                    updateTaskCount(oldSectionId);
                    return;
                }
            }
            taskRows.first().before(task);
            updateTaskCount(newSectionId);
            updateTaskCount(oldSectionId);
        } else {
            var tableTemplate =
                "<table class='status-table collapsible-item' data-collapse-state='expanded'>" +
                "<thead>" +
                "<tr>" +
                "<td colspan='7' class='report-line-subheader noselect completed-task' data-section='{0}'><i class='fa fa-minus-square-o' data-role='expand-indicator' data-collapse-target='true'></i>{1}</td>" +
                "</tr>" +
                "</thead>" +
                "<tbody class='expanded'>" +
                "<tr class='report-line-content multiple-collapse-member'>" +
                "<th class='report-line-headings report-line-border report-line-headings-action'></th>" +
                "<th class='report-line-headings report-line-border report-line-headings-priority'></th>" +
                "<th class='report-line-headings report-line-border report-line-headings-task' style='width: 10%;'>Task</th>" +
                "<th class='report-line-headings report-line-border report-line-headings-deadline'>Due</th>" +
                "<th class='report-line-headings report-line-border report-line-headings-assignees" + assigneeViewClass(task) + "'>Assignees/Controllers</th>" +
                "<th class='report-line-headings report-line-border report-line-headings-progress' style='width: 70%;'>Progress</th>" +
                "</tr>" +
                "<tr class='report-line-ender'>" +
                "<td colspan='7'></td>" +
                "</tr>" +
                "</tbody>" +
                "</table>";
            var newTable;
            if (isComplete) {
                newTable = $(format(tableTemplate, newSectionId, "Completed - " + sectionName));
                task.closest("table").after(newTable);
                newTable.find("th").closest("tr").after(task);
            } else {
                newTable = $(format(tableTemplate, newSectionId, sectionName));
                task.closest("table").before(newTable);
                newTable.find("th").closest("tr").after(task);
            }
            updateTaskCount(newSectionId);
            updateTaskCount(oldSectionId);
        }
    }

    function updateTaskCount(sectionId) {
        var sectionHeader = $("td[data-section='" + sectionId + "']");
        var taskCount = sectionHeader.closest("table").find("tr[data-priority]").length;
        var sectionTitle = sectionHeader.text().split('(')[0].trim();
        sectionHeader.text(sectionTitle + " (" + taskCount + ")");
    }

    function assigneeViewClass(task) {
        if (task.find("td.report-line-assignees-content").first().hasClass("hidden")) {
            return " hidden";
        } else {
            return "";
        }
    }

    function resize() {
        $("#site-main").height(($(window).height() - ($("#site-nav").outerHeight() + $("nav.report-navbar-default").outerHeight() + $("#site-footer").outerHeight()) - 14) + "px");
        $("nav.report-navbar-default").css("margin-top", ($("#site-nav").outerHeight()) + "px");
        $("#site-main").css("margin-top", ($("#site-nav").outerHeight() + $("nav.report-navbar-default").outerHeight()) + "px");
    }

    return self;
})();

/* Copyright © 2024 Renegade Swish, LLC */