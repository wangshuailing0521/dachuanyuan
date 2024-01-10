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
    [Description("营业配件一览表 报表插件")]
    [HotUpdate]
    public class BusinessInfoReport : SysReportBaseService
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
            string beginTime = "";
            string endTime = "";
           

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
           
            if (customFilter["FBeginTime"] != null)
            {
                beginTime = Convert.ToDateTime(customFilter["FBeginTime"]).ToString("yyyy-MM-dd");
            }
            if (customFilter["FEndTime"] != null)
            {
                endTime = Convert.ToDateTime(customFilter["FEndTime"]).ToString("yyyy-MM-dd");
            }
            

            string sql = $@"EXEC sp_YJ_BusinessInfoReport 
             '{programNo}','{programGroup}', '{beginTime}','{endTime}','{tempName}'";


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
            result.Add(AddSum("FSaleQty"));
            result.Add(AddSum("FSaleAmount"));
            result.Add(AddSum("FRecAmount"));
            result.Add(AddSum("FNoRecAmount"));
            result.Add(AddSum("FKPAmount"));
            result.Add(AddSum("FNoKPAmount"));
            result.Add(AddSum("FAbleAmount"));
            result.Add(AddSum("FSCCost"));
            result.Add(AddSum("FJZCost"));
            result.Add(AddSum("FNoJZCost"));
            result.Add(AddSum("FAmount"));
            result.Add(AddSum("FProfit"));
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
