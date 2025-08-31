var schedulingBox = function (containerElem) {
    var self = {};
	var schedulingPanel = $("div.scheduling-panel", containerElem);
	var singleTaskPanel = $("div.single-task-panel", schedulingPanel);
	var recurringTaskPanel = $("div.recurring-task-panel", schedulingPanel);
	var dailyRecurringPanel = $("div.daily-recurring-panel", recurringTaskPanel);
	var weeklyRecurringPanel = $("div.weekly-recurring-panel", recurringTaskPanel);
	var monthlyRecurringPanel = $("div.monthly-recurring-panel", recurringTaskPanel);
	var yearlyRecurringPanel = $("div.yearly-recurring-panel", recurringTaskPanel);
	var recurringTaskDetailsPanel = $("div.recurring-task-details-panel", recurringTaskPanel);
	var busDayMonthPanel = $("div.bus-day-month", recurringTaskPanel);
	var scheduleUserID = $(".schedule-user-id", schedulingPanel);
	var busDayValUser = 64; //magic number, Mandi is the only one who can use this

	self.container = "#scheduling-panel";
	self.isRecurring = function () {	    
	    return schedulingPanel.data("status").frequencyType != 1;
	}
	self.getDueOn = function () {	    
	    var status = schedulingPanel.data("status");
	    return new Date(status.firstDueDate.toString());
	}
	self.getSoftDueOffset = function () {	    
		var status = schedulingPanel.data("status");
		return status.softDueOffsetDays;
	}
	self.toggleRecurring = function () {
	    $("select[data-item='recurring']", schedulingPanel).find("option[value='']").remove();

		var recurrenceSelector = $("select[data-item='recurring']", schedulingPanel);
		var recurrenceVal = recurrenceSelector.val();
		switch (recurrenceVal) {
			case "once":
				if (!recurringTaskPanel.hasClass("hidden")) {
					recurringTaskPanel.addClass("hidden");
				}
				if (singleTaskPanel.hasClass("hidden")) {
					singleTaskPanel.removeClass("hidden");
				}
				var updatedStatus  = schedulingPanel.data("status");
				updatedStatus.frequencyType = 1;
				schedulingPanel.attr("data-status", JSON.stringify(updatedStatus));
				self.ResetFrequencyInterval(null);
				break;
			case "recurring":
				if (!singleTaskPanel.hasClass("hidden")) {
					singleTaskPanel.addClass("hidden");
				}
				if (recurringTaskPanel.hasClass("hidden")) {
					recurringTaskPanel.removeClass("hidden");
				}
				var updatedStatus = schedulingPanel.data("status");
				updatedStatus.frequencyType = $("[data-item='recurrence-type']", recurringTaskPanel).val();
				schedulingPanel.attr("data-status", JSON.stringify(updatedStatus));
				self.switchRecurrenceType();
				break;
			default:
				console.warn("This state should not be possible. This may be an indication of a page error.");
		}
		var instanceId = schedulingPanel.closest('div[data-instance-id]').data('instance-id');
		document.dispatchEvent(new CustomEvent("recurringChanged",{bubbles: true,cancelable: true,detail:{ isRecurring: self.isRecurring(), instanceId: instanceId }}));
	};
	self.ResetFrequencyInterval = function (newValue){
	    var status = schedulingPanel.data("status");
	    status.frequencyInterval = newValue;
	    schedulingPanel.attr("data-status", JSON.stringify(status));
	}
	self.switchRecurrenceType = function () {	    
		var status = schedulingPanel.data("status");
		if (status.frequencyType == 1)
			return;
		var recurrenceSelector = $("select[data-item='recurrence-type']", schedulingPanel);
		var recurrenceVal = recurrenceSelector.val();
		var chosenPanel;
		switch (recurrenceVal) {
			case "2":
			    //daily
			    chosenPanel = dailyRecurringPanel;
			    dailyRecurringPanel.removeClass("hidden");
				weeklyRecurringPanel.addClass("hidden");
				monthlyRecurringPanel.addClass("hidden");
				yearlyRecurringPanel.addClass("hidden");
				yearlyRecurringPanel.addClass("hidden");
				if (!busDayMonthPanel.hasClass("hidden")) {
				    busDayMonthPanel.addClass("hidden");
				}
				self.ResetFrequencyInterval(0);
				break;
			case "3":
			    //weekly
			    chosenPanel = weeklyRecurringPanel;
				dailyRecurringPanel.addClass("hidden");
				weeklyRecurringPanel.removeClass("hidden");
				monthlyRecurringPanel.addClass("hidden");
				yearlyRecurringPanel.addClass("hidden");
				if (!busDayMonthPanel.hasClass("hidden")) {
				    busDayMonthPanel.addClass("hidden");
				}
				self.changeDaysOfWeek();
				break;
			case "4":
			    //monthly
			    chosenPanel = monthlyRecurringPanel;
				dailyRecurringPanel.addClass("hidden");
				weeklyRecurringPanel.addClass("hidden");
				monthlyRecurringPanel.removeClass("hidden");
				yearlyRecurringPanel.addClass("hidden");
				if (busDayMonthPanel.hasClass("hidden")) {
				    if (scheduleUserID.val() == busDayValUser) {
				        busDayMonthPanel.removeClass("hidden");
				    }
				}
				self.ResetFrequencyInterval(0);
				break;
			case "5":
			    //yearly
			    chosenPanel = yearlyRecurringPanel;
				dailyRecurringPanel.addClass("hidden");
				weeklyRecurringPanel.addClass("hidden");
				monthlyRecurringPanel.addClass("hidden");
				yearlyRecurringPanel.removeClass("hidden");
				if (busDayMonthPanel.hasClass("hidden")) {
				    if (scheduleUserID.val() == busDayValUser) {
				        busDayMonthPanel.removeClass("hidden");
				    }
				}
				self.changeMonthsOfYear();
				break;
			case "6":
				//quarterly
				dailyRecurringPanel.addClass("hidden");
				weeklyRecurringPanel.addClass("hidden");
				monthlyRecurringPanel.addClass("hidden");
				yearlyRecurringPanel.addClass("hidden");
				if (busDayMonthPanel.hasClass("hidden")) {
				    if (scheduleUserID.val() == busDayValUser) {
				        busDayMonthPanel.removeClass("hidden");
				    }
				}
                self.ResetFrequencyInterval(0);
				break;
			default:
				console.warn("This state should not be possible. This may be an indication of a page error.");
		}
		var frequencyElem = $("input[name='freq-recurrence']", chosenPanel);
		if (!frequencyElem.val()) {
		    frequencyElem.val(1);
		}
		var newFreq = $("input[name='freq-recurrence']", chosenPanel).val();
		status.frequencyRecurrence = newFreq;
		status.frequencyType = recurrenceVal;
		schedulingPanel.attr("data-status", JSON.stringify(status));
		self.changeBusinessDayBehavior();
	};
	self.changeDueOn = function () {
	    //get new date from element
		var newDate = $("input[name='due-on']", singleTaskPanel).val();
		//get status object from panel
		var status = schedulingPanel.data("status");
		//set status.firstDueDate equal to new date
		status.firstDueDate = newDate;
		//put status back onto html object
		schedulingPanel.attr("data-status", JSON.stringify(status));

		var instanceId = schedulingPanel.closest('div[data-instance-id]').data('instance-id');
		document.dispatchEvent(new CustomEvent("dueOnChanged", { bubbles: true, cancelable: true, detail: { newDate: newDate, instanceId: instanceId } }));
	};
	self.changeSoftDue = function () {
	    var newDate = $("input[name='soft-due']", singleTaskPanel).val();
	    var status = schedulingPanel.data("status");
	    status.firstSoftDue = newDate;
	    schedulingPanel.attr("data-status", JSON.stringify(status));
	};
	self.changeDueAt = function () {
		var newTime = $("select[name='due-time']", singleTaskPanel).val();
		var status = schedulingPanel.data("status");
		status.dueTime = newTime;
		schedulingPanel.attr("data-status", JSON.stringify(status));
	};
	self.changeDueTimeZone = function () {
		var timeZone = $("select[name='due-time-zone']", singleTaskPanel).val();
		var status = schedulingPanel.data("status");
		status.timeZone = timeZone;
		schedulingPanel.attr("data-status", JSON.stringify(status));
	};
	self.changeDailyFrequency = function () {
		var newFreq = $("input[name='freq-recurrence']", dailyRecurringPanel).val();
		var status = schedulingPanel.data("status");
		status.frequencyRecurrence = newFreq;
		schedulingPanel.attr("data-status", JSON.stringify(status));
	};
	self.changeWeeklyFreqency = function () {
		var newFreq = $("input[name='freq-recurrence']", weeklyRecurringPanel).val();
		var status = schedulingPanel.data("status");
		status.frequencyRecurrence = newFreq;
		schedulingPanel.attr("data-status", JSON.stringify(status));
	};
	self.changeMonthlyFreqency = function () {
		var newFreq = $("input[name='freq-recurrence']", monthlyRecurringPanel).val();
		var status = schedulingPanel.data("status");
		status.frequencyRecurrence = newFreq;
		schedulingPanel.attr("data-status", JSON.stringify(status));
	};
	self.changeYearlyFreqency = function () {
		var newFreq = $("input[name='freq-recurrence']", yearlyRecurringPanel).val();
		var status = schedulingPanel.data("status");
		status.frequencyRecurrence = newFreq;
		schedulingPanel.attr("data-status", JSON.stringify(status));
	};
	self.changeBusinessDayBehavior = function () {
	    var newBehavior = $("input[type='radio'][data-item='weekend-fallback']:checked", recurringTaskDetailsPanel).val();
		var status = schedulingPanel.data("status");
		status.businessDayBehavior = newBehavior;
		schedulingPanel.attr("data-status", JSON.stringify(status));
		self.changeBusinessDayValue();
	};
	self.changeBusinessDayValue = function () {
	    var newBusinessDayValue = $("select[name='bus-day-val']", recurringTaskDetailsPanel).val();
	    var status = schedulingPanel.data("status");
	    var behavior = $("input[type='radio'][data-item='weekend-fallback']:checked", recurringTaskDetailsPanel).val();
	    if (behavior < 4) { newBusinessDayValue = null;}
	    status.businessDayValue = newBusinessDayValue;
	    schedulingPanel.attr("data-status", JSON.stringify(status));
	};
	self.changeFirstDueDate = function () {
		var newDate = $("input[data-item='first-date']", recurringTaskDetailsPanel).val();
		var status = schedulingPanel.data("status");
		status.firstDueDate = newDate;
		schedulingPanel.attr("data-status", JSON.stringify(status));
	};
	self.changeLastDueDate = function () {
		var newDate = $("input[data-item='last-date']", recurringTaskDetailsPanel).val();
		var status = schedulingPanel.data("status");
		status.lastDueDate = newDate;
		schedulingPanel.attr("data-status", JSON.stringify(status));
	};
	self.changeDueTime = function () {
		var newTime = $("select[data-item='due-time']", recurringTaskDetailsPanel).val();
		var status = schedulingPanel.data("status");
		status.dueTime = newTime;
		schedulingPanel.attr("data-status", JSON.stringify(status));
	};
	self.changeTimeZone = function () {
		var timeZone = $("select[data-item='due-time-zone']", recurringTaskDetailsPanel).val();
		var status = schedulingPanel.data("status");
		status.timeZone = timeZone;
		schedulingPanel.attr("data-status", JSON.stringify(status));
	};
	self.changeSoftDueOffset = function () {
		var newCount = $("input[data-item='soft-due']", recurringTaskDetailsPanel).val();
		var status = schedulingPanel.data("status");
		status.softDueOffsetDays = newCount;
		schedulingPanel.attr("data-status", JSON.stringify(status));
	};
	self.changeDaysOfWeek = function () {
		var elements = $("input[type='checkbox'][name='weekday']:checked", weeklyRecurringPanel);
		var newValue = 0;
		for (var i = 0; i < elements.length; i++) {
			newValue = newValue + parseInt($(elements[i]).attr("data-val"));
		}
		var status = schedulingPanel.data("status");
		status.frequencyInterval = newValue;
		schedulingPanel.attr("data-status", JSON.stringify(status));
	};
	self.changeMonthsOfYear = function () {	    
		var elements = $("input[type='checkbox'][name='month']:checked", yearlyRecurringPanel);
		var newValue = 0;
		for (var i = 0; i < elements.length; i++) {
			newValue = newValue + parseInt($(elements[i]).attr("data-val"));
		}
		var status = schedulingPanel.data("status");
		status.frequencyInterval = newValue;
		schedulingPanel.attr("data-status", JSON.stringify(status));
    };
    self.saveChangesExisting = function (e) {
        self.saveChanges(false, true);
    };
	self.saveChanges = function (newTask, showAlert) {
        //default newTask to false
	    //newTask = typeof newTask !== 'undefined' ? newTask : false;

	    var status = schedulingPanel.data("status");
	    var data = status;
	    if (!data.dueTime){
	        data.dueTime = 0;
	    }
	    //on save, change quarterly into every 3 months
		if (data.frequencyType == 6) {
		    data.frequencyType = 4;
		    data.frequencyRecurrence = 3;
		}
        data.instanceId = schedulingPanel.closest('div[data-instance-id]').data('instance-id');
		data.newTask = newTask;
		data.changeId = $("#task-container").data("change-id");
		$.ajax({
			url: "../DataService.asmx/SaveSchedule",
			type: "POST",
			data: JSON.stringify(data),
			dataType: "json",
			contentType: "application/json; charset=utf-8",
			async: false
		});

        if (showAlert) { alert("save complete"); }

		if (typeof manageTasks !== "undefined") {
		    var taskArea = schedulingPanel.closest('div[data-instance-id]').find("div.working-on-now").first();
			var params = {
				InstanceId: status.instanceId,
				ChangeId: $("#task-container").data("change-id")
			};
			if (typeof slider === 'undefined')
				manageTasks.refreshWorkingOnNow(taskArea, params);
		}
	};
	self.populateSchedule = function (scheduleObject) {
	    var recurrenceType;
	    var cleanedFirstDueDate = jsDate(scheduleObject.firstDueDate);
	    var cleanedLastDueDate = jsDate(scheduleObject.lastDueDate);
	    var cleanedFirstSoftDue = jsDate(scheduleObject.firstSoftDue);

	    //special case for instances with no schedule
		if (scheduleObject.frequencyType == 0) {
			scheduleObject.firstDueDate = new Date(scheduleObject.localNow); 
		    scheduleObject.firstSoftDue = scheduleObject.firstDueDate;
		    cleanedFirstDueDate = scheduleObject.firstDueDate;
		    cleanedFirstSoftDue = cleanedFirstDueDate;
		    scheduleObject.dueTime = 19;
		    schedulingPanel.attr("data-status", JSON.stringify(scheduleObject));
		}


		$("select[data-item='recurring'] option", schedulingPanel).removeAttr("selected");
		$("select[data-item='recurring']", schedulingPanel).find("option[value='" + (scheduleObject.frequencyType > 1 ? "recurring" : "once") + "']").attr("selected", "selected");
		$("select[data-item='recurrence-type'] option", schedulingPanel).removeAttr("selected");
        $("select[data-item='recurrence-type']", schedulingPanel).find("option[value='" + scheduleObject.frequencyType + "']").attr("selected", "selected");
        $("select[data-item='recurrence-type']", schedulingPanel).find("option[value='" + scheduleObject.frequencyType + "']").prop("selected", "selected");
        $("select[data-item='recurrence-type']", schedulingPanel).val(scheduleObject.frequencyType);
		switch (scheduleObject.frequencyType) {
			case 2:
			    $("input[name='freq-recurrence']", dailyRecurringPanel).attr("value", scheduleObject.frequencyRecurrence);
				break;
			case 3:
			    $("input[name='freq-recurrence']", weeklyRecurringPanel).attr("value", scheduleObject.frequencyRecurrence);
				recurrenceType = "weekly";
				break;
			case 4:
			    $("input[name='freq-recurrence']", monthlyRecurringPanel).attr("value", scheduleObject.frequencyRecurrence);
				break;
			case 5:
			    $("input[name='freq-recurrence']", yearlyRecurringPanel).attr("value", scheduleObject.frequencyRecurrence);
				recurrenceType = "yearly";
				break;
		}

		if (typeof slider !== 'undefined') {
			$("[name='due-on']", singleTaskPanel).val(getFormattedDate(cleanedFirstDueDate));
			$("[name='due-on']", singleTaskPanel).trigger("change");
			$("[name='soft-due']", singleTaskPanel).val(getFormattedDate(cleanedFirstSoftDue));
			$("[name='soft-due']", singleTaskPanel).trigger("change");
			$("[data-role='save']").removeClass("btn-default").addClass("btn-secondary");
		} else {
			$("[name='due-on']", singleTaskPanel).data("lwDatepicker").setActiveDate(cleanedFirstDueDate);
			$("[name='soft-due']", singleTaskPanel).data("lwDatepicker").setActiveDate(cleanedFirstSoftDue);
		}

		$("[name='due-time']", singleTaskPanel).find("option[value='" + scheduleObject.dueTime + "']").attr("selected", "selected");
		$("[name='due-time-zone']", singleTaskPanel).find("option[value='" + scheduleObject.timeZone + "']").attr("selected", "selected");
		$("[name='due-time-zone']", singleTaskPanel).find("option[value='" + scheduleObject.timeZone + "']").prop("selected", "selected");
		$("[name='due-time-zone']", singleTaskPanel).trigger("change");
		$("[data-item='due-time-zone']", recurringTaskDetailsPanel).trigger("change");
		$("input[type='radio'][data-item='weekend-fallback']", recurringTaskDetailsPanel).prop({ checked: false });
		$("input[type='radio'][data-item='weekend-fallback']", recurringTaskDetailsPanel).filter("[value='" + scheduleObject.businessDayBehavior + "']").prop({ checked: true });
		if (scheduleObject.businessDayValue != null)
		{
		    //debugger;
		    $("select[name='bus-day-val'] option", recurringTaskDetailsPanel).removeAttr("selected");
		    $("select[name='bus-day-val']", recurringTaskDetailsPanel).find("option[value='" + scheduleObject.businessDayValue + "']").attr("selected", "selected");
		}

		if (typeof slider !== 'undefined') {
			if (cleanedFirstDueDate != null)
				$("input[data-item='first-date']", recurringTaskDetailsPanel).val(getFormattedDate(cleanedFirstDueDate));
			if (cleanedLastDueDate != null)
				$("input[data-item='last-date']", recurringTaskDetailsPanel).val(getFormattedDate(cleanedLastDueDate));
		} else {
			if (cleanedFirstDueDate != null)
				$("input[data-item='first-date']", recurringTaskDetailsPanel).data("lwDatepicker").setActiveDate(cleanedFirstDueDate);
			if (cleanedLastDueDate != null)
				$("input[data-item='last-date']", recurringTaskDetailsPanel).data("lwDatepicker").setActiveDate(cleanedLastDueDate);
		}

		$("select[data-item='due-time']", recurringTaskDetailsPanel).find("option[value='" + scheduleObject.dueTime + "']").attr("selected", "selected");
		$("select[data-item='due-time-zone']", recurringTaskDetailsPanel).find("option[value='" + scheduleObject.timeZone + "']").attr("selected", "selected");
		$("select[data-item='due-time-zone']", recurringTaskDetailsPanel).find("option[value='" + scheduleObject.timeZone + "']").prop("selected", "selected");		
		$("input[data-item='soft-due']", recurringTaskDetailsPanel).attr("value", scheduleObject.softDueOffsetDays);
		var bitmaskElements;
		if (recurrenceType) {
			if(recurrenceType=="weekly") {
				bitmaskElements = $("input[type='checkbox'][data-val]", weeklyRecurringPanel);
			}else if(recurrenceType=="yearly") {
				bitmaskElements = $("input[type='checkbox'][data-val]", yearlyRecurringPanel);
			}else {
				console.warn("Value 'recurrenceType' may be invalid.");
			}
			for(var i = 0; i<bitmaskElements.length;i++) {
			    var maskValue = parseInt($(bitmaskElements[i]).data("val"));
			    if ((maskValue & scheduleObject.frequencyInterval) > 0) {
					$(bitmaskElements[i]).attr("checked", "checked");
				}else {
					$(bitmaskElements[i]).removeAttr("checked");
				}
			}
		}

	    //special case for instances with no schedule
		if (scheduleObject.frequencyType == 0) {
		    cleanedFirstDueDate = new Date(scheduleObject.localNow).toLocaleDateString();
		    $("select[data-item='recurring'] option", schedulingPanel).removeAttr("selected");
		    $("select[data-item='recurring']", schedulingPanel).prepend("<option value=''></option>");
		    $("select[data-item='recurring']", schedulingPanel).val("");
		    singleTaskPanel.addClass("hidden");
       	}
		else {
		    self.toggleRecurring();
		    self.switchRecurrenceType();
		}
	};
	function init() {
		if (typeof slider !== 'undefined') {
			$("input[data-role='datepicker']", schedulingPanel).mobiscroll().date({
				theme: getMobileOperatingSystem(),
				display: 'modal'
			});
		} else {
			$("input[data-role='datepicker']", schedulingPanel).lwDatepicker();
		}

		//debugger;

		$("select[data-item='recurring']", schedulingPanel).change(self.toggleRecurring);
		$("select[data-item='recurrence-type']", recurringTaskPanel).change(self.switchRecurrenceType);
		$("input[name='due-on']", singleTaskPanel).change(self.changeDueOn);
		$("select[name='due-time']", singleTaskPanel).change(self.changeDueAt);
		$("select[name='due-time-zone']", singleTaskPanel).change(function () {
			$("option[name='dtz-resize-option']", singleTaskPanel.closest(".form-inline")).html($(this).find("option:selected").text());
			$(this).width($("select[name='dtz-resize']", singleTaskPanel.closest(".form-inline")).width());  
			self.changeDueTimeZone();
		});
		$("input[name='soft-due']", singleTaskPanel).change(self.changeSoftDue);
		$("input[name='freq-recurrence']", dailyRecurringPanel).change(self.changeDailyFrequency);
		$("input[name='freq-recurrence']", weeklyRecurringPanel).change(self.changeWeeklyFreqency);
		$("input[name='freq-recurrence']", monthlyRecurringPanel).change(self.changeMonthlyFreqency);
		$("input[name='freq-recurrence']", yearlyRecurringPanel).change(self.changeYearlyFreqency);
		$("input[type='radio'][data-item='weekend-fallback']", recurringTaskDetailsPanel).click(self.changeBusinessDayBehavior);
		$("select[name='bus-day-val']", recurringTaskDetailsPanel).click(self.changeBusinessDayValue);
		$("input[data-item='first-date']", recurringTaskDetailsPanel).change(self.changeFirstDueDate);
		$("input[data-item='last-date']", recurringTaskDetailsPanel).change(self.changeLastDueDate);
		$("select[data-item='due-time']", recurringTaskDetailsPanel).change(self.changeDueTime);
		$("select[data-item='due-time-zone']", recurringTaskDetailsPanel).change(function () {
			$("option[name='dtz-resize-option']", recurringTaskDetailsPanel.closest(".form-inline")).html($(this).find("option:selected").text());
			$(this).width($("select[name='dtz-resize']", recurringTaskDetailsPanel.closest(".form-inline")).width());
			self.changeTimeZone();
		});
		$("input[data-item='soft-due']", recurringTaskDetailsPanel).change(self.changeSoftDueOffset);
		$("input[type='checkbox'][name='weekday']", weeklyRecurringPanel).click(self.changeDaysOfWeek);
		$("input[type='checkbox'][name='month']", yearlyRecurringPanel).click(self.changeMonthsOfYear);
		if(schedulingPanel.closest("[data-instance-id]").length) {
			//if we're on the manage tasks page
			var toAppend = $("<input>").attr({
				"type":"button",
				"data-role": "save",
				"value": "Save Changes"
			});
			$(".form-group:first",schedulingPanel).append(toAppend);
            $("a[data-role='save']", schedulingPanel).click(self.saveChangesExisting);
		}
		var data = schedulingPanel.data("status");
		if (data) {
		    self.populateSchedule(data);
		}

	}
	init();
	return self;
};

function expandCallback(parent) {
	if (parent.hasClass("mtform-assignments")) {
		$("[name='due-time-zone']", parent).trigger("change");
		$("[data-item='due-time-zone']", parent).trigger("change");
	}
}
/* Copyright © 2024 Renegade Swish, LLC */

