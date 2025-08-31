function ShowRelatedComments(taskId) {
    window.modalModule.init({
        titleText: "Related Comments",
        controlName: 'Controls/Shared/RelatedComments.ascx',
        remoteParams: { TaskID: taskId, UserID: statusReportModule.userId }
    });
}

var statusReportModule = (function () {
    var self = {};
    var modal = null;
	self.reportId = $("#report-id").val();
	self.userId = $("#user-id").val();
	self.isConfidential = "";
	self.rightClickTaskId = "";
	self.rightClickTaskTypeId = "";

	var toolbar = null;
	var responseRequestedTaskID = -1;

	var assigneesMultiSelect = '';

	$().ready(function () {
	    modal = window.modalModule;
		toolbar = window.reportToolbarModule;

		var isMobile = typeof slider !== 'undefined';

		if (!isMobile) {
			$.contextMenu('html5');
			$("[contextmenu=subheader-menu]").dblclick(function (e) {
				$(e.target).contextMenu({ x: e.pageX, y: e.pageY });
			});
		}
		document.addEventListener("contextmenu", function (e) {

		    self.rightClickTaskId = $(e.target).closest("tr").data("id");
            // Try using data-id from the TR
		    if (self.rightClickTaskId == undefined || self.rightClickTaskId == "") {
		        self.rightClickTaskId = $(e.target).closest("tr").attr("data-id");
		    }
		    // If that didn't work, try using data-section
		    if (self.rightClickTaskId == undefined || self.rightClickTaskId == "") {
		        self.rightClickTaskId = $(e.target).attr("data-section");
		    }
		    // If that didn't work, try using data-id
		    if (self.rightClickTaskId == undefined || self.rightClickTaskId == "") {
		        self.rightClickTaskId = $(e.target).attr("data-id");
		    }

		    if ($(e.target).data("role") == "section-head"){
			self.rightClickTaskTypeId = $(e.target).data("id");
		    }

		});
		$(document).off('click', "[data-role='expand-general']").on('click', "[data-role='expand-general']", function (e) { expandGeneralComments(e); });
		$(document).off('click', "[data-role='collapse-general']").on('click', "[data-role='collapse-general']", function (e) { collapseGeneralComments(e); });
		$(document).off('click', "[data-role='expand-task']").on('click', "[data-role='expand-task']", function (e) { expandTaskComments(e); });
		$(document).off('click', "[data-role='collapse-task']").on('click', "[data-role='collapse-task']", function (e) { collapseTaskComments(e); });
		$(document).off('click', "[data-role='edit-comment']").on('click', "[data-role='edit-comment']", function (e) { self.editCommentClicked(e); });
		$(document).off('click', "[data-role='reply-to-comment']").on('click', "[data-role='reply-to-comment']", function (e) { replyToCommentClicked(e); });
		$(document).off('click', "[data-action='add-comment']").on('click', "[data-action='add-comment']", function (e) { addCommentClicked(e); });
		$(document).off('click', "tr[data-state='edit'] button[data-role='save']").on('click', "tr[data-state='edit'] button[data-role='save']", function (e) { saveButtonClick(e); });
		$(document).off('click', "tr[data-state='edit'] button[data-role='response-requested']").on('click', "tr[data-state='edit'] button[data-role='response-requested']", function (e) { responseRequestedClicked(e); });
		$(document).off('click', "tr[data-state='edit'] button[data-role='add-link']").on('click', "tr[data-state='edit'] button[data-role='add-link']", function (e) { addLinkClicked(e); });
		$(document).off('click', "button[data-role='reassign-task']").on('click', "button[data-role='reassign-task']", function(e) { reassignButtonClicked(e); });
		$(document).off('click', "button[data-role='cancel-comment']").on('click', "button[data-role='cancel-comment']", function(e) { cancelCommentClicked(e); });
		$(document).off('click', "button[data-role='reply-instead']").on('click', "button[data-role='reply-instead']", function(e) { replyInsteadClicked(e); });
		$(document).off('click', ".report-line-headings").on('click', ".report-line-headings", function (e) { reportResize(e); });
		$(".status-table tr").off('click', "a[data-role='complete-task']").on('click', "a[data-role='complete-task']", function (e) { completeTaskAjax(e); });
		$(".status-table tr").off('click', "a[data-role='na']").on('click', "a[data-role='na']", function (e) { naChecklist(e); });
		$(".status-table tr").off('click', "a[data-role='na-submit']").on('click', "a[data-role='na-submit']", function (e) { naSubmit(e); });
		$(".status-table tr").off('click', "a[data-role='reopen-task']").on('click', "a[data-role='reopen-task']", function(e) { reopenTaskAjax(e); });
		$(".status-table tr").off('click', "a[data-role='restore-task']").on('click', "a[data-role='restore-task']", function (e) { restoreTaskAjax(e); });
		$(".status-table tr").off('click', "input[data-role='take-control']").on('click', "input[data-role='take-control']", function (e) { takeControlButtonClicked(e); });
		
		// Initialize Attorney Client Status
		updateAttorneyClient();

		if (typeof slider !== 'undefined') {
			$(document).on("click", "a[data-action='single-checklist']", function (e) {
				e.preventDefault();
				var taskId = $(e.target).closest("tr").data("id");
				var isArchive = $("#IsArchive").val();
				var taskStage = isArchive ? 2 : 1;
				window.open("../ManageSingleChecklist.aspx?taskId=" + taskId + "&taskStage=" + taskStage);
			});

			$(document).off('click', "#btnCloseWindow")
				.on('click', "#btnCloseWindow",
					function (e) {
						slider.toggleClass('open');
					});
		}
	});

	function IsController(c) {
	    var TasksIControl = document.getElementById('tasks-controlled').value;
	    var arrTasksIControl = TasksIControl.split(',');
	    var Allowed = false;
	    for (i = 0; i < arrTasksIControl.length; i++)
	        if (c == arrTasksIControl[i])
	            Allowed = true;

	    return (Allowed);
	}

	function reportResize(e) {
	    modal.init({
	        titleText: "Resize",
	        controlName: "Controls/MyStatus/ResizeReport.ascx",
	        remoteParams: { ReportId: self.reportId }
	    });
	}

	function responseRequestedClicked(e) {
	    // make sure comment is not blank
	    var row = $(e.target).closest("tr.report-line-content");
	    if ($("textarea[data-role='comment']", row).val().replace(/(?:(?:^|\n)\s+|\s+(?:$|\n))/g, '').replace(/\s+/g, ' ') == "") {
	        alert("Selected comment is empty. Please click on one of your recent comments and try again.");
	        return;
	    }
		responseRequestedTaskID = $(e.target).closest(".report-line-content").data("id");
		saveButtonClick(e);
        // The modal window to choose recipients, etc. opens on success from the save button click if responseRequestedTaskID != -1
	}

    // N/A button clicked
	function naChecklist(e) {
	    $(e.target).closest("tr").find(".na-row").show();
	}

    // N/A submit
	function naSubmit(e) {

	    if ($(e.target).closest("tr").find(".na-reason").val() == "") {
	        alert("You must provide a reason for closing this task as N/A");
	    } else {
	        completeTaskAjax(e);
	    }
        
	}

	function CheckPopup(task, na, naReason) {
		$.ajax({
			url: "../DataService.asmx/RequirePopup",
			type: "POST",
			data: "",
			dataType: "json",
			async: true,
			contentType: "application/json",
			success: function (response) {
				if (response.d.length > 0) {
					$.prompt(response.d, {
						buttons: { "Yes": true, "No": false },
						submit: function (z, v, m, f) {
							z.preventDefault();
							$.prompt.close();
							if (v) {
								completeTaskProceed(task, na, naReason);
							}
						}
					});
				}
				else {
					completeTaskProceed(task, na, naReason);
				}
			},
			error: function (xhr, status, e) {
				return;
			}
		});
	}

	// Completing a Task
	function completeTaskAjax(e) {
		var task = $(e.target).closest("tr");
	    var na = ($(e.target).data("role") == "na-submit");
		var naReason = $(e.target).closest("tr").find(".na-reason").val();


		//console.log("Task:", task);
		//console.log("NA:", na);
		//console.log("NA Reason:", naReason);

		if (na) {
			completeTaskProceed(task, na, naReason);
		}
		else {
			//alert('task: ' + task + ', na: ' + na + ', naReason: ' + naReason);
			CheckPopup(task, na, naReason);
		}
	}
        
	function completeTaskProceed(task, na, naReason) {
		$.ajax({
			url: "../DataService.asmx/CompleteTask",
			type: "POST",
			data: JSON.stringify({
				userId: self.userId,
				reportId: self.reportId,
				taskId: task.data("id"),
				na: na,
				naReason: naReason
			}),
			dataType: "json",
			contentType: "application/json",
			success: function (response) {
				moveTask(task, response.d, true);
			},
	        error: function () {
				alert("An error occurred while processing your request.");
			}
		});
	}

	// Reopening a Task
	function reopenTaskAjax(e) {
		var task = $(e.target).closest("tr");
		$.ajax({
			url: "../DataService.asmx/ReOpenTask",
			type: "POST",
			data: JSON.stringify({
				reportId: self.reportId,
				taskId: task.data("id")
			}),
			dataType: "json",
			contentType: "application/json",
			success: function (response) {
				moveTask(task, response.d, false);
			},
			error: function() {
				alert("An error occurred while processing your request.");
			}
		});
	}

	// Restore Task
	function restoreTaskAjax(e) {
		var task = $(e.target).closest("tr");
		$.ajax({
			url: "../DataService.asmx/RestoreTask",
			type: "POST",
			data: JSON.stringify({
				taskId: task.data("id")
			}),
			dataType: "json",
			contentType: "application/json",
			success: function(response) {
				task.remove();
			},
			error: function() {
				alert("An error occurred while processing your request.");
			}
		});
	}

	function moveTask(task, response, isComplete) {
		// Ensure response is a string
		if (typeof response !== 'string') {
			response = JSON.stringify(response);

			// Extract the section name from the response
			var sectionNameMatch = response.match(/"Result":"([^"]+)"/);

			if (sectionNameMatch) {
				response = sectionNameMatch[1];
			}
		}

		if (response.indexOf("|") == -1) {
			alert(response);
		} else {
			var button = task.find("td:first");
			var temp = response.split("|");
			var sectionId;
			var sectionName;
			if (isComplete) { // Completing a task
				sectionId = "C" + temp[0];
				sectionName = temp[1];
				button.html("<a data-role='reopen-task'><img src='/Images/reopen_sm.gif' /></a>");
			} else { // Reopening a task
				sectionId = temp[0];
				sectionName = temp[1];
				button.html("<span class='hidden data-label'>Action</span><a data-role='complete-task' title='Complete Task'><img src='/Images/complete.gif' /></a><a data-role='na' title='N/A - Close Task' style='margin-left: 4px;'><i class='fa' style='color: #FF2551'>n/a</i></a><br><div class='na-row'><textarea class= 'na-reason' placeholder = 'Reason for N/A' rows = '5'></textarea><br><a data-role='na-submit' class='btn btn-default'><i class='fa fa-ban' style='color:#FF2551'></i> N/A - Close Task</a></div>");
			}
			var sectionTable = $("td[data-section='" + sectionId + "']").closest("table");

			// Derive the old section ID based on the destination section ID
			var oldSectionId;
			if (sectionId.startsWith("C")) {
				oldSectionId = sectionId.substring(1);
			} else {
				oldSectionId = "C" + sectionId;
			}

			// Check to see if table currently exists
			if (sectionTable.length != 0) {
				var taskPriority = task.data("priority");
				var taskRows = sectionTable.find("tr[data-priority]");
				// Go up the rows from the bottom to prevent multi-direction looping
				for (var i = taskRows.length - 1; i >= 0; i--) {
					var currentRowPriority = $(taskRows[i]).data("priority");
					// Check to see if moving task is the same priority
					if (taskPriority == currentRowPriority) {
						var taskDate = new Date(task.data("due-date"));
						var currentDate = new Date($(taskRows[i]).data("due-date"));
						// if the moving task date is after the current task date then insert after
						if (taskDate > currentDate) {
							$(taskRows[i]).after(task);
							updateTaskCount(sectionId);
							updateTaskCount(oldSectionId);
							return;
						}
					} else if (currentRowPriority < taskPriority) {
						// Handles the case where date is too new for insertion into priority
						// Also handles the case where no priorities exist for the moving task
						$(taskRows[i]).after(task);
						updateTaskCount(sectionId);
						updateTaskCount(oldSectionId);
						return;
					}
				}
				// Does not meet any other criteria, it must be first element in the list
				taskRows.first().before(task);
				updateTaskCount(sectionId);
				updateTaskCount(oldSectionId);
			} else {
				// Table does not exist, time to make it
				var tableTemplate =
					"<table class='status-table collapsible-item' data-collapse-state='expanded'>" +
					"<thead>" +
					"<tr>" +
					"<td colspan='7' class='report-line-subheader noselect completed-task' data-section='{0}'><i class='fa fa-minus-square-o' data-role='expand-indicator' data-collapse-target='true'></i>{1}</td>" +
					"</tr>" +
					"</thead>" +
					"<tbody class='expanded'>" +
					"<tr class='report-line-content multiple-collapse-member'>" +
					"<th class='report-line-headings report-line-border report-line-headings-action'></th>" +
					"<th class='report-line-headings report-line-border report-line-headings-priority'></th>" +
					"<th class='report-line-headings report-line-border report-line-headings-task' style='width: 10%;'>Task</th>" +
					"<th class='report-line-headings report-line-border report-line-headings-deadline'>Due</th>" +
					"<th class='report-line-headings report-line-border report-line-headings-assignees" + assigneeViewClass(task) + "'>Assignees/Controllers</th>" +
					"<th class='report-line-headings report-line-border report-line-headings-progress' style='width: 70%;'>Progress</th>" +
					"</tr>" +
					"<tr class='report-line-ender'>" +
					"<td colspan='7'></td>" +
					"</tr>" +
					"</tbody>" +
					"</table>";
				var newTable;
				if (isComplete) {
					newTable = $(format(tableTemplate, sectionId, "Completed - " + sectionName));
					task.closest("table").after(newTable);
					newTable.find("th").closest("tr").after(task);
				} else {
					newTable = $(format(tableTemplate, sectionId, sectionName));
					task.closest("table").before(newTable);
					newTable.find("th").closest("tr").after(task);
				}
				updateTaskCount(sectionId);
				updateTaskCount(oldSectionId);
			}
		}
	}

	function updateTaskCount(sectionId) {
		var sectionHeader = $("td[data-section='" + sectionId + "']");
		var taskCount = sectionHeader.closest("table").find("tr[data-priority]").length;
		var sectionTitle = sectionHeader.text().split('(')[0].trim();
		sectionHeader.text(sectionTitle + " (" + taskCount + ")");
	}

	//function moveTask(task, response, isComplete) {
	//	// Ensure response is a string
	//	if (typeof response !== 'string') {
	//		response = JSON.stringify(response);
	//	}

	//	// Try to parse the response to extract sectionId and sectionName
	//	var parsedResponse;
	//	try {
	//		parsedResponse = JSON.parse(response);
	//	} catch (e) {
	//		// Handle plain string response
	//		if (response.indexOf('|') !== -1) {
	//			parsedResponse = { Result: response };
	//		} else {
	//			return;
	//		}
	//	}

	//	// Ensure parsedResponse contains the expected properties
	//	if (!parsedResponse.Result) {
	//		return;
	//	}

	//	// Split the Result field to extract sectionId and sectionName
	//	var resultParts = parsedResponse.Result.split('|');
	//	if (resultParts.length < 2) {
	//		return;
	//	}

	//	var sectionId = resultParts[0];
	//	var sectionName = resultParts[1];

	//	// Update sectionId for completed tasks
	//	if (isComplete) {
	//		sectionId = "C" + sectionId;
	//	}

	//	// Remove everything after the final space in the section name
	//	var lastSpaceIndex = sectionName.lastIndexOf(" ");
	//	if (lastSpaceIndex !== -1) {
	//		sectionName = sectionName.substring(0, lastSpaceIndex);
	//	}

	//	var sectionTable = $("td[data-section='" + sectionId + "']").closest("table");

	//	// Identify the old section and update its task count
	//	var oldSectionId = task.closest("td[data-section]").data("section");
	//	updateTaskCount(oldSectionId);

	//	// Remove the task from its current position
	//	task.remove();

	//	// Update the task count for the old section after removing the task
	//	updateTaskCount(oldSectionId);

	//	// Update the data-role attribute
	//	var actionCell = task.find("td[data-role='action']");
	//	if (isComplete) {
	//		actionCell.html(`
 //           <span class="hidden data-label">Action</span>
 //           <a data-role="reopen-task" title="Reopen Task"><img src="/Images/reopen_sm.gif"></a>
 //       `);
	//	} else {
	//		actionCell.html(`
 //           <span class="hidden data-label">Action</span>
 //           <a data-role="complete-task" title="Complete Task"><img src="/Images/complete.gif"></a>
 //           <a data-role="na" title="N/A - Close Task"><i class="fa" style="color:#FF2551">n/a</i></a><br>
 //           <div class="na-row">
 //               <textarea class="na-reason" placeholder="Reason for N/A" rows="5"></textarea><br>
 //               <a data-role="na-submit" class="btn btn-default"><i class="fa fa-ban" style="color:#FF2551"></i> N/A - Close Task</a>
 //           </div>
 //       `);
	//	}

	//	// Check to see if table currently exists
	//	if (sectionTable.length != 0) {
	//		var taskPriority = task.data("priority");
	//		var taskRows = sectionTable.find("tr[data-priority]");
	//		// Go up the rows from the bottom to prevent multi-direction looping
	//		for (var i = taskRows.length - 1; i >= 0; i--) {
	//			var currentRowPriority = $(taskRows[i]).data("priority");
	//			// Check to see if moving task is the same priority
	//			if (taskPriority == currentRowPriority) {
	//				var taskDate = new Date(task.data("due-date"));
	//				var currentDate = new Date($(taskRows[i]).data("due-date"));
	//				// if the moving task date is after the current task date then insert after
	//				if (taskDate > currentDate) {
	//					$(taskRows[i]).after(task);
	//					updateTaskCount(sectionId);
	//					return;
	//				}
	//			} else if (currentRowPriority < taskPriority) {
	//				// Handles the case where date is too new for insertion into priority
	//				// Also handles the case where no priorities exist for the moving task
	//				$(taskRows[i]).after(task);
	//				updateTaskCount(sectionId);
	//				return;
	//			}
	//		}
	//		// Does not meet any other criteria, it must be first element in the list
	//		taskRows.first().before(task);
	//		updateTaskCount(sectionId);
	//	} else {
	//		// Table does not exist, time to make it
	//		var tableTemplate =
	//			"<table class='status-table collapsible-item' data-collapse-state='expanded'>" +
	//			"<thead>" +
	//			"<tr>" +
	//			"<td colspan='7' class='report-line-subheader noselect completed-task' data-section='{0}'><i class='fa fa-minus-square-o' data-role='expand-indicator' data-collapse-target='true'></i>{1}</td>" +
	//			"</tr>" +
	//			"</thead>" +
	//			"<tbody class='expanded'>" +
	//			"<tr class='report-line-content multiple-collapse-member'>" +
	//			"<th class='report-line-headings report-line-border report-line-headings-action'></th>" +
	//			"<th class='report-line-headings report-line-border report-line-headings-priority'></th>" +
	//			"<th class='report-line-headings report-line-border report-line-headings-task' style='width: 10%;'>Task</th>" +
	//			"<th class='report-line-headings report-line-border report-line-headings-deadline'>Due</th>" +
	//			"<th class='report-line-headings report-line-border report-line-headings-assignees" + assigneeViewClass(task) + "'>Assignees/Controllers</th>" +
	//			"<th class='report-line-headings report-line-border report-line-headings-progress' style='width: 70%;'>Progress</th>" +
	//			"</tr>" +
	//			"<tr class='report-line-ender'>" +
	//			"<td colspan='7'></td>" +
	//			"</tr>" +
	//			"</tbody>" +
	//			"</table>";
	//		var newTable;
	//		if (isComplete) {
	//			newTable = $(format(tableTemplate, sectionId, "Completed - " + sectionName));
	//			task.closest("table").after(newTable);
	//			newTable.find("th").closest("tr").after(task);
	//		} else {
	//			newTable = $(format(tableTemplate, sectionId, sectionName));
	//			task.closest("table").before(newTable);
	//			newTable.find("th").closest("tr").after(task);
	//		}
	//		updateTaskCount(sectionId);
	//	}
	//}

	//function updateTaskCount(sectionId) {
	//	var sectionHeader = $("td[data-section='" + sectionId + "']");
	//	var taskCount = sectionHeader.closest("table").find("tr[data-priority]").length;
	//	var sectionTitle = sectionHeader.text().split('(')[0].trim();
	//	sectionHeader.text(sectionTitle + " (" + taskCount + ")");
	//}

	function assigneeViewClass(task) {
	    if (task.find("td.report-line-assignees-content").first().hasClass("hidden")) {
	        return " hidden";
	    } else {
	        return "";
	    }
	}

	function reassignButtonClicked(e) {
	    var row = $(e.target).closest("tr");
	    var taskId = row.data("id");
		var assigneesCell = $("td[data-role='assignees']", row);
		var assigneesSpan = $("span[data-role='assignees-span']", assigneesCell);
		var assignButton = $("button[data-role='reassign-task']", assigneesCell);
		assigneesSpan.addClass("hidden");
		assignButton.addClass("hidden");
		if (assigneesMultiSelect.length == 0)
		{
		    $.ajax({
		        url: "../JQueryHandler.ashx?ControlName=" + encodeURI("Controls/Shared/AssigneesMultiSelect.ascx"),
		        type: "GET",
		        async: false,
		        success: function (htmlResult) {
		            assigneesMultiSelect = htmlResult;
		        }
		    });
		}
		var newDiv = $("<div>").addClass("new-assignment").appendTo(assigneesCell);
		newDiv.html(assigneesMultiSelect);
		var a = $("span[data-role='assignees-span']", row).text().split(" / ");
		var currentAssignees = a[0].trim().split(',');
		for (var i = 0; i < currentAssignees.length; i++) {
		    $('#reassign-select option:contains("' + currentAssignees[i].trim() + '")').attr("selected", "selected");
		}
		if (!IsController(taskId)) {
		    var newCommentLabel = $("<label>").addClass("new-assignment-comment-label").html("Comments:");
		    var newCommentSection = $("<input type='text'/>").addClass("new-assignment-comment-input");
		    newDiv.after(newCommentLabel);
		    newCommentLabel.after(newCommentSection);
		}
		
	}
	
	self.editCommentClicked = function (e) {
		if (checkForCommentOpen())
			return;
		var commentsCell = $(e.target).closest("tr");
		var comment = $(e.target).closest(".comment-line");
		var commentId = comment.data("id");
		if (comment.data("user-id") == self.userId) {
			commentsCell.data("mode", "edit-comment");
			commentsCell.data("edit-comment-id", commentId);
			convertToEditCommentRow(e, commentId);
		}
	}

	function replyToCommentClicked(e) {
		if (checkForCommentOpen())
			return;
		replyToCommentClickedGeneric($(e.target));
	}
	
	function replyToCommentClickedGeneric(commentclicked) {
		
		var commentsCell = commentclicked.closest("tr");
		var comment = commentclicked.closest(".comment-line");
		var commentId = comment.data("id");
		commentsCell.data("mode", "reply-comment");
		commentsCell.data("reply-comment-id", commentId);
		convertToReplyCommentRow(commentsCell, commentId);
	}
	
	function addCommentClicked(e) {
		if (checkForCommentOpen(e.target))
			return;
		convertToAddCommentRow(e);
		$(e.target).closest("tr").data("mode", "new-comment");
	}
	
	function checkForCommentOpen(target) {
		if ($("tr[data-state='edit']", document).length > 0) {
			if($(target).closest("tr").attr("data-state") != 'edit')
				alert("You already have a comment open.");
			return true;
		}
	}

	function replyInsteadClicked(e){
		var commentID = $(e.target).closest("tr.report-line-content").data("edit-comment-id");
		cancelCommentClicked(e);
		var replyToSpan = $("div[data-id="+commentID+"]").find("span[data-role='comment-text']")
		replyToCommentClickedGeneric(replyToSpan);
	}

	function cancelCommentClicked(e) {
		var row = $(e.target).closest("tr.report-line-content");
	    $("[data-role='soft-due-input']", row).val($("[data-role='soft-due-input']", row).attr("orig-val"))
	    $("[data-role='due-date-input']", row).val($("[data-role='due-date-input']", row).attr("orig-val"));
		cleanUpEditDomElements(row);
		rebuildRemovedDomElements(row);
		row.attr("data-state", "view");
	}

	function saveButtonClick(e) {
		var row = $(e.target).closest("tr.report-line-content");
		var state = row.attr("data-state");
		var currentDueDate = $("input[data-role='due-date-input']").val();
		var currentSoftDue = $("input[data-role='soft-due-input']").val();
		var currentPriority = $("input[data-role='priority-input']").val();
		var comments = $("textarea[data-role='comment']", row).val();
		var description = $("[data-role='task-name'] input", row).val();
		var oldDescription = $("[data-role='task-name'] a", row).text();
		var isReassigning = $("#reassign-select").length > 0;
		var isGeneral = row.data("general");
		var updateData = {};
		if (description) description = description.trim();
		if (oldDescription) oldDescription = oldDescription.trim();

		updateData.taskId = row.data("id");
		updateData.comments = comments;
		updateData.description = "";
		updateData.dueDate = null;
		updateData.commentId = 0;
		updateData.priority = null;
		updateData.newAssignees = null;
		updateData.newAssigneesNames = null;
		updateData.newAssigneesComments = "";
		updateData.isReply = false;
		if (isGeneral) {
			updateData.reminderDate = null;
			updateData.isGeneralComment = true;
		} else {
		    updateData.isGeneralComment = false;
		    if (description != oldDescription) {
		        updateData.description = description;
		        $("[data-role='task-name'] a", row).text($("[data-role='task-name'] input", row).val());
		    }
		}
		if (isReassigning) {
		    updateData.newAssignees = $("#reassign-select").val();
		    var names = [];
		    $("#reassign-select :selected").each(function (i, selected) {
		        names[i] = $(selected).text();
		    });
		    updateData.newAssigneesNames = names;
		    var assigneeComment = '';
		    if ($("input.new-assignment-comment-input", row).length > 0) {
		        assigneeComment = $("input.new-assignment-comment-input", row).val()
		    }
		    updateData.newAssigneesComments = assigneeComment;
		}
		if (currentDueDate) {
		    updateData.dueDate = currentDueDate;
		}
		if (currentSoftDue) {
		    updateData.reminderDate = currentSoftDue;
		}
		if (currentPriority) {
			if (row.data("priority") != currentPriority) {
				updateData.priority = currentPriority;
			}
		}
		
		var commentId;
		if (row.data("mode") == "reply-comment") {
			commentId = row.data("reply-comment-id");
			updateData.commentId = commentId;
			updateData.isReply = true;
		}
		if (row.data("mode") == "edit-comment") {
			commentId = row.data("edit-comment-id");
			updateData.commentId = commentId;
		}
		if (updateData.priority || updateData.reminderDate || isGeneral || updateData.description != "") {
			$.ajax({
				url: "../DataService.asmx/SaveTaskUpdates",
				type: "POST",
				data: JSON.stringify(updateData),
				contentType: "application/json",
				error: function(jqXHR, textStatus, errorThrown) {
				    alert("There was a problem saving your comment\n\n" + textStatus + ": " + errorThrown);
				},
				success: function (data) {
					if (updateData.priority) {
						//order might have changed. have to reload the page.
						window.location.reload();
					} else {
					    if (updateData.reminderDate) {
						    row.attr("data-soft-due", updateData.reminderDate);
						}
						
						if (updateData.priority) {
							row.attr("data-priority", updateData.priority);
						}
						if (isReassigning && (IsController(updateData.taskId))) {
						    var a = $("span[data-role='assignees-span']", row).text().split(" / ");
						    $("span[data-role='assignees-span']", row).text(updateData.newAssigneesNames + " / " + a[1].trim());
						}
						if (data.d)//if we got a returned comment info
						{
							if (row.data("mode") == "edit-comment") {
								var editedComment = row.find("[data-id='" + data.d.Id + "']");
								editedComment.find("[data-role='comment-text']").html(parseLinks(comments.replace(/\n/g, "<br>")));
								editedComment.removeClass("hidden");
							} else {
							    var newComment = $("<div>").attr({
									"data-role": "edit-comment",
									"data-id": "" + data.d.Id
							    });
							    newComment.addClass("comment-line sd" + $("#comment-color-num").val());
								
								var htmlToAdd = format("[<span data-role='comment-date'>{0}</span>] [{1}] <span data-role='comment-text'>{2}</span>",
									//Problematic new Date() uses; leaving for now as they're client-side dynamic 
									//and the value is replaced by a report reload (which happens a lot)
									format("{0}/{1}/{2}", new Date().getMonth() + 1, new Date().getDate(), new Date().getFullYear()),
									data.d.Initials,
									parseLinks(comments));
								newComment.html(htmlToAdd.replace(/\n/g, "<br>"));
								if (updateData.commentId) {
									var repliedComment = $("div[data-id='" + commentId + "']");
									var tabIn = parseFloat(repliedComment.css("padding-left")) + 30;
									newComment.css("padding-left", tabIn + "px");
									repliedComment.after(newComment);
								} else {
								    $("[data-role='comments'] a[data-action='injection-point']:last", row).before(newComment);
								}

								var div = $("div[data-id='" + data.d.Id + "']");
								div.data("user-id", statusReportModule.userId);
								div.data("id", data.d.Id);
							}
						}
						cleanUpEditDomElements(row);
						rebuildRemovedDomElements(row);
						row.attr("data-state", "view");
						if (responseRequestedTaskID != -1) {

							if (typeof slider !== 'undefined') {
								var params = {
									mode: "report",
									ReportId: self.reportId,
									isUrgent: true,
									TaskId: responseRequestedTaskID
								};

								$(".buttons").toggleClass("hidden");
								slider.html(`<div style="margin:50px auto;text-align:center">Loading...please wait <img src="../images/loading.gif" /></div>`);
								slider.load("../JQueryHandler.ashx?ControlName=" + encodeURI("Controls/MyStatus/EmailComments.ascx"), params,
									function () {
										slider.html(slider.html().replace(/h3/g, "h4"));
										slider.prepend("<h3>Response Requested</h3>");
										slider.append("&nbsp;&nbsp;&nbsp;&nbsp;<button id='btnCloseWindow' class='btn btn-secondary'>Close Window</button>");
										slider.find("button[data-action=send-email]").addClass("btn btn-success")
										slider.find("button[data-action=prev-email]").addClass("btn btn-info")
									});
								slider.toggleClass('open');
								return;
							}
							else {
								var params = {
									mode: "report",
									ReportId: toolbar.reportId,
									isUrgent: true,
									TaskId: responseRequestedTaskID
								};
								responseRequestedTaskID = -1;
								toolbar.openEmailModal(params, "Response Requested");
							}
						}
					}
				}
			});
		} else {
			cleanUpEditDomElements(row);
			rebuildRemovedDomElements(row);
			row.attr("data-state", "view");
		}
	}

	function rebuildRemovedDomElements(row) {
		var priority = row.data("priority");
		var softDue = $("[data-role='soft-due-input']", row).val();
		var dueDate = $("[data-role='due-date-input']", row).val();

		if (softDue) softDue = softDue.trim();
		if (dueDate) dueDate = dueDate.trim();

		$("td[data-role='priority']", row).html(`<span class="hidden data-label">Priority</span>` + priority);
		var softDueTag = "";
		var dueDateTag = "";
		if (softDue != dueDate) {
		    softDueTag = $("<span data-action='add-comment' class='reminderspan'>" + softDue + "</span>");
		}

		if (Date.parse(dueDate) <= Date.parse(new Date(Date.now()).toLocaleDateString())) {		
		    dueDateTag = $("<span data-action='add-comment' class='overduespan'>" + dueDate + "</span>");
		} else {
		    dueDateTag = $("<span data-action='add-comment'>" + dueDate + "</span>");
		}
		
		$("td[data-role='due-date']", row).html("").append(softDueTag).append(dueDateTag);

		$("td[data-role='assignees'] span[data-role='assignees-span']", row).removeClass("hidden");
        //BUG::instead of showing the div, remove div with blank comments
	    //$("[data-role='edit-comment']", row).removeClass("hidden");
        // Updated code below
		$("[data-role='edit-comment']", row).each(function () {
		    if ($(this).find("[data-role='comment-text']").text() == "")
		        $(this).remove();
		    else
		        $(this).removeClass("hidden");
		});

		$("[data-role='task-name'] a", row).show();
		$("[data-role='task-name'] input", row).hide();

		$(document).off('click', "[data-action='add-comment']").on('click', "[data-action='add-comment']", function (e) { addCommentClicked(e); });
	}

	function cleanUpEditDomElements(row) {
		$("button[data-role='reassign-task']", row).remove();
		$("input[data-role='priority']", row).remove();
		$("input[data-role='due-date']", row).remove();
		$("p[data-role='warning']", row).remove();
		$("textarea[data-role='comment']", row).remove();
		$("button[data-role='save']", row).remove();
		$("button[data-role='response-requested']", row).remove();
		$("button[data-role='add-link']", row).remove();
		$("button[data-role='cancel-comment']", row).remove();
		$("button[data-role='reassign-task']", row).remove();
		$("div.new-assignment", row).remove();
		$("label.new-assignment-comment-label", row).remove();
		$("input.new-assignment-comment-input", row).remove();
		$("div[ data-role='comment-buttons']", row).remove();

		row.find("td[data-role='comments']").children().removeClass("yellow-background");
		//let searchCriteria = $("#txtSearchInput").val().trim();
		//if (searchCriteria.length > 0) { highlightSearchResults(row, searchCriteria); }
	}

	function cleanLinks(str) {
	    var pt1 = str.indexOf('<!--a1-->');
	    var pt2 = str.indexOf('<!--/a1-->');
	    var pt3 = str.indexOf('<!--a2-->');
	    var pt4 = str.indexOf('<!--/a2-->');

	    if ((pt1 >= 0) && (pt2 >= 0) && (pt3 >= 0) && (pt4 >= 0))
	        str = str.substring(0, pt1) + '[link]' + str.substring(pt2 + 10, pt3) + '[/link]' + cleanLinks(str.substring(pt4 + 10, str.length));

		str = str.replace(/<br>/g, '\n');

		const span = document.createElement('span');
		span.innerHTML = str;
		removeHighlighting(span);
		str = span.innerHTML;
		span.remove();
	    return str;
	}

	function parseLinks(t)
	{
        var keepEnd;
	    var keepStart;
	    var linkPart;
	    while (t.indexOf("[link]") > -1 && t.indexOf("[/link]") > -1) {
    	    keepEnd = t.substring(t.indexOf("[/link]") + 7);
	        keepStart = t.substring(0, t.indexOf("[link]"));
            linkPart = t.substring(t.indexOf("[link]") + 6, t.indexOf("[/link]"));
	        t = keepStart + "<!--a1--><a href='" + linkPart + "' target='_new' onclick='event.cancelBubble=true;'><!--/a1-->" + linkPart + "<!--a2--></a><!--/a2-->" + keepEnd;
		}
    	return t;
	}


	/*function removeHighlighting(node) {
		
		const spans = node.querySelectorAll('span.searchhighlight');
		spans.forEach(span => {
			span.outerHTML = span.innerHTML; // Replace the span with its contents
		});
	}*/


	function removeHighlighting(node) {
		// Base case: If the node itself is a highlight span, process it
		if (node.nodeType === Node.ELEMENT_NODE && node.classList.contains('searchhighlight')) {
			// Create a temporary container to store the node's children
			const fragment = document.createDocumentFragment();

			// Move all children of the node to the fragment
			while (node.firstChild) {
				fragment.appendChild(node.firstChild);
			}

			// Replace the node with its children
			node.parentNode.replaceChild(fragment, node);

			// Continue processing the children of the fragment
			Array.from(fragment.childNodes).forEach(child => {
				removeHighlighting(child);
			});
		} else {
			// Recursive case: Process each child node
			Array.from(node.childNodes).forEach(child => {
				removeHighlighting(child);
			});
		}
	}

	function addLinkClicked(e) {
	    var row = $(e.target).closest("tr.report-line-content");
	    var browse = $("#browse", row);
	    var comment = $("textarea[data-role='comment']", row);
	    comment.val(comment.val() + ' [link][/link] ');
	    comment.focus();
	    comment.prop('selectionEnd', comment.val().length - 8);
	    //browse.click();
	    //if (browse.val() != '') {
	    //    comment.val(comment.val() + ' [link]' + browse.val() + '[/link] ');
	    //}
	}

	function convertToReplyCommentRow(tr, commentId) {
	    var commentsCell = tr.find("[data-role='comments']");
	    var targetComment = commentsCell.find("[data-id='" + commentId + "']");
	    targetComment.addClass("yellow-background");

	    buildCommentRow(tr);

        var warningText = $("<p data-role='warning' class='yellow-background' style='font-weight:bold;'>Replying to the comment highlighted in yellow.</p>");
        var commentField = $("<textarea onkeyup='checkchars(this)' style='width:100%;color:" + $("#comment-color").val() + ";'>").attr("data-role", "comment");
        var buttondiv = $("<div data-role='comment-buttons'></div>");
        var browseField = $("<input onclick='event.cancelBubble=true;' id='browse' style='display: none;' type='file' name='browse'>");
       
        var saveButton = $("<button class='btn btn-default btn-sm'>Save</button>").attr("data-role", "save");
        var responseRequestedButton = $("<button class='btn btn-default btn-sm'>Response Requested</button>").attr("data-role", "response-requested");
        var addLinkButton = $("<button class='btn btn-default btn-sm'>Add Link</button>").attr("data-role", "add-link");
        var cancelButton = $("<button class='btn btn-default btn-sm'>Cancel</button>").attr("data-role", "cancel-comment");

        var saveButtonDiv = $("<div style='display:inline-block;width:30%;'/>");
        var responseRequestedButtonDiv = $("<div style='display:inline-block;width:34%;'/>");
        var addLinkButtonDiv = $("<div style='display:inline-block;width:18%;'/>");
        var cancelButtonDiv = $("<div style='text-align:right;width:18%;display:inline-block;'>");

		warningText.insertAfter(targetComment);
		commentField.insertAfter(warningText);
		buttondiv.insertAfter(commentField);
		browseField.appendTo(buttondiv);
		saveButtonDiv.appendTo(buttondiv);
		responseRequestedButtonDiv.appendTo(buttondiv);
		addLinkButtonDiv.appendTo(buttondiv);
		cancelButtonDiv.appendTo(buttondiv);

		saveButton.appendTo(saveButtonDiv);
		responseRequestedButton.appendTo(responseRequestedButtonDiv);
		addLinkButton.appendTo(addLinkButtonDiv);
		cancelButton.appendTo(cancelButtonDiv);

		tr.attr("data-state", "edit");
		commentField.focus();
	}
	
	function convertToEditCommentRow(e, commentId) {
	    var tr = $(e.target).closest("tr");
	    var commentsCell = tr.find("[data-role='comments']");
	    var targetComment = commentsCell.find("[data-id='" + commentId + "']");

	    buildCommentRow(tr);

	    var commentField = $("<textarea onkeyup='checkchars(this)' style='width:100%;color:" + $("#comment-color").val() + ";'>").attr("data-role", "comment");
		commentField.val(cleanLinks(targetComment.find("[data-role='comment-text']").html()));
		targetComment.addClass("hidden");
		var buttondiv = $("<div data-role='comment-buttons'></div>");
		var browseField = $("<input onclick='event.cancelBubble=true;' id='browse' style='display: none;' type='file' name='browse'>");

		var saveButton = $("<button class='btn btn-default btn-sm'>Save</button>").attr("data-role", "save");
		var responseRequestedButton = $("<button class='btn btn-default btn-sm'>Response Requested</button>").attr("data-role", "response-requested");
		var addLinkButton = $("<button class='btn btn-default btn-sm'>Add Link</button>").attr("data-role", "add-link");
		var replyButton = $("<button class='btn btn-default btn-sm'>Reply</button>").attr("data-role", "reply-instead");
		var cancelButton = $("<button class='btn btn-default btn-sm'>Cancel</button>").attr("data-role", "cancel-comment");

		var saveButtonDiv = $("<div style='display:inline-block;width:20%;'/>");
		var responseRequestedButtonDiv = $("<div style='display:inline-block;width:27%;'/>");
		var addLinkButtonDiv = $("<div style='display:inline-block;width:14%;'/>");
		var replyButtonDiv = $("<div style='text-align:right;display:inline-block;width:13%;'/>");
		var cancelButtonDiv = $("<div style='text-align:right;width:24%;display:inline-block;'>");

		commentField.insertAfter(targetComment);
		buttondiv.insertAfter(commentField);
		browseField.appendTo(buttondiv);
		saveButtonDiv.appendTo(buttondiv);
		responseRequestedButtonDiv.appendTo(buttondiv);
		addLinkButtonDiv.appendTo(buttondiv);
		replyButtonDiv.appendTo(buttondiv);
		cancelButtonDiv.appendTo(buttondiv);

		saveButton.appendTo(saveButtonDiv);
		responseRequestedButton.appendTo(responseRequestedButtonDiv);
		addLinkButton.appendTo(addLinkButtonDiv);
		replyButton.appendTo(replyButtonDiv);
		cancelButton.appendTo(cancelButtonDiv);

		tr.attr("data-state", "edit");
		commentField.focus();
	}

	function convertToAddCommentRow(e) {
	    var tr = $(e.target).closest("tr");
	    var injectPoint = tr.find("a[data-action='injection-point']");

		buildCommentRow(tr);

		var warningText = $("<p data-role='warning' class='yellow-background' style='font-weight:bold;'>Warning: You are creating a new comment. ARE YOU SURE YOU WANT TO DO THIS? If you want to reply to an existing comment, click 'Cancel', then click on the text you want to reply to.</p>");
		var commentField = $("<textarea onkeyup='checkchars(this)' style='width:100%;color:" + $("#comment-color").val() + ";'>").attr("data-role", "comment");
		var buttondiv = $("<div data-role='comment-buttons'></div>");
		var browseField = $("<input onclick='event.cancelBubble=true;' id='browse' style='display: none;' type='file' name='browse'>");

		var saveButton = $("<button class='btn btn-default btn-sm'>Save</button>").attr("data-role", "save");
		var responseRequestedButton = $("<button class='btn btn-default btn-sm'>Response Requested</button>").attr("data-role", "response-requested");
		var addLinkButton = $("<button class='btn btn-default btn-sm'>Add Link</button>").attr("data-role", "add-link");
		var cancelButton = $("<button class='btn btn-default btn-sm'>Cancel</button>").attr("data-role", "cancel-comment");

		var saveButtonDiv = $("<div style='display:inline-block;width:30%;'/>");
		var responseRequestedButtonDiv = $("<div style='display:inline-block;width:34%;'/>");
		var addLinkButtonDiv = $("<div style='display:inline-block;width:18%;'/>");
		var cancelButtonDiv = $("<div style='text-align:right;width:18%;display:inline-block;'>");
		
		warningText.insertBefore(injectPoint);
		commentField.insertAfter(warningText);
		buttondiv.insertAfter(commentField);
		browseField.appendTo(buttondiv);
		saveButtonDiv.appendTo(buttondiv);
		responseRequestedButtonDiv.appendTo(buttondiv);
		addLinkButtonDiv.appendTo(buttondiv);
		cancelButtonDiv.appendTo(buttondiv);

		saveButton.appendTo(saveButtonDiv);
		responseRequestedButton.appendTo(responseRequestedButtonDiv);
		addLinkButton.appendTo(addLinkButtonDiv);
		cancelButton.appendTo(cancelButtonDiv);

		tr.attr("data-state", "edit");
		commentField.focus();
	}

	function buildCommentRow(tr) {
		var isMobile = typeof slider !== 'undefined';
	    var isController = IsController(tr.attr("data-id"));
	    var priorityCell = tr.find("[data-role='priority']");
	    var dueDateCell = tr.find("[data-role='due-date']");
	    var assigneesCell = tr.find("[data-role='assignees']");
	    var commentsCell = tr.find("[data-role='comments']");
	    var currentPriority = priorityCell.html();
	    var currentDueDate = $("span:last", dueDateCell).text();
	    var currentReminderDate = $(".reminderspan", dueDateCell).text();
	    var taskNameCell = tr.find("[data-role='task-name']");
	    var taskNameText = taskNameCell.find("a").text().trim();
	    var taskNameHTML = taskNameCell.html();
	    if (currentReminderDate == "") {
	        currentReminderDate = currentDueDate;
		}
		if (typeof currentPriority !== 'undefined') currentPriority = currentPriority.replace(`<span class="hidden data-label">Priority</span>`, "");
		priorityCell.html(`<span class="hidden data-label">Priority</span>`);
		$("<input style='width:100%' type='number'>").val(currentPriority).attr("data-role", "priority-input").appendTo(priorityCell);
		dueDateCell.html("");
	    var softDueSpan = $("<span class='softDueSpan'>Soft Due:<br/></span>");
	    var dueSpan = $("<span class='dueSpan'>Deadline:<br/></span>");

	    var softDueInput = $("<input style='width:100%'>").val(currentReminderDate).attr("data-role", "soft-due-input").attr("orig-val", currentReminderDate);

		if (isMobile) {
			softDueInput.mobiscroll().date({
				theme: getMobileOperatingSystem(),
				display: 'modal',
				onSelect: function (e) { validateSoftDue(); }
			});
		} else {
			softDueInput.lwDatepicker();
			softDueInput.change(function () { validateSoftDue(); });
		}
		softDueInput.appendTo(softDueSpan);
		softDueSpan.appendTo(dueDateCell);

	    var dueDateInput = $("<input style='width:100%'>").val(currentDueDate).attr("data-role", "due-date-input").attr("orig-val", currentDueDate);
		if (isMobile) {
			dueDateInput.mobiscroll().date({
				theme: getMobileOperatingSystem(),
				display: 'modal',
				onSelect: function (e) { validateSoftDue(); }
			});
		} else {
			dueDateInput.lwDatepicker();
			dueDateInput.change(function () { validateDueDate(); });
		}
		dueDateInput.appendTo(dueSpan);
		dueSpan.appendTo(dueDateCell);

	    taskNameCell.find("input[type=text]").val(taskNameText);
	    if (isController) {
	        taskNameCell.find("a").hide();
	        taskNameCell.find("input[type=text]").show();
	    } else {
            dueSpan.hide();
        }
	    
	    var reassignButton
	    if (isController) {
	        reassignButton = $("<button class='btn btn-default btn-reassign'>Reassign</button>").attr("data-role", "reassign-task").appendTo(assigneesCell);
	    } else {
	        reassignButton = $("<button class='btn btn-default btn-reassign'>Request to Reassign</button>").attr("data-role", "reassign-task").appendTo(assigneesCell);
	    }
	}

	function validateSoftDue() {
	    var softDueInput = $("[data-role=soft-due-input]");
	    var dueDateInput = $("[data-role=due-date-input]");
	    if (Date.parse(softDueInput.val()) > Date.parse(dueDateInput.val())) {
	        softDueInput.val(dueDateInput.val());
	    }
	    
	}

	function validateDueDate() {
	    var softDueInput = $("[data-role=soft-due-input]");
	    var dueDateInput = $("[data-role=due-date-input]");
	    if (Date.parse(dueDateInput.attr("orig-val")) == Date.parse(softDueInput.val())) {
	        softDueInput.val(dueDateInput.val());
	    }
	}

	function takeControlButtonClicked(e) {
	    var rowElem = $(e.target).closest("tr.report-line-content[data-id]");
		var checklistId = rowElem.data("id");
		takeControlOfChecklist(checklistId, $(e.target), rowElem);
	}

	function takeControlOfChecklist(checklistId, button, row) {
		if ($("tr[data-state='edit']", document).length > 0) {
			alert("You have a comment open. Please close it before using this feature.");
			return;
		}
		$.ajax({
			url: "../DataService.asmx/TakeControlOfChecklist",
			type: "POST",
			data: JSON.stringify({ activeChecklistId: checklistId }),
			contentType: "application/json",
			success: function (data) {
			    //remove button
			    button.remove();
			    $("#tasks-controlled").val($("#tasks-controlled").val() + "," + checklistId);
			    row.find("span[data-role='controllers-span']").text($("#user-name").val());
				//replace controller with user name
				//???add to tasks i control list
			},
			error: function (jqXHR, textStatus, errorThrown) {
			    alert(jqXHR.responseText);
			}
		});
	}

	// Attorney Client

	function updateAttorneyClient() {
		$.ajax({
			url: "../DataService.asmx/GetAttorneyClient",
			type: "POST",
			data: JSON.stringify({ reportId: self.reportId }),
			contentType: "application/json",
			success: function(data) {
				self.isConfidential = data.d;
				showAttorneyClientBanner();
			}
		});
	}

	function showAttorneyClientBanner() {
		if (self.isConfidential)
			$("#attorney-client-message").show();
	}

	// Priorities
	self.addPriorities = function() {
		$.ajax({
			url: "../DataService.asmx/AddPriorities",
			type: "POST",
			data: JSON.stringify({
				taskId: self.rightClickTaskId,
			}),
			contentType: "application/json",
			success: function(data) {
				data.d ?
					notifier.setMessage("Task Added.", "green", 2000) :
					notifier.setMessage("There was a problem adding your task", "red", 2000);
			}
		});
	};
	
	// Expand / Collapse General Comments
	function expandGeneralComments(e) {
		e.stopPropagation();
		var button = $("[data-role='expand-general']");
		button.html("<a data-role='collapse-general'><img src='/Images/minus.gif' alt='Collapse general comments'/></a>");
		var comments = $(".report-line-task-general-comment");
		comments.find("[data-comment='old']").removeClass("hidden");
	}
	
	function collapseGeneralComments(e) {
		e.stopPropagation();
		var button = $("[data-role='collapse-general']");
		button.html("<a data-role='expand-general'><img src='/Images/plus.gif' alt='Expand general comments'/></a>");
		var comments = $(".report-line-task-general-comment");
		comments.find("[data-comment='old']").addClass("hidden");
	}
	
	// Expand / Collapse Task Comments
	function expandTaskComments(e) {
		e.stopPropagation();
		var comments = $(e.currentTarget).closest("[data-role='comments']");
		var button = comments.find("[data-role='expand-task']");
		button.html("<a data-role='collapse-task'><img src='/Images/minus.gif' alt='Collapse task level comments'/></a>");
		var items = comments.find("[item-type='ph']");

		if (items.length > 0) {
			//button.after("<div>Retrieving comments...<img width='16px' src='images/loading.gif'/></div>");

			var req = {};
			req.ReportId = self.reportId;
			req.Ids = [];
			items.each(function () {
				req.Ids.push($(this).data("id"));
			});

			Post("../Services/ControlService.asmx/Comment_GET", JSON.stringify({ req }), function (msg) {
				let rsp = msg.d;

				items.each(function () {
					let idx = 0;
					for (let i = 0; i < rsp.length; i++) {
						if (rsp[i].Id == $(this).data("id")) {
							idx = i;
							break;
						}
					}

					$(this).find("[data-role='comment-text']").html(rsp[idx].Text);
				});

				items.removeAttr("item-type").removeClass("hidden");
				//statusReportModule.rebindCommentEvents();
			});
		} else {
			comments.find("[data-comment='old']").removeClass("hidden");
		}
	}
	
	function collapseTaskComments(e) {
		e.stopPropagation();
		var comments = $(e.currentTarget).closest("[data-role='comments']");
		var button = comments.find("[data-role='collapse-task']");
		button.html("<a data-role='expand-task'><img src='/Images/plus.gif' alt='Expand task level comments'/></a>");
		comments.find("[data-comment='old']").addClass("hidden");
	}

	bindCollapseAllClick();

	return self;
})();

var reportsFilterModule = (function () {
	var userHighlightingInput = $("#filters label[data-role='user-highlighting'] input");
	var hideCommentsCheckbox = $("#filters label[data-role='hide-comments'] input[type='checkbox']");
	var hideCommentsInput = $("#filters label[data-role='hide-comments'] input[type='text']");
	var assignmentSelect = $("#filters label[data-role='assigned-task'] select");
	var self = {};
	self.hideCommentsChecked = false;
	self.userHighlightingDate = null;
	self.hideCommentsDate = null;
	self.assignedTo = null;
	self.highlightUserComments = function () {
        var userID = $("#user-id").val();
	    //var allUserComments = $("tr.report-line-content td[data-role='comments'] div[data-user-id='" + userID + "']");
        var allUserComments = $("tr.report-line-content td[data-role='comments'] div[data-user-id]");
        for (var i = 0; i < allUserComments.length; i++) {
			var currentElem = $(allUserComments[i]);
			var commentDate = Date.parse(currentElem.data("date"));
			if (commentDate > self.userHighlightingDate) {
			    if ((currentElem.hasClass("sd0HighlightDate")) && !(currentElem.hasClass("sd0"))) { currentElem.addClass("sd0"); }
			    if ((currentElem.hasClass("sd1HighlightDate")) && !(currentElem.hasClass("sd1"))) { currentElem.addClass("sd1"); }
			    if ((currentElem.hasClass("sd2HighlightDate")) && !(currentElem.hasClass("sd2"))) { currentElem.addClass("sd2"); }
			    if ((currentElem.hasClass("sd3HighlightDate")) && !(currentElem.hasClass("sd3"))) { currentElem.addClass("sd3"); }
			    if ((currentElem.hasClass("sd4HighlightDate")) && !(currentElem.hasClass("sd4"))) { currentElem.addClass("sd4"); }
			    if ((currentElem.hasClass("sd50HighlightDate")) && !(currentElem.hasClass("sd50"))) { currentElem.addClass("sd50"); }
			    if (!currentElem.is(":visible")) {
			        currentElem.show();
			        currentElem.siblings("a[data-role='expand-task']").each(function (e) {
			            this.click();
			        });
			    }
			} else {
			    if (currentElem.hasClass("sd0")) { currentElem.removeClass("sd0").addClass("sd0HighlightDate"); }
			    if (currentElem.hasClass("sd1")) { currentElem.removeClass("sd1").addClass("sd1HighlightDate"); }
			    if (currentElem.hasClass("sd2")) { currentElem.removeClass("sd2").addClass("sd2HighlightDate"); }
			    if (currentElem.hasClass("sd3")) { currentElem.removeClass("sd3").addClass("sd3HighlightDate"); }
			    if (currentElem.hasClass("sd4")) { currentElem.removeClass("sd4").addClass("sd4HighlightDate"); }
			    if (currentElem.hasClass("sd50")) { currentElem.removeClass("sd50").addClass("sd50HighlightDate"); }
			}
		}
	};
	self.hideTasksWithoutComments = function () {
	    var currentVal = $("#filters label[data-role='hide-comments'] input[type='text']").val();
	    self.hideCommentsDate = Date.parse(currentVal);
		var allTasks = $("tr.report-line-content");
		for (var i = 0; i < allTasks.length; i++) {
			var currentTask = $(allTasks[i]);
			var currentDueDate = Date.parse(currentTask.data("due-date"));
			if (currentDueDate > self.hideCommentsDate) {
				var comments = $("td[data-role='comments'] p.comment-line", currentTask);
				if (comments.length == 0) {
					currentTask.addClass("hidden");
					continue;
				}
			}
			currentTask.removeClass("hidden");
		}
	};
	self.revertTasksWithoutComments = function () {
		$("tr.report-line-content").removeClass("hidden");
	};
	self.showTasksAssignedTo = function () {
	    //get selector of all tasks
		var allTasks = $("tr.report-line-content[data-id]");
		//filter via assignee metadata
		for (var i = 0; i < allTasks.length; i++) {
		    if ($("#filters label[data-role='assigned-task'] select").val() == 0) {
		        $(allTasks[i]).removeClass("hidden");
		    }
		    else {
		        var assigneesData = $("td[data-role='assignees'] span[data-role='assignees-span']", allTasks[i]).text();
		        if (assigneesData != null) {
		            var assignees = assigneesData.split("/")[0];
		            var assigneesArray = assignees.split(",");
		            var found = false;
		            for (var ii = 0; ii < assigneesArray.length; ii++) {
		                if (assigneesArray[ii].trim().replace("&nbsp;", " ") == self.assignedTo) {
		                    found = true;
		                }
		            }
		            if (!found) {
		                $(allTasks[i]).addClass("hidden");
		            } else {
		                $(allTasks[i]).removeClass("hidden");
		            }
		        }
		    }
		}
		//hide those that don't match
	};

	function highlightComments(){
	    var currentVal = $("#filters label[data-role='user-highlighting'] input").val();
	    self.userHighlightingDate = Date.parse(currentVal);
	    self.highlightUserComments();
	}

	$().ready(function () {
	    userHighlightingInput.change(function () {
	        highlightComments();
	    });
	    hideCommentsCheckbox.click(function () {
	        self.hideCommentsChecked = $("#filters label[data-role='hide-comments'] input[type='checkbox']:checked").length > 0;
	        if (self.hideCommentsChecked) {
	            self.hideTasksWithoutComments();
	        } else {
	            self.revertTasksWithoutComments();
	        }
	    });
	    hideCommentsInput.change(function () {
	        var currentVal = $("#filters label[data-role='hide-comments'] input[type='text']").val();
	        self.hideCommentsDate = Date.parse(currentVal);
	        if (self.hideCommentsChecked)
	            self.hideTasksWithoutComments();

	    });
	    assignmentSelect.change(function () {
	        var assigneeId = $("#filters label[data-role='assigned-task'] select").val();
	        self.assignedTo = $("#filters label[data-role='assigned-task'] select option[value='" + assigneeId + "']").html();
	        self.showTasksAssignedTo();
	    });
	});
	
	return self;
})();
/* Copyright © 2024 Renegade Swish, LLC */

