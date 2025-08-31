using System;
using System.Data.Entity;
using System.Diagnostics;
using System.Diagnostics.Eventing.Reader;
using System.Linq;
using System.Net.Mail;
using System.Web;
using System.Web.Security;
using System.Web.Services;
using Entities;
using Entities.Enums;

/// <summary>
/// Summary description for NagService
/// </summary>
[WebService(Namespace = "http://tempuri.org/")]
[WebServiceBinding(ConformsTo = WsiProfiles.BasicProfile1_1)]
[System.ComponentModel.ToolboxItem(false)]
// To allow this Web Service to be called from script, using ASP.NET AJAX, uncomment the following line. 
[System.Web.Script.Services.ScriptService]
public class NagService : WebService
{
    private NagSecurityProvider _secProvider;
    public UserInfo CurrentUser { get; private set; }

    public NagService()
    {
        _secProvider = new NagSecurityProvider();
        CurrentUser = _secProvider.GetUserInfo();
    }

    [WebMethod(true)]
    public Nag[] GetNagsUserControls(string filter)
    {
        var loginId = CurrentUser.LoginId;

        using (var db = new AcmeDataContext())
        {
            db.Database.Log = s => Debug.WriteLine(s);
            db.Configuration.ProxyCreationEnabled = false;
            db.Configuration.LazyLoadingEnabled = false;
            var query = db.Nags
                .Where(n => n.ControllerID == loginId
                            && !n.IsDeleted)
                .Include(n => n.Recipients.Select(r => r.User))
                .Include(n => n.Controller)
                .Include(n => n.MonthlySchedules);

            //Search/Link Filter
            if (String.IsNullOrWhiteSpace(filter) == false)
            {
                if (filter.StartsWith("#"))
                {
                    var filterId = 0;
                    if(int.TryParse(filter.Substring(1), out filterId))
                        query = query.Where(n => n.NagID == filterId);
                }
                else
                    query = query.Where(n => n.Subject.Contains(filter) || n.BodyText.Contains(filter));
            }
                    
            var result = query.ToArray();

            //strip backreferences
            foreach (var nag in result)
            {
                nag.Controller.ControlledNags = null;
                nag.Controller.Recipients = null;

                //ICollection isn't serializable, but the serializer's smart enough
                //to determine the underlying type; just make it an easy one to serialize
                nag.Recipients = nag.Recipients
                    .OrderBy(r => r.User.FullName)
                    .ToArray();

                foreach (var recipient in nag.Recipients)
                {
                    recipient.Nag = null;
                    if (recipient.User != null)
                        recipient.User.Recipients = null;
                }

                nag.MonthlySchedules = nag.MonthlySchedules.ToArray();
                foreach (var schedule in nag.MonthlySchedules)
                    schedule.Nag = null;
            }

            return result;
        }
    }

    [WebMethod(true)]
    public Nag[] GetNagsUserReceives(string filter)
    {
        var loginId = CurrentUser.LoginId;

        using (var db = new AcmeDataContext())
        {
            db.Database.Log = s => Debug.WriteLine(s);
            db.Configuration.ProxyCreationEnabled = false;
            db.Configuration.LazyLoadingEnabled = false;
            var query = db.Nags
                .Where(n => n.Recipients.Any(r => r.RecipientID == loginId)
                            && !n.IsDeleted)
                .Include(n => n.Recipients.Select(r => r.User))
                .Include(n => n.MonthlySchedules)
                .Include(n => n.Controller);

            //Search/Link Filter
            if (String.IsNullOrWhiteSpace(filter) == false)
            {
                if (filter.StartsWith("#"))
                {
                    var filterId = 0;
                    if (int.TryParse(filter.Substring(1), out filterId))
                        query = query.Where(n => n.NagID == filterId);
                }
                else
                    query = query.Where(n => n.Subject.Contains(filter) || n.BodyText.Contains(filter));
            }

            var result = query.ToArray();

            //strip backreferences
            foreach (var nag in result)
            {
                nag.Controller.ControlledNags = null;
                nag.Controller.Recipients = null;
                    
                //ICollection isn't serializable, but the serializer's smart enough
                //to determine the underlying type; just make it an easy one to serialize
                nag.Recipients = nag.Recipients
                    .Where(r => r.RecipientID == loginId)
                    .ToArray();

                foreach (var recipient in nag.Recipients)
                {
                    recipient.Nag = null;
                    if (recipient.User != null)
                        recipient.User.Recipients = null;
                }

                nag.MonthlySchedules = nag.MonthlySchedules.ToArray();
                foreach (var schedule in nag.MonthlySchedules)
                    schedule.Nag = null;
            }

            result = result.OrderBy(n => n.IsPaused
                ? 4
                : n.Recipients.Any(r => r.IsPaused)
                    ? 3
                    : n.Recipients.Any(r => r.SnoozeUntil > DateTime.Now)
                        ? 2
                        : 1)
                .ThenBy(n=>n.Subject).ToArray();

            return result;
        }
    }

    [WebMethod(true)]
    public void TogglePlayPause(int nagId, string loginId, bool allUsers)
    {
        using (var db = new AcmeDataContext())
        {
            var nag = db.Nags.First(n => n.NagID == nagId);

            if (allUsers)
                nag.IsPaused = !nag.IsPaused;
            else
            {
                if (String.IsNullOrWhiteSpace(loginId))
                    loginId = CurrentUser.LoginId;

                var recipients = nag.Recipients.Where(r => r.RecipientID == loginId);
                foreach (var recipient in recipients)
                {
                    if (recipient.SnoozeUntil > DateTime.Now) //we're really "un-snoozing"
                        recipient.SnoozeUntil = DateTime.Now.AddSeconds(-1);
                    else
                        recipient.IsPaused = !recipient.IsPaused;
                }
            }

            if (!allUsers && loginId == CurrentUser.LoginId)
            {
                var recipient = nag.Recipients.First(r => r.RecipientID == loginId);
                var isPaused = recipient.IsPaused;
                var message = new MailMessage();
                message.To.Add(new MailAddress(nag.Controller.QEmailAddress, nag.Controller.FullName));
                message.From = new MailAddress("sqlmail@acmewidget.com", "NagQ Mail");
                message.Subject = String.Format("ALERT - NAG HAS BEEN TURNED {0}", isPaused ? "OFF" : "ON");
                message.Body = String.Format(
                    "{0} has elected to {1} receiving the nag for {2}{3}",
                    recipient.User.FullName,
                    isPaused ? "stop" : "start",
                    nag.Subject,
                    isPaused ? "." : " again.");

                using (var srv = new SmtpClient(System.Configuration.ConfigurationManager.AppSettings["SMTPServer"], Convert.ToInt32(System.Configuration.ConfigurationManager.AppSettings["smtpport"])))
                {
                    srv.EnableSsl = true;
                    srv.UseDefaultCredentials = false;
                    srv.Credentials = new System.Net.NetworkCredential(System.Configuration.ConfigurationManager.AppSettings["smtpuser"], System.Configuration.ConfigurationManager.AppSettings["smtppass"]);
                    srv.Send(message);
                }
            }

            db.SaveChanges();
        }
    }

    [WebMethod(true)]
    public void ToggleDelete(int nagId, bool? forceValue)
    {
        using (var db = new AcmeDataContext())
        {
            var nag = db.Nags.First(n => n.NagID == nagId);

            nag.IsDeleted = forceValue ?? !nag.IsDeleted;
            nag.DeletedDate = nag.IsDeleted ? (DateTime?) DateTime.Now : null;

            db.SaveChanges();
        }
    }

    [WebMethod(true)]
    public Nag GetNagDetails(int nagId)
    {
        if (nagId == 0) //new record
            return new Nag
            {
                NagID = 0,
                ControllerID = CurrentUser.LoginId,
                Recipients = new Recipient[0],
                DaysOfWeek = (DaysOfWeek)127,
                TimesOfDay = null,
                Interval = 60,
                StartTime = new DateTime(2000, 1, 1, 8, 0, 0),
                EndTime = new DateTime(2000, 1, 1, 18, 0, 0),
            };

        using (var db = new AcmeDataContext())
        {
            db.Configuration.ProxyCreationEnabled = false;
            db.Configuration.LazyLoadingEnabled = false;

            var nag = db.Nags
                .Include(n=>n.Recipients.Select(r=>r.User))
                .Include(n=>n.Controller)
                .Include(n=>n.MonthlySchedules)
                .First(n => n.NagID == nagId);

            nag.Controller.ControlledNags = null;
            nag.Controller.Recipients = null;

            foreach (var recipient in nag.Recipients)
            {
                recipient.Nag = null;
                recipient.User.Recipients = null;
            }

            foreach (var schedule in nag.MonthlySchedules)
            {
                schedule.Nag = null;
            }

            nag.Recipients = nag.Recipients
                .OrderBy(r=>r.User.FullName)
                .ToArray();

            return nag;
        }
                
    }

    [WebMethod(true)]
    public User[] GetUserList()
    {
        using (var db = new AcmeDataContext())
        {
            db.Configuration.ProxyCreationEnabled = false;
            db.Configuration.LazyLoadingEnabled = false;

            var users = db.Users.Where(u => u.IsActive == true)
                .OrderBy(u=>u.FullName).ToArray();

            return users;
        }
    }

    [WebMethod(true)]
    public void SaveNag(Nag nag)
    {
        using (var db = new AcmeDataContext())
        {
            //TODO: Data validation

            var now = DateTime.Now;
            var wasPaused = false;
            if (nag.NagID == 0)
            {
                nag.CreatedDate = nag.ModifiedDate = now;
                nag.CreatedBy = nag.ModifiedBy = CurrentUser.LoginId;
                    
                foreach (var recipient in nag.Recipients)
                    recipient.IsPaused = false;

                //Remove blank rows (already handled for edits)
                nag.Recipients = nag.Recipients
                    .Where(r => !String.IsNullOrWhiteSpace(r.RecipientID))
                    .ToArray();

                nag.MonthlySchedules = nag.MonthlySchedules
                    .Where(s => s.MonthFrequency != 0
                                && s.Ordinal > 0)
                    .ToArray();
                        
                db.Nags.Add(nag);
            }
            else
            {
                var nagFromDb = db.Nags.Where(n => n.NagID == nag.NagID)
                    .Include(n => n.MonthlySchedules)
                    .Include(n => n.Recipients)
                    .First();
                wasPaused = nagFromDb.IsPaused && !nag.IsPaused;
                nagFromDb.ModifiedDate = now;
                nagFromDb.ModifiedBy = CurrentUser.LoginId;

                nagFromDb.Subject = nag.Subject;
                nagFromDb.BodyText = nag.BodyText;
                nagFromDb.StartDate = nag.StartDate;
                nagFromDb.EndDate = nag.EndDate;
                nagFromDb.DaysOfWeek = nag.DaysOfWeek;
                nagFromDb.Interval = nag.Interval;
                nagFromDb.StartTime = nag.StartTime;
                nagFromDb.EndTime = nag.EndTime;
                nagFromDb.TimesOfDay = nag.TimesOfDay;
                nagFromDb.ControllerID = nag.ControllerID;

                //Recipients; deal with as added/deleted
                var added = nag.Recipients
                    .Where(r => nagFromDb.Recipients
                        .Select(r2 => r2.RecipientID)
                        .Contains(r.RecipientID) == false
                                && String.IsNullOrWhiteSpace(r.RecipientID) == false)
                    .GroupBy(r=>r.RecipientID)
                    .Select(g=>new Recipient
                    {
                        RecipientID = g.Key,
                        IsPaused = false,
                    }).ToArray();

                var deleted = nagFromDb.Recipients
                    .Where(r => nag.Recipients
                        .Select(r2 => r2.RecipientID)
                        .Contains(r.RecipientID) == false).ToArray();

                foreach (var toAdd in added)
                    nagFromDb.Recipients.Add(toAdd);

                foreach (var toDelete in deleted)
                    nagFromDb.Recipients.Remove(toDelete);

                //Monthly schedules; these can also be updated
                var addedSched = nag.MonthlySchedules
                    .Where(s => s.ScheduleID == 0).ToArray();

                var deletedSched = nagFromDb.MonthlySchedules
                    .Where(s => nag.MonthlySchedules
                        .Select(s2 => s2.ScheduleID)
                        .Contains(s.ScheduleID) == false).ToArray();

                foreach (var toDelete in deletedSched)
                {
                    nagFromDb.MonthlySchedules.Remove(toDelete);
                    db.MonthlySchedules.Remove(toDelete);
                }

                foreach (var schedule in nag.MonthlySchedules.Where(s=>s.ScheduleID != 0))
                {
                    var toUpdate = nagFromDb.MonthlySchedules.FirstOrDefault(s=>s.ScheduleID == schedule.ScheduleID);
                    //shouldn't happen, we've deleted all the ones 
                    if (toUpdate == null) continue;

                    toUpdate.DaysOfWeek = schedule.DaysOfWeek;
                    toUpdate.MonthFrequency = schedule.MonthFrequency;
                    toUpdate.Ordinal = schedule.Ordinal;
                    toUpdate.XMonths = schedule.XMonths;
                }

                foreach (var toAdd in addedSched)
                    nagFromDb.MonthlySchedules.Add(toAdd);
            }

            db.SaveChanges();

            db.UpdateRunTimes(nag.NagID, now, wasPaused);
        }
    }

    [WebMethod(true)]
    public void RemoveCurrentRecipient(int nagId)
    {
        var currentUser = CurrentUser.LoginId;

        using (var db = new AcmeDataContext())
        {
            var nag = db.Nags.Include(n=>n.Recipients).FirstOrDefault(n => n.NagID == nagId);

            if(nag == null)
                throw new Exception("This Nag ID doesn't exist.");

            if(nag.Recipients.All(r => r.RecipientID != currentUser))
                throw new Exception("You are not currently associated with this Nag.");

            var toRemove = nag.Recipients.Where(r => r.RecipientID == currentUser).ToArray();
            foreach (var remove in toRemove)
            {
                nag.Recipients.Remove(remove);
                db.Recipients.Remove(remove);
            }

            db.SaveChanges();

            var message = new MailMessage();
            message.To.Add(new MailAddress(nag.Controller.QEmailAddress, nag.Controller.FullName));
            message.From = new MailAddress("sqlmail@acmewidget.com", "NagQ Mail");
            message.Subject = "ALERT - RECIPIENT HAS REMOVED THEMSELVES FROM NAG";
            message.Body =
                String.Format("{0} has removed themselves from the nag for {1}.",
                    CurrentUser.FullName,
                    nag.Subject);

            using (var srv = new SmtpClient(System.Configuration.ConfigurationManager.AppSettings["SMTPServer"], Convert.ToInt32(System.Configuration.ConfigurationManager.AppSettings["smtpport"])))
            {
                srv.EnableSsl = true;
                srv.UseDefaultCredentials = false;
                srv.Credentials = new System.Net.NetworkCredential(System.Configuration.ConfigurationManager.AppSettings["smtpuser"], System.Configuration.ConfigurationManager.AppSettings["smtppass"]);
                srv.Send(message);
            }
        }
    }

    [WebMethod(true)]
    public void SnoozeCurrentRecipient(int nagId, DateTime? snoozeUntil)
    {
        var currentUser = CurrentUser.LoginId;
        if (snoozeUntil == null)
            snoozeUntil = DateTime.Today.AddDays(1);

        using (var db = new AcmeDataContext())
        {
            var nag = db.Nags.Include(n => n.Recipients).FirstOrDefault(n => n.NagID == nagId);

            if (nag == null)
                throw new Exception("This Nag ID doesn't exist.");

            if (nag.Recipients.All(r => r.RecipientID != currentUser))
                throw new Exception("You are not currently associated with this Nag.");

            var toSnooze = nag.Recipients.Where(r => r.RecipientID == currentUser).ToArray();
            foreach (var snooze in toSnooze)
            {
                snooze.SnoozeUntil = snoozeUntil;
            }

            db.SaveChanges();

            var message = new MailMessage();
            message.To.Add(new MailAddress(nag.Controller.QEmailAddress, nag.Controller.FullName));
            message.From = new MailAddress("sqlmail@acmewidget.com", "NagQ Mail");
            message.Subject = "Notification - Recipient Has Snoozed Nag";
            message.Body =
                String.Format(
                    "{0} has snoozed the nag for {1} until {2}.",
                    CurrentUser.FullName,
                    nag.Subject,
                    snoozeUntil
                    );

            using (var srv = new SmtpClient(System.Configuration.ConfigurationManager.AppSettings["SMTPServer"], Convert.ToInt32(System.Configuration.ConfigurationManager.AppSettings["smtpport"])))
            {
                srv.EnableSsl = true;
                srv.UseDefaultCredentials = false;
                srv.Credentials = new System.Net.NetworkCredential(System.Configuration.ConfigurationManager.AppSettings["smtpuser"], System.Configuration.ConfigurationManager.AppSettings["smtppass"]);
                srv.Send(message);
            }
        }
    }

    [WebMethod(true)]
    public void Logout()
    {
        FormsAuthentication.SignOut();
        var cookie = HttpContext.Current.Request.Cookies[FormsAuthentication.FormsCookieName]
                     ?? new HttpCookie(FormsAuthentication.FormsCookieName);
        cookie.Expires = DateTime.Now.AddSeconds(-1);
        HttpContext.Current.Response.SetCookie(cookie);
    }
}
/* Copyright © 2024 Renegade Swish, LLC */

