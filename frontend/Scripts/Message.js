var messageModule = (function() {
	var self = {};
	var sendMessageButton = $("[data-role='send-message']");
	var modal = window.modalModule;

	$().ready(function() {
		sendMessageButton.click(sendMessage);
	});
	
	function sendMessage() {
		var message = $("#message-box").val();
		if (message.length > 0) {
			$.ajax({
				url: "/DataService.asmx/SendMessage",
				type: "POST",
				data: JSON.stringify({
					messageTo: $("#set-locked-by-id").val(),
					message: message
				}),
				contentType: "application/json",
				success: function (data) {
					modal.hide();
					$("#message-box").val("");
					window.prioritiesModule.resetTimeout();
					window.prioritiesModule.replyMessageOpen = false;
				}
			});
		}
	}
	
	return self;
})()
/* Copyright © 2024 Renegade Swish, LLC */

