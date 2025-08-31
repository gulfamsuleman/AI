var gradingDeductionsModule = (function() {
	var self = {};
	var deductionsTable = $("#deductions-table");
	var rowTemplate =
		"<tr data-id='{0}' {1}>" +
			"<td>" +
				"<input data-action='delete-deduction' type='button' class='fa btn {2}' value='&#xf00d;'/>" +
				"<input data-action='restore-deduction' type='button' class='fa btn {3}' value='&#xf112;'/>" +
			"</td>" +
			"<td>{4}</td>" +
			"<td>{5}</td>" +
			"<td {6}>{7}</td>" +
		"</tr>";

	self.handleDeductionReturnData = function(deductions) {
		deductionsTable.find("tbody").html("");
		for (var i = 0; i < deductions.length; i++) {
			addDeductionRow(deductions[i]);
		}
	};

	function addDeductionRow(deduction) {
		var deleteButton = deduction.IsDeleted || deduction.Id == -1 ? "hidden" : "";
		var rowStyle = deduction.IsDeleted ? "class='italic'" : "";
		var restoreButton = !deduction.IsDeleted ? "hidden" : "";
		var pointStyle = getPointStyle(deduction.Type, deduction.Points);
		var pointValue = getPointValues(deduction.Type, deduction.Points);
		var newElem = $(format(rowTemplate, deduction.Id, rowStyle, deleteButton, restoreButton, deduction.Date, deduction.Reason, pointStyle, pointValue));
		deductionsTable.find("tbody").append(newElem);
	}
	
	function getPointStyle(type, point) {
		var pointStyle = "class=";
		switch (type)
		{
			case 0:
				pointStyle += point < 0.0 ? "'red'" : "'green'";
				break;
			case 1:
				pointStyle += "'green bold'";
				break;
			case -1:
				pointStyle += point != 0.0 ? "'red bold'" : "";
				break;
			case 2:
				pointStyle += "'bold'";
				break;
		}
		return pointStyle;
	}
	
	function getPointValues(type, point) {
		var pointValue = "";
		switch (type)
		{
			case -1:
				pointValue += point != 0.0 ? "(" + Math.abs(point) + ")" : point;
				break;
			case 0:
				pointValue += point < 0.0 ? "(" + Math.abs(point) + ")" : point;
				break;
			case 1: case 2:
				pointValue += point;
				break;
		}
		return pointValue;
	}

	return self;
})()
/* Copyright © 2024 Renegade Swish, LLC */

