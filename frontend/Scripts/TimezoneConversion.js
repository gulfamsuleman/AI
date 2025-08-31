
var availableTimeZones = null;
var availableTimesGlobal = null;
var numberOfTasks = 0;
var selectedData = [];
var index = 0;
$(document).ready(function () {

    $("#progressBar").progressbar({
        value: 0
    });
    renderHoursBox();
    getAvailableTimezones();

    resize();
    window.onresize = resize;

    $("#progress-dialog").dialog({
        autoOpen: false,
        closeOnEscape: false,
        draggable: false,
        resizable: false,
        modal: true,
        dialogClass: "no-close",
        open: function () {
            $("#progressBar").progressbar({
                value: false
            });
        }
    });
});


function resize() {
    $("#site-main").height(($(window).height() - $("#site-nav").outerHeight() - $("#site-footer").outerHeight() - 4) + "px");
    $("#site-main").css("margin-top", ($("#site-nav").outerHeight()) + "px");
}

function buildTimezoneConversionTable() {

    $.ajax({
        url: "/DataService.asmx/GetExistingTasks",
        type: "POST",
        data: JSON.stringify({
            userId: $("#userId").val(),
            userName: $("#userName").val()
        }),
        contentType: "application/json",
        dataType: "json",
        async: "true",
        success: function (data) {
            let existingTable = '';

            existingTable = `<table id="existingTaskTable"></table>`;

            $("#existingTaskContainer").html(existingTable);
            var parsedData = JSON.parse(data.d);

            var existingData = new DataTable("#existingTaskTable", {
                dom: '<"top"B>rt<"bottom"ip><"clear">',
                responsive: true,
                pageLength: 1000,
                order: [[1, "asc"]],
                initComplete: function () {
                    var selectBox = `<select id="timePicker-1" style="margin: 10px;">`;
                    for (let [key, value] of availableTimesGlobal) {
                        if (value == "07:00 PM") {
                            selectBox += `<option value="${value}" selected>
                                                ${value}
                                              </option>`;
                        } else {
                            selectBox += `<option value="${value}">
                                                ${value}
                                              </option>`;
                        }
                    }
                    selectBox += `</select>`;
                    var timezonesBox = renderTimezoneBoxes(1, availableTimeZones);
                    $("#existingTaskTable_wrapper .top")
                        .append(`
                                <div class="top-dropdowns">
                                <span style="margin-left: 5px"><b>Bulk Update</b></span>
                                       ${timezonesBox}
                                </div>
                                <div class="top-dropdowns">
                                       <button id="convertAllTimezones" style="margin: 5px;" class="conversion-btn">Convert All Selected Timezones</button>
                                </div>`
                        );
                },
                columnDefs: [
                    { targets: [0, 3, 4], orderable: false }
                ],
                responsive: true,
                data: parsedData,
                columns: [
                    {
                        title: `<input type="checkbox" id="selectAllCheck" />`,
                        data: null,
                        render: function (data) {

                            return `<input type="checkbox" id="${data.ChecklistId}" value="${data.ChecklistId}" />`;
                        }
                    },
                    { title: "Task", data: "ChecklistName" },
                    {
                        title: "Next Due Date",
                        data: null,
                        render: function (data) {
                            if (data.DueTime === null)
                                return "--";
                            return `${moment(data.DueTime).format("MM/DD/YYYY hh:mm A")} ${data.Timezone}`;
                        }
                    },
                    {
                        title: "Change Timezone To",
                        data: null,
                        render: function (data) {
                            return renderTimezoneBoxes(data.objId, availableTimeZones, data.Timezone);
                        }
                    },
                    {
                        title: "Actions",
                        data: null,
                        render: function () {
                            return `<button class="conversion-btn">Change</button> `;
                        }
                    },
                    { title: "Recurring?", data: "IsRecurring", visible: false },
                    { title: "Instance ID", data: "objId", visible: false }
                ]

            });

            $('#convertAllTimezones').on('click', function (e) {
                selectedData = [];
                var newLocation = $("#zonePicker-1").val();
                $('#existingTaskTable tbody input[type="checkbox"]:checked').each(function () {
                    var data = existingData.row($(this).closest('tr')).data();
                    selectedData.push(
                        {
                            InstanceId: data.objId,
                            CurrentLocation: data.Timezone,
                            CurrentTimeStamp: data.DueTime,
                            NewLocation: newLocation,
                            IsRecurring: data.IsRecurring
                        }
                    );
                });
                convertTasks(selectedData);
            });

            existingData.on('click', 'button', function (e) {
                selectedData = [];

                var row = $(this).closest('tr');
                var data = existingData.row(row).data();
                selectedData.push(
                    {
                        InstanceId: data.objId,
                        CurrentLocation: data.Timezone,
                        CurrentTimeStamp: data.DueTime,
                        NewLocation: $(`#zonePicker-${data.objId}`, row).val(),
                        IsRecurring: data.IsRecurring
                    }
                );
                convertTasks(selectedData);
            });

            $("#selectAllCheck").on('click', function () {
                var isChecked = $("#selectAllCheck").is(':checked');
                if (isChecked) {
                    $('#existingTaskTable tbody input[type="checkbox"]').each(function () {
                        $(this).prop('checked', true);
                    });
                } else {
                    $('#existingTaskTable tbody input[type="checkbox"]').each(function () {
                        $(this).prop('checked', false);
                    });
                }
            });

        },
        error: function (error) {
            $("#existingTaskTable").html("I said we don't have any data!!!");
        }

    });
}
function convertTasks(data) {

    $("#progressTitle").html(`<span style="color: grey;">Converting Timezones. Please Wait...</span>`);
    $("#progress-dialog").dialog("open");
    $("#progressBar").progressbar("option", "value", 0);
    numberOfTasks = data.length;
    $("#progressBar").progressbar("option", "max", numberOfTasks);
    if (data.length > 0) {
        var item = data.pop();
        index = index + 1;
        convertTime(item, index);
    }
}
function getAvailableTimezones() {


    $.ajax({
        url: "/DataService.asmx/GetAvailableTimezones",
        type: "POST",
        contentType: "application/json",
        dataType: "json",
        async: "false",
        success: function (data) {
            availableTimeZones = JSON.parse(data.d);
            buildTimezoneConversionTable();
        },
        error: function (error) {

        }

    });
}

function renderTimezoneBoxes(objId, availableTimeZones, currentTimezone = null) {
    if (availableTimeZones) {
        var select = `<select style="margin: 10px;" id="zonePicker-${objId}"> `;
        availableTimeZones.forEach((tz, index) => {

            if (index <= 10) {
                if (currentTimezone) {
                    if (tz === currentTimezone)
                        select = select + `<option class="common-value" value ="${tz}" selected>${tz}</option> `;
                    else
                        select = select + `<option class="common-value" value="${tz}">${tz}</option> `;
                }
                else
                    select = select + `<option class="common-value" value="${tz}">${tz}</option> `;

            }
            else if (index == 11)
                select = select + `<option class="common-value" disabled>----</option>`;
            else {
                if (currentTimezone) {
                    if (tz === currentTimezone)
                        select = select + `<option value = "${tz}" selected>${tz}</option>`;
                    else
                        select = select + `<option value="${tz}">${tz}</option>`;
                }
                else
                    select = select + `<option value="${tz}">${tz}</option>`;
            }
        });
        select = select + `</select> `;
        return select;
    } else
        return `<span> Bro...</span> `;
}

function renderHoursBox() {

    var availableTimes = new Map();
    var baseDate = new Date(1900, 1, 1, 0, 0, 0);
    for (let i = 0.0; i < 24.0; i += .5) {
        var hoursToAdd = i * 60 * 60 * 1000;
        var tempTime = baseDate.getTime() + hoursToAdd;
        availableTimes.set(i, moment(tempTime).format("hh:mm A"));
    }
    availableTimesGlobal = availableTimes;

}

function convertTime(item, index) {


    $("#progressTitle").html(`<span style="color: grey;">Converting Timezones. Please Wait... (${index} of ${numberOfTasks})</span>`);
    $("#progressBar").progressbar("option", "value", index);
    $.ajax({
        url: "/DataService.asmx/ConvertTimezonesOfAllSelected",
        type: "POST",
        contentType: "application/json",
        dataType: "json",
        async: "false",
        data: JSON.stringify({
            request: item
        }),
        success: function (data) {

            if (selectedData.length > 0) {
                $("#progressTitle").html(`<span style="color: grey;">Converting Timezones. Please Wait... (${index} of ${numberOfTasks})</span>`);
                $("#progressBar").progressbar("option", "value", index);
                var nextItem = selectedData.pop();
                convertTime(nextItem, index + 1);
            } else {
                $("#progressTitle").html(`<span style="color:green;">Conversion Success!</span>`);
                setTimeout(function () {
                    $("#progress-dialog").dialog("close");
                }, 1000);

                getAvailableTimezones();
            }
        },
        error: function (error) {
            setTimeout(function () {
                $("#progressTitle").html(`<span style="color:red;">Conversion error!</span>`);
            }, 1000);

            $("#progress-dialog").dialog("close");
        }
    });

}
/* Copyright © 2024 Renegade Swish, LLC */

