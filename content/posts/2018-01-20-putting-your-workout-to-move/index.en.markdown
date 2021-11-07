---
title: Putting your workout to move
author: Giuliano Sposito
date: '2018-01-20'
slug: 'putting-your-workout-to-move'
categories:
  - data science
tags:
  - rstats
  - animation
  - tcx
  - workout
  - map
subtitle: ''
lastmod: '2021-11-03T00:49:28-03:00'
authorLink: ''
description: ''
hiddenFromHomePage: no
hiddenFromSearch: no
featuredImage: 'images/cover.jpg'
featuredImagePreview: 'images/cover.jpg'
toc:
  enable: yes
math:
  enable: no
lightgallery: no
license: ''
disqusIdentifier: 'putting-your-workout-to-move'
---
<script src="{{< blogdown/postref >}}index.en_files/kePrint/kePrint.js"></script>
<link href="{{< blogdown/postref >}}index.en_files/lightable/lightable.css" rel="stylesheet" />

In this quick post, we'll take one MTB ride, tracked by FitBit in a TXC File, and generate a animated gif. Using `gganimate` Package and using the same code we learned, we can animate the map with few words. 

<!--more-->

## Reading TCX File

[We already saw](/2018/01/ploting-your-mtb-track-with-r/) to how read and GPS track information stored in a TXC/GPX file, once it's just an `XML File`.


```r
library(XML)
library(lubridate)
library(tidyverse)
library(ggmap)
library(gganimate)
library(knitr)

file <- "data/11654237848.tcx"

pfile <- htmlTreeParse(file = file,
                       error = function (...) {},
                       useInternalNodes = TRUE)

features <- c("time", "position/latitudedegrees", "position/longitudedegrees",
              "altitudemeters", "distancemeters", "heartratebpm/value")

fnames <- c("dt", "lat", "lon", "alt", "dist", "hbpm")

"//trackpoint/" %>%
  paste0(features) %>%
  map(function(p){xpathSApply(pfile, path = p, xmlValue)}) %>%
  setNames(fnames) %>%
  as_data_frame() %>% 
  mutate_at(vars(lat:dist), as.numeric) %>%
  mutate(
    dt = lubridate::as_datetime(dt),
    hbpm  = as.integer(hbpm),
    tm.prev.s = c(0, diff(dt)),
    tm.cum.min  = round(cumsum(tm.prev.s)/60,1)
  ) -> track

track %>% 
  head(10) %>% 
  kable() %>% 
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

## Plot the map

Also we saw how is easy to plot the track over a map using `ggmap` package.


```r
# getting the map backgroubd 
bbox <- make_bbox(lon = track$lon, lat=track$lat, f=.1)
gmap <- get_map( location=bbox, maptype = "terrain", source="google")

# base plot
ggmap(gmap) + 
  geom_path(data=track, mapping=aes(lon, lat),
            color="red", alpha = 1, size = 0.8, lineend = "round") +
  coord_fixed() +
  theme_void() +
  theme( legend.position = "none" )
```

<img src="{{< blogdown/postref >}}index.en_files/figure-html/plot-1.png" width="672" />

## Animating the Map

Now, with a little more code, we can use the [gganimate](https://github.com/dgrtwo/gganimate) Package to create a animated gif version of this plot.

`gganimate` plotting a series of `ggplots` and put them together in a `gif` (or other format) using [ImageMagick](https://www.imagemagick.org/). Two `aesthetics` keywords in the `ggplot2` grammar are in charge to control how the individual charts will be gerated: `frame` and `cumulative`. The first indicate which feature in the data frame is the "time dimention" and the other controls if the plot will be incremental (from a "frame" to "frame") or cumulative (from "beginning" to the "current frame").


```r
# lets make a frame each 3 minutes
# to not destroy the track info, we collapse the data on each 3 minutes
track %>%
  mutate(
    dt = floor_date(dt, "3 minutes")
  ) -> track

# base plot
ggmap(gmap) + 
  # cumulative layer, the "whole path" along the time (dt)
  geom_path(data=track, mapping=aes(lon, lat, frame=dt, cumulative=T),
            color="yellow", alpha = 1, size = 0.8, lineend = "round") +
  # the "instant" plot, the 3 minutes path in the frame (dt)
  geom_path(data=track, mapping=aes(lon, lat, frame=dt, cumulative=F),
            size=1.2, lineend = "round", color="red") +
  coord_fixed() +
  theme_void() +
  theme( legend.position = "none" ) -> p

p <- gganimate(p, interval=0.01, ani.width=400,
               ani.height=400, filename = "11654237848.gif" )
```

![Animated MTB Track](images/11654237848.gif)
