--��ʱͳ�ƻ��ܱ�
--EXEC sp_YJ_WorkTimeReport '2023','11','2023','11',567
ALTER PROC sp_YJ_WorkTimeReport
	@Year INT,
	@Period INT,
	@EndYear INT,
	@EndPeriod INT,
	@SumAmount DECIMAL(28,10)
AS
BEGIN
	DECLARE @SQL VARCHAR(2000)
	DECLARE @UserId INT
	DECLARE @UserName VARCHAR(255)
	DECLARE @SumWorkTime DECIMAL(28,10)
	CREATE TABLE #TEMP(
		FProgramID INT,
		FProgramNo VARCHAR(255),
		FProgramName VARCHAR(255)
	)

	SELECT  A.FCreatorId,B.FProgramID
	       ,SUM(B.FDay1+FDay2+FDay3+FDay4+FDay5+FDay6+FDay7+FDay8+FDay9
			   +FDay10+FDay11+FDay12+FDay13+FDay14+FDay15+FDay16+FDay17+FDay18+FDay19
			   +FDay20+FDay21+FDay22+FDay23+FDay24+FDay25+FDay26+FDay27+FDay28+FDay29
			   +FDay30+FDay31)FWorkTime
	  INTO  #WorkTime
	  FROM  T_YJ_WorkTime A
			INNER JOIN T_YJ_WorkTimeEntry B
			ON A.FID = B.FID
			INNER JOIN T_BAS_PREBDONE C
			ON B.FPROGRAMID = C.FID
	 WHERE  1=1
	   AND  ((A.FYEAR >= @Year AND @Year <> '') OR @Year = '')
	   AND  ((A.FPERIOD >= @Period AND @Period <> '') OR @Period = '')
	   AND  ((A.FYEAR <= @EndYear AND @EndYear <> '') OR @EndYear = '')
	   AND  ((A.FPERIOD <= @EndPeriod AND @EndPeriod <> '') OR @EndPeriod = '')
	   AND  A.FDOCUMENTSTATUS = 'C'
	   AND  C.F_PDLJ_GROUP = 1402326
	 GROUP  BY A.FCreatorId,FProgramID

	INSERT INTO #TEMP(FProgramID)
	SELECT  DISTINCT FProgramID
	  FROM  #WorkTime

	DECLARE MyCusror CURSOR FOR
		SELECT DISTINCT A.FCreatorId
		  FROM  #WorkTime A 
    OPEN MyCusror
    FETCH NEXT FROM MyCusror INTO @UserId
    WHILE(@@Fetch_Status = 0)
    BEGIN
		SELECT @UserName = FNAME FROM T_SEC_USER WHERE FUSERID = @UserId 

		SET @SQL = 'ALTER TABLE #TEMP ADD ['+ @UserName + '] DECIMAL(28,2) DEFAULT 0'
		EXECUTE(@SQL)

		SET @SQL = ' UPDATE A ' 
				   +'   SET [' + @UserName + '] = B.FWorkTime '
				   +'  FROM #TEMP A '
				   +'       INNER JOIN #WorkTime B'
				   +'       ON A.FProgramID = B.FProgramID'
				   +' WHERE B.FCreatorId = ' + '''' +CONVERT(VARCHAR(255),@UserId)  + ''''
		EXECUTE(@SQL)

		FETCH NEXT FROM MyCusror INTO @UserId
    END
    CLOSE MyCusror
    DEALLOCATE MyCusror

	ALTER TABLE #TEMP ADD �ϼ� DECIMAL(28,2) DEFAULT 0
	ALTER TABLE #TEMP ADD ��ʱ���� DECIMAL(28,10) DEFAULT 0
	ALTER TABLE #TEMP ADD ��ʱ���ܽ�� DECIMAL(28,2) DEFAULT 0

	UPDATE A SET A.FProgramNo = B.FNUMBER FROM #TEMP A INNER JOIN T_BAS_PREBDONE B ON A.FProgramID = B.FID

	UPDATE  A
	   SET  A.�ϼ� = B.FWorkTime
	  FROM  #TEMP A
			INNER JOIN (SELECT FProgramID,SUM(FWorkTime)FWorkTime FROM #WorkTime GROUP BY FProgramID) B
			ON A.FProgramID = B.FProgramID

    SET @SumWorkTime = ISNULL((SELECT SUM(�ϼ�) FROM #TEMP),0)
	IF(ISNULL(@SumWorkTime,0) <> 0)
	BEGIN
		UPDATE #TEMP SET ��ʱ���� = @SumAmount / @SumWorkTime WHERE ISNULL(@SumWorkTime,0) <> 0
	END
    
	UPDATE #TEMP SET ��ʱ���ܽ�� = ��ʱ���� * �ϼ� WHERE @SumWorkTime <> 0
	SELECT * FROM #TEMP
END