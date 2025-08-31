var statusTimeline = (function() {
	var self = {};
	var timelinePanel = $("#timeline-panel");
	var timelineTable = $("#timeline-table");
	var timelineTableBody = $("#timeline-table tbody");
	var reportName = $("#report-name");
	var reportSelect = $("#report-select");
	var noTimeline = $("#no-timeline");
	var loading = $("#loading");
	var currentDisplayDate = "";
	
	function addTimelineTableRow(timeline) {
		var rowTemplate =
			"<tr data-status='" + JSON.stringify(timeline) + "'>" +
				"<td data-item='due-date' {0}>{1}</td>" +
				"<td data-item='description'>{2}</td>" +
			"</tr>";
		var dateClass = "";
		if (timeline.Overdue == 1)
			dateClass = "class='red-text'";
		var dateDisplay;
		if (timeline.DueDate == currentDisplayDate)
			dateDisplay = "";
		else {
			dateDisplay = timeline.DueDate;
			currentDisplayDate = timeline.DueDate;
		}
		var newElem = $(format(rowTemplate, dateClass, dateDisplay, timeline.Description));
		timelineTable.find("tbody").append(newElem);
		timelineTable.removeClass("hidden");
		return newElem;
	}

	self.setHeaderTitle = function() {
		if (window.controller == 1) {
			if (reportSelect.find("option:selected").val() == 0)
				reportName.text("All the Reports I Control");
			else
				reportName.text(reportSelect.find("option:selected").text());
		} else {
			reportName.text(window.reportName);
		}
	};

	function getReportTimelineAjax(reportId) {
		$.ajax({
			url: "/DataService.asmx/GetReportTimeline",
			type: "POST",
			data: JSON.stringify({
				reportId: reportId
			}),
			contentType: "application/json",
			success: function (data) {
				timelineTableBody.html("");
				if (data.d.length == 0) {
					loading.addClass("hidden");
					noTimeline.removeClass("hidden");
					timelineTable.addClass("hidden");
				} else {
					noTimeline.addClass("hidden");
					var timelines = data.d;
					for (var i = 0; i < timelines.length; i++) {
						statusTimeline.addTimelineTableRow(timelines[i]);
					}
					loading.addClass("hidden");
					timelineTable.removeClass("hidden");
				}
			}
		});
	}

	self.getReportTimeline = function(reportId) {
		timelineTable.addClass("hidden");
		noTimeline.addClass("hidden");
		loading.removeClass("hidden");
		getReportTimelineAjax(reportId);
	};

	self.addTimelineTableRow = function(timeline) {
		addTimelineTableRow(timeline);
	};

	self.refreshTimeline = function() {
		self.setHeaderTitle();
		self.getReportTimeline(reportSelect.find("option:selected").val());
	};

	$().ready(function () {
		if (window.controller == 1) {
			self.getReportTimeline(reportSelect.find("option:selected").val());
			reportSelect.removeClass("hidden");
		} else {
			self.getReportTimeline(statusReportModule.reportId);
		}
		self.setHeaderTitle();
		$(reportSelect, timelinePanel).on('change', self.refreshTimeline);
	});

	return self;
})()
/* Copyright © 2024 Renegade Swish, LLC */

