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

namespace YJ.DACHUANYUAN.Report.PlugIn
{
    [Description("工通书编号及项目统计表")]
    [HotUpdate]
    public class GCTZSInfoReport : AbstractDynamicFormPlugIn
    {
        public override void AfterBarItemClick(AfterBarItemClickEventArgs e)
        {
            base.AfterBarItemClick(e);

            if (e.BarItemKey == "tbSearch")
            {
                GetReport();
            }
        }

        public override void AfterButtonClick(AfterButtonClickEventArgs e)
        {
            base.AfterButtonClick(e);

            if (e.Key == "Search")
            {
                GetReport();
            }
        }

        void GetReport()
        {
            DynamicObject billObj = this.Model.DataObject;
           
            DynamicObjectCollection datas = GetReportBySql();
            DynamicObjectCollection entrys = billObj["FEntity"] as DynamicObjectCollection;
            BaseDataField fldProgram = this.View.BillBusinessInfo.GetField("FengineeNo") as BaseDataField;



            foreach (var data in datas)
            {
                bool isAdd = false;
                DynamicObject newEntry = entrys.Where(
                    x => x["FGTSBILLID"] != null && x["FGTSBILLID"].ToString() == data["FGTSBILLID"].ToString()).FirstOrDefault();

                if (newEntry == null)
                {
                    newEntry = new DynamicObject(entrys.DynamicCollectionItemPropertyType);
                    isAdd = true;
                }

                //赋值项目号
                DynamicObject[] programObjs = Kingdee.BOS.ServiceHelper.BusinessDataServiceHelper.LoadFromCache(
                    this.Context,
                    new object[] { data["FengineeNo"] },
                    fldProgram.RefFormDynamicObjectType);
                fldProgram.RefIDDynamicProperty.SetValue(newEntry, data["FengineeNo"]);
                fldProgram.DynamicProperty.SetValue(newEntry, programObjs[0]);

                newEntry["FprogramName"] = data["FprogramName"];
                newEntry["FGTSBILLID"] = data["FGTSBILLID"];
                newEntry["FYear"] = data["FYear"];
                newEntry["FMaterialName"] = data["FMaterialName"];
                newEntry["FJXXH"] = data["FJXXH"];
                newEntry["FQty"] = data["FQty"];
                newEntry["FContraNo"] = data["FContraNo"];
                newEntry["F_SHDP_Text5"] = data["F_SHDP_Text5"];
                newEntry["F_SHDP_Text6"] = data["F_SHDP_Text6"];
                newEntry["FWHQ"] = data["FWHQ"];
                newEntry["FWHP"] = data["FWHP"];
                newEntry["FPZ"] = data["FPZ"];
                newEntry["FSFZFL"] = data["FSFZFL"];
                newEntry["FZGWD"] = data["FZGWD"];
                newEntry["FJRFS"] = data["FJRFS"];
                newEntry["FTZJD"] = data["FTZJD"];
                newEntry["FRFJC"] = data["FRFJC"];
                newEntry["FWLJC"] = data["FWLJC"];
                newEntry["FWMP"] = data["FWMP"];
                newEntry["FYYDD"] = data["FYYDD"];
                newEntry["FJXDD"] = data["FJXDD"];
                newEntry["FDQDD"] = data["FDQDD"];
                newEntry["FCLTJ"] = data["FCLTJ"];
                newEntry["FZZGC"] = data["FZZGC"];
                newEntry["FJHQYD"] = data["FJHQYD"];
                newEntry["FJHQYS"] = data["FJHQYS"];
                newEntry["FJHFS"] = data["FJHFS"];
                newEntry["FGCWCR"] = data["FGCWCR"];
                newEntry["FWCZT"] = data["FWCZT"];

                if (isAdd)
                {
                    newEntry["Seq"] = entrys.Count + 1;
                    entrys.Add(newEntry);
                }
            }
            this.View.UpdateView("FEntity");
        }

        DynamicObjectCollection GetReportBySql()
        {
            string sql = $@"EXEC sp_YJ_GCTZSInfo";
            DynamicObjectCollection data = DBUtils.ExecuteDynamicObject(this.Context, sql);
            return data;
        }
    }
}
