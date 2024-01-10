--工通书编号及项目统计表
--EXEC sp_YJ_GCTZSInfo
ALTER PROC sp_YJ_GCTZSInfo
AS
BEGIN
	--SELECT FGTSBILLID,FYear,FengineeNo,FMaterialName,FQty,FContraNo,FWHQ
	--      ,FWHP,FPZ,FSFZFL,FZGWD,FJRFS,FTZJD,FRFJC,FWLJC,FWMP
	--	  ,FYYDD,FJXDD,FDQDD,FCLTJ,FZZGC
	--	  ,FJHQYD,FJHQYS,FJHFS,FGCWCR,FWCZT
	--  FROM SHDP_t_Cust_Entry100033
	-- WHERE FID = @BillID

	SELECT  A.FID  FGTSBILLID --工程通知书内码
	       ,YEAR(FDATE) FYear --项目年份
	       ,ISNULL(A.FengineeNo,'') FengineeNo--工程编号
		   ,ISNULL(F.FprogramName,'') FprogramName--工程编号
		   ,ISNULL(A.F_PDLJ_Text1,'') F_PDLJ_Text1--工程编号(废弃)
		   ,ISNULL(B.FNAME,'') FProgramName--项目名称(废弃)
		   ,ISNULL(C.FNAME,'') FMaterialName--机型
		   ,ISNULL(C.FSPECIFICATION,'') FJXXH--机型型号
		   ,ISNULL(A.FQty,0) FQty--数量
	       ,ISNULL(A.FContraNo,'') FContraNo--合同编号
		   ,ISNULL(F.FEquipmentNumber,'') F_SHDP_Text5 --设备编号
		   ,ISNULL(F.FDrawingNumber,'') F_SHDP_Text6 --图纸编号
		   ,ISNULL(F.F_PDLJ_Text222,'') FWHQ --雾化器
		   ,ISNULL(F.F_PDLJ_Text2221,'') FWHP --雾化盘
		   ,ISNULL(F.F_SHDP__PDLJ_Text22222,'') FPZ --喷嘴
		   ,ISNULL(F.F_PDLJ_Text221,'') FSFZFL --水分蒸发量
		   ,ISNULL(F.F_PDLJ_Text22221,'') FZGWD--最高温度
		   ,ISNULL(F_PDLJ_Text2222,'') FJRFS--加热方式
		   ,ISNULL(F.F_PDLJ_Text22222,'') FTZJD--塔锥角度
		   ,ISNULL(F.F_PDLJ_Text2,'') FRFJC--热风接触
		   ,ISNULL(F.F_PDLJ_Text21,'') FWLJC--物料接触
		   ,ISNULL(F.F_PDLJ_Text22,'') FWMP--外蒙皮
		   ,ISNULL(I.FNAME,'') FYYDD--营业担当
		   ,ISNULL(G.FNAME,'') FJXDD--机械担当
		   ,ISNULL(J.FNAME,'') FDQDD--电气担当
		   ,ISNULL(K.FNAME,'') FCLTJ--材料统计
		   ,ISNULL(F.F_PDLJ_Text22211,'') FZZGC--制作工厂
		   ,ISNULL(F.F_PDLJ_deliveryDate1,null) FJHQYD--交货期（预定）
		   ,ISNULL(F.F_PDLJ_deliveryDate,null) FJHQYS--交货期（严守）
		   ,CASE WHEN F.F_PDLJ_deliver1 = 'fobsh' THEN 'FOB上海'
		         WHEN F.F_PDLJ_deliver1 = 'chjh' THEN '车船交货'
				 WHEN F.F_PDLJ_deliver1 = 'tshjh' THEN '调试后交货'
				 WHEN F.F_PDLJ_deliver1 = 'azhjh' THEN '安装后交货'
			ELSE '' END FJHFS --交货方式
		   ,ISNULL(F.F_PDLJ_compleDate,null) FGCWCR--工程完成日
		   ,CASE WHEN F.F_PDLJ_completionstatus = 'WCTS' THEN '完成调试'
		         WHEN F.F_PDLJ_completionstatus = 'WCAZ' THEN '完成安装'
			ELSE '' END FWCZT --完成状态
	  FROM  PDLJ_t_Cust130007 A --工程决定通知书
			LEFT JOIN T_BAS_PREBDONE_L B
			ON A.FENGINEENO = B.FID
			LEFT JOIN T_BAS_PREBDONE H
			ON A.FENGINEENO = H.FID
			LEFT JOIN T_BD_MATERIAL_L C
			ON A.F_PDLJ_Base = C.FMATERIALID
			LEFT JOIN V_BD_SALESMAN_L D
			ON A.F_QAPZ_Base1 = D.FID
			--LEFT JOIN PDLJ_t_taskPlan_LK E --任务计划书
			--ON E.FSBillId = A.FID
			LEFT JOIN PDLJ_t_taskPlan F --任务计划书
			ON A.F_PDLJ_Text1 = F.FprogramName
			LEFT JOIN T_HR_EMPINFO_L G
			ON F.FBusinessManager1 = G.FID
			LEFT JOIN T_HR_EMPINFO_L I
			ON F.F_QAPZ_BusinessManager1 = I.FID
			LEFT JOIN T_HR_EMPINFO_L J
			ON F.FProjectLeader2 = J.FID
			LEFT JOIN T_HR_EMPINFO_L K
			ON F.F_PDLJ_BUSINESSMANAGER1 = K.FID
	 WHERE  1=1
END