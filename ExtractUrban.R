# load packages
library(raster)
library(sp)
library(rgdal)
library(RSQLite)
library(dismo)

# set working directory
setwd("C:/Users/cmfmiller/Dropbox/Courses/STA 208/project/")

# load US population density shape file
s <- shapefile("C:/Users/cmfmiller/Downloads/tl_2017_us_uac10/tl_2017_us_uac10.shp") # creates a spatial polygon's data frame

# open the connection to the SQL df
fire = dbConnect(drv = SQLite(), dbname = 'FPA_FOD_20170508.sqlite')

# load full data set
fires = dbGetQuery(fire, "SELECT * 
                   FROM fires;")

# attempts to extract all points at once maxes out my memory
# split data into 100 groups to loop over extraction
groups = sort(x = kfold(fires, k = 100))

# grab only the lat and long
by_group = split(x = fires[, c("LONGITUDE", "LATITUDE")], f = as.factor(groups))

# loop to extract points
urbantype = lapply(by_group, FUN =function(x){
  points = extract(s, x, method= "simple")
  urbantype = points$UATYP10
  return(urbantype)
})

# unlist all urbantype categories
vec = unlist(urbantype)

# assign to new column of df
fires$urbantype = vec

# assign a new category to the fires outside of a designated urban region
R = is.na(fires$urbantype)
fires$urbantype[R] = "R"

# save new and improved df to file
fwrite(fires, file = "wildfires.csv")

