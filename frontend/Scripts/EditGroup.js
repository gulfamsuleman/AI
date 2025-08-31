var usersEditGroup = (function() {
	var self = {};
	var editGroupTable = $("#users-in-group");
	var addUserList = $("#add-user-list");

	$().ready(function () {
		$(document).on("click", "a[data-role='remove-group-user']", function (e) { removeGroupUser(e); });
		$("button[data-role='add-user-to-group']").unbind("click").bind("click", function () { addGroupUser(); });
		$("button[data-role='edit-owner']").unbind("click").bind("click", function () { editOwner(); });
	});

	function editOwner() {
		var prevOwner = $("#owner-id").val();
		var newOwner = $("#owner-list").val();
		if (prevOwner == newOwner) {
			$.prompt("You have selected the current owner, please select a different owner if you'd like to change it.");
		}
		else {
			$.ajax({
				url: "../DataService.asmx/ChangeGroupOwner",
				type: "POST",
				data: JSON.stringify({
					groupId: $("#group-id").val(),
					owner: newOwner
				}),
				contentType: "application/json",
				success: function (data) {
					$("td[data-role=owner-" + $("#group-id").val() + "]").text($("#owner-list option:selected").text());
					$("#owner-id").val(newOwner);
					$.prompt("Owner changed successfully.");
					$("#hid-refresh").click();//click hidden button if it exists on this page - will refresh groups list
				}
			});
		}
	}

	function removeGroupUser(e) {
		var groupUserRow = $(e.currentTarget).closest("tr");
		$.ajax({
			url: "../DataService.asmx/RemoveUserFromGroup",
			type: "POST",
			data: JSON.stringify({
				membershipId: groupUserRow.data("id")
			}),
			contentType: "application/json",
			success: function (data) {
				addUserList.find("option:contains(" + groupUserRow.find("td:not(:has(a))").text() + ")").prop("disabled", false);
				groupUserRow.remove();
				if (typeof groupsModule != "undefined") {
				    groupsModule.refreshGroups();
				}
			}
		});
	}
	
	function addGroupUser() {
		var selectedUser = addUserList.find("option:selected");
		// Make sure that we don't add the blank selection
		if (selectedUser.val() != -1) {
			// Check to see it did that an invalid username did not get injected
			$("#users-in-group td:not(:has(input))").each(function () {
				if ($(this).text() == selectedUser.text())
					return;
			});
			$.ajax({
				url: "../DataService.asmx/AddUserToGroup",
				type: "POST",
				data: JSON.stringify({
					userId: selectedUser.val(),
					groupId: $("#group-id").val()
				}),
				contentType: "application/json",
				success: function (data) {
					addUserList.find("option[value='-1']").prop("selected", true);
					selectedUser.prop("disabled", true);
					refreshUsers(data.d);
					if (typeof groupsModule != "undefined") {
					    groupsModule.refreshGroups();
					}
				}
			});
		}
	}
	
	function refreshUsers(users) {
		var tbody = editGroupTable.find("tbody");
		tbody.html("");
		for (var i = 0; i < users.length; i++) {
			addGroupUserRow(users[i]);
		}
	}
	
	function addGroupUserRow(user) {
		var rowTemplate =
			"<tr data-id='{0}'>" +
				"<td data-role='actions'>" +
                    "<a data-role='remove-group-user'><img src='/Images/delete.gif' title='Remove'/></a>" +
				"</td>" +
				"<td data-role='name'>{1}</td>" +
			"</tr>";
		var newElem = $(format(rowTemplate, user.Id, user.FullName));
		editGroupTable.find("tbody").append(newElem);
	}

	return self;
})()
/* Copyright © 2024 Renegade Swish, LLC */

