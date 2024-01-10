--销售一览表
--EXEC sp_YJ_SaleInfoReport 'ASDAD','','',2022,1,2023,11
ALTER PROC sp_YJ_SaleInfoReport
	@ProgramNo VARCHAR(MAX),
	@Specification VARCHAR(MAX),
	@BeginYear INT,
	@BeginPeriod INT,
	@EndYear INT,
	@EndPeriod INT,
	@TempTable VARCHAR(255) = ''
AS
BEGIN
	CREATE TABLE #TEMP(
	    FSeq INT,
		FProgramID INT,
		FProgramName VARCHAR(255),
		FProgramGroupSeq INT,
		FProgramGroup VARCHAR(255),
		FYear VARCHAR(255),
		FCustID INT,
		FCustName VARCHAR(255),
		FCustShortName VARCHAR(255),
		FMaterialName VARCHAR(255),
		FSpecification VARCHAR(255),
		FSaleAmount DECIMAL(28,10) DEFAULT 0, --销售订单不含税金额
		FRecAbleAmount DECIMAL(28,10) DEFAULT 0,--财务应收不含税金额
		FKPAmount DECIMAL(28,10) DEFAULT 0, --开票金额
		FRate DECIMAL(28,10) DEFAULT 0,
		FCost DECIMAL(28,10) DEFAULT 0,
		FProfit DECIMAL(28,10) DEFAULT 0, --毛利

		FYSTime VARCHAR(255)
	)

	IF(@BeginYear = '')
	BEGIN
		SET @BeginYear = 2010
	END
	IF(@BeginPeriod = '')
	BEGIN
		SET @BeginPeriod = 1
	END
	IF(@EndYear = '')
	BEGIN
		SET @EndYear = 2030
	END
	IF(@EndPeriod = '')
	BEGIN
		SET @EndPeriod = 12
	END

	DECLARE @BeginYearPeriod INT
	DECLARE @EndYearPeriod INT
	DECLARE @BeginTime VARCHAR(255)
	DECLARE @EndTime VARCHAR(255)
	SET @BeginYearPeriod = @BeginYear * 100 + @BeginPeriod
	SET @EndYearPeriod = @EndYear * 100 + @EndPeriod

	SET @BeginTime = CONVERT(VARCHAR(4),@BeginYear) + '-' + CONVERT(VARCHAR(2),@BeginPeriod) + '-01'
	IF(@BeginPeriod < 10)
	BEGIN
		SET @BeginTime = CONVERT(VARCHAR(4),@BeginYear) + '-0' + CONVERT(VARCHAR(1),@BeginPeriod) + '-01'
	END

	SET @EndTime = CONVERT(VARCHAR(4),@EndYear) + '-' + CONVERT(VARCHAR(2),@EndPeriod) + '-01'
	IF(@EndPeriod < 10)
	BEGIN
		SET @EndTime = CONVERT(VARCHAR(4),@EndYear) + '-0' + CONVERT(VARCHAR(1),@EndPeriod) + '-01'
	END
	SET @EndTime = CONVERT(VARCHAR(10),DATEADD(MONTH,1,@EndTime),120)

	INSERT INTO #TEMP(FSeq,FCustID,FProgramID,FProgramGroup,FYear,FMaterialName,FSpecification,FRecAbleAmount,FProgramName,FCustName,FCustShortName)
	SELECT ROW_NUMBER() OVER(PARTITION BY B.F_PDLJ_Base2 ORDER BY A.FCustId), 
		   A.FCustId,B.F_PDLJ_Base2,G.FNAME
		  ,CASE WHEN G.FNAME = '设备' THEN YEAR(H.FDATE) ELSE YEAR(T.FDATE) END
		  ,C.FNAME,C.FSPECIFICATION,SUM(D.FALLAMOUNT),E.FNUMBER,F.FNAME,F.FSHORTNAME
	  FROM T_SAL_ORDER A
			INNER JOIN T_SAL_ORDERENTRY B
			ON A.FID = B.FID
			INNER JOIN T_BD_MATERIAL_L C
			ON B.FMATERIALID = C.FMATERIALID AND C.FLOCALEID = 2052
			INNER JOIN T_SAL_ORDERENTRY_F D
			ON B.FENTRYID = D.FENTRYID
			LEFT JOIN T_BAS_PREBDONE E
			ON B.F_PDLJ_Base2 = E.FID 
			LEFT JOIN T_BD_CUSTOMER_L F
			ON A.FCUSTID = F.FCUSTID AND F.FLOCALEID = 2052
			LEFT JOIN T_Project_L G
			ON E.F_PDLJ_Group = G.FID AND G.FLocaleID = 2052
			LEFT JOIN (SELECT FENGINEENO,MAX(FDATE)FDATE FROM PDLJ_t_Cust130007 GROUP BY FENGINEENO)H
			ON B.F_PDLJ_Base2 = H.FENGINEENO
			LEFT JOIN (SELECT F_PDLJ_BASE2,MAX(A.FDATE)FDATE FROM T_SAL_ORDER A INNER JOIN T_SAL_ORDERENTRY B ON A.FID = B.FID GROUP BY B.F_PDLJ_BASE2)T
			ON B.F_PDLJ_BASE2 = T.F_PDLJ_BASE2
	 WHERE  A.FDOCUMENTSTATUS = 'C'
	   AND  A.FCANCELSTATUS = 'A'
	   AND  ((@ProgramNo <> '' AND (E.FNUMBER IN (SELECT value FROM sp_split(@ProgramNo,','))) )OR @ProgramNo = '')
	   AND  ((@Specification <> '' AND (C.FSPECIFICATION LIKE '%'+@Specification+'%' ) )OR @Specification = '')
 	 GROUP BY A.FCustId,B.F_PDLJ_Base2,C.FNAME,C.FSPECIFICATION,E.FNUMBER,F.FNAME,G.FNAME,H.FDATE,F.FSHORTNAME,T.FDATE

	--SELECT  A.FCUSTOMERID,B.FPRESETBASE1,C.FSPECIFICATION,SUM(B.FNOTAXAMOUNTFOR)FAmount
	--  INTO  #RecAbleAmount
	--  FROM  T_AR_RECEIVABLE A
	--		INNER JOIN T_AR_RECEIVABLEENTRY B
	--		ON A.FID = B.FID
	--		INNER JOIN T_BD_MATERIAL_L C
	--		ON B.FMATERIALID = C.FMATERIALID AND C.FLOCALEID = 2052
	-- WHERE  A.FSetAccountType = '3' --财务应收
	--   AND  B.FPRESETBASE1 IN (SELECT FProgramID FROM #TEMP)
	--   AND  C.FSPECIFICATION IN (SELECT FSpecification FROM #TEMP)
	--   AND  ((A.FDATE >= @BeginTime AND @BeginTime <> '')OR @BeginTime = '')
	--   AND  ((A.FDATE < @EndTime AND @EndTime <> '')OR @EndTime = '')
	-- GROUP BY A.FCUSTOMERID,B.FPRESETBASE1,C.FSPECIFICATION

 --   UPDATE  A 
	--   SET  A.FRecAbleAmount = B.FAmount
	--  FROM  #TEMP A
	--	    INNER JOIN #RecAbleAmount B
	--	    ON A.FCustID = B.FCUSTOMERID AND A.FProgramID = B.FPRESETBASE1 AND A.FSpecification = B.FSPECIFICATION

	--根据项目，客户，合并展示物料
	UPDATE #TEMP SET FProgramGroupSeq = 1 WHERE FProgramGroup IN ('设备')
	UPDATE #TEMP SET FProgramGroupSeq = 2 WHERE FProgramGroup IN ('改造')
	UPDATE #TEMP SET FProgramGroupSeq = 3 WHERE FProgramGroup IN ('备品备件')
	UPDATE #TEMP SET FProgramGroupSeq = 4 WHERE FProgramGroup IN ('服务/维修')
	UPDATE #TEMP SET FProgramGroupSeq = 5 WHERE FProgramGroup IN ('试验')
	
	UPDATE #TEMP SET FSpecification = FMaterialName WHERE FProgramGroup NOT IN ('设备','试验')
	

	SELECT ROW_NUMBER() OVER(PARTITION BY FProgramID ORDER BY FSpecification)FSeq,FProgramID,FSpecification INTO #MaterialGroup FROM #TEMP GROUP BY FProgramID,FSpecification
	SELECT FProgramID,SUM(FRecAbleAmount)FRecAbleAmount INTO #RecAbleGroup FROM #TEMP GROUP BY FProgramID
	UPDATE #MaterialGroup SET FSpecification = '等' WHERE FSeq > 2
	DELETE FROM #MaterialGroup WHERE FSeq > 3

	SELECT  FProgramID,
		STUFF((SELECT  ','+ FSpecification FROM #MaterialGroup A WHERE A.FProgramID = B.FProgramID ORDER BY FSEQ ASC
		   FOR XML PATH('')), 1, 1, '') AS FSpecification
	  INTO #DMaterialGroup
	  FROM  #MaterialGroup B
	 GROUP  BY FProgramID

   UPDATE   A
      SET   A.FSpecification = B.FSpecification
     FROM   #TEMP A
			INNER JOIN #DMaterialGroup B
			ON A.FProgramID = B.FProgramID

   UPDATE   A
      SET   A.FRecAbleAmount = B.FRecAbleAmount
     FROM   #TEMP A
			INNER JOIN #RecAbleGroup B
			ON A.FProgramID = B.FProgramID
	
	DELETE FROM #TEMP WHERE FSeq > 1

	UPDATE  A
	   SET  A.FYSTime = CONVERT(VARCHAR(10), B.F_SHDP_Date10,120)
	  FROM  #TEMP A
			INNER JOIN SHDP_t_Cust_Entry100033 B
			ON A.FProgramID = B.FengineeNo

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
	   AND A.FNUMBER IN ('6001','6401')

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

	SELECT  C.FF100003 FProgramID,H.FLeve12ParentNo,SUM(A.FCREDIT)FCREDIT,SUM(A.FDEBIT)FDEBIT
	  INTO  #Balance
	  FROM  T_GL_Balance A
			INNER JOIN T_BD_ACCOUNT B
			ON B.FACCTID = A.FACCOUNTID
			INNER JOIN T_BD_FLEXITEMDETAILV C
			ON A.FDETAILID = C.FID
			INNER JOIN T_BAS_PREBDONE D
			ON C.FF100003 = D.FID
			INNER JOIN T_BAS_PREBDONE_L E
			ON C.FF100003 = E.FID AND E.FLocaleID = 2052
			LEFT JOIN T_Project F
			ON D.F_PDLJ_Group = F.FID 
			LEFT JOIN T_Project_L G
			ON D.F_PDLJ_Group = G.FID AND G.FLocaleID = 2052
			INNER JOIN #Acct H
			ON A.FACCOUNTID = H.FAcctID
	 WHERE  1=1
	   AND  ((A.FYEARPERIOD >= @BeginYearPeriod AND @BeginYearPeriod <> '' ) OR @BeginYearPeriod = '')	   
	   AND  ((A.FYEARPERIOD <= @EndYearPeriod AND @EndYearPeriod <> '' ) OR @EndYearPeriod = '')
	   AND  C.FF100003 IN (SELECT FProgramID FROM #TEMP)
	   AND  A.FACCOUNTID IN (SELECT FAcctID FROM #Acct)
	   AND  A.FCURRENCYID <> 0
	 GROUP  BY C.FF100003,H.FLeve12ParentNo

	UPDATE  A
	   SET  A.FSaleAmount = B.FAmount
	  FROM  #TEMP A
			INNER JOIN (SELECT FProgramID,SUM(FCREDIT) FAmount FROM #Balance WHERE FLeve12ParentNo = '6001' GROUP BY FProgramID) B
			ON A.FProgramID = B.FProgramID

	UPDATE  A
	   SET  A.FCost = B.FAmount
	  FROM  #TEMP A
			INNER JOIN (SELECT FProgramID,SUM(FDEBIT) FAmount FROM #Balance WHERE FLeve12ParentNo = '6401' GROUP BY FProgramID) B
			ON A.FProgramID = B.FProgramID

	

	----------------------------------------------------------------------------------------------------------------
	--获取应收单
	----------------------------------------------------------------------------------------------------------------
	SELECT  B.FPRESETBASE1 FProgramID,SUM(B.FALLAMOUNTFOR) FALLAMOUNTFOR,SUM(B.FNOTAXAMOUNTFOR)FNOTAXAMOUNTFOR
	  INTO  #AbleTable
	  FROM  T_AR_RECEIVABLE A
			INNER JOIN T_AR_RECEIVABLEENTRY B
			ON A.FID = B.FID
			INNER JOIN #TEMP C
			ON B.FPRESETBASE1 = C.FProgramID
     WHERE  A.FDOCUMENTSTATUS = 'C'
	   AND  A.FSetAccountType = '3' --财务应收
	 GROUP BY B.FPRESETBASE1

	UPDATE A SET A.FKPAmount = B.FALLAMOUNTFOR FROM #TEMP A INNER JOIN #AbleTable B ON A.FProgramID = B.FProgramID

	--特殊处理
	--S23JS789OA-1
	UPDATE  A
	   SET  A.FSaleAmount = B.FSaleAmount + A.FSaleAmount
	       ,A.FKPAmount = B.FKPAmount + B.FKPAmount
		   ,A.FRecAbleAmount = B.FRecAbleAmount + B.FRecAbleAmount 
		   ,A.FCost = B.FCost + B.FCost
	  FROM  #TEMP A
			INNER JOIN (SELECT * FROM #TEMP WHERE FProgramID = 2642088) B --S23JS789OA-2
			ON 1=1
	 WHERE  A.FProgramID = 2642087 --S23JS789OA-1
	DELETE FROM #TEMP WHERE FProgramID = 2642088--S23JS789OA-2
	UPDATE #TEMP SET FKPAmount = FKPAmount / 2 WHERE FProgramID = 2675042 --X23-001
	   
	  -- SELECT * FROM T_BAS_PREBDONE WHERE FNUMBER = 'X23-001'


	UPDATE #TEMP SET FProfit = FSaleAmount - FCost

	UPDATE #TEMP SET FRate = FKPAmount / FRecAbleAmount * 100 WHERE FRecAbleAmount <> 0

	DELETE FROM #TEMP WHERE FRecAbleAmount = 0 AND FCost = 0

	SELECT ROW_NUMBER() OVER(ORDER BY FProgramGroupSeq,FProgramName,FCustName ASC) FIDENTITYID,* 
		  FROM #TEMP 
		WHERE FSaleAmount <> 0 OR FCost <> 0 
		ORDER BY FProgramGroupSeq ASC, FProgramName ASC,FCustName ASC

	IF(@TempTable <> '')
	BEGIN
		DECLARE @SQL VARCHAR(2000)

		SET @SQL = '
		SELECT ROW_NUMBER() OVER(ORDER BY FProgramGroupSeq,FProgramName,FCustName ASC) FIDENTITYID,* 
		  INTO '+@TempTable+'
		  FROM #TEMP 
		WHERE FSaleAmount <> 0 OR FCost <> 0 
		ORDER BY FProgramGroupSeq ASC, FProgramName ASC,FCustName ASC'

		EXECUTE(@SQL)
	END
	
END