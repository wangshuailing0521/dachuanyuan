--营业配件一览表
--EXEC sp_YJ_BusinessInfoReport 'P23-012','','',''
ALTER PROC sp_YJ_BusinessInfoReport
	@ProgramNo VARCHAR(MAX)
   ,@ProgramGroup VARCHAR(MAX)
   ,@BeginTime VARCHAR(MAX)
   ,@EndTime VARCHAR(MAX)
   ,@TempTable VARCHAR(255) = ''
AS
BEGIN
	CREATE TABLE #TEMP(
	    FINDEX INT DEFAULT 0,
		FSalBillID INT,
		FSalEntryID INT,
		FProgramGroup VARCHAR(255), --项目分组
		FProgramID INT, --
		FProgramNo VARCHAR(255),--项目编码
		FSaler VARCHAR(255),--担当
		FCustName VARCHAR(255),--客户名称
		FSaleDate DATETIME ,--订货日
		FMaterialID INT,
		FMaterialInfo VARCHAR(255),--购买内容
		FSaleQty DECIMAL(28,10) DEFAULT 0,--数量
		FSaleAmount DECIMAL(28,10) DEFAULT 0,--总计金额
		FRecAmount DECIMAL(28,10) DEFAULT 0,--收款金额
		FRecDate DATETIME,--收款日
		FNoRecAmount DECIMAL(28,10) DEFAULT 0,--未收款金额
		FKPAmount DECIMAL(28,10) DEFAULT 0,--开票金额
		FKPDate DATETIME,--开票日
		FNoKPAmount DECIMAL(28,10) DEFAULT 0,--未开票金额
		FAbleAmount DECIMAL(28,10) DEFAULT 0,--销售额
		FDeliveryDate VARCHAR(255),--发货日
		FCarrier VARCHAR(255),--承运
		FWayBillNo VARCHAR(255),--快递单号
		FSCCost DECIMAL(28,10) DEFAULT 0,--生产成本
		FJZCost DECIMAL(28,10) DEFAULT 0,--结转成本
		FNoJZCost DECIMAL(28,10) DEFAULT 0,--未结转成本差异
		FStatus VARCHAR(255),--状态
		FAmount DECIMAL(28,10) DEFAULT 0,--金额
		FProfit DECIMAL(28,10) DEFAULT 0,--毛利
		FNote VARCHAR(255),--备注
	)

	CREATE TABLE #DETAILTEMP(
	    FINDEX INT DEFAULT 0,
		FSalBillID INT,
		FSalEntryID INT,
		FProgramGroup VARCHAR(255), --项目分组
		FProgramID INT, --
		FProgramNo VARCHAR(255),--项目编码
		FSaler VARCHAR(255),--担当
		FCustName VARCHAR(255),--客户名称
		FSaleDate DATETIME ,--订货日
		FMaterialID INT,
		FMaterialInfo VARCHAR(255),--购买内容
		FSaleQty DECIMAL(28,10) DEFAULT 0,--数量
		FSaleAmount DECIMAL(28,10) DEFAULT 0,--总计金额
		FRecAmount DECIMAL(28,10) DEFAULT 0,--收款金额
		FRecDate DATETIME,--收款日
		FNoRecAmount DECIMAL(28,10) DEFAULT 0,--未收款金额
		FKPAmount DECIMAL(28,10) DEFAULT 0,--开票金额
		FKPDate DATETIME,--开票日
		FNoKPAmount DECIMAL(28,10) DEFAULT 0,--未开票金额
		FAbleAmount DECIMAL(28,10) DEFAULT 0,--销售额
		FDeliveryDate DATETIME,--发货日
		FCarrier VARCHAR(255),--承运
		FWayBillNo VARCHAR(255),--快递单号
		FSCCost DECIMAL(28,10) DEFAULT 0,--生产成本
		FJZCost DECIMAL(28,10) DEFAULT 0,--结转成本
		FNoJZCost DECIMAL(28,10) DEFAULT 0,--未结转成本差异
		FStatus VARCHAR(255),--状态
		FAmount DECIMAL(28,10) DEFAULT 0,--金额
		FProfit DECIMAL(28,10) DEFAULT 0,--毛利
		FNote VARCHAR(255),--备注
	)

	INSERT INTO #TEMP(
		FProgramGroup,FProgramID,FProgramNo,FCustName,FSaler,FSaleDate)
	SELECT D.FNUMBER + '-'+ DL.FNAME,B.F_PDLJ_BASE2,C.FNUMBER,BCL.FShortName,BS.FNAME FSaler,MAX(A.FDATE) FSaleDate
	  FROM  T_SAL_ORDER A
			INNER JOIN T_SAL_ORDERENTRY B
			ON A.FID = B.FID
			LEFT JOIN T_SAL_ORDERENTRY_F BF
			ON B.FENTRYID = BF.FENTRYID
			LEFT JOIN T_SAL_ORDERENTRY_D BD
			ON B.FENTRYID = BD.FENTRYID
			LEFT JOIN T_BAS_PREBDONE C
			ON B.F_PDLJ_BASE2 = C.FID
			LEFT JOIN T_Project D
			ON C.F_PDLJ_Group = D.FID 
			LEFT JOIN T_Project_L DL
			ON C.F_PDLJ_Group = DL.FID AND DL.FLocaleID = 2052
			LEFT JOIN V_BD_SALESMAN_L BS
			ON A.FSALERID = BS.FID AND BS.FLOCALEID = 2052
			LEFT JOIN T_BD_CUSTOMER_L BCL
			ON A.FCUSTID = BCL.FCUSTID AND BCL.FLOCALEID = 2052
			LEFT JOIN T_BD_MATERIAL_L BML
			ON B.FMATERIALID = BML.FMATERIALID AND BML.FLOCALEID = 2052
	 WHERE  ((@ProgramNo <> '' AND (C.FNUMBER IN (SELECT value FROM sp_split(@ProgramNo,','))) )OR @ProgramNo = '')
	   AND  ((@ProgramGroup <> '' AND (D.FNUMBER IN (SELECT value FROM sp_split(@ProgramGroup,','))) )OR @ProgramGroup = '')
	   AND  ((A.FDATE >= @BeginTime AND @BeginTime <> '' ) OR @BeginTime = '')
	   AND  ((A.FDATE <= @EndTime AND @EndTime <> '' ) OR @EndTime = '')
	   AND  D.FNUMBER IN ('P','X','T')
	 GROUP  BY D.FNUMBER,DL.FNAME,B.F_PDLJ_BASE2,C.FNUMBER,BCL.FShortName,BS.FNAME

	INSERT INTO #DETAILTEMP(
		FSalBillID,FSalEntryID,FProgramGroup,FProgramID,FProgramNo,FSaler,FCustName,FSaleDate,
		FMaterialID,FMaterialInfo,FSaleQty,FSaleAmount,FDeliveryDate,FCarrier,FWayBillNo,FINDEX)
	SELECT  A.FID
	       ,B.FENTRYID
	       ,D.FNUMBER + '-'+ DL.FNAME
		   ,B.F_PDLJ_BASE2 FProgramID
		   ,C.FNUMBER FProgramNo
		   ,BS.FNAME FSaler
		   ,BCL.FShortName FCustName
		   ,A.FDATE FSaleDate
		   ,B.FMATERIALID
		   ,BML.FNAME + BML.FSPECIFICATION FMaterialInfo
		   ,B.FQTY FSaleQty
		   ,BF.FAllAmount FSaleAmount
		   ,B.F_SHDP_Date
		   ,B.F_SHDP_Combo1 FCarrier
		   ,B.F_SHDP_Text1 FWayBillNo
		   ,CASE WHEN D.FNUMBER = 'P' THEN 1
				 WHEN D.FNUMBER = 'X' THEN 2
				 WHEN D.FNUMBER = 'T' THEN 3
			ELSE 4
			END FINDEX
	  FROM  T_SAL_ORDER A
			INNER JOIN T_SAL_ORDERENTRY B
			ON A.FID = B.FID
			LEFT JOIN T_SAL_ORDERENTRY_F BF
			ON B.FENTRYID = BF.FENTRYID
			LEFT JOIN T_SAL_ORDERENTRY_D BD
			ON B.FENTRYID = BD.FENTRYID
			LEFT JOIN T_BAS_PREBDONE C
			ON B.F_PDLJ_BASE2 = C.FID
			LEFT JOIN T_Project D
			ON C.F_PDLJ_Group = D.FID 
			LEFT JOIN T_Project_L DL
			ON C.F_PDLJ_Group = DL.FID AND DL.FLocaleID = 2052
			LEFT JOIN V_BD_SALESMAN_L BS
			ON A.FSALERID = BS.FID AND BS.FLOCALEID = 2052
			LEFT JOIN T_BD_CUSTOMER_L BCL
			ON A.FCUSTID = BCL.FCUSTID AND BCL.FLOCALEID = 2052
			LEFT JOIN T_BD_MATERIAL_L BML
			ON B.FMATERIALID = BML.FMATERIALID AND BML.FLOCALEID = 2052
	 WHERE  ((@ProgramNo <> '' AND (C.FNUMBER IN (SELECT value FROM sp_split(@ProgramNo,','))) )OR @ProgramNo = '')
	   AND  ((@ProgramGroup <> '' AND (D.FNUMBER IN (SELECT value FROM sp_split(@ProgramGroup,','))) )OR @ProgramGroup = '')
	   AND  ((A.FDATE >= @BeginTime AND @BeginTime <> '' ) OR @BeginTime = '')
	   AND  ((A.FDATE <= @EndTime AND @EndTime <> '' ) OR @EndTime = '')
	   AND  D.FNUMBER IN ('P','X','T')

	--更新数量，总计金额
	UPDATE  A 
	   SET  A.FSaleQty  = B.FSaleQty
	       ,A.FSaleAmount = B.FSaleAmount
	  FROM  #TEMP A 
			INNER JOIN (SELECT FProgramID,SUM(FSaleQty)FSaleQty,SUM(FSaleAmount)FSaleAmount FROM #DETAILTEMP GROUP BY FProgramID) B
			ON A.FProgramID = B.FProgramID

	--更新购买内容
	SELECT ROW_NUMBER() OVER(PARTITION BY FProgramID ORDER BY FMaterialInfo)FSeq,FProgramID,FMaterialInfo INTO #MaterialGroup 
	FROM #DETAILTEMP GROUP BY FProgramID,FMaterialInfo
	UPDATE #MaterialGroup SET FMaterialInfo = '等' WHERE FSeq > 2
	DELETE FROM #MaterialGroup WHERE FSeq > 3

	SELECT  FProgramID,
		STUFF((SELECT  ','+ FMaterialInfo FROM #MaterialGroup A WHERE A.FProgramID = B.FProgramID ORDER BY FSEQ ASC
		   FOR XML PATH('')), 1, 1, '') AS FMaterialInfo
	  INTO #DMaterialGroup
	  FROM  #MaterialGroup B
	 GROUP  BY FProgramID

    UPDATE   A
      SET   A.FMaterialInfo = B.FMaterialInfo
     FROM   #TEMP A
			INNER JOIN #DMaterialGroup B
			ON A.FProgramID = B.FProgramID

	--更新发货日，承运，快递单号
	SELECT  FProgramID,
		STUFF((SELECT  DISTINCT '/'+ CONVERT(VARCHAR(10),FDeliveryDate,120)
		         FROM #DETAILTEMP A WHERE A.FProgramID = B.FProgramID
		   FOR XML PATH('')), 1, 1, '') AS FDeliveryDate,
		STUFF((SELECT  DISTINCT '/'+ FCarrier
		         FROM #DETAILTEMP A WHERE A.FProgramID = B.FProgramID
		   FOR XML PATH('')), 1, 1, '') AS FCarrier,
		STUFF((SELECT  DISTINCT '/'+ FWayBillNo 
		         FROM #DETAILTEMP A WHERE A.FProgramID = B.FProgramID
		   FOR XML PATH('')), 1, 1, '') AS FWayBillNo
	  INTO #ProgramSalGroup
	  FROM  #DETAILTEMP B
	 GROUP  BY FProgramID
	
   UPDATE   A
      SET   A.FDeliveryDate = B.FDeliveryDate
	       ,A.FCarrier = B.FCarrier
		   ,A.FWayBillNo = B.FWayBillNo
     FROM   #TEMP A
			INNER JOIN #ProgramSalGroup B
			ON A.FProgramID = B.FProgramID
	----------------------------------------------------------------------------------------------------------------
	--获取应收单
	----------------------------------------------------------------------------------------------------------------
	SELECT  B.FPRESETBASE1 FProgramID,A.FDATE,B.FALLAMOUNTFOR FAMOUNT,B.FNOTAXAMOUNTFOR
	  INTO  #AbleTable
	  FROM  T_AR_RECEIVABLE A
			INNER JOIN T_AR_RECEIVABLEENTRY B
			ON A.FID = B.FID
			INNER JOIN #TEMP C
			ON B.FPRESETBASE1 = C.FProgramID
     WHERE  A.FDOCUMENTSTATUS = 'C'
	   AND  A.FSetAccountType = '3' --财务应收
	----------------------------------------------------------------------------------------------------------------
	--获取收款单
	----------------------------------------------------------------------------------------------------------------
	SELECT  B.F_PDLJ_BASE FProgramID, A.FDATE,B.FREALRECAMOUNTFOR FAMOUNT
	  INTO  #RecTable
	  FROM  T_AR_RECEIVEBILL A
			INNER JOIN T_AR_RECEIVEBILLENTRY B
			ON A.FID = B.FID
			INNER JOIN #TEMP C
			ON B.F_PDLJ_BASE = C.FProgramID
     WHERE  A.FDOCUMENTSTATUS = 'C'

	UPDATE  A
	   SET  A.FKPDate = B.FDATE
	       ,A.FKPAmount = ISNULL(B.FAMOUNT,0)
		   ,A.FAbleAmount = ISNULL(B.FNOTAXAMOUNTFOR,0)
	  FROM  #TEMP A
			LEFT JOIN (SELECT FProgramID,MAX(FDATE)FDATE,SUM(FAMOUNT)FAMOUNT,SUM(FNOTAXAMOUNTFOR)FNOTAXAMOUNTFOR
			             FROM #AbleTable GROUP BY FProgramID)B
			ON A.FProgramID = B.FProgramID

	UPDATE  A
	   SET  A.FRecDate = B.FDATE
	       ,A.FRecAmount = ISNULL(B.FAMOUNT,0)
	  FROM  #TEMP A
			LEFT JOIN (SELECT FProgramID,MAX(FDATE)FDATE,SUM(FAMOUNT)FAMOUNT FROM #RecTable GROUP BY FProgramID)B
			ON A.FProgramID = B.FProgramID

	UPDATE #TEMP SET FNoKPAmount = FSaleAmount - FKPAmount
	UPDATE #TEMP SET FNoRecAmount = FSaleAmount - FRecAmount

	----------------------------------------------------------------------------------------------------------------
	--获取科目余额表
	----------------------------------------------------------------------------------------------------------------
	CREATE TABLE #Acct(
		FAcctID INT,
		FAcctNo VARCHAR(255),
		FLevel INT,
		FParentID INT,
		FLeve12ParentID INT,
		FLeve12ParentNo VARCHAR(255),
		FLeve13ParentNo VARCHAR(255),
		FLeve14ParentNo VARCHAR(255),
	)

	INSERT INTO #Acct
	SELECT FACCtID,FNUMBER,FLEVEL,FPARENTID,FACCtID,FNUMBER,'',''
	  FROM T_BD_ACCOUNT A
	 WHERE A.FLEVEL = 1
	   AND A.FNUMBER IN ('5001')

	INSERT INTO #Acct
	SELECT  A.FACCtID,A.FNUMBER,A.FLEVEL,A.FPARENTID,B.FLeve12ParentID,FLeve12ParentNo,A.FNUMBER,''
	  FROM  T_BD_ACCOUNT A
			INNER JOIN #Acct B
			ON A.FPARENTID = B.FACCtID
	 WHERE  A.FLEVEL = 2

	INSERT INTO #Acct
	SELECT  A.FACCtID,A.FNUMBER,A.FLEVEL,A.FPARENTID,B.FLeve12ParentID,FLeve12ParentNo,A.FNUMBER,''
	  FROM  T_BD_ACCOUNT A
			INNER JOIN #Acct B
			ON A.FPARENTID = B.FACCtID
	 WHERE  A.FLEVEL = 3

	INSERT INTO #Acct
	SELECT  A.FACCtID,A.FNUMBER,A.FLEVEL,A.FPARENTID,B.FLeve12ParentID,FLeve12ParentNo,FLeve13ParentNo,A.FNUMBER
	  FROM  T_BD_ACCOUNT A
			INNER JOIN #Acct B
			ON A.FPARENTID = B.FACCtID
	 WHERE  A.FLEVEL = 4

	DECLARE @YearPeriod INT
	SET @YearPeriod = ISNULL((SELECT MAX(FYEARPERIOD) FROM T_GL_Balance ),0)

	SELECT  C.FF100003 FProgramID,C.FFLEX5 FMaterialID, H.FLeve12ParentNo,SUM(A.FCREDIT)FCREDIT,SUM(A.FDEBIT)FDEBIT
	  INTO  #Balance
	  FROM  T_GL_Balance A
			INNER JOIN T_BD_ACCOUNT B
			ON B.FACCTID = A.FACCOUNTID
			INNER JOIN T_BD_FLEXITEMDETAILV C
			ON A.FDETAILID = C.FID
			INNER JOIN #Acct H
			ON A.FACCOUNTID = H.FAcctID
	 WHERE  1=1
	   --AND  ((A.FYEAR >= @BeginYear AND @BeginYear <> '' ) OR @BeginYear = '')
	   --AND  ((A.FYEAR <= @EndYear AND @EndYear <> '' ) OR @EndYear = '')
	   AND  C.FF100003 IN (SELECT FProgramID FROM #TEMP)
	   --AND  C.FFLEX5 IN (SELECT FMaterialID FROM #TEMP)
	   AND  A.FACCOUNTID IN (SELECT FAcctID FROM #Acct)
	   AND  A.FCURRENCYID <> 0
	   --AND  A.FYEARPERIOD = @YearPeriod
	 GROUP  BY C.FF100003,C.FFLEX5,H.FLeve12ParentNo

	UPDATE  A
	   SET  A.FSCCost = B.FDEBIT
		   ,A.FJZCost = B.FCREDIT
	  FROM  #TEMP A
			INNER JOIN (SELECT FProgramID,FMaterialID,SUM(FCREDIT)FCREDIT,SUM(FDEBIT)FDEBIT
						  FROM #Balance 
						 WHERE FLeve12ParentNo = '5001' 
						 GROUP BY FProgramID,FMaterialID) B
			ON A.FProgramID = B.FProgramID 
			--AND A.FMaterialID = B.FMaterialID

	UPDATE #TEMP SET FNoJZCost = FSCCost - FJZCost
	UPDATE #TEMP SET FAmount = ABS(FKPAmount - FRecAmount)
	UPDATE #TEMP SET FProfit = FAbleAmount - FSCCost
	UPDATE #TEMP SET FStatus = '预收' WHERE FKPAmount - FRecAmount < 0
	UPDATE #TEMP SET FStatus = '平' WHERE FKPAmount - FRecAmount = 0
	UPDATE #TEMP SET FStatus = '应收' WHERE FKPAmount - FRecAmount > 0

	SELECT * FROM #TEMP ORDER BY FINDEX ASC

	IF(@TempTable <> '')
	BEGIN
		DECLARE @SQL VARCHAR(2000)
		SET @SQL = '
		SELECT ROW_NUMBER() OVER(ORDER BY FINDEX ASC) FIDENTITYID,* 
		  INTO '+@TempTable+'
		  FROM #TEMP'

		EXECUTE(@SQL)
	END
END

