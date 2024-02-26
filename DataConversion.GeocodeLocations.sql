

--select *
--from bLocation
--where Address1 = '31 Wright Rd' and city = 'Hollister' --429345

--exec DataConversion.GeocodeLocations 429345


CREATE OR ALTER PROCEDURE DataConversion.GeocodeLocations   
    @bLocationID int    
	,@UserName varchar(255)
AS

	declare @Address nvarchar(500)
			,@Header nvarchar(100)
			,@Latitude int
			,@Longitude int

	select @Address = 'street=' + Address1 + '&city=' + city + '&state=' + state + '&postcode=' + zipcode + '&country=US'
	from bLocation
	where bLocationID = @bLocationID
	
	set @Header = '@{' + '''' + 'Authorization' + '''' + ' = ' + '''' + '504FCAC9ECD58E4DA3FA4011F27A17EB' + '''' + '}'
	   	  

	/* Build API call */   
    DECLARE @url varchar(255) = CONCAT(
        'https://pcmiler.alk.com/APIs/REST/v1.0/Service.svc/locations',
		'?',
        @Address
    );   
	
    DECLARE @cmd varchar(512) = CONCAT(		
       ' powershell -command "',		
		' (Invoke-RestMethod -Method GET -Headers ' + @Header + ' -Uri ',        
		'''',
        @url,     		
		'''',      		        
        ').Coords | ConvertTo-Json'        
		,'"'          
    );

	--print @cmd

    DECLARE @result TABLE (output varchar(MAX));

    /* Make the HTTP call using Powershell */
    INSERT @result
    EXEC xp_cmdshell @cmd	

    /* Process the resulting JSON and insert into import table */
    DECLARE @json varchar(MAX) = (
        (SELECT STRING_AGG(CAST(output AS varchar(MAX)), CHAR(10))
        FROM @result
        WHERE output IS NOT NULL) 
    );
				

	SELECT @Latitude = Lat * 1000000, @Longitude = Lon * 1000000		
	FROM OPENJSON(@json) 
	WITH (Lat decimal(19,6), Lon decimal(19,6))

	exec UpdatebLocationLatLong  @bLocationID, @Latitude, @Longitude, @UserName

		

  
