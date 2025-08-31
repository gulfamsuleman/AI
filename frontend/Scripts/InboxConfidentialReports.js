var confidentialReportsModule = (function() {
	var self = {};
	var confidentialReportSelect = $("#confidential-report-select");
	var confidentialReportsTable = $("#confidential-report-table");
	var rowTemplate =
		"<tr data-id={0}>" +
			"<td><a href='#' data-role='remove-confidential' title='Remove'><img src='/Images/delete.gif' title='Remove' /></a></td>" +
			"<td>{1}</td>" +
		"</tr>";

	$().ready(function() {
		$("button[data-role='add-confidential']").click(addConfidentialReport);
		$(document).on("click", "a[data-role='remove-confidential']", function(e) { removeConfidentialReport(e); });
	});
	
	function addConfidentialReport() {
		var report = confidentialReportSelect.find("option:selected");
		addConfidentialReportAjax(report.val());
		addConfidentialTableRow(report);
	}
	
	function addConfidentialTableRow(report) {
		var newElem = $(format(rowTemplate, report.val(), report.text()));
		confidentialReportsTable.find("tbody").append(newElem);
	}
	
	function addConfidentialReportAjax(reportId) {
		$.ajax({
			url: "/DataService.asmx/AddConfidentialReport",
			type: "POST",
			data: JSON.stringify({ reportId: reportId }),
			contentType: "application/json",
			success: function (data) {

			}
		});
	}
	
	function removeConfidentialReport(e) {
		var row = $(e.currentTarget).closest("tr");
		removeConfidentialReportAjax(row.data("id"));
		row.remove();
	}
	
	function removeConfidentialReportAjax(reportId) {
		$.ajax({
			url: "/DataService.asmx/RemoveConfidentialReport",
			type: "POST",
			data: JSON.stringify({ reportId: reportId }),
			contentType: "application/json",
			success: function(data) {
				
			}
		});
	}

	return self;
})()
/* Copyright © 2024 Renegade Swish, LLC */

