var assigneesBox = function (containerElem) {
	var self = {};
	var assignedToPanel = $("div.assigned-to-panel", containerElem);
	var assigneesTable = $("table.assignees-table", assignedToPanel);
	function addAssignedToTableRow(assignee) {
		var rowTemplate = "<tr data-status='" + JSON.stringify(assignee) + "'>" +
							"<td data-item=\"actions\">" +
								"<a data-role=\"delete\"><img src=\"/Images/delete.gif\" title=\"Remove\"/></a>" +
							"</td>" +
							"<td data-item=\"name\">{0}</td>" +
						"</tr>";
		assigneesTable.find("tbody").append(format(rowTemplate, assignee.name));
		assigneesTable.removeClass("hidden");
	}
	function removeAssignedToTableRow(jqElem) {
		$(jqElem).remove();
		var rows = assigneesTable.find("tbody tr");
		if (rows.length == 0) {
			assigneesTable.addClass("hidden");
		}
	}
	function addAssigneeAjax(assigneeItem, instanceId, changeId) {
		var data = {};
		data.groupId = assigneeItem.id;
		data.instanceId = instanceId;
		data.changeId = changeId;
		$.ajax({
			url: "../DataService.asmx/AddAssignee",
			type: "POST",
			data: JSON.stringify(data),
			dataType: "json",
			contentType: "application/json; charset=utf-8",
			success: function (response) {
				assigneeItem.id = response.d;
				addAssignedToTableRow(assigneeItem);
			}
		});
		checkAssigneeCountAjax(instanceId, changeId);
	}
	function deleteAssigneeAjax(assigneeItem, changeId) {
		var data = {};
		data.id = assigneeItem.id;
		data.existing = assigneeItem.existing;
		data.changeId = changeId;
		$.ajax({
			url: "../DataService.asmx/DeleteAssignee",
			type: "POST",
			data: data
		});
	}

	function checkAssigneeCountAjax(instanceId, changeId) {
		var data = {};
		data.instanceId = instanceId;
		data.changeId = changeId;
		$.ajax({
			url: "../DataService.asmx/GetAssigneeCount",
			type: "POST",
			data: JSON.stringify(data),
			dataType: "json",
			contentType: "application/json; charset=utf-8",
			success: function (response) {
				if (response.d > 2)
					$.prompt("Warning: you are assigning a task to more than 2 employees.  From our experience this never works well since it's unclear who is responsible for completing the task.", {
						buttons: { "Ok": true },
						submit: function (z, v, m, f) {
							z.preventDefault();
							$.prompt.close();
						}
					});
					//alert("Warning: you are assigning a task to more than 2 employees.  From our experience this never works well since it's unclear who is responsible for completing the task.");
			}
		});
	}
	self.addAssigneeRow = function(assignee) {
		addAssignedToTableRow(assignee);
	};
	self.addAssignee = function () {
		var newAssignee = {};
		var selectList = $("select", assignedToPanel);
		var changeId = $(assignedToPanel).closest("[data-change-id]").data("change-id");
		newAssignee.id = selectList.val();
		if (newAssignee.id < 0)
			return;
		newAssignee.name = selectList.find("option[value='" + newAssignee.id + "']:selected").text();
		newAssignee.existing = changeId <= 0 ? true : false;
		if(!!$(assignedToPanel).closest("[data-instance-id]").length) {
		    var instanceId = $(assignedToPanel).closest("[data-instance-id]").data("instance-id");
			addAssigneeAjax(newAssignee, instanceId, changeId);
		}else {
			addAssignedToTableRow(newAssignee);
		}
		selectList.val(-1);
	};
	self.deleteAssignee = function (e) {
	    if (window.confirm("Are you sure you want to delete this assignee?")) {
	    var assigneeItem = $(e.target).closest("tr").data("status");
	    var changeId = $(assignedToPanel).closest("[data-change-id]").data("change-id");
		deleteAssigneeAjax(assigneeItem, changeId);
		removeAssignedToTableRow($(e.target).closest("tr"));
        }
	};
	$().ready(function() {
		$("button[data-role='add']", assignedToPanel).click(self.addAssignee);
		$(assigneesTable).on('click', "a[data-role='delete']", self.deleteAssignee);
		if ($(assignedToPanel).data("status") && $(assignedToPanel).data("status").length > 0) {
			var data = $(assignedToPanel).data("status");
			for (var i = 0; i < data.length; i++) {
				addAssignedToTableRow(data[i]);
			}
		}
	});
	return self;
};
/* Copyright © 2024 Renegade Swish, LLC */

