#installing packages and opening libraries
install.packages("ggplot2")
install.packages("tidyr")
install.packages("readr")
install.packages("dplyr")
install.packages("skimr")
install.packages("here")
install.packages("janitor")
install.packages("ggrepel")
install.packages("lubridate")
install.packages("ggpubr")
library(ggplot2)
library(tidyr)
library(readr)
library(dplyr)
library(skimr)
library(here)
library(janitor)
library(ggrepel)
library(lubridate)
library(ggpubr)
library(tidyverse)

#importing .csv files into Global environment
Dactivity <- read.csv("C:/Users/DELL/Documents/FitBit Fitness Tracker Data/Fitabase Data 4.12.16-5.12.16/dailyActivity_merged.csv")

sleep_day <- read.csv("C:/Users/DELL/Documents/FitBit Fitness Tracker Data/Fitabase Data 4.12.16-5.12.16/sleepDay_merged.csv")

hourly_calories <- read.csv("C:/Users/DELL/Documents/FitBit Fitness Tracker Data/Fitabase Data 4.12.16-5.12.16/hourlyCalories_merged.csv")

#taking a look/preview at the data sets
View(Dactivity)
View(sleep_day)
head(Dactivity)
head(sleep_day)
str(Dactivity)
str(sleep_day)
colnames(Dactivity)
colnames(sleep_day)

#checking the numbers of user and cleaning
n_unique(Dactivity$Id) #to know how many unique users are per data frame 
n_unique(sleep_day$Id)
n_unique(hourly_calories$Id)
clean_names(Dactivity)
clean_names(sleep_day)
clean_names(hourly_calories)

#checking for duplicates
sum(duplicated(Dactivity))
sum(duplicated(sleep_day))
sum(duplicated(hourly_calories))

#removing duplicates and N/A
sleep_day <- sleep_day %>% 
  distinct() %>% 
  drop_na()

Dactivity <- Dactivity %>% 
  distinct() %>% 
  drop_na()

hourly_calories <- hourly_calories %>% 
  distinct() %>% 
  drop_na()

#verify that duplicates have been removed
sum(duplicated(Dactivity))
sum(duplicated(sleep_day))
sum(duplicated(hourly_calories))

#renaming columns to ensure same format
Dactivity <- rename_with(Dactivity, tolower)
sleep_day <- rename_with(sleep_day, tolower)
hourly_calories <- rename_with(hourly_calories, tolower)

#ensuring consistency in date and time columns 
Dactivity <- Dactivity %>% 
  rename(date = activitydate) %>% 
  mutate(date = as_date(date, format = "%m/%d/%Y"))

sleep_day <- sleep_day %>% 
  rename(date = sleepday) %>%
  mutate(date = as_date(date, format = "%m/%d/%Y %I:%M:%S %p", tz=Sys.timezone()))

hourly_calories <- hourly_calories %>% 
  rename(date_time = activityhour) %>% 
  mutate(date_time = as.POSIXct(date_time, format = "%m/%d/%Y %I:%M:%S %p", tz=Sys.timezone()))

head(Dactivity)
head(sleep_day)
head(hourly_calories)

#merging two data set as one 
Bellabeat <- merge(Dactivity, sleep_day, by = c("id", "date"))
View(Bellabeat)
glimpse(Bellabeat)

#checking for n/a
colSums(is.na(Bellabeat)) #or
sum(is.na(Bellabeat))

#checking for blank space
is.null(Bellabeat)

#Analyze and Shear Phase 
## correlation between Total steps vs sedentary minutes and Total minutes as sleep vs total minutes in bed
Bellabeat %>% 
  select(totalsteps, totaldistance, sedentaryminutes, calories) %>% 
  summary()

Bellabeat %>% 
  select(totalsleeprecords, totalminutesasleep, totaltimeinbed) %>% 
  summary()

ggarrange(
  ggplot(data = Bellabeat, mapping = aes(x = totalsteps, y = sedentaryminutes)) + 
    geom_jitter() +
    geom_smooth(color = "red") +
    labs(title = "TotalSteps vs SedentaryMinutes", x = "TotalSteps", y = "SedentaryMinutes") +
    theme(panel.background = element_blank(), plot.title = element_text(size = 14)),
  ggplot(data = Bellabeat, mapping = aes(x = totalminutesasleep, y = totaltimeinbed)) + 
    geom_jitter() +
    geom_smooth(color = "red") +
    labs(title = "TotalMinutesAsleep vs TotalTimeinBed", x = "TotalMinutesAsleep", y = "TotalTimeinBed") +
    theme(panel.background = element_blank(), plot.title = element_text(size = 14))
)

#average daily steps by user
daily_average <- Bellabeat %>% 
  group_by(id) %>% 
  summarise(mean_of_dailySteps = mean(totalsteps), mean_of_dailyCalories = mean(calories), mean_of_dailySleep = mean(totalminutesasleep))

head(daily_average)

#ensuring consistency/same format
daily_average <- rename_with(daily_average, tolower)
head(daily_average)

#classifying users by the daily average steps, using(from 0-4999=sedentary, =>5000 - 7499=lightly active, =>7500 - 9999=fairly active, =>10000=very active)
user_type <- daily_average %>% 
  mutate(user_type = case_when(
    mean_of_dailysteps <= 5000 ~ "sedentary",
    mean_of_dailysteps >= 5001 & mean_of_dailysteps < 7500 ~ "lightly active",
    mean_of_dailysteps >= 7501 & mean_of_dailysteps < 10000 ~ "fairly active",
    mean_of_dailysteps >= 10001 ~ "very active"
  ))

head(user_type)

#classifying users by daily average steps
user_type_percent <- user_type %>% 
  group_by(user_type) %>% 
  summarise(total = n()) %>% 
  mutate(totals = sum(total)) %>% 
  group_by(user_type) %>% 
  summarise(total_percent = total/totals) %>% 
  mutate(labels = scales::percent(total_percent))
user_type_percent$user_type <- factor(user_type_percent$user_type, levels = c("very active", "fairly active", "lightly active", "sedentary"))

head(user_type_percent)

### user type distribution
ggplot(data = user_type_percent, mapping = aes(x = "", y = total_percent, fill = user_type)) +
  geom_bar(stat = "identity", width = 1) +
  coord_polar("y", start = 0) +
  theme_minimal() +
  theme(axis.title.x = element_blank(), axis.title.y = element_blank(), panel.border = element_blank(), panel.grid = element_blank(), axis.ticks = element_blank(), axis.text.x = element_blank(), plot.title = element_text(hjust = 0.5, size = 14, face = "bold")) + 
  scale_fill_manual(values = c("#85e085", "#e6e600", "#ffd480", "#ff8080")) +
  geom_text(aes(label = labels), position = position_stack(vjust = 0.5)) + 
  labs(title = "user type distribution")

#alternatively using a Donut chart
ggplot(data = user_type_percent, aes(x= 2, y=total_percent, fill = user_type)) +
  geom_bar(stat = "identity") + 
  coord_polar("y", start = -1) +
  geom_text(aes(label = paste(total_percent, "%", sep = "")), col="black") +
  ggtitle("user distribution") +
  theme_void() +
  theme(legend.justification = c("right", "top")) +
  scale_fill_manual(values = c("#BE9E6F", "#2A603B","#ffd480", "#ff8080")) +
  xlim(0.5, 2.5) +
  theme(plot.title = element_text(hjust = 0.5, size = 1)) +
  theme(plot.title = element_text(face = "bold")) +
  theme(plot.background = element_rect(fill = "#D9DFE0"))

#hourly calories burnt throughout the day
hourly_calories <- hourly_calories %>% 
  separate(date_time, into = c("date", "time"), sep = " ") %>% 
  mutate(date = ymd(date)) #separating date and time

hourly_calories %>% 
  group_by(time) %>% 
  summarize(average_calories = mean(calories)) %>% 
  ggplot() +
  geom_col(mapping = aes(x = time, y = average_calories, fill = average_calories)) +
  labs(title = "hourly calories throughout the day") +
  scale_fill_gradient(low = "green", high = "red") +
  theme(axis.text.x = element_text(angle = 90))

#steps and minutes asleep per weekday
weekday_steps_sleep <- Bellabeat %>% 
  mutate(weekday = weekdays(date))
weekday_steps_sleep$weeday <- ordered(weekday_steps_sleep$weekday, levels = c("monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"))

weekday_steps_sleep <- weekday_steps_sleep %>% 
  group_by(weekday) %>% 
  summarize(daily_steps = mean(totalsteps), daily_sleep = mean(totalminutesasleep))

ggarrange(
  ggplot(data = weekday_steps_sleep, mapping = aes(x = weekday, y = daily_steps)) + 
    geom_col() +
    geom_hline(yintercept = 7500, color = 'red') +
    labs(title = "daily step per weekday", x="weekday",y="daily_steps") +
    theme(axis.title.x = element_text(angle = 45, vjust = 0.5, hjust = 1)), 
  ggplot(data = weekday_steps_sleep, aes(x = weekday, y = daily_sleep)) +
    geom_col() +
    geom_hline(yintercept = 480, color = 'red') +
    labs(title = "minutes as sleep per weekday", x = "weekday", y = "daily_sleep") +
    theme(axis.text.x = element_text(angle = 45, vjust = 0.5, hjust = 1))
)
