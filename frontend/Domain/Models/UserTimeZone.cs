using DataAccessLayer;
using QProcess.Extensions;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.Common;
using System.Linq;
using System.Runtime.Serialization;
using System.Text.Json.Serialization;
using System.Web;
using System.Xml.Serialization;
using static QProcess.Domain.SYSTEM.TimeZoneHelper;

namespace QProcess.Domain.Models
{
    public class UserTimeZone
    {
        private string _lastTimeZone = null;
        private string _timeZoneOverride = null;

        public int GmtOffset 
        {
            get {
                if (SystemTimeZone == null)
                    return 0;
                else
                    return GetOffsetBetweenTimeZone(SystemTimeZone, ClientTimeZone).ToIntEx().Value;
            }
        }
        public string TimeZoneName { 
            get 
            {  
                return _timeZoneOverride ?? _lastTimeZone; 
            } 
        }
        public string LastTimeZone 
        {
            get {
                return _lastTimeZone;
            } 
            set
            {
                if (string.IsNullOrWhiteSpace(value))
                    _lastTimeZone = null;
                else
                    _lastTimeZone = value;

                SetClientTimeZone();
            }
        }
        public string TimeZoneOverride
        {
            get
            {
                return _timeZoneOverride;
            }
            set
            {
                if (string.IsNullOrWhiteSpace(value))
                    _timeZoneOverride = null;
                else
                    _timeZoneOverride = value;

                SetClientTimeZone();
            }
        }

        public string SystemTimeZoneName
        {
            get => SystemTimeZone.DisplayName;
            set => GetTimeZone(value);
        }

        [SoapIgnore, XmlIgnore, JsonIgnore, IgnoreDataMember]
        public TimeZoneInfo SystemTimeZone { get; set; } = null;

        [SoapIgnore, XmlIgnore, JsonIgnore, IgnoreDataMember]
        public TimeZoneInfo ClientTimeZone { get; set; } = null;
        
        public int DueTime { get; }

        public UserTimeZone() { SystemTimeZoneName = FALLBACK_TIMEZONE; }

        public UserTimeZone(string lastTimeZone, string timeZoneOverride, string systemTimeZone)
        {
            SystemTimeZone = GetTimeZone(systemTimeZone);
            LastTimeZone = lastTimeZone;
            TimeZoneOverride = timeZoneOverride;

            if (string.IsNullOrWhiteSpace(LastTimeZone))
                LastTimeZone = null;

            if (string.IsNullOrWhiteSpace(TimeZoneOverride))
                TimeZoneOverride = null;
        }

        public UserTimeZone(DataRow row, string systemTimeZone)
        {
            SystemTimeZone = GetTimeZone(systemTimeZone);
            LastTimeZone = row["LastTimeZone"].ToBlank();
            TimeZoneOverride = row["TimeZoneOverride"].ToBlank();
            DueTime = row["DueTime"].ToIntEx().Value;

            if (string.IsNullOrWhiteSpace(LastTimeZone))
                LastTimeZone = systemTimeZone;

            if (string.IsNullOrWhiteSpace(TimeZoneOverride))
                TimeZoneOverride = null;
        }

        public static UserTimeZone GetUserTimeZone(int userId, string systemTimeZone)
        {
            using (var db = new DBCommand("UserTimeZone_GET"))
            {
                var rs = db.Add("@userId", userId).ExecuteDataSet();

                if (rs.Tables.Count > 0 && rs.Tables[0].Rows.Count > 0)
                {
                    return new UserTimeZone(rs.Tables[0].Rows[0], systemTimeZone);
                }
                else
                {
                    throw new Exception($"User ID {userId} does not exist.");
                }
            }
        }
        public void Save(int userId)
        {
            using (var db = new DBCommand("UserTimeZone_SET"))
            {
                db.Add("@userId", userId)
                  //.Add("@gmtOffset", GmtOffset)
                  .Add("@lastTimeZone", LastTimeZone)
                  .Add("@timeZoneOverride", TimeZoneOverride)
                  .ExecuteNonQuery();
            }
        }
        public DateTime GetLocalTimeNow()
        {
            var dt = DateTime.SpecifyKind(DateTime.UtcNow, DateTimeKind.Unspecified);
            if (ClientTimeZone.StandardName != FALLBACK_TIMEZONE) 
                dt = TimeZoneInfo.ConvertTimeFromUtc(dt, ClientTimeZone);

            return dt;
        }
        public DateTime GetLocalTime(DateTime dt)
        {
            if (dt.Kind != DateTimeKind.Unspecified)
                dt = DateTime.SpecifyKind(dt, DateTimeKind.Unspecified);
        
            if (SystemTimeZone == null || SystemTimeZone.StandardName == FALLBACK_TIMEZONE)
                return TimeZoneInfo.ConvertTimeFromUtc(dt, ClientTimeZone);
            
            return TimeZoneInfo.ConvertTime(dt, SystemTimeZone, ClientTimeZone);
        }
        public DateTime? GetLocalTimeEx(DateTime dt) => GetLocalTime(dt);
        public DateTime? GetLocalTimeEx(DateTime? dt)
        {
            if (dt == null) return null;
            return GetLocalTimeEx(dt.Value);
        }
        
        public DateTime GetUtcTime(DateTime dt)
        {
            if (dt.Kind != DateTimeKind.Unspecified)
                dt = DateTime.SpecifyKind(dt, DateTimeKind.Unspecified);

            return TimeZoneInfo.ConvertTimeToUtc(dt, ClientTimeZone);
        }
        public DateTime GetSystemTimeNow()
        {
            var dt = DateTime.SpecifyKind(DateTime.UtcNow, DateTimeKind.Unspecified);
            if (SystemTimeZone == null || SystemTimeZone.StandardName == FALLBACK_TIMEZONE) return dt;

            return TimeZoneInfo.ConvertTimeFromUtc(dt, SystemTimeZone);
        }
        public DateTime GetSystemTime(DateTime dt)
        {
            if (SystemTimeZone == null || SystemTimeZone.StandardName == FALLBACK_TIMEZONE)
                return GetUtcTime(dt);

            if (dt.Kind != DateTimeKind.Unspecified)
                dt = DateTime.SpecifyKind(dt, DateTimeKind.Unspecified);

            return TimeZoneInfo.ConvertTime(dt, ClientTimeZone, SystemTimeZone);
        }
        public DateTime? GetSystemTimeEx(DateTime? dt)
        {
            if (dt == null) return null;
            return GetSystemTime(dt.Value);
        }
        public DateTime GetSystemTime()
        {
            var dt = DateTime.SpecifyKind(DateTime.UtcNow, DateTimeKind.Unspecified);
            if (SystemTimeZone == null || SystemTimeZone.StandardName == FALLBACK_TIMEZONE)
                return dt;

            return TimeZoneInfo.ConvertTimeFromUtc(dt, SystemTimeZone);
        }
        private void SetClientTimeZone()
        {
            var tz = TimeZoneOverride ?? LastTimeZone;
            ClientTimeZone = GetTimeZone(tz);
        }
    }
}
/* Copyright © 2024 Renegade Swish, LLC */

