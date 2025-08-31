var footerModule = (function () {
	var self = {};
	var modal = null;

	$().ready(function () {
	    var footer = $("#site-footer");
		footer.find("a[data-action='preferences']").click(openPreferences);
		footer.find("a[data-action='view-groups']").click(openViewGroups);
		footer.find("a[data-action='overdueAdmin']").click(openOverdueAdminMonitor);//added by venkat 01/12/2018
		modal = window.modalModule;
	});
	
	function openPreferences() {
		modal.init({
			titleText: "My Preferences",
			controlName: "Controls/Footer/Preferences.ascx"
		});
	}
	
	function openViewGroups() {
		modal.init({
			titleText: "View Groups",
			controlName: "Controls/Footer/ViewGroups.ascx"
		});
	}

	function openOverdueAdminMonitor() {//added by venkat 01/12/2018
	    window.open("OverdueTaskReport.aspx", "OverdueTaskReport", "toolbar=no,status=no,scrollbars=yes,resizable=yes,menubar=yes,width=1100,height=770");
	}

	return self;
})()
/* Copyright © 2024 Renegade Swish, LLC */

