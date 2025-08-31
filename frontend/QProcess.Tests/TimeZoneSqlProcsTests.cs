using Microsoft.VisualStudio.TestTools.UnitTesting;
using System;
using System.Diagnostics;

namespace QProcess.Tests
{
    [TestClass]
    public class TimeZoneSqlProcsTests
    {
        [TestMethod]
        public void TestConvertTimeToUtc()
        {
            var rightNow = QProcess.Session.CurrentSession.UserTimeZone.GetLocalTimeNow();
            var nowString = rightNow.ToString("MM/dd/yyyy hh:mm tt");
            var expected = rightNow.ToUniversalTime().ToString("MM/dd/yyyy hh:mm tt");
            var nowUtcString = TimeZoneSqlProcs.TimeZoneSqlProcs.ConvertTimeToUtc(nowString, "America/Chicago");

            Assert.AreEqual(expected, nowUtcString);
        }

        [TestMethod]
        public void TestInvalidTime()
        {
            //2:30 AM on a "spring-forward" day - invalid. Should handle by adding an hour
            var nowString = "03/09/2025 02:30 AM";
            var dateTime = DateTime.Parse(nowString);
            var expected = "03/09/2025 08:30 AM";
            var nowUtcString = TimeZoneSqlProcs.TimeZoneSqlProcs.ConvertTime(nowString, "America/Chicago", "UTC");
            Console.WriteLine($"{dateTime} => {nowUtcString}");
            Assert.AreEqual(expected, nowUtcString);

            //2:30 AM on a "spring-forward" day - invalid. Should handle by adding an hour
            nowString = "03/09/2025 02:30 AM";
            dateTime = DateTime.Parse(nowString);            
            expected =  "03/09/2025 08:30 AM";
            nowUtcString = TimeZoneSqlProcs.TimeZoneSqlProcs.ConvertTimeToUtc(nowString, "America/Chicago");
            Console.WriteLine($"{dateTime} => {nowUtcString}");
            Assert.AreEqual(expected, nowUtcString);            

            //11/3/2024 6:30 AM UTC => 11/3/2024 1:30 AM CDT, and 11/3/2024 7:30 AM UTC => 11/3/2024 1:30 AM CST (1 hour apart)
            //We really don't care about the ambiguity as long as it converts
            nowString = "11/03/2024 06:30 AM";
            dateTime = DateTime.Parse(nowString);
            expected = "11/03/2024 01:30 AM";
            nowUtcString = TimeZoneSqlProcs.TimeZoneSqlProcs.ConvertTimeFromUtc(nowString, "America/Chicago");
            Console.WriteLine($"{dateTime} => {nowUtcString}");
            Assert.AreEqual(expected, nowUtcString);

            nowString = "11/03/2024 07:30 AM";
            dateTime = DateTime.Parse(nowString);
            expected = "11/03/2024 01:30 AM";
            nowUtcString = TimeZoneSqlProcs.TimeZoneSqlProcs.ConvertTimeFromUtc(nowString, "America/Chicago");
            Console.WriteLine($"{dateTime} => {nowUtcString}");
            Assert.AreEqual(expected, nowUtcString);

            //And checking what converts to UTC
            nowString = "11/03/2024 01:30 AM";
            dateTime = DateTime.Parse(nowString);
            expected = "11/03/2024 07:30 AM";
            nowUtcString = TimeZoneSqlProcs.TimeZoneSqlProcs.ConvertTimeToUtc(nowString, "America/Chicago");
            Console.WriteLine($"{dateTime} => {nowUtcString}");
            Assert.AreEqual(expected, nowUtcString);
        }

        [TestMethod]
        public void TestConvertTimeFromUtc()
        {
            var rightNowUtc = DateTime.UtcNow;
            var nowUtcString = rightNowUtc.ToString("MM/dd/yyyy hh:mm tt");
            var expected = rightNowUtc.ToLocalTime().ToString("MM/dd/yyyy hh:mm tt");
            var nowString = TimeZoneSqlProcs.TimeZoneSqlProcs.ConvertTimeFromUtc(nowUtcString, "America/Chicago");

            Assert.AreEqual(expected, nowString);
        }

        [TestMethod]
        public void TestConvertTime()
        {
            var rightNow = QProcess.Session.CurrentSession.UserTimeZone.GetLocalTimeNow();
            var nowString = rightNow.ToString("MM/dd/yyyy hh:mm tt");
            var expected = rightNow.ToUniversalTime().ToString("MM/dd/yyyy hh:mm tt");
            var nowUtcString = TimeZoneSqlProcs.TimeZoneSqlProcs.ConvertTime(nowString, "America/Chicago", "UTC");

            Assert.AreEqual(expected, nowUtcString);
        }

        [TestMethod]
        public void TestFormatTime()
        {
            var rightNowUtc = DateTime.UtcNow;
            var nowUtcString = rightNowUtc.ToString("MM/dd/yyyy hh:mm tt");
            var expected = rightNowUtc.ToUniversalTime().ToString("MM/dd/yyyy hh:mm tt");
            var nowString = TimeZoneSqlProcs.TimeZoneSqlProcs.FormatTime(nowUtcString, "America/Chicago",
                "America/New_York,America/Denver,America/Phoenix,America/Los_Angeles,Europe/London,Europe/Rome,Australia/Perth");

            Console.WriteLine(nowString);
        }
    }
}
