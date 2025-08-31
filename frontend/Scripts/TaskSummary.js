var taskSummaryModule = (function() {
	var self = {};
	var summaryTable = $("#summary-tasks-table");
	var statusTable = $("#status-tasks-table");
	var managedTable = $("#managed-tasks-table");
	var expandAll = $("[data-role='expand-all']");
	var summaryLoaded = false;
	var statusLoaded = false;
	var managedLoaded = false;
	var modal = null;

	var dragTable = null;
	var dragRow = null;
	var isDragging = false;
	var dragOffset = null;
	var ghost = null;
	
	$().ready(function () {
		modal = window.modalModule;
		summaryTable.find("[data-collapse-target='true']").parent().click(function() { getSummaryTasks(); });
		statusTable.find("[data-collapse-target='true']").parent().click(function () { getStatusTasks(); });
		managedTable.find("[data-collapse-target='true']").parent().click(function () { getManagedTasks(); });
		expandAll.click(getAllTasks);
		$(document).on("click", "[data-role='open-current']", function (e) { openCurrent(e); });
		$(document).on("click", "[data-role='open-last']", function (e) { openLast(e); });
		$(document).on("click", "[data-role='open-next']", function (e) { openNext(e); });
		$(document).on("click", "[data-role='open-status']", function (e) { openSetStatus(e); });

		$(document.body).append("<div id='task-drag-ghost'></div>");
		ghost = $("#task-drag-ghost").css("display", "hidden").css("opacity", 0.4).css("position", "absolute");

		resize();
		window.onresize = resize;
	});

	function resize() {
		$("#site-main").height(($(window).height() - $("#site-nav").outerHeight() - $("#site-footer").outerHeight() - 4) + "px");
		$("#site-main").css("margin-top", ($("#site-nav").outerHeight()) + "px");
	}

	$(document).on('mousedown', "[data-is-dragpoint]", function (e) {
		if (e.button != 0)
			return;
		dragRow = $(e.target).closest("tr");
		dragTable = dragRow.closest("table");
		if (!dragRow || !dragTable)
			return;
		isDragging = true;
		e.preventDefault();
		var rowOffset = $(dragRow).offset();
		dragOffset = [e.pageX - rowOffset.left, e.pageY - rowOffset.top];
	});

	$(document).mousemove(function (e) {
		if (isDragging) {
			if ($(ghost).not("visible")) {
				//make ghost visible only when the mouse is moved after mousedown
				$(ghost).empty()
					.append($(dragRow).clone())
					.show();
			}
			$(ghost).offset({ top: e.pageY - dragOffset[1], left: e.pageX - dragOffset[0] });
		}
	}).mouseup(function (e) {
		if (isDragging && e.button == 0) {
			$(ghost).hide();
			var underElement = document.elementFromPoint(e.clientX, e.clientY);
			dropTarget = $(underElement).closest("[data-drop-sid]");
			if (dropTarget.length > 0) {
				handleDrop(dropTarget, dropTarget.data('drop-sid'), dragRow.data('drop-from-id'), dragRow.data('drop-type'));
			}

			isDragging = false;
			dragRow = null;
			dragTable = null;
			hoverRow = null;
			dragOffset = null;
		}
	});

	function handleDrop(dropTarget, toId, fromId, moveType) {
		console.log([toId, fromId, moveType]);
		target = null;
		data = null;
		if (toId == -1) {
			if (moveType == 2) {
				target = "../DataService.asmx/DeleteInstanceTaskType";
				data = {taskId: fromId};
			}
			else
				return;
		}
		else if (moveType == 1) {
			target = "../DataService.asmx/AddInstanceTaskType";
			data = {instanceId: fromId, taskType: toId};
		}
		else {
			target = "../DataService.asmx/AddActiveTaskType";
			data = { taskId: fromId, taskType: toId };
		}

		$.ajax({
			url: target,
			type: "POST",
			data: JSON.stringify(data),
			contentType: "application/json",
			success: function () {
				//if (dropTarget.closest("#summary-tasks-table").length > 0)
					getSummaryTasks(true);
				//else if (dropTarget.closest("#status-tasks-table").length > 0)
					getStatusTasks(true);
				//else if (dropTarget.closest("#managed-tasks-table").length > 0)
					getManagedTasks(true);
			}
		});
	}
	
	function getSummaryTasks(allowReload) {
		if (summaryLoaded == true && !allowReload)
			return;
		if (!allowReload)
			$("#summary-tasks-table #throbber").removeClass("hidden");
		$.ajax({
			url: "../JQueryHandler.ashx?ControlName=" + encodeURI("Controls/TaskSummary/TasksPanel.ascx") + "&type=summary",
			type: "GET",
			success: function (htmlResult) {
				if (!allowReload)
					$("#summary-tasks-table #throbber").addClass("hidden");
				summaryTable.find("table").html(htmlResult);
				summaryLoaded = true;
			}
		});
	}
	
	function getStatusTasks(allowReload) {
		if (statusLoaded == true && !allowReload)
			return;
		if (!allowReload)
			$("#status-tasks-table #throbber").removeClass("hidden");
		$.ajax({
			url: "../JQueryHandler.ashx?ControlName=" + encodeURI("Controls/TaskSummary/StatusTasks.ascx"),
			type: "GET",
			success: function (htmlResult) {
				if (!allowReload)
					$("#status-tasks-table #throbber").addClass("hidden");
				statusTable.find("tbody").html(htmlResult);
				statusLoaded = true;
			}
		});
	}

	function getManagedTasks(allowReload) {
		if (managedLoaded == true && !allowReload)
			return;
		if (!allowReload)
			$("#managed-tasks-table #throbber").removeClass("hidden");
		$.ajax({
			url: "../JQueryHandler.ashx?ControlName=" + encodeURI("Controls/TaskSummary/TasksPanel.ascx") + "&type=managed",
			type: "GET",
			success: function (htmlResult) {
				if (!allowReload)
					$("#managed-tasks-table #throbber").addClass("hidden");
				managedTable.find("tbody").html(htmlResult);
				managedLoaded = true;
			}
		});
	}
	
	function getAllTasks() {
		if(!summaryLoaded)
			getSummaryTasks();
		if(!statusLoaded)
			getStatusTasks();
		if(!managedLoaded)
			getManagedTasks();
	}
	
	function openCurrent(e) {
		var task = $(e.currentTarget).closest("tr");
		openManageSingleChecklist(1, task.data("active-id"));
	}
	
	function openLast(e) {
		var task = $(e.currentTarget).closest("tr");
		openManageSingleChecklist(task.data("history-type"), task.data("history-id"));
	}
	
	function openNext(e) {
		var task = $(e.currentTarget).closest("tr");
		openManageSingleChecklist(3, task.data("upcoming-id"));
	}

	function openManageSingleChecklist(taskStage, taskId) {
		window.open("../ManageSingleChecklist.aspx?taskId=" + taskId + "&taskStage=" + taskStage);
	}
	
	function openSetStatus(e) {
		var task = $(e.currentTarget).closest("tr");
		modal.init({
			controlName: "Controls/TaskSummary/SetStatus.ascx",
			titleText: "Status Reports:",
			remoteParams: { InstanceId: task.data("instance-id") }
		});
	}

	bindExpandAllClick();

	return self;
})()
/* Copyright © 2024 Renegade Swish, LLC */

