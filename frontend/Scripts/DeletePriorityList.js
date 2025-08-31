var deletePriorityModule = (function() {
	var self = {};
	var deleteButton = $("[data-role='delete']");
	var cancelButton = $("[data-role='cancel']");
	var modal = window.modalModule;

	$().ready(function() {
		deleteButton.click(deletePriorityList);
		cancelButton.click(cancelDelete);
	});
	
	function deletePriorityList() {
		$.ajax({
			url: "/DataService.asmx/DeletePriorityList",
			type: "POST",
			data: JSON.stringify({ setId: $("#set-id").val() }),
			contentType: "application/json",
			success: function (data) {				
				window.location.href = isMobile ? "MobilePriorities.aspx" : "Priorities.aspx";
			}
		});
	}
	
	function cancelDelete() {
		if (typeof slider !== 'undefined') {
			slider.toggleClass('open');
			return;
		}

		modal.hide();
	}

	return self;
})()
/* Copyright © 2024 Renegade Swish, LLC */

