--加工及材料费支付情况表     
ALTER PROC sp_SCS_JGCLZFReport
	@ProgramNo VARCHAR(MAX),
	@SupplierNo VARCHAR(MAX),
	@TempTable VARCHAR(255) = ''
AS
BEGIN
	CREATE TABLE #TEMP(
		FProgamID INT,
		FProgramNo VARCHAR(255),
		FProgramName VARCHAR(255),--项目名称
		FYear VARCHAR(255),
		FJGAmount DECIMAL(28,10),--加工费(合同）
		FJGSupplierName VARCHAR(255),--供应商
		FJGPayAmount DECIMAL(28,10),--付款金额
		FJGNoPayAmount DECIMAL(28,10),--未付款金额
		FJGPayAbleAmount DECIMAL(28,10),--开票金额
		FJGNoPayAbleAmount DECIMAL(28,10),--未开票金额
		FJGStatus VARCHAR(255),--状态
		FJGAbsAmount DECIMAL(28,10),--金额

		FCLAmount DECIMAL(28,10),--材料费（合同）
		FCLSupplierName VARCHAR(255),--供应商
		FCLPayAmount DECIMAL(28,10),--付款金额
		FCLNoPayAmount DECIMAL(28,10),--未付款金额
		FCLPayAbleAmount DECIMAL(28,10),--开票金额
		FCLNoPayAbleAmount DECIMAL(28,10),--未开票金额
		FCLStatus VARCHAR(255),--状态
		FCLAbsAmount DECIMAL(28,10),--金额
	)

	CREATE TABLE #Supplier(
		FSupplierID INT,
		FSupplierNo VARCHAR(255),
		FSupplierName VARCHAR(255))

	IF(@SupplierNo = '')
	BEGIN
		INSERT INTO #Supplier(FSupplierID,FSupplierNo,FSupplierName)
		SELECT A.FSUPPLIERID,A.FNUMBER,B.FNAME FROM T_BD_SUPPLIER A INNER JOIN T_BD_SUPPLIER_L B ON A.FSupplierID = B.FSupplierID AND B.FLOCALEID = 2052
	END
	ELSE
	BEGIN
		INSERT INTO #Supplier(FSupplierID,FSupplierNo,FSupplierName)
		SELECT A.FSUPPLIERID,A.FNUMBER,B.FNAME FROM T_BD_SUPPLIER A INNER JOIN T_BD_SUPPLIER_L B ON A.FSupplierID = B.FSupplierID AND B.FLOCALEID = 2052
		WHERE FNUMBER IN (SELECT value FROM sp_split(@SupplierNo,','))
	END

	INSERT INTO #TEMP(FProgamID,FProgramNo,FProgramName)
	SELECT  DISTINCT A.FENGINEENO,H.FNUMBER,B.FNAME
	  FROM  PDLJ_t_Cust130007 A --工程决定通知书
			LEFT JOIN T_BAS_PREBDONE_L B
			ON A.FENGINEENO = B.FID
			LEFT JOIN T_BAS_PREBDONE H
			ON A.FENGINEENO = H.FID
	 WHERE  A.FDOCUMENTSTATUS = 'C'
	   AND  ((@ProgramNo <> '' AND (H.FNUMBER IN (SELECT value FROM sp_split(@ProgramNo,','))) )OR @ProgramNo = '')

	--INSERT INTO #TEMP(FProgamID,FProgramNo,FProgramName)
	--SELECT  C.FID,C.FNUMBER,D.FNAME
	--  FROM  T_PUR_POORDER A
	--		INNER JOIN T_PUR_POORDERENTRY B
	--		ON A.FID = B.FID
	--		INNER JOIN T_BAS_PREBDONE C
	--		ON B.F_qqqq_Base1 = C.FID
	--		INNER JOIN T_BAS_PREBDONE_L D
	--		ON C.FID = D.FID
	--		INNER JOIN T_BD_SUPPLIER F
	--		ON A.FSUPPLIERID = F.FSUPPLIERID
	--		INNER JOIN T_BD_EXPENSE_L E
	--		ON B.F_QAPZ_Base = E.FEXPID
	-- WHERE  A.FDOCUMENTSTATUS = 'C'
	--   AND  A.FCANCELSTATUS = 'A'
	--   AND  ((@ProgramNo <> '' AND (C.FNUMBER IN (SELECT value FROM sp_split(@ProgramNo,','))) )OR @ProgramNo = '')
	--   AND  ((@SupplierNo <> '' AND (F.FNUMBER IN (SELECT value FROM sp_split(@SupplierNo,','))) )OR @SupplierNo = '')
	--   AND  E.FNAME IN ('加工费','材料费')
	-- GROUP  BY C.FID,C.FNUMBER,D.FNAME

	UPDATE  A
	   SET  A.FYear = YEAR(B.FDATE)
	  FROM  #TEMP A
			INNER JOIN (SELECT FENGINEENO,MAX(FDATE)FDATE FROM PDLJ_t_Cust130007 GROUP BY FENGINEENO)B
			ON A.FProgamID = B.FENGINEENO

	SELECT  B.F_qqqq_Base1 FProgamID
	       ,B.F_QAPZ_Base FExpID
		   ,C.FNAME FExpName
		   ,D.FNAME FSupplierName
		   ,E.FAllAmount FAmount
	  INTO  #Poorder
	  FROM  T_PUR_POORDER A
			INNER JOIN T_PUR_POORDERENTRY B
			ON A.FID = B.FID
			INNER JOIN T_BD_EXPENSE_L C
			ON B.F_QAPZ_Base = C.FEXPID
			INNER JOIN T_BD_SUPPLIER_L D
			ON A.FSUPPLIERID = D.FSUPPLIERID
			INNER JOIN T_PUR_POORDERENTRY_F E
			ON B.FENTRYID = E.FENTRYID
			INNER JOIN T_BD_SUPPLIER F
			ON A.FSUPPLIERID = F.FSUPPLIERID
	 WHERE  A.FDOCUMENTSTATUS = 'C'
	   AND  A.FCANCELSTATUS = 'A'
	   AND  B.F_qqqq_Base1 IN (SELECT FProgamID FROM #TEMP)
	   AND  ((@SupplierNo <> '' AND (F.FNUMBER IN (SELECT value FROM sp_split(@SupplierNo,','))) )OR @SupplierNo = '')
	   AND  C.FNAME IN ('加工费','材料费')

	SELECT  B.F_qqqq_Base1 FProgamID
	       ,B.FCOSTID FExpID
		   ,B.FALLAMOUNTFOR FAmount
		   ,C.FNAME FExpName
	  INTO  #PayAble
	  FROM  T_AP_PAYABLE A
			INNER JOIN T_AP_PAYABLEENTRY B
			ON A.FID = B.FID
			INNER JOIN T_BD_EXPENSE_L C
			ON B.F_QAPZ_Base = C.FEXPID
	 WHERE  A.FDOCUMENTSTATUS = 'C'
	   AND  A.FCANCELSTATUS = 'A'
	   AND  B.F_qqqq_Base1 IN (SELECT FProgamID FROM #TEMP)
	   AND  C.FNAME IN ('加工费','材料费')

	--SELECT  B.F_qqqq_Base2 FProgamID
	--       ,B.FCOSTID FExpID
	--	   ,B.FREALPAYAMOUNTFOR-D.FRELATEREFUNDAMOUNT FAmount
	--	   ,C.FNAME FExpName
	--  INTO  #PayBill
	--  FROM  T_AP_PAYBILL A
	--		INNER JOIN T_AP_PAYBILLENTRY B
	--		ON A.FID = B.FID
	--		INNER JOIN T_AP_PAYBILLENTRY_O D
	--		ON B.FENTRYID = D.FENTRYID
	--		INNER JOIN T_BD_EXPENSE_L C
	--		ON B.FCOSTID = C.FEXPID
	-- WHERE  A.FDOCUMENTSTATUS = 'C'
	--   AND  A.FCANCELSTATUS = 'A'
	--   AND  B.F_qqqq_Base2 IN (SELECT FProgamID FROM #TEMP)
	--   AND  C.FNAME IN ('加工费','材料费')

	SELECT  B.F_qqqq_Base1 FProgamID
	       ,B.FSRCCOSTID FExpID
		   ,B.FREALPAYAMOUNT FAmount
		   ,C.FNAME FExpName
	  INTO  #PayBill
	  FROM  T_AP_PAYBILL A
			INNER JOIN T_AP_PAYBILLSRCENTRY B
			ON A.FID = B.FID
			INNER JOIN T_BD_EXPENSE_L C
			ON B.FSRCCOSTID = C.FEXPID
	 WHERE  A.FDOCUMENTSTATUS = 'C'
	   AND  A.FCANCELSTATUS = 'A'
	   AND  B.F_qqqq_Base1 IN (SELECT FProgamID FROM #TEMP)
	   AND  C.FNAME IN ('加工费','材料费')

	SELECT  B.F_qqqq_Base1 FProgamID
	       ,B.FExpID FExpID
		   ,B.FREALREFUNDAMOUNT FAmount
		   ,C.FNAME FExpName
	  INTO  #PayRefundBill
	  FROM  T_AP_REFUNDBILL A
			INNER JOIN T_AP_REFUNDBILLSRCENTRY B
			ON A.FID = B.FID
			INNER JOIN T_BD_EXPENSE_L C
			ON B.FExpID = C.FEXPID
	 WHERE  A.FDOCUMENTSTATUS = 'C'
	   AND  A.FCANCELSTATUS = 'A'
	   AND  B.F_qqqq_Base1 IN (SELECT FProgamID FROM #TEMP)
	   AND  C.FNAME IN ('加工费','材料费')

	UPDATE  A
	   SET  A.FJGSupplierName = B.FSupplierName
	  FROM  #TEMP A
			INNER JOIN (SELECT FProgamID,MAX(FSupplierName)FSupplierName
						  FROM #Poorder WHERE FExpName = '加工费' GROUP BY FProgamID )B
			ON A.FProgamID = B.FProgamID 

	UPDATE  A
	   SET  A.FJGAmount = B.FAmount
	  FROM  #TEMP A
			INNER JOIN (SELECT FProgamID,SUM(FAmount)FAmount
						  FROM #Poorder WHERE FExpName = '加工费' GROUP BY FProgamID )B
			ON A.FProgamID = B.FProgamID 

	UPDATE  A
	   SET  A.FJGPayAbleAmount = B.FAmount
	  FROM  #TEMP A
			INNER JOIN (SELECT FProgamID,SUM(FAmount)FAmount
						  FROM #PayAble WHERE FExpName = '加工费' GROUP BY FProgamID )B
			ON A.FProgamID = B.FProgamID 

	UPDATE  A
	   SET  A.FJGPayAmount = B.FAmount - ISNULL(C.FAmount,0)
	  FROM  #TEMP A
			INNER JOIN (SELECT FProgamID,SUM(FAmount)FAmount
						  FROM #PayBill WHERE FExpName = '加工费' GROUP BY FProgamID )B
			ON A.FProgamID = B.FProgamID 
			LEFT JOIN (SELECT FProgamID,SUM(FAmount)FAmount
						  FROM #PayRefundBill WHERE FExpName = '加工费' GROUP BY FProgamID )C
			ON A.FProgamID = C.FProgamID 

	UPDATE  A
	   SET  A.FCLSupplierName = B.FSupplierName
	  FROM  #TEMP A
			INNER JOIN (SELECT FProgamID,MAX(FSupplierName)FSupplierName
						  FROM #Poorder WHERE FExpName = '材料费' GROUP BY FProgamID )B
			ON A.FProgamID = B.FProgamID 

	UPDATE  A
	   SET  A.FCLAmount = B.FAmount
	  FROM  #TEMP A
			INNER JOIN (SELECT FProgamID,SUM(FAmount)FAmount
						  FROM #Poorder WHERE FExpName = '材料费' GROUP BY FProgamID )B
			ON A.FProgamID = B.FProgamID 

	UPDATE  A
	   SET  A.FCLPayAbleAmount = B.FAmount
	  FROM  #TEMP A
			INNER JOIN (SELECT FProgamID,SUM(FAmount)FAmount
						  FROM #PayAble WHERE FExpName = '材料费' GROUP BY FProgamID )B
			ON A.FProgamID = B.FProgamID 

	UPDATE  A
	   SET  A.FCLPayAmount = B.FAmount - ISNULL(C.FAmount,0)
	  FROM  #TEMP A
			INNER JOIN (SELECT FProgamID,SUM(FAmount)FAmount
						  FROM #PayBill WHERE FExpName = '材料费' GROUP BY FProgamID )B
			ON A.FProgamID = B.FProgamID 
			LEFT JOIN (SELECT FProgamID,SUM(FAmount)FAmount
						  FROM #PayRefundBill WHERE FExpName = '材料费' GROUP BY FProgamID )C
			ON A.FProgamID = C.FProgamID 

	UPDATE #TEMP SET FJGNoPayAmount = FJGAmount - FJGPayAmount
	UPDATE #TEMP SET FJGNoPayAbleAmount = FJGAmount - FJGPayAbleAmount
	UPDATE #TEMP SET FJGStatus = '预付' WHERE FJGPayAbleAmount < FJGPayAmount
	UPDATE #TEMP SET FJGStatus = '应付' WHERE FJGPayAbleAmount > FJGPayAmount
	UPDATE #TEMP SET FJGStatus = '平' WHERE FJGPayAbleAmount = FJGPayAmount
	UPDATE #TEMP SET FJGAbsAmount = ABS( FJGPayAbleAmount - FJGPayAmount )

	UPDATE #TEMP SET FCLNoPayAmount = FCLAmount - FCLPayAmount
	UPDATE #TEMP SET FCLNoPayAbleAmount = FCLAmount - FCLPayAbleAmount
	UPDATE #TEMP SET FCLStatus = '预付' WHERE FCLPayAbleAmount < FCLPayAmount
	UPDATE #TEMP SET FCLStatus = '应付' WHERE FCLPayAbleAmount > FCLPayAmount
	UPDATE #TEMP SET FCLStatus = '平' WHERE FCLPayAbleAmount = FCLPayAmount
	UPDATE #TEMP SET FCLAbsAmount = ABS( FCLPayAbleAmount - FCLPayAmount )

	IF(@SupplierNo <> '')
	BEGIN
		DELETE FROM #TEMP WHERE ISNULL(FJGSupplierName,'') = '' AND ISNULL(FCLSupplierName,'') = ''
		DELETE FROM #TEMP WHERE FJGSupplierName NOT IN (SELECT FSupplierName FROM #Supplier) AND FCLSupplierName NOT IN (SELECT FSupplierName FROM #Supplier)
	END

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