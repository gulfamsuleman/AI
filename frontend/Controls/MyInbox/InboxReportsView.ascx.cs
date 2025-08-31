using System;
using System.Linq;
using System.Web;
using System.Web.UI.WebControls;
using QProcess.Controls.MyInbox;
using QProcess.Enums;
using QProcess.Extensions;
using QProcess.Repositories;

namespace QProcess.Controls
{
	public partial class Controls_MyInbox_InboxReportsView : System.Web.UI.UserControl
	{
		protected int UserId { get; set; }
		protected InboxViewType ViewType { get; set; }
		protected string SortBy { get; set; }
		protected string SortOrder { get; set; }
		public Controls_MyInbox_ReportList UnreadReportListControl { get; set; }
		public Controls_MyInbox_ReportList ReadReportListControl { get; set; }
        public MobileReportList MobileUnreadReportListControl { get; set; }
        public MobileReportList MobileReadReportListControl { get; set; }
        public bool IsMobile { get; set; } = false;

        public Controls_MyInbox_InboxReportsView()
		{
			UnreadReportListControl = new Controls_MyInbox_ReportList();
			ReadReportListControl = new Controls_MyInbox_ReportList();
		}

		protected void Page_Load(object sender, EventArgs e)
		{
            
            var myInboxRepo = new MyInboxRepository();
			var userRepo = new UserRepository();
			string inboxDropdownPreference;
			if (Context.Request.Headers["X-IsMobile"] != null) {
				IsMobile = bool.Parse(Context.Request.Headers["X-IsMobile"]);

            }
			if (Context.Request.Headers["X-ViewType"] != null)
			{
				var userName = Context.Request.Headers["X-UserName"];

                var user = userRepo.GetUser(userName);
				UserId = user.Id;
                ViewType = Context.Request.Headers["X-ViewType"].FromString<InboxViewType>();
				userRepo.AddPreference(UserId, "InboxDropdown", Context.Request.Headers["X-ViewType"]);
			}
			else
			{
                if (!Web_Site.Helpers.Owin.VerifyAuthentication(HttpContext.Current.Request)) return;

                UserId = QProcess.Session.CurrentSession.QUser.Id;
                inboxDropdownPreference = userRepo.GetPreference(UserId, "InboxDropdown");
				if (inboxDropdownPreference.Length > 0)
				{
					ViewType = inboxDropdownPreference.FromString<InboxViewType>();
				}
				else
				{
					ViewType = InboxViewType.InterestedParty;
				}
			}
			SortBy = !String.IsNullOrEmpty(userRepo.GetInboxSortBy(UserId)) ? userRepo.GetInboxSortBy(UserId) : "LastReportDate";
			SortOrder = !String.IsNullOrEmpty(userRepo.GetInboxSortOrder(UserId)) ? userRepo.GetInboxSortOrder(UserId) : "ASC";

			if (IsMobile)
			{
				MobileUnreadReportListControl.Title = GetTitleText(false, ViewType);
				MobileUnreadReportListControl.SortBy = SortBy;
				MobileUnreadReportListControl.SortOrder = SortOrder;
				MobileUnreadReportListControl.ReportList = myInboxRepo.GetInboxReports(UserId, false, ViewType, SortBy + " " + SortOrder).ToList();

				MobileReadReportListControl.Title = GetTitleText(true, ViewType);
				MobileReadReportListControl.SortBy = SortBy;
				MobileReadReportListControl.SortOrder = SortOrder;
				MobileReadReportListControl.ReportList = myInboxRepo.GetInboxReports(UserId, true, ViewType, SortBy + " " + SortOrder).ToList();
			} else {
                UnreadReportListControl.Title = GetTitleText(false, ViewType);
                UnreadReportListControl.SortBy = SortBy;
                UnreadReportListControl.SortOrder = SortOrder;
                UnreadReportListControl.ReportList = myInboxRepo.GetInboxReports(UserId, false, ViewType, SortBy + " " + SortOrder).ToList();

                ReadReportListControl.Title = GetTitleText(true, ViewType);
                ReadReportListControl.SortBy = SortBy;
                ReadReportListControl.SortOrder = SortOrder;
                ReadReportListControl.ReportList = myInboxRepo.GetInboxReports(UserId, true, ViewType, SortBy + " " + SortOrder).ToList();
            }
		}

		protected string GetTitleText(bool read, InboxViewType viewType)
		{
			var title = read ? "Read Status Reports - " : "Unread Status Reports - ";
			switch (viewType)
			{
				case InboxViewType.Supervisor:
					title += "Supervisor Reports";
					break;
				case InboxViewType.InterestedParty:
					title += "Interested Party Reports";
					break;
				case InboxViewType.All:
					title += "All Reports";
					break;
				case InboxViewType.MyFavorites:
					title += "My Favorites";
					break;
			}
			return title;
		}
	}
}
/* Copyright © 2024 Renegade Swish, LLC */

