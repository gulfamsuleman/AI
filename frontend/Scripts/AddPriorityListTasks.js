var addPriorityTasksModule = (function() {
	var self = {};
	var forUserId = $("#for-user-id").val();
	var forListId = $("#for-list-id").val();
	var searchBox = $("#search-box");
	var searchButton = $("[data-role='search']");
	var radioButtons = $("input[type='radio'][name='order']");
	var availableTasksTable = $("#available-tasks-table");
	var addCheckedButton = $("[data-role='add-checked']");
	var dayAddButton = $("[data-role='add-due-today']");
	var weekAddButton = $("[data-role='add-due-week']");
	var excludeButton = $("[data-role='exclude']");
	var modal = null;
	var priorities = null;
	var selectedActiveChecklistID = 0;

	$().ready(function () {
		modal = window.modalModule;
		priorities = window.prioritiesModule;
		searchBox.keyup(function (e) { searchEvent(e); });
		searchButton.click(search);
		radioButtons.change(handleRadioChoice);
		addCheckedButton.click(addCheckedTasks);
		dayAddButton.click(addTasksDueToday);
		weekAddButton.click(addTasksDueThisWeek);
		excludeButton.click(excludeTasks);
	});
	
	function addCheckedTasks() {
		$.ajax({
			url: "/DataService.asmx/AddPriorityTasks",
			type: "POST",
			data: JSON.stringify({
				toListId: forListId,
				setId: window.prioritiesModule.setId,
				activeChecklistIds: getCheckedTasks()
			}),
			contentType: "application/json",
			success: function (data) {
				priorities.unobnoxiousReload();
			},
			error: function(jqXHR, textStatus, errorThrown) {
                                alert(textStatus + ": " + errorThrown);
                        }
			
		});
	}
	
	function addTasksDueToday() {
		$.ajax({
			url: "/DataService.asmx/AddOneDayTasks",
			type: "POST",
			data: JSON.stringify({
				forUserId: forUserId,
				toListId: forListId,
				setId: window.prioritiesModule.setId,
			}),
			contentType: "application/json",
			success: function (data) {
				priorities.unobnoxiousReload();
			}
		});
	}

	function addTasksDueThisWeek() {
		$.ajax({
			url: "/DataService.asmx/AddWeekTasks",
			type: "POST",
			data: JSON.stringify({
				forUserId: forUserId,
				toListId: forListId,
				setId: window.prioritiesModule.setId,
			}),
			contentType: "application/json",
			success: function(data) {
				priorities.unobnoxiousReload();
			}
		});
	}
	
	function excludeTasks() {
		$.ajax({
			url: "/DataService.asmx/ExcludeTasks",
			type: "POST",
			data: JSON.stringify({
				forUserId: forUserId,
				activeChecklistIds: getCheckedTasks()
			}),
			contentType: "application/json",
			success: function(data) {
			    $("#available-tasks-table input[type='checkbox']:checked").closest("tr").remove();
			}
		});
	}
	
	function getCheckedTasks() {
		var checked = $("#available-tasks-table input[type='checkbox']:checked");
		var activeCheckListIds = "";
		checked.each(function() {
			activeCheckListIds += $(this).closest("tr").data("active-checklist-id") + ";";
		});
		return activeCheckListIds;
	}
	
	function searchEvent(e) {
		if (e.which == 13) {
			search();
		}
	}
	
	function search() {
		if (searchBox.val().length == 0)
			availableTasksTable.removeHighlight();
		else {
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
			$('.checklist-name').each(function(){
				trid = $(this).closest('tr').attr('data-active-checklist-id');
				if ($(this).html().toLowerCase().indexOf(searchBox.val().toLowerCase()) >= 0){
					foundsearchhit = true;
					if (firstsearchhit == null){
						firstsearchhit = trid;
					}
					if (selectedActiveChecklistID == 0 || foundprevioushit){
						foundnexthit = true;
						return false;
					}
				}
				if (trid == selectedActiveChecklistID){
					foundprevioushit = true;
				}
			});

			if (foundsearchhit){
				if (foundnexthit){
					selectedActiveChecklistID = trid;
				}
				else{
					selectedActiveChecklistID = firstsearchhit;
				}
				scrollTo = $('[data-active-checklist-id="'+selectedActiveChecklistID+'"]');
				searchscroll = scrollTo.offset().top - container.offset().top + container.scrollTop();
			}
			else{
				selectedActiveChecklistID = 0;
			}

			container.animate({
    			scrollTop: searchscroll 
			});
		}
	}
	
	function handleRadioChoice() {
		var choice = $("input[type='radio'][name='order']:checked");
		window.prioritiesModule.openAvailableTasksModal(choice.val());
	}

	return self;
})()
/* Copyright © 2024 Renegade Swish, LLC */

