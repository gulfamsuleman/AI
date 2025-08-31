var reportHistoryModule = (function() {
	var self = {};
	var runButton = $("[data-role='run-report']");
	var startDate = $("#start-date");
	var endDate = $("#end-date");
	var sortBy = $("select[data-role='sort-by']");
	var completedBy = $("select[data-role='completed-by']");
	var days = 24 * 60 * 60 * 1000;
	
	$().ready(function () {
		if (typeof slider !== 'undefined') {
			$("input[data-role='datepicker']").mobiscroll().date({
				theme: getMobileOperatingSystem(),
				display: 'modal'
			});
		} else {
			$("input[data-role='datepicker']").lwDatepicker();
		}
		
		runButton.click(runReport);
	});
	
	function runReport() {
		if (checkDates()) {
			var params = {
				SelectedMemberId: completedBy.find("option:selected").val(),
				Sort: sortBy.find("option:selected").val(),
				StartDate: startDate.val(),
				EndDate: endDate.val()
			};
			reportsModule.showThrobber(reportsModule.history);
			reportsModule.history.load("../JQueryHandler.ashx?ControlName=" + encodeURI("Controls/Reports/History.ascx"), params, function () {
				if (typeof slider !== 'undefined') {
					reportsModule.history.find(".form-inline").removeClass("form-inline");
					reportsModule.history.find(".row").removeClass("row");
					reportsModule.history.find("select").addClass("form-control");
					reportsModule.history.find("a[data-role=run-report]").addClass("btn").addClass("btn-secondary").addClass("mt-2");
				}
			});
		}
	}
	
	function checkDates() {
		var start = new Date(startDate.val());
		var end = new Date(endDate.val());
		if (start > end) {
			alert("Ending date cannot be before starting date.");
			return false;
		} else if (end - start > 90*days) {
			alert("No more than 90 days of data can be shown.");
			return false;
		} else {
			return true;
		}
	}
	
	return self;
})()
/* Copyright © 2024 Renegade Swish, LLC */

