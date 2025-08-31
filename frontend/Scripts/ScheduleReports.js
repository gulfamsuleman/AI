$().ready(function () {
   
    $("#btnSaveSchedule").click(SaveSchedule);
    //$.ajax({
    //    url: "DataService.asmx/GetEmployeesForSupervisor",
    //    type: "POST",
    //    data: {},
    //    async: false,
    //    contentType: "application/json",
    //    success: function (data) {

    //        $("#ddlPriorityEmployees").html(data.d);
    //        //$("#tblPriorityListSchedules tbody").html("");
    //        //$("#tblPriorityListSchedules tbody").append("<tr><th>Deadline Day</th><th>Report Day</th><th>Time</th></tr>");
    //        //for (var i = 0; i < data.d.length; i++) {

    //        //    $("#tblPriorityListSchedules tbody").append("<tr><td>" + data.d[i].DaysOfWeek + "</td><td>" + data.d[i].ReportDay + "</td><td>" + data.d[i].TimesOfDay + "</td></tr>");
    //        //}
    //    }
    //});

    $.ajax({
        url: "DataService.asmx/GetSupervisorPriorityReportSchedule",
        type: "POST",
        //data: JSON.stringify({
        //    employeeId: $("#ddlPriorityEmployees option:selected").val()

        //}),
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





function SaveSchedule() {




    $.ajax({
        url: "DataService.asmx/SaveSupervisorsPrioritiesReportSchedule",
        type: "POST",
        data: JSON.stringify({
            day: $("#ddlDays option:selected").val(), offsetDays: $("#txtNumberOfDays").val()

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

function PopulateSchedule(data) {


    $("#tblPriorityListSchedules tbody").html("");
    $("#tblPriorityListSchedules tbody").append("<tr><th></th><th>Scheduled Day</th><th>OffSet Days</th></tr>");
    for (var i = 0; i < data.d.length; i++) {

        $("#tblPriorityListSchedules tbody").append("<tr><td><a href='#' onclick=DeleteSchedule(" + data.d[i].ScheduleID + ") data-role='delete-controller'><img src='/Images/delete.gif' title='Remove' /></a></td><td>" + data.d[i].DaysOfWeek + "</td><td>" + data.d[i].OffsetDays + "</td></tr>");
    }

}

function DeleteSchedule(scheduleId) {

    if (confirm("Are you sure you want to remove this schedule?")) {
        $.ajax({
            url: "DataService.asmx/DeleteSupervisorPriorityReportSchedule",
            type: "POST",
            data: JSON.stringify({
                scheduleId: scheduleId

            }),
            contentType: "application/json",
            success: function (data) {
                PopulateSchedule(data);
            }
        });
        return;
    }


}

function GetEmployeePrioritiesSchedule() {


    $.ajax({
        url: "DataService.asmx/GetPrioritiesListScheduleForEmployee",
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

