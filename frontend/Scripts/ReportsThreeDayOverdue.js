var threeDayOverdueModule = (function() {
	var self = {};
	var dropdown = $("select[data-role='three-day-selection']");

	$().ready(function() {
		dropdown.change(reloadThreeDayOverdue);
	});

	function reloadThreeDayOverdue() {
		var params = {
			Selection: dropdown.find("option:selected").val(),
		};
		reportsModule.showThrobber(reportsModule.threeDayOverdue);
		reportsModule.threeDayOverdue.load("JQueryHandler.ashx?ControlName=" + encodeURI("Controls/Reports/ThreeDayOverdue.ascx"), params, function () { });
	}

	return self;
})()
/* Copyright © 2024 Renegade Swish, LLC */

