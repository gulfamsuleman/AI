using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI.WebControls;
using QProcess.Repositories;

namespace QProcess
{

    public partial class SuggestionPage : SessionPage
	{
		protected List<Suggestion> Suggestions { get; set; }
		protected bool IsAdmin { get; set; }
		protected int LastSuggestion { get; set; }

        public Repeater Repeater1 { get; set; }

        public SuggestionPage()
        {
            Repeater1 = new Repeater();
        }

        protected void Page_Load(object sender, EventArgs e)
		{
            if (!Web_Site.Helpers.Owin.VerifyAuthentication(HttpContext.Current.Request)) return;

            var suggestionRepo = new SuggestionRepository();
			Suggestions = suggestionRepo.GetSuggestions().ToList();
			LastSuggestion = Suggestions.First().DisplayOrder;
			IsAdmin = QProcess.Session.CurrentSession.QUser.IsAdmin;
			if (Context.Request.Params["admin"] != null)
			{
				if (int.Parse(Context.Request.Params["admin"]) == 1)
				{
					IsAdmin = true;
				}
			}
			Repeater1.DataBind();
		}

		protected bool IsFirstElement(int displayOrder)
		{
			if (displayOrder > 0)
				return true;
			return false;
		}
	}

}
/* Copyright © 2024 Renegade Swish, LLC */

