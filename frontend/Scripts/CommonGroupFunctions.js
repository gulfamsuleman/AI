var editGroupModule = (function () {
	var self = {};
	var modal = null;

	$().ready(function () {
		modal = window.modalModule;
		$(document).on("click", "a[data-role='delete-user-group']", function (e) { deleteUserGroup(e); });
		$(document).on("click", "a[data-role='edit-user-group']", function (e) { editUserGroup(e); });
	});

	function deleteUserGroup(e) {
		var userGroupRow = $(e.currentTarget).closest("tr");
		var choice = confirm("Are you sure you want to delete this group?");
		if (choice) {
			$.ajax({
				url: "../DataService.asmx/DeleteGroup",
				type: "POST",
				data: JSON.stringify({
					id: userGroupRow.data("id")
				}),
				contentType: "application/json",
				success: function(data) {
					userGroupRow.remove();
				}
			});
		}
	};
    	
	function editUserGroup(e) {
		var userGroupRow = $(e.currentTarget).closest("tr");
		var editable = userGroupRow.data("edit");
		var title = editable == true ?
			"Edit Group - " :
			"View Group - ";
		if (userGroupRow.find("td[data-role='name']>a").length > 0) {
		    title += userGroupRow.find("td[data-role='name']>a").text();
		}
		else {
		    title += userGroupRow.find("td[data-role='name']").text();
		}

		if (typeof slider !== 'undefined') {
			slider.html(`<div style="margin:50px auto;text-align:center">Loading...please wait <img src="../images/loading.gif" /></div>`);
			slider.load("../JQueryHandler.ashx?ControlName=" + encodeURI("Controls/Shared/EditGroup.ascx"), { GroupId: userGroupRow.data("id"), Editable: editable }, function () {
				slider.prepend(`<h3>${title}</h3>`);
				slider.append(`
					<div class="row mt-3">
						<div class="col text-center">
						<button class="btn btn-secondary close-button">Close Window</button>
						</div>
					</div>`);
				slider.find(".close-button").on("click", function () {
					slider.toggleClass('open');
				});
			});
			slider.toggleClass('open');
			return;
		}

		modal.init({
			titleText: title,
			controlName: "Controls/Shared/EditGroup.ascx",
			remoteParams: { GroupId: userGroupRow.data("id"), Editable: editable }
		});
	}

	return self;
})()
/* Copyright © 2024 Renegade Swish, LLC */

