<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="PrintStatusPage.aspx.cs" Inherits="QProcess.PrintStatusPage" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>QProcess</title>
    <meta http-equiv="X-UA-Compatible" content="IE=edge" />
    <style type="text/css">
        @media print {
            .no-print, .no-print * {
                display: none !important;
            }
        }

        body {
            font-size: 12pt;
            font-family: Arial, Helvetica, sans-serif;
        }

        span {
            display: inline-block;
            padding: 4px 8px;
        }

            span.itm {
                display: block;
                margin-left: 20px;
            }

            span.bold {
                font-weight: bold;
            }

            span.name {
                display: inline-block;
                width: 150px;
                font-weight: bold;
                clear: left;
            }

            span.taskName {
                display: block;
                background-color: #eeeeee;
                font-weight: bold;
                border-bottom: 1px solid #cccccc;
            }

        input[type=checkbox] {
            float: left;
            margin-top: 5px;
            display: inline-block;
        }

        .task {
            border: 1px solid #cccccc;
            margin-bottom: 10px;
        }

        h2 {
            margin: 0;
            border-bottom: 3px double #cccccc;
            margin-bottom: 5px;
            margin-top: 25px;
        }

        h2 > span {
            color: blue;
            display: inline-block;
            margin-left: 10px;
            cursor: pointer;
            font-weight: normal;
            font-size: 12pt;
        }

        h1 {
            border: 1px solid #cccccc;
            background-color: #eeeeee;
            padding: 6px 14px;
            margin-bottom: 0px;
            text-align: center;
        }

        ul {
            margin: 0;
            padding: 0;
            background-color: #f8f8f8;
            border-top: 1px dashed #cccccc;
        }

        li {
            margin: 0;
            list-style: none;
            padding: 4px 8px;
        }
    </style>
    <script src="Scripts/jquery-1.9.1.min.js"></script>
    <script type="text/javascript">
        $().ready(function () {
            $("h2 > span").click(function () {
                $(".id" + $(this).parent().attr("v")).remove();
                $(this).parent().remove();
            });
        });
    </script>
</head>
<body>
    <%=data%>
    <form id="form1" runat="server"></form>
</body>
</html>
<!-- Copyright © 2024 Renegade Swish, LLC -->

