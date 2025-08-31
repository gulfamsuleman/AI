using System;
using System.Collections.Generic;
using System.Linq;
using QProcess.Enums;

[Serializable]
public class ReportLine
{
    [Serializable]
    public sealed class Type: IEquatable<Type>
	{
		private readonly string name;

		public static readonly Type Header = new Type("Header Row");
		public static readonly Type Subheader = new Type("Sub Header Row");
		public static readonly Type Headings = new Type("Headings Row");
        public static readonly Type SpecialHeadings = new Type("Special Headings Row");
		public static readonly Type Spacer = new Type("SpacerType");
		public static readonly Type Ender = new Type("EnderType");
		public static readonly Type Comments = new Type("Comments");
		public static readonly Type Task = new Type("");

		public static IDictionary<string, Type> All
		{
			get { return all; }
		}
		private static IDictionary<string, Type> all = typeof(Type).GetFields(System.Reflection.BindingFlags.Public | System.Reflection.BindingFlags.Static).Where(f => f.FieldType == typeof(Type)).Select(f => (Type)f.GetValue(null)).ToDictionary(f => f.name);

		private Type(string name)
		{
			this.name = name;
		}

        public bool Equals(Type other)
        {
            if (other == null) return false;
            if (ReferenceEquals(this, other)) return true;

            return this.ToString() == other.ToString();
        }

        public override bool Equals(object other)
        {
            if (other == null) return false;
            if (ReferenceEquals(this, other)) return true;
            return other is Type && this.Equals((Type) other);
        }

        public override int GetHashCode()
        {
            return (name != null ? name.GetHashCode() : 0);
        }

        public static bool operator == (Type self, object other)
        {
            if (ReferenceEquals(self, null) && ReferenceEquals(other, null)) return true;
            if (ReferenceEquals(self, null)) return false;
            return self.Equals(other);
        }

        public static bool operator != (Type self, object other)
        {
            if (ReferenceEquals(self, null) && ReferenceEquals(other, null)) return true;
            if (ReferenceEquals(self, null)) return false;
            return self.Equals(other) == false;
        }

        public override string ToString()
		{
			return name;
		}
	}

	public int? ID { get; set; }
	public string Description { get; set; }
	public Type LineType { get; set; }
	public TaskType MyTaskType { get; set; }
	public DateTime? DueDate { get; set; }
	public int? Priority { get; set; }
	public string AssignedTo { get; set; }
	public string Controllers { get; set; }
	public int? NativeType { get; set; }
	public int? SectionId { get; set; }
	public int? CommentsId { get; set; }
    public List<TaskDetailItem> TaskDetails { get; set; }
    public bool IsComplete { get; set; }
    public bool HasRelatedComments { get; set; }
    public bool IsRecurring { get; set; }
    public bool IsDaily { get; set; }

    public class TaskDetailItem
    {
        public string ItemName { get; set; }
        public string ItemType { get; set; }
        public bool IsCompleted { get; set; }
    }

}
/* Copyright © 2024 Renegade Swish, LLC */

