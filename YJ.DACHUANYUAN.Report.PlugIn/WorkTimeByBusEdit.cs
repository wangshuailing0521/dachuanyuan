using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.ComponentModel;

using Kingdee.BOS.App.Data;
using Kingdee.BOS.Core.CommonFilter;
using Kingdee.BOS.Core.DynamicForm.PlugIn;
using Kingdee.BOS.Core.DynamicForm.PlugIn.Args;
using Kingdee.BOS.Orm.DataEntity;
using Kingdee.BOS.Util;
using Kingdee.BOS.Orm.Metadata.DataEntity;
using Kingdee.BOS.Core.Metadata.FieldElement;
using Kingdee.BOS.Core.DynamicForm;

namespace YJ.DACHUANYUAN.Report.PlugIn
{
    [Description("工时汇报汇总插件")]
    [HotUpdate]
    public class WorkTimeByBusEdit : AbstractDynamicFormPlugIn
    {
        public override void AfterBarItemClick(AfterBarItemClickEventArgs e)
        {
            base.AfterBarItemClick(e);

            if (e.BarItemKey == "tbGetWorkTime")
            {
                DynamicObject billObj = this.Model.DataObject;
                DateTime beginDateTime = Convert.ToDateTime(billObj["FServiceDate"]);
                DateTime endDateTime = Convert.ToDateTime(billObj["FEndServiceDate"]);

                if (IsHaveNoAudit(beginDateTime.Year, beginDateTime.Month, endDateTime.Year, endDateTime.Month))
                {
                    View.ShowWarnningMessage("存在未审核的工时汇报,是否继续？", "", MessageBoxOptions.YesNo, result =>
                    {
                        if (result == MessageBoxResult.Yes)
                        {
                            GetWorkTime();
                        }
                    });
                }
                else
                {
                    GetWorkTime();
                }
            }
        }

        void GetWorkTime()
        {
            DynamicObject billObj = this.Model.DataObject;
            DateTime beginDateTime = Convert.ToDateTime(billObj["FServiceDate"]);
            DateTime endDateTime = Convert.ToDateTime(billObj["FEndServiceDate"]);
            decimal sumAmount = Convert.ToDecimal(billObj["F_QAPZ_Decimal28"]);
            DynamicObjectCollection workTimeDatas = GetWorkTimeBySql(beginDateTime.Year, beginDateTime.Month, endDateTime.Year, endDateTime.Month, sumAmount);
            DynamicObjectCollection entrys = billObj["FEntity"] as DynamicObjectCollection;
            DynamicPropertyCollection entryTypeColl = entrys.DynamicCollectionItemPropertyType.Properties;
            DynamicPropertyCollection workTimeDataTypeColl = workTimeDatas.DynamicCollectionItemPropertyType.Properties;
            BaseDataField fldProgram = this.View.BillBusinessInfo.GetField("F_QAPZ_Base") as BaseDataField;

            entrys.Clear();
            int seq = 1;
            foreach (var workTimeData in workTimeDatas)
            {
                DynamicObject newEntry = new DynamicObject(entrys.DynamicCollectionItemPropertyType);

                //赋值项目号
                DynamicObject[] programObjs = Kingdee.BOS.ServiceHelper.BusinessDataServiceHelper.LoadFromCache(
                    this.Context,
                    new object[] { workTimeData["FProgramID"] },
                    fldProgram.RefFormDynamicObjectType);
                fldProgram.RefIDDynamicProperty.SetValue(newEntry, workTimeData["FProgramID"]);
                fldProgram.DynamicProperty.SetValue(newEntry, programObjs[0]);

                newEntry["Seq"] = seq;
                entrys.Add(newEntry);

                //赋值其他字段
                foreach (DynamicProperty coll in entryTypeColl)
                {
                    string collName = coll.GetColumnName();
                    string collText = "";
                    try
                    {
                        collText = this.View.GetControl(collName).Text;
                    }
                    catch (Exception ex)
                    {
                        continue;
                    }

                    decimal workTime = 0;
                    if (workTimeDataTypeColl.Contains(collText) && decimal.TryParse(workTimeData[collText].ToString(), out workTime))
                    {
                        this.View.Model.SetValue(collName, workTime, seq - 1);
                        this.View.UpdateView(collName, seq - 1);
                        this.View.InvokeFieldUpdateService(collName, seq - 1);

                        //newEntry[collName] = workTime;
                    }
                }


                seq++;

            }

            this.View.UpdateView("F_QAPZ_Decimal29");
            this.View.UpdateView("F_QAPZ_Decimal30");
            this.View.UpdateView("FEntity");
        }

        bool IsHaveNoAudit(int year, int period, int endYear, int endPeriod)
        {
            string sql = $@"
                SELECT  1
                  FROM  T_YJ_WorkTime A
                 WHERE  A.FDOCUMENTSTATUS <> 'C'
                   AND  A.FYEAR >= {year}
                   AND  A.FPERIOD >= {period}
                   AND  A.FYEAR <= {endYear}
                   AND  A.FPERIOD <= {endPeriod}
                ";
            DynamicObjectCollection data = DBUtils.ExecuteDynamicObject(this.Context, sql);
            if (data.Count > 0)
            {
                return true;
            }
            return false;
        }

        DynamicObjectCollection GetWorkTimeBySql(int year, int period, int endYear, int endPeriod, decimal sumAmount)
        {
            string sql = $@"EXEC sp_YJ_WorkTimeByBusReport {year},{period},{endYear},{endPeriod},{sumAmount}";
            DynamicObjectCollection data = DBUtils.ExecuteDynamicObject(this.Context, sql);
            return data;
        }
    }
}
