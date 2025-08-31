var suggestionModule = (function() {
	var self = {};
	var suggestionText = $("textarea[data-role='add-suggestion']");
	var suggestionTable = $("#suggestion-table");
	var isAdmin = $("#is-admin").val() == "True";
	var rowTemplate =
		"<tr data-id='{0}' data-display='{1}' data-role='dragndrop-draggable'>" +
			"<td>" +
				"<input type='button' data-action='delete' {2} value='&#xf00d;' />" +
				"<input type='button' data-action='move-up' {3} value='&#xf062;' />" +
				"<input type='button' data-action='move-down' {4} value='&#xf063;' />" +
				"<input type='button' data-role='dragndrop-dragpoint' {5} value='&#xf047;' />" +
			"</td>" +
			"<td>{6}</td>" +
			"<td>{7}</td>" +
		"</tr>";
	
	$().ready(function() {
		$(document).on('click', "input[data-action='add']", addSuggestion);
		$(document).on('click', "input[data-action='delete']", function(e) { deleteSuggestion(e); });
		$(document).on('click', "input[data-action='move-down']", function(e) { moveSuggestionDown(e); });
		$(document).on('click', "input[data-action='move-up']", function(e) { moveSuggestionUp(e); });
		$(document).on('dragndropElementDropped', dragMove);
	});

	function addSuggestion() {
		$.ajax({
			url: "/DataService.asmx/AddSuggestion",
			type: "POST",
			data: JSON.stringify({ suggestion: suggestionText.val() }),
			contentType: "application/json",
			success: function(data) {
				handleReturnData(data.d);
			}
		});
	}
	
	function deleteSuggestion(e) {
		var choice = confirm("Are you sure you want to delete this item?");
		if (choice) {
			$.ajax({
				url: "/DataService.asmx/DeleteSuggestion",
				type: "POST",
				data: JSON.stringify({
					suggestionId: $(e.target).closest("tr").data("id")
				}),
				contentType: "application/json",
				success: function (data) {
					handleReturnData(data.d);
				}
			});
		}
	}
	
	function moveSuggestionDown(e) {
		var from = $(e.target).closest("tr");
		var to = from.next();
		moveSuggestionAjax(from.data("id"), to.data("id"));
	}
	
	function moveSuggestionUp(e) {
		var from = $(e.target).closest("tr");
		var to = from.prev();
		moveSuggestionAjax(from.data("id"), to.data("id"));
	}
	
	function dragMove(e) {
		var from = e.originalEvent.detail.draggedRow;
		var to = $(e.originalEvent.detail.dropTargetRow);
		moveSuggestionAjax(from.data("id"), to.data("id"));
	}

	function moveSuggestionAjax(from, to) {
		$.ajax({
			url: "/DataService.asmx/MoveSuggestion",
			type: "POST",
			data: JSON.stringify({
				fromId: from,
				toId: to
			}),
			contentType: "application/json",
			success: function(data) {
				handleReturnData(data.d);
			}
		});
	}
	
	function handleReturnData(suggestions) {
		suggestionTable.find("tbody").html("");
		for (var i = 0; i < suggestions.length; i++) {
			var last = i == suggestions.length - 1;
			var first = i == 0;
			addSuggestionRow(suggestions[i], first, last);
		}
	}

	function addSuggestionRow(suggestion, first, last) {
		var hidden = "class='fa btn hidden";
		var visible = "class='fa btn'";
		
		var newElem = $(format(rowTemplate,
			suggestion.Id,
			suggestion.DisplayOrder,
			isAdmin ? visible : hidden,
			isAdmin & !first ? visible: hidden,
			isAdmin & !last ? visible : hidden,
			isAdmin ? visible : hidden,
			suggestion.SuggestionText,
			suggestion.LoginName
		));
		suggestionTable.find("tbody").append(newElem);
	}

	return self;
})()
/* Copyright © 2024 Renegade Swish, LLC */

