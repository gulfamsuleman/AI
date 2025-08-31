var tasksByPersonModule = (function() {
	var self = {};
	var userSelection = $("select[data-role='user-selection']");
	var searchBox = $("input[data-role='search-task']");
	var personButton = $("[data-role='search-person']");
	var everyoneButton = $("[data-role='search-everyone']");
	$().ready(function() {
		userSelection.change(function () { reloadTasksByPerson(userSelection.find("option:selected").val()); });
		personButton.click(function () { reloadTasksByPerson(userSelection.find("option:selected").val()); });
		everyoneButton.click(function () { reloadTasksByPerson(-1); });
	});
	
	function reloadTasksByPerson(userId) {
		var params = {
			Search: searchBox.val(),
			SelectedUserId: userId
		};
		reportsModule.showThrobber(reportsModule.tasksByPerson);
		reportsModule.tasksByPerson.load("JQueryHandler.ashx?ControlName=" + encodeURI("Controls/Reports/TasksByPerson.ascx"), params, function () { });
	}

	return self;
})()
/* Copyright © 2024 Renegade Swish, LLC */

