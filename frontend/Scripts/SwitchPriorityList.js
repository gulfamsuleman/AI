var switchPriorityModule = (function() {
	var self = {};
	var newListTextbox = $("#new-list");
	var page = "Priorities.aspx";
	
	$().ready(function() {
		$(document).on("click", "#switch-table tr:not(#new-list-row)", function(e) { switchPriorityList(e); });
		newListTextbox.keypress(function(e) { newList(e); });

		if (typeof slider !== 'undefined') page = "MobilePriorities.aspx";
	});

	function switchPriorityList(e) {
		var row = $(e.currentTarget);
		var setId = row.data("id");
		if(setId != $("#set-id").val())
			window.location.href = page + "?setId=" + row.data("id");
		else {
			if (typeof slider !== 'undefined')
				slider.removeClass('open');
			else
				window.modalModule.hide();
		}
	}
	
	function newList(e) {
		if (e.which == 13) {
			if (newListTextbox.val().length > 0) {
				$.ajax({
					url: "../DataService.asmx/AddPriorityList",
					type: "POST",
					data: JSON.stringify({ listName: newListTextbox.val() }),
					contentType: "application/json",
					success: function(data) {
						window.location.href = page + "?setId=" + data.d;
					}
				});
			}
		}
	}

	return self;
})()
/* Copyright © 2024 Renegade Swish, LLC */

