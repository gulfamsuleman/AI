var setStatusModule = (function() {
	var self = {};
	var reportSelect = $("#report-dropdown");
	var sectionSelect = $("#section-dropdown");
	var goButton = $("button[data-role='add-instance']");
	var statusTable = $("#status-table");
	var instanceId = $("#instance-id");
	var sectionTemplate = "<option value='{0}'>{1}</option>";
	var rowTemplate =
		"<tr data-id='{0}' data-report-id='{1}'>" +
			"<td><a data-role='delete-instance'><img src='/Images/delete.gif' title='Remove'/></a></td>" +
			"<td>{2}</td>" +
			"<td>{3}</td>" +
		"</tr>";
	
	$().ready(function() {
		reportSelect.change(onReportSelect);
		goButton.click(addInstanceTaskType);
		$(document).on("click", "a[data-role='delete-instance']", function (e) { deleteInstanceTaskType(e); });
	});
	
	function onReportSelect() {
		var selectedId = reportSelect.find("option:selected").val();
		if (selectedId == -1) {
			sectionSelect.html("");
			sectionSelect.addClass("hidden");
			goButton.addClass("hidden");
		} else {
			getSections(selectedId);
			sectionSelect.removeClass("hidden");
			goButton.removeClass("hidden");
		}
	}
	
	function getSections(reportId) {
		$.ajax({
			url: "../DataService.asmx/GetTaskTypesForReport",
			type: "POST",
			data: JSON.stringify({ reportId: reportId }),
			contentType: "application/json",
			success: function(data) {
				populateSectionDropDown(data.d);
			}
		});
	}
	
	function populateSectionDropDown(sections) {
		sectionSelect.html("");
		for (var i = 0; i < sections.length; i++) {
			addSectionRow(sections[i]);
		}
	}
	
	function addSectionRow(section) {
		var newElem = $(format(sectionTemplate, section.Id, section.Name));
		sectionSelect.append(newElem);
	}

	function addInstanceTaskType(e) {
		$.ajax({
			url: "../DataService.asmx/AddInstanceTaskType",
			type: "POST",
			data: JSON.stringify({
				instanceId: instanceId.val(),
				taskType: sectionSelect.find("option:selected").val()
			}),
			contentType: "application/json",
			success: function(data) {
				handleStatusReturnData(data.d);
			}
		});
	}
	
	function handleStatusReturnData(rows) {
		statusTable.find("tbody").html("");
		if (rows.length == 0) {
			statusTable.addClass("hidden");
		} else {
			statusTable.removeClass("hidden");
			for (var i = 0; i < rows.length; i++) {
				addStatusTableRow(rows[i]);
			}
		}
	}
	
	function addStatusTableRow(row) {
		var newElem = $(format(rowTemplate, row.ID, row.ReportID, row.Report, row.TaskType ));
		statusTable.find("tbody").append(newElem);
	}
	
	function deleteInstanceTaskType(e) {
		var row = $(e.currentTarget).closest("tr");
		$.ajax({
			url: "../DataService.asmx/DeleteInstanceTaskType",
			type: "POST",
			data: JSON.stringify({ taskId: row.data("id") }),
			contentType: "application/json",
			success: function(data) {
				row.remove();
				if (statusTable.find("tbody tr").length == 0)
					statusTable.addClass("hidden");
			}
		});
	}

	return self;
})()
/* Copyright © 2024 Renegade Swish, LLC */

