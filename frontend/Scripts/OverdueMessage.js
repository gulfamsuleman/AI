var overdueMessageModule = (function () {
	var self = {};
	var show = false;
	var sendButton = $("[data-role='send-message']");
	var showHideLink = $("a[data-role='show-hide']");
	var checkboxes = $("input[type='checkbox']");
	var openLink = $("a[data-role='open-overdue-message']");
	var messageDismiss = $("button[data-dismiss='message-panel']");
	var assigneesDropdown = $("#assigned-filter-list");

	$().ready(function() {
		sendButton.click(sendOverdueMessage);
		showHideLink.click(toggleShowHideRecipients);
		checkboxes.click(checkboxClick);
		messageDismiss.click(dismissOverdueMessageModal);
		assigneesDropdown.change(changeAssignees);

	    	//call once to remove the person who is sending
		showHideRow();
		loadAssignees();
        
		if ($("#oid").val() != "") {
		    assigneesDropdown.val($("#oid").val());
		    changeAssignees();
		    openLink.click();
		    $("#message-body").focus();
		    $("#oid").val("");
		}
	});

	self.refreshRecipients = function (ctl) {
	    alert($(ctl).val());
	}
	
	function loadAssignees() {
		var assignees = getAllCheckedRecipients();
		
            	assigneesDropdown.html("<option value='-1'> </option>");

		assignees.each(function () {
			assigneesDropdown.append("<option value='" + $(this).val() + "'>" + $(this).attr("v-name") + "</option>");
		});
	}

	function changeAssignees() {
		var assignee = assigneesDropdown.val();

		//if show all, then check all checkboxes
		if (assignee < 0){
			$("input[type='checkbox']").prop('checked', true);
		}
		else {
			var checkedassignees = getAllCheckedRecipients();
			checkedassignees.each(function () {
				$(this).prop('checked', false);
			});
			$("input:checkbox[value='" + assignee + "']").prop("checked","true");
		}
		
		showHideRow();
	}

	function sendOverdueMessage() {
		$.ajax({
			url: "/DataService.asmx/SendOverdueEmailMessages",
			type: "POST",
			data: JSON.stringify({
				recipientIds: self.getRecipientIds(),
				message: $("#message-body").val()
			}),
			contentType: "application/json",
			success: function(data) {
				alert(data.d);
			},
		});
	}
	
	function toggleShowHideRecipients() {
		var notChecked;
		if (show) {
			notChecked = getAllNotCheckedRecipients().closest("div");
			notChecked.removeClass("hidden");
			showHideLink.text("Hide Unchecked Recipients");
			show = false;
		} else {
		    notChecked = getAllNotCheckedRecipients().closest("div");
			notChecked.addClass("hidden");
			showHideLink.text("Show All I Control");
			show = true;
		}
	}
	
	self.getRecipientIds = function() {
		var checked = getAllCheckedRecipients();
		var recipientIds = "";
		checked.each(function() {
			recipientIds += $(this).val() + ",";
		});
		return recipientIds;
	};

	function getAllCheckedRecipients() {
		return $("input[type='checkbox']:checked");
	}
	
	function getAllNotCheckedRecipients() {
		return $("input[type='checkbox']:not(:checked)");
	}
	
	function checkboxClick() {
		assigneesDropdown.val(-1);
		showHideRow();
	}

	function showHideRow() {
	    var checked = getAllCheckedRecipients();
	    $("#overdue-table").find("tbody > tr").addClass("hidden");
	    checked.each(function () {
	        var userId = $(this).val();
	        $("#overdue-table").find("tr[data-assignees*='|" + userId + "|']").removeClass("hidden");
	    });
	}


	function dismissOverdueMessageModal() {
		$("#message").addClass("hidden");
		$(".filters").removeClass("hidden");
	}

	return self;
})()
/* Copyright © 2024 Renegade Swish, LLC */

