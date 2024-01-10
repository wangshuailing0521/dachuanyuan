--营业业务月报
ALTER PROC sp_YJ_BusinessOperateReport
	@Year INT,
	@Period INT
AS
BEGIN
	IF(@Year = '')
	BEGIN
		SET @Year = 2010
	END
	IF(@Period = '')
	BEGIN
		SET @Period = 1
	END

	DECLARE @BeginTime VARCHAR(255)
	DECLARE @EndTime VARCHAR(255)

	SET @BeginTime = CONVERT(VARCHAR(4),@Year) + '-' + CONVERT(VARCHAR(2),@Period) + '-01'
	IF(@Period < 10)
	BEGIN
		SET @BeginTime = CONVERT(VARCHAR(4),@Year) + '-0' + CONVERT(VARCHAR(1),@Period) + '-01'
	END
	SET @EndTime = CONVERT(VARCHAR(10),DATEADD(MONTH,1,@BeginTime),120)

	CREATE TABLE #Order(
		FBillID INT,
		FOrderProgramID INT,
		FOrderCustName VARCHAR(255) DEFAULT '',
		FOrderMaterialName VARCHAR(255) DEFAULT '',
		FOrderBudgetAmount DECIMAL(28,10) DEFAULT 0,
		FOrderBudgetDate VARCHAR(255) DEFAULT '',
		FOrderActAmount DECIMAL(28,10) DEFAULT 0,
		FOrderActDate VARCHAR(255) DEFAULT '',
		FOrderNote VARCHAR(255) DEFAULT '',
	)
	CREATE TABLE #Sale(
		FBillID INT,
		FSalProgramID INT,
		FSaleCustName VARCHAR(255) DEFAULT '',
		FSaleMaterialName VARCHAR(255) DEFAULT '',
		FSaleBudgetAmount DECIMAL(28,10) DEFAULT 0,
		FSaleBudgetDate VARCHAR(255) DEFAULT '',
		FOrderActAmount DECIMAL(28,10) DEFAULT 0,
		FSaleActAmount DECIMAL(28,10) DEFAULT 0,
		FSaleActDate VARCHAR(255) DEFAULT '',
		FSaleNote VARCHAR(255) DEFAULT '',
	)

	------------------------------------------------------------------------------------------------------------
	--订货
	------------------------------------------------------------------------------------------------------------
	INSERT INTO #Order (FBillID,FOrderCustName,FOrderActAmount,FOrderActDate)
	SELECT  A.FID,C.FSHORTNAME,SUM(D.FALLAMOUNT),CONVERT(VARCHAR(10),A.FDATE,120)
	  FROM  T_SAL_ORDER A
			INNER JOIN T_SAL_ORDERENTRY B
			ON A.FID = B.FID
			INNER JOIN T_SAL_ORDERENTRY_F D
			ON B.FENTRYID = D.FENTRYID
			INNER JOIN T_BD_CUSTOMER_L C
			ON A.FCUSTID = C.FCUSTID
     WHERE  A.FDATE >= @BeginTime
	   AND  A.FDATE < @EndTime 
	   AND  A.FDOCUMENTSTATUS = 'C'
	   AND  A.FCANCELSTATUS = 'A'
	 GROUP  BY A.FID,C.FSHORTNAME,A.FDATE 

	UPDATE  A
	   SET  A.FOrderBudgetAmount = B.FPurBudgetAmount
	       ,A.FOrderBudgetDate = B.FPurBudgetDate
	  FROM  #Order A
			INNER JOIN T_YJ_PeriodBusPur B
			ON A.FOrderCustName = B.FPurProgram
			INNER JOIN T_YJ_PeriodBus C
			ON B.FID = C.FID 
	 WHERE  C.FDOCUMENTSTATUS = 'C'
	   AND  C.FYear = @Year
	   AND  C.FMonth = @Period
	   AND  C.FBillTypeID = '654b8888f4c2b7' --预定 654b88a3f4c2d9

	SELECT  ROW_NUMBER() OVER(PARTITION BY FID ORDER BY A.FSEQ ASC)FSeq,A.FID FBillID,B.FNAME
	  INTO  #MaterialGroup
	  FROM  T_SAL_ORDERENTRY A
			INNER JOIN T_BD_MATERIAL_L B
			ON A.FMATERIALID = B.FMATERIALID AND B.FLOCALEID = 2052
	 WHERE  A.FID IN (SELECT FBillID FROM #Order)

	UPDATE #MaterialGroup SET FNAME = '等' WHERE FSeq > 2
	DELETE FROM #MaterialGroup WHERE FSeq > 3

	SELECT  FBillID,
		STUFF((SELECT  ','+ FNAME FROM #MaterialGroup A WHERE A.FBillID = B.FBillID ORDER BY FSEQ ASC
		   FOR XML PATH('')), 1, 1, '') AS FNAME
	  INTO #DMaterialGroup
	  FROM  #MaterialGroup B
	 GROUP  BY FBillID

    UPDATE   A
       SET   A.FOrderMaterialName = B.FNAME
      FROM   #Order A
			 INNER JOIN #DMaterialGroup B
			 ON A.FBillID = B.FBillID

	DROP TABLE #MaterialGroup
	DROP TABLE #DMaterialGroup

	------------------------------------------------------------------------------------------------------------
	--销售
	------------------------------------------------------------------------------------------------------------
	INSERT INTO #Sale (FBillID,FSaleCustName,FSaleActAmount,FSaleActDate)
	SELECT  A.FID,C.FSHORTNAME,SUM(B.FALLAMOUNT),CONVERT(VARCHAR(10),A.FDATE,120)
	  FROM  T_AR_RECEIVABLE A
			INNER JOIN T_AR_RECEIVABLEENTRY B
			ON A.FID = B.FID
			INNER JOIN T_BD_CUSTOMER_L C
			ON A.FCUSTOMERID = C.FCUSTID
     WHERE  A.FDATE >= @BeginTime
	   AND  A.FDATE < @EndTime 
	   AND  A.FDOCUMENTSTATUS = 'C'
	   AND  A.FCANCELSTATUS = 'A'
	 GROUP  BY A.FID,C.FSHORTNAME,A.FDATE 

	UPDATE  A
	   SET  A.FSaleBudgetAmount = B.FSalBudgetAmount
	       ,A.FSaleBudgetDate = B.FSalBudgetDate
	  FROM  #Sale A
			INNER JOIN T_YJ_PeriodBusSal B
			ON A.FSaleCustName = B.FSalProgram
			INNER JOIN T_YJ_PeriodBus C
			ON B.FID = C.FID 
	 WHERE  C.FDOCUMENTSTATUS = 'C'
	   AND  C.FYear = @Year
	   AND  C.FMonth = @Period
	   AND  C.FBillTypeID = '654b8888f4c2b7' --预定 654b88a3f4c2d9

	SELECT  ROW_NUMBER() OVER(PARTITION BY FID ORDER BY A.FSEQ ASC)FSeq,A.FID FBillID,B.FNAME
	  INTO  #SalMaterialGroup
	  FROM  T_AR_RECEIVABLEENTRY A
			INNER JOIN T_BD_MATERIAL_L B
			ON A.FMATERIALID = B.FMATERIALID AND B.FLOCALEID = 2052
	 WHERE  A.FID IN (SELECT FBillID FROM #Sale)

	UPDATE #SalMaterialGroup SET FNAME = '等' WHERE FSeq > 2
	DELETE FROM #SalMaterialGroup WHERE FSeq > 3

	SELECT  FBillID,
		STUFF((SELECT  ','+ FNAME FROM #SalMaterialGroup A WHERE A.FBillID = B.FBillID ORDER BY FSEQ ASC
		   FOR XML PATH('')), 1, 1, '') AS FNAME
	  INTO  #DSalMaterialGroup
	  FROM  #SalMaterialGroup B
	 GROUP  BY FBillID

	UPDATE   A
       SET   A.FSaleMaterialName = B.FNAME
      FROM   #Sale A
			 INNER JOIN #DSalMaterialGroup B
			 ON A.FBillID = B.FBillID

	--获取销售订单金额
	SELECT  A.FID,SUM(C.FALLAMOUNT)FALLAMOUNT
	  INTO  #SalAmount
	  FROM  T_AR_RECEIVABLEENTRY A
			INNER JOIN T_SAL_ORDERENTRY B
			ON A.FORDERENTRYID = B.FENTRYID
			INNER JOIN T_SAL_ORDERENTRY_F C
			ON B.FENTRYID = C.FENTRYID
	 WHERE  A.FID IN (SELECT FBillID FROM #Sale)
	 GROUP  BY A.FID

	UPDATE   A
       SET   A.FOrderActAmount = B.FALLAMOUNT
      FROM   #Sale A
			 INNER JOIN #SalAmount B
			 ON A.FBillID = B.FID

	UPDATE  #Sale SET FSaleNote = CONVERT(VARCHAR(10),CAST((FSaleActAmount / FOrderActAmount * 100) AS DECIMAL(10,0))) + '%'
	WHERE FOrderActAmount <> 0
	

	DROP TABLE #SalMaterialGroup
	DROP TABLE #DSalMaterialGroup

	------------------------------------------------------------------------------------------------------------
	--返回数据
	------------------------------------------------------------------------------------------------------------
	SELECT * FROM #Order
	SELECT * FROM #Sale
END