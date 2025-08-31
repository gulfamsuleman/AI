using System;

namespace QProcess.Controls
{
	public partial class Controls_Fonts : System.Web.UI.UserControl
	{
		protected int FontSize { get; set; }
		protected void Page_Load(object sender, EventArgs e)
		{
			FontSize = !String.IsNullOrEmpty(Context.Request.Headers["X-FontSize"]) ? Convert.ToInt32(Context.Request.Headers["X-FontSize"]) : 12;
		}
	}
}
/* Copyright © 2024 Renegade Swish, LLC */

