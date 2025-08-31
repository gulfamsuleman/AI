using Microsoft.IdentityModel.Protocols.OpenIdConnect;
using Microsoft.IdentityModel.Tokens;
using Microsoft.Owin;
using Microsoft.Owin.Host.SystemWeb;
using Microsoft.Owin.Security;
using Microsoft.Owin.Security.Cookies;
using Microsoft.Owin.Security.Notifications;
using Microsoft.Owin.Security.OpenIdConnect;
using Owin;
using QProcess.Extensions;
using System;
using QProcess.Configuration;
using System.IdentityModel.Tokens.Jwt;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using System.Web;
using System.Collections.Generic;
using System.Security.Claims;

[assembly: OwinStartup(typeof(Web_Site.Helpers.Owin))]


namespace Web_Site.Helpers
{
    public class Owin
    {
        public static bool VerifyAuthentication(HttpRequest request)
        {
            var challengeIssued = (HttpContext.Current.Session["AuthChallenged"]?.ToBoolEx() ?? false);

            if (!request.IsAuthenticated /*&& !challengeIssued*/)
            {
                var prop = new AuthenticationProperties
                {
                    RedirectUri = request.Url.AbsoluteUri,//.Replace(request.Url.AbsolutePath, "/")
                    AllowRefresh = true,
                    IsPersistent = false,
                };

                if (HttpContext.Current.User.Identity is ClaimsIdentity identity)
                {
                    var loginHint = identity.FindFirst("login_hint");
                    if (!String.IsNullOrWhiteSpace(loginHint?.Value))
                        prop.Dictionary.Add("login_hint", loginHint.Value);
                }
                request.GetOwinContext().Authentication
                    .Challenge(prop, OpenIdConnectAuthenticationDefaults.AuthenticationType);

                HttpContext.Current.Session["AuthChallenged"] = true;
            }
            else if (request.IsAuthenticated && challengeIssued)
            {
                //Forces session population
                var user = QProcess.Session.CurrentSession.QUser.Id;
                HttpContext.Current.Session["AuthChallenged"] = false;
            }

            HttpContext.Current.ApplicationInstance.CompleteRequest();
            return request.IsAuthenticated;            
        }        

        // The Client ID is used by the application to uniquely identify itself to Azure AD.
        string clientId = AppSettings.Get("ClientId");

        // RedirectUri is the URL where the user will be redirected to after they sign in.
        string redirectUri = AppSettings.Get("RedirectUri");

        string postLogoutRedirect = AppSettings.Get("LogoutRedirectUri");

        // Tenant is the tenant ID (e.g. contoso.onmicrosoft.com, or 'common' for multi-tenant)
        static string tenant = AppSettings.Get("Tenant");

        // These tenant IDs are the acceptable AAD tenants for this app
        static string[] validTenants = AppSettings.Get("ValidTenants").ToUpper().Split(new[] { '|' }, StringSplitOptions.RemoveEmptyEntries);

        // Authority is the URL for authority, composed by Microsoft identity platform endpoint and the tenant name (e.g. https://login.microsoftonline.com/contoso.onmicrosoft.com/v2.0)
        string authority = String.Format(System.Globalization.CultureInfo.InvariantCulture,
            AppSettings.Get("Authority"), tenant);

        string domainHint = AppSettings.Get("DomainHint");

        static TimeSpan cookieTimeout;

        static Owin()
        {
            TimeSpan.TryParse(AppSettings.Get("CookieTimeout"), out cookieTimeout);
        }

        /// <summary>
        /// Configure OWIN to use OpenIdConnect 
        /// </summary>
        /// <param name="app"></param>
        public void Configuration(IAppBuilder app)
        {
            ServicePointManager.SecurityProtocol = SecurityProtocolType.Tls12|SecurityProtocolType.Tls13;
            app.SetDefaultSignInAsAuthenticationType(CookieAuthenticationDefaults.AuthenticationType);
            var cookieAuthOptions = new CookieAuthenticationOptions
            {
                CookieManager = new SystemWebCookieManager(),
                SlidingExpiration = true,
                CookieSameSite = Microsoft.Owin.SameSiteMode.None,
                CookieSecure = CookieSecureOption.Always,
            };

            if(cookieTimeout != default)
                cookieAuthOptions.ExpireTimeSpan = cookieTimeout;

            app.UseCookieAuthentication(cookieAuthOptions);
            app.UseOpenIdConnectAuthentication(
                new OpenIdConnectAuthenticationOptions
                {
                    CookieManager = new SystemWebCookieManager(),
                    // Sets the ClientId, authority, RedirectUri as obtained from web.config
                    ClientId = clientId,
                    Authority = authority,
                    RedirectUri = redirectUri,
                    // PostLogoutRedirectUri is the page that users will be redirected to after sign-out.
                    PostLogoutRedirectUri = postLogoutRedirect,
                    // Request email claim as some tenants don't return it with just 'profile'
                    Scope = OpenIdConnectScope.OpenIdProfile + " email",                      
                    // ResponseType is set to request the code id_token - which contains basic information about the signed-in user
                    ResponseType = OpenIdConnectResponseType.CodeIdToken,                    
                    TokenValidationParameters = new TokenValidationParameters()
                    {
                        ValidateIssuer = true,
                        ValidIssuer = AppSettings.Get("ValidIssuers") ?? "https://login.microsoftonline.com/",                        
                        IssuerValidator = ValidateIssuer
                    },
                    // OpenIdConnectAuthenticationNotifications configures OWIN to send notification of failed authentications to OnAuthenticationFailed method
                    Notifications = new OpenIdConnectAuthenticationNotifications
                    {
                        RedirectToIdentityProvider = ProvideLoginHintToIdentityProvider,
                        AuthenticationFailed = OnAuthenticationFailed
                    },
                    RefreshOnIssuerKeyNotFound = true,
                    UseTokenLifetime = false,
                }
            );
        }

        private Task ProvideLoginHintToIdentityProvider (RedirectToIdentityProviderNotification<OpenIdConnectMessage, OpenIdConnectAuthenticationOptions> context)
        {
            var prop = context.OwinContext.Authentication.AuthenticationResponseChallenge.Properties;

            if (prop.Dictionary.ContainsKey("login_hint"))
                context.ProtocolMessage.LoginHint = prop.Dictionary["login_hint"];
            else if (!String.IsNullOrWhiteSpace(domainHint))
                context.ProtocolMessage.DomainHint = domainHint;

            return Task.FromResult(0);
        }
        
        private string ValidateIssuer(string issuer, SecurityToken securityToken, TokenValidationParameters validationParameters)
        {
            if (!issuer.StartsWithAny(validationParameters.ValidIssuer.Split('|')))
                throw new SecurityTokenInvalidIssuerException($"IDX10205: Auth token issuer '{issuer}' is invalid or not accepted.") { InvalidIssuer = issuer };

            var jwtToken = securityToken as JwtSecurityToken;

            //JWT token version really doesn't matter as long as we have the claims we need.
            //var authVer = jwtToken.Claims.FirstOrDefault(c => c.Type == "ver");            
            //if (authVer == null || authVer.Value != "2.0")
            //    throw new SecurityTokenInvalidIssuerException($"IDX10205: Auth token issuer '{issuer}' does not use OAuth 2.0 and is invalid.") { InvalidIssuer = issuer };

            //Valid Tenants based on app Firm - Q = AcmeWidget only; TEB = TxExBank only; PHI = AW & PHI
            var tenantId = jwtToken.Claims.FirstOrDefault(c => c.Type == "tid");
            if (tenantId == null || !validTenants.Contains(tenantId.Value.ToUpper()))
                throw new SecurityTokenInvalidIssuerException($"IDX10205: Auth token tenant ID '{tenantId?.Value}' is invalid or not accepted.") { InvalidIssuer = issuer };

            return issuer;
        }

        /// <summary>
        /// Handle failed authentication requests by redirecting the user to the home page with an error in the query string
        /// </summary>
        /// <param name="context"></param>
        /// <returns></returns>
        private Task OnAuthenticationFailed(AuthenticationFailedNotification<OpenIdConnectMessage, OpenIdConnectAuthenticationOptions> context)
        {
            //if (context.Exception.Message.Contains("IDX21323"))
            //{
            //    context.HandleResponse();
            //    context.OwinContext.Authentication.Challenge();
            //}
            //else
            //{
                context.HandleResponse();
                context.Response.Write(context.Exception.Message);
                context.Response.StatusCode = 403;
            //}
            return Task.FromResult(0);
        }        
    }

}
/* Copyright � 2024 Renegade Swish, LLC */

