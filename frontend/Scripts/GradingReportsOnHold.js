var gradingReportsOnHoldModule = (function() {
	var self = {};
	var reportStart = $("#report-start");
	var reportEnd = $("#report-end");
	var reportTable = $("#report-table");
	var periodStart = $("#start-period");
	var periodEnd = $("#end-period");
	var userSelect = $("#on-hold-panel #user-select");
	var rowTemplate =
		"<tr data-id={0}>" +
			"<td><input data-action='delete-report' type='button' class='fa btn {1}' value='&#xf00d'/></td>" +
			"<td>{2}</td>" +
			"<td>{3}</td>" +
			"<td>{4}</td>" +
			"<td>{5}</td>" +
			"<td>{6}</td>" +
		"</tr>";
	
	$().ready(function() {
		$("[data-action='add-report']").click(addReportOnHold);
		$(document).on('click', "input[data-action='delete-report']", function(e) { deleteReportOnHold(e); });
	});

	function addReportOnHold() {
		var startDate = new Date(reportStart.val());
		var endDate = new Date(reportEnd.val());
		var startPeriod = new Date(periodStart.val());
		var endPeriod = new Date(periodEnd.val());
		if (startDate <= endDate) {
			if (startPeriod <= startDate && endDate <= endPeriod) {
				if ($("#select-user option:selected").val() > 0) {
					$.ajax({
						url: "/DataService.asmx/AddReportOnHold",
						type: "POST",
						data: JSON.stringify({
							userId:  userSelect.find("option:selected").val(),
							reportId: $("#select-report option:selected").val(),
							start: startDate,
							end: endDate,
							periodStart: startPeriod,
							periodEnd: endPeriod
						}),
						contentType: "application/json",
						success: function (data) {
							self.handleReportData(data.d);
						}
					});
				} else {
					alert("Please select a report");
				}
			} else {
				alert("Invalid Dates - does not apply to grading period selected");
			}
		} else {
			alert("Invalid Dates");
		}
	}

	function deleteReportOnHold(e) {
		var report = $(e.currentTarget).closest("tr");
		$.ajax({
			url: "/DataService.asmx/DeleteReport",
			type: "POST",
			data: JSON.stringify({
				vacationId: report.data("id"),
				periodStart: periodStart.val(),
				periodEnd: periodEnd.val()
			}),
			contentType: "application/json",
			success: function (data) {
				self.handleReportData(data.d);
			}
		});
	}

	self.handleReportData = function(reports) {
		if (reports.length > 0) {
			reportTable.find("tbody").html("");
			for (var i = 0; i < reports.length; i++) {
				addReportOnHoldRow(reports[i]);
			}
			reportTable.removeClass("hidden");
		} else {
			reportTable.addClass("hidden");
		}
	};

	function addReportOnHoldRow(report) {
		var deleteButton = report.Status == "Approved" ? "hidden" : "";
		var newElem = $(format(rowTemplate, report.Id, deleteButton, report.Report, report.User, report.StartDate, report.EndDate, report.Status));
		reportTable.find("tbody").append(newElem);
	}

	return self;
})()
/* Copyright © 2024 Renegade Swish, LLC */

