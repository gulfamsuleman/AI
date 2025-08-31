using System;
using System.Collections.Generic;
using System.Web.UI.WebControls;

namespace QProcess.Controls
{
	public partial class Controls_Reports_SortBy : System.Web.UI.UserControl
	{
		protected List<SortOption> SortOptions { get; set; }
		public string Sort { get; set; }
		public Repeater Repeater1 { get; set; }

		public Controls_Reports_SortBy()
		{
			Repeater1 = new Repeater();
		}

		protected void Page_Load(object sender, EventArgs e)
		{
			SortOptions = PopulateSortOptions();
			Repeater1.DataSource = SortOptions;
			Repeater1.DataBind();
		}

		protected List<SortOption> PopulateSortOptions()
		{
			return new List<SortOption>
			{
				new SortOption {Value = "Person", Name = "Name"},
				new SortOption {Value = "Task", Name = "Task"},
				new SortOption {Value = "Due", Name = "Due Date"}
			};
		}

		protected class SortOption
		{
			public string Value { get; set; }
			public string Name { get; set; }
		}
	}
}
/* Copyright © 2024 Renegade Swish, LLC */

