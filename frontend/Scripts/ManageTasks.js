
var manageTasksModule = function () {
    var self = {};
    var treeInitialized = false;
    var prevSearch = 'uninitialized search value';
    var prevAdmin = 'uninitialized search value';

    self.isMobile = (typeof slider !== 'undefined');

    var schedules = [];

    $().ready(function () {
        $("select[data-set='controllers-with-groups']").addClass("hidden");

        $("#task-management-attach-point")
            .on("click", "#save-name-icon", updateChecklistName)
            .on("click", "a[data-role='delete-checklist']", deleteChecklist)
            .on("click", "a[data-role='copy-checklist']", copyChecklist);

        $("a[data-role='show-all']").click(function (e) {
            var elem = $(e.target);
            var selectIndividuals = elem.siblings("select[data-set='controllers']");
            var selectGroups = elem.siblings("select[data-set='controllers-with-groups']");
            if (selectGroups.hasClass("hidden")) {
                selectGroups.removeClass("hidden");
            } else {
                selectGroups.addClass("hidden");
            }
            if (selectIndividuals.hasClass("hidden")) {
                selectIndividuals.removeClass("hidden");
            } else {
                selectIndividuals.addClass("hidden");
            }
        });


        $("#task-management-attach-point").on('click', "[data-role='activate-instance']", ActivateInstance);

        $("#task-management-attach-point").on('click', "[data-role='open-due-date']", OpenDueDate);

        $("#task-management-attach-point").on('click', "[data-role='send-request']", sendRequest);

        $("#task-management-attach-point").on('click', "[data-role='cancel-request']", cancelRequest);

        $("#task-management-attach-point").on('click', "[data-role='approve-request']", approveRequest);

        $("#task-management-attach-point").on('click', "[data-role='reject-request']", rejectRequest);

        $("#newFolder").on('click', function () { addSubFolder(0); });

        $("#task-management-attach-point").on('click', "[data-role='add-assignment-header']", function (event) {
            //add a blank assignment
            var checklistId = $("#task-container").data('checklist-id');
            $.ajax({
                url: "../DataService.asmx/CreateChecklistInstance",
                data: JSON.stringify({ checklistId: checklistId }),
                type: "POST",
                dataType: "json",
                contentType: "application/json",
                success: function (data, textStatus, jqXhr) {
                    var instanceId = data.d;
                    var userId = $("#user-id").val();
                    addInstance(instanceId, userId);
                }
            });
            event.stopPropagation();
        });

        $("#task-management-attach-point").on('click', ".mtform-assignments a[data-role='delete']", function (e) {
            //delete assignment
            if (window.confirm("Are you sure you want to delete this assignment?")) {
                var instanceId = $(e.target).closest(".mtform-assignments").data('instance-id');
                var changeId = $("#task-container").data('change-id');
                $.ajax({
                    url: "/DataService.asmx/DeleteChecklistInstance",
                    data: JSON.stringify({ instanceId: instanceId, changeId: changeId }),
                    type: "POST",
                    dataType: "json",
                    contentType: "application/json",
                    success: function (data, textStatus, jqXhr) {
                        $(e.target).closest(".mtform-assignments").remove();
                        renumberInstances();
                    }
                });
            }
            event.stopPropagation();
        });

        $("#task-management-attach-point").on('click', ".mtform-assignments a[data-role='copy']", function (e) {
            //copy assignment
            var instanceId = $(e.target).closest(".mtform-assignments").data('instance-id');
            var changeId = $("#task-container").data("change-id");
            $.ajax({
                url: "../DataService.asmx/CopyChecklistInstance",
                data: JSON.stringify({ instanceId: instanceId, changeId: changeId }),
                type: "POST",
                dataType: "json",
                contentType: "application/json",
                success: function (data, textStatus, jqXhr) {
                    var instanceId = data.d;
                    if (instanceId != 0) {
                        var userId = $("#user-id").val();
                        addInstance(instanceId, userId);
                    }
                }
            });
            event.stopPropagation();
        });

        $(document).on('click', "#checklist-items-panel>button[data-action='preview']", loadPreview);

        $(document)
            .on('dnd_move.vakata', function (e, data) {
                var t = $(data.event.target).closest("li[role='treeitem']");
                var tgt = $(data.event.toElement);
                //allow dropping items onto "root-level" elements; will move item to root folder
                if (tgt.closest("li.jstree-node > ul.jstree-children").length == 0) return;

                if (t.attr("data-is-template") !== undefined) {
                    data.helper.find('.jstree-icon').removeClass('jstree-ok').addClass('jstree-er');
                }
            })
            .on('dnd_stop.vakata', function (e, data) {
                var t = $(data.event.target).closest("li[role='treeitem']");
                var elementId = $(data.element).closest("li[role='treeitem']").data("id");
                var targetId = $(data.event.target).closest("li[role='treeitem']").data("id");
                //allow dropping items onto "root-level" elements; will move item to root folder
                if (t.attr("data-is-template") !== undefined
                        && t.closest("li.jstree-node > ul.jstree-children").length >= 0)
                    targetId = 0;
                else if (t.attr("data-is-template") !== undefined)
                    return;

                if (($(data.element).closest("li").attr("data-is-template") !== undefined)) {
                    moveChecklistToFolder(elementId, targetId); //drop point a folder, dragged is a leaf
                } else {
                    if (elementId != targetId) {
                        moveFolderToFolder(elementId, targetId); //drop point a folder, dragged is a folder
                    }
                }
            });

        $("select[data-role='task-group-select'], select[data-role='task-manager-select']").on("change", reInitializeTree);
        $("input[data-role='task-search-admin']").on("change", reInitializeTree);
        $("input[data-role='task-search']")
            .keyup(function (e) {
                if (e.which == 13) {
                    $("#new-term-searched").val($("input[data-role='task-search']").val());
                    $(e.target).trigger('blur');
                }
            })
            .blur(function () { reInitializeTree(); });

        /**********************/
        /*** TREEVIEW STUFF ***/
        /**********************/

        reInitializeTree();

        resize();
        window.onresize = resize;

        if (isMobile && queryChecklistId != "") {
            showTaskEditPanel(queryChecklistId, false, -1);
        }
    });

    $(document).ready(function () {
        if (!window.viewHistoryBound) {
            $("#task-management-attach-point").on("click", "a[data-action='view-history']", function (e) {
                var checklistId = $("#task-container").data("checklist-id");
                console.log("view-history clicked, checklistId:", checklistId);
                openHistory(checklistId);
            });
            window.viewHistoryBound = true;
        };
    });

    function getTaskSearchTerm() {
        return $("input[data-role='task-search']").val();
    }

    function getManagerId() {
        return $("select[data-role='task-manager-select']").val();
    }

    function getAdmin() {
        if ($("input[data-role='task-search-admin']").prop("checked")) {
            return "true";
        }
        else {
            return "false";
        }
    }

    function getGroupId() {
        return $("select[data-role='task-group-select']").val();
    }

    function populateControllers(controllersArray) {
        for (var i = 0; i < controllersArray.length; i++) {
            controllersBox.addControllerRow(controllersArray[i]);
        }
    }

    function populateChecklistItems(checklistItemsArray) {
        for (var i = 0; i < checklistItemsArray.length; i++) {
            checklistItemsBox.addChecklistItemRow(checklistItemsArray[i]);
        }
    }

    function populateAssignments(assignmentsArray) {
        for (var i = 0; i < assignmentsArray.length; i++) {
            populateAssignment(assignmentsArray[i], i);
        }
    }

    function populateAssignment(assignment, index) {
        populateAssignees(assignment.assignees, index);
        populateStatusReports(assignment.statusReports, index);
        populateAlertsReminders(assignment.alertsReminders, index);
        populateSchedule(assignment.schedule, index);

    }

    function addInstance(instanceId, userId) {
        var params = {};
        var tree = $("#treePanel");
        params.TaskId = $("#task-container").data("checklist-id");
        params.IsArchive = false;
        if (instanceId)
            params.InstanceId = instanceId;
        if (userId)
            params.UserId = userId;
        $.ajax({
            url: "../JQueryHandler.ashx?ControlName=" + encodeURI("Controls/ManageTasks/AssignmentPanel.ascx"),
            type: "POST",
            data: params,
            success: function (htmlResult) {
                //insert before add-assignment-header
                var assignmentCount = $(".mtform-assignments").length;
                var assignmentsTemplate = "{0}";
                var filledAssignment = format(assignmentsTemplate, htmlResult);
                $("h4[data-role='add-assignment-header']").before(filledAssignment);
                setTimeout(function () {
                    renumberInstances();
                    var parent = $(".mtform-assignments[data-num='" + (assignmentCount + 1) + "']");
                    var newAssigneesPanel = assigneesBox(parent);
                    var newStatusReportPanel = statusReportsBox(parent);
                    var newSchedulingReportPanel = schedulingBox(parent);
                    schedules.push(newSchedulingReportPanel);
                    var newAlertsPanel = alertsRemindersBox(parent, newSchedulingReportPanel.isRecurring(), newSchedulingReportPanel.getDueOn());
                    newStatusReportPanel.populateStatusReports($("#task-container").data("checklist-id"));
                }, 100);
            }
        });
    }

    function renumberInstances() {
        $(".mtform-assignments span[data-role='instance-number']").each(function (index, element) {
            $(element).text(index + 1);
            $(element).closest(".mtform-assignments").attr('data-num', index + 1);
        })
    }

    function ActivateInstance(e) {
        var params = {
            InstanceId: $(e.target).closest(".mtform-assignments").data('instance-id'),
            ChangeId: $("#task-container").data("change-id")
        };
        $.ajax({
            url: "../DataService.asmx/ActivateChecklistInstance",
            type: "POST",
            data: params,
            datatype: "json",
            success: function (htmlResult) {
                self.refreshWorkingOnNow(e.target, params);
            }
        });
        return false;
    }

    self.refreshWorkingOnNow = function (dueLink, params) {
        $(dueLink).closest("fieldset").parent().load("JQueryHandler.ashx?ControlName=" + encodeURI("Controls/ManageTasks/WorkingOnNow.ascx"), params, function () { });
    };

    function OpenDueDate(e) {
        var id = $(e.target).data('due-date-id');
        var popupwin = window.open('../ManageSingleChecklist.aspx?taskId=' + id + '&taskStage=1', "checklistmini", "toolbar=no,status=yes,scrollbars=yes,resizable=yes,menubar=no,width=1300,height=800,resizable=yes")
        popupwin.focus();
    }

    function approveRequest() {
        var params = {
            changeRequestId: $("#task-container").data("change-id")
        };
        $.ajax({
            url: "../DataService.asmx/ApproveChangeRequest",
            type: "POST",
            data: params,
            datatype: "json",
            success: function () {
                $("#task-container").empty();
                window.location = "ChangeRequests.aspx";
            }
        });
    }

    function rejectRequest() {
        var params = {
            changeRequestId: $("#task-container").data("change-id")
        };
        $.ajax({
            url: "../DataService.asmx/DenyChangeRequest",
            type: "POST",
            data: params,
            datatype: "json",
            success: function () {
                $("#task-container").empty();
                window.location = "ChangeRequests.aspx";
            }
        });
    }

    function sendRequest() {

        var i;
        for (i = 0; i < schedules.length; i++) {
            schedules[i].saveChanges(false, false);
        }

        var params = {
            changeId: $("#task-container").data("change-id"),
            comment: $("[data-role='change-comments']").val()
        };
        $.ajax({
            url: "../DataService.asmx/SendRequest",
            type: "POST",
            data: params,
            datatype: "json",
            success: function () {
                $("#task-container").empty();
                $("[data-role='change-comments']").val("");
            }
        });
    }

    function cancelRequest() {
        var params = {
            ChangeId: $("#task-container").data("change-id")
        };
        $.ajax({
            url: "../DataService.asmx/CancelRequest",
            type: "POST",
            data: params,
            datatype: "json",
            success: function () {
                $("#task-container").empty();
            }
        });
    }

    function removeEmptyNodes() {
        var treePanel = $("#treePanel");
        var nodes = treePanel.find(".jstree-node");
        for (var i = 0; i < nodes.length; i++) {
            if (treePanel.jstree("is_leaf", nodes[i])) {
                continue;
            }
            treePanel.jstree("open_node", nodes[i], function (e) {
                if (treePanel.jstree("is_parent", e) == 0) {
                    $("#" + e.id).remove();
                }
            }, false);
        }
    }

    function moveChecklistToFolder(checklistId, folderId) {
        $.ajax({
            url: "../DataService.asmx/MoveChecklistToFolder",
            data: JSON.stringify({ checklistId: checklistId, folderId: folderId }),
            type: "POST",
            dataType: "json",
            contentType: "application/json",
            success: function () {
                reInitializeTree(true);
            }
        });
    }

    function moveFolderToFolder(folderId, newParentId) {
        $.ajax({
            url: "../DataService.asmx/MoveFolderToFolder",
            data: JSON.stringify({ newParentId: newParentId, folderId: folderId }),
            type: "POST",
            dataType: "json",
            contentType: "application/json",
            success: function () {
                reInitializeTree(true);
            }
        });
    }

    function toggleTemplateOnChecklist(checklistId) {
        $.ajax({
            url: "../DataService.asmx/ToggleTemplate",
            data: JSON.stringify({ checklistId: checklistId }),
            type: "POST",
            dataType: "json",
            contentType: "application/json",
            success: function () {
                // Looks a little funny, but Javascript doesn't implicitly cast strings to bools
                var isTemplate = ($("#treePanel").find("[data-id=" + checklistId + "]").attr("data-is-template") == "true");
                $("#treePanel").find("[data-id=" + checklistId + "]").attr("data-is-template", !isTemplate);
                reInitializeTree();
            }
        });
    }

    function addSubFolder(folderId) {
        if (folderId == null) folderId = 0;

        $.ajax({
            url: "../DataService.asmx/AddSubFolder",
            data: JSON.stringify({ folderId: folderId }),
            type: "POST",
            dataType: "json",
            contentType: "application/json",
            success: function () {
                reInitializeTree(true);
            }
        });
    }

    function deleteFolder(folderId) {
        if (window.confirm("Are you sure you want to delete this folder?")) {
            $.ajax({
                url: "../DataService.asmx/DeleteFolder",
                data: JSON.stringify({ folderId: folderId }),
                type: "POST",
                dataType: "json",
                contentType: "application/json",
                success: function () {
                    reInitializeTree(true);
                }
            });
        }
    }

    function loadPreview() {
        var currentChecklistId = $("#task-container").data('checklist-id');
        var currentChangeId = $("#task-container").data('change-id');
        if (!currentChangeId) currentChangeId = -1;
        var currentChecklistName = $("h3[data-role='checklist-header']").text();

        modalModule.init({
            titleText: "Preview",
            controlName: "Controls/Shared/ChecklistPreview.ascx",
            remoteParams: { ChecklistName: currentChecklistName, ChecklistId: currentChecklistId, ChangeId: currentChangeId }
        });
    }


    function reInitializeTree(force) {
        var thisSearch = getTaskSearchTerm();
        var thisAdmin = getAdmin();

        if ((thisSearch != prevSearch) || (thisAdmin != prevAdmin) || force) {
            prevSearch = thisSearch;
            prevAdmin = thisAdmin;

            if (treeInitialized) {
                $("#treePanel").jstree(true).destroy();
                treeInitialized = false;
            }


            $("#treePanel").addClass("hidden");

            var posting = $.post(
                '../Treeview.ashx',
                {
                    MemberGroupId: getGroupId(),
                    ManagerGroupId: getManagerId(),
                    Search: thisSearch,
                    ParentID: 0,
                    adminSearch: thisAdmin
                }
            );
            posting.done(
                function (data) {
                    $("#treePanel").html(data).bind("loaded.jstree", function (event, data) {
                        if (thisSearch.trim().length > 0) {
                            data.instance.open_all();
                            //data.instance.open_node($(".jstree-leaf[data-is-folder]"));
                            //$("#treePanel").jstree("open_node", $(".jstree-leaf[data-is-template]"));
                        }
                    }).jstree({
                        "core": {
                            'check_callback': true,
                            'data': false
                        },
                        "plugins": ["dnd", "contextmenu"],
                        "contextmenu": {
                            "items": function ($node) {
                                var checklistMenu = {
                                    "Template": {
                                        "label": "Toggle Template",
                                        "action": function (obj) {
                                            var checklistId = $(obj.reference[0]).parent().data("id");
                                            toggleTemplateOnChecklist(checklistId);
                                        }
                                    },
                                    "Activate": {
                                        "label": "Run This Now",
                                        "action": function (obj) {
                                            var checklistId = $(obj.reference[0]).parent().data("id");
                                            runThisNow(checklistId);
                                        }
                                    },
                                    "Cancel": {
                                        "seperator_before": true,
                                        "label": "Cancel",
                                        "action": function () {
                                            $.vakata.context.hide();
                                        }
                                    }
                                };
                                var folderMenu = {
                                    "SubFolder": {
                                        "label": "Add Sub-Folder",
                                        "action": function (obj) {
                                            var folderId = $(obj.reference.context).data("id");
                                            addSubFolder(folderId);
                                        }
                                    },
                                    "Delete": {
                                        "separator_before": true,
                                        "label": "Delete",
                                        "action": function (obj) {
                                            var folderId = $(obj.reference.context).data("id");
                                            deleteFolder(folderId);
                                        }
                                    },
                                    "Rename": {
                                        "label": "Rename",
                                        "action": function (obj) {
                                            $("#treePanel").jstree().edit(obj.reference);
                                        }
                                    },
                                    "Cancel": {
                                        "separator_before": true,
                                        "label": "Cancel",
                                        "action": function (obj) {
                                            $.vakata.context.hide();
                                        }
                                    }
                                };
                                var nodeElem = $("#" + $node.id);
                                var isChecklist = (nodeElem.attr("data-is-template") !== undefined);
                                if (isChecklist)
                                    return checklistMenu;
                                else {
                                    return folderMenu;
                                }
                            }
                        }
                    });

                    $("#treePanel").on('ready.jstree', function () {
                        alert(1);
                        var queryObject = queryObj();
                        if (queryObject.checklistId) {
                            var nodeId = $("#treePanel li[role='treeitem'][data-id='" + queryObject.checklistId + "']").attr("id");
                            $("#treePanel").jstree("select_node", "#" + nodeId, true);
                        }
                    });
                    treeInitialized = true;

                    $("#treePanel").on('activate_node.jstree', function (e, data, event) {
                        var tree = $(e.target);
                        var selected = tree.jstree("get_selected", true);
                        var node = $("#" + selected[0].id);
                        var isChecklist = node.closest(".jstree-node").attr("data-is-template") !== undefined;
                        if (isChecklist) {
                            var taskId = selected[0].data.id;
                            var isArchive = false;
                            showTaskEditPanel(taskId, isArchive, -1);

                            if (typeof slider !== 'undefined')
                                slider.scrollTop(0);
                            else
                                $("#site-main").scrollTop(0);
                        }
                        else {
                            node.children(".jstree-icon").click();
                        }
                    });
                    $("#treePanel").removeClass("hidden");
                }
            );

            $("#treePanel").bind("rename_node.jstree", function (e, data) {
                var folderId = data.node.data.id;
                var text = data.text;
                var oldText = data.oldText;
                if (text != "" && text == oldText)
                    return;
                $.ajax({
                    url: "../DataService.asmx/RenameFolder",
                    data: JSON.stringify({ folderId: folderId, name: text }),
                    type: "POST",
                    dataType: "json",
                    contentType: "application/json",
                    success: function () {
                        reInitializeTree();
                    }
                });
            });
        }
    }

    var globalTaskEditBusy = false;
    function showTaskEditPanel(taskId, isArchive, changeId) {
        if (typeof slider !== 'undefined') {
            slider.toggleClass('open');
        }

        globalTaskEditBusy = true;
        setTimeout(function () { checkGlobalTaskEditBusy() }, 50);
        schedules = [];
        var params = { TaskId: taskId, ChangeId: changeId, IsArchive: isArchive };
        $("#task-management-attach-point").empty();
        $("#task-management-attach-point").load("../JQueryHandler.ashx?ControlName=" + encodeURI("Controls/ManageTasks/TaskEditPanel.ascx"), params,
            function () {
                var assignments = $("#task-container .assignment-wrapper");
                for (var i = 0; i < assignments.length; i++) {
                    var newAssigneesPanel = assigneesBox($(assignments[i]));
                    var newStatusReportPanel = statusReportsBox($(assignments[i]));
                    var newSchedulingReportPanel = schedulingBox($(assignments[i]));
                    schedules.push(newSchedulingReportPanel);
                    var newAlertsPanel = alertsRemindersBox($(assignments[i]), newSchedulingReportPanel.isRecurring(), newSchedulingReportPanel.getDueOn());
                    newStatusReportPanel.populateStatusReports($("#task-container").data("checklist-id"));
                }

                bindExpandAllClick();
                bindCollapseAllClick();
                $("[data-role='change-comments']").val("");
                globalTaskEditBusy = false;
                setTimeout(function () { checkGlobalTaskEditBusy() }, 50);
            });
    }

    function checkGlobalTaskEditBusy() {
        if (globalTaskEditBusy)
            $("body").addClass("busy");        
        else
            $("body").removeClass("busy");
    }

    function changeChecklistName(checklistId, changeId, newName) {
        $.ajax({
            url: "../DataService.asmx/UpdateChecklistName",
            type: "POST",
            data: JSON.stringify({ checklistId: checklistId, changeId: changeId, newName: newName }),
            contentType: "application/json",
            success: function () {
                if (changeId <= 0) {
                    // Change the name in the tree
                    var treeLink = $('li[data-id="' + checklistId + '"] a');
                    var icon = treeLink.find('i').detach();
                    treeLink.text(newName);
                    treeLink.prepend(icon);

                    // Change the name on the panel
                    $('h3[data-role="checklist-header"]').text(newName);
                }
            }
        });
    }

    function updateChecklistName() {
        var checklistId = $("#task-container").data("checklist-id");
        var changeId = $("#task-container").data("change-id");
        var newName = $("#name-panel input").val();
        $.ajax({
            url: "../DataService.asmx/DuplicateNameCheck",
            type: "POST",
            data: JSON.stringify({
                name: newName
            }),
            dataType: "json",
            contentType: "application/json",
            success: function (response) {
                var nameOK = response.d;
                if (nameOK) {
                    changeChecklistName(checklistId, changeId, newName);
                }
                else {
                    alert("You already have a task called '" + newName + "', please choose another name.");
                }
            },
            error: function (request, status, error) {
                alert(request.responseText);
            }
        });
    }

    function deleteChecklist() {
        var name = $('h3[data-role="checklist-header"]').text();
        var checklistId = $("#task-container").data("checklist-id");
        var changeId = $("#task-container").data("change-id");
        var comment = "";
        if (changeId > 0) {
            comment = $("[data-role='change-comments']").val();
        }
        $("[data-role='change-comments']").val();
        var deleteIt = confirm("Are you sure you want to delete " + name + "?");
        if (deleteIt) {
            $.ajax({
                url: "../DataService.asmx/DeleteChecklist",
                type: "POST",
                data: JSON.stringify({ checklistId: checklistId, changeId: changeId, comment: comment }),
                contentType: "application/json",
                success: function () {
                    if (changeId < 0) {
                        $('li[data-id="' + checklistId.toString() + '"]', '.jstree').remove();
                    }
                    else {
                        $("[data-role='change-comments']").val("");
                    }
                    $("#task-management-attach-point").empty();
                    $("#btnCloseWindow").trigger("click");
                }
            });
        }
    }

    function copyChecklist() {
        var checklistId = $("#task-container").data("checklist-id");
        $.ajax({
            url: "../DataService.asmx/CopyChecklist",
            type: "POST",
            data: JSON.stringify({ checklistId: checklistId }),
            contentType: "application/json",
            success: function (data, textStatus, jqXHR) {
                var taskId = data.d;
                window.location = (self.isMobile ? "Mobile" : "") + "ManageTasks.aspx?checklistId=" + taskId;
            }
        });
    }

    function runThisNow(checklistID) {
        var popupwin = window.open("RunChecklistNow.aspx?i=" + checklistID, "checklistmini", "toolbar=no,status=yes,scrollbars=yes,resizable=yes,menubar=no,width=700,height=600,resizable=yes")
        popupwin.focus();
    }

    if ($("#requested-checklist-id").val()) {
        if ($("#requested-change-id").val())
            showTaskEditPanel($("#requested-checklist-id").val(), false, $("#requested-change-id").val());
        else
            showTaskEditPanel($("#requested-checklist-id").val(), false, -1);
    }

    function resize() {
        $("#site-main").height(($(window).height() - $("#site-nav").outerHeight() - $("#site-footer").outerHeight() - 4) + "px");
        $("#site-main").css("margin-top", ($("#site-nav").outerHeight()) + "px");
    }

    self.handleDeleteActiveChecklist = function (taskID) {
        var task = $('a[data-due-date-id="' + taskID + '"]');
        var params = {
            InstanceId: task.closest(".mtform-assignments").data('instance-id'),
            ChangeId: $("#task-container").data("change-id")
        };
        self.refreshWorkingOnNow(task, params);
    };

    return self;
};

var manageTasks = manageTasksModule();
function gotoReport(reportId, type, taskId) {
    if (typeof slider !== 'undefined') {
        if (type == 'Controller') {
            window.location.href = 'MobileMyStatus.aspx?reportID=' + reportId + '&taskID=' + taskId;
        }
        else {
            window.location.href = 'MobileInbox.aspx?reportID=' + reportId + '&taskID=' + taskId;
        }
        return;
    }

    if (type == 'Controller') {
        window.location.href = 'MyStatus.aspx?reportID=' + reportId + '&taskID=' + taskId;
    }
    else {
        window.location.href = 'MyInbox.aspx?reportID=' + reportId + '&taskID=' + taskId;
    }
}

/* Copyright © 2024 Renegade Swish, LLC */

