using System;
using System.IO;
using System.Linq;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace QProcess.Helpers
{
	public class DOMInjector : PlaceHolder
	{
		private bool _performRegularly;

		public string InjectInto
		{
			get { return this.ViewState["InjectInto"] as string; }
			set { this.ViewState["InjectInto"] = value; }
		}

		protected override void OnInit(EventArgs e)
		{
			base.OnInit(e);

			this.PreRender += this.__PreRender;
		}

		protected override void Render(HtmlTextWriter writer)
		{
			if (this._performRegularly)
			{
				base.Render(writer);
			}
		}

		private void __PreRender(object sender, EventArgs e)
		{
			if (string.IsNullOrEmpty(this.InjectInto))
			{
				goto performRegularly;
			}

			var injectInto = this.FindControlRecursively(this.Page);

			if (injectInto == null)
			{
				goto performRegularly;
			}

			_performRegularly = false;

			using (var stringWriter = new StringWriter())
			using (var writer = new HtmlTextWriter(stringWriter))
			{
				base.Render(writer);

				writer.Flush();
                string data = stringWriter.GetStringBuilder().ToString();
                // [ST] 08/05/14 11:21 AM - update to skip this step if there is nothing to inject
                if (data.Trim() != "")
				    injectInto.Controls.Add(new LiteralControl(data));
			}

			this.Controls.Clear();

			return;

			performRegularly: this._performRegularly = true;
		}

		private Control FindControlRecursively(Control current)
		{
			var found = current.FindControl(this.InjectInto);

			return found ?? current.Controls.Cast<Control>().Select(FindControlRecursively).FirstOrDefault();
		}
	}
}
/* Copyright © 2024 Renegade Swish, LLC */

