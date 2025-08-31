<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="PrintTasks.aspx.cs" Inherits="QProcess.PrintTasks" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
     <title></title>
     <meta charset="utf-8" />
 	 <meta http-equiv="X-UA-Compatible" content="IE=edge" />
	 <link rel="stylesheet" href="Content/font-awesome.css">
   <script src="Scripts/jquery-1.9.1.min.js?<%= System.IO.File.GetLastWriteTime(Server.MapPath("Scripts/jquery-1.9.1.min.js")).Ticks.ToString() %>"></script>
    <script src="Scripts/masonry.pkgd.min.js"></script>
     <script type="text/javascript">
         $(document).ready(function () {
			$('.grid').masonry({
				columnWidth: 0,
				itemSelector: '.grid-item'
			});
			//setPrinting();
			//window.print();
			setTimeout(function(){
				window.location.reload(1);
			}, 600000);
         });

	
		function setPrinting() {
			var factory = document.getElementById("factory");
			factory.printing.leftMargin = .1;
			factory.printing.topMargin = .1;
			factory.printing.rightMargin = .1;
			factory.printing.bottomMargin = .1;
			factory.printing.header = "";
			factory.printing.footer = "";
		}
    </script>
    <style type="text/css">
        .grid {
  
        width: 950px;
        //max-height:900px;
         }
        .grid-item--width3 { width: 300px;
                             margin-top:10px;
                             margin-right:10px;
       
        }
        .break { page-break-after: always;}
		.fa-forward:before {
		  content: "\f04e";
		  color: #3399FF;
		  font-weight:bold;
		}
    </style>
</head>
<body>
    <form id="form1" runat="server">
     
      
       <%=htmlData %>
      
    </form>
</body>
</html>
<!-- Copyright © 2024 Renegade Swish, LLC -->

