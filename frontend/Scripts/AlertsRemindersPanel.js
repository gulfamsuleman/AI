var alertsRemindersBox = function (containerElem, recurring, dueDate) {
    var self = {};
    /*
    var alertType = {
        "Overdue"   : 1,
        "Hours"     : 2,
        "Assignment": 3,
        "Schedule"  : 4,
        "Custom"    : 5,
        "Complete"  : 7,
        "Reminder"  : 8,
        "ReminderX" : 9
    };
    */
    var alertType = {
        1: "Overdue",
        2: "Hours",
        3: "Assignment",
        4: "Schedule",
        5: "Custom",
        7: "Complete",
        8: "Reminder",
        9: "ReminderX"
    };

    var isRecurring = recurring;
    var dueOn = dueDate;
	var alertsRemindersPanel = $("div.alerts-reminders-panel", containerElem);
	var alertsEmailPanel = $("div.alerts-email-panel", alertsRemindersPanel);
	var alertsEveryPanel = $("div.alerts-every-panel", alertsRemindersPanel);
	var alertsDayBeforePanel = $("div.alerts-days-before-panel", alertsRemindersPanel);
	var alertsHourBeforePanel = $("div.alerts-hours-before-panel", alertsRemindersPanel);
	var alertsTimePanel = $("div.alerts-time-panel", alertsRemindersPanel);
	var alertsTextPanel = $("div.alerts-text-panel", alertsRemindersPanel);
	var alertsTable = $("table.alerts-table", alertsRemindersPanel);
	function setIsRecurring(event) {
	    var recurring = event.detail.isRecurring;
	    var ourInstanceId = alertsRemindersPanel.closest("[data-instance-id]").data("instance-id");
	    var otherInstanceId = event.detail.instanceId;
	    if (otherInstanceId == ourInstanceId) {
	        isRecurring = recurring;
	    }
	}
	function setDueOn(event) {
	    var newDate = event.detail.newDate;
	    var ourInstanceId = alertsRemindersPanel.closest("[data-instance-id]").data("instance-id");
	    var otherInstanceId = event.detail.instanceId;
	    if (otherInstanceId == ourInstanceId) {
	        dueOn = newDate;
	        if (!isRecurring) {
	            refreshDateColumn();
	        }
	    }
	}
	function refreshDateColumn() {
	    $('td[data-item="date"]').each(function (index, element) {
	        element = $(element);
	        var status = element.closest("[data-status]").data("status");

	    });
	}
	function processTime(time) {
	    var meridian = time < 12 ? " AM" : " PM";
	    var hoursPart = String(time).split('.')[0] % 12;
	    hoursPart = hoursPart == 0 ? 12 : hoursPart;
	    hoursPart = time == 0 ? 12 : hoursPart;
	    var minutesPart = String(time).split('.')[1] ? ":30" : ":00";
	    return hoursPart + minutesPart + meridian;
	}
	function addAlertTableRow(status) {

		var rowTemplate = "";
		var type = "{0}";
		var alertee = "{1}";
		var date = "";
		var time = "";
		var text = "";
		var dispTime = "";

		switch (alertType[status.typeId]) {
		    case "Overdue":
                type = "When task goes overdue"
		        break;
		    case "Hours":
		        type = "Every {3} hour(s) after task goes overdue";
		        text = "{4}";
		        dispTime = Math.abs(status.time);
		        break;
		    case "Assignment":
		        type = "When assignments are changed";
		        break;
		    case "Schedule":
		        type = "When schedule is edited";
		        break;
		    case "Custom":
		        date = "{2}";
		        time = "{3}";
		        text = "{4}";
		        dispTime = status.time ? processTime(status.time) : "";
		        break;
		    case "Complete":
		        type = "When task is completed";
		        break;
		    case "Reminder":
		        if (status.time < 0) {
		            type = "{0} {3} hours before due";
		            dispTime = Math.abs(status.time);
		        } else {
		            date = "{2}";
		            time = "{3}";
		            dispTime = status.time ? processTime(status.time) : "";
		        }
		        break;
		    case "ReminderX":
		        type = "{0} {3} hours before due";
		        dispTime = Math.abs(status.time);
		        break;
		    default:
		        break;
		}

		var rowTemplate = "<tr data-role='dragndrop-draggable' data-status='" + JSON.stringify(status) + "'>" +
                            "<td data-item='actions' nowrap>" +
                            "<a data-role='delete'><img src='/Images/delete.gif' title='Remove'></a></td>" +
                            "<td data-item='type'>" + type + "</td>" +
                            "<td data-item='alertee'>" + alertee + "</td>" +
                            "<td data-item='date'>" + date + "</td>" +
                            "<td data-item='time' nowrap>" + time + "</td>" +
                            "<td data-item='text'>" + text + "</td>" +
                        "</tr>";		    

		alertsTable.find("tbody").append(format(rowTemplate, status.type, status.alertee, status.daysBefore || "", dispTime , status.text));
		alertsTable.removeClass("hidden");
	}

	function removeAlertTableRow(jqElem) {
		$(jqElem).remove();
		var rows = alertsTable.find("tbody tr");
		if (rows.length == 0) {
			alertsTable.addClass("hidden");
		}
	}
	function addAlertAjax(alertItem, instanceId, changeId) {
		var data = {};
		data.id = instanceId;
		data.alertType = alertItem.type;
		data.changeId = changeId;
		switch(alertItem.type) {
			case "Reminder":
				data.nagBeforeDays = alertItem.daysBefore;
				data.nagTime = alertItem.time;
				data.alerteeGroupId = null;
				data.alertText = null;
				break;
			case "Hours":
				data.nagBeforeDays = null;
				data.nagTime = alertItem.recurrence;
				data.alertText = alertItem.text;
				data.alerteeGroupId = alertItem.alerteeId;
				break;
			case "Custom":
				data.nagBeforeDays = alertItem.daysBefore;
				data.nagTime = alertItem.time;
				data.alertText = alertItem.text;
				data.alerteeGroupId = alertItem.alerteeId;
				break;
			case "Overdue":
			case "Complete":
			case "Assignment":
			case "Schedule":
				data.nagBeforeDays = null;
				data.nagTime = null;
				data.alertText = null;
				data.alerteeGroupId = alertItem.alerteeId;
				break;
		}

		if (alertItem.typeId == "9") {
		    data.nagBeforeDays = null;
		}

		$.ajax({
			url: "/DataService.asmx/AddAlert",
			type: "POST",
			data: JSON.stringify(data),
			dataType: "json",
			contentType: "application/json; charset=utf-8",
			success: function(response) {
			    alertItem.id = response.d;
				addAlertTableRow(alertItem);
			}
		});
	}
	function upDateAlertAjax(alertItem) {
		//var alertItem = row.data("status");
		//alertItem.alerteeId = row.find('td[data-item="alertee"] select').val();
		//alertItem.text = row.find('td[data-item="text"] textarea').val();
		var data = {};
		data.id = alertItem.id;
		data.alertType = alertItem.type;
		switch (alertItem.type) {
			case "Reminder":
				data.nagBeforeDays = alertItem.daysBefore;
				data.nagTime = alertItem.time;
				data.alerteeGroupId = null;
				data.alertText = null;
				break;
			case "Hours":
				data.nagBeforeDays = null;
				data.nagTime = alertItem.recurrence;
				data.alertText = alertItem.text;
				data.alerteeGroupId = alertItem.alerteeId;
				break;
			case "Custom":
				data.nagBeforeDays = alertItem.daysBefore;
				data.nagTime = alertItem.time;
				data.alertText = alertItem.text;
				data.alerteeGroupId = alertItem.alerteeId;
				break;
			case "Overdue":
			case "Complete":
			case "Assignment":
			case "Schedule":
				data.nagBeforeDays = null;
				data.nagTime = null;
				data.alertText = null;
				data.alerteeGroupId = alertItem.alerteeId;
				break;
		}

		if (alertItem.typeId == "9") {
		    data.nagBeforeDays = null;
		}

		$.ajax({
			url: "/DataService.asmx/UpdateAlert",
			type: "POST",
			data: JSON.stringify(data),
			dataType: "json",
			contentType: "application/json; charset=utf-8"
		});
	}
	function deleteAlertAjax(alertItem, changeId) {
		var data = {};
		data.id = alertItem.id;
		data.changeId = changeId;
		data.existing = alertItem.existing;
		$.ajax({
			url: "/DataService.asmx/DeleteAlert",
			type: "POST",
			data: JSON.stringify(data),
			dataType: "json",
			contentType: "application/json; charset=utf-8"
		});
	}
	self.submitClick = function () {
		var alertType = $("input[name='alert-type']:checked", alertsRemindersPanel).val();
		var emailTo = $("select", alertsEmailPanel).val();
		if (alertType == 8 || alertType == 9)
		    emailTo = 0;
		var alerteeName = $("select :selected", alertsEmailPanel).text();
		if (alertType == 8 || alertType == 9)
		    alerteeName = "Assignees";
		var every = $("input", alertsEveryPanel).val();
		var daysBefore = $("input", alertsDayBeforePanel).val();
		var time = $("select", alertsTimePanel).val();
		var text = $("textarea", alertsTextPanel).val();
		var typeString = "";
		var status = null;
		var changeId = alertsRemindersPanel.closest("[data-change-id]").data("change-id");
		var existing = changeId <= 0 ? true : false;

		status = {
		    typeId: alertType,
            alertee: alerteeName,
			alerteeId: emailTo,
			recurrence: every,
			daysBefore: daysBefore,
			time: time,
			text: text,
			existing: existing
		};
		switch (alertType) {
			case "1":
				status.typeString = "When task goes overdue";
				status.type = "Overdue";
				break;
			case "2":
				status.typeString = "Every " + every + " hour(s) after task goes overdue";
				status.type = "Hours";
				status.time = every;
				break;
			case "3":
				status.typeString = "When assignments are changed";
				status.type = "Assignment";
				break;
			case "4":
				status.typeString = "When schedule is edited";
				status.type = "Schedule";
				break;
			case "5":
				status.typeString = "Custom";
				status.type = "Custom";
				break;
			case "7":
				status.typeString = "When task is completed";
				status.type = "Complete";
				break;
			case "8":
				status.typeString = "Reminder";
				status.type = "Reminder";
				break;
            case "9":
                status.typeString = "Reminder";
                status.type = "Reminder";
                status.time = $("input", alertsHourBeforePanel).val() * -1;
                break;
		}
		if (!!alertsRemindersPanel.closest("[data-instance-id]").length) {
		    var instanceId = alertsRemindersPanel.closest("[data-instance-id]").data("instance-id");
			addAlertAjax(status, instanceId, changeId);
		} else {
			addAlertTableRow(status);
		}
	};
	self.changeAlertType = function () {
	    alertsHourBeforePanel.addClass("hidden");
		var alertType = $("input[name='alert-type']:checked", alertsRemindersPanel);
		var alertVal = alertType.val();
		switch (alertVal) {
			case "1":
				alertsEmailPanel.removeClass("hidden");
				alertsEveryPanel.addClass("hidden");
				alertsDayBeforePanel.addClass("hidden");
				alertsTimePanel.addClass("hidden");
				alertsTextPanel.addClass("hidden");
				alertsHourBeforePanel.addClass("hidden");
				break;
			case "2":
				alertsEmailPanel.removeClass("hidden");
				alertsEveryPanel.removeClass("hidden");
				alertsDayBeforePanel.addClass("hidden");
				alertsTimePanel.addClass("hidden");
				alertsTextPanel.removeClass("hidden");
				alertsHourBeforePanel.addClass("hidden");
				break;
			case "3":
				alertsEmailPanel.removeClass("hidden");
				alertsEveryPanel.addClass("hidden");
				alertsDayBeforePanel.addClass("hidden");
				alertsTimePanel.addClass("hidden");
				alertsTextPanel.addClass("hidden");
				alertsHourBeforePanel.addClass("hidden");
				break;
			case "4":
				alertsEmailPanel.removeClass("hidden");
				alertsEveryPanel.addClass("hidden");
				alertsDayBeforePanel.addClass("hidden");
				alertsTimePanel.addClass("hidden");
				alertsTextPanel.addClass("hidden");
				alertsHourBeforePanel.addClass("hidden");
				break;
			case "5":
				alertsEmailPanel.removeClass("hidden");
				alertsEveryPanel.addClass("hidden");
				alertsDayBeforePanel.removeClass("hidden");
				alertsTimePanel.removeClass("hidden");
				alertsTextPanel.removeClass("hidden");
				alertsHourBeforePanel.addClass("hidden");
				break;
			case "7":
				alertsEmailPanel.removeClass("hidden");
				alertsEveryPanel.addClass("hidden");
				alertsDayBeforePanel.addClass("hidden");
				alertsTimePanel.addClass("hidden");
				alertsTextPanel.addClass("hidden");
				alertsHourBeforePanel.addClass("hidden");
				break;
			case "8":
				alertsEmailPanel.addClass("hidden");
				alertsEveryPanel.addClass("hidden");
				alertsDayBeforePanel.removeClass("hidden");
				alertsTimePanel.removeClass("hidden");
				alertsTextPanel.addClass("hidden");
                alertsHourBeforePanel.addClass("hidden");
				break;
            case "9":
                alertsEmailPanel.addClass("hidden");
                alertsEveryPanel.addClass("hidden");
                alertsDayBeforePanel.addClass("hidden");
                alertsTimePanel.addClass("hidden");
                alertsTextPanel.addClass("hidden");
                alertsHourBeforePanel.removeClass("hidden");
                break;
			default:
				console.warn("This state should not be possible. This may be an indication of a page error.");
		}
	};
	self.deleteRow = function (e) {
	    if (window.confirm("Are you sure you want to delete this alert?")) {
	    var changeId = alertsRemindersPanel.closest("[data-change-id]").data("change-id");
		deleteAlertAjax($(e.target).closest("tr").data("status"), changeId);
		removeAlertTableRow($(e.target).closest("tr"));
	    }
	};
	self.addAlertsRemindersRow = function(alertReminder) {
	    addAlertTableRow(alertReminder, alertReminder.type);
	};
	$().ready(function () {
		$("button[data-role='submit']", alertsRemindersPanel).click(self.submitClick);
		$("input[name='alert-type']", alertsRemindersPanel).change(self.changeAlertType);
		$(alertsTable).on('click', "a[data-role='delete']", self.deleteRow);
		if (alertsRemindersPanel.data("status") && alertsRemindersPanel.data("status").length > 0) {
			var data = alertsRemindersPanel.data("status");
			for (var i = 0; i < data.length; i++) {
				if (data[i].typeId == 2) {
					data[i].recurrence = data[i].time;
					//data[i].time = null;
				}
				addAlertTableRow(data[i], data[i].type);
			}
		}
		document.addEventListener("recurringChanged", setIsRecurring);
		document.addEventListener("dueOnChanged", setDueOn);
		$("div.alerts-email-panel select").val($("#groupID").val());
	});
	return self;
};
/* Copyright © 2024 Renegade Swish, LLC */

