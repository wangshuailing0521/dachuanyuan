--公司日常经费一览表
ALTER PROC sp_SCS_YearDayReport
	@Year INT
AS
BEGIN
	CREATE TABLE #TEMP(
		
		FAccountName VARCHAR(255) DEFAULT '',
		FZZAccountNo VARCHAR(255) DEFAULT '',
		FXSAccountNo VARCHAR(255) DEFAULT '',
		FGLAccountNo VARCHAR(255) DEFAULT '',
		FYFAccountNo VARCHAR(255) DEFAULT '',

		FZZFY DECIMAL(28,10) DEFAULT 0,--制造费用
		FXSFY DECIMAL(28,10) DEFAULT 0,--销售费用
		FGLFY DECIMAL(28,10) DEFAULT 0,--管理费用
		FYFFY DECIMAL(28,10) DEFAULT 0,--研发费（管理费用）
		FHJFY DECIMAL(28,10) DEFAULT 0,--合   计
	)

	INSERT INTO #TEMP(FAccountName,FZZAccountNo,FXSAccountNo,FGLAccountNo,FYFAccountNo) 
	VALUES(                 '工资','5101.01','6601.01','6602.01','5301.01')
	     ,(               '福利费','5101.02','6601.02','6602.02','5301.02')
		 ,(               '办公费','5101.06','6601.06','6602.07','5301.06')
		 ,(               '差旅费','5101.07','6601.07','6602.08','5301.07')
		 ,(               '水电费','5101.11','       ','       ','       ')
		 ,(               '租赁费','5101.10','       ','       ','       ')
		 ,( '折旧费及无形资产摊销','5101.09','       ','6602.10','5301.09')
		 ,(           '车辆使用费','5101.08','       ','       ','5301.08')
		 ,(           '交际应酬费','       ','       ','6602.15','       ')
		 ,(                 '聘金','5101.03','6601.03','6602.03','5301.03')
		 ,(               '广告费','       ','6601.09','       ','       ')
		 ,(               '参展费','       ','6601.10','       ','       ')
		 ,(           '销售服务费','       ','6601.11','       ','       ')
		 ,(             '六项基金','5101.04/5101.05','6601.04/6601.05','6602.04/6602.05','5301.04/5301.05')
		 ,(             '工会经费','       ','       ','6602.06','       ')
		 ,(             '董事会费','       ','       ','6602.13','       ')
		 ,(           '职工培训费','       ','       ','6602.11','       ')
		 ,(             '物料消耗','       ','       ','       ','5301.10')
		 ,(           '劳动保护费','       ','       ','6602.12','       ')
		 ,(           '技术使用费','       ','6601.12','       ','       ')
		 ,(                 '其他','5101.99','6601.99','6602.99','5301.99')
		 ,(           '营业外支出','       ','       ','6711','       ')


		 ,( '合计','','','','')


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
	 WHERE A.FNUMBER = '6711'

	INSERT INTO #Acct
	SELECT FACCtID,FNUMBER,FLEVEL,FPARENTID,FACCtID,FNUMBER,'',''
	  FROM T_BD_ACCOUNT A
	 WHERE A.FLEVEL = 2
	   --AND A.FNUMBER IN ('2221.17','2221.20','2221.07','2221.11','2221.05','2221.15'
	   --,'2221.14','2221.13')

	--INSERT INTO #Acct
	--SELECT FACCtID,FNUMBER,FLEVEL,FPARENTID,FACCtID,FNUMBER,'',''
	--  FROM T_BD_ACCOUNT A
	-- WHERE A.FLEVEL = 3
	--   AND A.FNUMBER IN ('2221.18.04')

	--INSERT INTO #Acct
	--SELECT  A.FACCtID,A.FNUMBER,A.FLEVEL,A.FPARENTID,B.FLeve12ParentID,FLeve12ParentNo,A.FNUMBER,''
	--  FROM  T_BD_ACCOUNT A
	--		INNER JOIN #Acct B
	--		ON A.FPARENTID = B.FACCtID
	-- WHERE  A.FLEVEL = 3

	--INSERT INTO #Acct
	--SELECT  A.FACCtID,A.FNUMBER,A.FLEVEL,A.FPARENTID,B.FLeve12ParentID,FLeve12ParentNo,A.FNUMBER,''
	--  FROM  T_BD_ACCOUNT A
	--		INNER JOIN #Acct B
	--		ON A.FPARENTID = B.FACCtID
	-- WHERE  A.FLEVEL = 4

	--INSERT INTO #Acct
	--SELECT  A.FACCtID,A.FNUMBER,A.FLEVEL,A.FPARENTID,B.FLeve12ParentID,FLeve12ParentNo,FLeve13ParentNo,A.FNUMBER
	--  FROM  T_BD_ACCOUNT A
	--		INNER JOIN #Acct B
	--		ON A.FPARENTID = B.FACCtID
	-- WHERE  A.FLEVEL = 5

	SELECT  A.FYEAR,A.FPERIOD,H.FLeve12ParentNo,SUM(A.FCREDIT)FCREDIT,SUM(A.FDEBIT)FDEBIT
	  INTO  #Balance
	  FROM  T_GL_Balance A
			INNER JOIN T_BD_ACCOUNT B
			ON B.FACCTID = A.FACCOUNTID
			INNER JOIN #Acct H
			ON A.FACCOUNTID = H.FAcctID
	 WHERE  1=1   
	   AND  ((A.FYEAR = @Year AND @Year <> '' ) OR @Year = '')
	   AND  A.FACCOUNTID IN (SELECT FAcctID FROM #Acct)
	   AND  A.FCURRENCYID <> 0
	   AND  A.FDETAILID = 0
	 GROUP  BY H.FLeve12ParentNo,A.FYEAR,A.FPERIOD

	UPDATE  A 
	   SET  A.FZZFY = B.FDEBIT
	  FROM  #TEMP A
			INNER JOIN (SELECT FLeve12ParentNo,FYEAR,SUM(FDEBIT)FDEBIT FROM #Balance GROUP BY FLeve12ParentNo,FYEAR)B
			ON B.FLeve12ParentNo IN (A.FZZAccountNo)

	UPDATE  A 
	   SET  A.FXSFY = B.FDEBIT
	  FROM  #TEMP A
			INNER JOIN (SELECT FLeve12ParentNo,FYEAR,SUM(FDEBIT)FDEBIT FROM #Balance GROUP BY FLeve12ParentNo,FYEAR)B
			ON B.FLeve12ParentNo IN (A.FXSAccountNo)

	UPDATE  A 
	   SET  A.FGLFY = B.FDEBIT
	  FROM  #TEMP A
			INNER JOIN (SELECT FLeve12ParentNo,FYEAR,SUM(FDEBIT)FDEBIT FROM #Balance GROUP BY FLeve12ParentNo,FYEAR)B
			ON B.FLeve12ParentNo IN (A.FGLAccountNo)

	UPDATE  A 
	   SET  A.FYFFY = B.FDEBIT
	  FROM  #TEMP A
			INNER JOIN (SELECT FLeve12ParentNo,FYEAR,SUM(FDEBIT)FDEBIT FROM #Balance GROUP BY FLeve12ParentNo,FYEAR)B
			ON B.FLeve12ParentNo IN (A.FYFAccountNo)

	UPDATE  A 
	   SET  A.FZZFY = (SELECT SUM(FDEBIT)FDEBIT FROM #Balance WHERE FLeve12ParentNo IN ('5101.04','5101.05'))
	  FROM  #TEMP A
	 WHERE  A.FZZAccountNo = '5101.04/5101.05' 

	UPDATE  A 
	   SET  A.FXSFY = (SELECT SUM(FDEBIT)FDEBIT FROM #Balance WHERE FLeve12ParentNo IN ('6601.04','6601.05'))
	  FROM  #TEMP A
	 WHERE  A.FXSAccountNo = '6601.04/6601.05' 

	UPDATE  A 
	   SET  A.FGLFY = (SELECT SUM(FDEBIT)FDEBIT FROM #Balance WHERE FLeve12ParentNo IN ('6602.04','6602.05'))
	  FROM  #TEMP A
	 WHERE  A.FGLAccountNo = '6602.04/6602.05' 

	UPDATE  A 
	   SET  A.FYFFY = (SELECT SUM(FDEBIT)FDEBIT FROM #Balance WHERE FLeve12ParentNo IN ('5301.04','5301.05'))
	  FROM  #TEMP A
	 WHERE  A.FYFAccountNo = '5301.04/5301.05' 

	UPDATE #TEMP SET FHJFY = FZZFY + FXSFY + FGLFY + FYFFY

	UPDATE #TEMP SET FZZFY = (SELECT SUM(FZZFY) FROM #TEMP WHERE FAccountName <> '合计') WHERE FAccountName = '合计'
	UPDATE #TEMP SET FXSFY = (SELECT SUM(FXSFY) FROM #TEMP WHERE FAccountName <> '合计') WHERE FAccountName = '合计'
	UPDATE #TEMP SET FGLFY = (SELECT SUM(FGLFY) FROM #TEMP WHERE FAccountName <> '合计') WHERE FAccountName = '合计'
	UPDATE #TEMP SET FYFFY = (SELECT SUM(FYFFY) FROM #TEMP WHERE FAccountName <> '合计') WHERE FAccountName = '合计'
	UPDATE #TEMP SET FHJFY = (SELECT SUM(FHJFY) FROM #TEMP WHERE FAccountName <> '合计') WHERE FAccountName = '合计'
			
	SELECT * FROM #TEMP
END