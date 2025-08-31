using System;
using System.Web.UI;

namespace QProcess.Controls
{
	public partial class MessageToUser : UserControl
    {
		protected bool ShowMessage = false;
		protected string Message = "";
		protected void Page_Load(object sender, EventArgs e)
		{            
        }

		public void Show()
		{
			ShowMessage = true;
		}

		public void SetMessage(string message)
		{
			Message = message;
		}
	}
}
/* Copyright © 2024 Renegade Swish, LLC */

