var reassignModule = (function() {
    var self = {};
    var checkAllStatusController = $("input[data-action='check-all-status-controller']");
    var checkAllStatusSupervisor = $("input[data-action='check-all-status-supervisor']");
    var checkAllTaskAssigned = $("input[data-action='check-all-task-assigned']");
    var checkAllTaskControlled = $("input[data-action='check-all-task-controlled']");
    var checkAllTaskAlertee = $("input[data-action='check-all-task-alertee']");
    var reassignButton = $("button[data-action='reassign']");
    var removeButton = $("button[data-action='removeAssignment']");
    var deleteButton = $("button[data-action='deleteTask']");
	
    $().ready(function () {

        reassignButton.click(reassignSelected);
        removeButton.click(removeSelected);
        deleteButton.click(deleteSelected);

	    checkAllStatusController.change(checkAllStatusControllerCheckboxes);
	    checkAllStatusSupervisor.change(checkAllStatusSupervisorCheckboxes);
	    checkAllTaskAssigned.change(checkAllTaskAssignedCheckboxes);
	    checkAllTaskControlled.change(checkAllTaskControlledCheckboxes);
	    checkAllTaskAlertee.change(checkAllTaskAlerteeCheckboxes);

	    resize();
	    window.onresize = resize;
	});

    function reassignSelected() {
        var reassignGroup = $("#reassign-member-select").find("option:selected").val();
        var addToStatusReport = $("#addToStatusChk").prop("checked");

        if (reassignGroup <= 0) {
            alert("Please select group to reassign")
            return;
        }
        //gather data on what was checked
        var dirty = 0;
        var statusControllerIds = [];
        $("input[data-role='status-controller']:checked").closest("tr").each(
			function () {
			    statusControllerIds.push($(this).data("id"));
			    dirty = 1;
			}
		);
        var statusSupervisorIds = [];
        $("input[data-role='status-supervisor']:checked").closest("tr").each(
			function () {
			    statusSupervisorIds.push($(this).data("id"));
			    dirty = 1;
			}
		);
        var taskAssigneeIds = [];
        $("input[data-role='task-assigned']:checked").closest("tr").each(
			function () {
			    taskAssigneeIds.push($(this).data("id"));
			    dirty = 1;
			}
		);
        var taskControllerIds = [];
        $("input[data-role='task-controlled']:checked").closest("tr").each(
			function () {
			    taskControllerIds.push($(this).data("id"));
			    dirty = 1;
			}
		);
        var taskAlerteeIds = [];
        $("input[data-role='task-alertee']:checked").closest("tr").each(
			function () {
			    taskAlerteeIds.push($(this).data("id"));
			    dirty = 1;
			}
		);
       
        //reassign status controllers
        if (statusControllerIds.length > 0) {

            $.ajax({
                url: "/DataService.asmx/ReassignReportUser",
                type: "POST",
                data: JSON.stringify({
                    Ids: statusControllerIds,
                    reassignedTo: reassignGroup
                }),
                contentType: "application/json",
                async: false
            });
        }
        //reassign status supervisors/IPs
        if (statusSupervisorIds.length > 0) {
            $.ajax({
                url: "/DataService.asmx/ReassignReportSupervisor",
                type: "POST",
                data: JSON.stringify({
                    Ids: statusSupervisorIds,
                    reassignedTo: reassignGroup
                }),
                contentType: "application/json",
                async: false
            });
        }
        //reassign task assignees
        if (taskAssigneeIds.length > 0) {
            $.ajax({
                url: "/DataService.asmx/ReassignTaskAssignment",
                type: "POST",
                data: JSON.stringify({
                    Ids: taskAssigneeIds,
                    reassignedTo: reassignGroup,
                    status: addToStatusReport
                }),
                contentType: "application/json",
                async: false
            });
        }
        //reassign task controllers
        if (taskControllerIds.length > 0) {
            $.ajax({
                url: "/DataService.asmx/ReassignTaskController",
                type: "POST",
                data: JSON.stringify({
                    Ids: taskControllerIds,
                    reassignedTo: reassignGroup
                }),
                contentType: "application/json",
                async: false,
                error: function (request, status, error) {
                    alert(request.responseText);
                }
            });
        }
        //reassign alertees
        if (taskAlerteeIds.length > 0) {
            $.ajax({
                url: "/DataService.asmx/ReassignTaskAlertee",
                type: "POST",
                data: JSON.stringify({
                    Ids: taskAlerteeIds,
                    reassignedTo: reassignGroup
                }),
                contentType: "application/json",
                async: false,
                error: function (request, status, error) {
                    alert(request.responseText);
                }
            });
        }
        if (dirty == 1) {
            window.location.reload();
        }
    }
    function removeSelected() {
        //gather data on what was checked
        var totalTypesRemaining = 0;
        var statusControllerIds = [];
        var statusControllers = 0;
        var opName = $("#reassign-panel h2").text().replace("Reassign tasks for ", "");
        var triedRemoveLast = false;

        $("input[data-role='status-controller']:checked").closest("tr").each(
			function () {
			    if ($(this).children().eq(2).text() == opName) {
			        triedRemoveLast = true;
			    } else {
			        statusControllerIds.push($(this).data("id"));
			        statusControllers = 1;
			    }
			}
		);

        var statusSupervisorIds = [];
        var statusSupervisors = 0;
        $("input[data-role='status-supervisor']:checked").closest("tr").each(
			function () {
			    if ($(this).children().eq(2).text() == opName) {
			        triedRemoveLast = true;
			    } else {
			        statusSupervisorIds.push($(this).data("id"));
			        statusSupervisors = 1;
			    }
			}
		);
        var taskAssigneeIds = [];
        var taskAssignees = 0;
        $("input[data-role='task-assigned']:checked").closest("tr").each(
			function () {
			    if ($(this).children().eq(2).text() == opName) {
			        triedRemoveLast = true;
			    } else {
			        taskAssigneeIds.push($(this).data("id"));
			        taskAssignees = 1;
			    }
			}
		);
        var taskControllerIds = [];
        var taskControllers = 0;
        $("input[data-role='task-controlled']:checked").closest("tr").each(
			function () {
			    if ($(this).children().eq(3).text() == opName) {
			        triedRemoveLast = true;
			    } else {
			        taskControllerIds.push($(this).data("id"));
			        taskControllers = 1;
			    }
			}
		);
        var taskAlerteeIds = [];
        var taskAlertees = 0;
        $("input[data-role='task-alertee']:checked").closest("tr").each(
			function () {
			    taskAlerteeIds.push($(this).data("id"));
			    taskAlertees = 1;
			}
		);
        //determine number of ajax calls we will make
        totalTypesRemaining = statusControllers + statusSupervisors + taskAssignees + taskControllers + taskAlertees;

        //remove status controllers
        if (statusControllerIds.length > 0)
        {

            $.ajax({
                url: "/DataService.asmx/RemoveReportUser",
                type: "POST",
                data: JSON.stringify({
                    Ids: statusControllerIds
                }),
                contentType: "application/json",
                success: function (data) {
                    for (var controllerID in statusControllerIds) {
                        $("tr[data-role='status-controller-id'][data-id='" + statusControllerIds[controllerID] + "']").hide();
                    }
                    totalTypesRemaining--;
                    if (totalTypesRemaining == 0) {
                        alert("Remove complete");
                    }
                }
            });
        }
        //remove status supervisors/IPs
        if (statusSupervisorIds.length > 0) {
            $.ajax({
                url: "/DataService.asmx/RemoveReportSupervisor",
                type: "POST",
                data: JSON.stringify({
                    Ids: statusSupervisorIds
                }),
                contentType: "application/json",
                success: function (data) {
                    for (var superID in statusSupervisorIds) {
                        $("tr[data-role='status-supervisor-id'][data-id='" + statusSupervisorIds[superID] + "']").hide();
                    }
                    totalTypesRemaining--;
                    if (totalTypesRemaining == 0) {
                        alert("Remove complete");
                    }
                }
            });
        }
        //remove task assignees
        if (taskAssigneeIds.length > 0) {
            $.ajax({
                url: "/DataService.asmx/RemoveTaskAssignment",
                type: "POST",
                data: JSON.stringify({
                    Ids: taskAssigneeIds
                }),
                contentType: "application/json",
                success: function (data) {
                    for (var taskAssigneeID in taskAssigneeIds) {
                        $("tr[data-role='task-assigned-id'][data-id='" + taskAssigneeIds[taskAssigneeID] + "']").hide();
                    }
                    totalTypesRemaining--;
                    if (totalTypesRemaining == 0) {
                        alert("Remove complete");
                    }
                }
            });
        }
        //remove task controllers
        if (taskControllerIds.length > 0) {
            $.ajax({
                url: "/DataService.asmx/RemoveTaskController",
                type: "POST",
                data: JSON.stringify({
                    Ids: taskControllerIds
                }),
                contentType: "application/json",
                success: function (data) {
                    for (var taskControllerID in taskControllerIds) {
                        $("tr[data-role='task-controlled-id'][data-id='" + taskControllerIds[taskControllerID] + "']").hide();
                    }
                    totalTypesRemaining--;
                    if (totalTypesRemaining == 0) {
                        alert("Remove complete");
                    }
                }
            });
        }
        //remove alertees
        if (taskAlerteeIds.length > 0) {
            $.ajax({
                url: "/DataService.asmx/RemoveTaskAlertee",
                type: "POST",
                data: JSON.stringify({
                    Ids: taskAlerteeIds
                }),
                contentType: "application/json",
                success: function (data) {
                    for (var alerteeID in taskAlerteeIds) {
                        $("tr[data-role='task-alertee-id'][data-id='" + taskAlerteeIds[alerteeID] + "']").hide();
                    }
                    totalTypesRemaining--;
                    if (totalTypesRemaining == 0) {
                        alert("Remove complete");
                    }
                }
            });
        }

        if (triedRemoveLast) {
            alert("Some of the selected assignments were the last on the task--these could not be removed.\n\nInstead, either use the \"Reassign All Selected To\" or \"Delete Task\" features for these tasks\n\nIf you have any questions, please contact IT.")
        }
    }

    function deleteSelected() {

        //gather data on what was checked
        var totalTypesRemaining = 0;
        var statusControllerIds = [];
        var statusControllers = 0;
        var opName = $("#reassign-panel h2").text().replace("Reassign tasks for ", "");
        var triedDeleteNotLast = false;

        $("input[data-role='status-controller']:checked").closest("tr").each(
			function () {
			    if ($(this).children().eq(2).text() != opName) {
			        triedDeleteNotLast = true;
			    } else {
			        statusControllerIds.push($(this).data("id"));
			        statusControllers = 1;
			    }
			}
		);

        var taskAssigneeIds = [];
        var taskAssignees = 0;
        $("input[data-role='task-assigned']:checked").closest("tr").each(
			function () {
			    if ($(this).children().eq(2).text() != opName) {
			        triedDeleteNotLast = true;
			    } else {
			        taskAssigneeIds.push($(this).data("id"));
			        taskAssignees = 1;
			    }
			}
		);
        
        //determine number of ajax calls we will make
        totalTypesRemaining = statusControllers + taskAssignees;

        //delete status reports
        if (statusControllerIds.length > 0) {

            if (window.confirm("Are you sure you want to delete?  This will permanently remove the selected status reports so that nobody can access them.  You should only do this if nobody is using the status report anymore.")) {
                $.ajax({
                    url: "/DataService.asmx/DeleteReportsByController",
                    type: "POST",
                    data: JSON.stringify({
                        Ids: statusControllerIds
                    }),
                    contentType: "application/json",
                    success: function (data) {
                        for (var controllerID in statusControllerIds) {
                            $("tr[data-role='status-controller-id'][data-id='" + statusControllerIds[controllerID] + "']").hide();
                        }
                        totalTypesRemaining--;
                        if (totalTypesRemaining == 0) {
                            alert("Delete complete");
                        }
                    }
                });
            }
        }
        
        //delete tasks
        if (taskAssigneeIds.length > 0) {
            if (window.confirm("Are you sure you want to delete?  This will permanently remove the selected tasks so that nobody can do them.  You should only do this if the task does not need to be done anymore.")) {
                $.ajax({
                    url: "/DataService.asmx/DeleteTaskAssignments",
                    type: "POST",
                    data: JSON.stringify({
                        Ids: taskAssigneeIds
                    }),
                    contentType: "application/json",
                    success: function (data) {
                        for (var taskAssigneeID in taskAssigneeIds) {
                            $("tr[data-role='task-assigned-id'][data-id='" + taskAssigneeIds[taskAssigneeID] + "']").hide();
                        }
                        totalTypesRemaining--;
                        if (totalTypesRemaining == 0) {
                            alert("Delete complete");
                        }
                    }
                });
            }
        }

        if (triedDeleteNotLast) {
            alert("Some of the selected assignments were NOT the last on the task--these could not be deleted.\n\nInstead, either use the \"Reassign All Selected To\" or \"Remove All Selected Assignments\" features for these tasks\n\nIf you have any questions, please contact IT.")
        }
        
    }

    function checkAllStatusControllerCheckboxes() {
        $("input[data-role='status-controller']").prop("checked", checkAllStatusController.prop("checked"));
    }
    function checkAllStatusSupervisorCheckboxes() {
        $("input[data-role='status-supervisor']").prop("checked", checkAllStatusSupervisor.prop("checked"));
    }
    function checkAllTaskAssignedCheckboxes() {
        $("input[data-role='task-assigned']").prop("checked", checkAllTaskAssigned.prop("checked"));
    }
    function checkAllTaskControlledCheckboxes() {
        $("input[data-role='task-controlled']").prop("checked", checkAllTaskControlled.prop("checked"));
    }
    function checkAllTaskAlerteeCheckboxes() {
        $("input[data-role='task-alertee']").prop("checked", checkAllTaskAlertee.prop("checked"));
    }

    function resize() {
        $("#site-main").height(($(window).height() - $("#site-nav").outerHeight() - $("#site-footer").outerHeight() - 4) + "px");
        $("#site-main").css("margin-top", ($("#site-nav").outerHeight()) + "px");
    }

	return self;
})()

function openReport(reportId, taskId) {
   window.location.href = 'MyInbox.aspx?reportID=' + reportId + '&taskID=' + taskId;
}
/* Copyright © 2024 Renegade Swish, LLC */

