using System;
using System.Configuration;
using System.Linq;
using System.Web;
using Entities;
using Entities.Enums;

public class NagSecurityProvider
{
    //Lifetime is per page request, to avoid multiple DB calls
    private UserInfo currentUser;

    public void AssertMinRole(string loginId, SecurityRoles role, HttpResponse response)
    {
        try
        {
            AssertMinRole(loginId, role);
        }
        catch (Exception)
        {
            response.StatusCode = 401; //forbidden
            response.End();
        }
    }
    public void AssertMinRole(SecurityRoles role)
    {
        AssertMinRole(HttpContext.Current.User.Identity.Name, role);
    }

    public void AssertMinRole(string loginId, SecurityRoles role)
    {
        //TODO: Uncomment once app is secured
        //if(!HasMinRole(loginId, role))
        //    throw new Exception("User is not authorized at the required level");
    }

    public bool HasMinRole(SecurityRoles role)
    {
        return HasMinRole(HttpContext.Current.User.Identity.Name, role);
    }

    public bool HasMinRole(string loginId, SecurityRoles role)
    {
        if (loginId.Contains("\\"))
            loginId = loginId.Split('\\').Last();

        var userInfo = GetUserInfo(loginId);

        return userInfo.RoleID >= (int) role;
    }

    public UserInfo GetUserInfo()
    {
        return GetUserInfo(ConfigurationManager.AppSettings["AppSecImpersonateUser"] ?? HttpContext.Current.User.Identity.Name);
    }

    public UserInfo GetUserInfo(string loginId, bool force = false)
    {
        var appId = ConfigurationManager.AppSettings["AppId"];
        if (currentUser != null && !force) return currentUser;

        if (loginId.Contains("\\"))
            loginId = loginId.Split('\\')[1];

        using (var db = new AcmeDataContext())
        {
            var result = db.GetUserInfo(loginId, appId).FirstOrDefault();
            currentUser = result ?? new UserInfo { FullName = "", Initials = "", RoleID = 0, RoleName = "No Access" };
            currentUser.LoginId = loginId;
            return result;
        }
    }
}
/* Copyright © 2024 Renegade Swish, LLC */

