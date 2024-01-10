--营业收款月报
ALTER PROC sp_YJ_BusinessRecReport
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

	CREATE TABLE #Budget(
		FBudgetProgramID INT,
		FBudgetProgramName VARCHAR(255),
		FBudgetNote VARCHAR(255),
		FBudgetAmount DECIMAL(28,10),
		FBudgetPayType VARCHAR(255),
	)
	CREATE TABLE #Act(
		FRecBillID INT,
		FSALBillID INT,
		FActProgramID INT,
		FActProgramName VARCHAR(255),
		FActNote VARCHAR(255),
		FActAmount DECIMAL(28,10),
		FActOrderAmount DECIMAL(28,10)
	)

	INSERT INTO #Budget(
		FBudgetProgramName,FBudgetNote,FBudgetAmount,FBudgetPayType)
	SELECT  FBudgetProgram,FBudgetNote,FBudgetAmount,FBudgetPayType
	  FROM  T_YJ_RecMonth A
			INNER JOIN T_YJ_RecMonthBudget B
			ON A.FID = B.FID
	 WHERE  A.FDOCUMENTSTATUS = 'C'
	   AND  A.FYEAR = @Year
	   AND  A.FMONTH = @Period
	   AND  A.FBILLTYPEID = '654b88a3f4c2d9'--预定

	INSERT INTO #Act(FRecBillID,FSALBillID,FActProgramID,FActProgramName,FActAmount,FActOrderAmount)
	SELECT  A.FID,D.FID,B.F_PDLJ_Base FProgramID,C.FNAME,SUM(B.FRECAMOUNTFOR_E),SUM(D.FALLAMOUNT)
	  FROM  T_AR_RECEIVEBILL A
			INNER JOIN T_AR_RECEIVEBILLENTRY B
			ON A.FID = B.FID
			INNER JOIN T_BAS_PREBDONE_L C
			ON B.F_PDLJ_Base = C.FID AND C.FLocaleID = 2052
			INNER JOIN (SELECT  A.FID,A.F_PDLJ_Base2,SUM(B.FALLAMOUNT)FALLAMOUNT
						  FROM  T_SAL_ORDERENTRY A 
								INNER JOIN T_SAL_ORDERENTRY_F B 
								ON A.FENTRYID = B.FENTRYID
						 GROUP  BY A.FID,A.F_PDLJ_Base2
						 )D
			ON B.FSALEORDERID = D.FID AND B.F_PDLJ_BASE = D.F_PDLJ_BASE2
	 WHERE  A.FDOCUMENTSTATUS = 'C'
	   AND  A.FDATE >= @BeginTime 
	   AND  A.FDATE < @EndTime
	 GROUP  BY A.FID,D.FID,B.F_PDLJ_BASE,C.FNAME
	
	--判断收款 预付款，中间款，尾款
	SELECT  B.FSALEORDERID FSALBillID,A.FID FRecBillID,B.F_PDLJ_Base FProgramID,SUM(B.FRECAMOUNTFOR_E)FRECAMOUNTFOR_E
	  INTO  #ProgramBillGroup
	  FROM  T_AR_RECEIVEBILL A
			INNER JOIN T_AR_RECEIVEBILLENTRY B
			ON A.FID = B.FID
	 WHERE  A.FDOCUMENTSTATUS = 'C'
	   AND  B.F_PDLJ_BASE IN (SELECT FActProgramID FROM #Act)
	   AND  A.FDATE < @EndTime
	 GROUP  BY B.FSALEORDERID,A.FID,B.F_PDLJ_Base

	SELECT  A.FSALBillID,A.FProgramID,MIN(A.FRecBillID)FRecBillID
	  INTO  #MINRecBill
	  FROM  #ProgramBillGroup A
	 GROUP  BY A.FSALBillID,A.FProgramID 

	SELECT  FSALBillID,FProgramID,SUM(FRECAMOUNTFOR_E)FRECAMOUNTFOR_E
	  INTO  #ProgramSumAmount
	  FROM  #ProgramBillGroup
	 GROUP  BY FSALBillID,FProgramID

    SELECT  A.FSALBillID,A.FProgramID,A.FRecBillID,ROW_NUMBER() OVER(PARTITION BY FProgramID,FSALBillID ORDER BY A.FRecBillID ASC)FSeq
	  INTO  #ProgramBillSeq
	  FROM  #ProgramBillGroup A

	UPDATE #Act SET FActNote = '中间款'
	UPDATE  A
	   SET  A.FActNote = '预付款'
	  FROM  #Act A
			INNER JOIN #MINRecBill B
		    ON A.FRecBillID = B.FRecBillID AND A.FActProgramID = B.FProgramID


	SELECT  A.FSALBillID,A.FActProgramID ,MAX(A.FRecBillID)FRecBillID
	  INTO  #MAXRecBill
	  FROM  #Act A
			INNER JOIN #ProgramSumAmount B
			ON A.FSALBillID = B.FSALBillID AND A.FActProgramID = B.FProgramID AND A.FActOrderAmount <= B.FRECAMOUNTFOR_E
	 GROUP  BY A.FSALBillID,A.FActProgramID 

	UPDATE  A
	   SET  A.FActNote = '尾款'
	  FROM  #Act A
			INNER JOIN #MAXRecBill B
		    ON A.FRecBillID = B.FRecBillID AND A.FActProgramID = B.FActProgramID
	
	SELECT * FROM #Budget
	SELECT  * FROM  #Act
END