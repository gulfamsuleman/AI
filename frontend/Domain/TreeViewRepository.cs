using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;

namespace QProcess.Repositories {

	public class TreeViewRepository
	{
        public DataSet GetChecklistsByFolder(int userId, int memberGroupId = 0, int managerGroupId = 0, bool isAdmin = false, string search = "", int parentId = 0)
        {
            using (var cmd = new CmdObj("QCheck_GetMyChecklistsByFolder"))
            {
                cmd.Add("@UserID", userId);
                cmd.Add("@memberGroupId", memberGroupId);
                cmd.Add("@managerGroupId", managerGroupId);
                cmd.Add("@isAdmin", isAdmin);
                cmd.Add("@search", search);
                return cmd.GetDS();
            }
        }

		public IEnumerable<TreeNodeData> GetChecklistsByFolderTV(int userId, int memberGroupId = 0, int managerGroupId = 0, bool isAdmin = false, string search = "", int parentId = 0)
		{
			using (var cmd = new CmdObj("QCheck_GetMyChecklistsByFolder"))
			{
				cmd.Add("@UserID", userId);
				cmd.Add("@memberGroupId", memberGroupId);
				cmd.Add("@managerGroupId", managerGroupId);
				cmd.Add("@isAdmin", 0);
					// We found that the original page had a check box that was 'isAdmin' to control this, which was set to always be invisible from the server side
					// This is why it loaded much faster.
					// AllChecklistsConsolidated.aspx.vb:250
					// AllChecklistsConsolidated.aspx:557
				cmd.Add("@search", search);
				//cmd.Add("@parentId", parentId);
				var test = cmd.GetDS().Tables[0].AsEnumerable();
				return test
					.Select(q => new TreeNodeData {
						Name = Convert.ToString(q["NodeName"]),
						Id = Convert.ToInt32(q["ID"]),
						FolderId = Convert.ToInt32(q["FolderID"]),
						ParentId = Convert.IsDBNull(q["ParentID"])?(int?)null:Convert.ToInt32(q["ParentID"]),
						Type = Convert.ToInt32(q["Type"]),
						IsActive = Convert.ToBoolean(q["Active"]),
						Template = Convert.ToInt32(q["Template"])
					});
			}
		}
	}

	public partial class TreeNodeData
	{
		public int Id { get; set; }
		public int FolderId { get; set; }
		public int? ParentId { get; set; }
		public string Name { get; set; }
		public int Type { get; set; }
		public bool IsActive { get; set; }
		public int Template { get; set; }
	}

	public static class TreeNodeExtensions
	{
		public static TreeNode<TreeNodeData> ToTree(this IEnumerable<TreeNodeData> list)
		{
			var pool = list.ToList();
			var root = list.SingleOrDefault(q => q.Type == 2);
			pool.Remove(root);
			var tree = new TreeNode<TreeNodeData>(root);

			tree.AddChildren(GetSubtree(pool, tree));

			return tree;
		}

		public static TreeNode<TreeNodeData> GetSubtree(IEnumerable<TreeNodeData> list, TreeNode<TreeNodeData> parent)
		{
			var pool = list.Where(q => q.ParentId != parent.Value.Id);
			var children = list.Where(q => q.ParentId == parent.Value.Id);
			foreach (var treeNodeData in children)
			{
				parent.AddChild(GetSubtree(pool, new TreeNode<TreeNodeData>(treeNodeData)));
			}

			return parent;
		}
	}

	

}
/* Copyright © 2024 Renegade Swish, LLC */

