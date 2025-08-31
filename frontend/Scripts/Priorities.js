var prioritiesModule = (function () {
    var self = {};
    var timeout;
    var pollTimer;
    var pollMessages;
    var targetUserId;
    var targetListId;
    self.setId = $("#set-id").val();
    var setLocked = $("#set-locked").val() == "True";
    var setLockedById = $("#set-locked-by-id").val();
    var setLockedByName = $("#set-locked-by-name").val();
    var timedOut = false;
    self.replyMessageOpen = false;
    var visibleDeleteRow = "";
    var prioritiesPanel = $("#priorities-panel");
    var prioritiesList = $("#priority-lists");
    self.timerSpan = $("#timer");
    var time = $("#time");
    var timeoutPanel = $("#timeout-panel");
    var modal = null;
    var commentSaving = false;
    self.isTouch = false;

    $().ready(function () {
        modal = window.modalModule;
        prioritiesPanel.on("contextmenu", function (e) {
            targetUserId = $(e.target).closest("tr").data("user-id");
            targetListId = $(e.target).closest("tr").data("list-id");
        });
        prioritiesPanel.on('click', "[data-role='show-comments']", showComments);
        prioritiesPanel.on('click', "[data-role='hide-comments']", hideComments);
        prioritiesPanel.on('click', "[data-role='add-names']", openAvailableUsersModal);
        prioritiesPanel.on('click', "[data-role='delete-list']", openDeleteListModal);
        prioritiesPanel.on('click', "[data-role='create-list']", openCreateListModal);
        prioritiesPanel.on('click', "[data-role='default-list']", openSetDefaultListModal);
        prioritiesPanel.on('click', "[data-role='switch-list']", openSwitchListModal);
        prioritiesPanel.on('click', "[data-role='change-fonts']", openFontModal);
        prioritiesPanel.on('click', "[data-role='email-priorities']", openEmailPrioritiesModal);
        prioritiesPanel.on('click', "[data-role='print-priorities']", printCssBW);
        prioritiesPanel.on('click', "[data-role='add-task']", showAddTaskPanel);
        prioritiesPanel.on('click', "[data-role='open-message']", openMessageModal);
        prioritiesPanel.on('click', "[data-role='status-link']", function (e) { statusLinkClick(e); });
        //prioritiesPanel.on('mouseenter', "[data-role='dragndrop-reorderable'] [data-role='list-title']", function (e) { showDragHandle(e); });
        //prioritiesPanel.on('mouseleave', "[data-role='dragndrop-reorderable'] [data-role='list-title']", function (e) { hideDragHandle(e); });
        //prioritiesPanel.find("tr").mouseup(onMouseUp);

        self.resetTimeout();
        pollTimer = setInterval(timer, 1000);
        //pollMessages = setInterval(checkForMessages, 5000);
        //window.onbeforeunload = myUnload;

        //function myUnload() {
        //    handleUnload();
        //}

        $(document).on("dragndropElementDropped", function (e) { handleElementDropped(e); });
        $(document).on("dragndropElementCancel", function (e) { handleElementCancel(e); });
        $(document).on("dnd_DragStart", function (e) { handleDragStart(e); });

        //if comments are to be hidden, we need to default them to hidden
        if ($("button[data-role='hide-comments'].hidden").length > 0) {
            $(".priority-comment").addClass("hidden");
        }

        $("table[data-table='task-table']").each(function () {
            if ($(this).has("tbody tr:not(.hidden)").length == 0) {
                $(this).hide();
            }
        });

        $('.pointer-cursor').on('mousedown', function (e) {
            e.stopPropagation();
            return false;
        });

        syncPost("GetEmployeePrioritySchedule", "");//added by venkat 09/22/2017
        $("#prioritySchedule").html(syncPostResult);

        $("tr.webview").each(function () {
            var $row = $(this);
            var $commentsDiv = $row.find("div.priority-comment");
            var $placeholder = $row.find(".expand-collapse-placeholder");

            // Look for any old comments (data-comment="old")
            if ($commentsDiv.find('.comment-line[data-comment="old"]').length > 0 && $placeholder.length > 0) {
                $placeholder.html(
                    `<a href="javascript:void(0);" class="expand-collapse-btn" data-role="expand-task" style="display:inline-flex;align-items:center;justify-content:center;width:12px;height:12px;">
                <img src="/Images/plus.gif" alt="Expand task level comments" style="display:block;max-width:12px;max-height:12px;" />
            </a>`
                );
            }
        });


        $("img.task-expand-collapse").on("click", function () {
            let img = $(this);
            let commentDiv = img.closest(".priority-comment");
            let commentId = commentDiv.data("id");
            let expanded = getExpandedComments();

            if (img.hasClass("expand-task")) {
                img.removeClass("expand-task").addClass("collapse-task");
                img.attr("src", "/Images/minus.gif");
                img.attr("alt", "Collapse task level comments");
                img.parent().parent().find("div.old").addClass("override-hidden");
                if (commentId) expanded.add(commentId);
            } else {
                img.addClass("expand-task").removeClass("collapse-task");
                img.attr("src", "/Images/plus.gif");
                img.attr("alt", "Expand task level comments");
                img.parent().parent().find("div.old").removeClass("override-hidden");
                if (commentId) expanded.delete(commentId);
            }
            setExpandedComments(expanded);
        });

        resize();
        window.onresize = resize;

        prioritiesPanel.on('mousedown', 'img, a, button', function (e) {
            e.stopPropagation();
            e.preventDefault();
            return false;
        });

        bindCommentEvent();

        // Expand/Collapse All Comments Button Handler
        var allExpanded = false;
        $(document).on("click", ".expandCollapseAllBtn", function () {
            var $icon = $(this); // The img itself
            var allExpanded = $icon.data("allExpanded") || false;
            allExpanded = !allExpanded;
            $icon.data("allExpanded", allExpanded);

            // Update all expand/collapse icons in the list
            $("a.expand-collapse-btn[data-role='expand-task'] img").each(function () {
                if (allExpanded) {
                    $(this).attr("src", "/Images/minus.gif");
                    $(this).attr("alt", "Collapse task level comments");
                } else {
                    $(this).attr("src", "/Images/plus.gif");
                    $(this).attr("alt", "Expand task level comments");
                }
            });

            // Update the clicked icon
            if (allExpanded) {
                $icon.attr("src", "/Images/minus.gif");
                $icon.attr("alt", "Collapse task level comments");
            } else {
                $icon.attr("src", "/Images/plus.gif");
                $icon.attr("alt", "Expand task level comments");
            }

            // Show/hide all old comments
            $("a.expand-collapse-btn[data-role='expand-task']").each(function () {
                var $rowBtn = $(this);
                var $row = $rowBtn.closest("tr");
                var $priorityComment = $row.find(".priority-comment");
                var $oldComments = $priorityComment.find(".comment-line[data-comment='old']");
                if (allExpanded) {
                    $oldComments.removeClass("hidden");
                } else {
                    $oldComments.addClass("hidden");
                }
            });
        });
    });

    function getExpandedComments() {
        return new Set(JSON.parse(localStorage.getItem("expandedComments") || "[]"));
    }

    function setExpandedComments(ids) {
        localStorage.setItem("expandedComments", JSON.stringify(Array.from(ids)));
    }

    function resize() {
        $("#site-main").height(($(window).height() - $("#site-nav").outerHeight() - $("#site-footer").outerHeight() - 4) + "px");
        $("#site-main").css("margin-top", ($("#site-nav").outerHeight()) + "px");
    }

    // Context Menu Options
    self.addTasks = function () {
        self.openAvailableTasksModal("duetime");
    };

    self.clearList = function () {
        var choice = confirm("Are you sure you want to clear this list?");
        if (choice) {
            $.ajax({
                url: "../DataService.asmx/ClearPriorityList",
                type: "POST",
                data: JSON.stringify({ setId: self.setId, listId: targetListId }),
                contentType: "application/json",
                success: function (data) {
                    $("tr[data-list='" + targetListId.toString() + "']").remove();
                    $("table[data-table='task-table']").each(function () {
                        if ($(this).has("tbody tr:not(.hidden)").length == 0) {
                            $(this).hide();
                        }
                    });
                }
            });
        }
    };

    self.viewStatusReport = function () {
        self.resetTimeout();
        $.ajax({
            url: "../DataService.asmx/GetStatusReportLink",
            type: "POST",
            data: JSON.stringify({
                reportUserId: targetUserId,
                taskId: -1
            }),
            contentType: "application/json",
            success: function (data) {
                if (data.d == "Not Accessible")
                    alert("Status Report Not Found.");
                else {
                    var popupwindow = window.open(data.d, "status-window", "toolbar=no,status=no,scrollbars=yes,resizable=yes,menubar=no,width=1280,height=800");
                    popupwindow.moveTo(0, 0);
                    popupwindow.focus();
                }
            }
        });
    };

    self.viewComment = function (reportUserId, taskId) {
        self.resetTimeout();
        $.ajax({
            url: "../DataService.asmx/GetStatusReportLink",
            type: "POST",
            data: JSON.stringify({
                reportUserId: reportUserId,
                taskId: taskId
            }),
            contentType: "application/json",
            success: function (data) {
                if (data.d == "Not Accessible")
                    alert("Task not found on a status report therefore you cannot comment.  Please add the task to a status list if you wish to comment.");
                else {
                    var popupwindow = window.open(data.d, "status-window", "toolbar=no,status=no,scrollbars=yes,resizable=yes,menubar=no,width=1280,height=800");
                    popupwindow.moveTo(0, 0);
                    popupwindow.focus();
                }
            }
        });
    };

    //Attaching a handler to beforeunload causes IE to give an obnoxious prompt before any navigation.
    //This function allows reloads that bypass this prompt.
    self.unobnoxiousReload = function () {
        //handleUnload(null);
        unlockPriorityList(null);
        //window.onbeforeunload = undefined;
        window.location.reload();
    };

    self.openWindow = function (taskId, taskStage) {//added by venkat 04/20/2017
        var popupwin = window.open("../ManageSingleChecklist.aspx?taskId=" + taskId + "&taskStage=" + taskStage, "checklistmini",
            "toolbar=no,status=no,scrollbars=yes,resizable=yes,menubar=no,width=800,height=600");
        popupwin.focus();
        return false;
    };

    function showComplete(e) {//added by venkat 04/20/2017
        $(".completedshown").show();
        $(".completedhidden").hide();
        $(".hidecompletedtasks").addClass("showcompletedtasks");
        $(".showcompletedtasks").removeClass("hidecompletedtasks");
    }
    // Comments
    function showComments() {
        if (typeof slider !== 'undefined') $(".buttons").toggleClass("hidden");
        updateCommentsSetting(true);
    }

    function hideComments() {
        if (typeof slider !== 'undefined') $(".buttons").toggleClass("hidden");
        updateCommentsSetting(false);
    }

    function updateCommentsSetting(show) {
        $.ajax({
            url: "../DataService.asmx/ShowComments",
            type: "POST",
            data: JSON.stringify({ showComments: show }),
            contentType: "application/json",
            success: function (data) {
                if (show) {
                    // Show comments and related controls
                    $(".priority-comment").removeClass("hidden");
                    $("button[data-role='show-comments']").addClass("hidden");
                    $("button[data-role='hide-comments']").removeClass("hidden");
                    // Show expand/collapse icons (plus/minus) including header
                    $("a.expand-collapse-btn[data-role='expand-task']").removeClass("hidden");
                    $("a.expand-collapse-btn[data-role='expand-task'] img").removeClass("hidden");
                    $(".expandCollapseAllBtn").removeClass("hidden");
                } else {
                    // Hide comments and related controls
                    $(".priority-comment").addClass("hidden");
                    $("button[data-role='show-comments']").removeClass("hidden");
                    $("button[data-role='hide-comments']").addClass("hidden");
                    // Hide expand/collapse icons (plus/minus) including header
                    $("a.expand-collapse-btn[data-role='expand-task']").addClass("hidden");
                    $("a.expand-collapse-btn[data-role='expand-task'] img").addClass("hidden");
                    $(".expandCollapseAllBtn").addClass("hidden");
                }
            }
        });
    }


    function printCssBW() {
        removePrintCss();
        addPrintCss("Content/PrintBase.css");
        setTimeout(function () { window.print(); }, 150);
    };

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

    // Modals
    function openAvailableUsersModal() {
        $(".modal-dialog").width(400);
        modal.init({
            controlName: "Controls/Priorities/AvailableUsers.ascx",
            titleText: "Add Lists to Set",
            remoteParams: { SetId: self.setId }
        });
    }

    function openCommentModal(taskId, userId, isNew) {
        if (typeof slider !== 'undefined') {
            slider.html(`
			<h3>Add a Comment</h3>
			<div class="row">
			  <div class="col modal-body">
			    <textarea rows="10" style="width:100%;color:red;" onkeyup="checkchars(this)"></textarea>
			  </div>
			</div>
			<div class="row">
				<div class="col text-center">
				<button class="btn btn-primary" onclick="prioritiesModule.saveComment();">Save Changes</button>
				<button class="btn btn-secondary close-button">Cancel</button>
				</div>
			</div>`);
            slider.find(".close-button").on("click", function () {
                slider.toggleClass('open');
            });
            slider.toggleClass('open');
        } else {
            $(".modal-dialog").width(800);
            modal.init({
                elementID: "comment-panel",
                titleText: "Add a Comment"
            });
        }

        // Only pre-fill if not a new comment
        if (!isNew) {
            $.ajax({
                url: "../DataService.asmx/GetLastComment",
                type: "POST",
                data: JSON.stringify({
                    taskId: taskId,
                    userId: userId
                }),
                contentType: "application/json",
                success: function (data) {
                    $(".modal-body textarea").val(data.d);
                }
            });
        } else {
            $(".modal-body textarea").val('');
        }
    }


    self.openAvailableTasksModal = function (sort) {
        modal.init({
            controlName: "Controls/Priorities/AvailableTasks.ascx",
            titleText: "Add Tasks To User Priority List",
            remoteParams: {
                TargetUserId: targetUserId,
                TargetListId: targetListId,
                Sort: sort
            }
        });
    };

    function openDeleteListModal() {
        if (typeof slider !== 'undefined') {
            $(".buttons").toggleClass("hidden");
            slider.html(`<div style="margin:50px auto;text-align:center">Loading...please wait <img src="../images/loading.gif" /></div>`);
            slider.load("../JQueryHandler.ashx?ControlName=" + encodeURI("Controls/Priorities/DeletePriorityList.ascx"), {}, function () {
                slider.prepend("<h3>Delete Priority List</h3>");
            });
            slider.toggleClass('open');
            return;
        }

        $(".modal-dialog").width(400);
        modal.init({
            controlName: "Controls/Priorities/DeletePriorityList.ascx",
            titleText: "Delete Priority Set"
        });
    }

    function openCreateListModal() {
        if (typeof slider !== 'undefined') {
            $(".buttons").toggleClass("hidden");
            slider.html(`<div style="margin:50px auto;text-align:center">Loading...please wait <img src="../images/loading.gif" /></div>`);
            slider.load("../JQueryHandler.ashx?ControlName=" + encodeURI("Controls/Priorities/CreatePriorityList.ascx"), {}, function () {
                slider.prepend("<h3>Create New Priority List</h3>");
            });
            slider.toggleClass('open');
            return;
        }

        $(".modal-dialog").width(400);
        modal.init({
            controlName: "Controls/Priorities/CreatePriorityList.ascx",
            titleText: "Create New Priority List"
        });
    }

    function openSetDefaultListModal() {
        if (typeof slider !== 'undefined') {
            $(".buttons").toggleClass("hidden");
            slider.html(`<div style="margin:50px auto;text-align:center">Loading...please wait <img src="../images/loading.gif" /></div>`);
            slider.load("../JQueryHandler.ashx?ControlName=" + encodeURI("Controls/Priorities/SetDefaultPriorityList.ascx"), {}, function () {
                slider.prepend("<h3>Set Default Priority List</h3>");
            });
            slider.toggleClass('open');
            return;
        }

        $(".modal-dialog").width(400);
        modal.init({
            controlName: "Controls/Priorities/SetDefaultPriorityList.ascx",
            titleText: "Set Default Priority List"
        });
    }

    function openSwitchListModal() {
        if (typeof slider !== 'undefined') {
            $(".buttons").toggleClass("hidden");
            slider.html(`<div style="margin:50px auto;text-align:center">Loading...please wait <img src="../images/loading.gif" /></div>`);
            slider.load("../JQueryHandler.ashx?ControlName=" + encodeURI("Controls/Priorities/SwitchPriorityList.ascx"), {}, function () {
                slider.prepend("<h3>Switch Priority List</h3>");
                slider.append(`
                    <div class="row">
                        <div class="col text-center mt-3">
                        <button class="btn btn-secondary close-button">Close Window</button>
                        </div>
                    </div>`);
                slider.find(".close-button").on("click", function () {
                    slider.toggleClass('open');
                });
            });
            slider.toggleClass('open');
            return;
        }

        $(".modal-dialog").width(300);
        modal.init({
            controlName: "Controls/Priorities/SwitchPriorityList.ascx",
            titleText: "Switch Priority List/Set",
            width: "200px"
        });
    }

    function openFontModal() {
        modal.init({
            controlName: "Controls/Priorities/Fonts.ascx",
            titleText: "Fonts",
            remoteParams: { FontSize: $("#font-size").val() }
        });
    }

    function openEmailPrioritiesModal() {
        $(".modal-dialog").width(800);

        if (commentSaving) {
            alert("Please wait until your comment has been saved.");
        }
        else {
            var trs = $("table[data-table='task-table'] tr");

            if (trs.length <= 1) {
                alert("Please add at least one task to your priority to continue.");
                return;
            }

            if (typeof slider !== 'undefined') {
                $(".buttons").toggleClass("hidden");
                slider.html(`<div style="margin:50px auto;text-align:center">Loading...please wait <img src="../images/loading.gif" /></div>`);
                slider.load("../JQueryHandler.ashx?ControlName=" + encodeURI("Controls/Priorities/EmailPriorityList.ascx"), { SetId: self.setId }, function () {
                    slider.prepend("<h3>Email Priorities List</h3><hr>");
                    slider.find("button").addClass("btn").addClass("btn-dark").addClass("mb-1");
                    slider.find("button[data-role=send-email]").after(`<button class="btn btn-secondary close-button" style="float:right;width:90px">Cancel</button>`);
                    slider.find("input[type=button]").addClass("btn").addClass("btn-dark").addClass("email-add-button");
                    slider.find("select").addClass("form-control").css("width", "80%");
                    slider.find(".close-button").on("click", function () {
                        slider.toggleClass('open');
                    });
                });
                slider.toggleClass('open');
                return;
            }

            modal.init({
                controlName: "Controls/Priorities/EmailPriorityList.ascx",
                titleText: "Email Priorities List",
                remoteParams: { SetId: self.setId }
            });
        }
    }
    self.openEmailPrioritiesModal = openEmailPrioritiesModal;

    function openPrioritiesScheduleModal() {//added by venkat 08/24/2017
        //var trs = $("table[data-table='task-table'] tr.move-cursor");

        //if (trs.length == 0) {
        //    alert("Please add at least one task to your priority to continue.");
        //    return;
        //}

        modal.init({
            controlName: "Controls/Priorities/SchedulePriorities.ascx",
            titleText: "Schedule Priorities",
            remoteParams: { SetId: self.setId }
        });
    }
    self.openPrioritiesScheduleModal = openPrioritiesScheduleModal;

    function GetPriorityScheduleReport() {
        if (typeof slider !== 'undefined') {
            $(".buttons").toggleClass("hidden");
            openMobileSchedulePriority();
            return;
        }
        // window.open("PrioritiesScheduleReport.aspx", "PrioritiesSchedule", "toolbar=no,status=no,scrollbars=yes,resizable=yes,menubar=no,width=1100,height=700");
        window.open("../SchedulePriorities.aspx", "PrioritiesSchedule", "toolbar=no,status=no,scrollbars=yes,resizable=yes,menubar=yes,width=1100,height=770");
    }
    self.GetPriorityScheduleReport = GetPriorityScheduleReport;

    function GetSupervisorsSchedule() {
        window.open("SupervisorsPrioritySchedule.aspx", "SupervisorsPrioritySchedule", "toolbar=no,status=no,scrollbars=yes,resizable=yes,menubar=no,width=900,height=600");
    }
    self.GetSupervisorsSchedule = GetSupervisorsSchedule;

    function openMessageModal() {
        modal.init({
            controlName: "Controls/Priorities/Message.ascx",
            titleText: "* Important Message",
            remoteParams: { reply: false, respondId: setLockedById, respondName: setLockedByName }
        });
    }

    // Timeout Functionality
    self.resetTimeout = function () {
        var min = 10;
        var d = new Date(); //harmless; client-side for session keeping
        d.setMinutes(d.getMinutes() + min);
        timeout = d;
    };

    function timer() {
        var d = new Date(); //harmless; client-side for session keeping
        var sec = (timeout - d) / 1000;
        if (sec <= 0)
            handleTimeout();
        else {
            if (!setLocked) {
                var min = Math.floor(sec / 60);
                sec -= (min * 60);
                sec = Math.floor(sec);
                if (sec < 10)
                    sec = "0" + sec;
                time.text(min + ":" + sec);
            }
        }
    }

    function handleTimeout() {
        sessionEndingEmail();
        unlockPriorityList(null);
        timedOut = true;
        clearInterval(pollTimer);
        prioritiesList.remove();
        timerSpan.remove();
        timeoutPanel.removeClass("hidden");
    }

    function handleUnload(e) {
        //sessionEndingEmail();
        //unlockPriorityList(e);
    }

    function saveChecklistItemsAjax(items, async) {
        $.ajax({
            url: "../DataService.asmx/SaveChecklistItems",
            type: "POST",
            data: JSON.stringify({ items: items }),
            dataType: "json",
            async: async,
            contentType: "application/json",
            success: function (response) {
                notifier.setMessage("Save successful", "green", 1000);
                for (var i = 0; i < response.d.length; i++) {
                    var item = response.d[i];
                    var itemRow = $("tr[data-checklist-item-id='" + item.ActiveChecklistItemId + "']");
                    itemRow.find("input[data-attr='completed']").prop("checked", item.IsCompleted);
                    itemRow.find("textarea[data-attr='comments']").val(item.Comments);
                    itemRow.find("span[data-attr='completed-by']").text(item.CompletedBy);
                    itemRow.find("span[data-attr='completed-on']").text(item.CompletedOn === null ? "" : item.CompletedOn);
                }
            },
            error: function (xhr, status, e) {
                notifier.setMessage("Error saving", "red", 1000);
            }
        });
    }

    function sessionEndingEmail() {
        $.ajax({
            url: "../DataService.asmx/SessionEndingChangesEmail",
            type: "POST",
            data: JSON.stringify({
                Form: "PrioritiesEmailForm.aspx",
                SetId: self.setId
            }),
            dataType: "json",
            async: false,
            contentType: "application/json",
            success: function (data) {
                for (var i = 0; i < data.d.length; i++) {
                    var pe = data.d[i];
                    var dt = new Date(parseInt(pe.CommentsSince.substr(6)));
                    var commentsSince = dt.getMonth().toString() + "/" + dt.getDate().toString() + "/" + dt.getFullYear().toString();
                    $.ajax({
                        url: "../EmailHandler.ashx",
                        type: "POST",
                        async: false,
                        data: {
                            Form: "PrioritiesEmailForm.aspx",
                            SetId: pe.SetId,
                            EmailAddresses: pe.EmailAddresses,
                            Subject: pe.Subject,
                            ShowBody: pe.ShowBody,
                            Body: pe.Body,
                            CommentsSince: commentsSince,
                            UserId: (pe.SingleUserList) ? pe.UserId : null,
                            Preview: false
                        },
                        success: function (msg, textStatus, request) {
                            notifier.setMessage("Send Successful.", "green", 2000);
                            window.modalModule.hide();
                        },
                        error: function (jqXHR, textStatus, errorThrown) {
                            $("#error").html(jqXHR).show();
                        }
                    });
                }
            },
            error: function (jqXHR, textStatus, errorThrown) {
                $("#error").html(jqXHR).show();
            }
        });
    }

    function unlockPriorityList(e) {
        if (e)
            e.preventDefault();
        if (!setLocked && !timedOut) {
            $.ajax({
                url: "../DataService.asmx/UnlockPriorityListSet",
                type: "POST",
                data: JSON.stringify({ setId: self.setId }),
                contentType: "application/json",
                async: false
            });
        }
    }

    function statusLinkClick(e) {
        var row = $(e.target).closest("tr");
        var reportUserId = row.data("user");
        var taskId = row.data("active-checklist-id");
        $("#acid").val(taskId);
        openCommentModal(taskId, reportUserId, true); // true = open as new/blank
        //openCommentModal(taskId, reportUserId);//changed by venkat on 04/20/2017
    }

    self.saveComment = function () {
        commentSaving = true;
        var taskId = $("#acid").val();
        var comments = $(".modal-body textarea").val();
        $.ajax({
            url: "../DataService.asmx/CreateNewPriorityComment",
            type: "POST",
            data: JSON.stringify({
                taskId: taskId,
                comments: comments,
                isNew: true // Always insert a new comment
            }),
            contentType: "application/json",
            async: false,
            success: function (data) {
                if (comments.trim().length > 0) {
                    var now = new Date();
                    var mm = String(now.getMonth() + 1).padStart(2, '0');
                    var dd = String(now.getDate()).padStart(2, '0');
                    var yyyy = now.getFullYear();
                    var today = mm + '/' + dd + '/' + yyyy;
                    var isoDate = yyyy + '-' + mm + '-' + dd;
                    var userId = $("#set-locked-by-id").val();
                    var commentId = data.d && data.d.Id ? data.d.Id : "";
                    var appName = $("#app-name").val() || "";
                    var initials = $("#initials").val() || "";
                    var fullName = data.d && data.d.FullName ? data.d.FullName : $("#set-locked-by-name").val();
                    var commenterDisplay = (appName.toLowerCase().indexOf("q") >= 0)
                        ? initials
                        : fullName;

                    var commentHtml =
                        "<div class='comment-line sd0 tab-0' data-role='reply-to-comment' " +
                        "data-id='" + commentId + "' " +
                        "data-user-id='" + userId + "' " +
                        "data-commenter='" + userId + "' " +
                        "data-date='" + isoDate + "' " +
                        "style='padding-left: 0px'>" +
                        "<span data-role='comment-text'>[" + today + "] [" + commenterDisplay + "] " + comments + "</span>" +
                        "</div>";

                    var commentsDiv = $("tr [data-active-checklist-id=" + taskId + "]").find(".priority-comment");
                    commentsDiv.append(commentHtml);

                    // Ensure the new comment is clickable/editable
                    bindCommentEvent();
                }

                if (typeof slider !== 'undefined')
                    slider.toggleClass('open');
                else
                    modal.hide();

                commentSaving = false;
            }
        });
    }

    function refreshWindow() {
        document.location.reload();// href = window.location.href;
    }

    self.cancelComment = function () {
        modal.hide();
    }

    // Moving / Deleting Tasks
    function showDragHandle(e) {
        var row = $(e.target).closest("tr");
        row.find("[data-handle='move']").removeClass("hidden");
    }

    function hideDragHandle(e) {
        var row = $(e.target).closest("tr");
        row.find("[data-handle='move']").addClass("hidden");
    }

    function handleDragStart(e) {
        var tableType = $(e.originalEvent.detail.dragTable).data("table");
        if (tableType == "user-table") {
            collapseAll();
            bindExpandAllClick();
            showDeleteRow(e);
        } else if (tableType == "task-table") {
            showDeleteRow(e);
        }
    }

    function handleElementDropped(e) {
        var tableType = $(e.originalEvent.detail.dragTable).data("table");
        hideDeleteRow();
        if (tableType == "user-table") {
            moveOrRemoveUser(e);
        } else if (tableType == "task-table") {
            moveOrRemoveTask(e);
            $("table[data-table='task-table']").each(function () {
                if ($(this).has("tbody tr:not(.hidden)").length == 0) {
                    $(this).hide();
                }
            });
        }
    }

    function handleElementCancel(e) {
        hideDeleteRow();
        expandAll();
        bindCollapseAllClick();
    }


    function moveOrRemoveTask(e) {
        self.resetTimeout();
        var draggedRow = e.originalEvent.detail.draggedRow;
        var dropTarget = $(e.originalEvent.detail.dropTargetRow);
        var dragTable = $(e.originalEvent.detail.dragTable);

        // Defensive: Only allow valid task rows (data-id > 0)
        var draggedId = draggedRow.data("id");
        var dropTargetId = dropTarget.data("id");
        if (!draggedId || isNaN(draggedId) || draggedId <= 0 || !dropTargetId || isNaN(dropTargetId)) {
            return; // Ignore invalid drag/drop
        }

        if (dropTargetId == -1) {
            draggedRow.addClass("hidden");
            removeTask(draggedId, dragTable, $(draggedRow).attr("data-list"));
            draggedRow.remove();
        } else {
            if (dropTarget.data("priority") != draggedRow.data("priority")) {
                moveTask(draggedId, dropTarget.data("priority"), dragTable, $(draggedRow).attr("data-user"));
            } else {
                prioritiesModule.openWindow(draggedRow.data("active-checklist-id"), 'Current');
            }
        }
    }
    function moveDeleteRowToEnd(table) {
        var $table = $(table);
        var $deleteRow = $table.find('tr[data-role="delete-row"]');
        if ($deleteRow.length) {
            $deleteRow.appendTo($table.find('tbody'));
        }
    }

    function moveTask(taskId, priority, table, userId) {
        $.ajax({
            url: "../DataService.asmx/MovePriorityTask",
            type: "POST",
            data: JSON.stringify({
                taskId: taskId,
                priority: priority,
                setId: self.setId,
                userId: userId
            }),
            contentType: "application/json",
            success: function (data) {
                updatePriority(table);
            }
        });
    }

    function removeTask(taskId, table, listId) {
        $.ajax({
            url: "../DataService.asmx/RemovePriorityTask",
            type: "POST",
            data: JSON.stringify({
                taskId: taskId,
                setId: self.setId,
                listId: listId
            }),
            contentType: "application/json",
            success: function (data) {
                updatePriority(table);
            }
        });
    }

    function showDeleteRow(e) {
        var dragRow = $(e.originalEvent.detail.draggedRow);
        var dragTable = dragRow.closest("table");
        visibleDeleteRow = dragTable.find("tr[data-role='delete-row']");
        visibleDeleteRow.removeClass("hidden");
    }

    function hideDeleteRow() {
        if (visibleDeleteRow)
            visibleDeleteRow.addClass("hidden");
    }

    function onMouseUp() {
        hideDeleteRow();
        expandAll();
        bindCollapseAllClick();
    }

    function updatePriority(table) {
        var rows = table.find("tr.webview");
        for (var i = 0; i < rows.length; i++) {
            var $row = $(rows[i]);
            // Only update if not a delete row or completed row
            if ($row.data("id") !== -1) {
                var priority = (parseInt($row.data("priority"), 10) === -1) ? "&nbsp;" : (i + 1);
                $row.data("priority", priority === "&nbsp;" ? -1 : (i + 1));
                var html = '<span class="hidden data-label">Priority</span>' +
                    '<span class="nbr">' + priority + '</span> ' +
                    '<span class="draggable" data-role="dragndrop-dragpoint"></span>';
                $row.find("td.priority-col").html(html);
            }
        }
        fixAllPriorityCells();
        moveDeleteRowToEnd(table);
    }

    function fixAllPriorityCells() {
        $("td.priority-col").each(function (index) {
            var $row = $(this).closest("tr.webview");
            if ($row.length && $row.data("id") !== -1) {
                var priority = $row.data("priority");
                if (priority === undefined || priority === null || priority === "" || priority === -1) {
                    priority = "&nbsp;";
                }
                var html = '<span class="hidden data-label">Priority</span>' +
                    '<span class="nbr">' + priority + '</span> ' +
                    '<span class="draggable" data-role="dragndrop-dragpoint"></span>';
                $(this).html(html);
            }
        });
    }

    // Move / Remove User
    function moveOrRemoveUser(e) {
        self.resetTimeout();
        var draggedRow = e.originalEvent.detail.draggedRow;
        var dropTarget = $(e.originalEvent.detail.dropTargetRow);
        var dragTable = $(e.originalEvent.detail.dragTable);
        if (dropTarget.data("id") == -1) {
            draggedRow.addClass("hidden");
            removeUser(draggedRow.data("list-id"), dragTable);
            draggedRow.remove();
        } else {
            if (dropTarget.data("display-order") != draggedRow.data("display-order")) {
                moveUser(draggedRow.data("list-id"), dropTarget.data("display-order"), dragTable);
            }
        }
        expandAll();
    }

    function moveUser(listId, displayOrder, table) {
        $.ajax({
            url: "../DataService.asmx/MovePriorityUser",
            type: "POST",
            data: JSON.stringify({
                setId: self.setId,
                listId: listId,
                displayOrder: displayOrder
            }),
            contentType: "application/json",
            success: function (data) {
                updateDisplayOrder(table);
            }
        });
    }

    function removeUser(listId, table) {
        $.ajax({
            url: "../DataService.asmx/RemovePriorityUser",
            type: "POST",
            data: JSON.stringify({
                setId: self.setId,
                listId: listId,
            }),
            contentType: "application/json",
            success: function (data) {
                updateDisplayOrder(table);
            }
        });
    }

    function updateDisplayOrder(table) {
        var rows = table.find("tr");
        for (var i = 1; i < rows.length; i++) {
            $(rows[i]).data("display-order", i);
        }
    }

    // Messaging
    function checkForMessages() {
        if (!self.replyMessageOpen) {
            if (!timedOut) {
                $.ajax({
                    url: "../DataService.asmx/CheckForMessages",
                    type: "POST",
                    data: JSON.stringify({
                        setId: self.setId
                    }),
                    contentType: "application/json",
                    success: function (data) {
                        if (data.d != null)
                            handleMessages(data.d);
                    }
                });
            } else {
                clearInterval(pollMessages);
            }
        }
    }

    function handleMessages(message) {
        if (message.Locked != "True") {
            // unlocked currently
            if (setLocked) {
                // it has become unlocked, refresh the page
                self.unobnoxiousReload();
            }
        } else {
            // locked by someone else currently
            if (!setLocked) {
                // somehow its become locked elsewhere. refresh the page
                setLocked = true;
                self.unobnoxiousReload();
            } else {
                // check and make sure the same person has it locked
                if (message.lockedBy != setLockedById) {
                    // new person has it locked, refresh the page
                    self.unobnoxiousReload();
                }
            }
        }

        if (message.Message != null && message.Message.length > 0) {
            self.replyMessageOpen = true;
            modal.init({
                controlName: "Controls/Priorities/Message.ascx",
                titleText: "* Important Message",
                remoteParams: { reply: true, respondTo: message.FromUserId, respondName: message.FromUserName }
            });
        }
    }

    bindCollapseAllClick();

    function openMobileSchedulePriority() {
        slider.html(`
			<h3>Priority Scheduling</h3>
			<hr>
			<div class="set-priority-schedule priority-card mb-3">
				<div class="priority-card-header">
					<span class="actions"><i class="fa fa-plus-square-o"></i></span>
					<h4>Set Priority Schedule</h4>
				</div>
				<div class='priority-section hidden'>
					<fieldset id="scheduleDays">
						<b>Select an Employee</b>
						<select class="form-control" id="ddlPriorityEmployees" onchange="GetEmployeePrioritiesSchedule()"></select>
							
						<b>Select a Deadline Day</b>
						<select id="ddlDays" class="form-control">
							<option value="7">Sunday</option>
							<option value="1">Monday</option>
							<option value="2">Tuesday</option>
							<option value="3">Wednesday</option>
							<option value="4">Thursday</option>
							<option value="5">Friday</option>
							<option value="6">Saturday</option>
						</select>
					</fieldset>
                       
					<fieldset id="scheduleTimes">
						<b>Select a Time</b>
						<select id="txtMeetingStartTime" class="form-control" style="width:120px;"></select>
					</fieldset>

					<div class="mt-3 text-center">
						<button class="btn btn-primary" id="btnSaveSchedule">Save</button>
					</div>

					<table id="tblPriorityListSchedules" class="table mt-3">
						<tbody> </tbody>
					</table>
				</div>
			</div>

			<div class="priority-schedule-history priority-card mb-3">
				<div class="priority-card-header">
					<span class="actions"><i class="fa fa-plus-square-o"></i></span>
					<h4>Priority Schedule History</h4>
				</div>
				<div class='priority-section hidden'>
					<b>Start Date</b>
					<input id="txtStartDate" class="form-control" type="text" />
					
					<b>End Date</b>
					<input id="txtEndDate" class="form-control" type="text" />
					
					<b>Employee</label>
					<select id="ddlPriorityEmployees2" class="form-control"></select>
				 
					<div class="mt-3 text-center">
						<button class="btn btn-primary" id="btnGo">Go</button>
					</div>

					<table id="tblHistoryReport" class="table-responsive"></table>
				</div>
			</div>

			<div class="priority-schedule priority-card mb-3">
				<div class="priority-card-header">
					<span class="actions"><i class="fa fa-plus-square-o"></i></span>
					<h4>Priority Schedule</h4>
				</div>
				<div class='priority-section hidden'>
					<b>Select an Employee</b>
					<select id="ddlPriorityEmployees3" class="form-control"></select>

					<div class="table-responsive mt-3">
						<table id="tblSupervisorReport" class="table"></table>
					</div>
				</div>
			</div>

			<div class="set-priority-schedule priority-card mb-3">
				<div class="priority-card-header">
					<span class="actions"><i class="fa fa-plus-square-o"></i></span>
					<h4>Schedule Reports</h4>
				</div>
				<div class='priority-section hidden'>
					<b>Select a Day</b>
					<select id="ddlDays2" class="form-control">
                        <option value="7">Sunday</option>
                        <option value="1">Monday</option>
                        <option value="2">Tuesday</option>
                        <option value="3">Wednesday</option>
                        <option value="4">Thursday</option>
                        <option value="5">Friday</option>
                        <option value="6">Saturday</option>
					</select>

					<b>Select Number of Days</b>
					<input type="number" id="txtNumberOfDays" class="form-control"/>
					
					<div class="mt-3 text-center">
						<button class="btn btn-primary" id="btnSaveSchedule2">Save</button>
					</div>

					<div class="table-responsive mt-3">
						<table id="tblPriorityListSchedules2" class="table">
							<tbody></tbody>
						</table>
					</div>
				</div>
			</div>

			<div class="set-priority-schedule priority-card mb-3">
				<div class="priority-card-header">
					<span class="actions"><i class="fa fa-plus-square-o"></i></span>
					<h4>Late Reports</h4>
				</div>
				<div id="rptDiv" class='priority-section hidden'>
					<b>Time Span</b>
					<select id="ddlTimeFrame" class="form-control">
						 <option value="1">Last 30 Days</option>
						 <option value="2">Last 365 Days</option>
						 <option value="3">YTD</option>
					</select>

					<div class="mt-3 text-center">
						<button class="btn btn-primary" id="btnEmail">Email</button>
					</div>

					<div class="table-responsive mt-3">
						<table id="tblLateReport" class="table">
							<tbody>
								<tr bgcolor="#b0c4de">
									<th style="text-align:left">Employee</th>
									<th style="text-align:left"># of Times Late Last 30 Days</th>
									<th style="text-align:left">Penalty Charged Last 30 Days</th>
								</tr>
							</tbody>
						</table>
					</div>
				</div>
			</div>

			<div class="set-priority-schedule priority-card mb-3">
				<div class="priority-card-header">
					<span class="actions"><i class="fa fa-plus-square-o"></i></span>
					<h4>Excuse</h4>
				</div>
				<div id="reportCriteria" class='priority-section hidden'>
					<b>Start Date</b>
					<input id="txtStartDate2" class="form-control" type="text" />
					
					<b>End Date</b>
					<input id="txtEndDate2" class="form-control" type="text" />
					
					<div class="mt-3 text-center">
						<button class="btn btn-primary" id="btnExcuse">Go</button>
					</div>

					<div class="table-responsive mt-3">
						<table id="tblExcuseReport" class="table">
							<tbody>
								<tr bgcolor="#b0c4de">
									<th style="text-align:left">Employee</th>
									<th style="text-align:left">Due Date</th>
									<th style="text-align:left"></th>
								</tr>
							</tbody>
						</table>
					</div>
				</div>
			</div>

            <div class="row mb-3">
                <div class="col text-center">
				<button class="btn btn-secondary close-button">Close Window</button>
                </div>
            </div>
			<script src="../Scripts/SchedulePriorities.js"></script>`);
        slider.toggleClass('open');
        setPriorityScheduleHistoryInitialState();
        slider.find("#txtMeetingStartTime").append(listOfTime);
        slider.find(".priority-card-header").on("click", function () {
            var section = $(this).parent().find(".priority-section");
            section.toggleClass("hidden");

            var toggle = $(this).find(".actions .fa");
            if (!section.hasClass("hidden"))
                toggle.removeClass("fa-plus-square-o").addClass("fa-minus-square-o");
            else
                toggle.removeClass("fa-minus-square-o").addClass("fa-plus-square-o");
        });
        slider.find(".close-button").on("click", function () {
            slider.toggleClass('open');
        });
    };

    function setPriorityScheduleHistoryInitialState() {
        $("#ddlTimeFrame").on("click", GetLateReport);
        $("#btnEmail").on("click", EmailLateReport);
        $("#btnExcuse").on("click", GetExcuseReport);
        asyncPostEx("GetRoleId", "", function (msg) {
            if (msg.d < 1) {
                $("#rptDiv").html("You are not authorized to view this report");
                $("#reportCriteria").html("You are not authorized to view this report");
            } else {
                GetLateReport();
                GetExcuseReport();
            }
        });

        $("#btnGo").on("click", GetScheduleReport);
        $("#ddlPriorityEmployees3").on("click", GetEmployeePrioritiesSchedule);
        $("#txtStartDate, #txtEndDate, #txtStartDate2, #txtEndDate2").mobiscroll().date({
            theme: getMobileOperatingSystem(),
            display: 'modal'
        });

        $("#txtStartDate, #txtStartDate2").val("01/01/1900");

        //Problematic new Date(); mostly a default but integral to report view
        var currentDate = new Date();
        var month = currentDate.getMonth() + 1;
        var day = currentDate.getDate();
        var year = currentDate.getFullYear();

        if (day < 10) {
            day = '0' + day;
        }
        if (month < 10) {
            month = '0' + month;
        }
        $("#txtEndDate, #txtEndDate2").val(month + "/" + day + "/" + year);
        $.ajax({
            url: "../DataService.asmx/GetEmployeesForSupervisor",
            type: "POST",
            data: {},
            async: true,
            contentType: "application/json",
            success: function (data) {

                $("#ddlPriorityEmployees2").html(data.d);
                $("#ddlPriorityEmployees2").prepend("<option value=0>All</option>");

                $("#ddlPriorityEmployees3").html(data.d);
                $("#ddlPriorityEmployees3").prepend("<option value=0>All</option>");

                GetScheduleReport();
                GetEmployeePrioritiesSchedule();
            }
        });

        $("#btnSaveSchedule2").click(SaveSchedule2);
        $.ajax({
            url: "../DataService.asmx/GetSupervisorPriorityReportSchedule",
            type: "POST",
            contentType: "application/json",
            success: function (data) {
                PopulateSchedule2(data);
            }
        });
    }
    function GetScheduleReport() {
        asyncPostEx("GetPriorityListScheduleReport",
            JSON.stringify({
                startDate: $("#txtStartDate").val(),
                endDate: $("#txtEndDate").val(),
                employee: $("#ddlPriorityEmployees2 option:selected").text()
            }), function (msg) {
                $("#tblHistoryReport").html(msg.d);
            });
    }
    function GetEmployeePrioritiesSchedule() {
        asyncPostEx("GetSupervisorsPrioritySchedule",
            JSON.stringify({
                employeeId: $("#ddlPriorityEmployees3 option:selected").val()
            }), function (msg) {
                $("#tblSupervisorReport").html(msg.d);
            });
    }
    function SaveSchedule2() {
        $.ajax({
            url: "../DataService.asmx/SaveSupervisorsPrioritiesReportSchedule",
            type: "POST",
            data: JSON.stringify({
                day: $("#ddlDays2 option:selected").val(), offsetDays: $("#txtNumberOfDays").val()

            }),
            contentType: "application/json",
            success: function (data) {
                PopulateSchedule2(data);
            }
        });
    }
    function PopulateSchedule2(data) {
        $("#tblPriorityListSchedules2 tbody").html("<tr><th></th><th>Scheduled Day</th><th>OffSet Days</th></tr>");
        for (var i = 0; i < data.d.length; i++) {
            $("#tblPriorityListSchedules2 tbody").append("<tr><td><a href='#' onclick=prioritiesModule.deleteSchedule2(" + data.d[i].ScheduleID + ") data-role='delete-controller'><img src='/Images/delete.gif' title='Remove' /></a></td><td>" + data.d[i].DaysOfWeek + "</td><td>" + data.d[i].OffsetDays + "</td></tr>");
        }
    }
    self.deleteSchedule2 = function (scheduleId) {
        if (confirm("Are you sure you want to remove this schedule?")) {
            $.ajax({
                url: "../DataService.asmx/DeleteSupervisorPriorityReportSchedule",
                type: "POST",
                data: JSON.stringify({
                    scheduleId: scheduleId

                }),
                contentType: "application/json",
                success: function (data) {
                    PopulateSchedule2(data);
                }
            });
            return;
        }
    };

    function GetLateReport() {
        syncPost("GetPriorityListScheduleReportAll", JSON.stringify({ timeSpan: $("#ddlTimeFrame option:selected").text() }));
        $("#tblLateReport").html(syncPostResult);


    }
    function EmailLateReport() {
        syncPost("EmailPriorityListScheduleReportAll", JSON.stringify({ timeSpan: $("#ddlTimeFrame option:selected").text() }));
        if (syncPostSuccess) {
            alert("Mail Sent Successfully");
        }
    }

    function GetExcuseReport() {
        syncPost("GetPriorityListScheduleReportExcuse", JSON.stringify({ startDate: $("#txtStartDate2").val(), endDate: $("#txtEndDate2").val() }));
        $("#tblExcuseReport").html(syncPostResult);


    }
    function ExcusePriorityLate(employee, scheduledDate) {
        //alert(employee + " " + scheduledDate)
        syncPost("ExcusePriorityLate", JSON.stringify({ employee: employee, scheduledDate: scheduledDate }));
        GetExcuseReport();

    }

    function showAddTaskPanel() {
        if (typeof slider !== 'undefined') {
            slider.toggleClass('open');
        }

        var htmlToAppend = `<div class="task-container">
								<h3>Add Tasks To Priorities</h3>
                                <div id="taskPlaceholder"></div>
                           </div>`;

        slider.html(htmlToAppend);

        var taskTableRow = $('#userTable tr:first');
        targetUserId = taskTableRow.attr('data-user-id');
        targetListId = taskTableRow.attr('data-list-id');

        remoteParams = { TargetUserId: targetUserId, TargetListId: targetListId, Sort: "duetime" }

        $("#taskPlaceholder").empty();
        $("#taskPlaceholder").load("../JQueryHandler.ashx?ControlName=" + encodeURI("Controls/Priorities/AvailableTasks.ascx"), remoteParams, function () {


            $("#taskPlaceholder").append(`<div class="text-center mt-2"><button id="btnCloseWindow" class="btn btn-secondary">Close Window</button></div>`);

        })
    };

    function bindCommentEvent() {
        $("div.priority-comment > div.comment-line").off().on("click", convertToReplyCommentRow);
        //$("div.priority-comment > div.task-comment").off().on("click", convertToReplyCommentRow)
    }

    $(document).on('click', 'a[data-action="add-comment"]', function (e) {
        e.preventDefault();
        var $row = $(this).closest('tr[data-id]');
        var taskId = $row.data('active-checklist-id') || $row.data('id');
        $('#comment-panel').removeClass('hidden');
        $('#taskComments').val('');
        $('#acid').val(taskId);
        $('#taskComments').focus();
    });

    function convertToReplyCommentRow() {
        if ($("textarea.comment-editor").length > 0) {
            alert("You already have a comment open.");
            return;
        }

        let ctl = $(this);
        commentId = ctl.data("id");

        //buildCommentRow(tr);

        var warningText = $("<p data-role='warning' class='yellow-background' style='font-weight:bold;'>Replying to the comment highlighted in yellow.</p>");
        var commentField = $("<textarea class='comment-editor' onkeyup='checkchars(this)' style='width:100%;color:red;height:150px;'>");
        var buttondiv = $("<div data-role='comment-buttons'></div>");
        //var browseField = $("<input onclick='event.cancelBubble=true;' id='browse' style='display: none;' type='file' name='browse'>");

        var saveButton = $("<button class='btn btn-default btn-sm'>Save</button>").attr("data-role", "save");
        //var responseRequestedButton = $("<button class='btn btn-default btn-sm'>Response Requested</button>").attr("data-role", "response-requested");
        var addLinkButton = $("<button class='btn btn-default btn-sm'>Add Link</button>").attr("data-role", "add-link");
        var cancelButton = $("<button class='btn btn-default btn-sm'>Cancel</button>").attr("data-role", "cancel-comment");

        var saveButtonDiv = $("<div style='display:inline-block;width:50%;'/>");
        var responseRequestedButtonDiv = $("<div style='display:inline-block;width:34%;'/>");
        var addLinkButtonDiv = $("<div style='display:none;width:33%;'/>");
        var cancelButtonDiv = $("<div style='text-align:right;width:50%;display:inline-block;'>");

        warningText.insertAfter(ctl);
        commentField.insertAfter(warningText);
        buttondiv.insertAfter(commentField);
        //browseField.appendTo(buttondiv);
        saveButtonDiv.appendTo(buttondiv);
        //responseRequestedButtonDiv.appendTo(buttondiv);
        addLinkButtonDiv.appendTo(buttondiv);
        cancelButtonDiv.appendTo(buttondiv);

        saveButton.appendTo(saveButtonDiv);
        //responseRequestedButton.appendTo(responseRequestedButtonDiv);
        addLinkButton.appendTo(addLinkButtonDiv);
        cancelButton.appendTo(cancelButtonDiv);

        //var commentUserId = ctl.data("userid");
        var commentUserId = ctl.data("user-id");
        var commentDateStr = ctl.data("date");
        var currentUserId = $("#set-locked-by-id").val();

        var isOwn = parseInt(commentUserId) === parseInt(currentUserId);

        // Robust date comparison (local date only)
        var isToday = false;
        if (commentDateStr) {
            var parts = commentDateStr.split("-");
            var commentYear = parseInt(parts[0], 10);
            var commentMonth = parseInt(parts[1], 10) - 1;
            var commentDay = parseInt(parts[2], 10);

            var now = new Date();
            isToday =
                commentYear === now.getFullYear() &&
                commentMonth === now.getMonth() &&
                commentDay === now.getDate();
        }

        if (isOwn && isToday) {
            commentField.data("isReply", "false");
            warningText.hide();
            ctl.hide();

            let txt = ctl.html();
            txt = htmlLinksToLinkTags(txt);

            // Try regex first
            let match = txt.match(/^\s*\[([^\]]+)\]\s*\[([^\]]+)\]\s*([\s\S]*)$/m);
            let commentText;
            if (match) {
                commentText = match[3].trim();
            } else {
                // Fallback: remove prefix by replace
                let prefixMatch = txt.match(/^\s*\[[^\]]+\]\s*\[[^\]]+\]\s*/);
                commentText = prefixMatch ? txt.replace(prefixMatch[0], '') : txt;
                commentText = commentText.trim();
            }
            commentField.val(commentText);
            commentField[0].selectionStart = commentField[0].selectionEnd = commentText.length;

        } else {
            commentField.data("isReply", "true");
            ctl.removeClass("hidden").addClass("override-hidden yellow-background");
        }

        function htmlLinksToLinkTags(comment) {
            comment = comment.replace(/<br\s*\/?>/gi, '\n');
            comment = comment.replace(/<!--a\d+--><a href=(['"])([^'"]+)\1[^>]*><!--\/a\d+-->([^<]+)<!--a\d+--><\/a><!--\/a\d+-->/g, '[link]$2[/link]');
            comment = comment.replace(/<a\s+href=(['"])([^'"]+)\1[^>]*>([^<]+)<\/a>/gi, '[link]$2[/link]');
            comment = comment.replace(/<\/?[^>]+(>|$)/g, "");
            return comment;
        }
        function linkTagsToHtmlLinks(text) {
            text = text.replace(/\[link\](.*?)\[\/link\]/g, function (match, url) {
                return `<a href="${url}" target="_new">${url}</a>`;
            });
            text = text.replace(/\n/g, '<br>');
            return text;
        }

        buttondiv.find("button[data-role=cancel-comment]").on("click", function () {
            ctl.removeClass("yellow-background override-hidden");
            //// Only re-hide if it was hidden before (i.e., not the most recent comment)
            //if (!ctl.hasClass("old")) {
            //	ctl.addClass("hidden");
            //}
            ctl.show();
            warningText.remove();
            commentField.remove();
            buttondiv.remove();
        });

        buttondiv.find("button[data-role=add-link]").on("click", function () {
            commentField.val(commentField.val() + ' [link][/link] ');
            commentField.focus();
            commentField.prop('selectionEnd', commentField.val().length - 8);
        });
        buttondiv.find("button[data-role=save]").on("click", function () {
            let req = {};
            req.commentId = commentId;
            req.comments = linkTagsToHtmlLinks(commentField.val());
            req.taskId = ctl.closest("tr").data("active-checklist-id");


            let method = commentField.data("isReply") == "true" ? "ReplyToComment" : "EditComment";

            $.ajax({
                url: "/DataService.asmx/" + method,
                type: "POST",
                data: JSON.stringify(req),
                contentType: "application/json",
                error: function (jqXHR, textStatus, errorThrown) {
                    alert("There was a problem saving your comment");
                    console.error("AJAX error saving comment", {
                        status: textStatus,
                        error: errorThrown,
                        responseText: jqXHR && jqXHR.responseText
                    });
                },
                success: function (data) {
                    // Build the new comment HTML
                    var now = new Date();
                    var mm = String(now.getMonth() + 1).padStart(2, '0');
                    var dd = String(now.getDate()).padStart(2, '0');
                    var yyyy = now.getFullYear();
                    var today = mm + '/' + dd + '/' + yyyy;
                    var isoDate = yyyy + '-' + mm + '-' + dd;
                    var userId = $("#set-locked-by-id").val();
                    var appName = $("#app-name").val() || "";
                    var initials = $("#initials").val() || "";
                    var fullName = data.d && data.d.FullName ? data.d.FullName : $("#set-locked-by-name").val();
                    var commenterDisplay = (appName.toLowerCase().indexOf("q") >= 0)
                        ? initials
                        : fullName;
                    var commentId = data.d && data.d.Id ? data.d.Id : "";

                    var commentHtml =
                        "<div class='comment-line sd0 tab-0' data-role='reply-to-comment' " +
                        "data-id='" + commentId + "' " +
                        "data-user-id='" + userId + "' " +
                        "data-commenter='" + userId + "' " +
                        "data-date='" + isoDate + "' " +
                        "style='padding-left: 0px'>" +
                        "<span data-role='comment-text'>[" + today + "] [" + commenterDisplay + "] " + req.comments + "</span>" +
                        "</div>";

                    var isReply = commentField.data("isReply") == "true";
                    var commentsDiv = ctl.closest("tr").find(".priority-comment");

                    if (isReply) {
                        // Determine the correct tab level for the reply
                        var parentTabClass = ctl.attr("class").match(/tab-(\d+)/);
                        var replyTab = parentTabClass ? parseInt(parentTabClass[1], 10) + 1 : 1;
                        // Insert the reply after the parent comment
                        var $reply = $(commentHtml)
                            .removeClass(function (i, c) { return (c.match(/(^|\s)tab-\d+/g) || []).join(' '); })
                            .addClass("tab-" + replyTab)
                            .css("padding-left", (replyTab * 30) + "px");
                        ctl.after($reply);
                    } else {
                        // If the comment is now empty, remove it from the DOM
                        if (!req.comments || !req.comments.trim()) {
                            ctl.remove();
                        } else {
                            // Edit: preserve all original attributes and classes
                            var original = ctl[0];
                            var attrs = "";
                            for (var i = 0; i < original.attributes.length; i++) {
                                var attr = original.attributes[i];
                                if (attr.name === "data-id") attrs += " data-id='" + commentId + "'";
                                else if (attr.name === "data-user-id") attrs += " data-user-id='" + userId + "'";
                                else if (attr.name === "data-commenter") attrs += " data-commenter='" + (userId || "") + "'";
                                else if (attr.name === "data-date") attrs += " data-date='" + isoDate + "'";
                                else if (attr.name === "class" || attr.name === "style") continue; // handled below
                                else attrs += " " + attr.name + "='" + attr.value + "'";
                            }
                            var classAttr = ctl.attr("class");
                            if (classAttr) {
                                attrs += " class='" + classAttr + "'";
                            }
                            var styleAttr = ctl.attr("style");
                            if (styleAttr) {
                                attrs += " style='" + styleAttr + "'";
                            }
                            commentHtml =
                                "<div" + attrs + ">" +
                                "<span data-role='comment-text'>[" + today + "] [" + commenterDisplay + "] " + req.comments + "</span>" +
                                "</div>";
                            var $newComment = $(commentHtml);
                            ctl.replaceWith($newComment);
                            $newComment.removeClass("yellow-background override-hidden").show();
                        }
                    }

                    // Clean up the reply UI
                    ctl.removeClass("yellow-background override-hidden").show();
                    warningText.remove();
                    commentField.remove();
                    buttondiv.remove();

                    bindCommentEvent();
                }

            });
        });

        commentField.focus();
    }

    window.fixAllPriorityCells = fixAllPriorityCells;

    // Delegated handler for expand/collapse buttons in the table cell
    $(document).on('click', '[data-role="expand-task"]', function (e) {
        e.preventDefault();
        var $btn = $(this);
        var $img = $btn.find('img');
        // Find the closest row, then the .priority-comment in that row
        var $row = $btn.closest('tr');
        var $priorityComment = $row.find('.priority-comment');
        var $oldComments = $priorityComment.find('.comment-line[data-comment="old"]');

        $oldComments.toggleClass('hidden');
        if ($oldComments.first().hasClass('hidden')) {
            $img.attr('src', '/Images/plus.gif');
            $img.attr('alt', 'Expand task level comments');
        } else {
            $img.attr('src', '/Images/minus.gif');
            $img.attr('alt', 'Collapse task level comments');
        }
    });

    return self;
})();
/* Copyright © 2024 Renegade Swish, LLC */

