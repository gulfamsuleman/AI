using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using QProcess.Domain.Models;
using QProcess.Models;

namespace QProcess.Repositories
{
	public class LoadTimesRepository
    {
        private readonly UserTimeZone myTz = QProcess.Session.CurrentSession.UserTimeZone;

        private EnumerableRowCollection<DataRow> ReportLoadTimes(DateTime startFilter, DateTime endFilter, 
			string reportName = "", int userId = -1, string sortBy = "", string sortOrder = "")
		{
			startFilter = myTz.GetSystemTime(startFilter);
			endFilter = myTz.GetSystemTime(endFilter);

			using (var cmd = new CmdObj("QCheck2_LoadTimeReport"))
			{
				var loadTimes = cmd.GetDS();
				var filteredLoadTimes =
					loadTimes.Tables[0].AsEnumerable().Where(l => (DateTime)l["DateTime"] > startFilter && (DateTime)l["DateTime"] < endFilter);
				if (!String.IsNullOrEmpty(reportName))
					filteredLoadTimes = filteredLoadTimes.Where(l => (string)l["Report Name"] == reportName);
				if (userId != -1)
					filteredLoadTimes = filteredLoadTimes.Where(l => (int)l["UserID"] == userId);
				if (!String.IsNullOrEmpty(sortBy) && !String.IsNullOrEmpty(sortOrder))
				{
					switch (sortOrder)
					{
						case "Desc":
							filteredLoadTimes = filteredLoadTimes.OrderByDescending(l => l[sortBy]);
							break;
						case "Asc":
							filteredLoadTimes = filteredLoadTimes.OrderBy(l => l[sortBy]);
							break;
					}
				}
				return filteredLoadTimes;
			}
		}

		public IEnumerable<ReportLoadTime> GetReportLoadTimes(DateTime startFilter, DateTime endFilter, string reportName = "",
			int userId = -1, string sortBy = "", string sortOrder = "")
        {
            var filteredLoadTimes = ReportLoadTimes(startFilter, endFilter, reportName, userId, sortBy, sortOrder);
			return filteredLoadTimes.Select(lt => new ReportLoadTime
			{
				User = (string)lt["User"],
				UserId = (int)lt["UserID"],
				PageName = (string)lt["Page Name"],
				ServerTime = (int)lt["Server Time"],
				ClientTime = (int)lt["Client Time"],
				TotalLoadTime = (int)lt["Total Load Time"],
				DateTime = myTz.GetLocalTime((DateTime)lt["DateTime"]),
				ReportName = (string)lt["Report Name"],
				LastOpened = myTz.GetLocalTime((DateTime)lt["LastOpened"]),
				Browser = (string)lt["Browser"]
			});
		}

		public List<LoadTimesUser> GetUsers(DateTime startFilter, DateTime endFilter)
		{
			var filteredLoadTimes = ReportLoadTimes(startFilter, endFilter);
			var userList = filteredLoadTimes.GroupBy(lt => lt["UserId"]).Select(r =>
				{
					var row = r.First();
					return new LoadTimesUser()
						{
							Id = (int) row["UserId"],
							Name = (string) row["User"]
						};
				}
			).ToList();
			userList.Insert(0, new LoadTimesUser{ Id = -1, Name = "All" });
			return userList;
		}

		public List<LoadTimesReport> GetReports(DateTime startFilter, DateTime endFilter)
		{
			var filteredLoadTimes = ReportLoadTimes(startFilter, endFilter);
			var reportList = filteredLoadTimes.GroupBy(lt => lt["Report Name"]).Select(r =>
			{
				var row = r.First();
				return new LoadTimesReport
				{
					Name = (string)row["Report Name"]
				};
			}
			).ToList();
			reportList.Insert(0, new LoadTimesReport { Name = "All" });
			return reportList;
		}

		public void SaveReportLoadTime(int userId, string pageName, int serverLoadTime, int clientLoadTime, 
			string browser, int reportId = -1, DateTime? lastViewed = null)
		{
			using (var cmd = new CmdObj("QCheck_LoadTime"))
			{
				cmd.Add("@UserID", userId);
				cmd.Add("@PageName", pageName);
				cmd.Add("@dt", myTz.GetSystemTimeNow());
				cmd.Add("@ServerLoadTime", serverLoadTime);
				cmd.Add("@ClientLoadTime", clientLoadTime);
				cmd.Add("@Browser", browser);
				if(reportId != -1)
					cmd.Add("@ReportID", reportId);
				if(lastViewed.HasValue)
					cmd.Add("@LastViewed", lastViewed.Value);
				cmd.ExecuteNonQueryWithOutput();
			}
		}
	}

	public class ReportLoadTime : IReportLoadTime
	{
		public string User { get; set; }
		public int UserId { get; set; }
		public string PageName { get; set; }
		public int ServerTime { get; set; }
		public int ClientTime { get; set; }
		public int TotalLoadTime { get; set; }
		public DateTime DateTime { get; set; }
		public string ReportName { get; set; }
		public DateTime LastOpened { get; set; }
		public string Browser { get; set; }
	}

	public class LoadTimesUser
	{
		public int Id { get; set; }
		public string Name { get; set; }
	}

	public class LoadTimesReport
	{
		public string Name { get; set; }
	}
}
/* Copyright © 2024 Renegade Swish, LLC */

