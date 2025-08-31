var addExistingTaskModule = (function() {
    var self = {};
    var selectedSectionId = $("#selected-section-id").val();
    var searchBox = $("#search-box");
    var searchButton = $("[data-role='search']");
    var radioButtons = $("input[type='radio'][name='order']");
    var availableTasksTable = $("#available-tasks-table");
    var addCheckedButton = $("[data-role='add-checked']");
    var dayAddButton = $("[data-role='add-due-today']");
    var weekAddButton = $("[data-role='add-due-week']");
    var excludeButton = $("[data-role='exclude']");
    var assigneeFilter = $("#ddFilter");
    var modal = null;
    var reportToolbar = null;
	var selectedActiveChecklistID = 0;
	var section = null;
	
    $().ready(function () {
	    modal = window.modalModule;
	    reportToolbar = window.reportToolbarModule;
	    searchBox.keyup(function (e) { searchEvent(e); });
	    searchButton.click(search);
	    radioButtons.change(handleRadioChoice);
	    addCheckedButton.click(addCheckedTasks);
	    dayAddButton.click(addTasksDueToday);
	    weekAddButton.click(addTasksDueThisWeek);
	    excludeButton.click(excludeTasks);
		assigneeFilter.change(filterAssignees);

		if (typeof slider !== "undefined") {
			$.ajax({
				url: "/DataService.asmx/GetTaskTypesForReport",
				type: "POST",
				data: { reportId: reportId },
				async: false,
				success: function (data) {

				},
				error: function (jqXHR, textStatus, errorThrown) {
					//notifier.setMessage(textStatus + ": " + errorThrown, "red", 4000);
				}
			});
			slider.html()
		}
    });

	function addExistingTaskAjax(instanceId) {
		$.ajax({
			url: "/DataService.asmx/AddExistingTaskToSectionOutput",
			type: "POST",
			data: { taskInstanceId: instanceId, sectionId: selectedSectionId },
            async: false,
			error: function (jqXHR, textStatus, errorThrown) {
			    notifier.setMessage(textStatus + ": " + errorThrown, "red", 4000);
			}
		});
	}

	function addCheckedTasks() {
	    var checked = $("#available-tasks-table input[type='checkbox']:checked");
	    var instanceId;
	    var added = false;
	    checked.each(function () {
	        instanceId = $(this).closest("tr").data("instance-id");
	        addExistingTaskAjax(instanceId);
	        added = true;
	    });
		if (added) {
			if (typeof slider === "undefined") {
				window.modalModule.hide();
				notifier.setMessage("Task(s) added.", "green", 2000);
				setTimeout(reload, 3000);
			}
			else {
				slider.toggleClass("open");
				setTimeout(reload, 1000);
			}
				
		} else {
			if (typeof slider === "undefined")
				notifier.setMessage("No task(s) to add.", "yellow", 2000);
			else
				slider.toggleClass("open");
	    }
	}

	function addTasksDueToday() {
	    var checked = $("#available-tasks-table input[type='checkbox']");
	    var taskDate;
	    var today = Date.today();
	    checked.each(function () {
	        taskDate = new Date($(this).closest("tr").children("td:eq(2)").text());
	        if (taskDate.equals(today)) {
	            $(this).prop("checked", true);
	        }
	    });
	}

	function addTasksDueThisWeek() {
	    var checked = $("#available-tasks-table input[type='checkbox']");
	    var taskDate;
	    var today = Date.today();
	    var nextWeek = Date.today().addDays(7);
	    checked.each(function () {
	        taskDate = new Date($(this).closest("tr").children("td:eq(2)").text());
	        if (taskDate.between(today, nextWeek)) {
	            $(this).prop("checked", true);
	        }
	    });
	}

	function excludeTasks() {
        /*
	    $.ajax({
	        url: "/DataService.asmx/ExcludeTasks",
	        type: "POST",
	        data: JSON.stringify({
	            forUserId: forUserId,
	            activeChecklistIds: getCheckedTasks()
	        }),
	        contentType: "application/json",
	        success: function (data) {
	            $("#available-tasks-table input[type='checkbox']:checked").closest("tr").remove();
	        }
	    });
        */
	}

	function getCheckedTasks() {
	    var checked = $("#available-tasks-table input[type='checkbox']:checked");
	    var instanceIds = "";
	    checked.each(function () {
	        instanceIds += $(this).closest("tr").data("instance-id") + ";";
	    });
	    return instanceIds;
	}

	function searchEvent(e) {
	    if (e.which == 13) {
	        search();
	    }
	}

	function search() {
	    if (searchBox.val().length == 0) {
	        availableTasksTable.removeHighlight();
	    } else {
	        availableTasksTable.removeHighlight();
	        availableTasksTable.highlight(searchBox.val());

	        var container = $('#available-tasks');
	        var foundprevioushit = false;
	        var firstsearchhit;
	        var foundsearchhit = false;
	        var trid;
	        var searchscroll = 0;
	        var foundnexthit = false;

	        //loop through all the tasks and find the *next* hit
	        $('.checklist-name').each(function () {
	            trid = $(this).closest('tr').attr('data-instance-id');
	            if ($(this).html().toLowerCase().indexOf(searchBox.val().toLowerCase()) >= 0) {
	                foundsearchhit = true;
	                if (firstsearchhit == null) {
	                    firstsearchhit = trid;
	                }
	                if (selectedActiveChecklistID == 0 || foundprevioushit) {
	                    foundnexthit = true;
	                    return false;
	                }
	            }
	            if (trid == selectedActiveChecklistID) {
	                foundprevioushit = true;
	            }
	        });

	        if (foundsearchhit) {
	            if (foundnexthit) {
	                selectedActiveChecklistID = trid;
	            }
	            else {
	                selectedActiveChecklistID = firstsearchhit;
	            }
	            scrollTo = $('[data-instance-id="' + selectedActiveChecklistID + '"]');
	            searchscroll = scrollTo.offset().top - container.offset().top + container.scrollTop();
	        }
	        else {
	            selectedActiveChecklistID = 0;
	        }

	        container.animate({
	            scrollTop: searchscroll
	        });

	    }
	}

	function handleRadioChoice() {
		var choice = $("input[type='radio'][name='order']:checked");

		if (slider !== undefined) return;

	    reportToolbar.addExistingTaskModalSort(selectedSectionId, choice.val());
	}

	function filterAssignees() {
	    if (assigneeFilter.val() == "") {
	        $("#available-tasks-table tr").show();
	    } else {
	        $("#available-tasks-table tr").hide();
	        $("#available-tasks-table tr:contains('" + assigneeFilter.val() + "')").show();
	    }
	    
	}

	function reload()
	{
	    window.location.reload();
	}

	return self;
})()
/* Copyright © 2024 Renegade Swish, LLC */

