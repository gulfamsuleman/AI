using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.IO;
using System.Text;
using System.Web;
using QProcess.Repositories;

namespace QProcess.Extensions 
{

	public static class TreeViewHtmlExtensions
	{
		public static HtmlString ToHtmlString(this IEnumerable<TreeNodeData> data)
		{
			var stream = new MemoryStream();
			var stw = new StreamWriter(stream, new UTF8Encoding());

			stw.Write("<ul>");
			foreach (var treeNodeData in data)
			{
				stw.Write("<li data-id='");
				stw.Write(treeNodeData.Id);
				stw.Write("'");

				if (treeNodeData.Type == 1)
				{
					stw.Write(" data-jstree='{\"icon\":\"fa fa-file-o\"}'");
					stw.Write(treeNodeData.Template != 0 ? " data-is-template='true'" : " data-is-template='false'");
				}
				else
				{
					stw.Write(" class='jstree-closed'");
				}
				stw.Write(">");
				stw.Write(treeNodeData.Name);
				stw.Write("</li>");
				stw.Flush();
			}
			stw.Write("</ul>");

			stream.Position = 0;
			var html = new HtmlString((new StreamReader(stream)).ReadToEnd());
			stw.Dispose();
			stream.Dispose();

			return html;
		}

		//public static HtmlString ToHtmlString(this IEnumerable<TreeNodeData> data)
		//{
		//	var sw = new StringWriter();

		//	using (var writer = new HtmlTextWriter(sw))
		//	{
		//		writer.RenderBeginTag(HtmlTextWriterTag.Ul);
		//		foreach (var treeNodeData in data)
		//		{
		//			writer.AddAttribute("data-id", "" + treeNodeData.Id);
		//			if (treeNodeData.Type == 1)
		//				writer.AddAttribute("data-jstree", "{'icon':'fa fa-file-o'}");
		//			writer.RenderBeginTag(HtmlTextWriterTag.Li);
		//			writer.Write(treeNodeData.Name);
		//			writer.RenderEndTag();
		//		}
		//		writer.RenderEndTag();
		//	}

		//	return new HtmlString(sw.ToString());
		//}
	}

	public static class DataExtensionMethods
	{
        public static string ToBlank(this object value)
        {
            if (value == DBNull.Value) return "";
            if (value == null) return "";

            return value.ToString();
        }

        public static string Left(this string value, int maxLength)
        {
            if (string.IsNullOrEmpty(value)) return value;
            maxLength = Math.Abs(maxLength);

            return (value.Length <= maxLength
                   ? value
                   : value.Substring(0, maxLength)
                   );
        }

        public static string ToBlankHtml(this object value)
        {
            if (value == DBNull.Value) return "&nbsp;";
            if (value == null) return "&nbsp;";

            return value.ToString();
        }

		public static string ToStringEx(this object value)
		{
			if (value == DBNull.Value) return null;
			if (value == null) return null;

			return Convert.ToString(value);
		}
		public static int? ToIntEx(this object value)
		{
			if (value == DBNull.Value) return null;
			if (value == null) return null;

			return Convert.ToInt32(value);
		}
		public static bool? ToBoolEx(this object value)
		{
			if (value == DBNull.Value) return null;
			if (value == null) return null;
			return Convert.ToBoolean(value);
		}
		public static double? ToDoubleEx(this object value)
		{
			if (value == DBNull.Value) return null;
			if (value == null) return null;
			return Convert.ToDouble(value);
		}
		public static DateTime? ToDateTimeEx(this object value)
		{
			if (value == DBNull.Value) return null;
			if (value == null) return null;
			return Convert.ToDateTime(value);
		}
	}

	public static class EnumExtensionMethods
	{
		public static string GetDescription(this Enum value)
		{
			var type = value.GetType();
			var memberInfo = type.GetMember(value.ToString());
			if (memberInfo.Length > 0)
			{
				var attributes = memberInfo[0].GetCustomAttributes(typeof(DescriptionAttribute), false);
				if (attributes.Length > 0)
				{
					return ((DescriptionAttribute) attributes[0]).Description;
				}
			}
			return value.ToString();
		}

		public static T FromString<T>(this string value)
		{
			return (T) Enum.Parse(typeof (T), value);
		}
	}

    public static class StringBuilderExtensions
    {
        public static StringBuilder RemoveLast(this StringBuilder sb, int numChars = 1)
        {
            if (numChars > sb.Length)
                numChars = sb.Length;
            sb.Remove(sb.Length - numChars, numChars);

            return sb;
        }
    }

    public static class Utils
    {
        public static string AppendAutoVersion(string path)
        {
            try
            {
                var mappedPath = HttpContext.Current.Server.MapPath(path);
                if (String.IsNullOrWhiteSpace(mappedPath))
                    return QProcess.Session.CurrentSession.UserTimeZone.GetLocalTimeNow().ToString("yyyyMMddHHmm");

                return File.GetLastWriteTime(mappedPath).ToString("yyyyMMddHHmm");
            }
            catch (Exception)
            {
                return QProcess.Session.CurrentSession.UserTimeZone.GetLocalTimeNow().ToString("yyyyMMddHHmm");
            }


        }
    }
}
/* Copyright © 2024 Renegade Swish, LLC */

