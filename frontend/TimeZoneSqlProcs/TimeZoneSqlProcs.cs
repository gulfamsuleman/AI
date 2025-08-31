using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using Microsoft.SqlServer.Server;
using TimeZoneConverter;

namespace TimeZoneSqlProcs
{
    public static class TimeZoneSqlProcs
    {
        static TimeZoneInfo GetTimeZoneInfo(string ianaName)
            => TZConvert.GetTimeZoneInfo(ianaName);

        private static (DateTime, string) FormatSingleTime(DateTime dte, string tz, int day = 0)
        {
            var tzi = GetTimeZoneInfo(tz);
            var ldt = TimeZoneInfo.ConvertTimeFromUtc(dte, tzi);
            var nme = tzi.IsDaylightSavingTime(ldt) ? tzi.DaylightName : tzi.StandardName;
            var abr = 
                  tzi.Id.StartsWith("GMT") ? (tzi.IsDaylightSavingTime(ldt) ? "BST" : "GMT")
                : tzi.Id.StartsWith("W. Europe") ? (tzi.IsDaylightSavingTime(ldt) ? "CEST" : "CET")
                : tzi.Id.StartsWith("W. Australia") ? "AWST"
                : string.Join("", nme.Split(' ').Where(s => s.Length > 2).Select(s => s[0]));

            if (day == 0 || day != ldt.Day)
                return (ldt, TimeZoneInfo.ConvertTimeFromUtc(dte, tzi).ToString("MM/dd/yyyy hh:mm tt ") + abr);
            else
                return (ldt, TimeZoneInfo.ConvertTimeFromUtc(dte, tzi).ToString("hh:mm tt ") + abr);
        }

        [SqlFunction(DataAccess = DataAccessKind.Read)]
        public static string ConvertTimeFromUtc(string date, string dstTz)
        {
            if (String.IsNullOrWhiteSpace(date)) return null;
            if (String.IsNullOrWhiteSpace(dstTz)) dstTz = TimeZoneInfo.Local.DisplayName;

            var dte = DateTime.Parse(date);
            var dstTzi = GetTimeZoneInfo(dstTz);

            return TimeZoneInfo.ConvertTimeFromUtc(dte, dstTzi).ToString("MM/dd/yyyy hh:mm tt");
        }

        [SqlFunction(DataAccess = DataAccessKind.Read)]
        public static string ConvertTimeToUtc(string date, string srcTz) => ConvertTimeToUtcImpl(date, srcTz, false);

        public static string ConvertTimeToUtcImpl(string date, string srcTz, bool isRetry)
        {
            if (String.IsNullOrWhiteSpace(date)) return null;
            if (String.IsNullOrWhiteSpace(srcTz)) srcTz = TimeZoneInfo.Local.DisplayName;

            var dte = DateTime.Parse(date);
            try
            {                
                var srcTzi = GetTimeZoneInfo(srcTz);

                return TimeZoneInfo.ConvertTimeToUtc(dte, srcTzi).ToString("MM/dd/yyyy hh:mm tt");
            }
            catch(ArgumentException aex)
            {
                if (!isRetry && aex.Message.StartsWith("The supplied DateTime represents an invalid time."))
                    return ConvertTimeToUtcImpl(dte.AddHours(1).ToString("MM/dd/yyyy hh:mm tt"), srcTz, true);

                throw;
            }
        }

        [SqlFunction(DataAccess = DataAccessKind.Read)]
        public static string ConvertTime(string date, string srcTz, string dstTz)
        {
            if (String.IsNullOrWhiteSpace(date)) return null;
            if (String.IsNullOrWhiteSpace(srcTz)) srcTz = TimeZoneInfo.Local.DisplayName;
            if (String.IsNullOrWhiteSpace(dstTz)) dstTz = TimeZoneInfo.Local.DisplayName;

            //var dte = DateTime.Parse(date);
            //var srcTzi = GetTimeZoneInfo(srcTz);
            //var dstTzi = GetTimeZoneInfo(dstTz);

            return ConvertTimeFromUtc(ConvertTimeToUtc(date, srcTz), dstTz);
                //.ToString("MM/dd/yyyy hh:mm tt");
        }

        [SqlFunction(DataAccess = DataAccessKind.Read)]
        public static string FormatTime(string date, string localTz, string timezones)
        {
            /*
            using(var file = File.Open(@"C:\scripts\SQL_CLR\Logs\Log.txt", FileMode.Append, FileAccess.Write))
            using (var writer = new StreamWriter(file))
                writer.WriteLine($"FormatTime called - date: '{date}', localTz: '{localTz}', timezones: '{timezones}'");
            */

            var timezone = timezones.Split(new[] { ',' }, StringSplitOptions.RemoveEmptyEntries);
            var dte = DateTime.Parse(date);
            var rst = new List<string>();
            var (ldt, pri) = FormatSingleTime(dte, localTz);
            
            foreach (var tz in timezone)
            {
                if (tz == localTz) continue;
                rst.Add(FormatSingleTime(dte, tz, ldt.Day).Item2);                
            }

            if (rst.Count > 0)
                return pri + $" ({string.Join(", ", rst.Distinct())})";
            else
                return pri;
        }

    }
}
