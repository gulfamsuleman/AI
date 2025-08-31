var setDefaultPriorityModule = (function() {
	var self = {};
	var setDefaultButton = $("[data-role='default']");
	var cancelButton = $("[data-role='cancel']");
	var modal = window.modalModule;

	$().ready(function() {
		setDefaultButton.click(setDefaultPriorityList);
		cancelButton.click(cancelSetDefault);
	});
	
	function setDefaultPriorityList() {
		$.ajax({
			url: "/DataService.asmx/SetDefaultPriorityList",
			type: "POST",
			data: JSON.stringify({ setId: $("#set-id").val() }),
			contentType: "application/json",
			success: function(data) {
				window.location.href = isMobile ? "MobilePriorities.aspx" : "Priorities.aspx";
			}
		});
	}
	
	function cancelSetDefault() {
		if (typeof slider !== 'undefined') {
			slider.toggleClass('open');
			return;
		}

		modal.hide();
	}

	return self;
})()
/* Copyright © 2024 Renegade Swish, LLC */

