var bulkAssignmentsModule = (function() {
	var self = {};
	var memberList = $("#member-select");
	var commentBox = $("input[data-role='comment']");
	var addButton = $("button[data-action='add-assignment']");
	var removeButton = $("button[data-action='remove-assignment']");
	var highlightButton = $("button[data-action='clear-highlighting']");
	var checkAll = $("input[data-action='check-all']");
	var bulkTable = $("#bulk-assignments-table");

	$().ready(function() {
		addButton.click(addAssignment);
		removeButton.click(removeAssignment);
		highlightButton.click(removeHighlighting);
		checkAll.change(checkAllCheckboxes);

		resize();
		window.onresize = resize;
	});

	function resize() {
		$("#site-main").height(($(window).height() - $("#site-nav").outerHeight() - $("#site-footer").outerHeight() - 4) + "px");
		$("#site-main").css("margin-top", ($("#site-nav").outerHeight()) + "px");
	}
	
	function addAssignment() {
		var assignmentIds = [];
		$("input[data-role='task']:checked").closest("tr").each(
			function() {
				assignmentIds.push($(this).data("id"));
			}
		);
		$.ajax({
			url: "/DataService.asmx/AddAssignment",
			type: "POST",
			data: JSON.stringify({
				assignmentIds: assignmentIds,
				assigneeGroupId: memberList.find("option:selected").val(),
				comment: commentBox.val()
			}),
			contentType: "application/json",
			success: function(data) {
				window.location.reload();
			}
		});
	}
	
	function removeAssignment() {
		var assignmentIds = [];
		$("input[data-role='task']:checked").closest("tr").each(
			function () {
				assignmentIds.push($(this).data("id"));
			}
		);
		$.ajax({
			url: "/DataService.asmx/RemoveBulkAssignment",
			type: "POST",
			data: JSON.stringify({
				assignmentIds: assignmentIds,
				assigneeGroupId: memberList.find("option:selected").val(),
				comment: commentBox.val()
			}),
			contentType: "application/json",
			success: function (data) {
				window.location.reload();
			}
		});
	}
	
	function removeHighlighting() {
		$.ajax({
			url: "/DataService.asmx/RemoveHighlighting",
			type: "POST",
			success: function (data) {
				window.location.reload();
			}
		});
	}
	
	function checkAllCheckboxes() {
		$("input[type='checkbox']").prop("checked", checkAll.prop("checked"));
	}

	return self;
})()
/* Copyright © 2024 Renegade Swish, LLC */

