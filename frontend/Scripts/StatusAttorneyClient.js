var statusAttorneyClient = (function() {
	var self = {};
	var attorneyClientPanel = $("#attorney-client-panel");
	var attorneyClientSetter = $("#attorney-client-setter");

	self.populateAttorneyClientCheckbox = function(isConfidential) {
		isConfidential == true ?
			attorneyClientSetter.prop("checked", true) :
			attorneyClientSetter.prop("checked", false);
	};

	function setAttorneyClientAjax() {
		$.ajax({
			url: "/DataService.asmx/SetAttorneyClient",
			type: "POST",
			data: JSON.stringify({
				reportId: $("#hidden-report-id").val(),
				isConfidential: $("#attorney-client-setter").is(":checked")
			}),
			contentType: "application/json",
			success: function (response) {
				window.location.reload();
			},
			error: function () {
				alert("An error occurred while processing your request.");
			}
		});
	}

	self.setAttorneyClient = function(e) {
		setAttorneyClientAjax();
	};

	$().ready(function() {
		attorneyClientPanel.on('click', "button[data-role='save']", self.setAttorneyClient);
	});
	
	return self;
})()
/* Copyright © 2024 Renegade Swish, LLC */

