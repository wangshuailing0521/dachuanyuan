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
    [Description("加工及材料费支付情况表 报表插件")]
    [HotUpdate]
    public class JGCLZFReport : SysReportBaseService
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
            string supplierNo = "";
          

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

            List<string> supplierNoList = new List<string>();
            if (customFilter["FSupplierId"] != null)
            {
                DynamicObjectCollection supplierList = customFilter["FSupplierId"] as DynamicObjectCollection;
                foreach (DynamicObject item in supplierList)
                {
                    DynamicObject supplier = item["FSupplierId"] as DynamicObject;
                    supplierNoList.Add(Convert.ToString(supplier["Number"]));
                }
            }

            supplierNo = string.Join(",", supplierNoList);

           

            string sql = $@"EXEC sp_SCS_JGCLZFReport 
               '{programNo}','{supplierNo}','{tempName}'";


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
            result.Add(AddSum("FJGAmount"));
            result.Add(AddSum("FJGPayAmount"));
            result.Add(AddSum("FJGNoPayAmount"));
            result.Add(AddSum("FJGPayAbleAmount"));
            result.Add(AddSum("FJGNoPayAbleAmount"));
            result.Add(AddSum("FJGAbsAmount"));
            result.Add(AddSum("FCLAmount"));
            result.Add(AddSum("FCLPayAmount"));
            result.Add(AddSum("FCLNoPayAmount"));
            result.Add(AddSum("FCLPayAbleAmount"));
            result.Add(AddSum("FCLNoPayAbleAmount"));
            result.Add(AddSum("FCLAbsAmount"));
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
