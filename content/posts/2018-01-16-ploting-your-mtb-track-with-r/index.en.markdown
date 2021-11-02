---
title: Ploting your MTB track with R
author: Giuliano Sposito
date: '2018-01-16'
slug: 'ploting-your-mtb-track-with-r'
categories:
  - data science
tags:
  - rstats
  - gps
  - gpx
  - strava
  - runtastic
  - tcx
  - workout
subtitle: ''
lastmod: '2021-11-02T12:56:27-03:00'
authorLink: ''
description: ''
hiddenFromHomePage: no
hiddenFromSearch: no
featuredImage: 'images/mtb_cover.jpg'
featuredImagePreview: 'images/mtb_cover.jpg'
toc:
  enable: yes
math:
  enable: no
lightgallery: no
license: ''
---
<script src="{{< blogdown/postref >}}index.en_files/kePrint/kePrint.js"></script>
<link href="{{< blogdown/postref >}}index.en_files/lightable/lightable.css" rel="stylesheet" />
<script src="{{< blogdown/postref >}}index.en_files/kePrint/kePrint.js"></script>
<link href="{{< blogdown/postref >}}index.en_files/lightable/lightable.css" rel="stylesheet" />


In this [RNotebook](http://rmarkdown.rstudio.com/r_notebooks.html) we'll read a [TCX](https://en.wikipedia.org/wiki/Training_Center_XML) and [GPX](https://en.wikipedia.org/wiki/GPS_Exchange_Format) files, used to track physical training and exercises evolving GPS and paths used by some workout Mobile Apps and Devices. Particularly we'll will process one TCX file containing a MTB ride mine and transforming the a useful R data.frame ploting the ride track over a map.

<!--more-->

### Tracking Files[^1]

There are two popular file format to track workouts and routes through GPS devices: GPX and TCX.

**GPX** is an [XML](https://en.wikipedia.org/wiki/XML) format designed specifically for saving GPS track, way point and route data. It is increasingly used by GPS programs because of its flexibility as an XML schema. More information can be found on the official [GPX website](http://www.topografix.com).

The **TCX** format is also an [XML](https://en.wikipedia.org/wiki/XML) format, but was created by [Garmin](http://www.garmin.com) to include additional data with each track point (e.g. heart rate and cadence) as well as a user defined organizational structure. The format appears to be primarily used by Garmin's fitness oriented GPS devices. The TCX schema is hosted by [Garmin](http://www.garmin.com).

Many of the dozens of other formats can be converted into GPX or TCX formats using [GPSBabel](http://www.gpsbabel.org).


### Reading a TCX File

Lets see what is the basic format of one [TCX file](https://en.wikipedia.org/wiki/Training_Center_XML), once it's a [XML file](https://en.wikipedia.org/wiki/XML) we just open it in a text editor to look at. I downloaded one from a MTB ride that I did using a [FitBit Charge 2](https://www.fitbit.com/charge2), plus an iPhone as tracker.


```xml

<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<TrainingCenterDatabase xmlns="http://www.garmin.com/xmlschemas/TrainingCenterDatabase/v2">
    <Activities>
        <Activity Sport="Biking">
            <Id>2018-01-13T08:15:42.000-02:00</Id>
            <Lap StartTime="2018-01-13T08:15:42.000-02:00">
                <TotalTimeSeconds>12672.0</TotalTimeSeconds>
                <DistanceMeters>42274.04000000001</DistanceMeters>
                <Calories>2315</Calories>
                <Intensity>Active</Intensity>
                <TriggerMethod>Manual</TriggerMethod>
                <Track>
                    <Trackpoint>
                        <Time>2018-01-13T08:15:42.000-02:00</Time>
                        <Position>
                            <LatitudeDegrees>-22.703736066818237</LatitudeDegrees>
                            <LongitudeDegrees>-46.75607788562775</LongitudeDegrees>
                        </Position>
                        <AltitudeMeters>684.7</AltitudeMeters>
                        <DistanceMeters>0.0</DistanceMeters>
                        <HeartRateBpm>
                            <Value>104</Value>
                        </HeartRateBpm>
                    </Trackpoint>
                    <Trackpoint>
                        <Time>2018-01-13T08:15:47.000-02:00</Time>
                        <Position>
                            <LatitudeDegrees>-22.703736066818237</LatitudeDegrees>
                            <LongitudeDegrees>-46.75607788562775</LongitudeDegrees>
                        </Position>
                        <AltitudeMeters>684.7</AltitudeMeters>
                        <DistanceMeters>6.240000000000001</DistanceMeters>
                        <HeartRateBpm>
                            <Value>102</Value>
                        </HeartRateBpm>
                    </Trackpoint>
                    
                    ...
                    
            </Lap>
            <Creator xsi:type="Device_t" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                <Name>Fitbit Charge 2</Name>
                <UnitId>0</UnitId>
                <ProductID>0</ProductID>
            </Creator>
        </Activity>
    </Activities>
</TrainingCenterDatabase>

```

As we see, it's a time-date indexed XML file with some structuring to define `activities` and inside them `activity` with `summary informations`, `laps` and `track points`. 

Let's extract the available tracking data (date-time, latitude and longitude coords, altitude and heart beat) from this file, using the [XML Package](https://cran.r-project.org/web/packages/XML/index.html). Because with are just interested in the GPS data we can use [XPath Query](https://www.w3schools.com/xml/xpath_intro.asp) directly to take the track points data through all the XML file. 



```r
# setup
library(XML)
library(lubridate)
library(tidyverse)

# Reading the XML file
file <- htmlTreeParse(file = "data/11654237848.tcx", # file downloaded from FitBit
                       error = function (...) {},
                       useInternalNodes = TRUE)

# XML nodes names to read 
features <- c("time", "position/latitudedegrees", "position/longitudedegrees",
              "altitudemeters", "distancemeters", "heartratebpm/value")

# building the XPath query adding the "father node"
xpath_feats <- paste0("//trackpoint/", features)

# for each of the XPaths let's extract the value of the node
xpath_feats %>%
  # the map returns a list with vector of the values for each xpath
  map(function(p){xpathSApply(file, path = p, xmlValue)}) %>%
  # setting a shorter name for them and collapsing the list in to a tibble
  setNames(c("dt", "lat", "lon", "alt", "dist", "hbpm")) %>%
  as_tibble() %>% 
  # Lets correct the data type because everthing return as char
  mutate_at(vars(lat:dist), as.numeric) %>% # numeric values
  mutate(
    dt = lubridate::as_datetime(dt), # date time
    hbpm  = as.integer(hbpm), # integer (heart beat per minutes)
    # we'll build other two features:  
    tm.prev.s = c(0, diff(dt)), # time (s) from previous track point
    tm.cum.min  = round(cumsum(tm.prev.s)/60,1) # cumulative time (min)
  ) -> track

# lets see the final format
track %>% 
  head(10) %>% 
  knitr::kable() %>% 
  kableExtra::kable_styling(font_size = 9)
```

<table class="table" style="font-size: 9px; margin-left: auto; margin-right: auto;">
 <thead>
  <tr>
   <th style="text-align:left;"> dt </th>
   <th style="text-align:right;"> lat </th>
   <th style="text-align:right;"> lon </th>
   <th style="text-align:right;"> alt </th>
   <th style="text-align:right;"> dist </th>
   <th style="text-align:right;"> hbpm </th>
   <th style="text-align:right;"> tm.prev.s </th>
   <th style="text-align:right;"> tm.cum.min </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> 2018-01-06 10:34:08 </td>
   <td style="text-align:right;"> -22.70375 </td>
   <td style="text-align:right;"> -46.75608 </td>
   <td style="text-align:right;"> 683.59 </td>
   <td style="text-align:right;"> 0.00 </td>
   <td style="text-align:right;"> 111 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 0.0 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2018-01-06 10:34:12 </td>
   <td style="text-align:right;"> -22.70375 </td>
   <td style="text-align:right;"> -46.75608 </td>
   <td style="text-align:right;"> 683.59 </td>
   <td style="text-align:right;"> 0.02 </td>
   <td style="text-align:right;"> 111 </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:right;"> 0.1 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2018-01-06 10:34:13 </td>
   <td style="text-align:right;"> -22.70375 </td>
   <td style="text-align:right;"> -46.75608 </td>
   <td style="text-align:right;"> 683.30 </td>
   <td style="text-align:right;"> 0.05 </td>
   <td style="text-align:right;"> 111 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 0.1 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2018-01-06 10:34:14 </td>
   <td style="text-align:right;"> -22.70375 </td>
   <td style="text-align:right;"> -46.75609 </td>
   <td style="text-align:right;"> 683.59 </td>
   <td style="text-align:right;"> 0.11 </td>
   <td style="text-align:right;"> 111 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 0.1 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2018-01-06 10:34:15 </td>
   <td style="text-align:right;"> -22.70374 </td>
   <td style="text-align:right;"> -46.75610 </td>
   <td style="text-align:right;"> 684.09 </td>
   <td style="text-align:right;"> 0.79 </td>
   <td style="text-align:right;"> 111 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 0.1 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2018-01-06 10:34:16 </td>
   <td style="text-align:right;"> -22.70373 </td>
   <td style="text-align:right;"> -46.75611 </td>
   <td style="text-align:right;"> 684.09 </td>
   <td style="text-align:right;"> 2.37 </td>
   <td style="text-align:right;"> 111 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 0.1 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2018-01-06 10:34:17 </td>
   <td style="text-align:right;"> -22.70372 </td>
   <td style="text-align:right;"> -46.75611 </td>
   <td style="text-align:right;"> 684.59 </td>
   <td style="text-align:right;"> 4.08 </td>
   <td style="text-align:right;"> 111 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 0.1 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2018-01-06 10:34:18 </td>
   <td style="text-align:right;"> -22.70371 </td>
   <td style="text-align:right;"> -46.75609 </td>
   <td style="text-align:right;"> 685.20 </td>
   <td style="text-align:right;"> 5.94 </td>
   <td style="text-align:right;"> 110 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 0.2 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2018-01-06 10:34:19 </td>
   <td style="text-align:right;"> -22.70369 </td>
   <td style="text-align:right;"> -46.75608 </td>
   <td style="text-align:right;"> 685.50 </td>
   <td style="text-align:right;"> 7.83 </td>
   <td style="text-align:right;"> 110 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 0.2 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2018-01-06 10:34:20 </td>
   <td style="text-align:right;"> -22.70367 </td>
   <td style="text-align:right;"> -46.75607 </td>
   <td style="text-align:right;"> 685.10 </td>
   <td style="text-align:right;"> 9.80 </td>
   <td style="text-align:right;"> 110 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 0.2 </td>
  </tr>
</tbody>
</table>

With the data set in hand, we can use the info, for examplar to plot the _heart beat_ and _altitude_.


```r
library(ggplot2)

ggplot(track, aes(x=dt, y=hbpm)) + 
  geom_line(colour="red") + theme_bw() + ylim(0,max(track$hbpm))
```

<img src="{{< blogdown/postref >}}index.en_files/figure-html/hearBeatPlot-1.png" width="672" />



```r
ggplot(track) +
  geom_area(aes(x = dt, y = alt), fill="blue", stat="identity") +
  theme_bw() 
```

<img src="{{< blogdown/postref >}}index.en_files/figure-html/plotAlt-1.png" width="672" />


### Ploting the track

We can take the latitude and longitude coordenates extract from TCX and plot the path executed during this ride. This is pretty straighforward using `geom_path()`in `ggplot2`.



```r
# ploting latitude in N/S orietation and lon as E/L orientation
ggplot(track, aes(x=lon, y=lat)) +
  geom_path(aes(colour=alt), size=1.2) + # ploting alt as color reference
  scale_colour_gradientn(colours = terrain.colors(10)) + # color scale
  coord_fixed() + # to keep the aspect ratio
  theme_void() # removint axis
```

<img src="{{< blogdown/postref >}}index.en_files/figure-html/plotTrack-1.png" width="672" />


That's cool, we extract the GPS path from TCX file and plot them with a couple of lines, just remaining plot over a map, and this is easy too, using `ggmap`package.


### Ploting over a map

The [ggmap R Package](https://cran.r-project.org/web/packages/ggmap/index.html) is a collection of functions to visualize spatial data and models on top of static maps from various online sources (e.g Google Maps and Stamen Maps). It includes tools common to those tasks, including functions for geolocation and routing.

The package uses some providers to get a "background" image to be used as base map, also maps the scale of the image to the appropriate lat/lon coordenates.



```r
library(ggmap)

# first we define a "box" based on lats and lons that will ploted over
# the make_bbox build it.
bbox <- make_bbox(lon = track$lon, lat=track$lat, f=.1)

# after that we ask for a map containing this box to one of the providers
# in this case we'll ask for google maps a 'terrain map'
gmap <- get_map( location=bbox, maptype = "terrain", source="google")

# we can see the map obtained
ggmap(gmap)
```

<img src="{{< blogdown/postref >}}index.en_files/figure-html/mapBackground-1.png" width="672" />


Once with the map background in hands, we just plot the track over it, changing the color scale to improve the contrast.



```r
# now the ggmap is the base o ggplot
ggmap(gmap) +
  # ploting the path using lon and lat as coordenates and alt as color
  geom_path(data=track, aes(x=lon, y=lat, colour=alt), size=1.2) + 
  scale_colour_gradientn(colours = topo.colors(10)) + # color scale
  coord_fixed() + # to keep the aspect ratio
  theme_void() # removint axis
```

<img src="{{< blogdown/postref >}}index.en_files/figure-html/plotOverMap-1.png" width="672" />

### Conclusion

As we saw, it's pretty straightforward to get the data in the XML and transform them in a useful R data frame. Obviously if the XML was more complicated, with several activities and laps, we should handle this info if we want keep these informations before read the `trackpoints`. The data frame with track points would gain `activity.id` and `lap.id` columns. The use of `ggmap` is very helpful to use maps and gglot together.

### Appendix: Reading a GPX file

Basically, as we using XPath to get the data points, reading a GPX file is pretty the same, let's look the structure of one file exported from [Runtastic website](http://www.runtastic.com)

```xml

<?xml version="1.0" encoding="UTF-8"?>
<gpx version="1.1" creator="Runtastic: Life is short - live long, http://www.runtastic.com" xsi:schemaLocation="http://www.topografix.com/GPX/1/1
                                http://www.topografix.com/GPX/1/1/gpx.xsd
                                http://www.garmin.com/xmlschemas/GpxExtensions/v3
                                http://www.garmin.com/xmlschemas/GpxExtensionsv3.xsd
                                http://www.garmin.com/xmlschemas/TrackPointExtension/v1
                                http://www.garmin.com/xmlschemas/TrackPointExtensionv1.xsd" xmlns="http://www.topografix.com/GPX/1/1" xmlns:gpxtpx="http://www.garmin.com/xmlschemas/TrackPointExtension/v1" xmlns:gpxx="http://www.garmin.com/xmlschemas/GpxExtensions/v3" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <metadata>
    <desc>Ate o Barracao de Itapira. Volta pelo Jardim Vitoria atras do Cristo e Faz. Palmeiras.</desc>
    <copyright author="www.runtastic.com">
      <year>2017</year>
      <license>http://www.runtastic.com</license>
    </copyright>
    <link href="http://www.runtastic.com">
      <text>runtastic</text>
    </link>
    <time>2017-06-11T11:45:00.000Z</time>
  </metadata>
  <trk>
    <link href="http://www.runtastic.com/sport-sessions/1698893337">
      <text>Visit this link to view this activity on runtastic.com</text>
    </link>
    <trkseg>
      <trkpt lon="-46.7560615539550781" lat="-22.7035655975341797">
        <ele>677.462890625</ele>
        <time>2017-06-11T11:45:00.000Z</time>
      </trkpt>
      <trkpt lon="-46.7560310363769531" lat="-22.7035102844238281">
        <ele>677.3987426757812</ele>
        <time>2017-06-11T11:45:02.000Z</time>
      </trkpt>
      
      ...
      
      </trkseg>
  </trk>
</gpx>

```

Basically it's about same, with a metadata in the beginning and the `track points` are in the nodes `trkpt`, but the struct is different. The GPS coords are `attributes` of these nodes while `elevation` and `time` are sub-nodes in the value. We'll have to use XPath different to get the value and the attributes.



```r
# reading the xml file download from runtastic
file <- htmlTreeParse(file = "./data/runtastic_20170611_1134_Cycling.gpx",
                      error = function (...) {},
                      useInternalNodes = TRUE)

# reading the ATTRIBUTES of 'trkpt' nodes
coords <- xpathSApply(file, path = "//trkpt", xmlAttrs) # <- look parameter xmlAttrs
lat <- as.numeric(coords["lat", ])
lon <- as.numeric(coords["lon", ])

# reading node values
ele <- as.numeric(xpathSApply(file, path = "//trkpt/ele", xmlValue)) # <- look parameter xmlValue
dt <- lubridate::as_datetime(xpathSApply(file, path = "//trkpt/time", xmlValue)) # <- look parameter xmlValue

# buiding the data frame
tibble(
  dt = dt,
  lat = lat,
  lon = lon, 
  alt = ele
) %>% mutate(
  tm.prev.s = c(0, diff(dt)), # time (s) from previous track point
  tm.cum.min  = round(cumsum(tm.prev.s)/60,1) # cumulative time (min)
) -> gpx.track

gpx.track %>% 
  head(10) %>% 
  knitr::kable() %>% 
  kableExtra::kable_styling(font_size = 9)
```

<table class="table" style="font-size: 9px; margin-left: auto; margin-right: auto;">
 <thead>
  <tr>
   <th style="text-align:left;"> dt </th>
   <th style="text-align:right;"> lat </th>
   <th style="text-align:right;"> lon </th>
   <th style="text-align:right;"> alt </th>
   <th style="text-align:right;"> tm.prev.s </th>
   <th style="text-align:right;"> tm.cum.min </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> 2017-06-11 11:45:00 </td>
   <td style="text-align:right;"> -22.70357 </td>
   <td style="text-align:right;"> -46.75606 </td>
   <td style="text-align:right;"> 677.4629 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 0.0 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2017-06-11 11:45:02 </td>
   <td style="text-align:right;"> -22.70351 </td>
   <td style="text-align:right;"> -46.75603 </td>
   <td style="text-align:right;"> 677.3987 </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:right;"> 0.0 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2017-06-11 11:45:05 </td>
   <td style="text-align:right;"> -22.70347 </td>
   <td style="text-align:right;"> -46.75600 </td>
   <td style="text-align:right;"> 677.3459 </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:right;"> 0.1 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2017-06-11 11:45:08 </td>
   <td style="text-align:right;"> -22.70337 </td>
   <td style="text-align:right;"> -46.75598 </td>
   <td style="text-align:right;"> 677.2225 </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:right;"> 0.1 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2017-06-11 11:45:10 </td>
   <td style="text-align:right;"> -22.70330 </td>
   <td style="text-align:right;"> -46.75596 </td>
   <td style="text-align:right;"> 677.0735 </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:right;"> 0.2 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2017-06-11 11:45:13 </td>
   <td style="text-align:right;"> -22.70319 </td>
   <td style="text-align:right;"> -46.75595 </td>
   <td style="text-align:right;"> 676.7396 </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:right;"> 0.2 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2017-06-11 11:45:16 </td>
   <td style="text-align:right;"> -22.70307 </td>
   <td style="text-align:right;"> -46.75594 </td>
   <td style="text-align:right;"> 676.2781 </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:right;"> 0.3 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2017-06-11 11:45:18 </td>
   <td style="text-align:right;"> -22.70299 </td>
   <td style="text-align:right;"> -46.75592 </td>
   <td style="text-align:right;"> 675.7316 </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:right;"> 0.3 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2017-06-11 11:45:21 </td>
   <td style="text-align:right;"> -22.70288 </td>
   <td style="text-align:right;"> -46.75592 </td>
   <td style="text-align:right;"> 675.1077 </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:right;"> 0.3 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2017-06-11 11:45:24 </td>
   <td style="text-align:right;"> -22.70276 </td>
   <td style="text-align:right;"> -46.75592 </td>
   <td style="text-align:right;"> 674.4054 </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:right;"> 0.4 </td>
  </tr>
</tbody>
</table>


### References

[^1]: http://www.earlyinnovations.com/gpsphotolinker/about-gpx-and-tcx-file-formats.html
