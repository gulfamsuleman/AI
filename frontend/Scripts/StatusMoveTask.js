var statusMoveTask = (function () {
	var self = {};
	var moveTaskPanel = $("#move-task-panel");

	$().ready(function () {
	    moveTaskPanel.on("click", "button[data-role='go']", function (e) {
			moveTask();
		});
	});

	function moveTask() {
		var selectedSection = $("#Select1 option:selected").val();
		var selectedReport = statusReportModule.reportId;
		$.ajax({
			url: "DataService.asmx/MoveTask",
			type: "POST",
			data: JSON.stringify({
			    taskId: statusReportModule.rightClickTaskId,
				sectionId: selectedSection,
				reportId: selectedReport
			}),
			contentType: "application/json",
			success: function (data) {
			    window.modalModule.hide();
				data.d ?
					notifier.setMessage("Task Moved.", "green", 2000) :
					notifier.setMessage("Unable to move task. Make sure the task is not already on the report you are moving to.", "red", 2000);
				window.location.reload();
			}
		});
	}

	return self;
})()
/* Copyright © 2024 Renegade Swish, LLC */

