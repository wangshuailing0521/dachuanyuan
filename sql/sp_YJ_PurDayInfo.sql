--�ɹ�ÿ�ո��ٱ�
ALTER PROC sp_YJ_PurDayInfo
	@TempTable VARCHAR(255) = ''
AS
BEGIN
	CREATE TABLE #TEMP(
		FPurBillID INT,
		FPurEntryID INT,
		FPurBillNo VARCHAR(2000), --���ݱ�� �ɹ�����ѯ�۵���
		FPurDate DATETIME, --���� �ɹ������ɹ�����
		FSupplierName VARCHAR(2000), --��Ӧ�� ��Ӧ�̼��
		FProgramName VARCHAR(2000),--��Ŀ���� �ɹ�������ϸ��--��Ŀ����
		FProgramNumber VARCHAR(2000),--��Ŀ��� �ɹ�������ϸ��--��Ŀ��
		FMaterialName VARCHAR(2000),--Ʒ�� ���Ӧ��������
		FSpecification VARCHAR(2000),--��� ���Ӧ�����ͺ�
		FMaterialCZ VARCHAR(2000),--���� ���Ӧ���ϲ��ʹ����
		FMaterialCZ1 VARCHAR(2000),--���� ���Ӧ���ϲ��ʷ���
		FNote VARCHAR(2000), --��ע �ɹ�������ϸ�еı�ע
		FQty DECIMAL(28,10), --���� �ɹ�������ϸ��--����
		FBudgetDHDate VARCHAR(255),--Ԥ�ڵ��� �ɹ�������ϸ�н��������ֶ�
		FPrice DECIMAL(28,10),--���� �ɹ�������ϸ�е���
		FAmount DECIMAL(28,10),--�ܼ� �ɹ�������ϸ�м�˰�ϼ�
		FActDHDate VARCHAR(255),--ʵ�ʵ����� ר�������嵥��ϸ�ж�ʵ�ʵ�������
		FPayType VARCHAR(255),--���ʽ �ɹ���������ͷʵ�ʸ�������
		FQWPayDate VARCHAR(255),--������� ��Ӧ�������뵥����ϸ�ж�Ӧ������������
		FPayDate VARCHAR(255),--�������� ��Ӧ�������
		FPayAmount DECIMAL(28,10), --������ ��Ӧ������
		FInvoiveNo VARCHAR(255),--��Ʊ���� ��ӦӦ��������ͷ��Ʊ����
		FInvoiveRecDate VARCHAR(255),--��Ʊ�յ����� Ӧ����ҵ������
		FInvoiveCreateDate VARCHAR(255),--��Ʊ������ ��ӦӦ������Ʊ��������
		FXJBillNo VARCHAR(255),--ѯ�۵���
		)
	INSERT INTO #TEMP(
		FPurBillID,FPurEntryID,FPurBillNo,FPurDate,FSupplierName,FProgramName,FProgramNumber
	   ,FMaterialName,FSpecification,FMaterialCZ,FMaterialCZ1,FNote,FQty,FBudgetDHDate
	   ,FPrice,FAmount,FPayType,FXJBillNo)
	SELECT  A.FID,B.FENTRYID,A.FBILLNO,A.FDATE,BSL.FSHORTNAME,D.FNAME,C.FNUMBER
		   ,BML.FNAME,BML.FSPECIFICATION,BM.F_PDLJ_Text7,F_PDLJ_Text12,B.FNOTE,B.FQTY,CONVERT(VARCHAR(10),BD.FDELIVERYDATE,120)
		   ,BF.FTaxPrice,BF.FAllAmount,A.F_SHDP_Remarks,A.F_QAPZ_Text
	  FROM  T_PUR_POORDER A
			INNER JOIN T_PUR_POORDERENTRY B
			ON A.FID = B.FID
			INNER JOIN T_PUR_POORDERENTRY_D BD
			ON B.FENTRYID = BD.FENTRYID
			INNER JOIN T_PUR_POORDERENTRY_F BF
			ON B.FENTRYID = BF.FENTRYID
			INNER JOIN T_BAS_PREBDONE C
			ON B.F_qqqq_Base1 = C.FID
			INNER JOIN T_BAS_PREBDONE_L D
			ON C.FID = D.FID
			INNER JOIN T_BD_MATERIAL BM 
			ON B.FMATERIALID = BM.FMATERIALID
			INNER JOIN T_BD_MATERIAL_L BML
			ON B.FMATERIALID = BML.FMATERIALID AND BML.FLOCALEID = 2052
			LEFT JOIN T_BD_SUPPLIER_L BSL
			ON A.FSUPPLIERID = BSL.FSUPPLIERID AND BSL.FLOCALEID = 2052
	 WHERE  1=1
	   AND  A.FDOCUMENTSTATUS = 'C'

	SELECT  DISTINCT
			B.FOrderEntryID
	       ,A.FDATE FInvoiveRecDate
		   ,A.F_PDLJ_Remarks FInvoiveNo
		   ,A.F_SHDP_DATE FInvoiveCreateDate
	  INTO  #PayAble
	  FROM  T_AP_PAYABLE A
			INNER JOIN T_AP_PAYABLEENTRY B
			ON A.FID = B.FID
	 WHERE  A.FDOCUMENTSTATUS = 'C'
	   AND  A.FCANCELSTATUS = 'A'
	   AND  B.FOrderEntryID IN (SELECT FPurEntryID FROM #TEMP)

	SELECT  DISTINCT
			B.FOrderEntryID
		   ,B.FEXPECTPAYDATE
	  INTO  #PayApply
	  FROM  T_CN_PAYAPPLY A
			INNER JOIN T_CN_PAYAPPLYENTRY B
			ON A.FID = B.FID
	 WHERE  A.FDOCUMENTSTATUS = 'C'
	   AND  A.FCANCELSTATUS = 'A'
	   AND  B.FOrderEntryID IN (SELECT FPurEntryID FROM #TEMP)

	SELECT  DISTINCT
			D.FOrderEntryID
		   ,A.FDATE
	  INTO  #PayBill
	  FROM  T_AP_PAYBILL A
			INNER JOIN T_AP_PAYBILLSRCENTRY B
			ON A.FID = B.FID
			INNER JOIN T_AP_PAYBILLSRCENTRY_LK C
			ON B.FENTRYID = C.FENTRYID
			INNER JOIN T_CN_PAYAPPLYENTRY D
			ON C.FSID = D.FENTRYID AND C.FSBILLID = D.FID
	 WHERE  A.FDOCUMENTSTATUS = 'C'
	   AND  A.FCANCELSTATUS = 'A'
	   AND  B.FOrderEntryID IN (SELECT FPurEntryID FROM #TEMP)

	SELECT  D.FOrderEntryID
		   ,SUM(B.FREALPAYAMOUNT)FREALPAYAMOUNT
	  INTO  #PayBillAmount
	  FROM  T_AP_PAYBILL A
			INNER JOIN T_AP_PAYBILLSRCENTRY B
			ON A.FID = B.FID
			INNER JOIN T_AP_PAYBILLSRCENTRY_LK C
			ON B.FENTRYID = C.FENTRYID
			INNER JOIN T_CN_PAYAPPLYENTRY D
			ON C.FSID = D.FENTRYID AND C.FSBILLID = D.FID
	 WHERE  A.FDOCUMENTSTATUS = 'C'
	   AND  A.FCANCELSTATUS = 'A'
	   AND  B.FOrderEntryID IN (SELECT FPurEntryID FROM #TEMP)
	 GROUP  BY D.FOrderEntryID


	UPDATE  A 
	   SET  A.FQWPayDate = CONVERT(VARCHAR(10),B.FEXPECTPAYDATE,120)
	  FROM  #TEMP A
			INNER JOIN #PayApply B
			ON A.FPurEntryID = B.FORDERENTRYID

	UPDATE  A 
	   SET  A.FPayDate = CONVERT(VARCHAR(10),B.FDATE,120)
	  FROM  #TEMP A
			INNER JOIN #PayBill B
			ON A.FPurEntryID = B.FORDERENTRYID

	
	UPDATE  A 
	   SET  A.FPayAmount = B.FREALPAYAMOUNT
	  FROM  #TEMP A
			INNER JOIN #PayBillAmount B
			ON A.FPurEntryID = B.FORDERENTRYID

	UPDATE  A 
	   SET  A.FInvoiveRecDate = CONVERT(VARCHAR(10),B.FInvoiveRecDate,120)
	       ,A.FInvoiveNo = B.FInvoiveNo
		   ,A.FInvoiveCreateDate = CONVERT(VARCHAR(10),B.FInvoiveCreateDate,120)
	  FROM  #TEMP A
			INNER JOIN #PayAble B
			ON A.FPurEntryID = B.FORDERENTRYID

	--��ȡʵ�ʷ�����
	UPDATE  A
	   SET  A.FActDHDate = CONVERT(VARCHAR(10),E.F_QAPZ_DATE1,120)
	  FROM  #TEMP A
			INNER JOIN T_PUR_POORDERENTRY_LK B
			ON A.FPurEntryID = B.FENTRYID
			INNER JOIN T_PUR_ReqEntry C
			ON B.FSID = C.FENTRYID AND B.FSBILLID = C.FID
			INNER JOIN T_PUR_ReqEntry_LK D
			ON C.FENTRYID = D.FENTRYID
			INNER JOIN PDLJ_t_MateAllocaEntry E
			ON D.FSID = E.FEntryID AND D.FSBILLID = E.FID

	SELECT * FROM #TEMP

	IF(@TempTable <> '')
	BEGIN
		DECLARE @SQL VARCHAR(2000)
		SET @SQL = '
		SELECT ROW_NUMBER() OVER(ORDER BY FPurBillNo DESC) FIDENTITYID,* 
		  INTO '+@TempTable+'
		  FROM #TEMP'

		EXECUTE(@SQL)
	END

	
END