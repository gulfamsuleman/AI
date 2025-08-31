var manageSingleChecklistModule = (function() {
	var self = {};
	var taskId = $("#task-id").val();
	var checklistId = $(".active-checklist").data("checklist-id");
	var changeId = $("#change-id").val();
	var softDueDate = new Date($("#reminder-date").val());
	var dueDate = new Date($("#due-date").val());	
	self.checklistModule = {};
	
	$().ready(function () {
		$(document).on('click', "a[data-action='update-reminder']", function (e) { updateReminderDate(); });
		$(document).on('click', "a[data-action='update-due']", function (e) { updateDueDate(); });
		$(document).on('click', "button[data-action='request']", function (e) { requestNewDueDateShow(); });
		$(document).on('click', "button[data-action='send-request']", function (e) { requestNewDueDate(); });
		$(document).on('click', "button[data-action='delete']", function (e) { deleteChecklist(); });
		$("a[data-action='change-deadline]").hide();
		// Setup the datepickers and select lists
		setInitialDatepickerDates();
		setInitialHours();
		$("[data-role='expand-indicator']").click();
		var w = $(window), d = $(document), b = $('body');

		var newDueDateQS = $("#newDueDateQS").val();
		if (newDueDateQS) {
			$("#RequestNewDue").click();
			var newDueDate = new Date(newDueDateQS);
			$("#request-new-due-date input.input-dt").val(newDueDate.formatDate("MM/dd/yyyy"));
			var hourVal = newDueDate.getHours();
			var minVal = newDueDate.getMinutes();
			if (minVal) hourVal += 0.5;
			$("#request-new-due-date select.input-dt").val(hourVal);
			$("#request-comment").focus();
			
		}

		if ($("#add-priority").val() == "1")
			addToPriorities();
	});

	function hideChecklist() {
	    $("div.active-checklist").hide();
	}

	function addToPriorities() {
	    var activeTask = $("div.active-checklist").attr("data-unique-id");
	    $.ajax({
	        url: "/DataService.asmx/AddPriorities",
	        type: "POST",
	        data: JSON.stringify({taskId: activeTask}),
	        contentType: "application/json",
	        success: function (data) {
	            if (data.d) {
	                alert("Task Added");
	                window.location.href = "Priorities.aspx";
	            }else{
	                alert("There was a problem adding your task");
	            }
	        }
	    });
	}
	
	function setInitialDatepickerDates() {
		$("#reminder-datepicker").data("lwDatepicker").setActiveDate(softDueDate);
		if($("#request-datepicker").length != 0)
			$("#request-datepicker").data("lwDatepicker").setActiveDate(dueDate);
		if($("#update-datepicker").length != 0)
			$("#update-datepicker").data("lwDatepicker").setActiveDate(dueDate);
	}

	function setInitialHours() {
	    var reminderVal = softDueDate.getHours();
	    if (softDueDate.getMinutes() > 0) { reminderVal += 0.5; }
	    var dueVal = dueDate.getHours();
	    if (dueDate.getMinutes() > 0) { dueVal += 0.5; }
	    $("#reminder-time").find("option[value='" + reminderVal + "']").prop("selected", "selected");
		$("#request-time").find("option[value='" + dueVal + "']").prop("selected", "selected");
		$("#update-time").find("option[value='" + dueVal + "']").prop("selected", "selected");
	}

	function requestNewDueDateShow() {
		$("button[data-action='request']").addClass("hidden");
		$("#request-new-due-date").removeClass("hidden");
	}
	
	function requestNewDueDate() {
	    var selectedTime = $("#request-time option:selected").val();
	    dueDate = new Date($("#request-datepicker").val());
	    dueDate.setHours(selectedTime);
	    if (isDecimal(selectedTime)) {
	        dueDate.setMinutes(30);
		}

		dueDate = dueDate.formatDate("MM/dd/yyyy hh:mm t");
		taskId = $("#task-id").val();
		$.ajax({
			url: "/DataService.asmx/RequestDueDateChange",
			type: "POST",
			data: JSON.stringify({
				taskId: taskId,
				newDueTime: dueDate,
				comment: $("#request-comment").val()
			}),
			contentType: "application/json",
			success: function(data) {
			    if (window.opener != null) {
			        window.opener.location.reload();
			        window.close();
			    }
			},
			error: function (jqXHR, textStatus, errorThrown) {
			    alert(jqXHR.responseText);
			}
		});
	}
	
	function updateDueDate() {
	    var selectedTime = $("#update-time option:selected").val();
		dueDate = new Date($("#update-datepicker").val());
		dueDate.setHours(selectedTime);
		if (isDecimal(selectedTime)){
		    dueDate.setMinutes(30);
		}
		dueDate = dueDate.formatDate("MM/dd/yyyy hh:mm t");
		taskId = $("#task-id").val();
		$.ajax({
			url: "/DataService.asmx/UpdateDueDate",
			type: "POST",
			data: JSON.stringify({
				taskId: taskId,
				dateTime: dueDate
			}),
			contentType: "application/json",
			success: function (data) {
			    if (window.opener != null) {
			        window.opener.location.reload();
			        window.close();
			    }
			}
		});
	}

	function isDecimal(num) {
	    if (parseFloat(parseInt(num)) === parseFloat(num)) {
	        return false;
	    }
	    return true;
	}
	
	function updateReminderDate() {
		var selectedTime = $("#reminder-time option:selected").val();
		softDueDate = new Date($("#reminder-datepicker").val());
		softDueDate.setHours(selectedTime);
		if (isDecimal(selectedTime)) {
		    softDueDate.setMinutes(30);
		}
		softDueDate = softDueDate.formatDate("MM/dd/yyyy hh:mm t");

		selectedTime = $("#update-time option:selected").val();
		dueDate = new Date($("#update-datepicker").val());
		dueDate.setHours(selectedTime);
		if (isDecimal(selectedTime)) {
		    dueDate.setMinutes(30);
		}
		dueDate = dueDate.formatDate("MM/dd/yyyy hh:mm t");
		if (dueDate < softDueDate) {
			alert("Soft due date is after the normal due date. Please pick a date before the due date.");
		} else {
			taskId = $("#task-id").val();
			$.ajax({
				url: "/DataService.asmx/UpdateReminderDate",
				type: "POST",
				data: JSON.stringify({
					taskId: taskId,
					dateTime: softDueDate
				}),
				contentType: "application/json",
				success: function (data) {
				    if (window.opener != null) {
				        window.opener.location.reload();
				        window.close();
				    }
				}
			});
		}
	}
	
	function deleteChecklist() {
		var choice = confirm("Are you sure you want to delete this task?");
		if (choice) {
			$.ajax({
				url: "/DataService.asmx/DeleteActiveChecklist",
				type: "POST",
				data: JSON.stringify({
				    activeChecklistId: taskId
				}),
				contentType: "application/json",
				success: function (data) {
				    if (window.opener != null) {
				        if (typeof window.opener.manageTasks !== "undefined")
				        {
				            window.opener.manageTasks.handleDeleteActiveChecklist(taskId);
				        }
				        else
				        {
				            window.opener.location.reload();
				        }
				        window.close();
				    }
				},
				error: function (jqXHR, textStatus, errorThrown) {
				    alert(jqXHR.responseText);
				}
			});
		}
	}

	return self;
})()

function gotoReport(reportId, type, taskId) {
    if (type == 'Controller') {
        window.opener.location.href = 'MyStatus.aspx?reportID=' + reportId + '&taskID=' + taskId;
    }
    else {
        window.opener.location.href = 'MyInbox.aspx?reportID=' + reportId + '&taskID=' + taskId;
    }
    window.close();
}
/* Copyright © 2024 Renegade Swish, LLC */

