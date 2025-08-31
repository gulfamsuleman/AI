using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using Unity;
using Unity.Lifetime;

namespace QProcess.Services
{
    public class PerSessionLifeTimeManager : LifetimeManager, IInstanceLifetimeManager, IFactoryLifetimeManager, ITypeLifetimeManager
    {
        private string _key = Guid.NewGuid().ToString();

        public override void RemoveValue(ILifetimeContainer container = null)
        {
            HttpContext.Current.Session.Remove(_key);
        }

        public override void SetValue(object newValue, ILifetimeContainer container = null)
        {
            HttpContext.Current.Session[_key] = newValue;
        }

        public override object GetValue(ILifetimeContainer container = null)
        {
            return HttpContext.Current.Session[_key] ?? LifetimeManager.NoValue;
        }

        protected override LifetimeManager OnCreateLifetimeManager()
        {
           return new PerSessionLifeTimeManager();
        }

    }
}