function format(str) {
	for (var i = 1; i < arguments.length; i++) {
		str = str.replace('{' + (i - 1) + '}', arguments[i]);
	}
	return str;
}

function jsDate(cSharpDate) {
	if (!!cSharpDate) {
		return new Date(parseInt(cSharpDate.substring(6)) - clntTz + svrTz);
	} else {
		return null;
	}
}

function queryObj() {
	var result = {}, keyValuePairs = location.search.slice(1).split('&');

	keyValuePairs.forEach(function (keyValuePair) {
		keyValuePair = keyValuePair.split('=');
		result[keyValuePair[0]] = keyValuePair[1] || '';
	});

	return result;
}

$.fn.extend({
	//check to see if jquery found any elements
	hasElements: function() {
		return !!this.length;
	}
});

var serialize = function (obj) {
	var str = [];
	for (var p in obj)
		str.push(encodeURIComponent(p) + "=" + encodeURIComponent(obj[p]));
	return str.join("&");
};
/* Copyright © 2024 Renegade Swish, LLC */

