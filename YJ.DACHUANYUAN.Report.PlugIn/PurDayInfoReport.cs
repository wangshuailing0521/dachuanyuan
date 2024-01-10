using Kingdee.BOS;
using Kingdee.BOS.App.Data;
using Kingdee.BOS.Contracts;
using Kingdee.BOS.Contracts.Report;
using Kingdee.BOS.Core.Report;
using Kingdee.BOS.Orm.DataEntity;
using Kingdee.BOS.Orm.Metadata.DataEntity;
using Kingdee.BOS.Util;

using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Linq;
using System.Text;

namespace YJ.DACHUANYUAN.Report.PlugIn
{
    [Description("采购每日跟踪表 报表插件")]
    [HotUpdate]
    public class PurDayInfoReport : SysReportBaseService
    {
        private string tempName;

        public override void Initialize()
        {
            //设置零时表主键
            base.Initialize();
            this.ReportProperty.IdentityFieldName = "FIDENTITYID";
            this.ReportProperty.IsGroupSummary = true;//支持分组汇总
        }

        public override void BuilderReportSqlAndTempTable(IRptParams filter, string tableName)
        {
            base.BuilderReportSqlAndTempTable(filter, tableName);

            tempName = tableName;

            string sql = $@"EXEC sp_YJ_PurDayInfo '{tempName}'";


            DBUtils.Execute(this.Context, sql);

        }

      
        /// <summary>
        /// 设置报表合计列
        /// </summary>
        /// <param name="filter"></param>
        /// <returns></returns>
        public override List<SummaryField> GetSummaryColumnInfo(IRptParams filter)
        {
            var result = base.GetSummaryColumnInfo(filter);
            result.Add(AddSum("FQty"));
            result.Add(AddSum("FAmount"));
            return result;
        }

        public override void CloseReport()
        {
            base.CloseReport();

            IDBService dbService = Kingdee.BOS.App.ServiceHelper.GetService<IDBService>();
            dbService.DeleteTemporaryTableName(Context, new string[] { tempName });
        }

        SummaryField AddSum(string field_name)
        {
            return new SummaryField(field_name, Kingdee.BOS.Core.Enums.BOSEnums.Enu_SummaryType.SUM);
        }
    }
}
