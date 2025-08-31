var reassignControllersModule = (function() {
    var self = {};

    var username = $("#username");
    var memberList = $("#member-select");
    var toggleShowNew = $("#toggle-show-new");
    var toggleShowNonComplete = $("#toggle-show-non-complete");
    var controlledTaskTable = $("#controlledTasksTable");
    var throbber = $("#throbber");
    var rowTemplate =
		"<tr data-id='{0}' class='{1}'>" +
				"<td data-role='checkbox'><input data-role='task-select' type='checkbox'/></td>" +
				"<td data-role='name'>{2}</td>" +
				"<td>{3}</td>" +
				"<td>{4}</td>" +
			"</tr>";

    $().ready(function () {

        controlledTaskTable.hide();
        throbber.hide();

        controlledTaskTable.tablesorter({
            headers: {
               0: {
                    // disable it by setting the property sorter to false 
                    sorter: false
                }
            },
            sortList: [[1, 0]]
        });

        $(document).on("change", "#check-all", function () { checkAll(); });
        $(document).on("change", "#member-select", function () { getControlledTaskList(); });
        $(document).on("change", "#toggle-show-new", function () { getControlledTaskList(); });
        $(document).on("change", "#toggle-show-non-complete", function () { getControlledTaskList(); });
        $(document).on("click", "button[data-action=reassign]", function () { reassign(); });

        resize();
        window.onresize = resize;
    });

    function checkAll() {
        $("input[data-role='task-select']").prop("checked", $("#check-all").prop("checked"));
    }

    function resize() {
        $("#site-main").height(($(window).height() - $("#site-nav").outerHeight() - $("#site-footer").outerHeight() - 4) + "px");
        $("#site-main").css("margin-top", ($("#site-nav").outerHeight()) + "px");
    }

    function getControlledTaskList() {
        controlledTaskTable.hide();
        if (memberList.val() > 0)
        {
            throbber.show();
            $.ajax({
                url: "/DataService.asmx/GetTasksControlledByGroup",
                type: "POST",
                data: JSON.stringify({
                    groupID: memberList.val(),
                    loginName: username.val(),
                    newOnly: toggleShowNew.is(':checked'),
                    incompleteOnly: toggleShowNonComplete.is(':checked')
                }),
                contentType: "application/json",
                success: function (data) {
                    controlledTaskTable.find("tbody").html("");
                    for (var i = 0; i < data.d.length; i++) {
                        addTaskRow(data.d[i]);
                    }
                    controlledTaskTable.trigger("update");
                    throbber.hide();
                    controlledTaskTable.show();
                }
            });
        }
    }

    function addTaskRow(task) {
        var highlighted = "";
        if (task.IsHighlighted) {
            highlighted = "highlight";
        }
        var newElem = $(format(rowTemplate, task.Id, highlighted, task.Name, task.Controllers, task.Assignees));
        controlledTaskTable.find("tbody").append(newElem);
    }

    function reassign() {

        var statusControllerIds = [];
        $('#new-member-select :selected').each(function (i, selected) {
            statusControllerIds.push($(selected).val());
        });
       
        var checklistIDs = [];
        $("input[data-role='task-select']:checked").closest("tr").each(
           function () {
               checklistIDs.push($(this).data("id"));
           }
       );
       

        if ((statusControllerIds.length > 0) && (checklistIDs.length > 0) && memberList.val() > 0)
        {
            controlledTaskTable.hide();
            throbber.show();
            $.ajax({
                url: "/DataService.asmx/ReassignTaskControllers",
                type: "POST",
                data: JSON.stringify({
                    checklistIDs: checklistIDs,
                    AssignedIds: statusControllerIds
                }),
                contentType: "application/json",
                success: function (data) {
                    getControlledTaskList();
                }
            });
        }
        else {
            alert("Please select tasks to reassign and who to change the controller to.");
        }
    }

    return self;
})()
/* Copyright © 2024 Renegade Swish, LLC */

