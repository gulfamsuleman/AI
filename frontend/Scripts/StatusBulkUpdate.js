var bulkUpdateModule = (function() {
	var self = {};
	var checkAll = $("input[data-role='select-all-tasks']");
	var checkDueTomorrow = $("input[data-role='select-due-tomorrow']");
	var task = $("input[data-role='task']");
	var checkboxes = $("#bulk-update-step-2 input[data-role='task']");
	var updateDate = $("input[data-role='update-soft-due']");
	var addComment = $("input[data-role='add-comments']");
	var comment = $("textarea[data-role='comment']");
	var datepicker = $("input[data-role='datepicker']");

	$().ready(function() {
		datepicker.lwDatepicker({ autoFillToday: true });
		$("[data-role='next-step']").click(goToStepTwo);
		checkAll.click(toggleCheckAllTasks);
		checkDueTomorrow.click(toggleCheckAllTasksDueTomorrow);
		task.click(clearMainOptions);
		$("[data-role='save-update']").click(submitBulkUpdates);
	});

	function goToStepTwo() {
		if (!$.trim(comment.val()) && addComment.prop("checked") == true)
			alert("Add Comments is checked but no comment has been entered.");
		else
			showSection($("#bulk-update-step-2"));
	}
	
	function showSection(section) {
		$("#bulk-update-panel").children().addClass("hidden");
		section.removeClass("hidden");
	}
	
	function toggleCheckAllTasks() {
		checkDueTomorrow.prop("checked", false);
		if(checkAll.prop("checked") == true)
			checkboxes.prop("checked", true);
		else
			checkboxes.prop("checked", false);
	}
	
	function toggleCheckAllTasksDueTomorrow() {
		checkAll.prop("checked", false);
		checkboxes.prop("checked", false);
		if (checkDueTomorrow.prop("checked") == true)
			$("#bulk-update-step-2 input[data-role='task'][data-period='past']").prop("checked", true);
	}
	
	function clearMainOptions() {
		checkAll.prop("checked", false);
		checkDueTomorrow.prop("checked", false);
	}
	
	function submitBulkUpdates() {
		showSection($("#bulk-update-step-3"));
		var updates = [];
		var checked = $("input[data-role='task']:checked");
		checked.each(function() {
			var update = {
				TaskId: $(this).val(),
				UpdateDueDate: updateDate.prop("checked"),
				UpdateComment: addComment.prop("checked"),
				Comment: comment.val(),
				DateTime: datepicker.val()
			};
			updates.push(update);
		});
		$.ajax({
			url: "/DataService.asmx/BulkUpdateTasks",
			type: "POST",
			data: JSON.stringify({ updates: updates }),
			contentType: "application/json",
			success: function(data) {
				showSection($("#bulk-update-step-4"));
			}
		});
	}

	return self;
})()
/* Copyright © 2024 Renegade Swish, LLC */

