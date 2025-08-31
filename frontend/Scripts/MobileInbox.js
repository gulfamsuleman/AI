var mobileInboxModule = (function () {
    var self = {};
    var throbber = $("#throbber");
    var datepicker = $("input[data-role='datepicker']");
    var reportId = $("#ReportId").val();
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
            if (taskId > 0) {
                $.find("tr[data-id=" + taskId + "] > td > a[data-action=add-comment]")[0].click();
                $.find("tr[data-id=" + taskId + "]")[0].scrollIntoView();
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

    self.showEmailCommentsPanel = function (reportId) {
        if (typeof slider === 'undefined')
            return;

        var html = `<div class='emailModes' style='display: none;'>
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
                        $(".emailControl", slider).append("<button class='btn btn btn-warning' data-action='send-email-all'>Email, Mark Read, Go To Inbox</button>");
                        $(".emailControl", slider).append("<button id='btnCloseWindow' class='btn btn-secondary'>Close Window</button>");
                        $(".emailControl button[data-action=send-email-all]", slider).addClass("btn btn-success")
                        $(".emailControl button[data-action=send-email]", slider).addClass("btn btn-success")
                        $(".emailControl button[data-action=prev-email]", slider).addClass("btn btn-info")
                        $("button[data-action='send-email-all']").click(function () { sendEmailAll(reportId); });
                    });
            });

        slider.toggleClass('open');
        $("#emailCommentsMode", slider).trigger("change");
    }

    function sendEmailAll(reportId) {
        sending = false
        sendEmailRequest(false, reportId);
        if (sending) {
            if (window.myInboxModule)
                window.myInboxModule.markReportAsRead(reportId);
            window.location.assign("MobileInbox.aspx");
        }
    }

    function sendEmailRequest(prev, reportId) {

        var mode = "comments";
        var preview = 0;
        if (prev == true) {
            preview = 1;
        }

        var recipients = $("#email-list .email-item input[data-email]:checked");
        var comments = $("#comments-section .comment-item input[data-id]:checked");
        var onlyTasksWithComments = false;
        var isIncludeDetails = false;

        if (mode == "all") {
            onlyTasksWithComments = $("#only-tasks-with-comments").is(":checked");
            isIncludeDetails = $("#is-include-details").is(":checked");
        }

        if (recipients.length == 0 && preview == 0) {
            //notifier.setMessage("You must select at least 1 recipient to use this feature.", "yellow", 5000);
            alert("You must select at least 1 recipient");
            return;
        }
        if (mode == "comments" && !$("#all-comments").prop('checked') && comments.length == 0) {
            //notifier.setMessage("You must select at least 1 comment to send to use this feature.", "yellow", 5000);
            alert("You must select at least 1 comment to send");
            return;
        }
        var commentsDate = $("#comments-date").val();
        var commentsTime = $("#comments-time").val();
        var addresses = [];
        var recipientIds = [];
        recipients.each(function () {
            recipientIds.push($(this).data("id"));
            addresses.push($(this).data("email"));
        });
        var commentIds = [];
        comments.each(function () {
            commentIds.push($(this).data("id"));
        });
        var isArchive = '';
        sending = true;
        var singleCol = isMobile && prev && window.innerWidth < 800;

        $.ajax({
            url: "/EmailHandler.ashx",
            type: "POST",
            async: false,
            data: {
                Form: "MyStatusEmailForm.aspx",
                CommentIds: commentIds.join(),
                RecipientIds: recipientIds.join(),
                EmailAddresses: addresses.join(),
                Subject: "QProcess Email",
                Mode: mode,
                ReportId: reportId,
                IsArchive: isArchive,
                CommentsDate: commentsDate,
                CommentsTime: commentsTime,
                Preview: preview,
                OnlyTasksWithComments: onlyTasksWithComments,
                IsIncludeDetails: isIncludeDetails,
                SingleCol: singleCol
            },
            success: function (msg, textStatus, request) {
                if (msg == "There are no comments to send") {
                    alert(msg);
                } else {
                    if (preview == 1) {
                        if (typeof slider !== "undefined") {
                            $("div.preview", slider).remove();
                            slider.append("<div class='preview'>" + msg + "</div>");
                        }
                        else {
                            $("#divPreview").show().center();
                            if ($("#divPreview")[0].contentWindow != null) {
                                var d = $("#divPreview")[0].contentWindow.document; // contentWindow works in IE7 and FF
                                d.open(); d.close(); // must open and close document object to start using it!
                            }
                            // now start doing normal jQuery:
                            $("body", d).append("<span onclick='window.parent.closePreview()' style='float:right; font-weight:bold;cursor:pointer;color:red'>Close Preview</span>" + msg).css("background-color", "white");
                        }
                    } else {
                        if (typeof slider !== "undefined") {
                            slider.toggleClass('open');
                        } else {
                            notifier.setMessage("Send Successful.", "green", 2000);
                            window.modalModule.hide();
                        }
                    }
                }
            },
            error: function (jqXHR, textStatus, errorThrown) {
                alert(textStatus + ": " + errorThrown);
            }
        });
    }

    function resize() {
        $("#site-main").height(($(window).height() - ($("#site-nav").outerHeight() + $("nav.report-navbar-default").outerHeight() + $("#site-footer").outerHeight()) - 14) + "px");
        $("nav.report-navbar-default").css("margin-top", ($("#site-nav").outerHeight()) + "px");
        $("#site-main").css("margin-top", ($("#site-nav").outerHeight() + $("nav.report-navbar-default").outerHeight()) + "px");
    }

    return self;
})();
/* Copyright © 2024 Renegade Swish, LLC */

