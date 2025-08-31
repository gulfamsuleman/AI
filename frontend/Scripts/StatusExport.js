var statusExport = (function() {
	var self = {};
	var exportPanel = $("#export-panel");
	var exportTable = $("#export-table");
	var exportOptions = $("#export-options");
	var reportsChecked = false;
	var archivesChecked = false;
	var exportButton = $("button[data-role='export']");

	

	function addExportTableRow(report) {
		var rowTemplate =
			"<tr data-status='" + JSON.stringify(report) + "'>" +
				"<td class='center'><input type='checkbox' data-role='report-select'></td>" +
				"<td data-item='name'>{0}</td>" +
				"<td class='center'><input type='checkbox' data-role='archive-select'></td>" +
			"</tr>";
		var newElem = $(format(rowTemplate, report.Name));
		exportTable.find("tbody").append(newElem);
		exportTable.removeClass("hidden");
		return newElem;
	}

	self.checkAllReports = function() {
		if (reportsChecked) {
			$("input[data-role='report-select']").prop("checked", false);
			$("button[data-role='all-reports']").text("Check All Reports");
			reportsChecked = false;
		} else {
			$("input[data-role='report-select']").prop("checked", true);
			$("button[data-role='all-reports']").text("Uncheck All Reports");
			reportsChecked = true;
		}
		validateGoButton();

	};
	
	self.checkAllArchives = function () {
		if (archivesChecked) {
			$("input[data-role='archive-select']").prop("checked", false);
			$("button[data-role='all-archives']").text("Check All Archives");
			archivesChecked = false;
		} else {
			$("input[data-role='archive-select']").prop("checked", true);
			$("button[data-role='all-archives']").text("Uncheck All Archives");
			archivesChecked = true;
		}
		validateGoButton();
	};

	self.exportFile = function(e) {
		var options = {
			dueDateFrom: $("#due-date-from").val(),
			dueDateTo: $("#due-date-to").val(),
			commentFrom: $("#comment-date-from").val(),
			commentTo: $("#comment-date-to").val(),
			exportType: $("input[name='export-choice']:checked").val(),
			excludeGeneralComments: $("#exclude-general").is(":checked"),
			reportList: getReportsChecked(),
			pageName: 'MyStatusExport.aspx'
		};

		var queryString = serialize(options);
		$('<iframe src=OfficeExportHandler.ashx?' + queryString + '/>').appendTo('body');
	};
	
	function getReportsChecked() {
		var array = [];
		var rows = exportTable.find("tbody tr");
		rows.each(function() {
			var showReport = $(this).find("input[data-role='report-select']").prop("checked");
			var showArchive = $(this).find("input[data-role='archive-select']").prop("checked");
			var reportId = $(this).data("status").Id;
			if (showReport) {
				array.push({ ReportId: reportId, ShowArchive: false });
			}
			if (showArchive) {
				array.push({ ReportId: reportId, ShowArchive: true });
			}
		});
		return JSON.stringify(array);
	}
	
	self.addExportTableRow = function(e) {
		addExportTableRow(e);
	};

	function validateGoButton() {
		
		exportButton.prop('disabled', $("input[type='checkbox']:checked").length == 0);
	}

	$().ready(function () {
		$("input[data-role='datepicker']").lwDatepicker();
		exportPanel.on('click', "button[data-role='export']", self.exportFile);
		exportPanel.on('click', "button[data-role='all-reports']", self.checkAllReports);
		exportPanel.on('click', "button[data-role='all-archives']", self.checkAllArchives);
		exportTable.on('click', "input[type='checkbox']", validateGoButton);
	});

	return self;
})()
/* Copyright © 2024 Renegade Swish, LLC */

