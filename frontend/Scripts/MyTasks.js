var myTasksModule = (function () {
    var self = {};
    self.checklistModules = [];
    self.searchableTasks = [];
    $().ready(function () {
        //initialize(); return;
        Post("Services/ControlService.asmx/Control_GET", JSON.stringify({ req: "ChecklistHeader" }), function (msg) {
            let ctl = msg.d;

			$(document).on("keydown", function (e) {				
				if (e.ctrlKey && e.altKey && e.key == "e") {
					e.preventDefault();
					GetQuickDeadlineExtensions();
				}
			});
			var req = {};
			req.StartDate = $("#start-date").val();
			req.EndDate = $("#end-date").val();
            req.Recurrence = $("#task-recurrance").val();
			Post("Services/ControlService.asmx/Checklist_GET", JSON.stringify({ req }), function (iMsg) {
                let rsp = iMsg.d;
                searchableTasks = rsp;
				let list = $("#divTaskList");
				list.html("");

                for (let i = 0; i < rsp.length; i++) {
                    let e = rsp[i];
                    let div = $(ctl);

                    div.attr("data-unique-id", e.UniqueId);
                    div.attr("data-task-stage", e.TaskStage);
                    div.attr("data-checklist-id", e.ChecklistId);
                    div.attr("data-status", e.CompletionCssClass);
                    div.find(".checklist-title").attr("title", e.Name).text(e.Name.length > 47 ? e.Name.substr(0, 47) + "..." : e.Name);

                    if (!e.ControllerPartOfAssignee)
                        div.find(".checklist-title").attr("style", "color:#ee9020");

                    var right = div.find(".checklist-right");
                    if (e.PendingChange)
                        right.append(`<i class="fa fa-forward pending-indicator" title='A new deadline of ${e.NewDeadlineText} has been requested for this task'></i>`);

                    if (e.IsRecurring)
                        right.append(`<i class="fa fa-refresh recurring-indicator"></i>`);

                    div.find(".checklist-group").text(e.CompletionString);
                    div.find(".checklist-status").text(e.DisplayDate);

                    list.append(div);
                }

                initialize();
            });
        });

        Post("Services/ControlService.asmx/Control_GET", JSON.stringify({ req: "ChecklistHeader" }), function (msg) {
            let ctl = msg.d;

            var req = {};
            req.StartDate = $("#start-date").val();
            req.EndDate = $("#end-date").val();
            req.Recurrence = $("#task-recurrance").val();
            Post("Services/ControlService.asmx/ChecklistOtherOverdue_GET", JSON.stringify({ req }), function (iMsg) {
                let rsp = iMsg.d;
                let list = $("#divOtherOverdueTaskList");
                list.html("");

                if (rsp.length == 0) {
                    document.getElementById("otherOverdueDiv").style.display = "none";
                }
                else {
                    document.getElementById("otherOverdueDiv").style.display = "inline-grid";
                    for (let i = 0; i < rsp.length; i++) {
                        let e = rsp[i];
                        let div = $(ctl);

                        div.attr("data-unique-id", e.UniqueId);
                        div.attr("data-task-stage", e.TaskStage);
                        div.attr("data-checklist-id", e.ChecklistId);
                        div.attr("data-status", e.CompletionCssClass);
                        div.find(".checklist-title").attr("title", e.Name).text(e.Name.length > 47 ? e.Name.substr(0, 47) + "..." : e.Name);

                        if (!e.ControllerPartOfAssignee)
                            div.find(".checklist-title").attr("style", "color:#ee9020");

                        var right = div.find(".checklist-right");
                        if (e.PendingChange)
                            right.append(`<i class="fa fa-forward pending-indicator" title='A new deadline of ${e.NewDeadlineText} has been requested for this task'></i>`);

                        if (e.IsRecurring)
                            right.append(`<i class="fa fa-refresh recurring-indicator"></i>`);

                        div.find(".checklist-group").text(e.CompletionString);
                        div.find(".checklist-status").text(e.DisplayDate);

                        list.append(div);
                    }
                }

                initialize();
            });
        });
    });

    function initialize() {
        $("a[data-role='save-all']").click(saveAll);
        $("a[data-role='excel-export']").off("click").on("click", exportFile);
        $("#start-date").change(updateStartingDate);
        $("#end-date").change(updateEndingDate);
        $("a[data-action='change-deadline]").show();
        $("[data-role='expand-all']").click(function (e) { loadAllChecklists(); });
        $("[data-role='collapse-all']").click(function (e) { hideAllChecklists(); });
        $(document).on('click', "[data-collapse-target='true']", function (e) { loadChecklistEx(e); });

        resize();
        window.onresize = resize;
        if (acID > 0) {
            $("div[data-unique-id=" + acID + "] i.fa-plus-square-o").click();
        }
    }

    function loadAllChecklists() {
        //window.location = String(window.location).replace("#", "") + "?expandAll=true";
        $(".fa-plus-square-o").each(function (e, i) {
            i.click();
        });
    }

    function hideAllChecklists() {
        //window.location = String(window.location).replace("#", "") + "?expandAll=true";
        $(".fa-minus-square-o").each(function (e, i) {
            i.click();
        });
    }

    function loadChecklist(e, isChecklist) {
        var checklist;
        if (isChecklist)
            checklist = e;
        else
            checklist = $(e.target).closest(".collapsible-item");

        if (checklist.find("div[data-role='checklist-body']").html().length > 0)
            return;
        else {
            var params = {
                UniqueId: checklist.data("unique-id"),
                TaskStage: checklist.data("task-stage")
            };
            var loader = checklist.closest("div[data-role='checklist-holder']");
            loader.load("JQueryHandler.ashx?ControlName=" + encodeURI("Controls/Shared/Checklist.ascx"), params, function () {
                expandObject(loader.find("div[data-role='checklist']"));
                let searchCriteria = $("#txtSearchInput").val().trim();
                if (searchCriteria.length > 0) {
                    removeHighlighting(checklist[0]);
                    highlightSearchResults(checklist[0], searchCriteria);
                }
            });
        }
    }

    function loadChecklistEx(e) {
        var checklist = $(e.target).closest(".collapsible-item");

        if (checklist.find("div[data-role='checklist-body']").html().length > 0)
            return;

        var params = {
            UniqueId: checklist.data("unique-id"),
            TaskStage: checklist.data("task-stage")
        };

        checklist.load("JQueryHandler.ashx?ControlName=" + encodeURI("Controls/Shared/Checklist.ascx"), params, function () {
            expandObject(checklist.find("div[data-role='checklist']"));
            let searchCriteria = $("#txtSearchInput").val().trim();
            if (searchCriteria.length > 0) {
                removeHighlighting(checklist[0]);
                highlightSearchResults(checklist[0], searchCriteria);
            }
        });
    }

    function saveAll() {
        var saves = $("a[data-action='save']");
        if (saves.length > 0) {
            saves.each(function (i, e) { e.click(); });
        }
        else {
            notifier.setMessage("Nothing to save", "yellow", 2000);
        }
    }

	function saveAllChecklistsAjax(items) {
		$.ajax({
			url: "/DataService.asmx/SaveChecklistItems",
			type: "POST",
			data: JSON.stringify({ items: items }),
			dataType: "json",
			contentType: "application/json",
			success: function(response) {
				notifier.setMessage("Save successful", "green", 2000);
				for (var i = 0; i < response.d.length; i++) {
					var item = response.d[i];
					var itemRow = $("tr[data-checklist-item-id='" + item.ActiveChecklistItemId + "']");
					itemRow.find("input[data-attr='completed']").prop("checked", item.IsCompleted);
					itemRow.find("textarea[data-attr='comments']").val(item.Comments);
					itemRow.find("span[data-attr='completed-by']").text(item.CompletedBy);
					itemRow.find("span[data-attr='completed-on']").text(item.CompletedOn === null ? "" : item.CompletedOn);
				}
			},
			error: function(xhr, status, e) {
				notifier.setMessage("Error saving", "red", 2000);
			}
		});
	}

    function exportFile(e) {

        var options = {
            exportType: 'msexcel',
            pageName: 'MyTasksExport.aspx'
        };

        var queryString = serialize(options);
        $('<iframe src=OfficeExportHandler.ashx?' + queryString + '/>').appendTo('body');
    }

	function updateStartingDate() {
		$.ajax({
			url: "/DataService.asmx/UpdatePreferredStartingDate",
			type: "POST",
			data: JSON.stringify({ startDate: $("#start-date").val() }),
			contentType: "application/json",
			success: function() {

			}
		});
	}
	
	function updateEndingDate() {
		$.ajax({
			url: "/DataService.asmx/UpdatePreferredEndingDate",
			type: "POST",
			data: JSON.stringify({ endDate: $("#end-date").val() }),
			contentType: "application/json",
			success: function() {

            }
        });
    }

    return self;
})();

function gotoReport(reportId, type, taskId) {
    if (type == 'Controller') {
        window.location.href = 'MyStatus.aspx?reportID=' + reportId + '&taskID=' + taskId;
    }
    else {
        window.location.href = 'MyInbox.aspx?reportID=' + reportId + '&taskID=' + taskId;
    }
}

function GetQuickDeadlineExtensions()//added by venkat 11/01/2017
{
    window.open("QuickDeadlineExtensions.aspx", "QuickDeadlineExtensions", "toolbar=no,status=no,scrollbars=yes,resizable=yes,menubar=no,width=900,height=600");

}

// Collapsible Section
$(document).ready(function () {
    $(".collapsible .collapse-clicker").click(function () {
        var my = $(this);
        my.closest(".collapsible").toggleClass("collapsed");
        my.toggleClass("fa-arrow-down").toggleClass("fa-arrow-up");
    });
});
/* Copyright © 2024 Renegade Swish, LLC */

