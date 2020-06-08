-- IMPORT ALL THE FUEL CHECK DATA. UNION INTO A SINGLE TABLE.

select * 
into dbo.Prices
from [dbo].[2016_08]
union select * from [dbo].[2016_09]
union select * from [dbo].[2016_10]
union select * from [dbo].[2016_11]
union select * from [dbo].[2016_12]
union select * from [dbo].[2017_01]
union select * from [dbo].[2017_02]
union select * from [dbo].[2017_03]
union select * from [dbo].[2017_04]
union select * from [dbo].[2017_05]
union select * from [dbo].[2017_06]
union select * from [dbo].[2017_07]
union select * from [dbo].[2017_08]
union select * from [dbo].[2017_09]
union select * from [dbo].[2017_10]
union select * from [dbo].[2017_11]
union select * from [dbo].[2017_12]
union select * from [dbo].[2018_01]
union select * from [dbo].[2018_02]
union select * from [dbo].[2018_03]
union select * from [dbo].[2018_04]
union select * from [dbo].[2018_05]
union select * from [dbo].[2018_06]
union select * from [dbo].[2018_07]
union select * from [dbo].[2018_08]
union select * from [dbo].[2018_09]
union select * from [dbo].[2018_10]
union select * from [dbo].[2018_11]
union select * from [dbo].[2018_12]
union select * from [dbo].[2019_01]

select * into #prices from Prices where FuelType = 'U91'
-- drop table #prices

-- CREATE A TABLE TO HOLD THE ALL DAILY TIME STEPS

declare @start datetime, @end datetime 
set @start = (select convert(date,min([PriceUpdatedDate])) from #prices)
set @end = (select convert(date,max([PriceUpdatedDate])) from #prices)

declare @timestep datetime
set @timestep = @start + 1
create table #timestepdaily (timestep datetime)

while @timestep <= @end
begin
	insert into #timestepdaily values (@timestep)
	-- INCREMENT TIMESTEPS BY 1 DAY
	set @timestep = dateadd(dd,1,@timestep)
end

select * from #timestepdaily
-- drop table #timestepdaily

-- Create a list of sites that sell petrol to put in a temp table.
create table #sites ([ServiceStationName] varchar(50))
insert into #sites
select distinct [ServiceStationName] from #prices
-- drop table #sites

select *
into #sites_timesteps
from #timestepdaily t
cross join #sites s

select * from #sites_timesteps order by 2,1
-- drop table #sites_timesteps

-- INSERT THE TIME STEP DATA AND PRICES INTO A REAL TABLE
select
ServiceStationName,
convert(date,timestep) as timestep,
isnull((
select top 1 price 
from  #prices p
where p.[PriceUpdatedDate] <= st.timestep
and p.[ServiceStationName] = st.ServiceStationName
order by p.[PriceUpdatedDate] desc
),0.00) as price
into dbo.PricesTimeSteps
from #sites_timesteps st
order by 1,2

-- QUERY THE DATA IN 6 MONTH CHUNKS FROM THE NEW TABLE.
-- COPY TO EXCEL, TRANSFORM TO CROSS TABLE, SAVE AS CSV.
-- EXCEL CAN ONLY HAVE 255 COLUMN HEADINGS IN A CROSS TAB. HENCE, 6 MONTH SPLITS ACROSS 2 YEARS OF DATA.

select * from [dbo].[PricesTimeSteps] where timestep between '2018-09-01' and '2019-01-31' order by ServiceStationName, timestep

select * from [dbo].[PricesTimeSteps] where timestep between '2018-03-01' and '2018-08-31' order by ServiceStationName, timestep

select * from [dbo].[PricesTimeSteps] where timestep between '2017-09-01' and '2018-02-28' order by ServiceStationName, timestep

select * from [dbo].[PricesTimeSteps] where timestep between '2017-03-01' and '2017-08-31' order by ServiceStationName, timestep

select * from [dbo].[PricesTimeSteps] where timestep between '2016-09-01' and '2017-02-28' order by ServiceStationName, timestep

