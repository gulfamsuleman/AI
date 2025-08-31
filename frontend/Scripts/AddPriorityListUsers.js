var addPriorityUsersModule = (function() {
	var self = {};
	var addUsersButton = $("[data-role='add-list-users']");

	$().ready(function() {
		addUsersButton.click(addPriorityUsers);
	});

	function addPriorityUsers() {
		var checked = $("input[type='checkbox']:checked");
		var listIds = "";
		checked.each(function() {
			listIds += $(this).closest("tr").data("id") + ";";
		});
		$.ajax({
			url: "DataService.asmx/AddPriorityListUsers",
			type: "POST",
			data: JSON.stringify({
				setId: $("#set-id").val(),
				listIds: listIds
			}),
			contentType: "application/json",
			success: function(data) {
				window.location.href = "Priorities.aspx?setId=" + $("#set-id").val();
			}
		});
	}

	return self;
})()
/* Copyright © 2024 Renegade Swish, LLC */

