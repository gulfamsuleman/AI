<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Error.aspx.cs" Inherits="QProcess.Error.ErrorPage" %>

<!DOCTYPE html>

<!DOCTYPE html>
<html>
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" />    
    <title>Error <%=StatusCode %> - <%=AppName %></title>
    <style>
        body {
            color: black;
            background-color: white;
            background-image: none;
            background-repeat: no-repeat;
            background-image: url("/Images/<%=Firm%>/warmup.webp");
            /*background-position: center -30%;*/
            background-size: cover;   
            background-blend-mode: difference;
            font-family: Tahoma, Verdana;
            font-size: 12pt;
        }
        div.top {
            font-size: 15vmin;
            color: #00000090;
            position: fixed;
            top:20vh;
            left:10vw;
        }
        div.bottom {
            font-size: 5vmin;
            color: #00000090;
            position: fixed;
            top: 60vh;
            left: 30vw;
            width: 60vw;
        }
        div.bottom a {
            color: #00000090;
            text-decoration: none;
        }
        div.bottom a:hover {
            color: black;
            text-decoration: none;
        }
        
        #errorDetails {
            position: fixed;
            width: 75%;
            top: calc(100vh + 10px);
            left: calc(12.5% - 12.5px);
            padding: 12.5px;
            border-radius: 25px;
            visibility: hidden;
            background: white;
            height: 90vh;
            overflow-y: auto;
            z-index: 10;
            transition: top .5s ease-in-out;
        }

        #errorDetails.active {
            visibility:visible;
            top: 5vh;            
        }     
        
        #errorDetails img {
            width:100%;
        }

        #errorDetails span.close {
            float: right;
            cursor: pointer;
        }
        #errorDetails span.close:hover {
            float: right;
            cursor: pointer;
            color: #00000090;
        }
        #errorDetails span.close::before {
            width:1em;
            height:1em;            
            content: "\00d7";
        }
    </style>
    <script type="text/javascript">
        function showDetails(show) {
            var dialog = document.getElementById('errorDetails');
            if (dialog.classList.contains("active") && !show)
                dialog.classList.remove("active");
            else if (!dialog.classList.contains("active") && show)
                dialog.classList.add("active");
        }
    </script>
</head>
<body runat="server">    
    <div class="top">Error <%=StatusCode %></div>
    <div class="bottom"><%=AppName %> encountered an error. Sorry! 
        <ul>
            <li><a href="/MyTasks.aspx">Return to My Tasks</a></li>
            <li><a href="#" onclick="showDetails(true)">Show Error Details</a></li>
        </ul>
    </div>

    <div id="errorDetails">
        <span class="close" onclick="showDetails(false)"></span>
        <h3>Error Details</h3>        
        <span><%=LastError?.ToString().Replace(Environment.NewLine, "<br/>") ?? "No error details available." %></span>
    </div>
</body>
</html>
<!-- Copyright © 2024 Renegade Swish, LLC -->

