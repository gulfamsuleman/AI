using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using QProcess.Models;

namespace QProcess.Repositories
{
    public class GradingRepository
	{
		public IEnumerable<GradingUser> GetGradingUsers(int userId)
		{
			using (var cmd = new CmdObj("Grading_Daily_GetUsers"))
			{
				var users = cmd.GetDS();
				return users.Tables[0].AsEnumerable().Select(u => new GradingUser
					{
						Id = (int) u["ID"],
						Name = (string) u["FullName"]
					});
			}
		}
		
		public Tuple<DateTime,DateTime> GetGradingPeriodDates(int gradingPeriodId)
		{
			using (var cmd = new CmdObj("Grading_StartEnd"))
			{
				cmd.Add("@GradingPeriodID", gradingPeriodId);
				cmd.Add("@StartDt", SqlDbType.DateTime, ParameterDirection.Output, 8);
				cmd.Add("@EndDt", SqlDbType.DateTime, ParameterDirection.Output, 8);
				cmd.ExecuteNonQueryWithOutput();
				return new Tuple<DateTime, DateTime>((DateTime) cmd["@StartDt"], (DateTime) cmd["@EndDt"]);
			}
		}

		// Deductions
		public IEnumerable<Deduction> GetDeductions(int userId, int periodId, bool showDeleted = false)
		{
			using (var cmd = new CmdObj("Grading_Daily_GetDeductions"))
			{
				cmd.Add("@UserID", userId);
				cmd.Add("@GradingPeriodID", periodId);
				cmd.Add("@ShowDeleted", showDeleted);
				var deductions = cmd.GetDS();
				return deductions.Tables[0].AsEnumerable().Select(d => new Deduction
					{
						Id = (int) d["id"],
						Date = (string)d["date"] == "01/01/1900" ? "" : (string)d["date"],
						Reason = (string) d["reason"],
						Points = (double) d["points"],
						Type = (int) d["type"],
						IsDeleted = (bool) d["isdeleted"]
					});
			}
		}

		public void DeleteDeduction(int deductionId, int userId, string reason)
		{
			using (var cmd = new CmdObj("Grading_Daily_DeleteDeduction"))
			{
				cmd.Add("@ID", deductionId);
				cmd.Add("@UserID", userId);
				cmd.Add("@Reason", reason);
				cmd.ExecuteNonQueryWithOutput();
			}
		}

		public void RestoreDeduction(int deductionId)
		{
			using (var cmd = new CmdObj("Grading_Daily_RestoreDeduction"))
			{
				cmd.Add("@ID", deductionId);
				cmd.ExecuteNonQueryWithOutput();
			}
		}

		public void RecalculateDeductions(int periodId, int userId)
		{
			using (var cmd = new CmdObj("Grading_Daily_FinalizeUser"))
			{
				cmd.Add("@GradingPeriodID", periodId);
				cmd.Add("@UserID", userId);
				cmd.ExecuteNonQueryWithOutput();
			}
		}

		// Vacations
		public IEnumerable<Vacation> GetVacations(int periodId, int userId = -1)
		{
			var dates = GetGradingPeriodDates(periodId);
			return GetVacations(dates.Item1, dates.Item2, userId);
		}

		public IEnumerable<Vacation> GetVacations(DateTime start, DateTime end, int userId=-1)
		{
			using (var cmd = new CmdObj("Grading_Daily_GetVacations"))
			{
				if(userId != -1)
					cmd.Add("@UserID", userId);
				cmd.Add("@StartDt", start);
				cmd.Add("@EndDt", end);
				var vacations = cmd.GetDS();
				return vacations.Tables[0].AsEnumerable().Select(v => new Vacation
					{
						FullName = (string)v["Fullname"],
						Id = (int)v["ID"],
						StartDate = (string)v["StartDt"],
						EndDate = (string)v["EndDt"],
						Status = (string)v["status"]
					});
			}
		}

		public void AddVacation(int userId, DateTime start, DateTime end, bool approve=false)
		{
			using (var cmd = new CmdObj("Grading_Daily_AddVacation"))
			{
				cmd.Add("@UserID", userId);
				cmd.Add("@StartDt", start);
				cmd.Add("@EndDt", end);
				if(approve)
					cmd.Add("@Approved", 1);
				cmd.ExecuteNonQueryWithOutput();
			}
		}

		public void DeleteVacation(int vacationId)
		{
			using (var cmd = new CmdObj("Grading_Daily_DeleteVacation"))
			{
				cmd.Add("@ID", vacationId);
				cmd.ExecuteNonQueryWithOutput();
			}
		}

		public void ApproveVacation(int vacationId)
		{
			using (var cmd = new CmdObj("Grading_Daily_ApproveVacation"))
			{
				cmd.Add("@ID", vacationId);
				cmd.ExecuteNonQueryWithOutput();
			}
		}
		
		// Reports On Hold
		public IEnumerable<ReportOnHold> GetReportsOnHold(int periodId, int userId = -1)
		{
			var dates = GetGradingPeriodDates(periodId);
			return GetReportsOnHold(dates.Item1, dates.Item2, userId);
		}

		public IEnumerable<ReportOnHold> GetReportsOnHold(DateTime start, DateTime end, int userId=-1)
		{
			using (var cmd = new CmdObj("Grading_Daily_GetOnHold"))
			{
				if(userId != -1)
					cmd.Add("@UserID", userId);
				cmd.Add("@StartDt", start);
				cmd.Add("@EndDt", end);
				var reports = cmd.GetDS();
				return reports.Tables[0].AsEnumerable().Select(r => new ReportOnHold
					{
						User = (string)r["User"],
						Report = (string)r["report"],
						Id = (int)r["ID"],
						StartDate = (string)r["StartDt"],
						EndDate = (string)r["EndDt"],
						Status = (string)r["status"]
					});
			}
		}

		public void AddReportOnHold(int reportId, int userId, DateTime start, DateTime end)
		{
			using (var cmd = new CmdObj("Grading_Daily_AddOnHold"))
			{
				cmd.Add("@ReportID", reportId);
				cmd.Add("@UserID", userId);
				cmd.Add("@StartDt", start);
				cmd.Add("@EndDt", end);
				cmd.ExecuteNonQueryWithOutput();
			}
		}

		public void DeleteReportOnHold(int reportOnHoldId)
		{
			using (var cmd = new CmdObj("Grading_Daily_DeleteOnHold"))
			{
				cmd.Add("@ID", reportOnHoldId);
				cmd.ExecuteNonQueryWithOutput();
			}
		}

		// Adjustments
		public void AddAdjustment(int userId, int periodId, string reason, double points)
		{
			using (var cmd = new CmdObj("Grading_Daily_AddAdjustment"))
			{
				cmd.Add("@UserID", userId);
				cmd.Add("@GradingPeriodID", periodId);
				cmd.Add("@Reason", reason);
				cmd.Add("@Points", points);
				cmd.ExecuteNonQueryWithOutput();
			}
		}

		public IEnumerable<GradingGridLine> GetGradingGrid(int gradingPeriodId, string sortExpression)
		{
			using (var cmd = new CmdObj("Grading_Daily_GetGrid"))
			{
				cmd.Add("@GradingPeriodID", gradingPeriodId);
				var gridLines = cmd.GetDS();
				gridLines.Tables[0].DefaultView.Sort = sortExpression;
				var sortedTable = gridLines.Tables[0].DefaultView.ToTable();
				return sortedTable.AsEnumerable().Select(gl => new GradingGridLine
					{
						Id = (int) gl["id"],
						FullName = (string) gl["Fullname"],
						ControllerDeductions = (double)gl["ControllerDeductions"],
						SupervisorDeductions = (double)gl["SupervisorDeductions"],
						StatusOverdue = (double)gl["StatusOverdue"],
						ChecklistOverdue = (double)gl["ChecklistOverdue"],
						IPBonus = (double)gl["IPBonus"],
						TenDayDeduction = (double)gl["TenDayDeduction"],
						Score = (double)gl["Score"],
						Grade = (string)gl["Grade"],
						GradePrevious = (string)gl["GradePrevious"],
						TotalComments = (int)gl["TotalComments"],
						ControllerComments = (int)gl["ControllerComments"],
						IPComments = (int)gl["IPComments"],
						SuperVisorComments = (int)gl["SupervisorComments"],
						TotalCharacters = (int)gl["TotalCharacters"],
						TotalTime = Convert.ToDouble((decimal)gl["totaltime"]),
						ControllerTime = Convert.ToDouble((decimal)gl["controllertime"]),
						SupervisorTime = Convert.ToDouble((decimal)gl["supervisortime"]),
						ControllerCharacters = (int)gl["ControllerCharacters"],
						IPCharacters = (int)gl["IPCharacters"],
						SupervisorCharacters = (int)gl["SupervisorCharacters"],
						AdjustmentPoints = (double)gl["AdjustmentPoints"],
						AdjustmentReason = (string)gl["AdjustmentReason"]
					});
			}
		}
	}

	public class GradingUser
	{
		public int Id { get; set; }
		public string Name { get; set; }
	}

	public class Deduction : IDeduction
	{
		public int Id { get; set; }
		public string Date { get; set; }
		public string Reason { get; set; }
		public double Points { get; set; }
		public int Type { get; set; }
		public bool IsDeleted { get; set; }
	}

	public class Vacation
	{
		public string FullName { get; set; }
		public int Id { get; set; }
		public string StartDate { get; set; }
		public string EndDate { get; set; }
		public string Status { get; set; }
	}

	public class ReportOnHold
	{
		public string User { get; set; }
		public string Report { get; set; }
		public int Id { get; set; }
		public string StartDate { get; set; }
		public string EndDate { get; set; }
		public string Status { get; set; }
	}

	public class GradingGridLine
	{
		public int Id { get; set; }
		public string FullName { get; set; }
		public double ControllerDeductions { get; set; }
		public double SupervisorDeductions { get; set; }
		public double StatusOverdue { get; set; }
		public double ChecklistOverdue { get; set; }
		public double IPBonus { get; set; }
		public double TenDayDeduction { get; set; }
		public double Score { get; set; }
		public string Grade { get; set; }
		public string GradePrevious { get; set; }
		public int TotalComments { get; set; }
		public int ControllerComments { get; set; }
		public int IPComments { get; set; }
		public int SuperVisorComments { get; set; }
		public int TotalCharacters { get; set; }
		public double TotalTime { get; set; }
		public double ControllerTime { get; set; }
		public double SupervisorTime { get; set; }
		public int ControllerCharacters { get; set; }
		public int IPCharacters { get; set; }
		public int SupervisorCharacters { get; set; }
		public double AdjustmentPoints { get; set; }
		public string AdjustmentReason { get; set; }
	}
}
/* Copyright © 2024 Renegade Swish, LLC */

