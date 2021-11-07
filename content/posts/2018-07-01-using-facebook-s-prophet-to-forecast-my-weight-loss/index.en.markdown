---
title: Using Facebook's Prophet to forecast my weight loss
author: Giuliano Sposito
date: '2018-07-01'
slug: 'forecasting-my-weight-using-facebook-s-prophet'
categories:
  - data science
tags:
  - forecast
  - prophet
  - rstats
  - google sheets
  - mice
  - inputation
  - time series
  - tsibble
subtitle: ''
lastmod: '2021-11-07T10:25:52-03:00'
authorLink: ''
description: ''
hiddenFromHomePage: no
hiddenFromSearch: no
featuredImage: 'images/cover.png'
featuredImagePreview: 'images/cover.png'
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
<script src="{{< blogdown/postref >}}index.en_files/kePrint/kePrint.js"></script>
<link href="{{< blogdown/postref >}}index.en_files/lightable/lightable.css" rel="stylesheet" />
<script src="{{< blogdown/postref >}}index.en_files/kePrint/kePrint.js"></script>
<link href="{{< blogdown/postref >}}index.en_files/lightable/lightable.css" rel="stylesheet" />
<script src="{{< blogdown/postref >}}index.en_files/kePrint/kePrint.js"></script>
<link href="{{< blogdown/postref >}}index.en_files/lightable/lightable.css" rel="stylesheet" />
<script src="{{< blogdown/postref >}}index.en_files/kePrint/kePrint.js"></script>
<link href="{{< blogdown/postref >}}index.en_files/lightable/lightable.css" rel="stylesheet" />

In this post, we'll try to forecast my weight using Forecast and Facebook's Prophet packages. We'll see what is the performance from Facebook's method in a simple case of forecast.

<!--more-->



Recently, in the beginning of march, I went to a Nutritionist who recommended me to start a regime to lost some weight. As a good practice in these situations, short feedback cycles are essential to (re)build good habits, so I start to weigh myself almost daily, and record the values in a spreadsheet to follow my progress.

I kept the record until end of may, when my vacations started and I travel for three weeks, and now, at end of June, I restart to record my weight again. Between this time, I saw the [Bruno Rodrigue's](https://github.com/b-rodrigues/) [post](http://www.brodrigues.co/blog/2018-06-24-fun_ts/) where he try to forecast his weight using the Forecast package, and I was inspired to do the same, but using my own data, and see how the [Facebook's Prophet](https://facebook.github.io/prophet/) package performs trying to predict my weight in the final of June using the data recorded between March and May.



```r
#setup

library(googlesheets4) # I keep my records in a google spreadsheet
library(tibbletime)   # We'll use tibble time and mice to fill the gap in the 
library(mice)         # weighting records
library(tsibble)      # TS Tibble is a 'time aware tibble' to keep time series data   
library(lubridate)    # lubridate to manipulate easly date-time info 
library(tidyverse)    # tidyr, dplyr and magrittr
library(forecast)     # package 'standard' to forecast time series
library(prophet)      # the 'facebook' method
```

### Loading the dataset and filling the gaps

I weigh myself almost daily (but, in the weekends I'm usually away from home) and keep the weight records in a Google Spreadsheet, so let's get the data set using the [googlesheets](https://cran.r-project.org/web/packages/googlesheets/googlesheets.pdf) package and fill the gap using [mice](https://cran.r-project.org/web/packages/mice/mice.pdf) package.


```r
# download data from google spreadsheets
gs4_auth(email = "gsposito@gmail.com") 
raw_data <- read_sheet("1P1q58DYs4Jy5cXKXCrdl11ru4Rop1Mu7r8fXEraCX9M")

# handles date/weight
raw_data %>%                # the dataset has record for date, weigth, fat, 
  select(1:2) %>%           # water, muscle and bones, filtering first two
  mutate(Peso=Peso/10) %>%  # to make it Kilograms
  set_names(c("date","weight")) -> measures 

head(measures, 10) %>%
  kable(align = "c",bootstrap_options = "striped", full_width = F) %>% 
  kableExtra::kable_styling(font_size = 11)
```

<table class="table" style="font-size: 11px; margin-left: auto; margin-right: auto;">
 <thead>
  <tr>
   <th style="text-align:center;"> date </th>
   <th style="text-align:center;"> weight </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:center;"> 2018-03-05 </td>
   <td style="text-align:center;"> 10.14 </td>
  </tr>
  <tr>
   <td style="text-align:center;"> 2018-03-06 </td>
   <td style="text-align:center;"> 10.15 </td>
  </tr>
  <tr>
   <td style="text-align:center;"> 2018-03-07 </td>
   <td style="text-align:center;"> 10.12 </td>
  </tr>
  <tr>
   <td style="text-align:center;"> 2018-03-08 </td>
   <td style="text-align:center;"> 10.06 </td>
  </tr>
  <tr>
   <td style="text-align:center;"> 2018-03-09 </td>
   <td style="text-align:center;"> 9.99 </td>
  </tr>
  <tr>
   <td style="text-align:center;"> 2018-03-10 </td>
   <td style="text-align:center;"> 9.98 </td>
  </tr>
  <tr>
   <td style="text-align:center;"> 2018-03-12 </td>
   <td style="text-align:center;"> 9.90 </td>
  </tr>
  <tr>
   <td style="text-align:center;"> 2018-03-13 </td>
   <td style="text-align:center;"> 9.94 </td>
  </tr>
  <tr>
   <td style="text-align:center;"> 2018-03-14 </td>
   <td style="text-align:center;"> 9.84 </td>
  </tr>
  <tr>
   <td style="text-align:center;"> 2018-03-15 </td>
   <td style="text-align:center;"> 9.82 </td>
  </tr>
</tbody>
</table>

We can see there is no data recorded at days 11, 16, 17 and 18 and go on. Also, there is a big gap in June.


```r
tail(measures) %>%
  kable() %>% 
  kableExtra::kable_styling(font_size = 11)
```

<table class="table" style="font-size: 11px; margin-left: auto; margin-right: auto;">
 <thead>
  <tr>
   <th style="text-align:left;"> date </th>
   <th style="text-align:right;"> weight </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> 2018-05-25 </td>
   <td style="text-align:right;"> 9.07 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2018-05-28 </td>
   <td style="text-align:right;"> 8.93 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2018-05-29 </td>
   <td style="text-align:right;"> 8.95 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2018-05-30 </td>
   <td style="text-align:right;"> 8.95 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2018-06-25 </td>
   <td style="text-align:right;"> 8.70 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2018-06-29 </td>
   <td style="text-align:right;"> 8.71 </td>
  </tr>
</tbody>
</table>

Let's separate the last two points, in June, from the remaining data, so we'll have something like a "training" and a "test" data sets.


```r
# taking the June measures as a "test" points
weight.target <- measures %>%
  filter( date >= ymd(20180601) ) %>% 
  mutate(date = as.Date(date))

# and the previous as "training" points to be used in Forecast and Prophet
measures <- measures %>%
  filter( date < ymd(20180601) )
```

Let's make the gaps in the "training" data set explicit, so we can fill'in them using [mice](). 


```r
# explicit NA
measures %>%
  mutate( date = as.Date(date) ) %>% 
  as_tsibble() %>%
  fill_gaps() -> measures

head(measures,20) %>%
  kable() %>% 
  kableExtra::kable_styling(font_size = 11)
```

<table class="table" style="font-size: 11px; margin-left: auto; margin-right: auto;">
 <thead>
  <tr>
   <th style="text-align:left;"> date </th>
   <th style="text-align:right;"> weight </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> 2018-03-05 </td>
   <td style="text-align:right;"> 10.14 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2018-03-06 </td>
   <td style="text-align:right;"> 10.15 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2018-03-07 </td>
   <td style="text-align:right;"> 10.12 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2018-03-08 </td>
   <td style="text-align:right;"> 10.06 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2018-03-09 </td>
   <td style="text-align:right;"> 9.99 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2018-03-10 </td>
   <td style="text-align:right;"> 9.98 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2018-03-11 </td>
   <td style="text-align:right;"> NA </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2018-03-12 </td>
   <td style="text-align:right;"> 9.90 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2018-03-13 </td>
   <td style="text-align:right;"> 9.94 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2018-03-14 </td>
   <td style="text-align:right;"> 9.84 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2018-03-15 </td>
   <td style="text-align:right;"> 9.82 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2018-03-16 </td>
   <td style="text-align:right;"> NA </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2018-03-17 </td>
   <td style="text-align:right;"> NA </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2018-03-18 </td>
   <td style="text-align:right;"> NA </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2018-03-19 </td>
   <td style="text-align:right;"> 9.78 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2018-03-20 </td>
   <td style="text-align:right;"> 9.79 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2018-03-21 </td>
   <td style="text-align:right;"> 9.70 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2018-03-22 </td>
   <td style="text-align:right;"> 9.70 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2018-03-23 </td>
   <td style="text-align:right;"> NA </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2018-03-24 </td>
   <td style="text-align:right;"> NA </td>
  </tr>
</tbody>
</table>

Now, with "NA" explicit in the time series we can use [mice].


```r
# complete values
measures %>%
  mice(method = "pmm", m=5, maxit = 50, seed=42, printFlag= F) %>% # five imputation for NA
  mice::complete("long") %>% # fill the NA
  group_by(date) %>% # average them (5 points for missing data)
  summarise( weight = mean(weight) ) -> measures_completed

# compare original data and missing values
measures_completed %>%
  inner_join(measures, by="date") %>%   # join with original (with NA) dataset
  set_names(c("date","inputted","original")) %>%
  tidyr::gather(type,weight,-date) %>% # pivot-it
  ggplot() + geom_point(aes(date,weight,color=type))
```

<img src="{{< blogdown/postref >}}index.en_files/figure-html/inputeMissing-1.png" width="672" />

Well, the [mice](https://cran.r-project.org/web/packages/mice/mice.pdf) package did a remarkable job, the inputted values (red ones) seems like real measures, now with data set completed we convert it to a time series and use forecast to predict the weight behavior in June.

### Forecasting with Forecast Package

The [Forecast package](https://cran.r-project.org/web/packages/forecast/forecast.pdf) implements ARIMA models for time series data. In statistics and econometrics, and in particular in time series analysis, an autoregressive integrated moving average (ARIMA) model is a generalization of an autoregressive moving average (ARMA) model. Both of these models are fitted to time series data either to better understand the data or to predict future points in the series (forecasting). [(more on ARIMA)](https://en.wikipedia.org/wiki/Autoregressive_integrated_moving_average)

Let's use this model to forecast.


```r
# models the time series
model <- measures_completed %>%
  pull(weight) %>%  # convert to a vector
  as.ts() %>%       # transform to a Time Serie
  auto.arima()      # fit the model

# make de predicion for 30 days
prediction <- model %>%
  forecast(h=31) %>%  # forecast next 30 measures
  as.tibble() %>%     # covert to tibble
  mutate( date = max(measures_completed$date) + 1:31 ) # add the dates

# prediction dataset
head(prediction) %>%
  kable() %>% 
  kableExtra::kable_styling(font_size = 11)
```

<table class="table" style="font-size: 11px; margin-left: auto; margin-right: auto;">
 <thead>
  <tr>
   <th style="text-align:right;"> Point Forecast </th>
   <th style="text-align:right;"> Lo 80 </th>
   <th style="text-align:right;"> Hi 80 </th>
   <th style="text-align:right;"> Lo 95 </th>
   <th style="text-align:right;"> Hi 95 </th>
   <th style="text-align:left;"> date </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:right;"> 8.928799 </td>
   <td style="text-align:right;"> 8.882932 </td>
   <td style="text-align:right;"> 8.974666 </td>
   <td style="text-align:right;"> 8.858651 </td>
   <td style="text-align:right;"> 8.998947 </td>
   <td style="text-align:left;"> 2018-05-31 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 8.914873 </td>
   <td style="text-align:right;"> 8.862890 </td>
   <td style="text-align:right;"> 8.966856 </td>
   <td style="text-align:right;"> 8.835372 </td>
   <td style="text-align:right;"> 8.994374 </td>
   <td style="text-align:left;"> 2018-06-01 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 8.900948 </td>
   <td style="text-align:right;"> 8.843496 </td>
   <td style="text-align:right;"> 8.958399 </td>
   <td style="text-align:right;"> 8.813083 </td>
   <td style="text-align:right;"> 8.988812 </td>
   <td style="text-align:left;"> 2018-06-02 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 8.887022 </td>
   <td style="text-align:right;"> 8.824579 </td>
   <td style="text-align:right;"> 8.949465 </td>
   <td style="text-align:right;"> 8.791524 </td>
   <td style="text-align:right;"> 8.982520 </td>
   <td style="text-align:left;"> 2018-06-03 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 8.873097 </td>
   <td style="text-align:right;"> 8.806033 </td>
   <td style="text-align:right;"> 8.940161 </td>
   <td style="text-align:right;"> 8.770531 </td>
   <td style="text-align:right;"> 8.975662 </td>
   <td style="text-align:left;"> 2018-06-04 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 8.859171 </td>
   <td style="text-align:right;"> 8.787785 </td>
   <td style="text-align:right;"> 8.930558 </td>
   <td style="text-align:right;"> 8.749995 </td>
   <td style="text-align:right;"> 8.968347 </td>
   <td style="text-align:left;"> 2018-06-05 </td>
  </tr>
</tbody>
</table>

```r
# plot to compare the prediction with the real values
prediction %>%
  rename( weight = `Point Forecast`) %>% # rename the forecast column
  mutate( origin = "prediction" ) %>%    # mark the data as 'prediction'
  bind_rows( measures_completed %>% mutate(origin="measures") ) %>% # join with real data
  ggplot(aes(x=date)) + 
  geom_point(aes(y=weight,color=origin)) + 
  geom_ribbon(aes(ymin=`Lo 80`, ymax=`Hi 80`), alpha=0.2) +
  geom_ribbon(aes(ymin=`Lo 95`, ymax=`Hi 95`), alpha=0.2) +
  geom_point(data=weight.target, mapping = aes(date, weight)) +
  theme_bw()
```

<img src="{{< blogdown/postref >}}index.en_files/figure-html/forecastJune-1.png" width="672" />

The Forecast package did a "OK" job, the first real measure are in the 80% certainty range and the second in the 95% range, what is, for predictions, a good job. But the model miss the two points, they are at the edge of the certainty interval.


```r
# comparing the real and predicted values
prediction %>%
  inner_join(weight.target, by="date") %>%
  select(date, `Lo 95`, forecast=`Point Forecast`, weight,`Hi 95`) %>%
  mutate( interval_size = `Hi 95` - `Lo 95` ) %>% 
  kable() %>% 
  kableExtra::kable_styling(font_size = 11)
```

<table class="table" style="font-size: 11px; margin-left: auto; margin-right: auto;">
 <thead>
  <tr>
   <th style="text-align:left;"> date </th>
   <th style="text-align:right;"> Lo 95 </th>
   <th style="text-align:right;"> forecast </th>
   <th style="text-align:right;"> weight </th>
   <th style="text-align:right;"> Hi 95 </th>
   <th style="text-align:right;"> interval_size </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> 2018-06-25 </td>
   <td style="text-align:right;"> 8.380875 </td>
   <td style="text-align:right;"> 8.580660 </td>
   <td style="text-align:right;"> 8.70 </td>
   <td style="text-align:right;"> 8.780446 </td>
   <td style="text-align:right;"> 0.3995711 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2018-06-29 </td>
   <td style="text-align:right;"> 8.311620 </td>
   <td style="text-align:right;"> 8.524958 </td>
   <td style="text-align:right;"> 8.71 </td>
   <td style="text-align:right;"> 8.738296 </td>
   <td style="text-align:right;"> 0.4266767 </td>
  </tr>
</tbody>
</table>

Can the Facebook's Prophet do a better job?

### Prophet

The [Facebook's Prophet](https://facebook.github.io/prophet/) is a procedure for forecasting time series data based on an additive model where non-linear trends are fit with yearly, weekly, and daily seasonality, plus holiday effects. It works best with time series that have strong seasonal effects and several seasons of historical data. Prophet is robust to missing data and shifts in the trend, and typically handles outliers well.

Facebook implemented the procedure in R and Python and make it public in 2017, the package [Prophet](https://cran.r-project.org/web/packages/prophet/index.html) gives you access to it. If you want to know more about it, check [this](https://towardsdatascience.com/using-open-source-prophet-package-to-make-future-predictions-in-r-ece585b73687).


```r
# by definition we need to pass a df with 2 columns "ds" (datestamp) and "y" (target var)
measures_completed %>%
  set_names(c("ds","y")) %>%
  prophet() -> pmodel

# we use the model to make the prediction
pmodel %>%
  make_future_dataframe(30) %>%
  predict(pmodel,.) -> pprediction

# what is the output format
pprediction %>%
  as.tibble() %>%
  glimpse()
```

```
## Rows: 117
## Columns: 16
## $ ds                         <dttm> 2018-03-05, 2018-03-06, 2018-03-07, 2018-0~
## $ trend                      <dbl> 10.155044, 10.123293, 10.091542, 10.059791,~
## $ additive_terms             <dbl> -0.007936320, -0.002856559, -0.009109722, 0~
## $ additive_terms_lower       <dbl> -0.007936320, -0.002856559, -0.009109722, 0~
## $ additive_terms_upper       <dbl> -0.007936320, -0.002856559, -0.009109722, 0~
## $ weekly                     <dbl> -0.007936320, -0.002856559, -0.009109722, 0~
## $ weekly_lower               <dbl> -0.007936320, -0.002856559, -0.009109722, 0~
## $ weekly_upper               <dbl> -0.007936320, -0.002856559, -0.009109722, 0~
## $ multiplicative_terms       <dbl> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0~
## $ multiplicative_terms_lower <dbl> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0~
## $ multiplicative_terms_upper <dbl> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0~
## $ yhat_lower                 <dbl> 10.113679, 10.084900, 10.048282, 10.042038,~
## $ yhat_upper                 <dbl> 10.180122, 10.153888, 10.116648, 10.108169,~
## $ trend_lower                <dbl> 10.155044, 10.123293, 10.091542, 10.059791,~
## $ trend_upper                <dbl> 10.155044, 10.123293, 10.091542, 10.059791,~
## $ yhat                       <dbl> 10.147108, 10.120436, 10.082432, 10.077176,~
```

As you see, the prophet's prediction give us a lot of information, let's check how it performed.


```r
#plot the prediction against the target
pprediction %>%
  as.tibble() %>%
  mutate(ds=as_date(ds)) %>%
  filter(ds > max(measures_completed$date) ) %>%
  select(ds, trend, yhat, yhat_lower, yhat_upper) %>%
  ggplot() + 
  geom_line(aes(x=ds, y=yhat), color="blue") +
  geom_ribbon(aes(x=ds, ymin=yhat_lower, ymax=yhat_upper), alpha=0.2) +
  geom_point(data=measures_completed, aes(x=date, y=weight), color="salmon") +
  geom_point(data=weight.target, mapping=aes(x=date, y=weight), color="black") +
  theme_bw()
```

<img src="{{< blogdown/postref >}}index.en_files/figure-html/prophetPerform-1.png" width="672" />

Wow, the prophet to an excellent job, the real measures are in the center of the range and the prediction values are close to it.


```r
# checking the values in the June measures
pprediction %>%
  as.tibble() %>% 
  mutate(date=as_date(ds)) %>%
  inner_join(weight.target, by="date") %>%
  select(date=ds, yhat_lower, yhat, weight, yhat_upper ) %>%
  mutate( interval_size = yhat_upper - yhat_lower ) %>% 
  kable() %>% 
  kableExtra::kable_styling(font_size = 11)
```

<table class="table" style="font-size: 11px; margin-left: auto; margin-right: auto;">
 <thead>
  <tr>
   <th style="text-align:left;"> date </th>
   <th style="text-align:right;"> yhat_lower </th>
   <th style="text-align:right;"> yhat </th>
   <th style="text-align:right;"> weight </th>
   <th style="text-align:right;"> yhat_upper </th>
   <th style="text-align:right;"> interval_size </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> 2018-06-25 </td>
   <td style="text-align:right;"> 8.637765 </td>
   <td style="text-align:right;"> 8.748224 </td>
   <td style="text-align:right;"> 8.70 </td>
   <td style="text-align:right;"> 8.870323 </td>
   <td style="text-align:right;"> 0.2325575 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2018-06-29 </td>
   <td style="text-align:right;"> 8.584754 </td>
   <td style="text-align:right;"> 8.723976 </td>
   <td style="text-align:right;"> 8.71 </td>
   <td style="text-align:right;"> 8.872009 </td>
   <td style="text-align:right;"> 0.2872546 </td>
  </tr>
</tbody>
</table>

As you saw, the prediction points made by prophet are remarkable close to the real values and also the size of certainty interval is very narrow, almost half forecast´s.

Of course, we just use these packages "out-of-the-box", we didn't tunning the Forecast parameters, maybe it can be a better job, but this don't invalidate the results of Prophet.

The performance of the prophet was great in the test, for sure, the this package deserves another post in the future, to explore other features available.

