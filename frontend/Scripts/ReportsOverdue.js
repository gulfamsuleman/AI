var reportOverdueModule = (function() {
	var self = {};
	var sortBy = $("select[data-role='sort-by']");
	var overdueUsers = $("select[data-role='show-overdue']");
	var openLink = $("a[data-role='open-overdue-message']");
	
	$().ready(function () {
		sortBy.change(reloadOverdueTasks);
		overdueUsers.change(reloadOverdueTasks);
		openLink.click(openOverdueMessageModal);
		loadMessages();
		if ($(".old-overdue").length > 0) {
		    $("#overdue-alert").show();
		}
	});
	
	function reloadOverdueTasks() {
		var params = {
			UserId: overdueUsers.find("option:selected").val(),
			Sort: sortBy.find("option:selected").val()
		};
		reportsModule.showThrobber(reportsModule.overdue);
		reportsModule.overdue.load("../JQueryHandler.ashx?ControlName=" + encodeURI("Controls/Reports/Overdue.ascx"), params, function (){});
	}

	function loadMessages() {
		var params = {
			UserId: overdueUsers.find("option:selected").val(),
			Sort: sortBy.find("option:selected").val()
		};
		$("#message").load("../JQueryHandler.ashx?ControlName=" + encodeURI("Controls/Reports/OverdueMessage.ascx"), params, function (){});
	}
	
	function openOverdueMessageModal() {
		$(".filters").addClass("hidden");
		$("#message").removeClass("hidden");
	}
	
	return self;
})()
/* Copyright © 2024 Renegade Swish, LLC */

