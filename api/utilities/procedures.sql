USE [656989_datasurfer]
GO
/****** Object:  StoredProcedure [app].[sp_census_estimate_age]    Script Date: 4/22/2015 4:05:47 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [app].[sp_census_estimate_age]
	@DATASOURCE_ID int,
	@GEOGRAPHY_NAME nvarchar(25),
	@GEOGRAPHY_ZONE nvarchar(50)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @SQL nvarchar(max);
	DECLARE @ParmDefinition nvarchar(500);
   
	SET @SQL = '
		SELECT
			s.sex
			,a.group_10yr
			,SUM(ase.population) as population
        FROM 
			fact.age_sex_ethnicity ase
			JOIN dim.datasource d on ase.datasource_id = d.datasource_id
        	JOIN dim.mgra m on ase.mgra_id = m.mgra_id
        	JOIN dim.age_group a on ase.age_group_id = a.age_group_id
        	JOIN dim.sex s on ase.sex_id = s.sex_id
        WHERE 
			d.datasource_id = @IN_DATASOURCE_ID and lower(m.' + @GEOGRAPHY_NAME + ') = @IN_GEO_ZONE
        GROUP BY 
			s.sex, a.group_10yr 
        UNION ALL 
		SELECT 
			s.sex as sex,
			''Total Population'' as group_10yr
			,SUM(ase.population) as population	
		FROM 
			fact.age_sex_ethnicity ase
			JOIN dim.datasource d on ase.datasource_id = d.datasource_id
    		JOIN dim.mgra m on ase.mgra_id = m.mgra_id
    		JOIN dim.age_group a on ase.age_group_id = a.age_group_id
    		JOIN dim.sex s on ase.sex_id = s.sex_id 
		WHERE 
			d.datasource_id = @IN_DATASOURCE_ID and lower(m.' + @GEOGRAPHY_NAME + ') = @IN_GEO_ZONE
		GROUP BY 
			s.sex 
		UNION ALL 
		SELECT 
			''Total'' as sex
			,''Total Population'' as group_10yr
			,SUM(ase.population) as population
		FROM 
			fact.age_sex_ethnicity ase
			JOIN dim.datasource d on ase.datasource_id = d.datasource_id
    		JOIN dim.mgra m on ase.mgra_id = m.mgra_id
    		JOIN dim.age_group a on ase.age_group_id = a.age_group_id
    		JOIN dim.sex s on ase.sex_id = s.sex_id
    	WHERE 
			d.datasource_id = @IN_DATASOURCE_ID and lower(m.' + @GEOGRAPHY_NAME + ') = @IN_GEO_ZONE';

	SET @ParmDefinition = N'@IN_DATASOURCE_ID int, @IN_GEO_ZONE nvarchar(50)';

	EXECUTE sp_executesql @SQL, @ParmDefinition, @IN_DATASOURCE_ID = @DATASOURCE_ID, @IN_GEO_ZONE = @GEOGRAPHY_ZONE;
END


GO
/****** Object:  StoredProcedure [app].[sp_census_estimate_ethnicity]    Script Date: 4/22/2015 4:05:47 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [app].[sp_census_estimate_ethnicity]
	@DATASOURCE_ID int,
	@GEOGRAPHY_NAME nvarchar(25),
	@GEOGRAPHY_ZONE nvarchar(50)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @SQL nvarchar(max);
	DECLARE @ParmDefinition nvarchar(500);
   
	SET @SQL = '
		SELECT 
			e.short_name as ethnicity
			,SUM(population) as population 
		FROM 
			fact.age_sex_ethnicity ase
			JOIN dim.datasource d on ase.datasource_id = d.datasource_id
        	JOIN dim.mgra m ON ase.mgra_id = m.mgra_id
        	JOIN dim.ethnicity e ON ase.ethnicity_id = e.ethnicity_id
        WHERE 
			d.datasource_id = @IN_DATASOURCE_ID
			and lower(m.' + @GEOGRAPHY_NAME + ') = @IN_GEO_ZONE
		GROUP BY 
			e.short_name 
    	UNION ALL
			SELECT 
				''Total Population'' as ethnicity
				,SUM(ase.population) as population
			FROM
				fact.age_sex_ethnicity ase 
				JOIN dim.datasource d on ase.datasource_id = d.datasource_id
    			JOIN dim.mgra m ON ase.mgra_id = m.mgra_id WHERE
    			d.datasource_id = @IN_DATASOURCE_ID and lower(m.' + @GEOGRAPHY_NAME + ') = @IN_GEO_ZONE';

	SET @ParmDefinition = N'@IN_DATASOURCE_ID int, @IN_GEO_ZONE nvarchar(50)';

	EXECUTE sp_executesql @SQL, @ParmDefinition, @IN_DATASOURCE_ID = @DATASOURCE_ID, @IN_GEO_ZONE = @GEOGRAPHY_ZONE;
END


GO
/****** Object:  StoredProcedure [app].[sp_census_estimate_housing]    Script Date: 4/22/2015 4:05:47 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [app].[sp_census_estimate_housing]
	@DATASOURCE_ID int,
	@GEOGRAPHY_NAME nvarchar(25),
	@GEOGRAPHY_ZONE nvarchar(50)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @SQL nvarchar(max);
	DECLARE @ParmDefinition nvarchar(500);
   
	SET @SQL = 'SELECT s.long_name as unit_type
		,SUM(units) as units
		,SUM(occupied) as occupied
		,SUM(units - occupied) as unoccupied
		,CASE 
			WHEN SUM(units) = 0 THEN NULL 
			ELSE SUM(units - occupied) / CAST(SUM(units) as float)
		END as vacancy_rate
	FROM 
		fact.housing h JOIN dim.datasource d on h.datasource_id = d.datasource_id	
		JOIN dim.mgra m ON h.mgra_id = m.mgra_id
		JOIN dim.structure_type s ON h.structure_type_id = s.structure_type_id
	WHERE
		d.datasource_id = @IN_DATASOURCE_ID
		and lower(m.' + @GEOGRAPHY_NAME + ') = @IN_GEO_ZONE
	GROUP BY 
		s.long_name
	UNION ALL 
	SELECT 
		''Total Units'' as unit_type
		,SUM(units) as units
		,SUM(occupied) as occupied
		,SUM(units - occupied) as unoccupied
        ,CASE
			WHEN SUM(units) = 0 THEN NULL 
			ELSE SUM(units - occupied) / CAST(SUM(units) as float)	END as vacancy_rate
	FROM 
		fact.housing h JOIN dim.datasource d on h.datasource_id = d.datasource_id
		JOIN dim.mgra m ON h.mgra_id = m.mgra_id
        JOIN dim.structure_type s ON h.structure_type_id = s.structure_type_id
    WHERE 
		d.datasource_id = @IN_DATASOURCE_ID and lower(m.' + @GEOGRAPHY_NAME + ') = @IN_GEO_ZONE';

	SET @ParmDefinition = N'@IN_DATASOURCE_ID int, @IN_GEO_ZONE nvarchar(50)';
	EXECUTE sp_executesql @SQL, @ParmDefinition, @IN_DATASOURCE_ID = @DATASOURCE_ID, @IN_GEO_ZONE = @GEOGRAPHY_ZONE;
END


GO
/****** Object:  StoredProcedure [app].[sp_census_estimate_income]    Script Date: 4/22/2015 4:05:47 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [app].[sp_census_estimate_income]
	@DATASOURCE_ID int,
	@GEOGRAPHY_NAME nvarchar(25),
	@GEOGRAPHY_ZONE nvarchar(50)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @SQL nvarchar(max);
	DECLARE @ParmDefinition nvarchar(500);
   
	SET @SQL = '
		SELECT 
			g.name as income_group,
			sum(i.households) as households
		FROM 
			fact.household_income i
			JOIN dim.income_group g ON i.income_group_id = g.income_group_id
			JOIN dim.datasource d ON i.datasource_id = d.datasource_id
			JOIN dim.mgra m ON i.mgra_id = m.mgra_id
		WHERE 
			d.datasource_id = @IN_DATASOURCE_ID and lower(m.' + @GEOGRAPHY_NAME + ') = @IN_GEO_ZONE
		GROUP BY 
			i.income_group_id, g.name
		ORDER BY 
			i.income_group_id';

	SET @ParmDefinition = N'@IN_DATASOURCE_ID int, @IN_GEO_ZONE nvarchar(50)';

	EXECUTE sp_executesql @SQL, @ParmDefinition, @IN_DATASOURCE_ID = @DATASOURCE_ID, @IN_GEO_ZONE = @GEOGRAPHY_ZONE;
END


GO
/****** Object:  StoredProcedure [app].[sp_forecast_age]    Script Date: 4/22/2015 4:05:47 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [app].[sp_forecast_age]
	@DATASOURCE_ID int,
	@GEOGRAPHY_NAME nvarchar(25),
	@GEOGRAPHY_ZONE nvarchar(50)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @SQL nvarchar(max);
	DECLARE @ParmDefinition nvarchar(500);
   
	SET @SQL = '
		SELECT 
			ase.year
			,s.sex
			,a.group_10yr
			,sum(ase.population) as population
		FROM
			fact.age_sex_ethnicity ase
        	JOIN dim.datasource d on ase.datasource_id = d.datasource_id
        	JOIN dim.mgra m on ase.mgra_id = m.mgra_id
        	JOIN dim.age_group a on ase.age_group_id = a.age_group_id
        	JOIN dim.sex s on ase.sex_id = s.sex_id
        WHERE
			d.datasource_id = @IN_DATASOURCE_ID and lower(m.' + @GEOGRAPHY_NAME + ') = @IN_GEO_ZONE
        GROUP BY 
			ase.year, s.sex, a.group_10yr
		UNION
		SELECT 
			ase.year
			,s.sex
			,''Total Population''
			,sum(ase.population) as population
		FROM
			fact.age_sex_ethnicity ase
        	JOIN dim.datasource d on ase.datasource_id = d.datasource_id
        	JOIN dim.mgra m on ase.mgra_id = m.mgra_id
        	JOIN dim.age_group a on ase.age_group_id = a.age_group_id
        	JOIN dim.sex s on ase.sex_id = s.sex_id
        WHERE
			d.datasource_id = @IN_DATASOURCE_ID and lower(m.' + @GEOGRAPHY_NAME + ') = @IN_GEO_ZONE
        GROUP BY 
			ase.year, s.sex
		UNION
		SELECT 
			ase.year
			,''Total''
			,''Total Population''
			,sum(ase.population) as population
		FROM
			fact.age_sex_ethnicity ase
        	JOIN dim.datasource d on ase.datasource_id = d.datasource_id
        	JOIN dim.mgra m on ase.mgra_id = m.mgra_id
        	JOIN dim.age_group a on ase.age_group_id = a.age_group_id
        	JOIN dim.sex s on ase.sex_id = s.sex_id
        WHERE
			d.datasource_id = @IN_DATASOURCE_ID and lower(m.' + @GEOGRAPHY_NAME + ') = @IN_GEO_ZONE
        GROUP BY 
			ase.year';

	SET @ParmDefinition = N'@IN_DATASOURCE_ID int, @IN_GEO_ZONE nvarchar(50)';

	EXECUTE sp_executesql @SQL, @ParmDefinition, @IN_DATASOURCE_ID = @DATASOURCE_ID, @IN_GEO_ZONE = @GEOGRAPHY_ZONE;
END


GO
/****** Object:  StoredProcedure [app].[sp_forecast_ethnicity]    Script Date: 4/22/2015 4:05:47 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [app].[sp_forecast_ethnicity]
	@DATASOURCE_ID int,
	@GEOGRAPHY_NAME nvarchar(25),
	@GEOGRAPHY_ZONE nvarchar(50)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @SQL nvarchar(max);
	DECLARE @ParmDefinition nvarchar(500);
   
	SET @SQL = '
		SELECT
			ase.year
			,e.short_name as ethnicity
			,sum(ase.population) as population
		FROM 
			fact.age_sex_ethnicity ase
			JOIN dim.datasource d on ase.datasource_id = d.datasource_id
			JOIN dim.mgra m on ase.mgra_id = m.mgra_id
			JOIN dim.ethnicity e on ase.ethnicity_id = e.ethnicity_id
		WHERE 
			d.datasource_id = @IN_DATASOURCE_ID and lower(m.' + @GEOGRAPHY_NAME + ') = @IN_GEO_ZONE
		GROUP BY 
			ase.year, e.short_name
		UNION ALL
		SELECT
			ase.year
			,''Total Population'' as ethnicity
			,sum(ase.population) as population
		FROM 
			fact.age_sex_ethnicity ase
			JOIN dim.datasource d on ase.datasource_id = d.datasource_id
			JOIN dim.mgra m on ase.mgra_id = m.mgra_id
			JOIN dim.ethnicity e on ase.ethnicity_id = e.ethnicity_id
		WHERE 
			d.datasource_id = @IN_DATASOURCE_ID and lower(m.' + @GEOGRAPHY_NAME + ') = @IN_GEO_ZONE
		GROUP BY 
			ase.year'

	SET @ParmDefinition = N'@IN_DATASOURCE_ID int, @IN_GEO_ZONE nvarchar(50)';

	EXECUTE sp_executesql @SQL, @ParmDefinition, @IN_DATASOURCE_ID = @DATASOURCE_ID, @IN_GEO_ZONE = @GEOGRAPHY_ZONE;
END


GO
/****** Object:  StoredProcedure [app].[sp_forecast_ethnicity_change]    Script Date: 4/22/2015 4:05:47 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [app].[sp_forecast_ethnicity_change]
	@DATASOURCE_ID int,
	@GEOGRAPHY_NAME nvarchar(25),
	@GEOGRAPHY_ZONE nvarchar(50)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @B_YEAR nchar(4);
	DECLARE @SQL nvarchar(max);
	DECLARE @ParmDefinition nvarchar(500);

	SET @B_YEAR =
		CASE @DATASOURCE_ID
			WHEN 6 --Series 12
				THEN '2008'	
			WHEN 13 --Series 13
				THEN '2012'
		END;
   
	SET @SQL = '
		SELECT 
			ethnicity
			,CASE 
				WHEN [' + @B_YEAR + '] > 0 THEN [2020]/CAST([' + @B_YEAR + '] as FLOAT) - 1
				ELSE NULL
			END as pct_chg_byear_to_2020
			,CASE 
				WHEN [2020] > 0 THEN [2025]/CAST([2020] as FLOAT) - 1
				ELSE NULL
			END as pct_chg_2020_to_2025
			,CASE 
				WHEN [2025] > 0 THEN [2030]/CAST([2025] as FLOAT) - 1
				ELSE NULL
			END as pct_chg_2025_to_2030
			,CASE 
				WHEN [2030] > 0 THEN [2035]/CAST([2030] as FLOAT) - 1
				ELSE NULL
			END as pct_chg_2030_to_2035
			,CASE 
				WHEN [2035] > 0 THEN [2040]/CAST([2035] as FLOAT) - 1
				ELSE NULL
			END as pct_chg_2035_to_2040
			,CASE 
				WHEN [2040] > 0 THEN [2045]/CAST([2040] as FLOAT) - 1
				ELSE NULL
			END as pct_chg_2040_to_2045
			,CASE 
				WHEN [2045] > 0 THEN [2050]/CAST([2045] as FLOAT) - 1
				ELSE NULL
			END as pct_chg_2045_to_2050
			,CASE 
				WHEN [' + @B_YEAR + '] > 0 THEN [2050]/CAST([' + @B_YEAR + '] as FLOAT) - 1
				ELSE NULL
			END as pct_chg_base_to_horizon
		FROM
			(SELECT
				ase.year
				,e.short_name as ethnicity
				,sum(ase.population) as population
			FROM 
				fact.age_sex_ethnicity ase
				JOIN dim.datasource d on ase.datasource_id = d.datasource_id
				JOIN dim.mgra m on ase.mgra_id = m.mgra_id
				JOIN dim.ethnicity e on ase.ethnicity_id = e.ethnicity_id
			WHERE 
				d.datasource_id = @IN_DATASOURCE_ID and lower(m.' + @GEOGRAPHY_NAME + ') = @IN_GEO_ZONE
			GROUP BY 
				ase.year, e.short_name) p PIVOT
				(SUM(population) for year in ([' + @B_YEAR + '],[2020],[2025],[2030],[2035],[2040],[2045],[2050])) as piv
		UNION ALL
				SELECT 
			ethnicity
			,CASE 
				WHEN [' + @B_YEAR + '] > 0 THEN [2020]/CAST([' + @B_YEAR + '] as FLOAT) - 1
				ELSE NULL
			END as pct_chg_byear_to_2020
			,CASE 
				WHEN [2020] > 0 THEN [2025]/CAST([2020] as FLOAT) - 1
				ELSE NULL
			END as pct_chg_2020_to_2025
			,CASE 
				WHEN [2025] > 0 THEN [2030]/CAST([2025] as FLOAT) - 1
				ELSE NULL
			END as pct_chg_2025_to_2030
			,CASE 
				WHEN [2030] > 0 THEN [2035]/CAST([2030] as FLOAT) - 1
				ELSE NULL
			END as pct_chg_2030_to_2035
			,CASE 
				WHEN [2035] > 0 THEN [2040]/CAST([2035] as FLOAT) - 1
				ELSE NULL
			END as pct_chg_2035_to_2040
			,CASE 
				WHEN [2040] > 0 THEN [2045]/CAST([2040] as FLOAT) - 1
				ELSE NULL
			END as pct_chg_2040_to_2045
			,CASE 
				WHEN [2045] > 0 THEN [2050]/CAST([2045] as FLOAT) - 1
				ELSE NULL
			END as pct_chg_2045_to_2050
			,CASE 
				WHEN [' + @B_YEAR + '] > 0 THEN [2050]/CAST([' + @B_YEAR + '] as FLOAT) - 1
				ELSE NULL
			END as pct_chg_base_to_horizon
		FROM
			(SELECT
				ase.year
				,''Total Population'' as ethnicity
				,sum(ase.population) as population
			FROM 
				fact.age_sex_ethnicity ase
				JOIN dim.datasource d on ase.datasource_id = d.datasource_id
				JOIN dim.mgra m on ase.mgra_id = m.mgra_id
				JOIN dim.ethnicity e on ase.ethnicity_id = e.ethnicity_id
			WHERE 
				d.datasource_id = @IN_DATASOURCE_ID and lower(m.' + @GEOGRAPHY_NAME + ') = @IN_GEO_ZONE
			GROUP BY 
				ase.year) p PIVOT
				(SUM(population) for year in ([' + @B_YEAR + '],[2020],[2025],[2030],[2035],[2040],[2045],[2050])) as piv';
			

	SET @ParmDefinition = N'@IN_DATASOURCE_ID int, @IN_GEO_ZONE nvarchar(50)';

	EXECUTE sp_executesql @SQL, @ParmDefinition, @IN_DATASOURCE_ID = @DATASOURCE_ID, @IN_GEO_ZONE = @GEOGRAPHY_ZONE;
END


GO
/****** Object:  StoredProcedure [app].[sp_forecast_housing]    Script Date: 4/22/2015 4:05:47 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [app].[sp_forecast_housing]
	@DATASOURCE_ID int,
	@GEOGRAPHY_NAME nvarchar(25),
	@GEOGRAPHY_ZONE nvarchar(50)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @SQL nvarchar(max);
	DECLARE @ParmDefinition nvarchar(500);
   
	SET @SQL = '
		SELECT
			h.year
			,s.long_name as unit_type
			,SUM(units) as units
			,SUM(occupied) as occupied
			,SUM(units - occupied) as unoccupied
    		,CASE
				WHEN SUM(units) = 0 THEN NULL 
				ELSE SUM(units - occupied) / CAST(SUM(units) as float) 
			END as vacancy_rate
		FROM
			fact.housing h
			JOIN dim.datasource d on h.datasource_id = d.datasource_id
			JOIN dim.mgra m ON h.mgra_id = m.mgra_id
			JOIN dim.structure_type s ON h.structure_type_id = s.structure_type_id
		WHERE 
			d.datasource_id = @IN_DATASOURCE_ID and lower(m.' + @GEOGRAPHY_NAME + ') = @IN_GEO_ZONE
		GROUP 
			BY h.year, s.long_name
		UNION ALL
		SELECT
			h.year
			,''Total Units'' as unit_type
			,SUM(units) as units
			,SUM(occupied) as occupied
			,SUM(units - occupied) as unoccupied
    		,CASE
				WHEN SUM(units) = 0 THEN NULL 
				ELSE SUM(units - occupied) / CAST(SUM(units) as float) 
			END as vacancy_rate
		FROM
			fact.housing h
			JOIN dim.datasource d on h.datasource_id = d.datasource_id
			JOIN dim.mgra m ON h.mgra_id = m.mgra_id
			JOIN dim.structure_type s ON h.structure_type_id = s.structure_type_id
		WHERE 
			d.datasource_id = @IN_DATASOURCE_ID and lower(m.' + @GEOGRAPHY_NAME + ') = @IN_GEO_ZONE
		GROUP 
			BY h.year';

	SET @ParmDefinition = N'@IN_DATASOURCE_ID int, @IN_GEO_ZONE nvarchar(50)';

	EXECUTE sp_executesql @SQL, @ParmDefinition, @IN_DATASOURCE_ID = @DATASOURCE_ID, @IN_GEO_ZONE = @GEOGRAPHY_ZONE;
END


GO
/****** Object:  StoredProcedure [app].[sp_forecast_income]    Script Date: 4/22/2015 4:05:47 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [app].[sp_forecast_income]
	@DATASOURCE_ID int,
	@GEOGRAPHY_NAME nvarchar(25),
	@GEOGRAPHY_ZONE nvarchar(50)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @SQL nvarchar(max);
	DECLARE @ParmDefinition nvarchar(500);
	
	SET @SQL = '
		SELECT 
			i.yr as year
			,g.name as income_group
			,sum(i.households) as households
		FROM 
			fact.household_income i
			JOIN dim.income_group g ON i.income_group_id = g.income_group_id
			JOIN dim.datasource d ON i.datasource_id = d.datasource_id
			JOIN dim.mgra m ON i.mgra_id = m.mgra_id
		WHERE 
			d.datasource_id = @IN_DATASOURCE_ID and lower(m.' + @GEOGRAPHY_NAME + ') = @IN_GEO_ZONE
		GROUP BY i.yr, i.income_group_id, g.name';

	SET @ParmDefinition = N'@IN_DATASOURCE_ID int, @IN_GEO_ZONE nvarchar(50)';

	EXECUTE sp_executesql @SQL, @ParmDefinition, @IN_DATASOURCE_ID = @DATASOURCE_ID, @IN_GEO_ZONE = @GEOGRAPHY_ZONE;
END

GO
/****** Object:  StoredProcedure [app].[sp_forecast_jobs]    Script Date: 4/22/2015 4:05:47 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [app].[sp_forecast_jobs]
	@DATASOURCE_ID int,
	@GEOGRAPHY_NAME nvarchar(25),
	@GEOGRAPHY_ZONE nvarchar(50)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @SQL nvarchar(max);
	DECLARE @ParmDefinition nvarchar(500);
   
	SET @SQL = '
		SELECT 
			j.year
			,e.full_name as category
			,sum(j.jobs) as jobs
		FROM
			fact.jobs j
			JOIN dim.datasource d on j.datasource_id = d.datasource_id
			JOIN dim.mgra m ON j.mgra_id = m.mgra_id
			JOIN dim.employment_type e ON j.employment_type_id = e.employment_type_id
		WHERE
			d.datasource_id = @IN_DATASOURCE_ID and lower(m.' + @GEOGRAPHY_NAME + ') = @IN_GEO_ZONE AND e.civilian = 1
		GROUP BY
			j.year, e.full_name
		UNION ALL
		SELECT 
			j.year
			,''Total Civilian Jobs''
			,sum(j.jobs) as jobs
		FROM
			fact.jobs j
			JOIN dim.datasource d on j.datasource_id = d.datasource_id
			JOIN dim.mgra m ON j.mgra_id = m.mgra_id
			JOIN dim.employment_type e ON j.employment_type_id = e.employment_type_id
		WHERE
			d.datasource_id = @IN_DATASOURCE_ID and lower(m.' + @GEOGRAPHY_NAME + ') = @IN_GEO_ZONE AND e.civilian = 1
		GROUP BY
			j.year';

	SET @ParmDefinition = N'@IN_DATASOURCE_ID int, @IN_GEO_ZONE nvarchar(50)';

	EXECUTE sp_executesql @SQL, @ParmDefinition, @IN_DATASOURCE_ID = @DATASOURCE_ID, @IN_GEO_ZONE = @GEOGRAPHY_ZONE;
END


GO
/****** Object:  StoredProcedure [app].[sp_median_hh_inc]    Script Date: 4/22/2015 4:05:47 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [app].[sp_median_hh_inc] (@DATASOURCE_ID INT, @GEOGRAPHY_NAME SYSNAME, @GEOGRAPHY_ZONE NVARCHAR(128))
AS
BEGIN

/* Steps:
 * 1. Sum HHs by year and geography name in a CTE.
 * 2. Compute the income distribution (as a CTE) by income group and year for each geography,
 *    including the lower and upper bounds of the interval.
 * 3. Join the income distribution to itself to get a cumulative sum. To do this, join where the income group of the second
      table (a copy of itself) is <= income group of the first table as well as the cum_sum >= N / 2. Also, rank order by year and
	  income group so we can select only the top (rank 1) result from each year, income group pair. This is the group that contains
	  the median.
 * 4. Compute the closed-form computation of grouped median.
           lower bound of group containing median + (((N / 2) - cumulative freq of groups preceding group that contains median) /
		           frequency of group containing median) * interval width of group containing median
   5. Compute as float, round to nearest INT, and cast as INT.
  */
DECLARE @sql_string NVARCHAR(MAX) = N'
WITH num_hh AS
(
	SELECT i.yr, SUM(i.households) as hh
	FROM fact.household_income i
		INNER JOIN dim.mgra m
		ON m.mgra_id = i.mgra_id
	WHERE datasource_id = @ds
	AND m.' + QUOTENAME(@GEOGRAPHY_NAME) + N' = ''' +
	LTRIM(RTRIM(UPPER(@GEOGRAPHY_ZONE))) + N'''
	GROUP BY i.yr
)
,inc_dist AS
(
    SELECT i.yr
	    ,i.income_group_id
		,ig.lower_bound
		,ig.upper_bound
		,ig.upper_bound - ig.lower_bound + 1 as interval_width
		,SUM(i.households) hh
	FROM fact.household_income i
		INNER JOIN dim.mgra m
		ON m.mgra_id = i.mgra_id
			INNER JOIN dim.income_group ig
			ON i.income_group_id = ig.income_group_id
	WHERE i.datasource_id = @ds
	AND m.' + QUOTENAME(@GEOGRAPHY_NAME) + N' = ''' +
	LTRIM(RTRIM(UPPER(@GEOGRAPHY_ZONE))) + N'''
	GROUP BY i.yr
		,i.income_group_id
		,ig.lower_bound
		,ig.upper_bound
)
, cum_dist AS
(
	SELECT ROW_NUMBER() OVER (PARTITION BY a.yr ORDER BY a.yr, a.income_group_id) as row_num
		,a.yr
		,a.income_group_id
		,a.lower_bound
		,a.upper_bound
		,a.interval_width
		,a.hh
		,SUM(b.hh) as cum_sum
	FROM inc_dist a
		INNER JOIN inc_dist b
		ON a.income_group_id >= b.income_group_id
		AND a.yr = b.yr
			INNER JOIN num_hh
			ON num_hh.yr = a.yr
	GROUP BY a.yr
		,a.income_group_id
		,a.lower_bound
		,a.upper_bound
		,a.interval_width
		,a.hh
		,num_hh.hh
	HAVING SUM(b.hh) > (num_hh.hh / 2.0)
)
SELECT cum_dist.yr
	,CAST(ROUND((lower_bound + ((num_hh.hh / 2.0 - (cum_sum - cum_dist.hh)) / cum_dist.hh) * interval_width), 0) as INT) as median_inc
FROM cum_dist
	INNER JOIN num_hh
	ON num_hh.yr = cum_dist.yr
    AND cum_dist.row_num = 1
ORDER BY cum_dist.yr;'

EXECUTE sp_executesql @sql_string,N'@ds INT',@ds = @DATASOURCE_ID;

END



GO
