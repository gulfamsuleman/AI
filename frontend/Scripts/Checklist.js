var checklistModule = (function () {
    var self = {};
    var modal = null;
    self.dirtyFlag = false;
    self.uniqueId = -1;

    $().ready(function () {
        modal = window.modalModule;
        $(document).off('click', "a[data-action='view-alerts']").on('click', "a[data-action='view-alerts']", function (e) { openViewAlerts(e); });
        $(document).off('click', "a[data-action='manage-tasks']").on('click', "a[data-action='manage-tasks']", function (e) { openManageTasks(e); });
        $(document).off('click', "a[data-action='add-to-priorities']").on('click', "a[data-action='add-to-priorities']", function (e) { addToPriorities(e); });
        $(document).off('click', "a[data-action='change-deadline']").on('click', "a[data-action='change-deadline']", function (e) { openChangeDeadline(e); });
        $(document).off('click', "a[data-action='save']").on('click', "a[data-action='save']", function (e) { submitChecklist(e); });
        $(document).off('click', "a[data-action='na']").on('click', "a[data-action='na']", function (e) { naChecklist(e); });
        $(document).off('click', "a[data-action='na-submit']").on('click', "a[data-action='na-submit']", function (e) { naSubmit(e); });
        $(document).off('click', "a[data-action='export']").on('click', "a[data-action='export']", function (e) { exportChecklist(e); });
        $(document).off('click', "a[data-action='reopen']").on('click', "a[data-action='reopen']", function (e) { reopenChecklist(e); });
        $(document).off('click', "a[data-action='start']").on('click', "a[data-action='start']", function (e) { startChecklist(e); });
        $(document).off('click', "a[data-action='complete']").on('click', "a[data-action='complete']", function (e) { completeChecklist(e); });
        $(document).off('dblclick', ".checklist-item-comment").on('dblclick', ".checklist-item-comment", function (e) { expandComment(e); });
        $(document).off('change', "div[data-role='checklist'] input").on('change', "div[data-role='checklist'] input", function (e) { toggleCheckbox(e); });
        if ($("#hide-change-deadline").val() == "True") {
            $("a[data-action='change-deadline']").hide();
        }
        if ($("#expand-all").val() == "True") {
            expandAll();
            $("[data-role='expand-all']").unbind('click');
            bindCollapseAllClick();
        }
    });

    function now() {
        //problematic "new Date()"; leaving in place for now b/c the only usage is purely client-side 
        //(and is replaced with data from the server on next page load) but we need better
        var date = new Date();
        var hours = date.getHours();
        var minutes = date.getMinutes();
        var seconds = date.getSeconds();
        var ampm = hours >= 12 ? 'PM' : 'AM';
        hours = hours % 12;
        hours = hours ? hours : 12; // the hour '0' should be '12'
        minutes = minutes < 10 ? '0' + minutes : minutes;
        seconds = seconds < 10 ? '0' + seconds : seconds;
        var strTime = hours + ':' + minutes + ':' + seconds + ' ' + ampm;
        return date.getMonth() + 1 + "/" + date.getDate() + "/" + date.getFullYear() + "  " + strTime;
    }

    function toggleCheckbox(e) {
        self.dirtyFlag = true;
        self.uniqueId = getChecklist(e).data("unique-id");
        checkCompleteStatus(e, false);
    }

    function showCheck(ctl) {
        ctl.addClass("green-check");
        setTimeout(function () {
            ctl.addClass("fade-out");
            setTimeout(function () {
                ctl.removeClass("green-check").removeClass("fade-out");
            }, 2000);
        }, 1000);
    }

    function checkCompleteStatus(e, isChecklist) {
        var checklist;
        if (isChecklist)
            checklist = e;
        else
            checklist = getChecklist(e);
        var disableCompleteButton = checklist.find('input:checkbox:not(:checked)').length > 0;
        if (disableCompleteButton && checklist.find('input:checkbox').length == 1)
            disableCompleteButton = false;
        if (disableCompleteButton) {
            checklist.find("a[data-action='complete']").attr('disabled', true);
        } else {
            checklist.find("a[data-action='complete']").attr('disabled', false);
        }
    }

    function addToPriorities(e) {
        var taskId = $(e.target).closest("div.active-checklist").attr("data-unique-id");
        $.ajax({
            url: "/DataService.asmx/AddPriorities",
            type: "POST",
            data: JSON.stringify({
                taskId: taskId,
            }),
            contentType: "application/json",
            success: function (data) {
                data.d ? alert("Task Added") : alert("There was a problem adding your task");
            }
        });
    }

    function openViewAlerts(e) {
        e.stopPropagation();
        var checklist = getChecklist(e);
        modal.init({
            titleText: "View Alerts",
            controlName: "Controls/Shared/ViewAlerts.ascx",
            remoteParams: { UniqueId: checklist.data("unique-id"), TaskStage: checklist.data("task-stage") }
        });
    };

    function openChangeDeadline(e) {
        var taskId = $(e.target).closest("div.active-checklist").attr("data-unique-id");
        var taskStage = "Current";
        var popupwin = window.open("ManageSingleChecklist.aspx?taskId=" + taskId + "&taskStage=" + taskStage + "&headerOnly=1", "checklistmini", "toolbar=no,status=no,scrollbars=yes,resizable=yes,menubar=no,width=1280,height=400");
        popupwin.focus();
        popupwin.onbeforeunload = function () {
            if (window.opener) {
                window.opener.location.reload();
            }
        }
    }

    function openManageTasks(e) {
        e.stopPropagation();
        var checklist = getChecklist(e);
        if (window.opener && !window.opener.closed) {
            window.opener.location.href = "ManageTasks.aspx?checklistId=" + checklist.data("checklist-id");
            window.close();
        }
        else {
            window.location.href = "ManageTasks.aspx?checklistId=" + checklist.data("checklist-id");
        }
    }

    $(document).ready(function () {
        $("body").off("click", "a[data-action='view-history']").on("click", "a[data-action='view-history']", function (e) {
            var checklist = getChecklist(e);
            //checklist.data("unique-id")
            openHistory(checklist.data("checklist-id"), checklist.data("unique-id"));
        });
    });

    function submitChecklist(e) {
        var checklist = getChecklist(e);
        saveChecklistItems(self.getActiveChecklistItems(checklist));
    }

    self.getActiveChecklistItems = function (checklist) {
        items = [];
        var checklistItems = checklist.find("tr[data-checklist-item-id]");
        for (var i = 0; i < checklistItems.length; i++) {
            var toAdd = {};
            toAdd.ActiveChecklistId = checklist.data("unique-id");
            toAdd.ActiveChecklistItemId = parseInt($(checklistItems[i]).data("checklist-item-id"));
            toAdd.Comments = $(checklistItems[i]).find("textarea[data-attr='comments']").hasElements() ?
				$(checklistItems[i]).find("textarea[data-attr='comments']").val() : "";
            toAdd.IsCompleted = $(checklistItems[i]).find("input[data-attr='completed']").is(':checked') ? true : false;
            items.push(toAdd);
        }
        return items;
    };

    function saveChecklistItemsAjax(items, async) {
        $.ajax({
            url: "/DataService.asmx/SaveChecklistItems",
            type: "POST",
            data: JSON.stringify({ items: items }),
            dataType: "json",
            async: async,
            contentType: "application/json",
            success: function (response) {
                notifier.setMessage("Save successful", "green", 1000);
                for (var i = 0; i < response.d.length; i++) {
                    var item = response.d[i];
                    var itemRow = $("div[data-unique-id='" + item.ActiveChecklistId + "'] tr[data-checklist-item-id='" + item.ActiveChecklistItemId + "']");
                    itemRow.find("input[data-attr='completed']").prop("checked", item.IsCompleted);
                    itemRow.find("textarea[data-attr='comments']").val(item.Comments);
                    if (i == response.d.length - 1) {
                        showCheck(itemRow.find("textarea[data-attr='comments']").parent());
                    }
                    itemRow.find("span[data-attr='completed-by']").text(item.CompletedBy);
                    itemRow.find("span[data-attr='completed-on']").text(item.CompletedOn === null ? "" : item.CompletedOn);
                }
            },
            error: function (xhr, status, e) {
                notifier.setMessage("Error saving", "red", 1000);
            }
        });
    }

    
    function CheckPopup(checklist, na) {
        $.ajax({
            url: "/DataService.asmx/RequirePopup",
            type: "POST",
            data: "",
            dataType: "json",
            async: true,
            contentType: "application/json",
            success: function (response) {
                if (response.d.length > 0) {
                    $.prompt(response.d, {
                        position: "center",
                        classes: {
                            prompt: 'impromptu-box'
                        },
                             buttons: { "Yes": true, "No": false },
                             submit: function (z, v, m, f) {
                             z.preventDefault();
                                 $.prompt.close();
                                 if (v) {
                                     completeChecklistProceed(checklist, na);
                                 }
                          }
                     });
                }
                else {
                    completeChecklistProceed(checklist, na);
                }
            },
            error: function (xhr, status, e) {
                return;
            }
        });
    }

    function saveChecklistItems(items) {
        saveChecklistItemsAjax(items, true);
    }

    function completeChecklist(e) {
        var checklist = getChecklist(e);
        var na = ($(e.currentTarget).data("action") == "na-submit");
        if (na) {
            completeChecklistProceed(checklist, na);
        }
        else {
            CheckPopup(checklist, na);
        }
    }

    function completeChecklistProceed(checklist, na) {
        if (checklist.find('input:checkbox').length > 1) {
            completeChecklistAjax(checklist, na);
        } else {
            completeSingleItemChecklist(checklist, na);
        }
    }

    function expandComment(e) {
        $(e.target).css("height", "200px");
    }

    function completeChecklistAjax(checklist, na) {
        saveChecklistItemsAjax(self.getActiveChecklistItems(checklist), false);
        var naReason = checklist.find(".na-reason").val();
        $.ajax({
            url: "/DataService.asmx/CompleteChecklist",
            type: "POST",
            data: JSON.stringify({ uniqueId: checklist.data("unique-id"), na: na, naReason: naReason }),
            dataType: "json",
            contentType: "application/json",
            success: function (response) {
                if (window.opener) {
                    try{
                    // Opener was the My Status tab
                    if (window.opener.location.toString().indexOf("MyStatus.aspx") >= 0) 
                    {
                        window.opener.$("tr[data-id=" + response.d.CompletedUniqueID.toString() + "] a[data-role=complete-task]").click();
                    }

                    // Opener was the Calendar tab
                    if (window.opener.location.toString().indexOf("Calendar.aspx") >= 0) 
                    {
                        // If there is a reminder for this task showing on the calendar, get rid of it.
                        window.opener.$('[data-active-checklist-id="' + response.d.CompletedUniqueID + '"].green').hide();
                        // Show the checklist as completed
                        var taskToComplete = window.opener.$('[data-active-checklist-id="' + response.d.CompletedUniqueID + '"]');
                        taskToComplete.removeClass("blue").removeClass("red").removeClass("bold");
                        if (taskToComplete.parents("[id=overdue-panel]").length > 0) {
                            taskToComplete.hide();
                            //if (taskToComplete.siblings(".red").length == 0) {
                            if (taskToComplete.parent().siblings().children(".red").length == 0) {
                                taskToComplete.closest(".day-of-week-panel").hide();
                            }
                        } else {
                            taskToComplete.addClass("grey").addClass("strikethrough");
                            taskToComplete.removeClass("activeTask");
                            taskToComplete.addClass("completedTask");

                            //if completed tasks are hidden, add the appropriate class to hide it
                            if (!(window.opener.$('input[data-action="toggleCompleted"]').is(":checked"))) {
                                taskToComplete.addClass("hide");
                            }

                            if (na) {
                                taskToComplete.find("#images").append("<span class='IsNA'>[N/A]</span>");
                            }
                        }

                        // Show the next occurrence as activated
                        window.opener.$('[data-upcoming-id="' + response.d.UpcomingDueTimeID + '"]')
                            .removeClass("grey").removeClass("italic")
                            .addClass("blue").addClass("bold")
                            .attr("onclick", "return calendarModule.openWindow(" + response.d.NewActiveChecklistID + ", 'Current')")
                            .attr("data-type", "Current")
                            .attr("data-upcoming-id", "");
                    }

                    // Opener was Reports tab
                    if (window.opener.location.toString().indexOf("Reports.aspx") >= 0) {
                        window.opener.$("tr[data-id=" + response.d.CompletedUniqueID.toString() + "]").hide();
                    }
					
					 // Opener was Priorities tab
                    if (window.opener.location.toString().indexOf("Priorities.aspx") >= 0) {//added by venkat 04/20/2017
                        window.opener.location.reload();
                    }
					
					
					}
                      
					finally
					{		
                    				
                    // In all cases, close the window
                    window.close();
					}
                } else {
                    collapseObject(checklist);
                    notifier.setMessage("Task Completed", "green", 1000);
                    checklist.attr("data-status", "completed");
                    checklist.find("span[class='checklist-group']").text("Completed");
                    
                    checklist.find("span.checklist-status").text(now());
                    showReopenLink(checklist);
                    var detached = checklist.parent().detach();
                    $("[data-role='checklist-holder']:last").after(detached);
                }
            },
            error: function (jqXHR, textStatus, errorThrown) {
                alert("An error occurred while processing your request.");
            }
        });
    }

    function completeSingleItemChecklist(checklist, na) {
        checklist.find("input:checkbox").prop("checked", "checked");
        completeChecklistAjax(checklist, na);
    }

    function naChecklist(e) {
        var checklist = getChecklist(e);
        var items = self.getActiveChecklistItems(checklist);
        for (var i = 0; i < items.length; i++) {
            items[i].IsCompleted = true;
            items[i].Comments = "N/A";
        }
        saveChecklistItems(items);
        $(e.currentTarget).prev().removeAttr('disabled');
        $(".na-row").hide();
        $("div[data-role='checklist'] a[data-action='na']").show();

        var $submissionRow = $(e.currentTarget).closest("tr.submission-row");
        var $naRows = $submissionRow.nextAll("tr.na-row").slice(0, 2).show();

        $naRows.first().find("textarea.na-reason").focus();

        $(e.currentTarget).hide();
    }

    function naSubmit(e) {
        var checklist = getChecklist(e);
        var nareason = checklist.find(".na-reason").val();
        if (nareason == "") {
            alert("You must provide a reason for closing this task as N/A");
        } else {
            $(".na-row").hide();
            completeChecklist(e);
        }
        
    }

    function exportChecklist(e) {
        var checklist = getChecklist(e);
        var options = {
            exportType: 'msexcel',
            pageName: 'ChecklistExport.aspx',
            checklistId: checklist.data("unique-id"),
            taskStage: checklist.data("task-stage")
        };

        var queryString = serialize(options);
        $('<iframe class="hidden" src=OfficeExportHandler.ashx?' + queryString + '/>').appendTo('body');
    }

    function reopenChecklist(e) {
        var checklist = getChecklist(e);
        $.ajax({
            url: "/DataService.asmx/ReOpenTask",
            type: "POST",
            data: JSON.stringify({
                taskId: checklist.data("unique-id"),
                reportId: 0 // Pass in zero cause the function does not need a reportId for this task
            }),
            contentType: "application/json",
            success: function (data) {
                var dueDate = new Date(data.d.Result);
                var localNow = new Date(data.d.TimeString);

                var h = dueDate.getHours();
                var t = h > 11 ? "PM" : "AM";
                h = h == 0 ? 12 : h < 13 ? h : (h % 13) + 1;
                var m = dueDate.getMinutes();
                m = m < 10 ? "0" + m : m;
                var s = dueDate.getSeconds();
                s = s < 10 ? "0" + s : s;
                checklist.find("span.checklist-status").text((dueDate.getMonth() + 1) + "/" + dueDate.getDate() + "/" + dueDate.getFullYear() + " " + h + ":" + m + ":" + s + " " + t);

                
                if (dueDate < localNow) {
                    checklist.attr("data-status", "overdue");
                    checklist.find("span[class='checklist-group']").text("Overdue");
                } else {
                    checklist.attr("data-status", "normal");
                    checklist.find("span[class='checklist-group']").text("Due");
                }
                showSaveBlock(checklist);
                if (window.opener) {
                    window.opener.$('[data-active-checklist-id="' + checklist.data("unique-id") + '"]')
                        .removeClass("grey").removeClass("italic").removeClass("strikethrough")
                        .addClass("blue").addClass("bold");
                }
            }
        });
    }

    function startChecklist(e) {
        var checklist = getChecklist(e);
        $.ajax({
            url: "/DataService.asmx/StartChecklist",
            type: "POST",
            data: JSON.stringify({
                upcomingId: checklist.data("unique-id"),
                instanceId: checklist.data("identifier")
            }),
            contentType: "application/json",
            success: function (data) {
                let uniqueId = data.d.Result;
                let localNow = new Date(data.d.TimeString);
                if (window.opener) {
                    // Show this occurrence as activated
                    window.opener.$('[data-upcoming-id="' + checklist.data("unique-id") + '"]')
                        .removeClass("grey").removeClass("italic")
                        .addClass("blue").addClass("bold")
                        .attr("onclick", "return calendarModule.openWindow(" + uniqueId + ", 'Current')")
                        .attr("data-type", "Current")
                        .attr("data-upcoming-id", "")
                        .attr("data-active-checklist-id", uniqueId);
                }
                checklist.data("unique-id", uniqueId);
                checklist.data("identifier", uniqueId);
                showSaveBlock(checklist);
                //below are used for manage single checklist
                $("#task-id").val(uniqueId);
                $(".show-on-open").removeClass("hidden");

                var dueDate = new Date(Date.parse(checklist.find("span.checklist-status").text()));
                if (dueDate < localNow) {
                    checklist.attr("data-status", "overdue");
                    checklist.find("span[class='checklist-group']").text("Overdue");
                } else {
                    checklist.attr("data-status", "normal");
                    checklist.find("span[class='checklist-group']").text("Due");
                }
            }
        });
    }

    function showSaveBlock(checklist) {
        checklist.find("#save-block").removeClass("hidden");
        checklist.find("a[data-action='start']").addClass("hidden");
        checklist.find("a[data-action='reopen']").addClass("hidden");
    }

    function showReopenLink(checklist) {
        checklist.find("#save-block").addClass("hidden");
        checklist.find("a[data-action='reopen']").removeClass("hidden");
    }

    function getChecklist(e) {
        return $(e.currentTarget).closest("div[data-role='checklist']");
    }

    return self;
})()
/* Copyright © 2024 Renegade Swish, LLC */

