var usersPanel = (function () {
	var self = {};
	var tempUserData = {};
	var currentUserRow;
	var isEditing = false;
	
	$().ready(function() {
		$(document).on("click", "button[data-role='add-user']", function () { addUser(); });
		$(document).on("click", "a[data-role='delete-user']", function (e) { deleteUser(e); });
		$(document).on("click", "a[data-role='edit-user']", function (e) { editUser(e); });
		$(document).on("click", "a[data-role='update-user']", function () { updateUser(); });

		resize();
		window.onresize = resize;
	});

	function resize() {
		$("#site-main").height(($(window).height() - $("#site-nav").outerHeight() - $("#site-footer").outerHeight() - 4) + "px");
		$("#site-main").css("margin-top", ($("#site-nav").outerHeight()) + "px");
	}
	
	// Users
	function addUser() {
		$.ajax({
			url: "/DataService.asmx/AddUser",
			type: "POST",
			data: JSON.stringify({
				login: $("#login").val(),
				name: $("#name").val(),
				email: $("#email").val(),
				password: "Q",
				admin: $("#admin").is(":checked")
			}),
			contentType: "application/json",
			success: function(data) {
				window.location.reload();
			}
		});
	}
	
	function deleteUser(e) {
		var userRow = $(e.currentTarget).closest("tr");
		var choice = confirm("Are you sure you want to delete this user?");
		if (choice) {
			$.ajax({
				url: "/DataService.asmx/DeleteUser",
				type: "POST",
				data: JSON.stringify({ id: userRow.data("id") }),
				contentType: "application/json",
				success: function(data) {
					userRow.remove();
				}
			});	
		}
	}
	
	function editUser(e) {
		if (isEditing) {
			switchToNonEditMode(tempUserData);
			isEditing = false;
		}
		currentUserRow = $(e.currentTarget).closest("tr");
		getTempUserData(currentUserRow);
		switchToEditMode(currentUserRow);
		isEditing = true;
	}
	
	function updateUser() {
		var updatedValues = {
			id: currentUserRow.data("id"),
			login: currentUserRow.find("td[data-role='login'] input").val(),
			name: currentUserRow.find("td[data-role='name'] input").val(),
			email: currentUserRow.find("td[data-role='email'] input").val(),
			password: "Q",
			admin: currentUserRow.find("td[data-role='admin'] input").is(":checked")
		};
		$.ajax({
			url: "/DataService.asmx/UpdateUser",
			type: "POST",
			data: JSON.stringify(updatedValues),
			contentType: "application/json",
			success: function (data) {
				switchToNonEditMode(updatedValues);
			},
			error: function(data) {
				switchToNonEditMode(tempUserData);
			}
		});
	}
	
	function getTempUserData() {
		tempUserData.login = currentUserRow.find("td[data-role='login']").text();
		tempUserData.name = currentUserRow.find("td[data-role='name']").text();
		tempUserData.email = currentUserRow.find("td[data-role='email']").text();
		tempUserData.password = "Q";
		tempUserData.admin = currentUserRow.find("td[data-role='admin'] input").is(":checked");
	}
	
	function switchToNonEditMode(collection) {
		currentUserRow.find("td[data-role='actions']").html(
			"<a data-role='delete-user'><img src='/Images/delete.gif' title='Remove'/></a> " +
			"<a data-role='edit-user'><img src='/Images/edit.gif' title='Edit'/></a>");
		currentUserRow.find("td[data-role='login']").text(collection.login);
		currentUserRow.find("td[data-role='name']").text(collection.name);
		currentUserRow.find("td[data-role='email']").text(collection.email);
		currentUserRow.find("td[data-role='admin'] input").prop("checked", collection.admin);
		currentUserRow.find("td[data-role='admin'] input").prop("disabled", true);
	}
	
	function switchToEditMode() {
		currentUserRow.find("td[data-role='actions']").html("<a data-role='update-user'><img src='/Images/save_sm.gif' title='Save'/></a>");
		currentUserRow.find("td:not(:has(a, input))").each(function () {
			var value = $(this).html();
			var input = $("<input type='text' />");
			input.val(value);
			$(this).html(input);
		});
		currentUserRow.find("td[data-role='admin'] input").prop("disabled", false);
	}
	
	return self;
})()
/* Copyright © 2024 Renegade Swish, LLC */

