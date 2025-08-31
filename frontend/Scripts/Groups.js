var groupsModule = (function() {
	var self = {};
	var userGroupsTable = $("#user-groups-table");
	var rowTemplate =
		"<tr data-id='{0}' data-edit='{1}'>" +
				"<td data-role='actions'>{2}</td>" +
				"<td data-role='name'>{3}</td>" +
				"<td><a href='#' data-role='edit-user-group'>{4}</a></td>" +
				"<td>{5}</td>" +
				"<td>{6}</td>" +
				"<td>{7}</td>" +
			"</tr>";


	$().ready(function() {
		$(document).on("change", "#display-user-list", function () { getMyGroups(); });
		$("#hid-refresh").click(function () { getMyGroups(); });
	    resize();
	    window.onresize = resize;
	});

	function resize() {
		$("#site-main").height(($(window).height() - $("#site-nav").outerHeight() - $("#site-footer").outerHeight() - 4) + "px");
		$("#site-main").css("margin-top", ($("#site-nav").outerHeight()) + "px");
	}

	self.refreshGroups = function () {
	    getMyGroups();
	}

	function getMyGroups() {
		$.ajax({
			url: "../DataService.asmx/GetMyGroups",
			type: "POST",
			data: JSON.stringify({
			    filterUserId: $("#display-user-list option:selected").val()
			}),
			contentType: "application/json",
			success: function(data) {
				userGroupsTable.find("tbody").html("");
				for (var i = 0; i < data.d.length; i++) {
					addGroupRow(data.d[i]);
				}
			}
		});
	}
	
	function addGroupRow(group) {
	    var button = group.IsOwner ? "<a data-role='delete-user-group'><img src='../Images/delete.gif' title='Remove'/></a>" : "";
		var editView = group.IsOwner ? "Edit" : "View";
		var isMember = group.IsMember ? "<i class='fa fa-star'></i>" : "";
		var isOwner = group.IsOwner ? "<i class='fa fa-star'></i>" : "";
		var newElem = $(format(rowTemplate, group.Id, group.IsOwner, button, group.GroupName, editView, isMember, isOwner, group.Owner));
		userGroupsTable.find("tbody").append(newElem);
	}
	
	return self;
})()
/* Copyright © 2024 Renegade Swish, LLC */

