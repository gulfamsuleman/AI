///////////////////////////////////////////////////////////////////////////////////////////////////////////
// browser resize events
// even thought the resizeContent function is attached to onload and onresize event, please add only the
// resize functionalities to this function
///////////////////////////////////////////////////////////////////////////////////////////////////////////

//window.onload = resizeContent;
//window.onresize = resizeContent;

///////////////////////////////////////////////////////////////////////////////////////////////////////////
// when setting an element height, always remember to set it with "px" suffix for cross browser compatibility
// Example: always make sure divContent element is 100px less than browser height 
// Usage: document.getElementById("divContent").style.height = (height - 100) + "px";
//
// DO NOT USE THIS, PLEASE ADD TO YOUR WEBPAGE OR JS FILE, THEN COMMENT BELOW FUNCTION OUT
///////////////////////////////////////////////////////////////////////////////////////////////////////////
//function resizeContent() {
//    // get the current browser view height and width
//    var height = 0;
//    var width = 0;
//    
//    if (typeof window.innerWidth != 'undefined') {
//        height = window.innerHeight;
//        width = window.innerWidth;
//    }
//    else
//    {
//        height = document.getElementsByTagName('body')[0].clientHeight;
//        width = document.getElementsByTagName('body')[0].clientWidth;
//    }
//}

///////////////////////////////////////////////////////////////////////////////////////////////////////////
// browser onload events
// add your one time onload event here, however, try to use async logic when possible to give a more
// responsive loading experience for the webpage
//
// DO NOT USE THIS, PLEASE ADD TO YOUR WEBPAGE OR JS FILE, THEN COMMENT BELOW FUNCTION OUT
///////////////////////////////////////////////////////////////////////////////////////////////////////////
//$(document).ready(function () {
//   
//});

///////////////////////////////////////////////////////////////////////////////////////////////////////////
// IE does not know about the target attribute. It looks for srcElement 
// This function will get the event target in a browser-compatible way 
///////////////////////////////////////////////////////////////////////////////////////////////////////////
function getEventTarget(e) {
    e = e || window.event;
    return e.target || e.srcElement;
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////
// custom function add-in to jQuery to allow showing div in center of window
// Example: show a hidden div in the center of the browser
// Usage: $(element).show().center(); 
///////////////////////////////////////////////////////////////////////////////////////////////////////////
jQuery.fn.center = function () {
    this.css("position", "absolute");
    this.css("top", Math.max(0, (($(window).height() - this.outerHeight()) / 2) + $(window).scrollTop()) + "px");
    this.css("left", Math.max(0, (($(window).width() - this.outerWidth()) / 2) + $(window).scrollLeft()) + "px");
    return this;
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////
// custom function add-in to jQuery to allow toggle checked state for checkbox/radiobutton
// Example: set a checkbox to checked state
// Usage: $(element).checked(true); 
///////////////////////////////////////////////////////////////////////////////////////////////////////////
jQuery.fn.checked = function (value) {
    if (value === true || value === false) {
        // Set the value of the checkbox
        $(this).each(function () { this.checked = value; });
    }
    else if (value === undefined || value === 'toggle') {
        // Toggle the checkbox
        $(this).each(function () { this.checked = !this.checked; });
    }

    return this.checked;
};

///////////////////////////////////////////////////////////////////////////////////////////////////////////
// custom function add-in to jQuery to get status of checked state
// Example: get checkbox check state
// Usage: $(element).CommaFormat(); 
///////////////////////////////////////////////////////////////////////////////////////////////////////////
function commaFormat(x) {
    if (x == null || x == undefined) return "";

    var parts = x.toString().split(".");
    parts[0] = parts[0].replace(/\B(?=(\d{3})+(?!\d))/g, ",");
    return parts.join(".");
};

function moneyFormat(x) {
    if (x == null || x == undefined) return "$0";

    var parts = x.toString().split(".");
    parts[0] = parts[0].replace(/\B(?=(\d{3})+(?!\d))/g, ",");
    return "$" + parts.join(".");
};

///////////////////////////////////////////////////////////////////////////////////////////////////////////
// custom function add-in to jQuery to get status of checked state
// Example: get checkbox check state
// Usage: $(element).IsChecked(); 
///////////////////////////////////////////////////////////////////////////////////////////////////////////
jQuery.fn.IsChecked = function () {
    return $(this).is(':checked');
};

///////////////////////////////////////////////////////////////////////////////////////////////////////////
// change out the stylesheet assuming you have a <link> with the id of themeStyle between your <head> tags
// Usage: changeTheme('grayscale.css'); 
///////////////////////////////////////////////////////////////////////////////////////////////////////////
function changeTheme(cssName) {
    $("#themeStyle").attr('href', 'css/' + cssName);
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////
// add trim extension method to string type since IE8 or lower does not support trim in javascript yet
// Usage: $("#txtName").val().trim()
///////////////////////////////////////////////////////////////////////////////////////////////////////////
String.prototype.trim = function () { return this.replace(/(?:(?:^|\n)\s+|\s+(?:$|\n))/g, '').replace(/\s+/g, ' '); };

///////////////////////////////////////////////////////////////////////////////////////////////////////////
// Usage:   var data = {
//              'brown': 'red',
//              'lazy': 'slow'
//          };
//
//          "The quick %{brown} fox jumped over the %{lazy} dog.".bindData(data);
//          result => The quick red fox jumped over the slow dog
///////////////////////////////////////////////////////////////////////////////////////////////////////////
String.prototype.bindData = function (data) {
    var m, ret = this;
    while (m = /%\{\s*([^\}\s]+)\s*\}/.exec(ret)) {
        ret = ret.replace(m[0], data[m[1]] || '??');
    }
    return ret;
};

///////////////////////////////////////////////////////////////////////////////////////////////////////////
// this replaces the builtin replace function to allow replacing of all instance instead of just the first one
// Usage: "this is a test on another test on yet another test".replace("test", "tttt");
///////////////////////////////////////////////////////////////////////////////////////////////////////////
String.prototype.replaceEx = function (pattern, replacement) { return this.split(pattern).join(replacement); };

///////////////////////////////////////////////////////////////////////////////////////////////////////////
// format date function similar to the .NET version
// Usage:   var date = new Date();
//          alert(String.format("Date 1: {0}\nDate 2:{1}\nDate3: {2}",
//                      date.formatDate("yyyy-MM-dd HH:mm"),
//                      date.formatDate("MM/dd/yyyy hh:mm t"),
//                      date.formatDate("MM-yyyy hh:mmt")));
///////////////////////////////////////////////////////////////////////////////////////////////////////////
Date.prototype.formatDate = function (format) {
    var date = this;
    if (!format)
        format = "MM/dd/yyyy";

    var month = date.getMonth() + 1;
    var year = date.getFullYear();

    format = format.replace("MM", month.toString().padL(2, "0"));
    format = format.replace("M", month.toString());

    if (format.indexOf("yyyy") > -1)
        format = format.replace("yyyy", year.toString());
    else if (format.indexOf("yy") > -1)
        format = format.replace("yy", year.toString().substr(2, 2));

    format = format.replace("dd", date.getDate().toString().padL(2, "0"));
    format = format.replace("d", date.getDate().toString());

    var hours = date.getHours();
    if (format.indexOf("t") > -1) {
        if (hours > 11)
            format = format.replace("t", "pm")
        else
            format = format.replace("t", "am")
    }
    if (format.indexOf("T") > -1) {
        if (hours > 11)
            format = format.replace("T", "PM")
        else
            format = format.replace("T", "AM")
    }
    if (format.indexOf("HH") > -1)
        format = format.replace("HH", hours.toString().padL(2, "0"));
    if (format.indexOf("hh") > -1) {
        if (hours > 12) hours -= 12;
        if (hours == 0) hours = 12;
        format = format.replace("hh", hours.toString().padL(2, "0"));
    }
    if (format.indexOf("mm") > -1)
        format = format.replace("mm", date.getMinutes().toString().padL(2, "0"));
    if (format.indexOf("ss") > -1)
        format = format.replace("ss", date.getSeconds().toString().padL(2, "0"));
    return format;
}

function parseDate(jsonDateString) {
    return new Date(parseInt(jsonDateString.replace('/Date(', '')));
}

String.repeat = function (chr, count) {
    var str = "";
    for (var x = 0; x < count; x++) { str += chr };
    return str;
}
String.prototype.padL = function (width, pad) {
    if (!width || width < 1)
        return this;

    if (!pad) pad = " ";
    var length = width - this.length
    if (length < 1) return this.substr(0, width);

    return (String.repeat(pad, length) + this).substr(0, width);
}
String.prototype.padR = function (width, pad) {
    if (!width || width < 1)
        return this;

    if (!pad) pad = " ";
    var length = width - this.length
    if (length < 1) this.substr(0, width);

    return (this + String.repeat(pad, length)).substr(0, width);
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////
// return true or false if string is valid date in format of MM/DD/YYYY
// Usage:   if ("03/11/2001".IsDate()) 
//              alert("Valid date");
///////////////////////////////////////////////////////////////////////////////////////////////////////////
String.prototype.IsDate = function () {
    var s = this;

    // make sure it is in the expected format 
    if (s.search(/^\d{1,2}[\/|\-|\.|_]\d{1,2}[\/|\-|\.|_]\d{4}/g) != 0)
        return false;

    // remove other separators that are not valid with the Date class     
    s = s.replace(/[\-|\.|_]/g, "/");

    // convert it into a date instance 
    var dt = new Date(Date.parse(s));

    // check the components of the date 
    // since Date instance automatically rolls over each component 
    var arrDateParts = s.split("/");
    return (
        dt.getMonth() == arrDateParts[0] - 1 &&
        dt.getDate() == arrDateParts[1] &&
        dt.getFullYear() == arrDateParts[2]
    );
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////
// return true or false if string is valid number
// flag input is to specify the type of number allowed
// 1 = Positive only; 2 = Negative only; 3 = Either positive or negative
// Usage:   if ("100.00".IsNumber(1)) 
//              alert("Valid positive number");
///////////////////////////////////////////////////////////////////////////////////////////////////////////
String.prototype.IsNumber = function (flag) {
    var strNum;
    var result = false;
    var msg;
    var dblVal;

    strNum = this.trim().split(",").join("");

    if (strNum.length < 1) {
        return false;
    }
    else {
        result = true;
    }

    dblVal = parseFloat(strNum);
    if (isNaN(dblVal)) {
        msg = 'You must enter a NUMBER.'
        result = false;
    }
    else {

        switch (flag) {
            case 1:
                if (dblVal < 0) {
                    result = false;
                    msg = 'You must enter a POSITIVE NUMBER.'
                }
                break;
            case 2:
                if (dblVal > 0) {
                    result = false;
                    msg = 'You must enter a NEGATIVE NUMBER.'
                }
                break;
            case 3:
                result = true;
                break;
            default:
                break;
        }
    }

    if (result) {
        return true;
    } else {
        //alert(msg);
        return false;
    }
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////
// easier way to add day to a date
// Usage: var d = new Date();
//        alert(d.addDays(5));
///////////////////////////////////////////////////////////////////////////////////////////////////////////
Date.prototype.addDays = function (days) {
    var dat = new Date(this.valueOf())
    dat.setDate(dat.getDate() + days);
    return dat;
}

Date.dayRange = function (date1, date2) {
    //Get 1 day in milliseconds
    var one_day = 1000 * 60 * 60 * 24;

    // Convert both dates to milliseconds
    var date1_ms = date1.getTime();
    var date2_ms = date2.getTime();

    // Calculate the difference in milliseconds
    var difference_ms = date2_ms - date1_ms;

    // Convert back to days and return
    return Math.round(difference_ms / one_day);
}

Date.yearRange = function (date1, date2) {
    //Get 1 year in milliseconds (assuming each year has exactly 365 days)
    var one_day = 1000 * 60 * 60 * 24 * 365;

    // Convert both dates to milliseconds
    var date1_ms = date1.getTime();
    var date2_ms = date2.getTime();

    // Calculate the difference in milliseconds
    var difference_ms = date2_ms - date1_ms;

    // Convert back to days and return
    return (difference_ms / one_day).toFixed(1);
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////
// Global Dates object to use for date comparison
// Usage: if (Dates.compare(a,b) == -1)
//          alert("A is less than B");
///////////////////////////////////////////////////////////////////////////////////////////////////////////
var Dates = {
    convert: function (d) {
        // Converts the date in d to a date-object. The input can be:
        //   a date object: returned without modification
        //  an array      : Interpreted as [year,month,day]. NOTE: month is 0-11.
        //   a number     : Interpreted as number of milliseconds
        //                  since 1 Jan 1970 (a timestamp) 
        //   a string     : Any format supported by the javascript engine, like
        //                  "YYYY/MM/DD", "MM/DD/YYYY", "Jan 31 2009" etc.
        //  an object     : Interpreted as an object with year, month and date
        //                  attributes.  **NOTE** month is 0-11.
        return (
            d.constructor === Date ? d :
            d.constructor === Array ? new Date(d[0], d[1], d[2]) :
            d.constructor === Number ? new Date(d) :
            d.constructor === String ? new Date(d) :
            typeof d === "object" ? new Date(d.year, d.month, d.date) :
            NaN
        );
    },
    compare: function (a, b) {
        // Compare two dates (could be of any type supported by the convert
        // function above) and returns:
        //  -1 : if a < b
        //   0 : if a = b
        //   1 : if a > b
        // NaN : if a or b is an illegal date
        // NOTE: The code inside isFinite does an assignment (=).
        return (
            isFinite(a = this.convert(a).valueOf()) &&
            isFinite(b = this.convert(b).valueOf()) ?
            (a > b) - (a < b) :
            NaN
        );
    },
    inRange: function (d, start, end) {
        // Checks if date in d is between dates in start and end.
        // Returns a boolean or NaN:
        //    true  : if d is between start and end (inclusive)
        //    false : if d is before start or after end
        //    NaN   : if one or more of the dates is illegal.
        // NOTE: The code inside isFinite does an assignment (=).
        return (
             isFinite(d = this.convert(d).valueOf()) &&
             isFinite(start = this.convert(start).valueOf()) &&
             isFinite(end = this.convert(end).valueOf()) ?
             start <= d && d <= end :
             NaN
         );
    }
}

////////////////////////////////////// WEB SERVICE METHOD BEGIN ///////////////////////////////////////////
var servicePage = "../DataService.asmx/";

///////////////////////////////////////////////////////////////////////////////////////////////////////////
// custom function to encapsulate sync function call to web service via jQuery 
// Example: change a phone number based on unique ID
// Usage: var param = JSON.stringify({ _id: ("#txtID").val(), _phone: ("#txtPhone").val() });
//        syncPost("SetPhoneNbr", param);
//        if (syncPostSuccess) {
//          $("#ddlOption").html(syncPostResult);
//        }
//        else {
//          alert("The following error occurred:\n\n" + syncPostResult);
//        }
///////////////////////////////////////////////////////////////////////////////////////////////////////////
var syncPostResult = "";
var syncPostSuccess = false;
function syncPost(methodName, parameters) {
    $.ajax({
        type: "POST",
        url: servicePage + methodName,
        data: parameters,
        contentType: "application/json; charset=utf-8",
        dataType: "json",
        async: false,
        success: function (msg) {
            syncPostSuccess = true;
            syncPostResult = "";

            // check to see if boolean value is returned
            if (typeof msg.d == "boolean" || typeof msg.d == "object" || typeof msg.d == "number" || msg.d == null) {
                syncPostResult = msg.d;
            } else {
                var idx = msg.d.indexOf("|");
                // only try to bind if the controlID is not blank
                if (idx != 0 && idx != -1 && idx < 40) {
                    if ($(msg.d.substring(0, idx)).prop('tagName') == "DIV" || $(msg.d.substring(0, idx)).prop('tagName') == "SELECT" || $(msg.d.substring(0, idx)).prop('tagName') == "TBODY")
                        $(msg.d.substring(0, idx)).html(msg.d.substring(idx + 1));
                    else 
                        $(msg.d.substring(0, idx)).val(msg.d.substring(idx + 1));
                } else {
                    syncPostResult = msg.d;
                }
            }
        },
        error: function (xhr, status, error) {
            var err = eval("(" + xhr.responseText + ")");
            syncPostResult = err.Message;
            syncPostSuccess = false;
        }
    });
}

function loadControl(pageName) {
    $.ajax({
        type: "GET",
        url: "controls/" + pageName + ".html",
        async: false,
        success: function (msg) {
            syncPostSuccess = true;
            syncPostResult = msg;
        },
        error: function (xhr, status, error) {
            var err = eval("(" + xhr.responseText + ")");
            syncPostResult = err.Message;
            syncPostSuccess = false;
        }
    });
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////
// custom function to encapsulate sync function call to web service via jQuery with own custom success and
// error function passing in as parameter
// Example: change a phone number based on unique ID
// Usage: var param = JSON.stringify({ _id: ("#txtID").val(), _phone: ("#txtPhone").val() });
//        syncPostEx("SetPhoneNbr", param, customSuccessFunction, customErrorFunction);
//
//        function customSuccessFunction(msg) {
//          ...
//        }
//        function customErrorFunction(xhr, status, error) {
//          ...
//        }
///////////////////////////////////////////////////////////////////////////////////////////////////////////
function syncPostEx(methodName, parameters, successCallBack, errorCallBack) {
    if (errorCallBack == null) {
        $.ajax({
            type: "POST",
            url: servicePage + methodName,
            data: parameters,
            contentType: "application/json; charset=utf-8",
            dataType: "json",
            async: false,
            success: successCallBack
        });
    } else {
        $.ajax({
            type: "POST",
            url: servicePage + methodName,
            data: parameters,
            contentType: "application/json; charset=utf-8",
            dataType: "json",
            async: false,
            success: successCallBack,
            error: errorCallBack
        });
    }
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////
// custom function to encapsulate async(ajax) function call to web service via jQuery
// Example: get a phone number based on unique ID
// Usage: var param = JSON.stringify({ _controlID: "#txtTest", _id: 0 });
//        asyncPost("GetPhoneNbr", param);
///////////////////////////////////////////////////////////////////////////////////////////////////////////
function asyncPost(methodName, parameters) {
    $.ajax({
        type: "POST",
        url: servicePage + methodName,
        data: parameters,
        contentType: "application/json; charset=utf-8",
        dataType: "json",
        success: function (msg) {

        },
        error: function (xhr, status, error) {
            // alert user of the error
            var err = eval("(" + xhr.responseText + ")");
            alert(err.Message);
        }
    });
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////
// custom function to encapsulate async(ajax) function call to web service via jQuery with own custom 
// success and error function passing in as parameter
// Example: get a phone number based on unique ID
// Usage: var param = JSON.stringify({ _controlID: "#txtTest", _id: 0 });
//        asyncPostEx("GetPhoneNbr", param, customSuccessFunction, customErrorFunction);
//
//        function customSuccessFunction(msg) {
//          $("#txtTest").val(msg.d);
//        }
//        function customErrorFunction(xhr, status, error) {
//          var err = eval("(" + xhr.responseText + ")");
//          alert("The following error occurred while processing your request:\n\n" + err.Message);
//        }
///////////////////////////////////////////////////////////////////////////////////////////////////////////
function asyncPostEx(methodName, parameters, successCallBack, errorCallBack) {
    if (errorCallBack == null) {
        $.ajax({
            type: "POST",
            url: servicePage + methodName,
            data: parameters,
            contentType: "application/json; charset=utf-8",
            dataType: "json",
            success: successCallBack
        });
    } else {
        $.ajax({
            type: "POST",
            url: servicePage + methodName,
            data: parameters,
            contentType: "application/json; charset=utf-8",
            dataType: "json",
            success: successCallBack,
            error: errorCallBack
        });
    }
}
function Post(methodName, parameters, successCallBack, errorCallBack) {
    if (errorCallBack == null) {
        $.ajax({
            type: "POST",
            url: methodName,
            data: parameters,
            contentType: "application/json; charset=utf-8",
            dataType: "json",
            success: successCallBack
        });
    } else {
        $.ajax({
            type: "POST",
            url: methodName,
            data: parameters,
            contentType: "application/json; charset=utf-8",
            dataType: "json",
            success: successCallBack,
            error: errorCallBack
        });
    }
}

function loadControl(ctlName, ctlPath) {
    $.ajax({
        type: "GET",
        url: ctlPath,
        async: false,
        success: function (msg) { $("#" + ctlName).html(msg); }
    });
}

//////////////////////////////////////// WEB SERVICE METHOD END //////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////////////////////////////////
// functions taken from old Junkbonds
///////////////////////////////////////////////////////////////////////////////////////////////////////////
function checkNumber(ctl, flag) {
    // The Flag input is to specify the type of number allowable
    // 1 = Positive only; 2 = Negative only; 3 = Either positive or negative

    var numfield = $(ctl);
    var strNum;
    var result = false;
    var msg;
    var dblVal;

    strNum = numfield.val().split(",").join("");

    if (strNum.length < 1) {
        return false;
    }
    else {
        result = true;
    }

    dblVal = parseFloat(strNum);
    if (isNaN(dblVal)) {
        msg = 'You must enter a NUMBER.'
        result = false;
    }
    else {

        switch (flag) {
            case 1:
                if (dblVal < 0) {
                    result = false;
                    msg = 'You must enter a POSITIVE NUMBER.'
                }
                break;
            case 2:
                if (dblVal > 0) {
                    result = false;
                    msg = 'You must enter a NEGATIVE NUMBER.'
                }
                break;
            case 3:
                result = true;
                break;
            default:
                break;
        }
    }

    if (result) {
        numfield.val(dblVal);
        return true;
    }
    else {
        alert(msg);
        numfield.focus();
        return false;
    }
}

// support IE8 as it doesn't support native keys function
function NumberOfKeys(theObject) {
    if (Object.keys)
        return Object.keys(theObject).length;

    var n = 0;
    for (var key in theObject)
        ++n;

    return n;
}

function showOverlay() {
    document.getElementById("overlay").style.visibility = "visible";
}

function hideOverlay() {
    document.getElementById("overlay").style.visibility = "hidden";
}

// alternate row colors
function alternateTableRowColor(tbl) {
    var alt = false;
    $(tbl).find("tbody tr").removeClass("alt").each(function () {
        if (alt) $(this).addClass("alt");

        alt = !alt;
    });
}

// Task History

function openHistory(checklistId, uniqueId = null)
{
    if (checklistId == null && uniqueId == null) {
        console.error("Both checklistId and uniqueId are null.");
        return;
    }

    var modal = window.modalModule; // Ensure modal is assigned to a global variable
    window.modal = modal; // Make modal globally accessible

    modal.init({
        titleText: "History",
        controlName: "Controls/Shared/ChecklistHistory.ascx",
        remoteParams: { checklistId: checklistId, uniqueId: uniqueId }
    });
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////
// Function to log feature usage
///////////////////////////////////////////////////////////////////////////////////////////////////////////
function logFeatureUsage(feature, details) {
    $.post('/PageUsageLogHandler.ashx', {
        feature: feature,
        details: details || '',
        isMobile: typeof isMobile !== "undefined" ? isMobile : false
    });
}
function logSearchPageAccess() {
    logFeatureUsage('SearchPage', window.location.pathname + window.location.search);
}

/* Copyright © 2024 Renegade Swish, LLC */