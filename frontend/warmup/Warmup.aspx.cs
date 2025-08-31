using System;
using System.IO;
using System.Text;

namespace SiteWarmup
{
    public partial class Warmup : System.Web.UI.Page
    {
        public string ServiceClassUris
        {
            get
            {
                var uris = new StringBuilder();

                var baseDir = Server.MapPath("~/");
                var currUri = Request.Url;

                foreach (var file in Directory.EnumerateFiles(baseDir, "*.asmx", SearchOption.AllDirectories))
                {
                    var cleanFile = file.Replace(baseDir, "");
                    var uri = new UriBuilder(currUri.Scheme, currUri.Host, currUri.Port, cleanFile, "?wsdl");
                    uris.Append($"\"{uri}\",");
                }
                return uris.ToString();
            }
        }
        protected void Page_Load(object sender, EventArgs e)
        {

        }
    }
}
/* Copyright © 2024 Renegade Swish, LLC */

