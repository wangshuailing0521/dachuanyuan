--开票到账及收支情况表
ALTER PROC sp_YJ_DZSZReport
	@BEGINYEAR VARCHAR(23),
	@ENDYEAR VARCHAR(23),
	@ProgramNo VARCHAR(MAX),
	@TempTable VARCHAR(255) = ''
AS
BEGIN

	CREATE TABLE #TEMP(
		FContraNo VARCHAR(255),
		FProgramID INT ,
		FProgramNo VARCHAR(255),
		FProgramName VARCHAR(255),
		FSpecification VARCHAR(255),
		FQty DECIMAL(28,10),
		FDeviceNo VARCHAR(255),--设备编号
		FYear VARCHAR(255),
		FContractAmount DECIMAL(28,10),
		FAcceptDate DATETIME,--验收日期
		FFinalACccounts DECIMAL(28,10),--决算
		FSaler VARCHAR(255),
		FArtificer VARCHAR(255),
		FLastRecAbleYear VARCHAR(255), --最后开票
		FRecAbleAmount DECIMAL(28,10) DEFAULT 0,--开票额
		FNoRecAbleAmount DECIMAL(28,10) DEFAULT 0,--未开票金额
		FRecAmount DECIMAL(28,10) DEFAULT 0,--收款额
		FNoRecAmount DECIMAL(28,10) DEFAULT 0,--未到帐金额
		FStatus VARCHAR(255),--状态
		FAbsAmount DECIMAL(28,10) DEFAULT 0,--金额
		FRecAbleRate DECIMAL(28,10),--开票比例
	)

	INSERT INTO #TEMP(
		FContraNo,FProgramID,FProgramNo,FProgramName,FSpecification,FQty,FYear,FContractAmount,FSaler,FArtificer
	)
	SELECT  A.FContraNo --合同编号
		   ,B.FID FProgramID 
	       ,A.F_PDLJ_Text1 FProgramNo --项目编号
		   ,B.FNAME FProgramName --项目名称
		   ,C.FSpecification --工程名称
		   ,A.FQty --台数
		   ,YEAR(FDATE) FYear --项目年份
		   ,A.Fcontractvalue FContractAmount --合同金额
		   ,D.FNAME FSaler --营业担当
		   ,G.FNAME FArtificer --技术担当
	  FROM  PDLJ_t_Cust130007 A --工程决定通知书
			LEFT JOIN T_BAS_PREBDONE_L B
			ON A.FENGINEENO = B.FID
			LEFT JOIN T_BAS_PREBDONE H
			ON A.FENGINEENO = H.FID
			LEFT JOIN T_BD_MATERIAL_L C
			ON A.F_PDLJ_Base = C.FMATERIALID
			LEFT JOIN V_BD_SALESMAN_L D
			ON A.F_QAPZ_Base1 = D.FID
			LEFT JOIN PDLJ_t_taskPlan_LK E --任务计划书
			ON E.FSBillId = A.FID
			LEFT JOIN PDLJ_t_taskPlan F --任务计划书
			ON E.FID = F.FID
			LEFT JOIN T_HR_EMPINFO_L G
			ON F.FBusinessManager1 = G.FID
	 WHERE  ((@BEGINYEAR <> '' AND YEAR(FDATE) >= CONVERT(INT,@BEGINYEAR) )OR @BEGINYEAR = '')
	   AND  ((@ENDYEAR <> '' AND YEAR(FDATE) <= CONVERT(INT,@ENDYEAR) )OR @ENDYEAR = '')
	   AND  ((@ProgramNo <> '' AND (A.F_PDLJ_Text1 IN (SELECT value FROM sp_split(@ProgramNo,','))) )OR @ProgramNo = '')
	   --AND  ((@ProgramNo <> '' AND (A.F_PDLJ_Text1 = @ProgramNo) )OR @ProgramNo = '')

	SELECT  B.FPRESETBASE1 FProgramID 
		   ,YEAR(A.FDATE) FRecAbleYear
		   ,SUM(B.FALLAMOUNTFOR) FAmount
	  INTO  #RecAble
	  FROM  T_AR_RECEIVABLE A
			INNER JOIN T_AR_RECEIVABLEENTRY B
			ON A.FID = B.FID
	 WHERE  A.FDOCUMENTSTATUS = 'C'
	   AND  A.FCANCELSTATUS = 'A'
	   AND  B.FPRESETBASE1 IN (SELECT FProgramID FROM #TEMP)
	 GROUP  BY B.FPRESETBASE1,YEAR(A.FDATE)

    SELECT  B.F_PDLJ_Base FProgramID 
		   ,SUM(B.FREALRECAMOUNTFOR-FRELATEREFUNDAMOUNT) FAmount
	  INTO  #RecBill
	  FROM  T_AR_RECEIVEBILL A
			INNER JOIN T_AR_RECEIVEBILLENTRY B
			ON A.FID = B.FID
			INNER JOIN T_AR_RECEIVEBILLENTRY_O C
			ON B.FENTRYID = C.FENTRYID
	 WHERE  A.FDOCUMENTSTATUS = 'C'
	   AND  A.FCANCELSTATUS = 'A'
	   AND  B.F_PDLJ_Base IN (SELECT FProgramID FROM #TEMP)
	 GROUP  BY B.F_PDLJ_Base

	

	UPDATE  A
	   SET  A.FRecAbleAmount = B.FAmount
	  FROM  #TEMP A
			INNER JOIN (SELECT FProgramID,SUM(FAmount)FAmount FROM #RecAble GROUP BY FProgramID) B
			ON A.FProgramID = B.FProgramID

	UPDATE  A
	   SET  A.FRecAmount = B.FAmount
	  FROM  #TEMP A
			INNER JOIN #RecBill B
			ON A.FProgramID = B.FProgramID

	UPDATE #TEMP SET FNoRecAbleAmount = ISNULL(FContractAmount,0) - ISNULL(FRecAbleAmount,0)
	UPDATE #TEMP SET FNoRecAmount = ISNULL(FContractAmount,0) - ISNULL(FRecAmount,0)
	UPDATE #TEMP SET FStatus = '预收' WHERE ISNULL(FRecAbleAmount,0) < ISNULL(FRecAmount,0)
	UPDATE #TEMP SET FStatus = '应收' WHERE ISNULL(FRecAbleAmount,0) > ISNULL(FRecAmount,0)
	UPDATE #TEMP SET FStatus = '平' WHERE ISNULL(FRecAbleAmount,0) = ISNULL(FRecAmount,0)
	UPDATE #TEMP SET FAbsAmount = ABS( ISNULL(FRecAbleAmount,0) - ISNULL(FRecAmount,0) )
	UPDATE #TEMP SET FRecAbleRate = ISNULL(FRecAbleAmount,0) / ISNULL(FContractAmount,0) * 100 WHERE ISNULL(FContractAmount,0) <> 0

	UPDATE  A
	   SET  A.FLastRecAbleYear = B.FYear
	  FROM  #TEMP A
			INNER JOIN (SELECT FProgramID,MAX(FRecAbleYear)FYear FROM #RecAble GROUP BY FProgramID) B
			ON A.FProgramID = B.FProgramID
	 WHERE  ISNULL(A.FNoRecAbleAmount,0) = 0

	SELECT * FROM #TEMP

	IF(@TempTable <> '')
	BEGIN
		DECLARE @SQL VARCHAR(2000)
		SET @SQL = '
		SELECT ROW_NUMBER() OVER(ORDER BY FProgramNo ASC) FIDENTITYID,* 
		  INTO '+@TempTable+'
		  FROM #TEMP'

		EXECUTE(@SQL)
	END
END

