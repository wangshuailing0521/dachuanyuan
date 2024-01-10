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
    [Description("完工项目成本报表 报表插件")]
    [HotUpdate]
    public class ProgramCostReport : SysReportBaseService
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
            string programGroup = "";
            string beginYear = "";
            string beginPeriod = "";
            string endYear = "";
            string endPeriod = "";

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

            if (customFilter["FProgramGroup"] != null)
            {
                programGroup = customFilter["FProgramGroup"].ToString();
            }
           
            if (customFilter["FBeginYear"] != null)
            {
                beginYear = customFilter["FBeginYear"].ToString();
            }
            if (customFilter["FBeginPeriod"] != null)
            {
                beginPeriod = customFilter["FBeginPeriod"].ToString();
            }
            if (customFilter["FEndYear"] != null)
            {
                endYear = customFilter["FEndYear"].ToString();
            }
            if (customFilter["FEndPeriod"] != null)
            {
                endPeriod = customFilter["FEndPeriod"].ToString();
            }

            string sql = $@"EXEC sp_YJ_ProgramCost 
              '{beginYear}','{beginPeriod}','{endYear}','{endPeriod}', '{programNo}','{programGroup}','{tempName}'";


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
            result.Add(AddSum("F5A"));
            result.Add(AddSum("F6A"));
            result.Add(AddSum("F7A"));
            result.Add(AddSum("F8A"));
            result.Add(AddSum("F9A"));
            result.Add(AddSum("F10"));
            result.Add(AddSum("F11"));
            result.Add(AddSum("F12"));
            result.Add(AddSum("F13"));
            result.Add(AddSum("F14"));
            result.Add(AddSum("F15"));
            result.Add(AddSum("F16"));
            result.Add(AddSum("F17"));
            result.Add(AddSum("F18"));
            result.Add(AddSum("F19"));
            result.Add(AddSum("F20"));
            result.Add(AddSum("F21"));
            result.Add(AddSum("F22"));
            result.Add(AddSum("F23"));
            result.Add(AddSum("F24"));
            result.Add(AddSum("F25"));
            result.Add(AddSum("F26"));
            result.Add(AddSum("F27"));
            result.Add(AddSum("F28"));
            result.Add(AddSum("F29"));
            result.Add(AddSum("F30"));
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
