let availableGroups = [];
let assignmentIds = [];

$().ready(function () {

    getGroups();
    
});

function getGroups() {
    var supervisorId = $("#supervisorId").val();

    $.ajax({
        url: "../DataService.asmx/GetSupervisedGroups",
        type: "POST",
        data: JSON.stringify({ supervisorId: supervisorId }),
        dataType: "json",
        contentType: "application/json",
        success: function (response) {
            var data = response.d;
            availableGroups = [];
            availableGroups = data;

            populateGraphs();
        },
        error: function (error) {
            console.error("AJAX error:", error);
        }
    });
}


function populateGraphs() {
    var supervisorId = $("#supervisorId").val();
    var userId = $("#userId").val();

    $.ajax({
        url: "../DataService.asmx/GetRedactedTaskList",
        type: "POST",
        data: JSON.stringify({ userId: userId, supervisorId: supervisorId, isOwnDashboard: false }),
        dataType: "json",
        contentType: "application/json",
        success: function (response) {
            var data = response.d;

            if (data && Array.isArray(data)) {
                populateAssignments(data);
            } else {
                console.error("Unexpected data format:", data);
            }
        },
        error: function (error) {
            console.error("AJAX error:", error);
        }
    });
}

function populateAssignments(values) {
    let userDataTable = `
        <div style="text-align: center;">
            <label for="modalAssignmentsTable" style="font-size: 15pt"><b>Assignments</b></label>
            <table id="modalAssignmentsTable" class="display compact" style="width:100%"></table><br>
        </div>`;

    $("#userAssignmentsTable").html(userDataTable);

    var newTable = new DataTable("#modalAssignmentsTable", {
        dom: '<"top"B>ltp',
        pageLength: 8,
        initComplete: function () {

            var selectBox = `<span>Reassign To:</span><select id="groupPicker-1">`;
            for (let group of availableGroups) {
                selectBox += `<option value="${group.Id}" selected>
                                                ${group.GroupName}
                                              </option>`;
            }
            selectBox += `</select>`;

            $("#modalAssignmentsTable_wrapper .top").append(
                `<div id="assignmentActions" style="display:flex; justify-content:space-between; align-items: center;">
                    <div id="reassignmentActions">
                        <button id="tasksModalButton" style="margin: 5px;" class="conversion-btn">Reassign</button>
                        <input type="checkbox" name="temporaryReassignment" id="temporaryReassignment" value="true"/>
                        <label for="temporaryReassignment">Temporary Reassignment?</label>
                    </div>
                    <div id="dateActions" style="display:none;">
                    <label for="fromDate">From:</label>
                    <input data-role="datepicker" type="text" size="6" id="fromDate" />
                    <label for="toDate">To:</label>
                    <input data-role="datepicker" type="text" size="6" id="toDate" />
                </div>
                <div>
                    ${selectBox}
                </div>
                </div>`);
        },
        paging: true,
        lengthChange: false,
        searching: true,
        autoFill: false,
        columnDefs: [
            { targets: [0, 1, 2, 3, 4, 5], orderable: false },
        ],
        responsive: true,
        data: values,
        columns: [
            {
                title: `<input type="checkbox" id="selectAllCheck" />`,
                data: null,
                render: function (data) {
                    if (data.ChecklistName !== '<REDACTED>')
                        return `<input type="checkbox" id="${data.ChecklistID}" value="${data.AssignmentID}" />`;
                    else
                        return '--';
                }
            },
            { title: "Task", data: 'ChecklistName' },
            { title: "Due Date", data: 'DueDate' },
            { title: "Assignees", data: 'Assignees' },
            { title: "Controllers", data: 'Controllers' },
            { title: "Report", data: 'StatusReportString' }
        ],
        drawCallback: function () {
            $('#modalAssignmentsTable td').each(function () {
                var fullText = $(this).text();
                $(this).attr('title', fullText);
            });
        }
    });
    
    $('#modalAssignmentsTable table td').each(function () {
        var fullText = $(this).text();
        $(this).attr('title', fullText);
    });
    $("#temporaryReassignment").on('click', function () {
        if ($(this).is(":checked")) {
            $("#dateActions").show();
            var datepicker = $("input[data-role='datepicker']");
            datepicker.lwDatepicker();
        }
        else $("#dateActions").hide();
    });

    $("#tasksModalButton").on('click', reassignUserTasks);

    $("#selectAllCheck").on('click', function () {
        var isChecked = $("#selectAllCheck").is(':checked');
        if (isChecked) {
            $('#modalAssignmentsTable tbody input[type="checkbox"]').each(function () {
                $(this).prop('checked', true);
                assignmentIds.push($(this).val());
            });
            console.log(assignmentIds);
        } else {
            assignmentIds = [];
            $('#modalAssignmentsTable tbody input[type="checkbox"]').each(function () {
                $(this).prop('checked', false);
            });
        }
    });

}

$('#modalAssignmentsTable tbody input[type="checkbox"]').on('click', function () {
    var isChecked = $(this).is(':checked');
    if (isChecked) assignmentIds.push($(this).val());
    console.log(assignmentIds);
});

function reassignUserTasks() {
    var groupId = $("#groupPicker-1").val();
    var assignmentIdsToSend = assignmentIds;

    if (assignmentIdsToSend.length < 1) alert("No tasks selected.");

    else if ($("#temporaryReassignment").is(':checked')) {

        let toDate = $("#toDate").val();
        let fromDate = $("#fromDate").val();
        let goAhead = confirm(`If a multi-member group is selected, this will affect all users in the group. Are you sure you want to confirm ?`);

        if (goAhead) {
            alert("Under construction!");
            //$.ajax({
            //    url: "../DataService.asmx/TemporaryAssignment_AddBulk",
            //    type: "POST",
            //    data: JSON.stringify({
            //        replacingIDs: assignmentIdsToSend,
            //        tempGroupID: groupId,
            //        TempAssignmentStart: fromDate,
            //        TempAssignmentEnd: toDate
            //    }),
            //    dataType: "json",
            //    contentType: "application/json",
            //    success: function (response) {

            //        alert("Tasks successfully reassigned!");
            //        populateGraphs();
            //    },
            //    error: function (error) {
            //        console.error("AJAX error:", error);
            //    }
            //});
        }
    }
    else {
        alert("Under construction!");
        //$.ajax({
        //    url: "../DataService.asmx/ReassignTasksToGroup",
        //    type: "POST",
        //    data: JSON.stringify({ groupId: groupId, assignmentIds: assignmentIdsToSend.join(',') }),
        //    dataType: "json",
        //    contentType: "application/json",
        //    success: function (response) {

        //        alart("Tasks successfully reassigned");
        //        populateGraphs();
        //    },
        //    error: function (error) {
        //        console.error("AJAX error:", error);
        //    }
        //});
    }
}

function reassign() {


    $.ajax({
        url: "../DataService.asmx/ReassignTasks",
        type: "POST",
        data: JSON.stringify({ checklistIds: checklistId, groupId: $("#groupPicker-1").val() }),
        dataType: "json",
        contentType: "application/json",
        success: function (response) {
            alert("Reassign Successful!");
        }
        ,
        error: function (error) {
            console.error("AJAX error:", error);
        }
    });

}
