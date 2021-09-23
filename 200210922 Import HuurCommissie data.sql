USE HuurCommissie;
GO

/*
200210922 Import HuurCommissie data

*/

-- BEGIN imports

DECLARE @TablePrefix varchar(100) = 'Tbl_Huur_Cie_';
DECLARE @DirectoryName varchar(255) = 'D:\NLDATA\Huurcommissie'; --directroy where you stored  the data from https://www.huurcommissie.nl/over-de-huurcommissie/uitspraken/export-openbaar-register
DECLARE @FileName varchar(255) = '';
DECLARE @tablename varchar(1000) = '';
DECLARE @doscommand varchar(8000);
DECLARE @result int; 
DECLARE @sql nvarchar(max) ='';
DECLARE @CSVFieldTerminator varchar(1) = ';';
DECLARE @CSVFieldQuote varchar(1) = '"';
DECLARE @debug varchar(5) = 'Y'; --Y,I,N
DECLARE @quote varchar(5)= '''';
DECLARE @crlf varchar(5) = CHAR(13)+CHAR(10);
DECLARE @msg varchar(8000) = ''

-- BEGIN get dir into table
DROP TABLE IF EXISTS #CommandShell;
CREATE TABLE #CommandShell ( Line VARCHAR(512));
SET @doscommand = 'dir "'+@DirectoryName+ '\*.csv" /TC';
--PRINT @doscommand;
INSERT INTO #CommandShell
EXEC @result = MASTER..xp_cmdshell   @doscommand ;
IF (@result = 0)  
    PRINT 'Success'  
ELSE  
    PRINT 'Failure'  
;
DELETE
FROM   #CommandShell
WHERE  Line NOT LIKE '[0-9][0-9]/[0-9][0-9]/[0-9][0-9][0-9][0-9] %'
OR Line LIKE '%<DIR>%'
OR Line is null
;
-- END get dir into table

DECLARE File_Cursor CURSOR 
FAST_FORWARD
FOR 
SELECT 
--         1         2         3         4
--1234567890123456789012345678901234567890
--19/09/2021  11:36         1.199.628 huurcie 2017-exportList.csv
  [FileName] = SUBSTRING(Line,37,500)
--      [FileName] = REVERSE( LEFT(REVERSE(Line),CHARINDEX(' ',REVERSE(Line))-1 ) )  -breaks on spaces withn name!
FROM #CommandShell
WHERE 1=1
OPEN File_Cursor  
FETCH NEXT FROM File_Cursor
INTO @FileName; 
WHILE @@FETCH_STATUS = 0  
BEGIN  
  DROP TABLE IF EXISTS [tmp_One_Column];
  CREATE TABLE [tmp_One_Column](
    OneColumn varchar(max) NULL
  );
  SET @sql = '
  BULK INSERT [tmp_One_Column]
  FROM '+@quote+@DirectoryName+'\'+@FileName+@quote+'
  WITH (
    CODEPAGE = '+@quote+'RAW'+@quote+'
  , DATAFILETYPE = '+@quote+'char'+@quote+'
  , ROWTERMINATOR = '+@quote+'0x0a'+@quote+'
--  , ROWTERMINATOR = '+@quote+'\n'+@quote+'
--  , FORMAT = '+@quote+'CSV'+@quote+'
--  , FIELDTERMINATOR  = '+@quote+'£'+@quote+'
--  , FIELDTERMINATOR  = '+@quote+@CSVFieldTerminator+@quote+'
--  , FIELDQUOTE  = '+@quote+@CSVFieldQuote+@quote+'
  , FIRSTROW = 1
  , LASTROW = 1
  , TABLOCK
  );'
  IF @debug = 'Y' 
	BEGIN
    SET @msg = @sql
		IF LEN(@msg) > 2047
			PRINT @msg;
		ELSE
			RAISERROR (@msg, 0, 1) WITH NOWAIT; 
	END;
	EXEC (@sql);
  --drop table
  SET @sql = 'DROP TABLE IF EXISTS ['+@TablePrefix+REPLACE(@FileName,'.csv','')+'];'
  IF @debug = 'Y' 
	BEGIN
    SET @msg = @sql
		IF LEN(@msg) > 2047
			PRINT @msg;
		ELSE
			RAISERROR (@msg, 0, 1) WITH NOWAIT; 
	END;
  EXEC (@sql);
--  SELECT * FROM [tmp_One_Column] t1;
  --create table
  SELECT @sql = 'CREATE TABLE ['+@TablePrefix+REPLACE(@FileName,'.csv','')+'] ('+@crlf+'['+REPLACE(SUBSTRING(t1.OneColumn,1,LEN(t1.OneColumn)-0),';','] varchar(max) NULL,'+@crlf+'[')+'] varchar(max) NULL);'
  FROM [tmp_One_Column] t1
  ;
  --there is one empthy column name
  SET @sql = REPLACE(@sql,'[]','[empty1]');
  --there are quotes on column names
  SET @sql = REPLACE(@sql,'"','');
  IF @debug = 'Y' 
	BEGIN
    SET @msg = @sql
		IF LEN(@msg) > 2047
			PRINT @msg;
		ELSE
			RAISERROR (@msg, 0, 1) WITH NOWAIT; 
	END;
  EXEC (@sql);
  --load data
  SET @sql = '
  BULK INSERT ['+@TablePrefix+REPLACE(@FileName,'.csv','')+']
  FROM '+@quote+@DirectoryName+'\'+@FileName+@quote+'
  WITH (
    CODEPAGE = '+@quote+'RAW'+@quote+'
--  , DATAFILETYPE = '+@quote+'char'+@quote+'
  , ROWTERMINATOR = '+@quote+'0x0a'+@quote+'
--  , ROWTERMINATOR = '+@quote+'\n'+@quote+'
  , FORMAT = '+@quote+'CSV'+@quote+'
--  , FIELDTERMINATOR  = '+@quote+';'+@quote+'
  , FIELDTERMINATOR  = '+@quote+@CSVFieldTerminator+@quote+'
  , FIELDQUOTE  = '+@quote+@CSVFieldQuote+@quote+'

  , FIRSTROW = 2
  , TABLOCK
  );'
  IF @debug = 'Y' 
	BEGIN
    SET @msg = @sql
		IF LEN(@msg) > 2047
			PRINT @msg;
		ELSE
			RAISERROR (@msg, 0, 1) WITH NOWAIT; 
	END;
  EXEC (@sql);

  --drop 1 line table
  DROP TABLE IF EXISTS [tmp_One_Column];

  FETCH NEXT FROM File_Cursor   
  INTO @FileName; 
END
CLOSE File_Cursor;  
DEALLOCATE File_Cursor;  

-- drop directory table
DROP TABLE IF EXISTS #CommandShell;

-- END imports


USE [HuurCommissie]
GO

CREATE OR ALTER   VIEW [dbo].[Vw_HuurCommissie_Uitspraken] AS
SELECT *
FROM [HuurCommissie].[dbo].[Tbl_Huur_Cie_huurcie 2017-exportList]
UNION
SELECT *
FROM [HuurCommissie].[dbo].[Tbl_Huur_Cie_huurcie 2018-exportList]
UNION
SELECT *
FROM [HuurCommissie].[dbo].[Tbl_Huur_Cie_huurcie 2019-exportList]
UNION
SELECT *
FROM [HuurCommissie].[dbo].[Tbl_Huur_Cie_huurcie 2020-exportList]
UNION
SELECT *
FROM [HuurCommissie].[dbo].[Tbl_Huur_Cie_huurcie 2021-exportList]
WHERE 1=1
;
GO

