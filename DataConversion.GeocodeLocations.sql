

--select *
--from bLocation
--where Address1 = '31 Wright Rd' and city = 'Hollister' --429345

--exec DataConversion.GeocodeLocations 429345


CREATE OR ALTER PROCEDURE DataConversion.GeocodeLocations   
    @bLocationID int     
AS

	declare @Address nvarchar(500)
	declare @Header nvarchar(100)

	select @Address = 'street=' + Address1 + '&city=' + city + '&state=' + state + '&postcode=' + zipcode + '&country=US'
	from bLocation
	where bLocationID = @bLocationID

	--set @Header = '	$header = @{' + '''' + 'Authorization' + '''' + ' = ' + '''' + '504FCAC9ECD58E4DA3FA4011F27A17EB' + '''' + '};'
	set @Header = '@{' + '''' + 'Authorization' + '''' + ' = ' + '''' + '504FCAC9ECD58E4DA3FA4011F27A17EB' + '''' + '}'
	   	  

	/* Build API call */
   
    DECLARE @url varchar(255) = CONCAT(
        'https://pcmiler.alk.com/APIs/REST/v1.0/Service.svc/locations',
		'?',
        @Address
    );

   -- DECLARE @query varchar(255) = ').Coords | ConvertTo-Json'
	
    DECLARE @cmd varchar(512) = CONCAT(		
       ' powershell -command "',
		--' powershell ',
		----@Header,
		-- ' -command ',
        --' (Invoke-RestMethod -Method GET -Headers ' + @Header + ' -Uri "',  
		' (Invoke-RestMethod -Method GET -Headers ' + @Header + ' -Uri ',        
		'''',
        @url,     
		--'"',           
		--').Coords '
		'''',      		        
        ').Coords | ConvertTo-Json'        
		,'"'          
    );

	--print @cmd

    DECLARE @result TABLE (output varchar(MAX));

    /* Make the HTTP call using Powershell */
    INSERT @result
    EXEC xp_cmdshell @cmd

	--select * from @result

	--SELECT STRING_AGG(CAST(output AS varchar(MAX)), CHAR(10))
 --       FROM @result
 --       WHERE output IS NOT NULL

    /* Process the resulting JSON and insert into import table */
    DECLARE @json varchar(MAX) = (
        (SELECT STRING_AGG(CAST(output AS varchar(MAX)), CHAR(10))
        FROM @result
        WHERE output IS NOT NULL) 
    );

	--print @json
	
	--SELECT JSON_VALUE('{ "lat": "25", "lon": "30" }', '$.lon')
--	SELECT JSON_VALUE('{
--    "lat":  "36.869346",
--    "lon":  "-121.402060"
--}', '$.lon')

	--select JSON_VALUE(@json, '$.lat')

	--SELECT lat = JSON_VALUE(@json, '$.Lat')
	--select lon = JSON_VALUE(@json, '$.Lon')       
        --FROM OPENJSON (@json) 

		SELECT @bLocationID as LocationID, Lat * 1000000 as Lat, Lon * 1000000 as Lon
		into #tmp1
		FROM OPENJSON(@json) 
		WITH (Lat decimal(19,6), Lon decimal(19,6))

	--exec UpdatebLocationLatLong  @bLocationID, @Latitude, @Longitude, @UserName

		--select *
		update l set Latitude= t.lat, Longitude = t.Lon
		from #tmp1 t
		--inner join bLocation l on l.bLocationID = t.LocationID
		inner join ConversionScripts..bLocation l on l.bLocationID = t.LocationID

    --WITH days AS (
    --    SELECT
    --        datetime AS DegreeDayDate,
    --        @baseTemp - ROUND(temp, 0) AS DegreeDays
    --    FROM OPENJSON (@json) WITH (
    --        datetime date,
    --        temp numeric(4, 1)
    --    )
    --)

  
