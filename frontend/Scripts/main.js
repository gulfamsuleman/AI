var prioritiesModule = null;
var lastKeepAliveCheck = null;
var failureCount = 0;
var sessionFailureCount = 0;

var sessionCheckWindow = null;

var sessionCheck = function (force) {
	//No matter what, even if we're trying to force it, if we've failed too many times just give up.
	if (sessionFailureCount > 2) {
		if (sessionCheckWindow) {
			sessionCheckWindow.close();
			sessionCheckWindow = null;
			return;
		}
	}
	//If the user moves to a different browser tab (or a different app window, or the computer sleeps),
	//JS may stop running on QP. We can check this using the KeepAlive timestamp
	//harmless new Date() - purely client-side, used for timing keepalive checks
	if ((!document.hidden && new Date().getTime() - lastKeepAliveCheck.getTime() > (15 * 60 * 1000)) || force) {
		//If we haven't sent a heartbeat in a while, we should verify the user auth is still valid
		//Don't try to re-open the window if it's already open (user's likely being prompted to login)
		if (sessionCheckWindow == null || sessionCheckWindow.closed || force)
			sessionCheckWindow = window.open("../SessionCheck.aspx", "_sessChk", "popup,width=800,height=500",);

		//if (!sessionCheckWindow)
		//	alert("Your session appears to have timed out, and a popup to re-establish it was blocked.")

		var checkResult = function () {
			if (sessionCheckWindow != null) {
				if (sessionCheckWindow.closed) {
					sessionCheckWindow = null;
					return;
				}

				//Gateway Timeouts have been reported in this process; 
				//the fix is simple, just retry
				var body = $(sessionCheckWindow.document).find("body");
				if (body.html().includes("The corporate app cannot be accessed")
					|| body.html().toLowerCase().includes("gateway timeout")
					|| body.html().toLowerCase().includes("gateway time-out")) {
					sessionFailureCount++;
					sessionCheckWindow.location.reload();
				}
			}

			setTimeout(checkResult, 1000 + Math.floor(Math.random() * 4000));
		};

		setTimeout(checkResult, 1000 + Math.floor(Math.random() * 4000));
	}
}

var keepAliveTimeout = null;

var keepAlive = function () {
	if (typeof prioritiesModule === 'undefined') return;

	$.ajax({
		url: "/DataService.asmx/KeepAlive",
		type: "POST",
		contentType: "application/json",
		async: true,
		success: function () {
			lastKeepAliveCheck = new Date(); //harmless; used for tracking the keepalive feature
			failureCount = 0;
			sessionFailureCount = 0;
			if (prioritiesModule != undefined && prioritiesModule) {
				prioritiesModule.resetTimeout();
				//prioritiesModule.timerSpan.hide();
			}

			if (keepAliveTimeout)
				clearTimeout(keepAliveTimeout);

			keepAliveTimeout = setTimeout(function () { keepAlive(); }, 240000);
		},
		error: function () {			
			//Most likely failure is the session's already dead; the SessionCheck routine will re-establish it
			//However this can be invasive; avoid it unless we're pretty sure it's needed.
			//If we've failed multiple times, or last succeeded more than 15 mins ago, just do it.
			//harmless new Date() - purely client-side for tracking keepAlive
			var force = (++failureCount >= 3 || new Date().getTime() - lastKeepAliveCheck.getTime() > (16 * 60 * 1000));

			//TODO: interrogate the XHR for specific error info; certain failures should force re-auth as well.

			sessionCheck(force);			
			
			if (keepAliveTimeout)
				clearTimeout(keepAliveTimeout);

			keepAliveTimeout = setTimeout(function () { keepAlive(); }, 300000);

			if (prioritiesModule)
				prioritiesModule.timerSpan.show();
		}
	});
};

$().ready(function () {
	$("input[data-role='datepicker']").lwDatepicker();
	$.contextMenu('html5');

	keepAlive();
	$(window).on("visibilitychange", keepAlive);
	$(window).on("online", keepAlive);
});

var SaveLoadTimes = true;

var notifier = (function () {
	var self = {};
	self.setMessage = function (message, color, timeToLive) {
		switch (color) {
			case "red":
				$(".notification-box").attr("data-color", "red");
				break;
			case "green":
				$(".notification-box").attr("data-color", "green");
				break;
			case "yellow":
				$(".notification-box").attr("data-color", "yellow");
				break;
			default:
				console.warn("Possible error: Attribute 'color' of 'notifier.setMessage' is invalid.");
				return;
		}
		$(".notification-box [data-role='message']").html(message);
		$(".notification-box").attr("data-shown", "true");
		setTimeout(function () {
			$(".notification-box").attr("data-shown", "false");
		}, timeToLive);
	};
	$().ready(function() {
		$(".notification-box [data-role='close']").click(function() {
			$(".notification-box").attr("data-shown", "false");
		});
	});
	return self;
})();

// Used for IE support. IE doesn't support the DOM4 constructor for custom events. 
// https://developer.mozilla.org/en-US/docs/Web/API/CustomEvent
(function () {
	function CustomEvent(event, params) {
		params = params || { bubbles: false, cancelable: false, detail: undefined };
		var evt = document.createEvent('CustomEvent');
		evt.initCustomEvent(event, params.bubbles, params.cancelable, params.detail);
		return evt;
	};

	CustomEvent.prototype = window.CustomEvent.prototype;

	window.CustomEvent = CustomEvent;
})();

// Used for IE8 support, IE8 doesn't support the Array.forEach method
if (!Array.prototype.forEach) {
	Array.prototype.forEach = function (fun /*, thisArg */) {
		"use strict";

		if (this === void 0 || this === null)
			throw new TypeError();

		var t = Object(this);
		var len = t.length >>> 0;
		if (typeof fun !== "function")
			throw new TypeError();

		var thisArg = arguments.length >= 2 ? arguments[1] : void 0;
		for (var i = 0; i < len; i++) {
			if (i in t)
				fun.call(thisArg, t[i], i, t);
		}
	};
}


// The following functions are used for expand/collapse accross My Tasks, Manage Tasks, and My Status pages.
function expandObject(jQuerySelector) {
	jQuerySelector.find("[data-role='expand-indicator']").removeClass("fa-plus-square-o").addClass("fa-minus-square-o");
	jQuerySelector.find(".collapsed").removeClass("collapsed").addClass("expanded");
	jQuerySelector.attr("data-collapse-state", "expanded");
}

function collapseObject(jQuerySelector) {
	
	jQuerySelector.find("[data-role='expand-indicator']").removeClass("fa-minus-square-o").addClass("fa-plus-square-o");
	jQuerySelector.find(".expanded").removeClass("expanded").addClass("collapsed");
	jQuerySelector.attr("data-collapse-state", "collapsed");
	
}

$(document).on('click', "[data-collapse-target='true']", (function (e) {
	e.preventDefault();
	var parentObject = $(e.target).closest(".collapsible-item");
	if (parentObject.attr("data-collapse-state") === "collapsed") {
		expandObject(parentObject);
		if (typeof expandCallback === 'function') {
    			expandCallback(parentObject);
		}
	} else if (parentObject.attr("data-collapse-state") === "expanded") {
		collapseObject(parentObject);
	} else {
		console.error("A collapsible object on this page has reached an error state. Please contact your system administrator.");
	}
}));

function bindExpandAllClick() {
	$("[data-role='expand-all']").click(function (e) {
		e.preventDefault();
		var target = $(e.target).closest("label");
		target.attr("data-role", "collapse-all");
		expandAll();
		target.unbind("click");
		bindCollapseAllClick();
	});
}

function expandAll() {
	var collapsedItems = $(".collapsible-item[data-collapse-state='collapsed']");
	expandObject(collapsedItems);
}

function bindCollapseAllClick() {
	$("[data-role='collapse-all']").click(function (e) {
		e.preventDefault();
		var target = $(e.target).closest("label");
		target.attr("data-role", "expand-all");
		collapseAll();
		target.unbind("click");
		bindExpandAllClick();
	});
}

function collapseAll() {
	var expandedItems = $(".collapsible-item[data-collapse-state='expanded']");
	collapseObject(expandedItems);
}

function saveLoadTimes() {
	if (!SaveLoadTimes) return;

	var clientLoadEnd = new Date(); //harmless; performance tracking
	var clientLoadTime = clientLoadEnd - window.clientLoadBegin;

	var data = {
		pageName: $("#current-page-name").val(),
		serverLoadTime: $("#server-load").val(),
		clientLoadTime: clientLoadTime
	};
	var reportId = $("#hidden-report-id").val();
	reportId ? data.reportId = reportId : data.reportId = -1;
	var lastViewed = $("#last-viewed").val();
	lastViewed ? data.lastViewed = lastViewed : data.lastViewed = null;
	
	$.ajax({
		url: "/DataService.asmx/SaveReportLoadTime",
		type: "POST",
		data: JSON.stringify(data),
		contentType: "application/json"
	});
}

/* Copyright © 2024 Renegade Swish, LLC */

