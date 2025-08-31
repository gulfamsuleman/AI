$().ready(function () {
    if (typeof slider === 'undefined')
        $('#txtMeetingStartTime').timepicker({ 'minTime': '12:00am' });

    $("#btnSaveSchedule").click(SaveSchedule);
    $.ajax({
        url: "../DataService.asmx/GetEmployeesForSupervisor",
        type: "POST",
        data: {},
        async: false,
        contentType: "application/json",
        success: function (data) {
            
            $("#ddlPriorityEmployees").html(data.d);
            //$("#tblPriorityListSchedules tbody").html("");
            //$("#tblPriorityListSchedules tbody").append("<tr><th>Deadline Day</th><th>Report Day</th><th>Time</th></tr>");
            //for (var i = 0; i < data.d.length; i++) {

            //    $("#tblPriorityListSchedules tbody").append("<tr><td>" + data.d[i].DaysOfWeek + "</td><td>" + data.d[i].ReportDay + "</td><td>" + data.d[i].TimesOfDay + "</td></tr>");
            //}
        }
    });

    $.ajax({
        url: "../DataService.asmx/GetPrioritiesListScheduleForEmployee",
        type: "POST",
        data: JSON.stringify({
            employeeId: $("#ddlPriorityEmployees option:selected").val()

        }),
        contentType: "application/json",
        success: function (data) {
            PopulateSchedule(data);
            //$("#tblPriorityListSchedules tbody").html("");
            //$("#tblPriorityListSchedules tbody").append("<tr><th>Deadline Day</th><th>Report Day</th><th>Time</th></tr>");
            //for (var i = 0; i < data.d.length; i++) {
               
            //    $("#tblPriorityListSchedules tbody").append("<tr><td>" + data.d[i].DaysOfWeek + "</td><td>" + data.d[i].ReportDay + "</td><td>" + data.d[i].TimesOfDay + "</td></tr>");
            //}
        }
    });

   
});



//var schedulePrioritiesModule = (function () {
//   // var self = {};
//    //var sendEmailButton = $("[data-role='send-email']");
//    //var panel = $("#email-priority-list-panel");
//   // var modal = window.modalModule;

//    $().ready(function () {
//        $('#txtMeetingStartTime').timepicker({ 'minTime': '3:00pm' });
//    });

  
   

    

//    return self;
//})()

function SaveSchedule()
{


    

    $.ajax({
        url: "../DataService.asmx/SaveEmployeePrioritiesSchedule",
        type: "POST",
        data: JSON.stringify({
            day: $("#ddlDays option:selected").val(),
            time: $("#txtMeetingStartTime").val(),
            reportDay: $("#ddlDays option:selected").val(),
            employeeId: $("#ddlPriorityEmployees option:selected").val()
        }),
        contentType: "application/json",
        success: function (data) {
            PopulateSchedule(data);
            //$("#tblPriorityListSchedules tbody").html("");
            //$("#tblPriorityListSchedules tbody").append("<tr><th>Report Day</th><th>Deadline Day</th><th>Time</th></tr>");
            //for (var i = 0; i < data.d.length; i++) {

            //    $("#tblPriorityListSchedules tbody").append("<tr><td>" + data.d[i].ReportDay + "</td><td>" + data.d[i].DaysOfWeek + "</td><td>" + data.d[i].TimesOfDay + "</td></tr>");
            //}
        }
    });
 



}

function PopulateSchedule(data)
{


    $("#tblPriorityListSchedules tbody").html("");
    $("#tblPriorityListSchedules tbody").append("<tr><th></th><th>Deadline Day</th><th>Time</th></tr>");
    for (var i = 0; i < data.d.length; i++) {

        $("#tblPriorityListSchedules tbody").append("<tr><td><a href='#' onclick=DeleteSchedule(" + data.d[i].ScheduleID + ") data-role='delete-controller'><img src='/Images/delete.gif' title='Remove' /></a></td><td>" + data.d[i].DaysOfWeek + "</td><td>" + data.d[i].TimesOfDay + "</td></tr>");
    }

}

function DeleteSchedule(scheduleId)
{

    if (confirm("Are you sure you want to remove this schedule?")) {
        $.ajax({
            url: "../DataService.asmx/DeletePrioritySchedule",
            type: "POST",
            data: JSON.stringify({
                scheduleId: scheduleId
               ,employeeId: $("#ddlPriorityEmployees option:selected").val()

            }),
            contentType: "application/json",
            success: function (data) {
                PopulateSchedule(data);
            }
        });
        return;
    }


}

function GetEmployeePrioritiesSchedule()
{


    $.ajax({
        url: "../DataService.asmx/GetPrioritiesListScheduleForEmployee",
        type: "POST",
        data: JSON.stringify({
            employeeId: $("#ddlPriorityEmployees option:selected").val()

        }),
        contentType: "application/json",
        success: function (data) {
            PopulateSchedule(data);
            //$("#tblPriorityListSchedules tbody").html("");
            //$("#tblPriorityListSchedules tbody").append("<tr><th>Deadline Day</th><th>Report Day</th><th>Time</th></tr>");
            //for (var i = 0; i < data.d.length; i++) {

            //    $("#tblPriorityListSchedules tbody").append("<tr><td>" + data.d[i].DaysOfWeek + "</td><td>" + data.d[i].ReportDay + "</td><td>" + data.d[i].TimesOfDay + "</td></tr>");
            //}
        }
    });


}
/* Copyright © 2024 Renegade Swish, LLC */

