var calendarModule = (function () {
    var self = {};
    var datepicker = $("input[data-role='calendar']");
    var select = $("select[data-role='assignees']");
    var dateHeader = $(".day-of-week");
    var assigneeId = queryObj()["assigneeId"];
    var showStatus = queryObj()["showStatus"];
    var filterMask = queryObj()["filterMask"] ? queryObj()["filterMask"] : $("#filterMask").val();

    var alertMenu = $.contextMenu({
        selector: ".alert:not(#legend .alert)",
        trigger: "left",
        items: {
            openTask: {
                name: "Open Task",
                icon: "fa-male",
                callback: function (key, opt) {
                    self.openWindow(opt.$trigger.attr("data-unique-id"),
                        opt.$trigger.attr("data-type"));
                }
            },
            muteAlert: {
                name: "Mute This Alert (Me Only)",
                icon: "fa-window-close",
                callback: function (key, opt) {
                    self.muteAlert(
                        opt.$trigger,
                        opt.$trigger.attr("data-alert-id"),
                        opt.$trigger.attr("data-date"));
                }
            },
            unmuteAlert: {
                name: "Un-Mute This Alert",
                icon: "fa-envelope",
                callback: function (key, opt) {
                    self.unmuteAlert(opt.$trigger,
                        opt.$trigger.attr("data-alert-id"),
                        opt.$trigger.attr("data-date"));
                }
            }
        },
        events: {
            show: function (opt) {
                var emailIcon = opt.$trigger.find("#images i.fa-envelope, #images i.fa-window-close");

                if (emailIcon.hasClass("fa-window-close")) {
                    opt.items.muteAlert.$node.addClass("hide");
                    opt.items.unmuteAlert.$node.removeClass("hide");
                }
                if (emailIcon.hasClass("fa-envelope")) {
                    opt.items.unmuteAlert.$node.addClass("hide");
                    opt.items.muteAlert.$node.removeClass("hide");
                }
            }
        }
    });

    $().ready(function () {
        datepicker.lwDatepicker({ alwaysVisible: true });
        datepicker.change(function () { updateSelection(datepicker.val()); });
        $("#date-selection-calendar div.lw-dp ul.lw-dp-week li")
            .on("dragover", function (event) { calendarModule.itemAllowDrop(event.originalEvent); })
            .on("drop", function (event) { calendarModule.itemDrop(event.originalEvent); });

        $(".lw-dp-next-year, .lw-dp-previous-year, .lw-dp-previous, .lw-dp-next")
            .click(function () {
                setTimeout(function () {
                    $("#date-selection-calendar div.lw-dp ul.lw-dp-week li")
                        .on("dragover", function (event) { calendarModule.itemAllowDrop(event.originalEvent); })
                        .on("drop", function (event) { calendarModule.itemDrop(event.originalEvent); });
                }, 100);
            });
        dateHeader.click(function (e) { updateSelection($(e.currentTarget).closest(".day-of-week-panel").data("date")); });
        select.change(updateAssignee);
        $(document)
            .off('change', "input[data-action^='toggle']")
            .on('change', "input[data-action^='toggle']",
                function (e) { toggleDisplay(e.target); });

        //Set calendar item filters if specified in the query string or session
        if (filterMask) {
            $("input[data-action='toggleActive']").prop("checked", (filterMask & 1) > 0);
            toggleDisplay($("input[data-action='toggleActive']"), (filterMask & 1) > 0);
            $("input[data-action='toggleSoft']").prop("checked", (filterMask & 2) > 0);
            toggleDisplay($("input[data-action='toggleSoft']"), (filterMask & 2) > 0);
            $("input[data-action='toggleOverdue']").prop("checked", (filterMask & 4) > 0);
            toggleDisplay($("input[data-action='toggleOverdue']"), (filterMask & 4) > 0);
            $("input[data-action='toggleAlerts']").prop("checked", (filterMask & 8) > 0);
            toggleDisplay($("input[data-action='toggleAlerts']"), (filterMask & 8) > 0);
            $("input[data-action='toggleCompleted']").prop("checked", (filterMask & 16) > 0);
            toggleDisplay($("input[data-action='toggleCompleted']"), (filterMask & 16) > 0);
            $("input[data-action='toggleFuture']").prop("checked", (filterMask & 32) > 0);
            toggleDisplay($("input[data-action='toggleFuture']"), (filterMask & 32) > 0);
            $("input[data-action='toggleControl']").prop("checked", (filterMask & 64) > 0);
            toggleDisplay($("input[data-action='toggleControl']"), (filterMask & 64) > 0);
            $("input[data-action='toggleSoftReminder']").prop("checked", (filterMask & 128) > 0);
            toggleDisplay($("input[data-action='toggleSoftReminder']"), (filterMask & 128) > 0);
        }
    });

    function toggleDisplay(target, forceValue) {
        var dataAction = $(target).attr("data-action");
        var isChecked = forceValue != undefined ? forceValue : $(target).prop("checked");
        var selector = "";

        if (dataAction == "toggleActive") selector = ".activeTask";
        else if (dataAction == "toggleSoft") selector = ".softDue";
        else if (dataAction == "toggleSoftReminder") selector = ".softDueReminder";
        else if (dataAction == "toggleOverdue") selector = ".overdueTask";
        else if (dataAction == "toggleAlerts") selector = ".alert";
        //Checking either completed tasks or alerts changed visibility of completed alerts.
        //Seemed a bit weird, so now this option only affects tasks.
        else if (dataAction == "toggleCompleted") selector = ".completedTask:not(.alert)";
        else if (dataAction == "toggleFuture") selector = ".futureTask";
        else if (dataAction == "toggleControl") selector = $("i.fa-users").closest("a");

        if (isChecked) $(selector).removeClass(dataAction == "toggleControl" ? "hideControl" : "hide");
        else $(selector).addClass(dataAction == "toggleControl" ? "hideControl" : "hide");

        if ($("#overdue-panel a.bold:not(.hide, .hideControl)").length == 0)
            $("#overdue-panel").hide();
        else
            $("#overdue-panel").show();

        if (forceValue == undefined) {
            filterMask = 0;
            filterMask += $("input[data-action='toggleActive']").prop("checked") ? 1 : 0;
            filterMask += $("input[data-action='toggleSoft']").prop("checked") ? 2 : 0;
            filterMask += $("input[data-action='toggleOverdue']").prop("checked") ? 4 : 0;
            filterMask += $("input[data-action='toggleAlerts']").prop("checked") ? 8 : 0;
            filterMask += $("input[data-action='toggleCompleted']").prop("checked") ? 16 : 0;
            filterMask += $("input[data-action='toggleFuture']").prop("checked") ? 32 : 0;
            filterMask += $("input[data-action='toggleControl']").prop("checked") ? 64 : 0;
            filterMask += $("input[data-action='toggleSoftReminder']").prop("checked") ? 128 : 0;
            if (filterMask)
                asyncPost("SetFilterMask", JSON.stringify({ filterMask: filterMask }));
        }
    }

    function updateSelection(date) {
        $("*").css("cursor", "wait");

        var href = "Calendar.aspx?date=" + date;
        if (assigneeId)
            href += "&assigneeId=" + assigneeId;
        if (showStatus)
            href += "&showStatus=" + showStatus;

        filterMask = 0;
        filterMask += $("input[data-action='toggleActive']").prop("checked") ? 1 : 0;
        filterMask += $("input[data-action='toggleSoft']").prop("checked") ? 2 : 0;
        filterMask += $("input[data-action='toggleOverdue']").prop("checked") ? 4 : 0;
        filterMask += $("input[data-action='toggleAlerts']").prop("checked") ? 8 : 0;
        filterMask += $("input[data-action='toggleCompleted']").prop("checked") ? 16 : 0;
        filterMask += $("input[data-action='toggleFuture']").prop("checked") ? 32 : 0;
        filterMask += $("input[data-action='toggleControl']").prop("checked") ? 64 : 0;
        filterMask += $("input[data-action='toggleSoftReminder']").prop("checked") ? 128 : 0;
        if (filterMask)
            href += "&filterMask=" + filterMask;

        window.location.href = href;
    }

    function updateAssignee() {
        $("*").css("cursor", "wait");

        var selected = select.find("option:selected");
        var selectedString = "";
        $(selected).each(function () {
            selectedString = (selectedString == '')
                ? selectedString + $(this).val()
                : selectedString + "," + $(this).val();
        });
        selected = selectedString;

        //Warn user if they are trying to multi-select a special option
        if (selected.indexOf("-") >= 0 && selected.indexOf(",") >= 0
            && confirm('You have selected an option ("All Tasks I Control") that cannot be combined with any other options. If you continue, only this option will remain selected.\r\n\r\nDo you wish to proceed anyway?'))
            selected = select.find("option:selected").val();

        if (selected.indexOf("*") >= 0) {
            showStatus = true;
            assigneeId = selected.replace(/\*/g, "");
        } else {
            showStatus = false;
            assigneeId = selected;
        }

        filterMask = 0;
        filterMask += $("input[data-action='toggleActive']").prop("checked") ? 1 : 0;
        filterMask += $("input[data-action='toggleSoft']").prop("checked") ? 2 : 0;
        filterMask += $("input[data-action='toggleOverdue']").prop("checked") ? 4 : 0;
        filterMask += $("input[data-action='toggleAlerts']").prop("checked") ? 8 : 0;
        filterMask += $("input[data-action='toggleCompleted']").prop("checked") ? 16 : 0;
        filterMask += $("input[data-action='toggleFuture']").prop("checked") ? 32 : 0;
        filterMask += $("input[data-action='toggleControl']").prop("checked") ? 64 : 0;
        filterMask += $("input[data-action='toggleSoftReminder']").prop("checked") ? 128 : 0;

        window.location.href = "Calendar.aspx?date=" + datepicker.val() + "&assigneeId=" + assigneeId + "&showStatus=" + showStatus + "&filterMask=" + (filterMask ? filterMask : 103);
    }

    self.itemClicked = function (itemSelector, taskId, taskStage, isAlert) {
        if (isAlert) //show a context menu instead
        {
            //menu opens automatically; see "alertMenu" for config
        } else {
            self.openWindow(taskId, taskStage);
        }

    };

    self.itemDragStart = function (event) {
        var dataId = -1;
        var isController = false;

        if ($(event.target).is("div.dayofweekDiv")) {
            dataId = $(event.target).find("a").attr("data-unique-id");
            isController = $(event.target).find("a i.fa-users").length > 0;
        }
        else if ($(event.target).is("div.dayofweekDiv a")) {
            dataId = $(event.target).attr("data-unique-id");
            isController = $(event.target).find("i.fa-users").length > 0;
        }
        else if ($(event.target).is("div.dayofweekDiv a span.itemName")) {
            dataId = $(event.target).closest("a").attr("data-unique-id");
            isController = $(event.target).closest("a").find("i.fa-users").length > 0;
        }

        if (dataId > 0) {
            event.dataTransfer.setData("text", JSON.stringify({ acId: dataId, isController: isController }));
        }
    }

    self.itemAllowDrop = function (event) {
        event.preventDefault();
    }

    self.itemDrop = function (event) {
        var data = JSON.parse(event.dataTransfer.getData("text"))
        var acId = data.acId;
        var isController = data.isController;
        var dragItem = $("div.dayofweekDiv a.activeTask[data-unique-id=" + acId + "], div.dayofweekDiv a.softDue[data-unique-id=" + acId + "], div.dayofweekDiv a.overdueTask[data-unique-id=" + acId + "]");
        var taskId = dragItem.attr("data-unique-id");
        var isSoftDue = $(dragItem).hasClass("softDue");
        var dropItem = $(event.target);
        var fromDate = new Date(dragItem.attr("data-date"));

        //Some browsers will target the specific item dropped onto;
        //make sure we're targeting the .checklist-list div for the day being moved to
        if (dropItem.is("div.day-of-week-panel *") || dropItem.is("table.calendarBlock td"))
            dropItem = dropItem.closest("td").find("div.checklist-list");
        else if (dropItem.is("div.checklist-list *"))
            dropItem = dropItem.closest("div.checklist-list");        

        var toDate = null;
        if (dropItem.is("div.checklist-list")) {
            toDate = new Date(dropItem.closest("div.day-of-week-panel").attr("data-date"));
        }
        else if (dropItem.is("div.lw-dp li")) {
            var monthName = dropItem.closest("div.lw-dp").find("div.lw-dp-toolbar div.lw-dp-monthbar div.lw-dp-month").text();
            var month = -1;
            switch (monthName.substring(0, 3).toLowerCase()) {
                case "jan": month = 0; break;
                case "feb": month = 1; break;
                case "mar": month = 2; break;
                case "apr": month = 3; break;
                case "may": month = 4; break;
                case "jun": month = 5; break;
                case "jul": month = 6; break;
                case "aug": month = 7; break;
                case "sep": month = 8; break;
                case "oct": month = 9; break;
                case "nov": month = 10; break;
                case "dec": month = 11; break;
            }
            if (dropItem.is(".lw-dp-firstweek .lw-dp-neighbour-month-day"))
                month -= 1;
            else if (dropItem.is(".lw-dp-lastweek .lw-dp-neighbour-month-day"))
                month += 1;

            var year = dropItem.closest("div.lw-dp").find("div.lw-dp-toolbar div.lw-dp-yearbar div.lw-dp-year").text();
            var day = dropItem.text();
            toDate = new Date(year, month, day);
        }

        toDate.setHours(fromDate.getHours());
        toDate.setMinutes(fromDate.getMinutes());

        if (fromDate.getTime() - toDate.getTime() == 0) return;

        if (isSoftDue) {
            self.updateReminderTime(taskId, toDate);
        } 
        else if (isController) {
            if (confirm("Do you want to reschedule this item? \n\nItem " + taskId + ' - \"' + (dragItem.find("span.itemName").text())
                + '" \n\nFrom: ' + fromDate.formatDate("M/d/yyyy hh:mm T")
                + " \n\nTo: " + toDate.formatDate("M/d/yyyy hh:mm T")))
                self.updateDueTime(taskId, toDate);
        }
        else {
            var taskStage = dragItem.attr("data-type");
            self.openWindow(taskId, taskStage, toDate);
        }

        event.preventDefault();
    }

    self.updateDueTime = function (taskId, dueDate) {
        $.ajax({
            url: "/DataService.asmx/UpdateDueDate",
            type: "POST",
            data: JSON.stringify({
                taskId: taskId,
                dateTime: dueDate
            }),
            contentType: "application/json",
            success: function (data) {
                window.location.reload(true);
            }
        });
    }

    self.updateReminderTime = function (taskId, softDueDate) {
        $.ajax({
            url: "/DataService.asmx/UpdateReminderDate",
            type: "POST",
            data: JSON.stringify({
                taskId: taskId,
                dateTime: softDueDate
            }),
            contentType: "application/json",
            success: function (data) {
                window.location.reload(true);
            }
        });
    }

    //window.location.reload(true);


    self.openWindow = function (taskId, taskStage, newDueDate) {
        var url = "ManageSingleChecklist.aspx?";
        if (taskId)
            url += "&taskId=" + taskId;
        if (taskStage != null && taskStage != undefined)
            url += "&taskStage=" + taskStage;
        if (newDueDate)
            url += "&newDueDate=" + encodeURI(newDueDate.formatDate("M/d/yyyy hh:mm T"));

        var popupwin = window.open(url, "checklistmini",
            "toolbar=no,status=no,scrollbars=yes,resizable=yes,menubar=no,width=800,height=600");

        popupwin.focus();
        return false;
    }

    self.muteAlert = function (itemSelector, alertID, alertDateTime) {
        asyncPostEx("SetAlertException", JSON.stringify({ alertId: alertID, exceptionTime: alertDateTime }),
            function (msg) {
                itemSelector
                    .find("i.fa-envelope")
                    .removeClass("fa-envelope")
                    .addClass("fa-window-close");
            },
            function (xhr) {
                notifier.setMessage(xhr.responseText, "red", 3000);
            });
    }

    self.unmuteAlert = function (itemSelector, alertID, alertDateTime) {
        asyncPostEx("ClearAlertException", JSON.stringify({ alertId: alertID, exceptionTime: alertDateTime }),
            function (msg) {
                itemSelector
                    .find("i.fa-window-close")
                    .removeClass("fa-window-close")
                    .addClass("fa-envelope");
            },
            function (xhr) {
                notifier.setMessage(xhr.responseText, "red", 3000);
            });
    }

    return self;
})();


//added by Venkat
function ShowPrintPopUP() {

    window.open("Print.aspx", "Print", "toolbar=no,status=no,scrollbars=yes,resizable=yes,menubar=no,width=700,height=600");
    // window.open("PrintOutTest.aspx", "Print", "toolbar=no,status=no,scrollbars=yes,resizable=yes,menubar=no");
}

function GetQuickDeadlineExtensions()//added by venkat 11/01/2017
{
    window.open("QuickDeadlineExtensions.aspx", "QuickDeadlineExtensions", "toolbar=no,status=no,scrollbars=yes,resizable=yes,menubar=no,width=900,height=600");

}
/* Copyright © 2024 Renegade Swish, LLC */

