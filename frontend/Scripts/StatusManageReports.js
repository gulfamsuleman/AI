var manageReportsModule = (function () {
	var self = {};
	var reportsPanel = $("#reports-panel");
	var reportsTable = $("#reports-table");
	var editButton = "<a data-role='edit'><img src='/Images/edit.gif' title='Edit' /></a>";
	var deleteButton = "<a data-role='delete'><img src='/Images/delete.gif' title='Remove' /></a>";
	var saveButton = "<a data-role='save'><img src='/Images/save_sm.gif' title='Save' /></a>";
	function addReportTableRow(report) {
		var rowTemplate =
			"<tr data-id='{0}'>" +
				"<td data-item='actions'>" +
					editButton + " " +
					deleteButton +
				"</td>" +
				"<td data-item='name'>{1}</td>" +
			"</tr>";
		var newElem = $(format(rowTemplate, report.Id, report.Name));
		reportsTable.find("tbody").append(newElem);
		reportsTable.removeClass("hidden");
		return newElem;
	}
	function editReportTableRow(jqElem) {
		$("td[data-item='actions'] a", jqElem).remove();
		$("td[data-item='actions']", jqElem).append(saveButton);
		$("td[data-item='name']", jqElem).html("<input type='text' value='" + $("td[data-item = 'name']", jqElem).html() + "' />");
	}
	function saveReportTableRow(jqElem) {
		$("td[data-item='actions']", jqElem).html(editButton + ' ' + deleteButton);
		$("td[data-item='name']", jqElem).html($("td[data-item='name'] input").val());
		saveReportAjax(jqElem.data("id"), $("td[data-item='name']", jqElem).html());
	}
	function removeReportTableRow(jqElem) {
		var reportId = jqElem.data("id");
		var reportName = jqElem.find("td[data-item='name']").html();

		if (!confirm("Are you sure you want to delete the \"" + reportName + "\" Status Report? \r\n\r\n\r\n\r\nThis will remove the ability to view or use this report for ALL users!"))
			return;

		jqElem.remove();
		var rows = reportsTable.find("tbody tr");
		if(rows.length == 0) {
			reportsTable.addClass("hidden");
		}
		deleteReportAjax(reportId);
	}
	function addReportAjax(reportId, name, jqElem) {
		$.ajax({
			url: "/DataService.asmx/AddReport",
			type: "POST",
			data: JSON.stringify({
				reportId: reportId,
				name: name
			}),
			dataType: "json",
			contentType: "application/json",
			success: function (response) {
				var id = response.d;
				jqElem.attr("data-id", id);
			},
			error: function () {
				alert("An error occurred while processing your request.");
			}
		});
	}
	function saveReportAjax(reportId, name) {
		$.ajax({
			url: "/DataService.asmx/SaveReport",
			type: "POST",
			data: JSON.stringify({
				reportId: reportId,
				name: name
			}),
			contentType: "application/json",
			success: function (response) {
				
			},
			error: function () {
				alert("An error occurred while processing your request.");
			}
		});
	}
	function deleteReportAjax(reportId) {
		$.ajax({
			url: "/DataService.asmx/DeleteReport",
			type: "POST",
			data: JSON.stringify({ reportId: reportId }),
			contentType: "application/json",
			success: function (response) { },
			error: function () {
				alert("An error occurred while processing your request.");
			}
		});
	}

	self.addReportTableRow = function(obj) {
		addReportTableRow(obj);
	};
	self.createReport = function() {
		var newReport = {
			Id: 0,
			Name: "New Report"
		};
		var tableRow = addReportTableRow(newReport);
		addReportAjax(newReport.Id, newReport.Name, tableRow);
	};
	self.editReport = function(e) {
		editReportTableRow($(e.target).closest("tr"));
	};
	self.deleteReport = function(e) {
		removeReportTableRow($(e.target).closest("tr"));
	};
	self.saveReport = function (e) {
		saveReportTableRow($(e.target).closest("tr"));
	};
	$().ready(function() {
		$("button[data-role='add']", reportsPanel).click(self.createReport);
		reportsTable.on('click', "a[data-role='delete']", self.deleteReport);
		reportsTable.on('click', "a[data-role='edit']", self.editReport);
		reportsTable.on('click', "a[data-role='save']", self.saveReport);
	});
	return self;
})()
/* Copyright © 2024 Renegade Swish, LLC */

