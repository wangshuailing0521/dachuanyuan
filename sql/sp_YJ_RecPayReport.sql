--营业收入/成本明细表及毛利率分析表
--EXEC sp_YJ_RecPayReport 2023
ALTER PROC sp_YJ_RecPayReport
	@Year INT
AS
BEGIN
	CREATE TABLE #TEMP(
		FMonthName VARCHAR(255),
		FMonth INT,
		FRecSum DECIMAL(28,10) DEFAULT 0, 
		FRecPWGZJ DECIMAL(28,10) DEFAULT 0, --喷雾干燥机
		FRecBPBJ DECIMAL(28,10) DEFAULT 0, --备品备件
		FRecOther DECIMAL(28,10) DEFAULT 0, --其他

		FCostSum DECIMAL(28,10) DEFAULT 0, 
		FCostPWGZJ DECIMAL(28,10) DEFAULT 0, --喷雾干燥机
		FCostBPBJ DECIMAL(28,10) DEFAULT 0, --备品备件
		FCostOther DECIMAL(28,10) DEFAULT 0, --其他

		FRateSum DECIMAL(28,10) DEFAULT 0, 
		FRatePWGZJ DECIMAL(28,10) DEFAULT 0, --喷雾干燥机
		FRateBPBJ DECIMAL(28,10) DEFAULT 0, --备品备件
		FRateOther DECIMAL(28,10) DEFAULT 0, --其他

		FNote VARCHAR(255)
	)

	INSERT INTO #TEMP(FMonthName,FMonth) SELECT '1月份',1
	INSERT INTO #TEMP(FMonthName,FMonth) SELECT '2月份',2
	INSERT INTO #TEMP(FMonthName,FMonth) SELECT '3月份',3
	INSERT INTO #TEMP(FMonthName,FMonth) SELECT '4月份',4
	INSERT INTO #TEMP(FMonthName,FMonth) SELECT '5月份',5
	INSERT INTO #TEMP(FMonthName,FMonth) SELECT '6月份',6
	INSERT INTO #TEMP(FMonthName,FMonth) SELECT '7月份',7
	INSERT INTO #TEMP(FMonthName,FMonth) SELECT '8月份',8
	INSERT INTO #TEMP(FMonthName,FMonth) SELECT '9月份',9
	INSERT INTO #TEMP(FMonthName,FMonth) SELECT '10月份',10
	INSERT INTO #TEMP(FMonthName,FMonth) SELECT '11月份',11
	INSERT INTO #TEMP(FMonthName,FMonth) SELECT '12月份',12

	INSERT INTO #TEMP(FMonthName,FMonth) SELECT '合计',0
	INSERT INTO #TEMP(FMonthName,FMonth) SELECT '上年同期实际',0
	INSERT INTO #TEMP(FMonthName,FMonth) SELECT '今年为上年%',0

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
	 WHERE A.FLEVEL = 2
	   AND A.FNUMBER IN ('6001.01','6001.02','6001.03','6001.04','6001.05','6001.99'
	   ,'6401.01','6401.02','6401.04','6401.05','6401.06','6401.09')

	INSERT INTO #Acct
	SELECT  A.FACCtID,A.FNUMBER,A.FLEVEL,A.FPARENTID,B.FLeve12ParentID,FLeve12ParentNo,A.FNUMBER,''
	  FROM  T_BD_ACCOUNT A
			INNER JOIN #Acct B
			ON A.FPARENTID = B.FACCtID
	 WHERE  A.FLEVEL = 3

	INSERT INTO #Acct
	SELECT  A.FACCtID,A.FNUMBER,A.FLEVEL,A.FPARENTID,B.FLeve12ParentID,FLeve12ParentNo,A.FNUMBER,''
	  FROM  T_BD_ACCOUNT A
			INNER JOIN #Acct B
			ON A.FPARENTID = B.FACCtID
	 WHERE  A.FLEVEL = 4

	INSERT INTO #Acct
	SELECT  A.FACCtID,A.FNUMBER,A.FLEVEL,A.FPARENTID,B.FLeve12ParentID,FLeve12ParentNo,FLeve13ParentNo,A.FNUMBER
	  FROM  T_BD_ACCOUNT A
			INNER JOIN #Acct B
			ON A.FPARENTID = B.FACCtID
	 WHERE  A.FLEVEL = 5

	SELECT  A.FYEAR,A.FPERIOD,H.FLeve12ParentNo,SUM(A.FCREDIT)FCREDIT,SUM(A.FDEBIT)FDEBIT
	  INTO  #Balance
	  FROM  T_GL_Balance A
			INNER JOIN T_BD_ACCOUNT B
			ON B.FACCTID = A.FACCOUNTID
			INNER JOIN #Acct H
			ON A.FACCOUNTID = H.FAcctID
	 WHERE  1=1
	   AND  ((A.FYEAR >= (@Year - 1) AND @Year <> '' ) OR @Year = '')	   
	   AND  ((A.FYEAR <= @Year AND @Year <> '' ) OR @Year = '')
	   AND  A.FACCOUNTID IN (SELECT FAcctID FROM #Acct)
	   AND  A.FCURRENCYID <> 0
	   AND  A.FDETAILID = 0
	 GROUP  BY H.FLeve12ParentNo,A.FYEAR,A.FPERIOD

	DECLARE @Period INT
	SET @Period = 0
	WHILE (@Period <= 12)
	BEGIN
		SET @Period = @Period + 1

		UPDATE #TEMP SET FRecPWGZJ = (
			SELECT SUM(FCREDIT) FROM #Balance 
			 WHERE FYEAR = @Year AND FPERIOD = @Period AND FLeve12ParentNo IN ('6001.01','6001.02'))
		WHERE FMonth = @Period

		UPDATE #TEMP SET FRecBPBJ = (
			SELECT SUM(FCREDIT) FROM #Balance 
			 WHERE FYEAR = @Year AND FPERIOD = @Period AND FLeve12ParentNo IN ('6001.03'))
		WHERE FMonth = @Period

		UPDATE #TEMP SET FRecOther = (
			SELECT SUM(FCREDIT) FROM #Balance 
			 WHERE FYEAR = @Year AND FPERIOD = @Period AND FLeve12ParentNo IN ('6001.04','6001.05','6001.99'))
		WHERE FMonth = @Period

		UPDATE #TEMP SET FCostPWGZJ = (
			SELECT SUM(FDEBIT) FROM #Balance 
			 WHERE FYEAR = @Year AND FPERIOD = @Period AND FLeve12ParentNo IN ('6401.01','6401.02'))
		WHERE FMonth = @Period

		UPDATE #TEMP SET FCostBPBJ = (
			SELECT SUM(FDEBIT) FROM #Balance 
			 WHERE FYEAR = @Year AND FPERIOD = @Period AND FLeve12ParentNo IN ('6401.04'))
		WHERE FMonth = @Period

		UPDATE #TEMP SET FCostOther = (
			SELECT SUM(FDEBIT) FROM #Balance 
			 WHERE FYEAR = @Year AND FPERIOD = @Period AND FLeve12ParentNo IN ('6401.05','6401.06','6401.09'))
		WHERE FMonth = @Period		
	END

	--更新今年合计
	UPDATE #TEMP SET FRecPWGZJ = (SELECT SUM(FRecPWGZJ) FROM #TEMP) WHERE FMonthName = '合计'
	UPDATE #TEMP SET FRecBPBJ = (SELECT SUM(FRecBPBJ) FROM #TEMP) WHERE FMonthName = '合计'
	UPDATE #TEMP SET FRecOther = (SELECT SUM(FRecOther) FROM #TEMP) WHERE FMonthName = '合计'
	UPDATE #TEMP SET FCostPWGZJ = (SELECT SUM(FCostPWGZJ) FROM #TEMP) WHERE FMonthName = '合计'
	UPDATE #TEMP SET FCostBPBJ = (SELECT SUM(FCostBPBJ) FROM #TEMP) WHERE FMonthName = '合计'
	UPDATE #TEMP SET FCostOther = (SELECT SUM(FCostOther) FROM #TEMP) WHERE FMonthName = '合计'

	--获取去年数据
	UPDATE #TEMP SET FRecPWGZJ = (
		SELECT SUM(FCREDIT) FROM #Balance 
		 WHERE FYEAR = @Year - 1 AND FLeve12ParentNo IN ('6001.01','6001.02'))
	 WHERE FMonthName = '上年同期实际'

	UPDATE #TEMP SET FRecBPBJ = (
		SELECT SUM(FCREDIT) FROM #Balance 
		 WHERE FYEAR = @Year - 1 AND FLeve12ParentNo IN ('6001.03'))
	 WHERE FMonthName = '上年同期实际'

	UPDATE #TEMP SET FRecOther = (
		SELECT SUM(FCREDIT) FROM #Balance 
		 WHERE FYEAR = @Year - 1 AND FLeve12ParentNo IN ('6001.04','6001.05','6001.99'))
	 WHERE FMonthName = '上年同期实际'

	UPDATE #TEMP SET FCostPWGZJ = (
		SELECT SUM(FDEBIT) FROM #Balance 
		 WHERE FYEAR = @Year - 1 AND FLeve12ParentNo IN ('6401.01','6401.02'))
	 WHERE FMonthName = '上年同期实际'

	UPDATE #TEMP SET FCostBPBJ = (
		SELECT SUM(FDEBIT) FROM #Balance 
		 WHERE FYEAR = @Year - 1 AND FLeve12ParentNo IN ('6401.04'))
	 WHERE FMonthName = '上年同期实际'

	UPDATE #TEMP SET FCostOther = (
		SELECT SUM(FDEBIT) FROM #Balance 
		 WHERE FYEAR = @Year - 1 AND FLeve12ParentNo IN ('6401.05','6401.06','6401.09'))
	 WHERE FMonthName = '上年同期实际'

	--更新合计数据
	UPDATE #TEMP SET FRecSum = FRecPWGZJ + FRecBPBJ + FRecOther
	UPDATE #TEMP SET FCostSum = FCostPWGZJ + FCostBPBJ + FCostOther

	--更新毛利率数据
	UPDATE #TEMP SET FRateSum = ROUND((FRecSum -  FCostSum)/ FRecSum * 100,2) WHERE FRecSum <> 0
	UPDATE #TEMP SET FRatePWGZJ = ROUND((FRecPWGZJ -  FCostPWGZJ)/ FRecPWGZJ * 100,2) WHERE FRecPWGZJ <> 0
	UPDATE #TEMP SET FRateBPBJ = ROUND((FRecBPBJ -  FCostBPBJ)/ FRecBPBJ * 100,2) WHERE FRecBPBJ <> 0
	UPDATE #TEMP SET FRateOther = ROUND((FRecOther -  FCostOther)/ FRecOther * 100,2) WHERE FRecOther <> 0

	--更新今年为上年
	UPDATE #TEMP SET FRecSum = ROUND(
		(SELECT FRecSum FROM #TEMP WHERE FMonthName = '上年同期实际') /
		(SELECT FRecSum FROM #TEMP WHERE FMonthName = '合计') * 100,2)
	 WHERE FMonthName = '今年为上年%'

	UPDATE #TEMP SET FRecPWGZJ = ROUND(
		(SELECT FRecPWGZJ FROM #TEMP WHERE FMonthName = '上年同期实际') /
		(SELECT FRecPWGZJ FROM #TEMP WHERE FMonthName = '合计') * 100,2)
	 WHERE FMonthName = '今年为上年%'

	UPDATE #TEMP SET FRecBPBJ = ROUND(
		(SELECT FRecBPBJ FROM #TEMP WHERE FMonthName = '上年同期实际') /
		(SELECT FRecBPBJ FROM #TEMP WHERE FMonthName = '合计') * 100,2)
	 WHERE FMonthName = '今年为上年%'

	UPDATE #TEMP SET FRecOther = ROUND(
		(SELECT FRecOther FROM #TEMP WHERE FMonthName = '上年同期实际') /
		(SELECT FRecOther FROM #TEMP WHERE FMonthName = '合计') * 100,2)
	 WHERE FMonthName = '今年为上年%'

	UPDATE #TEMP SET FCostSum = ROUND(
		(SELECT FCostSum FROM #TEMP WHERE FMonthName = '上年同期实际') /
		(SELECT FCostSum FROM #TEMP WHERE FMonthName = '合计') * 100,2)
	 WHERE FMonthName = '今年为上年%'

	UPDATE #TEMP SET FCostPWGZJ = ROUND(
		(SELECT FCostPWGZJ FROM #TEMP WHERE FMonthName = '上年同期实际') /
		(SELECT FCostPWGZJ FROM #TEMP WHERE FMonthName = '合计') * 100,2)
	 WHERE FMonthName = '今年为上年%'

	UPDATE #TEMP SET FCostBPBJ = ROUND(
		(SELECT FCostBPBJ FROM #TEMP WHERE FMonthName = '上年同期实际') /
		(SELECT FCostBPBJ FROM #TEMP WHERE FMonthName = '合计') * 100,2)
	 WHERE FMonthName = '今年为上年%'

	UPDATE #TEMP SET FCostOther = ROUND(
		(SELECT FCostOther FROM #TEMP WHERE FMonthName = '上年同期实际') /
		(SELECT FCostOther FROM #TEMP WHERE FMonthName = '合计') * 100,2)
	 WHERE FMonthName = '今年为上年%'


	--UPDATE  A
	--   SET  A.FSaleAmount = B.FAmount
	--  FROM  #TEMP A
	--		INNER JOIN (SELECT FProgramID,SUM(FCREDIT) FAmount FROM #Balance WHERE FLeve12ParentNo = '6001' GROUP BY FProgramID) B
	--		ON A.FProgramID = B.FProgramID

	--UPDATE  A
	--   SET  A.FCost = B.FAmount
	--  FROM  #TEMP A
	--		INNER JOIN (SELECT FProgramID,SUM(FDEBIT) FAmount FROM #Balance WHERE FLeve12ParentNo = '6401' GROUP BY FProgramID) B
	--		ON A.FProgramID = B.FProgramID

	SELECT * FROM #TEMP
END