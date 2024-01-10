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
    [Description("开票到账及收支情况表 报表插件")]
    [HotUpdate]
    public class DZSZReport : SysReportBaseService
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

            string programNo = "";
            string beginYear = "";
            string endYear = "";

            DynamicObject customFilter = filter.FilterParameter.CustomFilter;

            List<string> programNoList = new List<string>();
            if (customFilter["FProgramId"] != null)
            {
                DynamicObjectCollection programList = customFilter["FProgramId"] as DynamicObjectCollection;
                foreach (DynamicObject item in programList)
                {
                    DynamicObject program = item["FProgramId"] as DynamicObject;
                    programNoList.Add(Convert.ToString(program["Number"]));
                }
            }

            programNo = string.Join(",", programNoList);

            if (customFilter["FBeginYear"] != null)
            {
                beginYear = customFilter["FBeginYear"].ToString();
            }
            if (customFilter["FEndYear"] != null)
            {
                endYear = customFilter["FEndYear"].ToString();
            }


            string sql = $@"EXEC sp_YJ_DZSZReport 
               '{beginYear}','{endYear}','{programNo}','{tempName}'";


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
            result.Add(AddSum("FContractAmount"));
            result.Add(AddSum("FFinalACccounts"));
            result.Add(AddSum("FRecAbleAmount"));
            result.Add(AddSum("FNoRecAbleAmount"));
            result.Add(AddSum("FRecAmount"));
            result.Add(AddSum("FNoRecAmount"));
            result.Add(AddSum("FAbsAmount"));
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
