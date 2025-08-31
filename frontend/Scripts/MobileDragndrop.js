$().ready(function () {
	var dragTable = null;
	var dragRow = null;
	var hoverRow = null;
	var isDragging = false;
	var dragOffset = null;
	var scrollContainer = null;
	$(document.body).append("<div id='dragndrop-ghost'></div>");
	var ghost = $("#dragndrop-ghost").css("display", "hidden").css("position", "absolute");

	var handleDragStart = function (e, isTouch) {
		if (!isTouch && e.button != 0)
			return;
		else if (isTouch && e.originalEvent.touches.length != 1)
			return;

		dragRow = $(e.target).closest("tr");
		dragTable = dragRow.closest("table[data-role='dragndrop-reorderable']");
		if (!dragRow || !dragTable)
			return;
		isDragging = true;
		document.dispatchEvent(new CustomEvent("dnd_DragStart", { detail: { draggedRow: dragRow, dragTable: dragTable } }));
		e.preventDefault();
		var rowOffset = $(dragRow).offset();
		dragOffset = [e.pageX - rowOffset.left, e.pageY - rowOffset.top];

		scrollContainer = isMobile ? $("main.container") : $("#site-main");
	}

	// Support drag from the entire priority-col cell for both mouse and touch
	$(document).on('mousedown touchstart', "td.priority-col", function (e) {
		if ($(this).find(".draggable[data-role='dragndrop-dragpoint']").length > 0) {
			var isTouch = e.type === "touchstart";
			handleDragStart(e, isTouch);
		}
	});


	var handleDragMove = function (e, isTouch) {
		if (isDragging) {
			if (isTouch) {
				e.pageX = e.originalEvent.touches[0].pageX;
				e.pageY = e.originalEvent.touches[0].pageY;
				e.clientX = e.originalEvent.touches[0].clientX;
				e.clientY = e.originalEvent.touches[0].clientY;
			}

			if ($(ghost).not("visible")) {
				//make ghost visible only when the mouse is moved after mousedown
				$(ghost).empty()
					.append($(dragRow).clone())
					.show();
			}
			//$(ghost).offset({ top: e.pageY - dragOffset[1], left: e.pageX - dragOffset[0] });
			$(ghost).offset({ top: e.pageY, left: e.pageX });

			//set hover classes appropriately
			$(ghost).hide();
			var underElement = document.elementFromPoint(e.clientX, e.clientY);
			$(ghost).show();

			$(dragTable).find("tr").removeClass("dragndrop-hover");
			hoverRow = null;

			$(dragTable).find(underElement).closest("tr").each(function () {
				$(this).addClass("dragndrop-hover");
				$(".delete-row.dragndrop-hover td.recycle-small").css("background", "transparent url('/Images/recycle_full_sm.jpg') left center no-repeat;");
				$("td.recycle-small").not(".dragndrop-hover td").css("background", "transparent url('/Images/recycle_sm.jpg') left center no-repeat;");

				$(".delete-row.dragndrop-hover td.recycle-large").css("background", "transparent url('/Images/recycle_full.jpg') left center no-repeat;");
				$("td.recycle-large").not(".dragndrop-hover td").css("background", "transparent url('/Images/recycle.jpg') left center no-repeat;");

				hoverRow = this;
			});

			if (hoverRow != null)
				hoverRow.scrollIntoView({ behavior: 'smooth', block: 'center', inline: 'nearest' });
			//scrollIntoView(hoverRow, scrollContainer, e.clientY);
		}
	}

	var handleDragEnd = function (e, isTouch) {
		if (isDragging && ((!isTouch && e.button == 0) || (isTouch && e.originalEvent.touches.length < 2))) {
			if (hoverRow) {
				var elementDropped = new CustomEvent("dragndropElementDropped", { detail: { draggedRow: dragRow, dropTargetRow: hoverRow, dragTable: dragTable, dropId: $(e.target).attr("id") } });
				document.dispatchEvent(elementDropped);
				$(hoverRow).removeClass("dragndrop-hover");
				$(hoverRow).css("background-color", "");
				if ($(dragRow).prevAll().filter(hoverRow).length !== 0) {
					$(hoverRow).before($(dragRow));
				}
				else if ($(dragRow).nextAll().filter(hoverRow).length !== 0) {
					$(hoverRow).after($(dragRow));
				}
			}
			else {
				var elementDropped = new CustomEvent("dragndropElementCancel", { detail: { draggedRow: dragRow, dropTargetRow: hoverRow, dragTable: dragTable, dropId: $(e.target).attr("id") } });
				document.dispatchEvent(elementDropped);
			}
			$(ghost).hide();
			isDragging = false;
			dragRow = null;
			dragTable = null;
			hoverRow = null;
			dragOffset = null;
		}
	}

	$(document)
		.mousemove(function (e) { handleDragMove(e, false); })
		.mouseup(function (e) { handleDragEnd(e, false); });
	$(document)
		.on("touchmove", function (e) { handleDragMove(e, true); })
		.on("touchend", function (e) { handleDragEnd(e, true); });
});

// Element is the row you are hovering over.  Container is #site-main, the div under the tabs.  ClientY is the mouse position relative to the window
function scrollIntoView(element, container, clientY) {
	var containerTop = $(container)[0].scrollTop;
	var containerBottom = containerTop + $(container).height();
	if (element) { // If we're actually hovering over a row, scroll that row into view.  Element offset is relative to its parent priority list.  Need to also include that list's offset.
		var elemTop = element.offsetTop + $(element).closest("[data-table=user-table]")[0].offsetTop;
		var elemBottom = elemTop + $(element).height();
		if (elemTop < containerTop) {
			element.scrollIntoView({ behavior: 'smooth', block: 'start', inline: 'nearest' });
			//$(container).scrollTop(elemTop);
		} else if (elemBottom > containerBottom) {
			element.scrollIntoView({ behavior: 'smooth', block: 'center', inline: 'nearest' });
			//$(container).scrollBy(elemBottom - $(container).height());
		}
	}
	else { // If we're not hovering over a row, do the best we can.  This happens if you go outside a priority list table.
		if (clientY > 200) {
			$(container).scrollTop(containerTop + 20);
		} else {
			if (containerTop != 0) {
				if (containerTop - 20 > 0) {
					$(container).scrollTop(containerTop - 20);
				} else {
					$(container).scrollTop(0);
				}
			}
		}
	}
}
/* Copyright © 2024 Renegade Swish, LLC */

