var addGroupModule = (function() {
	var self = {};

	$().ready(function() {
		$(document).on("click", "button[data-role='add-user-group']", function () { addUserGroup(); });
	});

	function addUserGroup() {
		$.ajax({
			url: "../DataService.asmx/AddGroup",
			type: "POST",
			data: JSON.stringify({
				name: $("#group-name").val()
			}),
			contentType: "application/json",
			success: function (data) {
				window.location.reload();
			}
		});
	}

	return self;
})()
/* Copyright © 2024 Renegade Swish, LLC */

