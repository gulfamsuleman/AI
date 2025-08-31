using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.UI.WebControls;
using QProcess.Repositories;

namespace QProcess.Controls
{
    public partial class Controls_Grading_GradingPeriods : System.Web.UI.UserControl
    {
        public List<NamedEntity> GradingPeriods { get { return _GradingPeriods ?? new SelectListRepository().GetGradingPeriods().ToList(); } set { _GradingPeriods = value; } }
        private List<NamedEntity> _GradingPeriods { get; set; }
        public int PeriodId { get; set; }
        public Repeater Repeater1 { get; set; }

        public Controls_Grading_GradingPeriods()
        {
            Repeater1 = new Repeater();
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            var selectListRepo = new SelectListRepository();
            _GradingPeriods = _GradingPeriods ?? selectListRepo.GetGradingPeriods().ToList();
            _GradingPeriods.First().Name = "Current Period";

            Repeater1.DataBind();
        }
    }
}
/* Copyright © 2024 Renegade Swish, LLC */

