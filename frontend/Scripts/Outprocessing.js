function outprocessUserConfirm() {

    var employeeToOutprocess = $("#outprocess-employee-target-select").find("option:selected").val();
    var employeeToOutprocessName = $("#outprocess-employee-target-select").find("option:selected").text();
    var employeeToReassignTasks = $("#supervised-all-employee-select").find("option:selected").val();
    var employeeToReassignTasksName = $("#supervised-all-employee-select").find("option:selected").text();

    var message = `
    Are you sure you want to begin outprocessing for ${employeeToOutprocessName} and reassign all tasks to ${employeeToReassignTasksName}?
    `;

    if (employeeToOutprocess === undefined || employeeToReassignTasks === undefined) {
        alert("Please select a user from each available list.");
    } else { 
        if (confirm(message)) {
            outprocessUser(employeeToOutprocess, employeeToReassignTasks);
        }
    }
}

function outprocessUser(outprocessedUser, reassignedUser) {

        $.ajax({
            url: "/DataService.asmx/OutprocessUser",
            type: "POST",
            data: JSON.stringify({
                outprocessedUserId: outprocessedUser,
                reassignedUserId: reassignedUser
            }),
            contentType: "application/json",
            async: true,
            success: function (data) {
                alert("User has been successfully outprocessed and tasks have been reassigned.");
                location.reload();
            },
            error: function (xhr, status, error) {
                alert("Outprocessing was not successful. Please contact system administrator.");
            }
        }); 
}
/* Copyright © 2024 Renegade Swish, LLC */

