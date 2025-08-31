var manageEmailsModule = (function() {
	var self = {};

	$().ready(function() {
		$("#manage-emails-panel input[type='checkbox']").change(function (e) { updateSettingAjax(e); });
	});
	
	function updateSettingAjax(e) {
		var checkbox = $(e.currentTarget);
		$.ajax({
			url: "../DataService.asmx/SetSupervisorEmailPreference",
			type: "POST",
			data: JSON.stringify({
				type: checkbox.data("type"),
				sendEmail: checkbox.prop("checked")
			}),
			contentType: "application/json",
			success: function(data) {
				
			}
		});
	}

	return self;
})()
/* Copyright © 2024 Renegade Swish, LLC */

