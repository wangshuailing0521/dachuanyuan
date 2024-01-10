using Kingdee.BOS.App.Data;
using Kingdee.BOS.Core.Bill.PlugIn;
using Kingdee.BOS.Core.DynamicForm.PlugIn.Args;
using Kingdee.BOS.Core.Metadata.FieldElement;
using Kingdee.BOS.Orm.DataEntity;
using Kingdee.BOS.ServiceHelper;
using Kingdee.BOS.Util;

using System;
using System.ComponentModel;
using System.Data;
using System.Linq;

namespace YJ.DACHUANYUAN.Report.PlugIn
{
    [Description("营业业务月报")]
    [HotUpdate]
    public class BusinessOperateReport : AbstractBillPlugIn
    {
        public override void AfterButtonClick(AfterButtonClickEventArgs e)
        {
            base.AfterButtonClick(e);

            if (e.Key.EqualsIgnoreCase("FSearch"))
            {
                ClearThisBill();
                RefreshData();
                this.View.UpdateView();
            }
        }

        void RefreshData()
        {
            DynamicObject billObj = this.Model.DataObject;

            int year = Convert.ToInt32(billObj["FYear"]);
            int month = Convert.ToInt32(billObj["FMonth"]);

            DataSet ds = DBUtils.ExecuteDataSet(
                this.Context, $@"EXEC sp_YJ_BusinessOperateReport {year},{month}");

            SetOrder(billObj, ds.Tables[0]);
            SetRecAble(billObj, ds.Tables[1]);
        }

        /// <summary>
        /// 订货
        /// </summary>
        /// <param name="billObj"></param>
        /// <param name="dt"></param>
        void SetOrder(DynamicObject billObj, DataTable dt)
        {
            if (dt.Rows.Count <= 0)
            {
                return;
            }

            DynamicObjectCollection entity = billObj["FPurEntity"] as DynamicObjectCollection;

            int seq = 1;

            foreach (DataRow dtRow in dt.Rows)
            {
                DynamicObject newEntry = new DynamicObject(entity.DynamicCollectionItemPropertyType);

                //BaseDataField fldCust = this.View.BillBusinessInfo.GetField("FRecCustID") as BaseDataField;
                //DynamicObject custObj = BusinessDataServiceHelper.LoadFromCache(
                //    this.Context, new object[] { dtRow["FRecCustID"] }, fldCust.RefFormDynamicObjectType).FirstOrDefault();
                //fldCust.RefIDDynamicProperty.SetValue(newEntry, dtRow["FRecCustID"]);
                //fldCust.DynamicProperty.SetValue(newEntry, custObj);

                newEntry["Seq"] = seq;
                newEntry["FPurProgram"] = dtRow["FOrderCustName"];
                newEntry["FPurMaterial"] = dtRow["FOrderMaterialName"];
                newEntry["FPurBudgetAmount"] = dtRow["FOrderBudgetAmount"];
                if (dtRow["FOrderBudgetDate"] != null && dtRow["FOrderBudgetDate"].ToString() != "")
                {
                    newEntry["FPurBudgetDate"] = Convert.ToDateTime(dtRow["FOrderBudgetDate"]);
                }

               
                newEntry["FPurActAmount"] = dtRow["FOrderActAmount"];
                if (dtRow["FOrderActDate"] != null && dtRow["FOrderActDate"].ToString() != "")
                {
                    newEntry["FPurActDate"] = Convert.ToDateTime(dtRow["FOrderActDate"]);
                }
               
                newEntry["FPurNote"] = dtRow["FOrderNote"];

                entity.Add(newEntry);

                seq++;
            }
        }

        /// <summary>
        /// 销售
        /// </summary>
        /// <param name="billObj"></param>
        /// <param name="dt"></param>
        void SetRecAble(DynamicObject billObj, DataTable dt)
        {
            if (dt.Rows.Count <= 0)
            {
                return;
            }

            DynamicObjectCollection entity = billObj["FSalEntity"] as DynamicObjectCollection;
            int seq = 1;
            foreach (DataRow dtRow in dt.Rows)
            {
                DynamicObject newEntry = new DynamicObject(entity.DynamicCollectionItemPropertyType);

                //BaseDataField fldSupplier = this.View.BillBusinessInfo.GetField("FPayContactID") as BaseDataField;
                //DynamicObject supplierObj = BusinessDataServiceHelper.LoadFromCache(
                //    this.Context, new object[] { dtRow["FPayContactID"] }, fldSupplier.RefFormDynamicObjectType).FirstOrDefault();
                //fldSupplier.RefIDDynamicProperty.SetValue(newEntry, dtRow["FPayContactID"]);
                //fldSupplier.DynamicProperty.SetValue(newEntry, supplierObj);

                newEntry["Seq"] = seq;
                newEntry["FSalProgram"] = dtRow["FSaleCustName"];
                newEntry["FSalMaterial"] = dtRow["FSaleMaterialName"];
                newEntry["FSalBudgetAmount"] = dtRow["FSaleBudgetAmount"];
                if (dtRow["FSaleBudgetDate"] != null && dtRow["FSaleBudgetDate"].ToString() != "")
                {
                    newEntry["FSalBudgetDate"] = Convert.ToDateTime(dtRow["FSaleBudgetDate"]);
                }
               
                newEntry["FSalActAmount"] = dtRow["FSaleActAmount"];

                if (dtRow["FSaleActDate"] != null && dtRow["FSaleActDate"].ToString() != "")
                {
                    newEntry["FSalActDate"] = Convert.ToDateTime(dtRow["FSaleActDate"]);
                }

              
                newEntry["FSalNote"] = dtRow["FSaleNote"];

                entity.Add(newEntry);

                seq++;
            }
        }


        void ClearThisBill()
        {
            DynamicObject billObj = this.Model.DataObject;

            DynamicObjectCollection FPurEntity = billObj["FPurEntity"] as DynamicObjectCollection;
            FPurEntity.Clear();

            DynamicObjectCollection FSalEntity = billObj["FSalEntity"] as DynamicObjectCollection;
            FSalEntity.Clear();
        }
    }
}
