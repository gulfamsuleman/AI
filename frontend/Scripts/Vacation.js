$().ready(function () {
    
    resize();
    window.onresize = resize;
    
    $("#start-date").change(refreshList);
    $("#end-date").change(refreshList);

    $(".AssignmentType").change(refreshList);

    populateGroups();
    populateUserSelect();

    $('.TaskResults').on('click', '.reassigncheckall', function () {
        $('.reassigncheck').prop('checked', ($(this).prop('checked')));
    });

    $(".reassignbtn").click(reassignChecked);
    updateAssignmentLabels();
});

function populateGroups() {
    var grouplist = "<option value=0>Select Group To Reassign</option>";

    $.ajax({
        url: "/DataService.asmx/GetGroups",
        type: "POST",
        data: "",
        dataType: "json",
        contentType: "application/json",
        success: function (response) {
            for (var i = 0; i < response.d.length; i++) {
                grouplist += "<option value='" + response.d[i].Id + "'>" + response.d[i].Name+"</option>"
            }
            $("#grouplist").html(grouplist);
        }
    });
}

function reassignChecked() {
    var reassignTo = $("#grouplist").val();
    if (reassignTo > 0) {
        var checkedcount = $("input.reassigncheck:checked").length;
        var processedcount = 0;

        $("input.reassigncheck:checked").each(function () {
            var id = $(this).closest("tr").attr("v");
            var jsonRequestData = JSON.stringify({ ReplacingID: id, TempGroupID: reassignTo, TempAssignmentStart: $("#start-date").val(), TempAssignmentEnd: $("#end-date").val()});
            $.ajax({
                url: "/DataService.asmx/TemporaryAssignment_Add",
                type: "POST",
                data: jsonRequestData,
                dataType: "json",
                contentType: "application/json",
                success: function (response) {
                    processedcount++;
                    if (processedcount == checkedcount) {
                        clearAndRefresh();
                    }
                },
                error: function (xhr, status, e) {
                    notifier.setMessage("Error saving reassignments", "red", 2000);
                }
            });
        });

    }
}


function clearAndRefresh() {
    $("#grouplist").val(0);
    refreshList();
}

function resize() {
    $("#site-main").height(($(window).height() - $("#site-nav").outerHeight() - $("#site-footer").outerHeight() - 4) + "px");
    $("#site-main").css("margin-top", ($("#site-nav").outerHeight()) + "px");
}

function toIsoDate(str) {
    // Handles empty or invalid dates gracefully
    if (!str) return null;
    var d = new Date(str);
    if (isNaN(d)) return null;
    // Only date part, no time
    return d.getFullYear() + '-' +
        ('0' + (d.getMonth() + 1)).slice(-2) + '-' +
        ('0' + d.getDate()).slice(-2) + 'T00:00:00';
}

function refreshList() {
    var userId = $("#user-select-group").is(":visible") ? $("#user-select").val() : $("#currentUserId").val();
    userId = userId ? parseInt(userId, 10) : null;
    var assignmentType = parseInt($("input[name='AssignmentType']:checked").val(), 10);

    var jsonRequestData = JSON.stringify({
        TempAssignmentStart: toIsoDate($("#start-date").val()),
        TempAssignmentEnd: toIsoDate($("#end-date").val()),
        AssignmentType: assignmentType,
        UserId: userId
    });

    $.ajax({
        url: "/DataService.asmx/TemporaryAssignment_GetList",
        type: "POST",
        data: jsonRequestData,
        dataType: "json",
        contentType: "application/json",
        success: function (response) {
            var tasklisthtml = "<table class='tasklist'><tr><th><input type='checkbox' class='reassigncheckall'></th><th>Task Name</th><th>Current Assignees</th><th>Temp Assignee</th></tr>";
            if (response.d.length == 0) {
                tasklisthtml += "<tr><td colspan=100%>No Tasks Found</td></tr>"
            }
            for (var i = 0; i < response.d.length; i++) {
                var item = response.d[i];
                tasklisthtml += "<tr class='reassign' v='" + item.AssignmentID + "'>";
                tasklisthtml += "<td><input type='checkbox' class='reassigncheck'></td>";
       
                tasklisthtml += "<td>" + item.TaskName + "</td>";
                tasklisthtml += "<td>" + item.Assignees + "</td>";
                if (item.TempGroupName.length > 0) {
                    tasklisthtml += "<td>" + item.TempGroupName + ": " + item.TempAssignmentStart + " - " + item.TempAssignmentEnd + "</td>";
                }
                else {
                    tasklisthtml += "<td></td>";
                }
                tasklisthtml += "</tr > ";
            }
            tasklisthtml += "</table>"
            $(".TaskResults").html(tasklisthtml);
        },
        error: function (xhr, status, e) {
            notifier.setMessage("Error retrieving task list", "red", 2000);
            if (xhr && xhr.responseText) {
                console.error(xhr.responseText);
            }
        }    
    });
}
function updateAssignmentLabels() {
    var selectedText = $("#user-select-group").is(":visible")
        ? $("#user-select option:selected").text()
        : "me";

    // Update all labels with a data-default attribute
    $("label[data-default]").each(function () {
        var baseText = $(this).attr("data-default");
        // Replace name with selected user
        var newText = baseText.replace(/\bme\b/gi, selectedText);
        $(this).text(newText);
    });
}


function populateUserSelect() {
    var currentUserId = $("#currentUserId").val();

    $.ajax({
        url: "/DataService.asmx/GetSupervisedUsers",
        type: "POST",
        data: JSON.stringify({ supervisorId: currentUserId }),
        dataType: "json",
        contentType: "application/json",
        success: function (response) {
            var users = response.d || [];
            if (users.length > 0) {
                // Supervisor: show dropdown and populate
                var options = "<option value='" + currentUserId + "'>Myself</option>";
                users.forEach(function (user) {
                    if (user.Id != currentUserId) {
                        options += "<option value='" + user.Id + "'>" + user.FullName + "</option>";
                    }
                });
                $("#user-select").html(options);
                $("#user-select-group").show();
            } else {
                // Not a supervisor: hide dropdown, always use self
                $("#user-select-group").hide();
                $("#user-select").html(""); // Clear options just in case
            }
            updateAssignmentLabels();
            refreshList();
        }
    });
}

// Ensure refreshList is called when the dropdown changes
$(document).on('change', '#user-select', function () {
    updateAssignmentLabels();
    refreshList();
});

/* Copyright © 2024 Renegade Swish, LLC */

