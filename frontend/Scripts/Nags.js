var servicePage = "../NagService.asmx/";

function handleError(xhr) {
    if (xhr.responseText.indexOf("<!DOCTYPE html>") >= 0) {
        var errWindow = window.open();
        $(errWindow.document.body).html(xhr.responseText);
        return false;
    } else {
        var err = eval("(" + xhr.responseText + ")");
        alert("The following error occurred while processing your request:\n\n" + err.Message);
        return false;
    }
}

function getBrowser() {
    var ua = navigator.userAgent, tem, M = ua.match(/(opera|chrome|safari|firefox|msie|trident(?=\/))\/?\s*(\d+)/i) || [];
    if (/trident/i.test(M[1])) {
        tem = /\brv[ :]+(\d+)/g.exec(ua) || [];
        return { name: 'IE', version: (tem[1] || '') };
    }
    if (M[1] === 'Chrome') {
        tem = ua.match(/\bOPR|Edge\/(\d+)/)
        if (tem != null) { return { name: 'Opera', version: tem[1] }; }
    }
    M = M[2] ? [M[1], M[2]] : [navigator.appName, navigator.appVersion, '-?'];
    if ((tem = ua.match(/version\/(\d+)/i)) != null) { M.splice(1, 1, tem[1]); }
    return {
        name: M[0],
        version: M[1]
    };
}

function dotNetDateToString(dotNetDate, defaultString) {
    if (!dotNetDate) return defaultString ? defaultString : "";

    var pattern = /Date\(([^)]+)\)/;
    return $.datepicker.formatDate("mm/dd/yy", new Date(parseFloat(pattern.exec(dotNetDate)[1])));
}

function dotNetDateToDate(dotNetDate, defaultDate) {
    if (!dotNetDate) return defaultDate ? defaultDate : null;

    var pattern = /Date\(([^)]+)\)/;
    return new Date(parseFloat(pattern.exec(dotNetDate)[1]));
}

function getQueryString(queryVar, url) {
    if (!url) {
        url = window.location.href;
    }
    queryVar = queryVar.replace(/[\[\]]/g, "\\$&");
    var regex = new RegExp("[?&]" + queryVar + "(=([^&#]*)|&|#|$)"),
        results = regex.exec(url);
    if (!results) return null;
    if (!results[2]) return '';
    return decodeURIComponent(results[2].replace(/\+/g, " "));
}

var nagDataModule = function () {
    var self = this;

    self.getNagsUserControls = function (filter, doneCallback) {
        asyncPostEx("GetNagsUserControls", JSON.stringify({ filter: filter }),
            function (msg) { doneCallback(msg.d) },
            function (xhr) { handleError(xhr) }
        );
    }

    self.getNagsUserReceives = function (filter, doneCallback) {
        asyncPostEx("GetNagsUserReceives", JSON.stringify({ filter: filter }),
            function (msg) { doneCallback(msg.d) },
            function (xhr) { handleError(xhr) }
        );
    }

    self.togglePlayPauseForCurrentUser = function (nagId, doneCallback) {
        asyncPostEx("TogglePlayPause",
            JSON.stringify({ nagId: nagId, loginId: null, allUsers: false }),
            function (msg) { doneCallback(msg.d) },
            function (xhr) { handleError(xhr) }
        );
    }

    self.togglePlayPauseAllRecipients = function (nagId, doneCallback) {
        asyncPostEx("TogglePlayPause",
            JSON.stringify({ nagId: nagId, loginId: null, allUsers: true }),
            function (msg) { doneCallback(msg.d) },
            function (xhr) { handleError(xhr) }
        );
    }

    self.togglePlayPauseForRecipient = function (nagId, recipientId, doneCallback) {
        asyncPostEx("TogglePlayPause",
            JSON.stringify({ nagId: nagId, loginId: recipientId, allUsers: false }),
            function (msg) { doneCallback(msg.d) },
            function (xhr) { handleError(xhr) }
        );
    }

    self.toggleDelete = function (nagId, forceValue, doneCallback) {
        asyncPostEx("ToggleDelete",
            JSON.stringify({ nagId: nagId, forceValue: forceValue }),
            function (msg) { doneCallback(msg.d) },
            function (xhr) { handleError(xhr) }
        );

    }

    self.getNagDetails = function (nagId, doneCallback) {
        asyncPostEx("GetNagDetails",
            JSON.stringify({ nagId: nagId }),
            function (msg) { doneCallback(msg.d) },
            function (xhr) { handleError(xhr) }
        );
    }

    self.getUserList = function () {
        syncPost("GetUserList");
        return syncPostResult;
    }

    self.saveNag = function (nag, doneCallback, errorCallback) {
        asyncPostEx("SaveNag",
            JSON.stringify({ nag: nag }),
            function (msg) { doneCallback(msg.d) },
            function (xhr) { (errorCallback ? errorCallback : handleError)(xhr) }
        );
    }

    self.removeCurrentRecipient = function (nagId, doneCallback, errorCallback) {
        asyncPostEx("RemoveCurrentRecipient",
            JSON.stringify({ nagId: nagId }),
            function (msg) { doneCallback(msg.d) },
            function (xhr) { (errorCallback ? errorCallback : handleError)(xhr) }
        );
    }

    self.snoozeCurrentRecipient = function (nagId, doneCallback, errorCallback) {
        asyncPostEx("SnoozeCurrentRecipient",
            JSON.stringify({ nagId: nagId, snoozeUntil: null }),
            function (msg) { doneCallback(msg.d) },
            function (xhr) { (errorCallback ? errorCallback : handleError)(xhr) }
        );
    }
}

var nagViewModule = function (dataModule) {
    var self = this;

    self.intervals = {
        "0": "(None)",
        "30": "30 Minutes",
        "60": "1 Hour",
        "120": "2 Hours",
        "240": "4 Hours",
        "1440": "Daily",
        "10082": "Weekly on Mondays",
        "10083": "Weekly on Tuesdays",
        "10084": "Weekly on Wednesdays",
        "10085": "Weekly on Thursdays",
        "10086": "Weekly on Fridays",
        "10087": "Weekly on Saturdays",
        "10081": "Weekly on Sundays"
    };

    self.monthlyFrequencies =
    {
        "1": "Each Month",
        "2": "Even Months",
        "-2": "Odd Months",
        "-1": "Every Nth Month"
    }

    self.daysOfWeek = {
        "127": "Day",
        "62": "Weekday",
        "65": "Weekend Day",
        "1": "Sunday",
        "2": "Monday",
        "4": "Tuesday",
        "8": "Wednesday",
        "16": "Thursday",
        "32": "Friday",
        "64": "Saturday"
    }

    self.translateInterval = function (interval) {
        var hours = Math.floor(interval / 60);
        return (hours > 0 ? hours + "h " : "")
            + (interval % 60) + "m";
    }

    self.translateDaysOfWeek = function (daysOfWeek) {
        var result = "";

        result += daysOfWeek & 1 ? "S" : "<span class='faded'>S</span>";
        result += daysOfWeek & 2 ? "M" : "<span class='faded'>M</span>";
        result += daysOfWeek & 4 ? "T" : "<span class='faded'>T</span>";
        result += daysOfWeek & 8 ? "W" : "<span class='faded'>W</span>";
        result += daysOfWeek & 16 ? "T" : "<span class='faded'>T</span>";
        result += daysOfWeek & 32 ? "F" : "<span class='faded'>F</span>";
        result += daysOfWeek & 64 ? "S" : "<span class='faded'>S</span>";

        return result;
    }

    self.translateDaysOfMonth = function (monthlySchedules) {
        var result = "";
        for (var i = 0; i < monthlySchedules.length; i++) {
            var schedule = monthlySchedules[i];
            var o = schedule.Ordinal;
            result += o == -1 ? "Last" : o + (Math.floor(o / 10) == 1
                    ? "th"
                    : o % 10 == 1
                    ? "st"
                    : o % 10 == 2
                    ? "nd"
                    : o % 10 == 3
                    ? "rd"
                    : "th"
            );
            result += " " + self.daysOfWeek[schedule.DaysOfWeek];
            if (schedule.MonthFrequency == -1) {
                var n = schedule.XMonths;
                result += " Of " + self.monthlyFrequencies[schedule.MonthFrequency].replace("Nth", n + (Math.floor(n / 10) == 1
                    ? "th"
                    : n % 10 == 1
                    ? "st"
                    : n % 10 == 2
                    ? "nd"
                    : n % 10 == 3
                    ? "rd"
                    : "th"));
            } else {
                result += " Of " + self.monthlyFrequencies[schedule.MonthFrequency];
            }

            if (i < monthlySchedules.length - 1)
                result += ",<br/>";
        }
        return result;
    }

    self.translateTimesOfDay = function (timesOfDay) {
        var timeStrings = timesOfDay ? timesOfDay.split("|") : [];
        if (timeStrings.length == 0) return "";
        var result = "";

        for (var i = 0; i < timeStrings.length; i++) {
            if (!timeStrings[i] || timeStrings[i] == "") continue;
            timeStrings[i] = $.timepicker.formatDate(new Date("1/1/2000 " + timeStrings[i]), "hh:mm TT");
            result += timeStrings[i] + ", ";
        }
        return result.slice(0, result.length - 2);
    }

    self.refreshPageData = function (checkActions) {
        var filter = $("#filter").val();

        if (filter == "") filter = null;

        dataModule.getNagsUserControls(filter, function (data) {
            self.bindUserControlsTable(data);
        });

        dataModule.getNagsUserReceives(filter, function (data) {
            self.bindUserReceivesTable(data);
            if (checkActions)
                self.checkQueryActions();
        });
    }

    self.checkQueryActions = function () {
        var id = getQueryString("nagId");
        if (id && id != "") {
            var disableFlag = getQueryString("pause");
            if (disableFlag && disableFlag != "") {
                //Remember this is a toggle; only "click" the button if the nag is not already paused
                $("#NagsIReceive table tbody tr td input[name='NagID'][value='" + id + "']")
                    .closest('td').find('button.playpause.pause').click();
            }

            var removeFlag = getQueryString("remove");
            if (removeFlag && removeFlag != "") {
                $("#NagsIReceive table tbody tr td input[name='NagID'][value='" + id + "']")
                    .closest('td').find('button.remove').click();
            }

            var snoozeFlag = getQueryString("snooze");
            if (snoozeFlag && snoozeFlag != "") {
                $("#NagsIReceive table tbody tr td input[name='NagID'][value='" + id + "']")
                    .closest('td').find('button.snooze').click();
            }
        }
    }

    self.bindUserControlsTable = function (data) {
        var table = $("#NagsIControl .tableDiv .displayTable tbody");
        var rowTemplate = $("#NagsIControl .tableDiv .rowTemplate tr");

        table.empty();

        for (var i = 0; i < data.length; i++) {
            var nag = data[i];
            var newRow = $(rowTemplate.html());

            newRow.find("[name='NagID']").val(nag.NagID);
            newRow.find("[name='Subject']").html(nag.Subject);
            newRow.find("[name='StartDate']").html(dotNetDateToString(nag.StartDate));
            newRow.find("[name='EndDate']").html(dotNetDateToString(nag.EndDate));
            newRow.find("[name='DaysOfWeek']").html(self.translateDaysOfWeek(nag.DaysOfWeek));
            newRow.find("[name='DaysOfMonth']").html(self.translateDaysOfMonth(nag.MonthlySchedules));
            newRow.find("[name='Interval']").html(nag.Interval ? self.translateInterval(nag.Interval) : "");
            newRow.find("[name='StartTime']").html((nag.Interval && nag.StartTime) ? $.timepicker.formatDate(dotNetDateToDate(nag.StartTime), "hh:mm TT") : "");
            newRow.find("[name='EndTime']").html((nag.Interval && nag.EndTime) ? $.timepicker.formatDate(dotNetDateToDate(nag.EndTime), "hh:mm TT") : "");
            newRow.find("[name='TimesOfDay']").html(nag.Interval ? "" : self.translateTimesOfDay(nag.TimesOfDay));
            newRow.find("[name='Recipients']").html(self.listRecipients(nag.Recipients));

            newRow.find("[name='NagID']").closest("td").find("button.playpause")
                .off("click").click(function () {
                    var nagId = $(this).closest("td").find("[name='NagID']").val();
                    dataModule.togglePlayPauseAllRecipients(nagId, function () {
                        self.refreshPageData();
                    });
                })
                .addClass(nag.IsPaused ? "play" : "pause")
                .html(nag.IsPaused ? "Turn On" : "Pause")
                .prop("title", nag.IsPaused ? "Turn Nag On (All Recipients)" : "Pause Nag (All Recipients)");

            newRow.find("[name='Status']").html(nag.IsPaused ? "Paused For All" : "Active");

            newRow.find("span").attr("title", nag.IsPaused ? "Nag Paused (All Users)" : "Nag Active");

            table.append($("<tr>")
                .addClass(nag.IsPaused ? "red" : "green").append(newRow));
        }

        table.find("[name='Recipients'] button.playpause")
            .off("click").click(function () {
                var nagId = $(this).closest("tr").find("[name='NagID']").val();
                var recipientId = $(this).closest("li").find("[name='RecipientID']").val();
                dataModule.togglePlayPauseForRecipient(nagId, recipientId, function () {
                    self.refreshPageData();
                });
            })
            .addClass("hidden");

        table.find("button.delete")
            .off("click").click(function () {
                if (!confirm("Are you sure you wish to delete this nag?"))
                    return;
                var nagId = $(this).closest("tr").find("[name='NagID']").val();
                dataModule.toggleDelete(nagId, null,
                    function () {
                        self.refreshPageData();
                        alert("Nag deleted!");
                    });
            });

        table.find("button.edit")
            .off("click").click(function () {
                var nagId = $(this).closest("tr").find("[name='NagID']").val();
                self.openNagDetails(nagId);
            });

        $("#NagsIControl").find("button.new")
            .off("click").click(function () {
                self.openNagDetails(0);
            });
    }

    self.bindUserReceivesTable = function (data) {
        var table = $("#NagsIReceive .tableDiv .displayTable tbody");
        var rowTemplate = $("#NagsIReceive .tableDiv .rowTemplate tr");

        table.empty();
        for (var i = 0; i < data.length; i++) {
            var nag = data[i];
            var from = "";
            var snoozeUntil = dotNetDateToDate(nag.Recipients[0].SnoozeUntil);
            var isSnoozed = snoozeUntil > Date.now();
            var newRow = $(rowTemplate.html());
            newRow.find("[name='NagID']").val(nag.NagID);
            newRow.find("[name='From']").html(nag.Controller.FullName);
            newRow.find("[name='Subject']").html(nag.Subject);
            newRow.find("[name='StartDate']").html(dotNetDateToString(nag.StartDate));
            newRow.find("[name='EndDate']").html(dotNetDateToString(nag.EndDate));
            newRow.find("[name='DaysOfWeek']").html(self.translateDaysOfWeek(nag.DaysOfWeek));
            newRow.find("[name='DaysOfMonth']").html(self.translateDaysOfMonth(nag.MonthlySchedules));
            newRow.find("[name='Interval']").html(nag.Interval ? self.translateInterval(nag.Interval) : "");
            newRow.find("[name='StartTime']").html((nag.Interval && nag.StartTime) ? $.timepicker.formatDate(dotNetDateToDate(nag.StartTime), "hh:mm TT") : "");
            newRow.find("[name='EndTime']").html((nag.Interval && nag.EndTime) ? $.timepicker.formatDate(dotNetDateToDate(nag.EndTime), "hh:mm TT") : "");
            newRow.find("[name='TimesOfDay']").html(nag.Interval ? "" : self.translateTimesOfDay(nag.TimesOfDay));
            newRow.find("button.playpause")
                .off("click").click(function () {
                    var nagId = $(this).closest("td").find("[name='NagID']").val();
                    dataModule.togglePlayPauseForCurrentUser(nagId, function () {
                        self.refreshPageData();
                    });
                })
                .addClass(nag.Recipients[0].IsPaused || isSnoozed ? "play" : "pause")
                .html(nag.Recipients[0].IsPaused || isSnoozed ? "Turn On" : "Pause")
                .prop("title", nag.Recipients[0].IsPaused || isSnoozed ? "Turn Nag On (Just Me)" : "Pause Nag (Just Me)");

            if (isSnoozed || nag.isPaused || nag.Recipients[0].IsPaused)
                newRow.find("button.snooze").addClass("gray").off("click");

            newRow.find("[name='Status']").html(nag.IsPaused ? "Paused For All" : nag.Recipients[0].IsPaused ? "Paused For Me" : isSnoozed ? "Snoozed Until " + dotNetDateToString(nag.Recipients[0].SnoozeUntil) : "Active");
            newRow.find("span").attr("title", nag.IsPaused ? "Nag Paused (All Users)" : nag.Recipients[0].IsPaused ? "Nag Paused (Just Me)" : isSnoozed ? "Nag Snoozed" : "Nag Active");

            table.append($("<tr>")
                .addClass(nag.IsPaused ? "gray" : nag.Recipients[0].IsPaused ? "red" : isSnoozed ? "blue" : "green")
                .append(newRow));
        }

        table.find("button.remove")
            .off("click").click(function () {
                if (!confirm("Are you sure you wish to remove yourself from this nag's recipient list? Other users will not be affected."))
                    return;
                var nagId = $(this).closest("tr").find("[name='NagID']").val();
                dataModule.removeCurrentRecipient(nagId,
                    function () {
                        self.refreshPageData();
                        alert("Recipient removed!");
                    });
            });

        table.find("button.snooze:not(.gray)")
            .off("click")
            .click(function () {
                var nagId = $(this).closest("tr").find("[name='NagID']").val();
                dataModule.snoozeCurrentRecipient(nagId,
                    function () {
                        self.refreshPageData();
                    });
            });

        //shouldn't need this anymore
        table.find("button.gray")
            .off("click");
    }

    self.listRecipients = function (recipients) {
        var html = "";
        for (var i = 0; i < recipients.length; i++) {
            var recipient = recipients[i];
            var paused = recipient.IsPaused;
            html += "<li class='nobullet " + (paused ? "red" : "green")
                                        + "' title='" + (paused ? "User Paused" : "User Active")
                                        + "'>";
            html += "<input type='hidden' name='RecipientID' value='" + recipient.RecipientID + "'/>";
            html += "<button class='playpause " + (paused ? "play" : "pause") + "' title='Turn Nag " + (paused ? "On" : "Off") + " (This Recipient Only)'>Turn " + (paused ? "On" : "Off") + "</button>";
            html += recipient.User.FullName;
            html += " (" + (paused ? "Paused" : "Active") + ")";
            html += "</li>";
        }

        return html;
    };

    self.intervalChanging = false;

    self.openNagDetails = function (nagId) {
        dataModule.getNagDetails(nagId, function (nag) {
            var dialogSelector = $("#nagDetailDialog");

            //Set up user select lists
            var users = dataModule.getUserList();
            var userOptions = "<option value=''>(Select A User)</option>";
            for (i = 0; i < users.length; i++) {
                var user = users[i];
                userOptions += "<option value='" + user.LoginID + "'>"
                    + user.FullName + "</option>";
            }

            var frequencyOptions = "";
            for (var option in self.monthlyFrequencies) {
                if (!self.monthlyFrequencies.hasOwnProperty(option)) continue;
                var frequency = self.monthlyFrequencies[option];
                frequencyOptions += "<option value='" + option + "'>"
                    + frequency + "</option>";
            }

            var daysOptions = "";
            for (var option in self.daysOfWeek) {
                if (!self.daysOfWeek.hasOwnProperty(option)) continue;
                var day = self.daysOfWeek[option];
                daysOptions += "<option value='" + option + "'>"
                    + day + "</option>";
            }

            var ordinalOptions = "";
            for (var i = 1; i < 31; i++)
                ordinalOptions += "<option value='" + i + "'>" + i +
                    (Math.floor(i / 10) == 1
                        ? "th"
                        : i % 10 == 1
                            ? "st"
                            : i % 10 == 2
                            ? "nd"
                                : i % 10 == 3
                                ? "rd"
                                : "th"
                    ) + "</option>";
            ordinalOptions += "<option value='-1'>Last</option>";

            //Bind fields
            dialogSelector.find("#NagID").val(nag.NagID);
            dialogSelector.find("#NagSubject").val(nag.Subject);
            dialogSelector.find("#NagBodyText").val(nag.BodyText);
            dialogSelector.find("#NagHour").val(nag.Hour);
            var startDate = dotNetDateToDate(nag.StartDate);
            if (startDate)
                dialogSelector.find("#NagStartDate").val($.datepicker.formatDate("mm/dd/yy", startDate));
            else
                dialogSelector.find("#NagStartDate").val(null);
            var endDate = dotNetDateToDate(nag.EndDate);
            if (endDate)
                dialogSelector.find("#NagEndDate").val($.datepicker.formatDate("mm/dd/yy", endDate));
            else
                dialogSelector.find("#NagEndDate").val(null);

            var schedTable = dialogSelector.find("#NagSchedTable tbody");
            schedTable.empty();

            if (nag.MonthlySchedules.length > 0) {

                for (i = 0; i < nag.MonthlySchedules.length; i++) {
                    var schedule = nag.MonthlySchedules[i];
                    var schedRow = $("<tr>").append(dialogSelector.find("#nagSchedTemplate tr").html());

                    schedRow.find(".ordinalSelect")
                        .html(ordinalOptions)
                        .val(schedule.Ordinal);

                    schedRow.find(".daySelect")
                        .html(daysOptions)
                        .val(schedule.DaysOfWeek);

                    schedRow.find(".monthSelect")
                        .html(frequencyOptions)
                        .val(schedule.MonthFrequency)
                    .off("change")
                    .on("change", function () {
                        var span = $(this).closest("td").find("span.nMonth");
                        if ($(this).val() != -1)
                            span.hide();
                        else {
                            span.show();
                            span.find("input").val("1");
                        }
                    });

                    if (schedule.MonthFrequency != -1)
                        schedRow.find("span.nMonth").hide();
                    else {
                        schedRow.find("input.nMonthInput").val(schedule.XMonths);
                    }

                    schedRow.find("input[type='hidden']")
                        .attr("id", "schedRow" + (i + 1))
                        .val(schedule.ScheduleID);

                    schedTable.append(schedRow);
                }

                dialogSelector.find("#NagMonthlySchedule").prop("checked", true);
                dialogSelector.find("tr.daysOfWeekRow").hide();
                dialogSelector.find("tr.monthlySchedRow").show();
            } else { //if there are no monthly schedule rules, it's weekly or better
                dialogSelector.find("#NagSunday").prop("checked", nag.DaysOfWeek & 1);
                dialogSelector.find("#NagMonday").prop("checked", nag.DaysOfWeek & 2);
                dialogSelector.find("#NagTuesday").prop("checked", nag.DaysOfWeek & 4);
                dialogSelector.find("#NagWednesday").prop("checked", nag.DaysOfWeek & 8);
                dialogSelector.find("#NagThursday").prop("checked", nag.DaysOfWeek & 16);
                dialogSelector.find("#NagFriday").prop("checked", nag.DaysOfWeek & 32);
                dialogSelector.find("#NagSaturday").prop("checked", nag.DaysOfWeek & 64);

                dialogSelector.find("#NagWeeklySchedule").prop("checked", true);
                dialogSelector.find("tr.daysOfWeekRow").show();
                dialogSelector.find("tr.monthlySchedRow").hide();
            }

            var timesTable = dialogSelector.find("#NagTimeTable tbody");
            timesTable.empty();

            if (nag.Interval) //not undefined, null or zero
            {
                dialogSelector.find("#NagInterval").val(nag.Interval);

                var startTime = dotNetDateToDate(nag.StartTime);
                if (startTime)
                    dialogSelector.find("#NagStartTime")
                        .val($.timepicker.formatDate(startTime,
                            getBrowser().name == "IE" ? "hh:mm TT" : "HH:mm"));
                else
                    dialogSelector.find("#NagStartTime").val(null);
                var endTime = dotNetDateToDate(nag.EndTime);
                if (endTime)
                    dialogSelector.find("#NagEndTime")
                        .val($.timepicker.formatDate(endTime,
                        getBrowser().name == "IE" ? "hh:mm TT" : "HH:mm"));
                else
                    dialogSelector.find("#NagEndTime").val(null);

                dialogSelector.find("#NagScheduleInterval").prop("checked", true);
                dialogSelector.find("tr.intervalRow").show();
                dialogSelector.find("tr.specificRow").hide();
            } else {
                var times = (nag.TimesOfDay ? nag.TimesOfDay : "").split("|");

                for (i = 0; i < times.length; i++) {
                    var timeString = times[i];
                    if (!timeString || timeString == "") continue;

                    var timeRow = $("<tr>").append(dialogSelector.find("#nagTimeTemplate tr").html());

                    var timeDate = new Date("1/1/2000 " + timeString);
                    timeString = $.timepicker.formatDate(timeDate,
                        getBrowser().name == "IE" ? "hh:mm TT" : "HH:mm");

                    timeRow.find("input[type='time']")
                        .attr("id", "timeRow" + (i + 1))
                        .val(timeString);
                    timesTable.append(timeRow);
                }

                dialogSelector.find("#NagScheduleSpecific").prop("checked", true);
                dialogSelector.find("tr.intervalRow").hide();
                dialogSelector.find("tr.specificRow").show();
            }

            dialogSelector.find("#NagController").html(userOptions).val(nag.ControllerID);

            //Recipients table
            var recipTable = dialogSelector.find("#NagRecipientTable tbody");
            recipTable.empty();

            for (i = 0; i < nag.Recipients.length; i++) {
                var recipient = nag.Recipients[i];
                var recipientRow = $("<tr>").append(dialogSelector.find("#nagUserTemplate tr").html());
                recipientRow.find("[name='Recipient']").html(userOptions);
                recipientRow.find("[name='Recipient']").val(recipient.RecipientID);
                recipientRow.find("[name='Active']")
                    .prop("checked", !recipient.IsPaused)
                    .prop("disabled", nagId.NagID != 0);
                recipTable.append(recipientRow);
            }

            //Event handlers
            dialogSelector.find("#NagInterval")
                .off("change").on("change", function () {
                    if (self.intervalChanging) return;
                    try {
                        self.intervalChanging = true;

                        var currentValue = $(this).val();
                        if (currentValue % 5 != 0)
                            $(this).val(parseInt(currentValue) + (5 - (currentValue % 5)));
                    } finally {
                        self.intervalChanging = false;
                    }
                });

            //Remove rows
            dialogSelector.find(".dialogListTable tbody button.remove")
                .off("click").on("click", function () {
                    $(this).closest("tr").remove();
                });

            //Day Of Week buttons
            dialogSelector.find("#DaysOfWeekClear")
                .off("click").click(function () {
                    $(this).closest("tr").next("tr").find("input[type='checkbox']")
                        .prop("checked", false);
                });
            dialogSelector.find("#DaysOfWeekAll")
                .off("click").click(function () {
                    $(this).closest("tr").next("tr").find("input[type='checkbox']")
                        .prop("checked", true);
                });
            dialogSelector.find("#DaysOfWeekWeekdays")
                .off("click").click(function () {
                    $(this).closest("tr").next("tr")
                        .find("input[type='checkbox']:not(#NagSunday, #NagSaturday)")
                        .prop("checked", true);
                    $("#NagSunday").prop("checked", false);
                    $("#NagSaturday").prop("checked", false);
                });
            dialogSelector.find("#DaysOfWeekMWF")
                .off("click").click(function () {
                    $("#NagSunday").prop("checked", false);
                    $("#NagMonday").prop("checked", true);
                    $("#NagTuesday").prop("checked", false);
                    $("#NagWednesday").prop("checked", true);
                    $("#NagThursday").prop("checked", false);
                    $("#NagFriday").prop("checked", true);
                    $("#NagSaturday").prop("checked", false);
                });
            dialogSelector.find("#DaysOfWeekTuTh")
                .off("click").click(function () {
                    $("#NagSunday").prop("checked", false);
                    $("#NagMonday").prop("checked", false);
                    $("#NagTuesday").prop("checked", true);
                    $("#NagWednesday").prop("checked", false);
                    $("#NagThursday").prop("checked", true);
                    $("#NagFriday").prop("checked", false);
                    $("#NagSaturday").prop("checked", false);
                });

            //Add Monthly Schedule
            dialogSelector.find("#NagSchedTable tfoot button.add")
                .off("click").on("click", function () {
                    var table = $(this).closest("table").find("tbody");
                    var lastRow = table.find("input[type='hidden']").last();
                    var lastRowId = lastRow.length == 0 ? 0 : parseInt(lastRow.attr("id").slice(8));
                    var schedRow = $("<tr>").append(dialogSelector.find("#nagSchedTemplate tr").html());
                    schedRow.find(".ordinalSelect")
                        .html(ordinalOptions)
                        .val("1");

                    schedRow.find(".daySelect")
                        .html(daysOptions)
                        .val("127");

                    schedRow.find(".monthSelect")
                        .html(frequencyOptions)
                        .val("1")
                        .off("change")
                        .on("change", function () {
                            var span = $(this).closest("td").find("span.nMonth");
                            if ($(this).val() != -1)
                                span.hide();
                            else {
                                span.show();
                                span.find("input").val("1");
                            }
                        });

                    schedRow.find("input[type='hidden']")
                        .attr("id", "schedRow" + (lastRowId + 1))
                        .val("0");

                    schedRow.find("span.nMonth").hide();

                    table.append(schedRow);
                    setTimeout(function () { table.closest("table").find("button.add")[0].scrollIntoView() }, 100);
                    schedRow.find("button.remove")
                        .off("click").on("click", function () {
                            $(this).closest("tr").remove();
                        });
                });

            //Add Time
            dialogSelector.find("#NagTimeTable tfoot button.add")
                .off("click").on("click", function () {
                    var table = $(this).closest("table").find("tbody");
                    var lastRow = table.find("input[type='time']").last();
                    var lastRowId = lastRow.length == 0 ? 0 : parseInt(lastRow.attr("id").slice(7));
                    var timeRow = $("<tr>").append(dialogSelector.find("#nagTimeTemplate tr").html());
                    table.append(timeRow);
                    setTimeout(function () { table.closest("table").find("button.add")[0].scrollIntoView() }, 100);
                    timeRow.find("button.remove")
                        .off("click").on("click", function () {
                            $(this).closest("tr").remove();
                        });
                    timeRow.find("input[type='time']")
                        .attr("id", "timeRow" + (lastRowId + 1))
                        .timepicker({
                            showPeriod: true,
                            showLeadingZero: true
                        });
                });

            //Add Recipient
            dialogSelector.find("#NagRecipientTable tfoot button.add")
                .off("click").on("click", function () {
                    var table = $(this).closest("table").find("tbody");
                    var recipientRow = $("<tr>").append(dialogSelector.find("#nagUserTemplate tr").html());
                    table.append(recipientRow);
                    setTimeout(function () { table.closest("table").find("button.add")[0].scrollIntoView() }, 100);
                    recipientRow.find("[name='Recipient']").html("<option value=''>(Select A Recipient)</option>" + userOptions)
                        .off("change").on("change", function () {
                            $(this).find("option[value='']").remove();
                        });
                    recipientRow.find("button.remove")
                        .off("click").on("click", function () {
                            $(this).closest("tr").remove();
                        });
                });

            dialogSelector.find("button.save").off("click").click(function () {
                self.saveNag(dialogSelector);
            });

            dialogSelector.find("button.delete").off("click").click(function () {
                if (confirm("Are you sure you wish to delete this nag?"))
                    dataModule.toggleDelete(dialogSelector.find("#NagID").val(), null,
                        function () {
                            self.refreshPageData();
                            alert("Nag deleted!");
                            dialogSelector.dialog("close");
                        });
            });

            //Chrome has built-in datepickers, but we're an IE shop...
            //if (getBrowser().name == "IE") {
                dialogSelector.find("input[type='date']").datepicker();
                dialogSelector.find(".intervalRow input[type='time']").timepicker({
                    showPeriod: true,
                    showLeadingZero: true
                });
                dialogSelector.find("#NagTimeTable input[type='time']").timepicker({
                    showPeriod: true,
                    showLeadingZero: true
                });
            //}

            //finally, hide/show the various schedule fields based on schedule type
            dialogSelector.find('input[type="radio"][name="nagScheduleType"]')
                .off("change").change(function () {
                    if ($("#NagScheduleInterval").prop("checked")) {
                        dialogSelector.find("tr.intervalRow").show();
                        dialogSelector.find("tr.specificRow").hide();
                    } else {
                        dialogSelector.find("tr.intervalRow").hide();
                        dialogSelector.find("tr.specificRow").show();
                    }
                });

            dialogSelector.find('input[type="radio"][name="nagOnDays"]')
                .off("change").change(function () {
                    if ($("#NagMonthlySchedule").prop("checked")) {
                        dialogSelector.find("tr.monthlySchedRow").show();
                        dialogSelector.find("tr.daysOfWeekRow").hide();
                    } else {
                        dialogSelector.find("tr.monthlySchedRow").hide();
                        dialogSelector.find("tr.daysOfWeekRow").show();
                    }
                });

            dialogSelector.dialog({
                autoOpen: false,
                show: 250,
                hide: 250,
                width: "auto",
                //maxHeight: 800,
                position: { my: "center top", at: "center top+50", of: $(window) },
                resizable: false,
                draggable: true,
                closeText: "Close",
                beforeClose: function (e, ui) {
                    if (!self.saved)
                        return confirm("You may have unsaved changes. Are you sure you wish to close this dialog?");
                }
            });
            $(".ui-dialog-titlebar-close").addClass("red");

            self.saved = false;
            dialogSelector.dialog("open");
        });
    }

    self.setTimeFieldVisibility = function (dialogSelector) {

        if (dialogSelector.find("#NagInterval").val() < 1000) {
            dialogSelector.find("#NagHour").closest("tr").hide();
            dialogSelector.find("#NagStartTime").show();
            dialogSelector.find("#NagEndTime").show();
        } else {
            dialogSelector.find("#NagHour").closest("tr").show();
            dialogSelector.find("#NagStartTime").hide();
            dialogSelector.find("#NagEndTime").hide();
        }
    }

    self.saveNag = function (dialogSelector) {
        var nag = self.unbindNagDialog(dialogSelector);

        dataModule.saveNag(nag, function () {
            self.refreshPageData();
            alert("Save successful!");
            self.saved = true;
            dialogSelector.dialog("close");
        });
    };

    self.unbindNagDialog = function (dialogSelector) {
        var nag = {};

        nag.NagID = dialogSelector.find("#NagID").val();
        nag.Subject = dialogSelector.find("#NagSubject").val();
        nag.BodyText = dialogSelector.find("#NagBodyText").val();
        nag.ControllerID = dialogSelector.find("#NagController").val();
        nag.StartDate = dialogSelector.find("#NagStartDate").val();
        nag.EndDate = dialogSelector.find("#NagEndDate").val();

        var daysOfWeek = 0;
        nag.MonthlySchedules = [];
        if (dialogSelector.find("#NagWeeklySchedule").prop("checked")) {
            daysOfWeek = daysOfWeek | dialogSelector.find("#NagSunday").prop("checked");
            daysOfWeek = daysOfWeek | (dialogSelector.find("#NagMonday").prop("checked") << 1);
            daysOfWeek = daysOfWeek | (dialogSelector.find("#NagTuesday").prop("checked") << 2);
            daysOfWeek = daysOfWeek | (dialogSelector.find("#NagWednesday").prop("checked") << 3);
            daysOfWeek = daysOfWeek | (dialogSelector.find("#NagThursday").prop("checked") << 4);
            daysOfWeek = daysOfWeek | (dialogSelector.find("#NagFriday").prop("checked") << 5);
            daysOfWeek = daysOfWeek | (dialogSelector.find("#NagSaturday").prop("checked") << 6);
        } else {
            var schedRows = dialogSelector.find("#NagSchedTable tbody tr");
            for (var i = 0; i < schedRows.length; i++) {
                var schedRow = $(schedRows[i]);
                var schedule = {};
                schedule.ScheduleID = parseInt(schedRow.find("input[type='hidden']").val());
                schedule.Ordinal = parseInt(schedRow.find("select.ordinalSelect").val());
                schedule.DaysOfWeek = parseInt(schedRow.find("select.daySelect").val());
                schedule.MonthFrequency = parseInt(schedRow.find("select.monthSelect").val());
                schedule.XMonths = parseInt(schedRow.find("input.nMonthInput").val() == "" ? "0" : schedRow.find("input.nMonthInput").val());

                nag.MonthlySchedules.push(schedule);
            }
        }

        nag.DaysOfWeek = daysOfWeek;

        if (dialogSelector.find("#NagScheduleInterval").prop("checked")) {
            nag.Interval = dialogSelector.find("#NagInterval").val();
            var startTime = dialogSelector.find("#NagStartTime").val();
            if (startTime && startTime != "")
                nag.StartTime = new Date("1/1/2000 " + startTime);
            var endTime = dialogSelector.find("#NagEndTime").val();
            if (endTime && endTime != "")
                nag.EndTime = new Date("1/1/2000 " + endTime);
        } else {
            var timeRows = dialogSelector.find("#NagTimeTable tbody tr");
            var allTimes = "";
            for (i = 0; i < timeRows.length; i++) {
                var timeRow = timeRows[i];
                var timeString = $(timeRow).find("input[type='time']").val();
                if (!timeString || timeString == "") continue;
                var theTime = new Date("1/1/2000 " + timeString);
                timeString = $.timepicker.formatDate(theTime, "HH:mm");
                allTimes += timeString + "|";
            }
            nag.TimesOfDay = allTimes;
        }


        //Recipients table
        nag.Recipients = [];
        var rows = dialogSelector.find("#NagRecipientTable tbody tr");
        for (var i = 0; i < rows.length; i++) {
            var recipient = {};
            var recipientRow = $(rows[i]);
            recipient.RecipientID = recipientRow.find("[name='Recipient']").val();
            if (!recipient.RecipientID || recipient.RecipientID == "") continue;
            nag.Recipients.push(recipient);
        }

        return nag;
    }
}

$(document).ready(function () {
    window.dataModule = new nagDataModule();
    window.viewModule = new nagViewModule(dataModule);

    var id = getQueryString("nagId");

    if (id && id != "") {
        $("#filter").val("#" + id);
        $("button.showAll")
            .off("click")
            .on("click", function () {
                $("#filter").val("");
                $("button.showAll").addClass("hidden");
                viewModule.refreshPageData();
            })
            .removeClass("hidden");
    }

    viewModule.refreshPageData(true); //checks whether to turn off the selected nag

    $(document).tooltip({
        items: ":not(.dialogContent)", //prevents the dialog title showing up when mousing over the dialog div
        show: { effect: "fade", duration: 250, delay: 750 },
        hide: 250,
        content: function () {
            $(".ui-tooltip").remove();
            return $(this).prop("title");
        },
        position: { my: "left bottom", at: "right top" }
    });
})
/* Copyright © 2024 Renegade Swish, LLC */

