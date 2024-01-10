ALTER PROC sp_YJ_OKCost
	@BeginYear INT,
	@BeginPeriod INT,
	@EndYear INT,
	@EndPeriod INT
AS
BEGIN
	CREATE TABLE #TEMP(
		FName VARCHAR(255),
		FAmount DECIMAL(28,10) DEFAULT 0,
		FNote VARCHAR(255),
		FType INT)

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

	INSERT INTO #TEMP(FName,FType) SELECT '期初原材料余额',1
	INSERT INTO #TEMP(FName,FType) SELECT '      加：本期购货净额',1
	INSERT INTO #TEMP(FName,FType) SELECT '      减：期末原材料余额',1
	INSERT INTO #TEMP(FName,FType) SELECT '      减：其他原材料发出额',1
	INSERT INTO #TEMP(FName,FType) SELECT '直接材料成本',1
	INSERT INTO #TEMP(FName,FType) SELECT '      加：直接人工成本',2
	INSERT INTO #TEMP(FName,FType) SELECT '      加：制造费用',2
	INSERT INTO #TEMP(FName,FType) SELECT '      加：加工费',2
	INSERT INTO #TEMP(FName,FType) SELECT '      加：外包',2
	INSERT INTO #TEMP(FName,FType) SELECT '      加：运输包装费',2
	INSERT INTO #TEMP(FName,FType) SELECT '产品生产成本',2
	INSERT INTO #TEMP(FName,FType) SELECT '      加：在产品期初余额',3
	INSERT INTO #TEMP(FName,FType) SELECT '      减：在产品期末余额',3
	INSERT INTO #TEMP(FName,FType) SELECT '      减：其他在产品发出额',3
	INSERT INTO #TEMP(FName,FType) SELECT '产成品成本',3
	INSERT INTO #TEMP(FName,FType) SELECT '      加：产成品期初余额',4
	INSERT INTO #TEMP(FName,FType) SELECT '      减：产成品期末余额',4
	INSERT INTO #TEMP(FName,FType) SELECT '      减：其他产成品发出额',4
	INSERT INTO #TEMP(FName,FType) SELECT '主营业务成本',4

	--期初原材料余额
	UPDATE  #TEMP 
	   SET  FAmount = ISNULL(
					(SELECT SUM(FBEGINBALANCEFOR)
					  FROM  T_GL_Balance A
							INNER JOIN T_BD_ACCOUNT B
							ON B.FACCTID = A.FACCOUNTID
					 WHERE  1=1
					   AND  ((A.FYEAR = @BeginYear AND @BeginYear <> '' ) OR @BeginYear = '')
					   AND  ((A.FPERIOD = @BeginPeriod AND @BeginPeriod <> '' ) OR @BeginPeriod = '')
					   AND  B.FNUMBER IN ('1403')
					   AND  A.FDETAILID = 0
					   AND  A.FCURRENCYID <> 0),0)
	  FROM  #TEMP A 
	 WHERE  FName = '期初原材料余额'

	--      加：本期购货净额
	UPDATE  #TEMP 
	   SET  FAmount = ISNULL(
					(SELECT SUM(FDEBIT)
					  FROM  T_GL_Balance A
							INNER JOIN T_BD_ACCOUNT B
							ON B.FACCTID = A.FACCOUNTID
					 WHERE  1=1
					   AND  ((A.FYEARPERIOD >= @BeginYearPeriod AND @BeginYearPeriod <> '' ) OR @BeginYearPeriod = '')	   
					   AND  ((A.FYEARPERIOD <= @EndYearPeriod AND @EndYearPeriod <> '' ) OR @EndYearPeriod = '')
					   AND  B.FNUMBER IN ('1403','5001.01.02','5001.02.01','5001.02.03','5001.02.04','5001.02.05','5001.02.06'
									     ,'5001.04.01','5001.05.01','5001.05.03')
					   AND  A.FDETAILID = 0
					   AND  A.FCURRENCYID <> 0),0)
	  FROM  #TEMP A 
	 WHERE  FName = '      加：本期购货净额'

	--      减：期末原材料余额
	UPDATE  #TEMP 
	   SET  FAmount = 0 - ISNULL(
					(SELECT SUM(FENDBALANCEFOR)
					  FROM  T_GL_Balance A
							INNER JOIN T_BD_ACCOUNT B
							ON B.FACCTID = A.FACCOUNTID
					 WHERE  1=1
					   AND  ((A.FYEAR = @EndYear AND @EndYear <> '' ) OR @EndYear = '')
					   AND  ((A.FPERIOD = @EndPeriod AND @EndPeriod <> '' ) OR @EndPeriod = '')
					   AND  B.FNUMBER IN ('1403')
					   AND  A.FDETAILID = 0
					   AND  A.FCURRENCYID <> 0),0)
	  FROM  #TEMP A 
	 WHERE  FName = '      减：期末原材料余额'

	--      减：其他原材料发出额
	UPDATE  #TEMP 
	   SET  FAmount = 0 - ISNULL(
					(SELECT SUM(FCREDIT)
					  FROM  T_GL_Balance A
							INNER JOIN T_BD_ACCOUNT B
							ON B.FACCTID = A.FACCOUNTID
					 WHERE  1=1
					   AND  ((A.FYEARPERIOD >= @BeginYearPeriod AND @BeginYearPeriod <> '' ) OR @BeginYearPeriod = '')	   
					   AND  ((A.FYEARPERIOD <= @EndYearPeriod AND @EndYearPeriod <> '' ) OR @EndYearPeriod = '')
					   AND  B.FNUMBER IN ('6601.11.16')
					   AND  A.FDETAILID = 0
					   AND  A.FCURRENCYID <> 0),0)
	  FROM  #TEMP A 
	 WHERE  FName = '      减：其他原材料发出额'

	--直接材料成本
	UPDATE #TEMP SET FAmount = ISNULL((SELECT SUM(FAmount) FROM #TEMP WHERE FType = 1),0) WHERE FName = '直接材料成本'
	--      加：直接人工成本
	UPDATE  #TEMP 
	   SET  FAmount = ISNULL(
					(SELECT SUM(FDEBIT)
					  FROM  T_GL_Balance A
							INNER JOIN T_BD_ACCOUNT B
							ON B.FACCTID = A.FACCOUNTID
					 WHERE  1=1
					   AND  ((A.FYEARPERIOD >= @BeginYearPeriod AND @BeginYearPeriod <> '' ) OR @BeginYearPeriod = '')	   
					   AND  ((A.FYEARPERIOD <= @EndYearPeriod AND @EndYearPeriod <> '' ) OR @EndYearPeriod = '')
					   AND  B.FNUMBER IN ('5001.01','5001.02','5001.03','5001.04','5001.05')
					   AND  A.FDETAILID = 0
					   AND  A.FCURRENCYID <> 0),0)
	  FROM  #TEMP A 
	 WHERE  FName = '      加：直接人工成本'

	--      加：制造费用
	UPDATE  #TEMP 
	   SET  FAmount = ISNULL(
					(SELECT SUM(FDEBIT)
					  FROM  T_GL_Balance A
							INNER JOIN T_BD_ACCOUNT B
							ON B.FACCTID = A.FACCOUNTID
					 WHERE  1=1
					   AND  ((A.FYEARPERIOD >= @BeginYearPeriod AND @BeginYearPeriod <> '' ) OR @BeginYearPeriod = '')	   
					   AND  ((A.FYEARPERIOD <= @EndYearPeriod AND @EndYearPeriod <> '' ) OR @EndYearPeriod = '')
					   AND  B.FNUMBER IN ('5101.06','5101.07','5101.08','5101.09','5101.10','5101.11'
										 )
					   AND  A.FDETAILID = 0
					   AND  A.FCURRENCYID <> 0),0)
	  FROM  #TEMP A 
	 WHERE  FName = '      加：制造费用'

	--      加：加工费
	UPDATE  #TEMP 
	   SET  FAmount = ISNULL(
					(SELECT SUM(FDEBIT)
					  FROM  T_GL_Balance A
							INNER JOIN T_BD_ACCOUNT B
							ON B.FACCTID = A.FACCOUNTID
					 WHERE  1=1
					   AND  ((A.FYEARPERIOD >= @BeginYearPeriod AND @BeginYearPeriod <> '' ) OR @BeginYearPeriod = '')	   
					   AND  ((A.FYEARPERIOD <= @EndYearPeriod AND @EndYearPeriod <> '' ) OR @EndYearPeriod = '')
					   AND  B.FNUMBER IN ('5001.01.01','5001.01.03','5001.04.03','5001.05.05','5001.05.06')
					   AND  A.FDETAILID = 0
					   AND  A.FCURRENCYID <> 0),0)
	  FROM  #TEMP A 
	 WHERE  FName = '      加：加工费'

	--      加：外包
	UPDATE  #TEMP 
	   SET  FAmount = ISNULL(
					(SELECT SUM(FDEBIT)
					  FROM  T_GL_Balance A
							INNER JOIN T_BD_ACCOUNT B
							ON B.FACCTID = A.FACCOUNTID
					 WHERE  1=1
					   AND  ((A.FYEARPERIOD >= @BeginYearPeriod AND @BeginYearPeriod <> '' ) OR @BeginYearPeriod = '')	   
					   AND  ((A.FYEARPERIOD <= @EndYearPeriod AND @EndYearPeriod <> '' ) OR @EndYearPeriod = '')
					   AND  B.FNUMBER IN ('5001.01.04')
					   AND  A.FDETAILID = 0
					   AND  A.FCURRENCYID <> 0),0)
	  FROM  #TEMP A 
	 WHERE  FName = '      加：外包'

	--      加：运输包装费
	UPDATE  #TEMP 
	   SET  FAmount = ISNULL(
					(SELECT SUM(FDEBIT)
					  FROM  T_GL_Balance A
							INNER JOIN T_BD_ACCOUNT B
							ON B.FACCTID = A.FACCOUNTID
					 WHERE  1=1
					   AND  ((A.FYEARPERIOD >= @BeginYearPeriod AND @BeginYearPeriod <> '' ) OR @BeginYearPeriod = '')	   
					   AND  ((A.FYEARPERIOD <= @EndYearPeriod AND @EndYearPeriod <> '' ) OR @EndYearPeriod = '')
					   AND  B.FNUMBER IN ('5001.06')
					   AND  A.FDETAILID = 0
					   AND  A.FCURRENCYID <> 0),0)
	  FROM  #TEMP A 
	 WHERE  FName = '      加：运输包装费'

	--产品生产成本
	UPDATE #TEMP SET FAmount = ISNULL((SELECT SUM(FAmount) FROM #TEMP WHERE FType = 2),0) WHERE FName = '产品生产成本'

	--      加：在产品期初余额
	UPDATE  #TEMP 
	   SET  FAmount = ISNULL(
					(SELECT SUM(FBEGINBALANCEFOR)
					  FROM  T_GL_Balance A
							INNER JOIN T_BD_ACCOUNT B
							ON B.FACCTID = A.FACCOUNTID
					 WHERE  1=1
					   AND  ((A.FYEAR = @BeginYear AND @BeginYear <> '' ) OR @BeginYear = '')
					   AND  ((A.FPERIOD = @BeginPeriod AND @BeginPeriod <> '' ) OR @BeginPeriod = '')
					   AND  B.FNUMBER IN ('5001')
					   AND  A.FDETAILID = 0
					   AND  A.FCURRENCYID <> 0),0)
	  FROM  #TEMP A 
	 WHERE  FName = '      加：在产品期初余额'

	--      减：在产品期末余额
	UPDATE  #TEMP 
	   SET  FAmount = 0 - ISNULL(
					(SELECT SUM(FENDBALANCEFOR)
					  FROM  T_GL_Balance A
							INNER JOIN T_BD_ACCOUNT B
							ON B.FACCTID = A.FACCOUNTID
					 WHERE  1=1
					   AND  ((A.FYEAR = @EndYear AND @EndYear <> '' ) OR @EndYear = '')
					   AND  ((A.FPERIOD = @EndPeriod AND @EndPeriod <> '' ) OR @EndPeriod = '')
					   AND  B.FNUMBER IN ('5001')
					   AND  A.FDETAILID = 0
					   AND  A.FCURRENCYID <> 0),0)
	  FROM  #TEMP A 
	 WHERE  FName = '      减：在产品期末余额'

	--产品生产成本
	UPDATE #TEMP SET FAmount = ISNULL((SELECT SUM(FAmount) FROM #TEMP WHERE FType = 3),0) WHERE FName = '产成品成本'

	UPDATE #TEMP SET FAmount = 0 - FAmount WHERE FAmount < 0

	SELECT * FROM #TEMP
END