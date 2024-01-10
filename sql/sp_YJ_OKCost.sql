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

	INSERT INTO #TEMP(FName,FType) SELECT '�ڳ�ԭ�������',1
	INSERT INTO #TEMP(FName,FType) SELECT '      �ӣ����ڹ�������',1
	INSERT INTO #TEMP(FName,FType) SELECT '      ������ĩԭ�������',1
	INSERT INTO #TEMP(FName,FType) SELECT '      ��������ԭ���Ϸ�����',1
	INSERT INTO #TEMP(FName,FType) SELECT 'ֱ�Ӳ��ϳɱ�',1
	INSERT INTO #TEMP(FName,FType) SELECT '      �ӣ�ֱ���˹��ɱ�',2
	INSERT INTO #TEMP(FName,FType) SELECT '      �ӣ��������',2
	INSERT INTO #TEMP(FName,FType) SELECT '      �ӣ��ӹ���',2
	INSERT INTO #TEMP(FName,FType) SELECT '      �ӣ����',2
	INSERT INTO #TEMP(FName,FType) SELECT '      �ӣ������װ��',2
	INSERT INTO #TEMP(FName,FType) SELECT '��Ʒ�����ɱ�',2
	INSERT INTO #TEMP(FName,FType) SELECT '      �ӣ��ڲ�Ʒ�ڳ����',3
	INSERT INTO #TEMP(FName,FType) SELECT '      �����ڲ�Ʒ��ĩ���',3
	INSERT INTO #TEMP(FName,FType) SELECT '      ���������ڲ�Ʒ������',3
	INSERT INTO #TEMP(FName,FType) SELECT '����Ʒ�ɱ�',3
	INSERT INTO #TEMP(FName,FType) SELECT '      �ӣ�����Ʒ�ڳ����',4
	INSERT INTO #TEMP(FName,FType) SELECT '      ��������Ʒ��ĩ���',4
	INSERT INTO #TEMP(FName,FType) SELECT '      ������������Ʒ������',4
	INSERT INTO #TEMP(FName,FType) SELECT '��Ӫҵ��ɱ�',4

	--�ڳ�ԭ�������
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
	 WHERE  FName = '�ڳ�ԭ�������'

	--      �ӣ����ڹ�������
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
	 WHERE  FName = '      �ӣ����ڹ�������'

	--      ������ĩԭ�������
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
	 WHERE  FName = '      ������ĩԭ�������'

	--      ��������ԭ���Ϸ�����
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
	 WHERE  FName = '      ��������ԭ���Ϸ�����'

	--ֱ�Ӳ��ϳɱ�
	UPDATE #TEMP SET FAmount = ISNULL((SELECT SUM(FAmount) FROM #TEMP WHERE FType = 1),0) WHERE FName = 'ֱ�Ӳ��ϳɱ�'
	--      �ӣ�ֱ���˹��ɱ�
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
	 WHERE  FName = '      �ӣ�ֱ���˹��ɱ�'

	--      �ӣ��������
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
	 WHERE  FName = '      �ӣ��������'

	--      �ӣ��ӹ���
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
	 WHERE  FName = '      �ӣ��ӹ���'

	--      �ӣ����
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
	 WHERE  FName = '      �ӣ����'

	--      �ӣ������װ��
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
	 WHERE  FName = '      �ӣ������װ��'

	--��Ʒ�����ɱ�
	UPDATE #TEMP SET FAmount = ISNULL((SELECT SUM(FAmount) FROM #TEMP WHERE FType = 2),0) WHERE FName = '��Ʒ�����ɱ�'

	--      �ӣ��ڲ�Ʒ�ڳ����
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
	 WHERE  FName = '      �ӣ��ڲ�Ʒ�ڳ����'

	--      �����ڲ�Ʒ��ĩ���
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
	 WHERE  FName = '      �����ڲ�Ʒ��ĩ���'

	--��Ʒ�����ɱ�
	UPDATE #TEMP SET FAmount = ISNULL((SELECT SUM(FAmount) FROM #TEMP WHERE FType = 3),0) WHERE FName = '����Ʒ�ɱ�'

	UPDATE #TEMP SET FAmount = 0 - FAmount WHERE FAmount < 0

	SELECT * FROM #TEMP
END