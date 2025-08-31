using System.Collections.Generic;
using System.Data;
using QProcess.Models;

namespace QProcess.Repositories
{
	public class SuggestionRepository
	{
		public IEnumerable<Suggestion> GetSuggestions()
		{
			using (var cmd = new CmdObj("QCheck_GetSuggestions"))
			{
				var suggestions = cmd.GetDS();
				return suggestions.Tables[0].AsEnumerable().OrderByDescending(a=> a["DisplayOrder"]).Select(s => new Suggestion
					{
						Id = (int) s["SuggestionID"],
						SuggestionText = (string) s["Suggestion"],
						LoginName = (string) s["LoginName"],
						DisplayOrder = (int) s["DisplayOrder"]
					});
			}
		}

		public void AddSuggestion(string suggestion, int userId)
		{
			using (var cmd = new CmdObj("QCheck_AddSuggestion"))
			{
				cmd.Add("@Suggestion", suggestion);
				cmd.Add("@UserID", userId);
				cmd.ExecuteNonQueryWithOutput();
			}
		}

		public void DeleteSuggestion(int suggestionId)
		{
			using (var cmd = new CmdObj("QCheck_DeleteSuggestion"))
			{
				cmd.Add("@SuggestionID", suggestionId);
				cmd.ExecuteNonQueryWithOutput();
			}
		}

		public void MoveSuggestion(int fromId, int toId)
		{
			using (var cmd = new CmdObj("QCheck_MoveSuggestion"))
			{
				cmd.Add("@SuggestionID", fromId);
				cmd.Add("@MoveTo", toId);
				cmd.ExecuteNonQueryWithOutput();
			}
		}
	}

	public class Suggestion : ISuggestion
	{
		public int Id { get; set; }
		public string SuggestionText { get; set; }
		public string LoginName { get; set; }
		public int DisplayOrder { get; set; }
	}
}
/* Copyright © 2024 Renegade Swish, LLC */

