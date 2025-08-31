var gradingModule = (function() {
	var self = {};
	var gradingPeriod = $("#grading-periods");
	self.periodStart = $("#start-period");
	self.periodEnd = $("#end-period");
	

	$().ready(function() {
		gradingPeriod.change(changeGradingPeriod);
	});
	
	function changeGradingPeriod() {
		var selected = gradingPeriod.find("option:selected").val();
		window.location.href = "Grading.aspx?period=" + selected;
	}
	
	return self;
})()
/* Copyright © 2024 Renegade Swish, LLC */

