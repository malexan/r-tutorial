library(nycflights13)
data("airlines", "airports", "flights", "planes", "weather",
     package = "nycflights13")

# library(RODBC)
# Installation of ODBC-driver for SQLite
# http://www.ch-werner.de/sqliteodbc/html/index.html
# Installation on Linux is ok, but failed to work properly

### Creating SQLite file
library(RSQLite)
db <- dbConnect(SQLite(), dbname="db/db1.db")
dbWriteTable(db, "weather", as.data.frame(weather))
dbWriteTable(db, "airports", as.data.frame(airports))
dbWriteTable(db, "airlines", as.data.frame(airlines))
dbWriteTable(db, "flights", as.data.frame(flights))
dbWriteTable(db, "planes", as.data.frame(planes))
dbDisconnect(db)
rm(list=ls())


# SQL statements

# Load data from DB and analyze

# Analyze data inside of DB
# Oracle is udner construction: https://github.com/hadley/dplyr/pull/250

# Connection for RSQLite
library(RSQLite)
db <- dbConnect(SQLite(), dbname="db/db1.db")
dbListTables(db)
dbListFields(db, 'planes')
dbListFields(db, 'flights')
dbListFields(db, 'airlines')



### From Hadley's dplyr tutorial
## Find all flights to SFO or OAK
result <- dbSendQuery(db, "SELECT * FROM flights WHERE dest IN ('SFO', 'OAK')")
fetch(result, 10)
sfooak <- fetch(result, -1)
dbClearResult(result)
rm(sfooak)
## Find all flights in January
## Find all flights delayed by more than an hour
## Find all flights that departed between midnight and 5am.
## Find all flights where the arrival delay was more than twice the departure delay

result <- dbSendQuery(db, "SELECT * FROM flights WHERE month = 1")
r1 <- fetch(result, -1)
dim(r1)
head(r1)
dbClearResult(result)
rm(r1)

result <- dbSendQuery(db, "SELECT * FROM flights WHERE arr_delay > 2 * dep_delay")
r1 <- fetch(result, -1)
dim(r1)
head(r1)
dbClearResult(result)
rm(r1)

## Carrieres' preferences in plane manufacturers
dbListFields(db, 'airlines')
dbListFields(db, 'planes')
dbListFields(db, 'flights')

result <- dbSendQuery(db, 
"SELECT name, manufacturer, COUNT(*) AS cnt FROM planes
INNER JOIN flights USING(tailnum)
INNER JOIN airlines USING(carrier)
GROUP BY name, manufacturer")

## The most favorite plane manufacturers of carriers
result <- dbSendQuery(db, 
"SELECT name, manufacturer, MAX(cnt) FROM
(
SELECT name, manufacturer, COUNT(*) AS cnt FROM planes
INNER JOIN flights USING(tailnum)
INNER JOIN airlines USING(carrier)
GROUP BY name, manufacturer
)
GROUP BY name
")

dbDisconnect(db)
rm(db)
rm(result)

# Now the same tasks with dplyr
library(dplyr)
db <- src_sqlite("db/db1.db", create = F)
airlines <- tbl(db, "airlines")
planes <- tbl(db, "planes")
flights <- tbl(db, "flights")
planes

## Find all flights to SFO or OAK
flights %>%
  select(dest %in% c('SFO', 'OAK'))

## Find all flights in January
flights %>%
  select(month == 1)

## Find all flights where the arrival delay was more than twice the departure delay
flights %>%
  select(arr_delay > 2 * dep_delay)


## Carrieres' preferences in plane manufacturers
planes %>% 
  inner_join(flights, by = 'tailnum') %>%
  inner_join(airlines, by = 'carrier') %>% 
  group_by(name, manufacturer) %>%
  summarise(cnt = n())

## The most favorite plane manufacturers of carriers
x <- planes %>% 
  inner_join(flights, by = 'tailnum') %>%
  inner_join(airlines, by = 'carrier') %>% 
  group_by(name, manufacturer) %>%
  summarise(cnt = n()) %>%
  group_by(name) 

# Possible bug in dplyr!
x1 <- collect(x)
y <- filter(x, row_number(desc(cnt)) <= 1)
x %>% filter(row_number(desc(cnt)) <= 1)
y <- x %>% filter(cnt == max(cnt))
