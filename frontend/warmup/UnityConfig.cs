using QProcess.Repositories;
using QProcess.Services;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using Unity;

namespace QProcess.warmup
{
    public static class UnityConfig
    {
        private static Lazy<IUnityContainer> container = new Lazy<IUnityContainer>(() =>
        {
            var container = new UnityContainer();
            RegisterTypes(container);
            return container;
        });

        public static IUnityContainer Container => container.Value;

        public static void RegisterTypes(IUnityContainer container)
        {
            
            container.RegisterType<UserRepository, UserRepository>(new PerSessionLifeTimeManager());
            container.RegisterType<ChecklistRepository, ChecklistRepository>(new PerSessionLifeTimeManager());
            container.RegisterType<StatusReportRepository, StatusReportRepository>(new PerSessionLifeTimeManager());
            container.RegisterType<BulkAssignmentRepository, BulkAssignmentRepository>(new PerSessionLifeTimeManager());
            container.RegisterType<LinkedDeadlineRepository, LinkedDeadlineRepository>(new PerSessionLifeTimeManager());
            container.RegisterType<LoadTimesRepository, LoadTimesRepository>(new PerSessionLifeTimeManager());
            container.RegisterType<ChangeRequestRepository, ChangeRequestRepository>(new PerSessionLifeTimeManager());
            container.RegisterType<MyInboxRepository, MyInboxRepository>(new PerSessionLifeTimeManager()); 
            container.RegisterType<PrioritiesRepository, PrioritiesRepository>(new PerSessionLifeTimeManager());
            container.RegisterType<TaskSummaryRepository, TaskSummaryRepository>(new PerSessionLifeTimeManager());
        }
    }
}