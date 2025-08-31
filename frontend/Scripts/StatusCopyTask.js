var statusCopyTask = (function () {
	var self = {};
	var copyTaskPanel = $("#copy-task-panel");
	
	$().ready(function () {
		copyTaskPanel.on("click", "button[data-role='go']", function (e) {
			copyTask();
		});
	});

	function copyTask() {
		var selectedSection = $("#Select1 option:selected").val();
		$.ajax({
			url: "/DataService.asmx/CopyTask",
			type: "POST",
			data: JSON.stringify({ 
			    taskId: statusReportModule.rightClickTaskId,
				sectionId: selectedSection 
			}),
			contentType: "application/json",
			success: function (data) {
			    window.modalModule.hide();
				data.d ?
					notifier.setMessage("Task Copied.", "green", 2000) :
					notifier.setMessage("Unable to copy task. Make sure the task is not already on the report you are copying to.", "red", 2000);
				window.location.reload();
			}
		});
	}

	return self;
})()
/* Copyright © 2024 Renegade Swish, LLC */

