<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="DepartmentTasks.aspx.cs" Inherits="QProcess.DepartmentTasks" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title></title>
    <meta charset="utf-8" />
    <meta http-equiv="X-UA-Compatible" content="IE=edge" />
    <asp:PlaceHolder runat="server">
        <script src="Scripts/jquery-1.9.1.min.js?<%= System.IO.File.GetLastWriteTime(Server.MapPath("Scripts/jquery-1.9.1.min.js")).Ticks.ToString() %>"></script>
    </asp:PlaceHolder>
    <script>
        window.setTimeout(function () {
            window.location.reload();
        }, 600000);

        $(function () {
            resize();
            swapFonts();
        });

        var maxSize = 32;
        var minFont = 22;
        var fontSize = maxSize;
        var cols = 1;

        function resize() {
            if (!(scrollingWindow())) {
                return;
            }

            var canReduceColumns = true;
            var canReduceFont = true;
            while (scrollingWindow() && canReduceColumns) {
                fontSize = maxSize;
                canReduceFont = true;
                canReduceColumns = tryReduceColumns();
                cols++;
                while (scrollingWindow() && canReduceFont) {
                    canReduceFont = tryReduceFont();
                    if (cols > 3) {
                        cols = cols;
                    }
                }
            }
        }

        function swapFonts() {
            $(".gridoverdue").removeClass("grid-item");
        }

        function tryReduceColumns() {
            if ($(".grid1").length > 0) {
                $(".grid1").addClass("grid2");
                $(".grid1").removeClass("grid1");
                fontSize = 24;
                minFont = 16;
                setFont();
                return true;
            }
            if ($(".grid2").length > 0) {
                $(".grid2").addClass("grid3");
                $(".grid2").removeClass("grid2");
                fontSize = 22;
                minFont = 12;
                setFont();
                return true;
            }
            if ($(".grid3").length > 0) {
                $(".grid3").addClass("grid4");
                $(".grid3").removeClass("grid3");
                fontSize = 16;
                minFont = 8;
                setFont();
                return true;
            }
            return false;
        }


        function tryReduceFont() {
            if (fontSize > minFont) {
                fontSize--;
                setFont();
                return true;
            }
            return false;
        }

        function setFont() {
            $(".grid").css({ 'font-size': fontSize });
        }

        function scrollingWindow() {
            if (document.body.scrollWidth > document.body.clientWidth) { return true; }
            else { return false; }
        }
    </script>
    <style type="text/css">
        .header-item {
            text-align: center;
            color: white;
            background-color: black;
            padding: 2px;
        }

        .grid-item {
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
            border-bottom: 1px solid black;
            padding: 2px;
            color: black;
        }
        .gridoverdue, .gridReview {
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
            border-bottom: 1px solid black;
            padding: 2px;
        }

        .gridoverdue, .gridReviewOverdue {
            color: red;
            border-bottom: 1px solid black;
        }

        .grid1 {
            max-width: 98vw;
        }

        .grid2 {
            max-width: 49vw;
        }

        .grid3 {
            max-width: 32vw;
        }

        .grid4 {
            max-width: 24vw;
        }

        .grid {
            display: flex;
            flex-flow: column wrap;
            max-height: 97vh;
        }

        .multi {
            background-color: #f0fcdc;
            /*italicized*/
            font-style: italic;
        }

        .fa-forward:before {
            content: "\f04e";
            color: #3399FF;
            font-weight: bold;
        }
    </style>
    <link href="Content/font-awesome.css" rel="stylesheet" />
</head>
<body>
    <form id="form1" runat="server">

        <%=htmlData %>
    </form>
</body>
</html>
<!-- Copyright © 2024 Renegade Swish, LLC -->

