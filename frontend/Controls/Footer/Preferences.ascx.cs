using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.UI.HtmlControls;
using System.Web.UI.WebControls;
using QProcess.Repositories;

namespace QProcess.Controls
{
	public partial class Controls_Footer_Preferences : System.Web.UI.UserControl
	{
		protected int UserId { get; set; }
		protected Preferences Preferences { get; set; }
        protected Preferences BulkImportPreferences { get; set; }

        protected List<NamedEntitySelected> Assignees { get; set; }
		protected List<NamedEntitySelected> Controllers { get; set; }
		protected List<NamedEntitySelected> Deadlines { get; set; }
		protected List<NamedEntitySelected> Reports { get; set; }
		protected List<NamedEntitySelected> Priorities { get; set; }
		protected List<NamedEntitySelected> Alerts { get; set; }
		protected List<NamedEntitySelected> SoftDeadlines { get; set; }
		protected List<NamedEntitySelected> Echecklist { get; set; }

        protected List<NamedEntitySelected> BulkAssignees { get; set; }
        protected List<NamedEntitySelected> BulkControllers { get; set; }
        protected List<NamedEntitySelected> BulkDueDates { get; set; }
        protected List<NamedEntitySelected> BulkReports { get; set; }
        protected List<NamedEntitySelected> BulkPriorities { get; set; }
        protected List<NamedEntitySelected> BulkSoftDueDate { get; set; }

        public Repeater Repeater1 { get; set; }
		public Repeater Repeater2 { get; set; }
		public Repeater Repeater3 { get; set; }
		public Repeater Repeater4 { get; set; }
		public Repeater Repeater5 { get; set; }
		public Repeater Repeater6 { get; set; }
		public Repeater Repeater7 { get; set; }
		public Repeater Repeater8 { get; set; }

        public Repeater RepeaterBulkAssignee { get; set; }
        public Repeater RepeaterBulkController { get; set; }
        public Repeater RepeaterBulkDueDate { get; set; }
        public Repeater RepeaterBulkSoftDueDate { get; set; }
        public Repeater RepeaterBulkReport { get; set; }
        public Repeater RepeaterBulkPriority { get; set; }

		public HtmlInputCheckBox chkWeeklySummaryEmail { get; set; }

        public Controls_Footer_Preferences()
		{
			Repeater1 = new Repeater();
			Repeater2 = new Repeater();
			Repeater3 = new Repeater();
			Repeater4 = new Repeater();
			Repeater5 = new Repeater();
			Repeater6 = new Repeater();
			Repeater7 = new Repeater();
			Repeater8 = new Repeater();

            RepeaterBulkAssignee = new Repeater();
            RepeaterBulkController = new Repeater();
            RepeaterBulkDueDate = new Repeater();
            RepeaterBulkSoftDueDate = new Repeater();
            RepeaterBulkReport = new Repeater();
            RepeaterBulkPriority = new Repeater();

			chkWeeklySummaryEmail = new HtmlInputCheckBox();
        }

		protected void Page_Load(object sender, EventArgs e)
		{
			UserId = QProcess.Session.CurrentSession.QUser.Id;
			var userRepo = new UserRepository();
			Preferences = userRepo.GetPreferences(UserId);
            BulkImportPreferences = userRepo.GetBulkImportPreferences(UserId);
            var selectListRepo = new SelectListRepository();

			/* Email Automation */
			Assignees = GetNamedEntitySelectedList(selectListRepo.GetGroups(), new NamedEntity { Id = -1, Name = "Me" }, Preferences.Assignee);
			Repeater1.DataBind();

			Controllers = GetNamedEntitySelectedList(selectListRepo.GetGroups(), new NamedEntity { Id = -1, Name = "My Supervisor" }, Preferences.Controller);
			Repeater2.DataBind();

			Deadlines = GenerateSelectList(new NamedEntity { Id = -1, Name = "Tomorrow" }, Preferences.Due, "{0} days", 10);
			Repeater3.DataBind();

            Reports = GetNamedEntitySelectedList(
                selectListRepo.GetMySectionsCondensed(UserId)
                    .Prepend(new NamedEntity { Id = -1, Name = "First section of assignee's default report" })
                    .Prepend(new NamedEntity { Id = 0, Name = "None" }),
					null,
					Preferences.ReportOrig);
            Repeater4.DataBind();

            Priorities = GenerateSelectList(new NamedEntity { Id = -1, Name = "Not on a priority list" },
											Preferences.Priority, "Priority {0} on assignees list", 10,
											new NamedEntity { Id = 999, Name = "Last Priority on assignees list" });
			Repeater5.DataBind();

			Alerts = GenerateSelectList(new NamedEntity { Id = -1, Name = "No extra alert" }, Preferences.Alert, "{0} day(s) before deadline", 10);
			Repeater6.DataBind();

			SoftDeadlines = GenerateSelectList(new NamedEntity { Id = -1, Name = "Same as deadline" }, Preferences.SoftDue, "{0} day(s) before deadline", 10);
			Repeater7.DataBind();

			Echecklist = GenerateSelectList(new NamedEntity { Id = -1, Name = "Not on a priority list" },
											Preferences.EChecklistPriority, "Priority {0} on assignees list", 1,
											new NamedEntity { Id = 999, Name = "Last Priority on assignees list" });
			Repeater8.DataBind();

			chkWeeklySummaryEmail.Checked = Preferences.WeeklySummaryEmail;

            /* Bulk Import */
            BulkAssignees = GetNamedEntitySelectedList(selectListRepo.GetGroups(), new NamedEntity { Id = -1, Name = "Me" }, BulkImportPreferences.Assignee);
            RepeaterBulkAssignee.DataBind();

            BulkControllers = GetNamedEntitySelectedList(selectListRepo.GetGroups(), new NamedEntity { Id = -1, Name = "My Supervisor" }, BulkImportPreferences.Controller);
            RepeaterBulkController.DataBind();

            BulkDueDates = GenerateSelectList(new NamedEntity { Id = -1, Name = "Tomorrow" }, BulkImportPreferences.Due, "{0} days", 10);
            RepeaterBulkDueDate.DataBind();

            BulkReports = GetNamedEntitySelectedList(
                selectListRepo.GetMySectionsCondensed(UserId)
                    .Prepend(new NamedEntity { Id = -1, Name = "First section of assignee's default report" })
                    .Prepend(new NamedEntity { Id = 0, Name = "None" }),
					null,
					BulkImportPreferences.ReportOrig
            );
            RepeaterBulkReport.DataBind();

            BulkPriorities = GenerateSelectList(new NamedEntity { Id = -1, Name = "Not on a priority list" },
                                            BulkImportPreferences.Priority, "Priority {0} on assignees list", 10,
                                            new NamedEntity { Id = 999, Name = "Last Priority on assignees list" });
            RepeaterBulkPriority.DataBind();

            BulkSoftDueDate = GenerateSelectList(new NamedEntity { Id = -1, Name = "Same as due date" }, BulkImportPreferences.SoftDue, "{0} day(s) before due date", 10);
            RepeaterBulkSoftDueDate.DataBind();
        }

		public List<NamedEntitySelected> GetNamedEntitySelectedList(IEnumerable<NamedEntity> entities, NamedEntity firstItem, int defaultItemId)
		{
			var temp = entities.ToList();
            if (firstItem != null)
                temp.Insert(0, firstItem);
            return temp.Select(s => new NamedEntitySelected { Id = s.Id, Name = s.Name, IsSelected = defaultItemId == s.Id }).ToList();
		}

		public List<NamedEntitySelected> GenerateSelectList(NamedEntity firstItem,
			int defaultItemId, string template, int iterations, NamedEntity lastItem = null)
		{
			var toReturn = new List<NamedEntity>();
			for (int i = 1; i <= iterations; i++)
			{
				toReturn.Add(new NamedEntity { Id = i, Name = String.Format(template, i) });
			}
			if (lastItem != null)
				toReturn.Add(lastItem);
			return GetNamedEntitySelectedList(toReturn, firstItem, defaultItemId);
		}

		public class NamedEntitySelected : NamedEntity
		{
			public bool IsSelected { get; set; }
		}
	}
}
/* Copyright © 2024 Renegade Swish, LLC */

