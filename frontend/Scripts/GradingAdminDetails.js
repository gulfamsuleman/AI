var gradingAdminDetailsModule = (function() {
	var self = {};
	var gradingDetailsPanel = $("#grading-admin-details-panel");
	var userSelect = $("#grading-admin-details-panel #user-select");
	var periodSelect = $("#grading-admin-details-panel #grading-periods");
	var recalculateButton = $("button[data-action='recalculate-deductions']");
	var adjustmentButton = $("button[data-action='add-adjustment']");
	var adjustmentReason = $("#adjustment-reason");
	var adjustmentPoints = $("#adjustment-points");
	
	$().ready(function () {
		userSelect.change(reloadData);
		periodSelect.change(reloadData);
		recalculateButton.click(recalculateDeductions);
		adjustmentButton.click(addAdjustment);
		gradingDetailsPanel.on('click', "input[data-action='delete-deduction']", function (e) { deleteDeduction(e); });
		gradingDetailsPanel.on('click', "input[data-action='restore-deduction']", function (e) { restoreDeduction(e); });
	});
	
	function reloadData() {
		getDeductions();
		getVacations();
		getReportsOnHold();
	}

	function getDeductions() {
		$.ajax({
			url: "/DataService.asmx/GetDeductions",
			type: "POST",
			data: JSON.stringify({
				userId: userSelect.find("option:selected").val(),
				periodId: periodSelect.find("option:selected").val(),
			}),
			contentType: "application/json",
			success: function(data) {
				gradingDeductionsModule.handleDeductionReturnData(data.d);
			}
		});
	}

	function recalculateDeductions() {
		var choice = confirm("Are you sure you want to recalculate and lose all adjustments and excused deductions?");
		if (choice) {
			$.ajax({
				url: "/DataService.asmx/RecalculateDeductions",
				type: "POST",
				data: JSON.stringify({
					periodId: periodSelect.find("option:selected").val(),
					userId: userSelect.find("option:selected").val()
				}),
				contentType: "application/json",
				success: function (data) {
					gradingDeductionsModule.handleDeductionReturnData(data.d);
				}
			});
		}
	}
	
	function addAdjustment() {
		$.ajax({
			url: "/DataService.asmx/AddAdjustment",
			type: "POST",
			data: JSON.stringify({
				userId: userSelect.find("option:selected").val(),
				periodId: periodSelect.find("option:selected").val(),
				reason: adjustmentReason.val(),
				points: adjustmentPoints.val()
			}),
			contentType: "application/json",
			success: function(data) {
				gradingDeductionsModule.handleDeductionReturnData(data.d);
				adjustmentPoints.val("");
				adjustmentReason.val("");
			}
		});
	}
	
	function getVacations() {
		$.ajax({
			url: "/DataService.asmx/GetVacations",
			type: "POST",
			data: JSON.stringify({
				userId: userSelect.find("option:selected").val(),
				periodId: periodSelect.find("option:selected").val(),
			}),
			contentType: "application/json",
			success: function(data) {
				gradingVacationsModule.handleVacationData(data.d);
			}
		});
	}
	
	function getReportsOnHold() {
		$.ajax({
			url: "/DataService.asmx/GetReportsOnHold",
			type: "POST",
			data: JSON.stringify({
				userId: userSelect.find("option:selected").val(),
				periodId: periodSelect.find("option:selected").val(),
			}),
			contentType: "application/json",
			success: function (data) {
				gradingReportsOnHoldModule.handleReportData(data.d);
			}
		});
	}
	
	function deleteDeduction(e) {
		var reason = prompt("Please provide a reason");
		if (reason != null) {
			var deduction = $(e.currentTarget).closest("tr");
			$.ajax({
				url: "/DataService.asmx/DeleteDeduction",
				type: "POST",
				data: JSON.stringify({
					deductionId: deduction.data("id"),
					userId: userSelect.find("option:selected").val(),
					periodId: periodSelect.find("option:selected").val(),
					reason: reason
				}),
				contentType: "application/json",
				success: function (data) {
					gradingDeductionsModule.handleDeductionReturnData(data.d);
				}
			});
		} else {
			alert("Must provide a reason");
		}
	}
	
	function restoreDeduction(e) {
		var deduction = $(e.currentTarget).closest("tr");
		$.ajax({
			url: "/DataService.asmx/RestoreDeduction",
			type: "POST",
			data: JSON.stringify({
				deductionId: deduction.data("id"),
				userId: userSelect.find("option:selected").val(),
				periodId: periodSelect.find("option:selected").val(),
			}),
			contentType: "application/json",
			success: function (data) {
				gradingDeductionsModule.handleDeductionReturnData(data.d);
			}
		});
	}

	return self;
})()
/* Copyright © 2024 Renegade Swish, LLC */

