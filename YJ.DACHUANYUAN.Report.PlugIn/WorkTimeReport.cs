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
    [Description("工时汇总统计表 报表插件")]
    [HotUpdate]
    public class WorkTimeReport : SysReportBaseService
    {
        private string tempName;

        private List<string> fileNameList = new List<string>();

        public override void Initialize()
        {
            //设置零时表主键
            base.Initialize();
            this.ReportProperty.IdentityFieldName = "FIDENTITYID";
        }

        public override void BuilderReportSqlAndTempTable(IRptParams filter, string tableName)
        {
            base.BuilderReportSqlAndTempTable(filter, tableName);

            tempName = tableName;

            string beginTime = "";
            string endTime = "";
            string programIds = "";
            string userIds = "";
            string sumAmount = "";


            DynamicObject customFilter = filter.FilterParameter.CustomFilter;

            if (customFilter["FBeginTime"] != null)
            {
                beginTime = customFilter["FCreateTime"].ToString();
            }
            if (customFilter["FEndTime"] != null)
            {
                endTime = customFilter["FEndTime"].ToString();
            }

            string sql = $@"EXEC sp_YJ_WorkTimeReport '{tempName}','{beginTime}','{endTime}',{sumAmount}";

            DynamicObjectCollection table
                = DBUtils.ExecuteDynamicObject(this.Context, sql);


            DynamicPropertyCollection dynamicObjectTypeColl = table.DynamicCollectionItemPropertyType.Properties;

            foreach (var dynamicObjectType in dynamicObjectTypeColl)
            {
                fileNameList.Add(dynamicObjectType.Name);
            }

        }

        public override ReportHeader GetReportHeaders(IRptParams filter)
        {
            ReportHeader header = new ReportHeader();

            int i = 1;
            int oldi = i;
            foreach (var fileName in fileNameList)
            {
                oldi = i;

                string fileLocalName = fileName;

                if (fileName == "FProgramID")
                {
                    continue;
                }

             

                if (fileName == "FProgramNo")
                {
                    fileLocalName = "聚价";
                }

                if (fileName == "FProgramName")
                {
                    fileLocalName = "到手价";

                    i = 100;
                }

                if (fileName == "FDownPrice")
                {
                    fileLocalName = "最低限价";

                    i = 101;
                }

                header.AddChild(fileName, new LocaleValue(fileLocalName));
                header.AddChild(fileName, new LocaleValue(fileLocalName)).ColIndex = i;

                i = oldi;

                i++;
            }

            return header;
        }

        public override void CloseReport()
        {
            base.CloseReport();

            IDBService dbService = Kingdee.BOS.App.ServiceHelper.GetService<IDBService>();
            dbService.DeleteTemporaryTableName(Context, new string[] { tempName });
        }
    }
}
