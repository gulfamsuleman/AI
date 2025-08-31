var newTaskModule = (function () {
    var myStatusReportsBox, myAssigneesBox, mySchedulingBox, myAlertsRemindersBox;

    $().ready(function () {
		var datepicker = $("input[data-role='datepicker']");

		if (typeof slider !== 'undefined') {
			$("#main > .row").removeClass("row");
			$("#main select").addClass("form-control");
			$(".col-xs-3, .col-xs-8, .col-md-3, .col-md-6, .col-md-8").removeClass("col-xs-3").removeClass("col-xs-8").removeClass("col-md-3").removeClass("col-md-6").removeClass("col-md-8");

			datepicker.mobiscroll().date({
				theme: getMobileOperatingSystem(),
				display: 'modal'
			});
		} else {
			datepicker.lwDatepicker();
		}

		$("#simple-controller-panel select[data-set='controllers-with-groups']").addClass("hidden");
		$("[data-role='show-all']").click(showAll);
		$("#task-name").on("keyup", checkCreateReady);
		$("[name='supervisor-controlled'],[name='customize']").on("click", checkCreateReady);
		$("#create").click(checkCreateTask);
        $("body").on("click", "#checklist-items-panel button[data-action='preview']", showPreview);
		$("#complex-task-panel").on("click", "[data-role='continue']", function () { saveComplex(); })
		$("#task-controller [name='supervisor-controlled']").change(function () {
			$("#task-controller-select").toggleClass("hidden");
			$("#task-controller2-select").toggleClass("hidden");
			$("#task-controller-me").toggleClass("hidden");
		});

		if (window.location.href.includes("NewTask.aspx")) {
			resize();
			window.onresize = resize;

		}

		$("#task-name").focus();
	});

	function resize() {
		$("#site-main").height(($(window).height() - $("#site-nav").outerHeight() - $("#site-footer").outerHeight() - 4) + "px");
		$("#site-main").css("margin-top", ($("#site-nav").outerHeight()) + "px");
	}
	
	function saveComplex() {
		var instanceId = $("[data-instance-id]").data("instance-id");
		var checklistId = $("[data-checklist-id]").data("checklist-id");
		var priority = $("#priority").val();
	    //var addToPriorityList = $("#chkAddToPriorityList").prop("checked");//added by venkat 12/05/2017
		var addToPriorityList = $("#chkAddToPriorityListComplex").prop("checked");//added by venkat 06/14/2018

		$.ajax({//added by venkat 06/14/2018
		    url: "../DataService.asmx/UpdateStatusReport",
		    type: "POST",
		    data: JSON.stringify({ statusReport: $("select[data-set='folders']").val(), statusReportSection: $("select[data-set='sections']").val() }),
		    contentType: "application/json"
		});

        $.ajax({
            url: "../DataService.asmx/ClearActiveForInstance",
            type: "POST",
            data: JSON.stringify({ instanceId: instanceId }),
            dataType: "json",
            contentType: "application/json",
        }).done(function () {
            mySchedulingBox.saveChanges(true, false);

            if (addToPriorityList)//added by venkat 12/05/2017
            {
                $.ajax({
                    url: "../DataService.asmx/AddTaskToPriorityList",
                    type: "POST",
                    data: JSON.stringify({ instanceId: instanceId }),
                    dataType: "json",
                    contentType: "application/json",
                });
            }

            var finalizationData = { checklistId: checklistId, instanceId: instanceId };
            finalizationData.firstReminderDate = null;
            if (!mySchedulingBox.isRecurring()) {
                finalizationData.firstReminderDate = $("#task-soft-due").val();
            }


            $.ajax({
                url: "../DataService.asmx/FinalizeCustomizableChecklist",
                type: "POST",
                data: JSON.stringify(finalizationData),
                dataType: "json",
                contentType: "application/json",
                success: function (response) {
                    location.reload();
                },
                error: function () {
                    alert("An error occurred while processing your request.");
                    location.reload();
                }
            });

        });
    }

	function showAll() {
		var groupSelect = $("select[data-set='controllers-with-groups']");
		var individualSelect = $("select[data-set='controllers']");
		var group1 = $(".task-controller-select select[data-set='controllers-with-groups']");
		var group2 = $(".task-controller2-select select[data-set='controllers-with-groups']");
		var indiv1 = $(".task-controller-select select[data-set='controllers']");
		var indiv2 = $(".task-controller2-select select[data-set='controllers']");

		if (individualSelect.hasClass("hidden")) {
			groupSelect.addClass("hidden");
			indiv1.val(group1.val());
			indiv2.val(group2.val());
			individualSelect.removeClass("hidden");
		} else if (groupSelect.hasClass("hidden")) {
			individualSelect.addClass("hidden");
			group1.val(indiv1.val());
			group2.val(indiv2.val());
			groupSelect.removeClass("hidden");
			$("[data-role='show-all']").addClass("hidden");
		} else {
			console.warn("This state should not be possible. This may be an indication of a page error.");
		}
	}
	
	function checkCreateReady(e) {
		var name = $("#task-name").val();
		var supervisorSelected = $("[name='supervisor-controlled']:checked").length > 0;
		var taskType = $("[name='customize']:checked").length > 0;
		if (name && supervisorSelected && taskType) {
			$("#create").removeAttr("disabled");
		}
		else {
			$("#create").attr("disabled", "disabled");
		}
	}
	
	$("#task-name").on("keyup", checkCreateReady);
	$("[name='supervisor-controlled'],[name='customize']").on("click", checkCreateReady)
	$("#set-soft-due-date").click(function () {
		if (typeof slider !== 'undefined')
			$("#task-soft-due").val($("#task-due-date").val());
		else
			$("#task-soft-due").data("lwDatepicker").setActiveDate(new Date($("#task-due-date").val()));
	});

	function checkCreateTask() {
	    $.ajax({
	        url: "../DataService.asmx/DuplicateNameCheck",
	        type: "POST",
	        data: JSON.stringify({
	            name: $("#task-name").val()
	        }),
	        dataType: "json",
	        contentType: "application/json",
	        success: function (response) {
	            var nameOK = response.d;
	            if (nameOK) {
	                createTask();
	            }
	            else {
	                alert("You already have a task called '" + $("#task-name").val() +"', please choose another name.");
	            }
	        },
			error: function (request, status, error) {
	            alert(request.responseText);
	        }
	    });
	}

	function createTask() {
	    var willCustomize = $("input[type='radio'][name='customize'][value='true']").prop("checked");
		var model = {
			AssignedTo: $("#task-assignee").val(),
			ControllerId: $("#task-controller-select select:not(.hidden)").val(),
			Controller2Id: $("#task-controller2-select:not(.hidden) select:not(.hidden)").val(),
			DueDate: $("#task-due-date").val(),
			SoftDue: $("#task-soft-due").val(),
			FolderId: $("#task-folder").val(),
			IsSelfControlled: $("#task-controller input[type='radio'][name='supervisor-controlled'][value='false']").prop("checked"),
			Name: $("#task-name").val(),
			Priority: $("#priority").val(),
			TaskType: $("#task-type").val(),
			AddToPriorityList: $("#chkAddToPriorityList").prop("checked"),//added by venkat 04/20/2017
			TemplateId: $("#task-template").val()
		};

		var assignedToName = $("#task-assignee :selected").text();

		var alertConfirmed = confirm("Assign this task to " + assignedToName + "?\n\nOnce confirmed, assignment emails will be sent within a few minutes.");

		if (alertConfirmed) {
		    if (willCustomize) {
		        
		        $("#simple-task-form").addClass("hidden");
		        $("#complex-task-panel").removeClass("hidden");
		        $("#complex-task-panel").closest(".modal-dialog").width("75%");
		        $.ajax({
		            url: "../DataService.asmx/CreateCustomizableChecklist",
		            type: "POST",
		            data: JSON.stringify({ model: model }),
		            dataType: "json",
		            contentType: "application/json",
		            success: function (response) {
		                var checklistId = response.d.ChecklistId;
		                var instanceId = response.d.InstanceId;
		                var params = { ChecklistId: checklistId, InstanceId: instanceId };
		                $("#complex-task-panel").load("../JQueryHandler.ashx?ControlName=" + encodeURI("Controls/NewTask/ComplexTask.ascx"), params, function () {
		                    myStatusReportsBox = statusReportsBox($(".status-reports-panel").parent());
		                    myStatusReportsBox.populateStatusReports(instanceId);
		                    myAssigneesBox = assigneesBox($(".assigned-to-panel").parent());
		                    mySchedulingBox = schedulingBox($(".scheduling-panel").parent());
		                    myAlertsRemindersBox = alertsRemindersBox($(".alerts-reminders-panel").parent(), mySchedulingBox.isRecurring(), mySchedulingBox.getDueOn());
                            $("#scheduling-save").addClass("hidden");
                            $(".scheduling-note").addClass("hidden");
		                    if($("#chkAddToPriorityList").prop("checked"))
		                    {
		                        $("#chkAddToPriorityListComplex").prop("checked", true);
                            }
                            //if the preview is within a modal dialog, hide it
                            $("#checklist-items-panel button[data-action='preview']", "#modal").hide();
		                });
		            },
		            error: function () {
		                alert("An error occurred while processing your request.");
		            }
		        });
		    }
		    else {
		        $.ajax({
		            url: "../DataService.asmx/CreateSimpleChecklist",
		            type: "POST",
		            data: JSON.stringify({ model: model }),
		            dataType: "json",
		            contentType: "application/json",
		            success: function (response) {
		                setTimeout(reload, 1000);
		            },
		            error: function () {
		                alert("An error occurred while processing your request.");
		            }
		        });
		    }
		}
	}

	function reload() {
	    location.reload();
	}
	
    function showPreview() {
		var currentChecklistId = $("[data-checklist-id]").data("checklist-id");
		var currentChecklistName = $("#task-name").val();

		if (typeof slider !== 'undefined') {
			slider.html(`<div style="margin:50px auto;text-align:center">Loading...please wait <img src="../images/loading.gif" /></div>`);
			slider.load("../JQueryHandler.ashx?ControlName=" + encodeURI("Controls/Shared/ChecklistPreview.ascx"), { ChecklistName: currentChecklistName, ChecklistId: currentChecklistId, changeId: -1 }, function () {
				slider.prepend("<h3>Preview</h3>");
				slider.append(`
                <div class="row mb-3 mt-3">
                    <div class="col text-center">
						<button class="btn btn-secondary close-button">Close Preview</button>
                    </div>
                </div>`);
				slider.find(".close-button").on("click", function () {
					slider.toggleClass('open');
				});
				slider.find("table").addClass("table-responsive");
			});
			slider.toggleClass('open');
			return;
		}

		modalModule.init({
			titleText: "Preview",
			controlName: "Controls/Shared/ChecklistPreview.ascx",
			remoteParams: { ChecklistName: currentChecklistName, ChecklistId: currentChecklistId, changeId: -1 }
		});
	}
})()
/* Copyright © 2024 Renegade Swish, LLC */

