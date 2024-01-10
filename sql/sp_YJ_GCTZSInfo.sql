--��ͨ���ż���Ŀͳ�Ʊ�
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

	SELECT  A.FID  FGTSBILLID --����֪ͨ������
	       ,YEAR(FDATE) FYear --��Ŀ���
	       ,ISNULL(A.FengineeNo,'') FengineeNo--���̱��
		   ,ISNULL(F.FprogramName,'') FprogramName--���̱��
		   ,ISNULL(A.F_PDLJ_Text1,'') F_PDLJ_Text1--���̱��(����)
		   ,ISNULL(B.FNAME,'') FProgramName--��Ŀ����(����)
		   ,ISNULL(C.FNAME,'') FMaterialName--����
		   ,ISNULL(C.FSPECIFICATION,'') FJXXH--�����ͺ�
		   ,ISNULL(A.FQty,0) FQty--����
	       ,ISNULL(A.FContraNo,'') FContraNo--��ͬ���
		   ,ISNULL(F.FEquipmentNumber,'') F_SHDP_Text5 --�豸���
		   ,ISNULL(F.FDrawingNumber,'') F_SHDP_Text6 --ͼֽ���
		   ,ISNULL(F.F_PDLJ_Text222,'') FWHQ --����
		   ,ISNULL(F.F_PDLJ_Text2221,'') FWHP --����
		   ,ISNULL(F.F_SHDP__PDLJ_Text22222,'') FPZ --����
		   ,ISNULL(F.F_PDLJ_Text221,'') FSFZFL --ˮ��������
		   ,ISNULL(F.F_PDLJ_Text22221,'') FZGWD--����¶�
		   ,ISNULL(F_PDLJ_Text2222,'') FJRFS--���ȷ�ʽ
		   ,ISNULL(F.F_PDLJ_Text22222,'') FTZJD--��׶�Ƕ�
		   ,ISNULL(F.F_PDLJ_Text2,'') FRFJC--�ȷ�Ӵ�
		   ,ISNULL(F.F_PDLJ_Text21,'') FWLJC--���ϽӴ�
		   ,ISNULL(F.F_PDLJ_Text22,'') FWMP--����Ƥ
		   ,ISNULL(I.FNAME,'') FYYDD--Ӫҵ����
		   ,ISNULL(G.FNAME,'') FJXDD--��е����
		   ,ISNULL(J.FNAME,'') FDQDD--��������
		   ,ISNULL(K.FNAME,'') FCLTJ--����ͳ��
		   ,ISNULL(F.F_PDLJ_Text22211,'') FZZGC--��������
		   ,ISNULL(F.F_PDLJ_deliveryDate1,null) FJHQYD--�����ڣ�Ԥ����
		   ,ISNULL(F.F_PDLJ_deliveryDate,null) FJHQYS--�����ڣ����أ�
		   ,CASE WHEN F.F_PDLJ_deliver1 = 'fobsh' THEN 'FOB�Ϻ�'
		         WHEN F.F_PDLJ_deliver1 = 'chjh' THEN '��������'
				 WHEN F.F_PDLJ_deliver1 = 'tshjh' THEN '���Ժ󽻻�'
				 WHEN F.F_PDLJ_deliver1 = 'azhjh' THEN '��װ�󽻻�'
			ELSE '' END FJHFS --������ʽ
		   ,ISNULL(F.F_PDLJ_compleDate,null) FGCWCR--���������
		   ,CASE WHEN F.F_PDLJ_completionstatus = 'WCTS' THEN '��ɵ���'
		         WHEN F.F_PDLJ_completionstatus = 'WCAZ' THEN '��ɰ�װ'
			ELSE '' END FWCZT --���״̬
	  FROM  PDLJ_t_Cust130007 A --���̾���֪ͨ��
			LEFT JOIN T_BAS_PREBDONE_L B
			ON A.FENGINEENO = B.FID
			LEFT JOIN T_BAS_PREBDONE H
			ON A.FENGINEENO = H.FID
			LEFT JOIN T_BD_MATERIAL_L C
			ON A.F_PDLJ_Base = C.FMATERIALID
			LEFT JOIN V_BD_SALESMAN_L D
			ON A.F_QAPZ_Base1 = D.FID
			--LEFT JOIN PDLJ_t_taskPlan_LK E --����ƻ���
			--ON E.FSBillId = A.FID
			LEFT JOIN PDLJ_t_taskPlan F --����ƻ���
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