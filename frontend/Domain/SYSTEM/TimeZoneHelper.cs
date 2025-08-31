using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using TimeZoneConverter;

namespace QProcess.Domain.SYSTEM
{
    public static class TimeZoneHelper
    {
        public const string FALLBACK_TIMEZONE = "UTC";

        /// <summary>
        /// Pass in a date/time in source time zone and it'll return back the same date/time in the destination time zone.
        /// </summary>
        /// <param name="srcTz">Source time zone</param>
        /// <param name="dstTz">Destination time zone</param>
        /// <param name="dt">DateTime in source time zone</param>
        /// <returns>DateTime in destination time zone</returns>
        public static DateTime GetDateTimeBetweenTimeZone(TimeZoneInfo srcTz, TimeZoneInfo dstTz, DateTime dt)
            => dt.AddMinutes(GetOffsetBetweenTimeZone(srcTz, dstTz, dt));

        /// <summary>
        /// The distance can be positive or negative, depending on if the destination time zone is in front or behind the source time zone.
        /// </summary>
        /// <param name="srcTz">Source time zone</param>
        /// <param name="dstTz">Destination time zone</param>
        /// <param name="dt">DateTime in source time zone</param>
        /// <returns>Distance in minutes from the source time zone to the destination time zone</returns>
        public static double GetOffsetBetweenTimeZone(TimeZoneInfo srcTz, TimeZoneInfo dstTz, DateTime dt)
        {
            var srcOffset = srcTz.GetUtcOffset(dt);
            var dstOffset = dstTz.GetUtcOffset(dt);
            var distance = Math.Abs(srcOffset.Subtract(dstOffset).TotalMinutes);
            return distance * (srcOffset > dstOffset ? -1 : 1);
        }
        public static double GetOffsetBetweenTimeZone(TimeZoneInfo srcTz, TimeZoneInfo dstTz)
        {
            var srcDt = DateTime.SpecifyKind(DateTime.UtcNow, DateTimeKind.Unspecified);
            if (srcTz.StandardName != FALLBACK_TIMEZONE) srcDt = TimeZoneInfo.ConvertTimeFromUtc(srcDt, srcTz);

            var srcOffset = srcTz.GetUtcOffset(srcDt);
            var dstOffset = dstTz.GetUtcOffset(srcDt);
            var distance = Math.Abs(srcOffset.Subtract(dstOffset).TotalMinutes);
            return distance * (srcOffset > dstOffset ? -1 : 1);
        }

        /// <summary>
        /// Give back a TimeZoneInfo object that can be used to determine offset from UTC, taking into consideration daylight saving for the given time zone.
        /// </summary>
        /// <param name="tzName">Time zone name in either IANA or common name</param>
        /// <param name="fallbackTzName">Time zone name to fallback in case provided name is invalid</param>
        /// <returns>TimeZoneInfo object of the specified time zone</returns>
        public static TimeZoneInfo GetTimeZone(string tzName, string fallbackTzName = FALLBACK_TIMEZONE)
        {
            if (string.IsNullOrWhiteSpace(tzName))
                return TZConvert.GetTimeZoneInfo(fallbackTzName);

            try
            {
                return TZConvert.GetTimeZoneInfo(tzName);
            }
            catch (Exception)
            {
                return TZConvert.GetTimeZoneInfo(fallbackTzName);
            }
        }

        /// <summary>
        /// Translate the current TimeZoneInfo object into the standard name with the GMT offset, e.g., Central Daylight Time (GMT-5:00)
        /// </summary>
        public static string GetGmtString(this TimeZoneInfo tz)
        {
            string name;
            var offset = tz.GetUtcOffset(DateTime.UtcNow);

            if (tz.IsDaylightSavingTime(DateTime.UtcNow))
                name = tz.DaylightName;
            else
                name = tz.StandardName;

            if (offset.Hours >= 0)
                return name + " (GMT+" + offset.Hours + ":" + offset.Minutes.ToString("00") + ")";
            else
                return name + " (GMT" + offset.Hours + ":" + offset.Minutes.ToString("00") + ")";
        }

        public static string GetAbbrString(this TimeZoneInfo tz)
        {
            string output = string.Empty;

            string[] timeZoneWords = tz.Id.Split(' ');
            foreach (string timeZoneWord in timeZoneWords)
            {
                if (timeZoneWord[0] != '(') output += timeZoneWord[0];
                //else output += timeZoneWord;
            }
            return output;
        }

        public static string[] GetTimeZoneNamesByCountryCode(string countryCode = "US")
            => TZConvert.GetIanaTimeZoneNamesByTerritory(true)[countryCode].ToArray();

        public static Dictionary<string, int> CommonTimeZones => new Dictionary<string, int>{
             {"America/New_York", 1}
            ,{"America/Chicago", 2}
            ,{"America/Denver", 3}
            ,{"America/Phoenix", 4}
            ,{"America/Los_Angeles", 5}
            ,{"America/Port_of_Spain", 6}
            ,{"Europe/London", 7}
            ,{"Asia/Nicosia", 8}
            ,{"Asia/Manila", 9}
            ,{"Australia/Perth", 10}
            ,{"Pacific/Auckland", 11}
        };

        public static string[] GetAllTimeZoneNames(bool commonFirst = false)
            => TZConvert.GetIanaTimeZoneNamesByTerritory(true)
                .SelectMany(tz => tz.Value)
                .Distinct()
            .OrderBy(s => commonFirst 
                ? (CommonTimeZones.ContainsKey(s) 
                    ? CommonTimeZones[s] 
                    : 999)
                : 0)
            .ThenBy(s => s)
                .ToArray();
    }
}
/* Copyright © 2024 Renegade Swish, LLC */

