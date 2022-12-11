CREATE DATABASE Bellabeat;

CREATE TABLE dailyActivity_merged (
    Id bigint,
	ActivityDate date,
    TotalSteps int,
    TotalDistance decimal,
	TrackerDistance decimal,
    LoggedActivitiesDistance decimal,
    VeryActiveDistance decimal,
    ModeratelyActiveDistance decimal,
    LightActiveDistance decimal,
    SedentaryActiveDistance decimal,
    VeryActiveMinutes int,
    FairlyActiveMinutes int,
    LightlyActiveMinutes int,
    SedentaryMinutes int,
    Calories int
    );
	
COPY  dailyActivity_merged
FROM 'C:\Users\DELL\Documents\FitBit Fitness Tracker Data\Fitabase Data 4.12.16-5.12.16\dailyActivity_merged.csv'
DELIMITER ',' CSV 
HEADER;
	
select * from dailyActivity_merged;

CREATE TABLE sleepDay_merged (
    Id bigint,
	SleepDay timestamp,
    TotalSleepRecords int,
    TotalMinutesAsleep int,
	TotalTimeInBed int
    );

COPY  sleepDay_merged
FROM 'C:\Users\DELL\Documents\FitBit Fitness Tracker Data\Fitabase Data 4.12.16-5.12.16\sleepDay_merged.csv'
DELIMITER ',' CSV 
HEADER;

select all * from sleepDay_merged;

CREATE TABLE weightLogInfo_merged (
    Id bigint,
	Date date,
    WeightKg decimal,
    WeightPounds decimal,
	Fat int,
    BMI decimal,
    IsManualReport text,
    LogId varchar
    );

COPY  weightLogInfo_merged
FROM 'C:\Users\DELL\Documents\FitBit Fitness Tracker Data\Fitabase Data 4.12.16-5.12.16\weightLogInfo_merged.csv'
DELIMITER ',' CSV 
HEADER;

select * from weightLogInfo_merged; 

CREATE TABLE dailyCalories_merged (
    Id bigint,
	activityday date,
    Calories int
    );

COPY  dailyCalories_merged
FROM 'C:\Users\DELL\Documents\FitBit Fitness Tracker Data\Fitabase Data 4.12.16-5.12.16\dailyCalories_merged.csv'
DELIMITER ',' CSV 
HEADER;

select * from dailyCalories_merged;

--Total steps/distance/sedentaryminutes per day
select activitydate, sum(totalsteps) as steps_per_day, sum(totaldistance) distance_per_day, sum(sedentaryminutes) as sedentary_min_perday 
from dailyActivity_merged
group by 1;

-- checking for numbers of participants
SELECT count (DISTINCT id) from dailyactivity_merged;
SELECT count (DISTINCT id) from dailyCalories_merged;
SELECT count (DISTINCT id) from sleepDay_merged;
SELECT count (DISTINCT id) from weightLogInfo_merged;

--- checking start-end date
select MIN(activitydate) as start_date, MAX(activitydate) as end_date
from dailyactivity_merged;

select MIN(activityday) as start_date, MAX(activityday) as end_date
from dailyCalories_merged;

select MIN(sleepday) as start_date, MAX(sleepday) as end_date
from sleepDay_merged;

select MIN(date) as start_date, MAX(date) as end_date
from weightLogInfo_merged;
--- with this result it implyies that all data set have the same start and end date

-- no. of times users uses the fitbit tracker
select id, count(id) as total_uses
from dailyactivity_merged
group by 1;

/* classifying users by how much they wore their fitbit tracker 
active users = 21 - 31 days 
moderate users = 11 - 20 days
light users = 0 - 10 days */
select id,
count(id) as total_uses, 
case
	when count(id) between 21 and 31 then 'active users'
	when count(id) between 11 and 20 then 'moderate users'
	when count(id) between 0 and 10 then 'light users'
end usage_type
from dailyactivity_merged
group by 1
order by 2 desc;

-- average activity minutes by day of week
select "day_of_week",
	round(avg(veryactiveminutes),2) as "avg_very_activeminute",
	round(avg(fairlyactiveminutes),2) as "avg_fairly_activeminute",
	round(avg(lightlyactiveminutes),2) as "avg_lightly_activeminute",
	round(avg(sedentaryminutes),2) as "avg_sedentary_minute"
FROM (select veryactiveminutes, fairlyactiveminutes, lightlyactiveminutes, sedentaryminutes,
	  case
	  when extract(isodow from activitydate)= 1 then 'monday'
	  when extract(isodow from activitydate)= 2 then 'tuesday'
	  when extract(isodow from activitydate)= 3 then 'wednesday'
	  when extract(isodow from activitydate)= 4 then 'thursday'
	  when extract(isodow from activitydate)= 5 then 'friday'
	  when extract(isodow from activitydate)= 6 then 'saturday'
	  when extract(isodow from activitydate)= 7 then 'sunday'
end as "day_of_week"
	  from dailyactivity_merged) as x
 group by 1;
 
/* user type based on total steps
classifying users by the daily average steps, using(from 0-4999=sedentary, =>5000 - 7499=lightly active, =>7500 - 9999=fairly active, =>10000=very active)*/
select id,
(round(avg(totalsteps),2)) as avg_step, 
case
	when avg(totalsteps) < 5000 then 'sedentary'
	when avg(totalsteps) between 5000 and 7499 then 'lightly activity'
	when avg(totalsteps) between 7500 and 9999 then 'fairly activity'
	when avg(totalsteps) >= 10000 then 'very active'
end as user_steps_type
from dailyactivity_merged as y
group by 1
order by 2 DESC;

-- average steps, average distance, average calories by day of week
select day_of_week, 
	round(avg(totalsteps),2) as "avg_steps",
	round(avg(totaldistance),2) as "avg_distance",
	round(avg(calories),2) as "avg_calories"
from (select totalsteps, totaldistance, calories,
	case
	 when extract(isodow from activitydate)= 1 then 'monday'
	  when extract(isodow from activitydate)= 2 then 'tuesday'
	  when extract(isodow from activitydate)= 3 then 'wednesday'
	  when extract(isodow from activitydate)= 4 then 'thursday'
	  when extract(isodow from activitydate)= 5 then 'friday'
	  when extract(isodow from activitydate)= 6 then 'saturday'
	  when extract(isodow from activitydate)= 7 then 'sunday'
end as "day_of_week" 
	 from dailyactivity_merged) as z
	 group by 1
	 order by avg_calories DESC;
	 
-- average Sleep Time and Awake Time per day of week 
select day_of_week,
	count(id) as days_observed, 
	round(avg(totalminutesasleep),2) as "avg_min_sleep", 
	round(avg(totaltimeinbed),2) as "avg_time_in_bed",
	round(avg(totaltimeinbed - totalminutesasleep),2) as "avg_time_awake"
from (select id, totalsleeprecords, totalminutesasleep, totaltimeinbed,
	  case
	  when extract(isodow from sleepday)= 1 then 'monday'
	  when extract(isodow from sleepday)= 2 then 'tuesday'
	  when extract(isodow from sleepday)= 3 then 'wednesday'
	  when extract(isodow from sleepday)= 4 then 'thursday'
	  when extract(isodow from sleepday)= 5 then 'friday'
	  when extract(isodow from sleepday)= 6 then 'saturday'
	  when extract(isodow from sleepday)= 7 then 'sunday'
end as "day_of_week" 
	  from sleepDay_merged) as w
	  GROUP by 1
	  order by avg_time_awake DESC;
	  
-- average total minutes asleep, steps, calories
select id, 
	round(avg(calories),2) as avg_calories, 
	round(avg(totalsteps),2) as avg_total_steps, 
	round(avg(totalminutesasleep),2) as avg_total_minutes_asleep 
from dailyactivity_merged
join sleepDay_merged using(id)
where sleepDay_merged is not null
group by 1;
-- no correlation is found btw average total minutes of sleep and average calories

-- average weight vs non sedentry minutes
select id, 
	round(avg(lightlyactiveminutes),2) as avg_lightly,
	round(avg(fairlyactiveminutes),2) as avg_fairly,
	round(avg(veryactiveminutes),2) as avg_very,
	round(avg(lightlyactiveminutes) + avg(fairlyactiveminutes) + avg(veryactiveminutes),2) as avg_totalminutes,
	round(avg(weightkg),2) as avg_weight
from dailyactivity_merged
join weightLogInfo_merged using(id)
group by 1;
/* users with low exercise shows overweight
users with weight of <70 kg had been more active */