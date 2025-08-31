var gradingVacationsModule = (function() {
	var self = {};
	var vacationTable = $("#vacation-table");
	var vacationStart = $("#vacation-start");
	var vacationEnd = $("#vacation-end");
	var periodStart = $("#start-period");
	var periodEnd = $("#end-period");
	var isApproval = $("#is-approval").val();
	var isAdminDetails = $("#admin-details").val();
	var userSelect = $("#vacation-panel #user-select");
	var rowTemplate =
		"<tr data-id={0}>" +
			"<td>" +
				"<input data-action='delete-vacation' type='button' class='fa btn {1}' value='&#xf00d'/>" +
				"<button data-action='approve-vacation' {2}>Approve</button>" +
			"</td>" +
			"{3}" +
			"<td>{4}</td>" +
			"<td>{5}</td>" +
			"<td id='vacation-status'>{6}</td>" +
		"</tr>";

	$().ready(function() {
		$("[data-action='add-vacation']").click(addVacation);
		$(document).on('click', "input[data-action='delete-vacation']", function (e) { deleteVacation(e); });
		$(document).on('click', "button[data-action='approve-vacation']", function (e) { approveVacation(e); });
	});

	function addVacation() {
		var startDate = new Date(vacationStart.val());
		var endDate = new Date(vacationEnd.val());
		var startPeriod = new Date(periodStart.val());
		var endPeriod = new Date(periodEnd.val());
		
		if (startDate <= endDate) {
			if (startPeriod <= startDate && endPeriod >= endDate) {
				if (isApproval == "True" && userSelect.find("option:selected").val() == -1) {
					alert("Please select a user from the list");
					return;
				}
				$.ajax({
					url: "/DataService.asmx/AddVacation",
					type: "POST",
					data: JSON.stringify({
						start: startDate,
						end: endDate,
						periodStart: startPeriod,
						periodEnd: endPeriod,
						userId: isApproval ? userSelect.find("option:selected").val() : -1
					}),
					contentType: "application/json",
					success: function (data) {
						self.handleVacationData(data.d);
					},
					error: function () {
						alert("An error occurred while processing your request");
					}
				});
			} else {
				alert("Invalid Vacation Dates - does not apply to grading period selected");
			}
		} else {
			alert("Invalid Vacation Dates");
		}
	}

	function deleteVacation(e) {
		var vacation = $(e.currentTarget).closest("tr");
		$.ajax({
			url: "/DataService.asmx/DeleteVacation",
			type: "POST",
			data: JSON.stringify({
				vacationId: vacation.data("id"),
				periodStart: periodStart.val(),
				periodEnd: periodEnd.val()
			}),
			contentType: "application/json",
			success: function (data) {
				self.handleVacationData(data.d);
			},
			error: function () {
				alert("An error occurred while processing your request");
			}
		});
	}

	self.handleVacationData = function(vacations) {
		if (vacations.length > 0) {
			vacationTable.find("tbody").html("");
			for (var i = 0; i < vacations.length; i++) {
				addVacationRow(vacations[i]);
			}
			vacationTable.removeClass("hidden");
		} else {
			vacationTable.addClass("hidden");
		}
	}

	function addVacationRow(vacation) {
		var approveButton = "";
		var deleteButton = "";
		var userName = "";
		if (isApproval || isAdminDetails) {
			userName = "<td>" + vacation.FullName + "</td>";
		} else {
			approveButton = "class='hidden'";
		}
		if (vacation.Status == "Approved") {
			deleteButton = "hidden";
			approveButton = "class='hidden'";
		}
		var newElem = $(format(rowTemplate, vacation.Id, deleteButton, approveButton, userName, vacation.StartDate, vacation.EndDate, vacation.Status));
		vacationTable.find("tbody").append(newElem);
	}
	
	function approveVacation(e) {
		var vacation = $(e.currentTarget).closest("tr");
		$.ajax({
			url: "/DataService.asmx/ApproveVacation",
			type: "POST",
			data: JSON.stringify({ vacationId: vacation.data("id") }),
			contentType: "application/json",
			success: function(data) {
				vacation.find("[data-action]").addClass("hidden");
				vacation.find("#vacation-status").text("Approved");
			},
			error: function () {
				alert("An error occurred while processing your request");
			}
		});
	}
	
	return self;
})()
/* Copyright © 2024 Renegade Swish, LLC */

