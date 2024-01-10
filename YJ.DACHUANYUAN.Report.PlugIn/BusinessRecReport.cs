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
    [Description("营业收款月报")]
    [HotUpdate]
    public class BusinessRecReport : AbstractBillPlugIn
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
                this.Context, $@"EXEC sp_YJ_BusinessRecReport {year},{month}");

            SetBudget(billObj, ds.Tables[0]);
            SetAct(billObj, ds.Tables[1]);
        }

        /// <summary>
        /// 预定
        /// </summary>
        /// <param name="billObj"></param>
        /// <param name="dt"></param>
        void SetBudget(DynamicObject billObj, DataTable dt)
        {
            if (dt.Rows.Count <= 0)
            {
                return;
            }

            DynamicObjectCollection entity = billObj["FBudgetEntity"] as DynamicObjectCollection;

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
                newEntry["FBudgetProgram"] = dtRow["FBudgetProgramName"];
                newEntry["FBudgetNote"] = dtRow["FBudgetNote"];
                newEntry["FBudgetAmount"] = dtRow["FBudgetAmount"];
                newEntry["FBudgetPayType"] = dtRow["FBudgetPayType"];
             

                entity.Add(newEntry);

                seq++;
            }
        }

        /// <summary>
        /// 实绩
        /// </summary>
        /// <param name="billObj"></param>
        /// <param name="dt"></param>
        void SetAct(DynamicObject billObj, DataTable dt)
        {
            if (dt.Rows.Count <= 0)
            {
                return;
            }

            DynamicObjectCollection entity = billObj["FActEntity"] as DynamicObjectCollection;
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
                newEntry["FActProgram"] = dtRow["FActProgramName"];
                newEntry["FActNote"] = dtRow["FActNote"];
                newEntry["FActAmount"] = dtRow["FActAmount"];
               

                entity.Add(newEntry);

                seq++;
            }
        }


        void ClearThisBill()
        {
            DynamicObject billObj = this.Model.DataObject;

            DynamicObjectCollection FBudgetEntity = billObj["FBudgetEntity"] as DynamicObjectCollection;
            FBudgetEntity.Clear();

            DynamicObjectCollection FActEntity = billObj["FActEntity"] as DynamicObjectCollection;
            FActEntity.Clear();
        }
    }
}
