var modalModule = (function () {
	var self = {};
	var modalElem = $("#modal");
	var titleElem = $(".modal-title", modalElem);
	var contentElem = $(".modal-body", modalElem);
	var submitBtnElem = $("#modal-button", modalElem);
	var settings = {};
	var buttonBound = false;
	var hideHandler = null;
	modalElem.modal({
		show: false
	});
	modalElem.find("button.close").click(function () {
		self.hide();
	});
	$("#modal").on("hidden", function() {
		self.dispose();
	});
	self.init = function (options) {
	    settings.elementID = options.elementID;
		settings.controlName = options.controlName;
		settings.pageName = options.pageName;
		if (settings.controlName && settings.pageName) console.warn("A control and page were both specified. This is probably an error.");
		if (settings.controlName && settings.elementID) console.warn("A control and element were both specified. This is probably an error.");
		if (settings.elementID && settings.pageName) console.warn("An element and page were both specified. This is probably an error.");
		settings.remoteParams = options.remoteParams;
		settings.buttonText = options.buttonText;
		settings.buttonCallback = options.buttonCallback;
		settings.titleText = options.titleText || "";
		settings.initFunction = options.initFunction;
		settings.initFunctionParams = options.initFunctionParams;
		self.build();
		self.show();
	};
	var onContentLoad = new CustomEvent("modalModuleContentLoad");
	var onClose = new CustomEvent("modalModuleClosed");
	self.show = function () {
		modalElem.modal("show");
	};
	self.onHide = function (handler) {
	    hideHandler = handler;
	};
	self.hide = function () {
		modalElem.modal("hide");
		if (hideHandler)
			hideHandler();
		self.dispose();
	};
	self.build = function() {
		updateTitle();
		updateContent();
		updateButton();
		bindSubmitButton();
	};
	self.dispose = function() {
		removeTitle();
		removeContent();
		removeButton();
		unbindSubmitButton();
		document.dispatchEvent(onClose);
		$(".modal-backdrop").remove();
	};
	var updateTitle = function() {
		titleElem.text(settings.titleText);
	};
	var removeTitle = function() {
		titleElem.text("");
	};
	var updateContent = function () {
		if (exists(settings.controlName)) {
			contentElem.load("JQueryHandler.ashx?ControlName=" + encodeURI(settings.controlName), settings.remoteParams, function() {
				document.dispatchEvent(onContentLoad);
				if (settings.initFunction)
					settings.initFunction.call(this, settings.initFunctionParams);
			});
		}else if(exists(settings.pageName)){
			contentElem.load(settings.pageName, settings.remoteParams, function() {
				document.dispatchEvent(onContentLoad);
				if (settings.initFunction)
					settings.initFunction.call(this, settings.initFunctionParams);
			});
		} else if (exists(settings.elementID)) {
		    contentElem.html($("#" + settings.elementID).html());
		}
	};
	var removeContent = function() {
		contentElem.html("");
	};
	var updateButton = function() {
		if (!exists(settings.buttonText))
			$(".modal-footer").hide();
		submitBtnElem.text(settings.buttonText);
	};
	var removeButton = function() {
		$(".modal-footer").show();
		submitBtnElem.text("");
	};
	var bindSubmitButton = function () {
		if (buttonBound)
			return;
		submitBtnElem.bind("click", settings.buttonCallback);
		buttonBound = true;
	};
	var unbindSubmitButton = function () {
		if (!buttonBound)
			return;
		submitBtnElem.unbind("click", settings.buttonCallback);
		buttonBound = false;
	};
	
	function exists(object) {
		return !!object;
	}
	
	return self;
})();
/* Copyright © 2024 Renegade Swish, LLC */

