using System;
using System.Web;
using System.IO;
using System.Text;

namespace QProcess
{
    public static class Log
    {
        public static void Write(string msg)
        {
            string path = HttpContext.Current.Server.MapPath("log");
            string file = path + "\\" + QProcess.Session.CurrentSession.UserTimeZone.GetLocalTimeNow().ToString("yyyyMMdd") + ".txt";
            StringBuilder sb = new StringBuilder();

            if (!Directory.Exists(path))
            {
                Directory.CreateDirectory(path);
            }
            var log = File.Open(file, FileMode.Append);
            sb.AppendLine("= = = = = = = = = = = = = =");
            sb.AppendLine(QProcess.Session.CurrentSession.UserTimeZone.GetLocalTimeNow().ToString());
            try { 
                sb.AppendLine(Session.CurrentSession?.QUser.Username); 
            }
            catch (Exception) { 
                sb.AppendLine("(Session lost - no user info)"); 
            }
            sb.AppendLine(msg);
            sb.AppendLine("");
            var sout = new StreamWriter(log);
            sout.WriteLine(sb.ToString());
            sout.Close();
            log.Close();
        }
    }
}
/* Copyright © 2024 Renegade Swish, LLC */

