var createPriorityModule = (function() {
	var self = {};
	var createButton = $("[data-role='create']");
	var cancelButton = $("[data-role='cancel']");
	var modal = window.modalModule;

	$().ready(function() {
		createButton.click(createPriorityList);
		cancelButton.click(cancelCreate);
	});
	
	function createPriorityList() {
		$.ajax({
			url: "../DataService.asmx/CreatePriorityList",
			type: "POST",
			data: JSON.stringify({ listName: $("#new-list").val() }),
			contentType: "application/json",
			success: function (data) {
				if (typeof slider !== 'undefined') {
					window.location.href = "MobilePriorities.aspx";
					return;
				}

				window.location.href = "Priorities.aspx";
			}
		});
	}
	
	function cancelCreate() {
		if (typeof slider !== 'undefined') {
			slider.toggleClass('open');
			return;
		}

		$("#new-list").val("")
		modal.hide();
	}

	return self;
})()
/* Copyright © 2024 Renegade Swish, LLC */

