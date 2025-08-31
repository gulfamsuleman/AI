using Microsoft.IdentityModel.Tokens;
using QProcess.Configuration;
using QProcess.Extensions;
using QProcess.Repositories;
using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.EnterpriseServices.Internal;
using System.IdentityModel.Tokens.Jwt;
using System.Linq;
using System.Runtime.InteropServices;
using System.Security.Claims;
using System.Web;
using System.Web.Script.Serialization;
using System.Web.Script.Services;
using System.Web.Services;
using System.Web.Http;
using System.Net;

namespace QProcess.Services
{
    /// <summary>
    /// Summary description for ExternalService
    /// </summary>
    [WebService(Namespace = "http://tempuri.org/")]
    [WebServiceBinding(ConformsTo = WsiProfiles.BasicProfile1_1)]
    [System.ComponentModel.ToolboxItem(false)]
    // To allow this Web Service to be called from script, using ASP.NET AJAX, uncomment the following line. 
    [ScriptService]
    public class ExternalService : System.Web.Services.WebService
    {
        private string key = AppSettings.Get("JwtKey");
        [WebMethod]
        public string RequestAccess(string userSecret)
        {
            if(userSecret != key) {
                throw new UnauthorizedAccessException("User Key is invalid");
            }

            else 
            return GenerateJwtToken();
        }

        [WebMethod]
        public string CreateSimpleTask(string taskName, string groupAssignedTo, DateTime? dueDate, string task = null, string controller = null)
        {
            string validToken = GetValidTokenFromHeaders();
            var isValidToken = ValidateToken(validToken);

            if (isValidToken)
            {
                if (string.IsNullOrEmpty(taskName) || string.IsNullOrEmpty(groupAssignedTo))
                    return $"Missing fields: TaskName and AssignedTo are required";

                var role = GetRoleFromValidToken(validToken);
                if (role == "approvedRole")
                {
                    var checklist = new CreateChecklistRequest()
                    {
                        TaskName = taskName,
                        GroupAssignedTo = groupAssignedTo,
                        Controller = string.IsNullOrEmpty(controller) ? groupAssignedTo : controller,
                        TaskType = task,
                        DueDate = dueDate 
                    };

                    var checklistRepo = new ChecklistRepository();

                    string result = checklistRepo.CreateGenericChecklist(checklist);
                    return result;
                }
            }

            return HttpStatusCode.Unauthorized.ToString();


        }

        private string GenerateJwtToken()
        {
            var symetricKey = Convert.FromBase64String(AppSettings.Get("JwtKey"));
            var tokenHandler = new JwtSecurityTokenHandler();
            var now = DateTime.UtcNow;

            var tokenDescriptor = new SecurityTokenDescriptor
            {
                Subject = new ClaimsIdentity(new[]
                {
                    new Claim(ClaimTypes.Name, "approvedUser"),
                    new Claim(ClaimTypes.Role, "approvedRole")
                }),
                Expires = now.AddMinutes(Double.Parse(AppSettings.Get("JwtTimeout"))),
                Issuer = AppSettings.Get("JwtIssuer"),
                Audience = AppSettings.Get("JwtAudience"),
                SigningCredentials = new SigningCredentials(new SymmetricSecurityKey(symetricKey),
                SecurityAlgorithms.HmacSha256Signature)
            };

            var stoken = tokenHandler.CreateToken(tokenDescriptor);
            var token = tokenHandler.WriteToken(stoken);

            return token;
        }

        private string GetValidTokenFromHeaders()
        {
            var authHeader = HttpContext.Current.Request.Headers["Authorization"];

            if (!string.IsNullOrEmpty(authHeader))
                return authHeader.Substring("Bearer ".Length);

            return null;
        }

        private bool ValidateToken(string token)
        {
            try
            {
                var tokenHandler = new JwtSecurityTokenHandler();

                var validationParams = new TokenValidationParameters
                {
                    ValidateIssuerSigningKey = true,
                    IssuerSigningKey = new SymmetricSecurityKey(Convert.FromBase64String(key)),
                    ValidateIssuer = true,
                    ValidIssuer = AppSettings.Get("JwtIssuer"),
                    ValidateAudience = true,
                    ValidAudience = AppSettings.Get("JwtAudience"),
                    ClockSkew = TimeSpan.Zero
                };

                SecurityToken validatedToken;
                tokenHandler.ValidateToken(token, validationParams, out validatedToken);
                return true;
            }
            catch (Exception ex)
            {
                return false;
            }
        }

        private string GetRoleFromValidToken(string token)
        {
            var tokenHandler = new JwtSecurityTokenHandler();
            var validatedToken = tokenHandler.ReadJwtToken(token);
            var userRoleClaim = validatedToken.Claims.FirstOrDefault(c => c.Type == "role");
            return userRoleClaim?.Value;
        }

    }

    public class CreateChecklistRequest
    {
        public string TaskName { get; set; }
        public string GroupAssignedTo { get; set; }
        public string Controller { get; set; }
        public string TaskType { get; set; }
        public DateTime? DueDate { get; set; }
    }
       
}
/* Copyright © 2024 Renegade Swish, LLC */

