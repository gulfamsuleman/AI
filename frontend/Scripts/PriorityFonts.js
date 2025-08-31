var priorityFontModule = (function() {
	var self = {};
	var fontText = $("#font-text");
	var fontSizeElem = $("#size");
	var fontSize = parseInt(fontSizeElem.text());
	var largerButton = $("[data-role='increase-font']");
	var smallerButton = $("[data-role='decrease-font']");
	var saveButton = $("[data-role='save-font']");
	
	$().ready(function () {
		setFontSize();
		largerButton.click(increaseFontSize);
		smallerButton.click(decreaseFontSize);
		saveButton.click(updateFontSize);
	});
	
	function increaseFontSize() {
		fontSize++;
		setFontSize();
	}
	
	function decreaseFontSize() {
		if (fontSize > 1)
			fontSize--;
		setFontSize();
	}
	
	function setFontSize() {
		fontSizeElem.text(fontSize);
		fontText.css("font-size", fontSize + "pt");
	}
	
	function updateFontSize() {
		$.ajax({
			url: "/DataService.asmx/UpdateFontPreference",
			type: "POST",
			data: JSON.stringify({ fontSize: fontSize }),
			contentType: "application/json",
			success: function(data) {
				window.location.reload();
			}
		});
	}

	return self;
})()
/* Copyright © 2024 Renegade Swish, LLC */

