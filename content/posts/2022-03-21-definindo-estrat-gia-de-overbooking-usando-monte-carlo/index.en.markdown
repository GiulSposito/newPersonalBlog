---
title: Defining overbooking strategy using Monte Carlo
author: Giuliano Sposito
date: '2022-03-20'
slug: monte-carlo-simulation-overbooking
categories:
  - advanced business analytics
tags:
  - data analysis
  - data science
  - decision making
  - monte carlo
subtitle: ''
lastmod: '2022-03-19T09:40:11-03:00'
authorLink: ''
description: ''
hiddenFromHomePage: no
hiddenFromSearch: no
featuredImage: 'images/cover_01.png'
featuredImagePreview: 'images/cover_01.png'
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

Not all passengers who buy a plane ticket show up at boarding. The _no shows_ make flights occur with idle capacity and incur an opportunity cost for the operator. To compensate, airlines use _overbooking_ (sale of seats above the flight capacity). But how many additional seats should we offer without it becoming a chronic passenger relocation problem?

<!--more-->

By _overbooking_, the risk has more passengers than the plane can handle at the time of boarding, leading to higher costs to relocate passengers on other flights and causing wear on the brand through user dissatisfaction. In this post, we will analyze the demand distribution and the behavior of the _no shows_ to find the best overbooking strategy through [Monte Carlo simulation](https://en.wikipedia.org/wiki/Monte_Carlo_method) to establish a statistically secure _overbooking_ policy.

### Approach

The approach we will use to try to find the best overbooking strategy will follow these steps:

1. Understand and model the behavior (distribution) of demand
1. Simulate boarding situations using Monte Carlo
1. Define an _overbooking_ strategy based on the probability of passenger relocation

### Flight Demand Data

As a starting point, we will load the demand and attendance data of a particular commercial flight available [in this excel sheet](./assets/Flight-Overbooking-Data.xlsx) and briefly explore the data and try to understand the behavior of the demand so that it can be modeled.


```r
# setup ####
library(tidyverse)

# read data ####
raw_data <- readxl::read_xlsx("./assets/Flight-Overbooking-Data.xlsx")

# simple clean up
flight_dt <- raw_data %>% 
  dplyr::select(1:5) %>% 
  janitor::clean_names()

# glimpse
flight_dt %>% 
  head(10) %>% 
  knitr::kable() %>% 
  kableExtra::kable_styling(font_size = 11)
```

<table class="table" style="font-size: 11px; margin-left: auto; margin-right: auto;">
 <thead>
  <tr>
   <th style="text-align:left;"> date </th>
   <th style="text-align:right;"> demand </th>
   <th style="text-align:right;"> booked </th>
   <th style="text-align:right;"> shows </th>
   <th style="text-align:right;"> rate </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> 2014-01-01 </td>
   <td style="text-align:right;"> 132 </td>
   <td style="text-align:right;"> 132 </td>
   <td style="text-align:right;"> 117 </td>
   <td style="text-align:right;"> 0.8863636 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2014-01-02 </td>
   <td style="text-align:right;"> 154 </td>
   <td style="text-align:right;"> 150 </td>
   <td style="text-align:right;"> 142 </td>
   <td style="text-align:right;"> 0.9466667 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2014-01-03 </td>
   <td style="text-align:right;"> 142 </td>
   <td style="text-align:right;"> 142 </td>
   <td style="text-align:right;"> 126 </td>
   <td style="text-align:right;"> 0.8873239 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2014-01-04 </td>
   <td style="text-align:right;"> 152 </td>
   <td style="text-align:right;"> 150 </td>
   <td style="text-align:right;"> 141 </td>
   <td style="text-align:right;"> 0.9400000 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2014-01-05 </td>
   <td style="text-align:right;"> 162 </td>
   <td style="text-align:right;"> 150 </td>
   <td style="text-align:right;"> 142 </td>
   <td style="text-align:right;"> 0.9466667 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2014-01-06 </td>
   <td style="text-align:right;"> 146 </td>
   <td style="text-align:right;"> 146 </td>
   <td style="text-align:right;"> 131 </td>
   <td style="text-align:right;"> 0.8972603 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2014-01-07 </td>
   <td style="text-align:right;"> 134 </td>
   <td style="text-align:right;"> 134 </td>
   <td style="text-align:right;"> 118 </td>
   <td style="text-align:right;"> 0.8805970 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2014-01-08 </td>
   <td style="text-align:right;"> 158 </td>
   <td style="text-align:right;"> 150 </td>
   <td style="text-align:right;"> 140 </td>
   <td style="text-align:right;"> 0.9333333 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2014-01-09 </td>
   <td style="text-align:right;"> 165 </td>
   <td style="text-align:right;"> 150 </td>
   <td style="text-align:right;"> 138 </td>
   <td style="text-align:right;"> 0.9200000 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2014-01-10 </td>
   <td style="text-align:right;"> 156 </td>
   <td style="text-align:right;"> 150 </td>
   <td style="text-align:right;"> 139 </td>
   <td style="text-align:right;"> 0.9266667 </td>
  </tr>
</tbody>
</table>

It is a very simple and straightforward dataset containing information on the date, the demand, how many passengers were registered, how many showed up, and the attendance rate (appeared/registered).

#### Data Overview


```r
# overview
flight_dt %>% 
  skimr::skim()
```


<table style='width: auto;'
        class='table table-condensed'>
<caption>Table 1: Data summary</caption>
 <thead>
  <tr>
   <th style="text-align:left;">   </th>
   <th style="text-align:left;">   </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> Name </td>
   <td style="text-align:left;"> Piped data </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Number of rows </td>
   <td style="text-align:left;"> 730 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Number of columns </td>
   <td style="text-align:left;"> 5 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> _______________________ </td>
   <td style="text-align:left;">  </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Column type frequency: </td>
   <td style="text-align:left;">  </td>
  </tr>
  <tr>
   <td style="text-align:left;"> numeric </td>
   <td style="text-align:left;"> 4 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> POSIXct </td>
   <td style="text-align:left;"> 1 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> ________________________ </td>
   <td style="text-align:left;">  </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Group variables </td>
   <td style="text-align:left;"> None </td>
  </tr>
</tbody>
</table>


**Variable type: numeric**

<table>
 <thead>
  <tr>
   <th style="text-align:left;"> skim_variable </th>
   <th style="text-align:right;"> n_missing </th>
   <th style="text-align:right;"> complete_rate </th>
   <th style="text-align:right;"> mean </th>
   <th style="text-align:right;"> sd </th>
   <th style="text-align:right;"> p0 </th>
   <th style="text-align:right;"> p25 </th>
   <th style="text-align:right;"> p50 </th>
   <th style="text-align:right;"> p75 </th>
   <th style="text-align:right;"> p100 </th>
   <th style="text-align:left;"> hist </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> demand </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 150.40 </td>
   <td style="text-align:right;"> 12.28 </td>
   <td style="text-align:right;"> 117.00 </td>
   <td style="text-align:right;"> 142.0 </td>
   <td style="text-align:right;"> 150.00 </td>
   <td style="text-align:right;"> 158.00 </td>
   <td style="text-align:right;"> 191.00 </td>
   <td style="text-align:left;"> ▁▆▇▂▁ </td>
  </tr>
  <tr>
   <td style="text-align:left;"> booked </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 145.32 </td>
   <td style="text-align:right;"> 6.85 </td>
   <td style="text-align:right;"> 117.00 </td>
   <td style="text-align:right;"> 142.0 </td>
   <td style="text-align:right;"> 150.00 </td>
   <td style="text-align:right;"> 150.00 </td>
   <td style="text-align:right;"> 150.00 </td>
   <td style="text-align:left;"> ▁▁▁▂▇ </td>
  </tr>
  <tr>
   <td style="text-align:left;"> shows </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 133.73 </td>
   <td style="text-align:right;"> 9.10 </td>
   <td style="text-align:right;"> 106.00 </td>
   <td style="text-align:right;"> 127.0 </td>
   <td style="text-align:right;"> 138.00 </td>
   <td style="text-align:right;"> 141.00 </td>
   <td style="text-align:right;"> 147.00 </td>
   <td style="text-align:left;"> ▁▂▃▂▇ </td>
  </tr>
  <tr>
   <td style="text-align:left;"> rate </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 0.92 </td>
   <td style="text-align:right;"> 0.03 </td>
   <td style="text-align:right;"> 0.88 </td>
   <td style="text-align:right;"> 0.9 </td>
   <td style="text-align:right;"> 0.92 </td>
   <td style="text-align:right;"> 0.94 </td>
   <td style="text-align:right;"> 0.99 </td>
   <td style="text-align:left;"> ▇▃▇▃▁ </td>
  </tr>
</tbody>
</table>


**Variable type: POSIXct**

<table>
 <thead>
  <tr>
   <th style="text-align:left;"> skim_variable </th>
   <th style="text-align:right;"> n_missing </th>
   <th style="text-align:right;"> complete_rate </th>
   <th style="text-align:left;"> min </th>
   <th style="text-align:left;"> max </th>
   <th style="text-align:left;"> median </th>
   <th style="text-align:right;"> n_unique </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> date </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:left;"> 2014-01-01 </td>
   <td style="text-align:left;"> 2015-12-31 </td>
   <td style="text-align:left;"> 2014-12-31 12:00:00 </td>
   <td style="text-align:right;"> 730 </td>
  </tr>
</tbody>
</table>

As you can see, there is an upper limit of 150 in the registered column, indicating that this is the capacity of the flight, that is, 150 seats.

#### Demand Behavior

Let's try to model the demand, making the fit of your distribution, for we will use the package `{fitdistrplus}`.


```r
library(fitdistrplus)

# checking the empirical distribution
plotdist(flight_dt$demand, discrete = T)
```

<img src="{{< blogdown/postref >}}index.en_files/figure-html/demandDistr-1.png" width="672" />

```r
# what are the distribution candidates?
descdist(flight_dt$demand, boot=1000, discrete = T)
```

<img src="{{< blogdown/postref >}}index.en_files/figure-html/demandDistr-2.png" width="672" />

```
## summary statistics
## ------
## min:  117   max:  191 
## median:  150 
## mean:  150.3973 
## estimated sd:  12.27513 
## estimated skewness:  0.149088 
## estimated kurtosis:  2.943392
```

The `{fitdistrplus}` package indicated three candidates as the best fit for the demand distribution: [normal](https://en.wikipedia.org/wiki/Normal_distribution), [poisson](https://en.wikipedia.org/wiki/Poisson_distribution) or [negative binomial](https://en.wikipedia.org/wiki/Negative_binomial_distribution). Let's test which of the two most common ones has the best fit.

##### Normal Distribution


```r
# lets fit a normal and see what we get
fitdist(flight_dt$demand, "norm", discrete = T) %T>%
  plot() %>% 
  summary()
```

<img src="{{< blogdown/postref >}}index.en_files/figure-html/fitNorm-1.png" width="672" />

```
## Fitting of the distribution ' norm ' by maximum likelihood 
## Parameters : 
##       estimate Std. Error
## mean 150.39726  0.4540115
## sd    12.26672  0.3210346
## Loglikelihood:  -2865.855   AIC:  5735.709   BIC:  5744.895 
## Correlation matrix:
##      mean sd
## mean    1  0
## sd      0  1
```

##### Poisson Distribution


```r
# lets fit a poisson and see what we get
fitdist(flight_dt$demand, "pois", discrete = T) %T>%
  plot() %>% 
  summary()
```

<img src="{{< blogdown/postref >}}index.en_files/figure-html/fitPois-1.png" width="672" />

```
## Fitting of the distribution ' pois ' by maximum likelihood 
## Parameters : 
##        estimate Std. Error
## lambda 150.3973  0.4538983
## Loglikelihood:  -2864.742   AIC:  5731.484   BIC:  5736.077
```

##### Melhor modelo

We observed that the Poisson distribution has, marginally, the best fit monitoring the indicators [loglikehood](https://www.statology.org › likelihood-vs-probability), [IAC](https://en.wikipedia.org/wiki/Akaike_information_criterion) and [BIC](https:/ /en.wikipedia.org/wiki/Bayesian_information_criterion). So let's use _poisson_ as our distribution model for demand.


```r
# Emp CDF fit for Poisson is a little better and IAC also is marginally better
demand.pois <- fitdist(flight_dt$demand, "pois", discrete = T)
```

#### Attendance

The _show up_ can be modeled as a [binomial](https://en.wikipedia.org/wiki/Binomial_distribution) lottery over the number of registered passengers for the flight with a success rate determined by the historical average.


```r
mean(flight_dt$rate)
```

```
## [1] 0.9194333
```

We found that the historical average presence rate for the flight is 92%, we can use this information to simulate the presence process by doing:


```r
pass_reg <- 145 # number of passengers registered for the fligth
show_ups <- rbinom(1, pass_reg, mean(flight_dt$rate)) # one random binomial draw with size of pass_reg at historic show_up rate
show_ups 
```

```
## [1] 127
```


### Simulation Model

We are going to make a model to simulate a boarding situation, in this first model, we will establish a fixed number for the overbooking of 15 positions, i. e., we will offer 15 additional seats for sale in addition to the flight capacity (150 positions).


```r
# demand simulation
simulateDemand <- function(overbook, n, capacity, showup_rate, demand_model) {
  # generate the demand scenarios (pois distributed)
  tibble(demand = rpois(n, demand_model$estimate)) %>% 
    # booked: demand inside capacity+overbook (flight seats) 
    mutate( booked = map_dbl(demand, ~min( .x, overbook+capacity ) )) %>% 
    # show-ups and no shows
    mutate( shows    = map_dbl(booked, ~rbinom(1,.x,showup_rate)),
            no_shows = booked - shows ) %>%
    # shop-up rate
    mutate( showup_rate = shows/booked ) %>%
    # calc overbook and empty seats
    mutate( overbooked  = shows - capacity,
            empty_seats = capacity - shows ) %>%
    # remove negative values
    mutate( overbooked  = map_dbl(overbooked, ~max(.x,0)),
            empty_seats = map_dbl(empty_seats, ~max(.x, 0))) %>% 
    return()  
}

# simulating 10 thousand cases using:
# fligth capacity: 150 passengers
# overbooking:      15 positions
# show_up rate:   ~92% historic based
# poisson distribuion: fitted previously
sim <- simulateDemand(15,10000,150,mean(flight_dt$rate),demand.pois)

# what we got
sim %>% 
  head(10) %>% 
  knitr::kable() %>% 
  kableExtra::kable_styling(font_size = 11)
```

<table class="table" style="font-size: 11px; margin-left: auto; margin-right: auto;">
 <thead>
  <tr>
   <th style="text-align:right;"> demand </th>
   <th style="text-align:right;"> booked </th>
   <th style="text-align:right;"> shows </th>
   <th style="text-align:right;"> no_shows </th>
   <th style="text-align:right;"> showup_rate </th>
   <th style="text-align:right;"> overbooked </th>
   <th style="text-align:right;"> empty_seats </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:right;"> 138 </td>
   <td style="text-align:right;"> 138 </td>
   <td style="text-align:right;"> 129 </td>
   <td style="text-align:right;"> 9 </td>
   <td style="text-align:right;"> 0.9347826 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 21 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 156 </td>
   <td style="text-align:right;"> 156 </td>
   <td style="text-align:right;"> 140 </td>
   <td style="text-align:right;"> 16 </td>
   <td style="text-align:right;"> 0.8974359 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 10 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 130 </td>
   <td style="text-align:right;"> 130 </td>
   <td style="text-align:right;"> 121 </td>
   <td style="text-align:right;"> 9 </td>
   <td style="text-align:right;"> 0.9307692 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 29 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 157 </td>
   <td style="text-align:right;"> 157 </td>
   <td style="text-align:right;"> 142 </td>
   <td style="text-align:right;"> 15 </td>
   <td style="text-align:right;"> 0.9044586 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 8 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 148 </td>
   <td style="text-align:right;"> 148 </td>
   <td style="text-align:right;"> 132 </td>
   <td style="text-align:right;"> 16 </td>
   <td style="text-align:right;"> 0.8918919 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 18 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 131 </td>
   <td style="text-align:right;"> 131 </td>
   <td style="text-align:right;"> 117 </td>
   <td style="text-align:right;"> 14 </td>
   <td style="text-align:right;"> 0.8931298 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 33 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 154 </td>
   <td style="text-align:right;"> 154 </td>
   <td style="text-align:right;"> 142 </td>
   <td style="text-align:right;"> 12 </td>
   <td style="text-align:right;"> 0.9220779 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 8 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 163 </td>
   <td style="text-align:right;"> 163 </td>
   <td style="text-align:right;"> 147 </td>
   <td style="text-align:right;"> 16 </td>
   <td style="text-align:right;"> 0.9018405 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 3 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 165 </td>
   <td style="text-align:right;"> 165 </td>
   <td style="text-align:right;"> 142 </td>
   <td style="text-align:right;"> 23 </td>
   <td style="text-align:right;"> 0.8606061 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 8 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 137 </td>
   <td style="text-align:right;"> 137 </td>
   <td style="text-align:right;"> 125 </td>
   <td style="text-align:right;"> 12 </td>
   <td style="text-align:right;"> 0.9124088 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 25 </td>
  </tr>
</tbody>
</table>

With a model to simulate a boarding situation, we can analyze the behavior of the frequency of the real _overbooking_ (that is) how many passengers, above the actual capacity of the plane (150 seats), appear at the boarding gate and who would need to be relocated to other flights (or financially compensated).


```r
# lets visualize the overbooked passengers distribution
sim %>% 
  count(overbooked) %>% 
  knitr::kable() %>% 
  kableExtra::kable_styling(font_size = 11)
```

<table class="table" style="font-size: 11px; margin-left: auto; margin-right: auto;">
 <thead>
  <tr>
   <th style="text-align:right;"> overbooked </th>
   <th style="text-align:right;"> n </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 8848 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 245 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:right;"> 210 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:right;"> 206 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:right;"> 170 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:right;"> 108 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:right;"> 96 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:right;"> 60 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 8 </td>
   <td style="text-align:right;"> 24 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 9 </td>
   <td style="text-align:right;"> 12 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 10 </td>
   <td style="text-align:right;"> 10 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 11 </td>
   <td style="text-align:right;"> 8 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 12 </td>
   <td style="text-align:right;"> 3 </td>
  </tr>
</tbody>
</table>

```r
plotdist(sim$overbooked)
```

<img src="{{< blogdown/postref >}}index.en_files/figure-html/bumped-1.png" width="672" />

#### Overbooking Policy

With the view of how _real overbooking_ behaves (# of reassigned passengers), we can then establish an _overbooking_ policy, for example, establishing that in 95% of the boarding situations of this flight, the number of **relocated passengers does not exceed 2**. So in this scenario of 15 additional accents, we would have


```r
# chance to have 2 or less bumped pass
bumped_more_2 <- sim %>% 
  count(overbooked) %>% 
  filter(overbooked>2) %>% 
  summarise( total = sum(n) ) %>% 
  unlist()

1-(bumped_more_2/10000)
```

```
##  total 
## 0.9303
```

It would not be possible to meet this criterion with 15 additional seats in this demand profile and attendance behavior, so how many seats should we offer to meet the established policy?

### Simulating Overbooking

Let's then analyze what would be the number of additional positions to be offered that allow the company to stay within the overbooking policy defined above. To do that, we simulate various boarding situations providing different additional seats (above the flight capacity), going, for example, from 1 to 20 extra positions.


```r
# lets find the optimal overbook to get max of 2 bumped passengers in 95% of situations

# before that, lets create a auxiliary function
probBumpedPass <- function(simulation, nPass){
  # calc the probability of the number of bumped passengers be less then nPass in a simulation
  simulation %>% 
    count(overbooked) %>% 
    filter(overbooked<=nPass) %>% 
    summarise( total = sum(n)/10000 ) %>% 
    unlist() %>% 
    return()
}

# looking the behavior of the probability to get 2 (or 5) less passengers bumped
tibble(overbook=1:20) %>% 
  mutate( simulation = map(overbook, simulateDemand, n=10000, 
                           capacity=150, showup_rate=mean(flight_dt$rate), 
                           demand_model=demand.pois)) %>% 
  mutate( prob2BumpPass = map_dbl(simulation, probBumpedPass, nPass=2),
          prob5BumpPass = map_dbl(simulation, probBumpedPass, nPass=5)) %>% 
  pivot_longer(cols=c(-overbook, -simulation), names_to = "bumped", values_to = "prob") %>% 
  ggplot(aes(x=overbook, y=prob, color=bumped)) +
  geom_hline(yintercept=0.95, linetype="dashed") + 
  geom_vline(xintercept=13, linetype="dashed", color="pink") +
  geom_vline(xintercept=18, linetype="dashed", color="lightblue") +
  geom_line() +
  geom_point() +
  labs(title="Bumped Passengers", 
       subtitle = "Chance to bump until 2 passengers (red) or 5 passengers (blue)",
       y="probability", x="seats offered beyond flight capacity") +
  theme_light()
```

<img src="{{< blogdown/postref >}}index.en_files/figure-html/simulation-1.png" width="672" />

We can see that by offering 13 additional seats, we would be able to meet the policy of having more than two reassigned passengers on only 5% of flights. If the policy were a 95% chance of having five or less, we could offer 18 seats in _overbooking_.

### Dependency between demand and show-up rate

We had assumed a constant show-up rate, no matter the demand for a flight on a given day, i.e., boarding attendance follows a constant rate. But is this hypothesis true?


```r
# we assume that the showup rate is fixed, is it?
cor.test(flight_dt$demand, flight_dt$rate)
```

```
## 
## 	Pearson's product-moment correlation
## 
## data:  flight_dt$demand and flight_dt$rate
## t = 26.194, df = 728, p-value < 2.2e-16
## alternative hypothesis: true correlation is not equal to 0
## 95 percent confidence interval:
##  0.6572186 0.7321212
## sample estimates:
##       cor 
## 0.6965629
```

This correlation rate is too high to ignore. Let's redo the boarding model considering this dependence, incorporating a linear dependence model between attendance rate and demand.


```r
# lets make a simple linear model
rate_model <- lm(rate ~ demand, data = flight_dt)

# what we got?
summary(rate_model)
```

```
## 
## Call:
## lm(formula = rate ~ demand, data = flight_dt)
## 
## Residuals:
##       Min        1Q    Median        3Q       Max 
## -0.059294 -0.013465 -0.001671  0.013015  0.102829 
## 
## Coefficients:
##              Estimate Std. Error t value Pr(>|t|)    
## (Intercept) 6.986e-01  8.460e-03   82.57   <2e-16 ***
## demand      1.469e-03  5.606e-05   26.19   <2e-16 ***
## ---
## Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
## 
## Residual standard error: 0.01858 on 728 degrees of freedom
## Multiple R-squared:  0.4852,	Adjusted R-squared:  0.4845 
## F-statistic: 686.1 on 1 and 728 DF,  p-value: < 2.2e-16
```

```r
par(mfrow=c(2,2))
plot(rate_model)
```

<img src="{{< blogdown/postref >}}index.en_files/figure-html/showUpModel-1.png" width="672" />

```r
par(mfrow=c(1,1))
```

Let's change the function that does the simulation by incorporating the dependency model.


```r
# another simulation model considering the dependency between showup rate and demand
simulateDemandShowUpModel <- function(overbook, n, capacity, showup_model) {
  # generate a demand simulation
  demSim <- tibble(demand = rpois(n, demand.pois$estimate))
  # based in showup model calc a predicted showup_rate for each demand
  demSim$predShowup_rate = predict(showup_model, newdata=demSim)
  
  # complete the simulation
  demSim %>% 
    # booked: demand inside capacity (flight seats) 
    mutate( booked = map_dbl(demand, ~min( .x, overbook+capacity ) )) %>% 
    # compute the show-ups and no shows
    mutate( shows    = map2_dbl(booked, predShowup_rate, ~rbinom(1,.x,.y)),
            no_shows = booked - shows ) %>%
    # shop-up rate
    mutate( showup_rate = shows/booked ) %>%
    # calc overbook and empty seats
    mutate( overbooked  = shows - capacity,
            empty_seats = capacity - shows ) %>%
    # remove negative values
    mutate( overbooked  = map_dbl(overbooked, ~max(.x,0)),
            empty_seats = map_dbl(empty_seats, ~max(.x, 0))) %>% 
    return()  
}

# simulating one case ####
sim <- simulateDemandShowUpModel(15,10000,150,rate_model)

# what we got
sim %>% 
  head(10) %>% 
  knitr::kable() %>% 
  kableExtra::kable_styling(font_size = 11)
```

<table class="table" style="font-size: 11px; margin-left: auto; margin-right: auto;">
 <thead>
  <tr>
   <th style="text-align:right;"> demand </th>
   <th style="text-align:right;"> predShowup_rate </th>
   <th style="text-align:right;"> booked </th>
   <th style="text-align:right;"> shows </th>
   <th style="text-align:right;"> no_shows </th>
   <th style="text-align:right;"> showup_rate </th>
   <th style="text-align:right;"> overbooked </th>
   <th style="text-align:right;"> empty_seats </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:right;"> 166 </td>
   <td style="text-align:right;"> 0.9423470 </td>
   <td style="text-align:right;"> 165 </td>
   <td style="text-align:right;"> 156 </td>
   <td style="text-align:right;"> 9 </td>
   <td style="text-align:right;"> 0.9454545 </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:right;"> 0 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 167 </td>
   <td style="text-align:right;"> 0.9438155 </td>
   <td style="text-align:right;"> 165 </td>
   <td style="text-align:right;"> 151 </td>
   <td style="text-align:right;"> 14 </td>
   <td style="text-align:right;"> 0.9151515 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 0 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 175 </td>
   <td style="text-align:right;"> 0.9555641 </td>
   <td style="text-align:right;"> 165 </td>
   <td style="text-align:right;"> 162 </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:right;"> 0.9818182 </td>
   <td style="text-align:right;"> 12 </td>
   <td style="text-align:right;"> 0 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 145 </td>
   <td style="text-align:right;"> 0.9115070 </td>
   <td style="text-align:right;"> 145 </td>
   <td style="text-align:right;"> 135 </td>
   <td style="text-align:right;"> 10 </td>
   <td style="text-align:right;"> 0.9310345 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 15 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 156 </td>
   <td style="text-align:right;"> 0.9276613 </td>
   <td style="text-align:right;"> 156 </td>
   <td style="text-align:right;"> 147 </td>
   <td style="text-align:right;"> 9 </td>
   <td style="text-align:right;"> 0.9423077 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 3 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 154 </td>
   <td style="text-align:right;"> 0.9247241 </td>
   <td style="text-align:right;"> 154 </td>
   <td style="text-align:right;"> 144 </td>
   <td style="text-align:right;"> 10 </td>
   <td style="text-align:right;"> 0.9350649 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 6 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 166 </td>
   <td style="text-align:right;"> 0.9423470 </td>
   <td style="text-align:right;"> 165 </td>
   <td style="text-align:right;"> 154 </td>
   <td style="text-align:right;"> 11 </td>
   <td style="text-align:right;"> 0.9333333 </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:right;"> 0 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 171 </td>
   <td style="text-align:right;"> 0.9496898 </td>
   <td style="text-align:right;"> 165 </td>
   <td style="text-align:right;"> 159 </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:right;"> 0.9636364 </td>
   <td style="text-align:right;"> 9 </td>
   <td style="text-align:right;"> 0 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 173 </td>
   <td style="text-align:right;"> 0.9526269 </td>
   <td style="text-align:right;"> 165 </td>
   <td style="text-align:right;"> 157 </td>
   <td style="text-align:right;"> 8 </td>
   <td style="text-align:right;"> 0.9515152 </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:right;"> 0 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 131 </td>
   <td style="text-align:right;"> 0.8909471 </td>
   <td style="text-align:right;"> 131 </td>
   <td style="text-align:right;"> 123 </td>
   <td style="text-align:right;"> 8 </td>
   <td style="text-align:right;"> 0.9389313 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 27 </td>
  </tr>
</tbody>
</table>

```r
# lets visualize the overbooked passengers distribution
sim %>%  
  count(overbooked) %>% 
  head(10) %>% 
  knitr::kable() %>% 
  kableExtra::kable_styling(font_size = 11)
```

<table class="table" style="font-size: 11px; margin-left: auto; margin-right: auto;">
 <thead>
  <tr>
   <th style="text-align:right;"> overbooked </th>
   <th style="text-align:right;"> n </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 8040 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 208 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:right;"> 197 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:right;"> 196 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:right;"> 214 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:right;"> 209 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:right;"> 199 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:right;"> 189 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 8 </td>
   <td style="text-align:right;"> 172 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 9 </td>
   <td style="text-align:right;"> 121 </td>
  </tr>
</tbody>
</table>

```r
plotdist(sim$overbooked)
```

<img src="{{< blogdown/postref >}}index.en_files/figure-html/simModelShowUpDependency-1.png" width="672" />

We can see that the distribution (for this case of 15 additional accents) spreads out a bit. Now, there are more chances of rearrangement by overbooking, apparently.


```r
# chance to have 2 or less bumped pass
bumped_more_2_dep <- sim %>% 
  count(overbooked) %>% 
  filter(overbooked>2) %>% 
  summarise( total = sum(n) ) %>% 
  unlist()

bumped_more_2_dep
```

```
## total 
##  1555
```

And arguably, only 84% of having two or fewer passengers relocated in this scenario, compared to 93% of the previous scenario. Let's redo the simulation considering various strategies for _overbooking_, as we did in the previous model.


```r
# looking the behavior of the probability to get 2 (or 5) less passengers bumped
# in the new model
tibble(overbook=1:20) %>% 
  mutate( simulation = map(overbook, simulateDemandShowUpModel, n=10000, capacity=150, showup_model= rate_model)) %>% 
  mutate( prob2BumpPass = map_dbl(simulation, probBumpedPass, nPass=2),
          prob5BumpPass = map_dbl(simulation, probBumpedPass, nPass=5)) %>% 
  pivot_longer(cols=c(-overbook, -simulation), names_to = "bumped", values_to = "prob") %>% 
  ggplot(aes(x=overbook, y=prob, color=bumped)) +
  geom_hline(yintercept=0.95, linetype="dashed") + 
  geom_vline(xintercept=8, linetype="dashed", color="pink") +
  geom_vline(xintercept=12, linetype="dashed", color="lightblue") +
  geom_line() +
  geom_point() +
  labs(title="Bumped Passengers (show-up rate dependent)", 
     subtitle = "Chance to bump until 2 passengers (red) or 5 passengers (blue)",
     y="probability", x="seats offered beyond flight capacity") +
  theme_light()
```

<img src="{{< blogdown/postref >}}index.en_files/figure-html/simNewModel-1.png" width="672" />

We get significantly different results when considering that the show-up rate is demand-dependent, so we need to offer far fewer additional seats to maintain an eventual policy of 95% of flights with two or fewer reassigned passengers.

Results for deploying the _overbooking_ policy:
* To have two or fewer passengers relocated on 95% of flights: 8 additional seats
* To have five or fewer passengers relocated on 95% of flights: 12 additional seats

### References

This post is an exercise taken from the [Advanced Business Analytics for Decision Making](https://www.coursera.org/learn/business-analytics-decision-making) course offered by the University of [Boulder Colorado](https://www .colorado.edu/) via [Coursera](https://www.coursera.org/).
