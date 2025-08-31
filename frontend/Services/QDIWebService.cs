using QProcess.warmup;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Services;
using Unity;

namespace QProcess.Services
{
    public class QDIWebService : WebService
    {
        protected IUnityContainer Container;

        public QDIWebService()
        {
            Container = UnityConfig.Container;
            InitializeDependencies();
        }

        protected virtual void InitializeDependencies()
        {

        }
    }
}