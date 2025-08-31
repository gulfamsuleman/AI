var reportsModule = (function () {
	var self = {};
	var controls = $("div[data-view='control']");
	var throbber = $("#throbber");
	self.reportsOverview = $("#reports-overview");
	self.overdue = $("#overdue");
	self.history = $("#history");
	self.threeDayOverdue = $("#three-day-overdue");
	self.tasksByPerson = $("#tasks-by-person");

	$().ready(function () {
		$("a[data-role='reports-overview']").click(loadReportsOverview);
		$("a[data-role='overdue']").click(self.loadOverdue);
		$("a[data-role='history']").click(self.loadHistory);
		$("a[data-role='three-day-overdue']").click(loadThreeDayOverdue);
		$("a[data-role='tasks-by-person']").click(loadTasksByPerson);

		resize();
		window.onresize = resize;
		if ($("#oldOverdue").val() == "1") {
			$("a[data-role='overdue']").click();
		}
		if ($("#oid").val() != "") {
			$("a[data-role='overdue']").first().click();
		}
	});

	function resize() {
		$("#site-main").height(($(window).height() - $("#site-nav").outerHeight() - $("#site-footer").outerHeight() - 4) + "px");
		$("#site-main").css("margin-top", ($("#site-nav").outerHeight()) + "px");
	}

	function loadReportsOverview(e) {
		updateNavigation(e);
		self.showThrobber(self.reportsOverview);
		self.reportsOverview.load("../JQueryHandler.ashx?ControlName=" + encodeURI("Controls/Reports/ReportsOverview.ascx"));
		showCurrentSelection(self.reportsOverview);
	}

	self.loadOverdue = function (e) {
		updateNavigation(e);
		self.showThrobber(self.overdue);
		self.overdue.load("../JQueryHandler.ashx?ControlName=" + encodeURI("Controls/Reports/Overdue.ascx"), {}, function () {
			if (typeof slider !== 'undefined') {
				self.overdue.find(".form-inline").removeClass("form-inline");
				self.overdue.find(".row").removeClass("row");
				self.overdue.find("select").addClass("form-control");
				self.overdue.find("a[data-role=open-overdue-message]").addClass("btn").addClass("btn-secondary").addClass("mt-2");
			}
		});
		showCurrentSelection(self.overdue);
	};

	self.loadHistory = function (e) {
		updateNavigation(e);
		self.showThrobber(self.history);
		self.history.load("../JQueryHandler.ashx?ControlName=" + encodeURI("Controls/Reports/History.ascx"), {}, function () {
			if (typeof slider !== 'undefined') {
				self.history.find(".form-inline").removeClass("form-inline");
				self.history.find(".row").removeClass("row");
				self.history.find("select").addClass("form-control");
				self.history.find("a[data-role=run-report]").addClass("btn").addClass("btn-secondary").addClass("mt-2");
			}
		});
		showCurrentSelection(self.history);
	};

	function loadThreeDayOverdue(e) {
		updateNavigation(e);
		self.showThrobber(self.threeDayOverdue);
		self.threeDayOverdue.load("../JQueryHandler.ashx?ControlName=" + encodeURI("Controls/Reports/ThreeDayOverdue.ascx"));
		showCurrentSelection(self.threeDayOverdue);
	}

	function loadTasksByPerson(e) {
		updateNavigation(e);
		self.showThrobber(self.tasksByPerson);
		self.tasksByPerson.load("../JQueryHandler.ashx?ControlName=" + encodeURI("Controls/Reports/TasksByPerson.ascx"));
		showCurrentSelection(self.tasksByPerson);
	}

	function showCurrentSelection(selection) {
		controls.addClass("hidden");
		selection.removeClass("hidden");
	}

	self.showThrobber = function (sourceElem) {
		sourceElem.html(throbber.html());
		sourceElem.removeClass("hidden");
		setInterval(function () { tick(sourceElem); }, 100);
	};

	function tick(sourceElem) {
		sourceElem.find("#wait-message").text(sourceElem.find("#wait-message").text() + " .");
	};

	function updateNavigation(e) {
		$("#report-nav").children().removeClass("active");
		$(e.target).addClass("active");
	}

	return self;
})();

function gotoReport(reportId, type, taskId) {
	if (typeof slider !== 'undefined') {
		if (type == 'Controller') {
			window.location.href = 'MobileMyStatus.aspx?reportID=' + reportId + '&taskID=' + taskId;
		}
		else {
			window.location.href = 'MobileInbox.aspx?reportID=' + reportId + '&taskID=' + taskId;
		}

		return;
	}

	if (type == 'Controller') {
		window.location.href = 'MyStatus.aspx?reportID=' + reportId + '&taskID=' + taskId;
	}
	else {
		window.location.href = 'MyInbox.aspx?reportID=' + reportId + '&taskID=' + taskId;
	}
}
/* Copyright © 2024 Renegade Swish, LLC */

