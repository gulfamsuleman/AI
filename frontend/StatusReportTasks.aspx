<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="StatusReportTasks.aspx.cs" Inherits="QProcess.StatusReportTasks" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title></title>
    <meta charset="utf-8" />
    <meta http-equiv="X-UA-Compatible" content="IE=edge" />
    <script src="Scripts/jquery-1.9.1.min.js?<%= System.IO.File.GetLastWriteTime(Server.MapPath("Scripts/jquery-1.9.1.min.js")).Ticks.ToString() %>"></script>
    <script>
        window.setTimeout(function () {
            window.location.reload();
        }, 840000);

        $(document).ready(function () {
            console.log("Document is ready");
            resize();
            swapFonts();
            automaticallyScrollPage();
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
                    if (cols > 2) {
                        cols = 2;
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
            if (document.body.scrollWidth > document.body.clientWidth) {
                return true;
            } else {
                return false;
            }
        }

        function automaticallyScrollPage() {
            console.log("Starting auto-scroll");
            var $grid = $('.grid');
            var scrollHeight = $grid.prop('scrollHeight') - $grid.height();
            var baseScrollSpeed = 50000; // Base scroll speed for a standard height
            var standardHeight = 1000; // Standard height to base the speed on

            // Calculate the scroll speed based on the height of the content
            var scrollSpeed = (scrollHeight / standardHeight) * baseScrollSpeed;

            function startScrolling() {
                console.log("Scrolling to bottom");
                $grid.animate({ scrollTop: scrollHeight }, scrollSpeed, 'linear', function () {
                    console.log("Reached bottom, resetting scroll");
                    setTimeout(function () {
                        $grid.scrollTop(0);
                        setTimeout(function () {
                            startScrolling();
                        }, 1000); // Add a 1-second delay before restarting the scroll
                    }, 1000); // Add a 1-second delay after resetting the scroll
                });
            }

            startScrolling();
        }
    </script>

    <style type="text/css">
        .header-item {
            text-align: center;
            color: white;
            background-color: black;
            padding: 2px;
            width: 100%;
            position: fixed;
            margin: -8px 0 0 -8px;
        }

        .gridoverdue {
            overflow: hidden;
            text-overflow: ellipsis;
            border: 1px solid lightgray;
            padding: 8px;
            margin: 5px;
            color: red;
        }

        .grid-item {
            text-overflow: ellipsis;
            border: 1px solid lightgray;
            padding: 8px;
            margin: 5px;
            color: black;
        }

        .grid-item .grid1,
        .grid-item .grid2,
        .grid-item .grid3,
        .grid-item .grid4,
        .gridoverdue .grid1 {
            max-width: 47%;
            margin-bottom: 10px;
        }

        .grid {
            display: flex;
            flex-direction: column; /* Stack items vertically */
            flex-wrap: nowrap; /* Prevent wrapping horizontally */
            max-height: 97vh; /* Allow vertical growth */
            overflow-y: auto; /* Enable vertical scrolling if content overflows */
        }

        @media (min-width: 768px) {
            .grid {
                flex-direction: row; /* Change to row to allow two columns */
                flex-wrap: wrap; /* Allow wrapping to the next row */
            }

            .grid > .grid-item, .grid > .gridoverdue {
                flex: 1 0 47%; /* Each item takes up 48% of the width, allowing two items per row */
            }
        }

        /* Styling for the multi class */
        .multi {
            background-color: #f0fcdc;
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
