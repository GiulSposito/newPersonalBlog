---
title: Chilling Effect Resulting from Mass Surveillance
author: Giuliano Sposito
date: '2021-03-19'
slug: 'chilling-effect-resulting-from-mass-surveillance'
categories:
  - data science
tags:
  - bit-by-bit book
  - rstats
  - data analysis
subtitle: ''
lastmod: '2021-11-11T14:05:05-03:00'
authorLink: ''
description: ''
hiddenFromHomePage: no
hiddenFromSearch: no
featuredImage: 'images/mass_surveillance_cover.jpg'
featuredImagePreview: 'images/mass_surveillance_cover.jpg'
toc:
  enable: yes
math:
  enable: yes
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


[Jon Penney (2016)](https://papers.ssrn.com/sol3/papers.cfm?abstract_id=2769645)[^1] explored whether the widespread publicity about NSA/PRISM surveillance (i.e., _the Snowden revelations_) in June 2013 was associated with a sharp and sudden decrease in traffic to Wikipedia articles on topics that raise privacy concerns. This post tries to reproduce some of this findings.


<!--more-->

This post is based in one exercise of Matthew J. Salganik's book [Bit by Bit: Social Research in the Digital Age](https://www.amazon.com/Bit-Social-Research-Digital-Age/dp/0691158649), from chapter 2.

### Introduction

[Penney (2016)](https://papers.ssrn.com/sol3/papers.cfm?abstract_id=2769645) explored whether the widespread publicity about [NSA/PRISM](https://en.wikipedia.org/wiki/PRISM_(surveillance_program)) surveillance (i.e., the Snowden revelations) in June 2013 was associated with a sharp and sudden decrease in traffic to Wikipedia articles on topics that raise privacy concerns. If so, this change in behavior would be consistent with a chilling effect resulting from mass surveillance. The approach of Penney (2016) is sometimes called an [interrupted time series design](https://ds4ps.org/pe4ps-textbook/docs/p-020-time-series.html).

To choose the topic keywords, Penney referred to the list used by the US Department of Homeland Security for tracking and monitoring social media. The DHS list categorizes certain search terms into a range of issues, i.e., “Health Concern,” “Infrastructure Security,” and “Terrorism.” For the study group, Penney used the 48 keywords related to “Terrorism” (see appendix [table 8](./keywords_table8.txt)). He then aggregated Wikipedia article view counts on a monthly basis for the corresponding 48 Wikipedia articles over a 32-month period from the beginning of January 2012 to the end of August 2014. To strengthen his argument, he also created several comparison groups by tracking article views on other topics.

Now, we are going to replicate and extend [Penney (2016)](https://papers.ssrn.com/sol3/papers.cfm?abstract_id=2769645). All the raw data that you will need for this activity is available from Wikipedia (https://dumps.wikimedia.org/other/pagecounts-raw/). Or we can get it from the R-package wikipediatrend (Meissner and Team 2016).

### Testing wikipediatrend package


```r
library(tidyverse)
library(wikipediatrend)
library(lubridate)
library(kableExtra)

# download pageviews from R and Python languages
trend_data <-   wp_trend(
  page = c("R_(programming_language)","Python_(programming_language)"), 
  lang = c("en"), 
  from = now()-years(2),
  to   = now()
)

# what we have?
head(trend_data) %>% 
  knitr::kable() %>% 
  kable_styling(font_size = 10)
```

<table class="table" style="font-size: 10px; margin-left: auto; margin-right: auto;">
 <thead>
  <tr>
   <th style="text-align:left;">   </th>
   <th style="text-align:left;"> language </th>
   <th style="text-align:left;"> article </th>
   <th style="text-align:left;"> date </th>
   <th style="text-align:right;"> views </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> 732 </td>
   <td style="text-align:left;"> en </td>
   <td style="text-align:left;"> python_(programming_language) </td>
   <td style="text-align:left;"> 2019-11-15 </td>
   <td style="text-align:right;"> 7301 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> en </td>
   <td style="text-align:left;"> r_(programming_language) </td>
   <td style="text-align:left;"> 2019-11-15 </td>
   <td style="text-align:right;"> 3052 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 733 </td>
   <td style="text-align:left;"> en </td>
   <td style="text-align:left;"> python_(programming_language) </td>
   <td style="text-align:left;"> 2019-11-16 </td>
   <td style="text-align:right;"> 4948 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> en </td>
   <td style="text-align:left;"> r_(programming_language) </td>
   <td style="text-align:left;"> 2019-11-16 </td>
   <td style="text-align:right;"> 2279 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 734 </td>
   <td style="text-align:left;"> en </td>
   <td style="text-align:left;"> python_(programming_language) </td>
   <td style="text-align:left;"> 2019-11-17 </td>
   <td style="text-align:right;"> 5353 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:left;"> en </td>
   <td style="text-align:left;"> r_(programming_language) </td>
   <td style="text-align:left;"> 2019-11-17 </td>
   <td style="text-align:right;"> 2259 </td>
  </tr>
</tbody>
</table>

```r
# ploting
trend_data %>% 
  ggplot(aes(x=date, y=views, color=article)) +
  geom_line() +
  theme_light() +
  theme(legend.position = "bottom") + 
  ylim(0,25000) + 
  labs(title="Daily Page Views",
       subtitle = "Last 2 Years for articles of R and Python in english language")
```

<img src="{{< blogdown/postref >}}index.en_files/figure-html/wikiPackage-1.png" width="672" />

### Reproduction

#### Part A

Read [Penney (2016)](https://papers.ssrn.com/sol3/papers.cfm?abstract_id=2769645) and replicate his figure 2, which shows the page views for “Terrorism”-related pages before and after the Snowden revelations. Interpret the findings.

{{< figure src="./images/fig2.png" title="fig2" >}}


```r
# loading DHS keywords listed as relating to “terrorism”
keywords <- read.delim("./data/keywords_table8.txt") %>% 
  janitor::clean_names()

# lets see it
head(keywords) %>% 
  knitr::kable() %>% 
  kable_styling(font_size = 11)
```

<table class="table" style="font-size: 11px; margin-left: auto; margin-right: auto;">
 <thead>
  <tr>
   <th style="text-align:left;"> topic_keyword </th>
   <th style="text-align:left;"> wikipedia_articles </th>
   <th style="text-align:right;"> government_trouble </th>
   <th style="text-align:right;"> browser_delete </th>
   <th style="text-align:right;"> privacy_sensitive </th>
   <th style="text-align:right;"> avoidance </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> Al Qaeda </td>
   <td style="text-align:left;"> http://en.wikipedia.org/wiki/Al-Qaeda </td>
   <td style="text-align:right;"> 2.20 </td>
   <td style="text-align:right;"> 2.11 </td>
   <td style="text-align:right;"> 2.21 </td>
   <td style="text-align:right;"> 2.84 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Terrorism </td>
   <td style="text-align:left;"> http://en.wikipedia.org/wiki/terrorism </td>
   <td style="text-align:right;"> 2.19 </td>
   <td style="text-align:right;"> 2.05 </td>
   <td style="text-align:right;"> 2.16 </td>
   <td style="text-align:right;"> 2.79 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Terror </td>
   <td style="text-align:left;"> http://en.wikipedia.org/wiki/terror </td>
   <td style="text-align:right;"> 1.98 </td>
   <td style="text-align:right;"> 1.96 </td>
   <td style="text-align:right;"> 2.01 </td>
   <td style="text-align:right;"> 2.64 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Attack </td>
   <td style="text-align:left;"> http://en.wikipedia.org/wiki/attack </td>
   <td style="text-align:right;"> 1.92 </td>
   <td style="text-align:right;"> 1.91 </td>
   <td style="text-align:right;"> 1.92 </td>
   <td style="text-align:right;"> 2.56 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Iraq </td>
   <td style="text-align:left;"> http://en.wikipedia.org/wiki/iraq </td>
   <td style="text-align:right;"> 1.60 </td>
   <td style="text-align:right;"> 1.74 </td>
   <td style="text-align:right;"> 1.76 </td>
   <td style="text-align:right;"> 2.25 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Afghanistan </td>
   <td style="text-align:left;"> http://en.wikipedia.org/wiki/afghanistan </td>
   <td style="text-align:right;"> 1.61 </td>
   <td style="text-align:right;"> 1.71 </td>
   <td style="text-align:right;"> 1.75 </td>
   <td style="text-align:right;"> 2.23 </td>
  </tr>
</tbody>
</table>


```r
# getting wiki trends

# we can call all keywords at once
# but some keywords aren't return values, 
# so let's iterate over each one

# making a "safe version", returning NULL instead of an error
safe_wpTrend <- safely(wp_trend, otherwise = NULL, quiet = T)

# for all keywords
trends <- keywords$wikipedia_articles %>% 
  # extract from "url" the article name
  str_extract("(?<=wiki/)(.*)") %>% 
  # for each article, download the historic page views
  map_df(function(.kw){
    # "...over a 32-month period from the beginning of January 2012 to the end of August 2014..."
    trends_resp <- safe_wpTrend(
      page = .kw, 
      lang = c("en"), 
      from = "2012-01-01",
      to   = "2014-06-30" # removing last two months because they are returning 0 views
    )
    # will return NULL inst
    return(trends_resp$result)
  }) 

# "...aggregated Wikipedia article view counts on a monthly basis..."
terrorism_articles <- trends %>% 
  # remove some zeros from data
  filter( views > 0) %>% 
  # group by "month" and sums the pageviews
  mutate(date = floor_date(date, "month") ) %>% 
  group_by(date) %>% 
  summarise( views = sum(views) ) %>% 
  # mark the data related pre/pos Snowden revelations in June 2013
  mutate( trend = if_else(date < ymd("20130601"), "Terrorism Article Trend Pre-June","Terrorism Article Trend Post-June") ) %>% 
  ungroup()

# Let's see the data
terrorism_articles %>% 
  ggplot(aes(x=date, y=views, color=trend)) +
    geom_point(size=2.5) +
    # ... the Snowden revelations in June 2013...
    geom_vline(xintercept = ymd("20130515"), color="dark grey", linetype="dashed", size=1) +
    geom_smooth(method = "lm", formula = y~x) + 
    theme_minimal() +
    theme( legend.position = "bottom") +
    labs(title="Pre and After June 13 Articles Trends", 
         subtitle="Terrorism related keywords",
         x="date",y="monthly page views")
```

<img src="{{< blogdown/postref >}}index.en_files/figure-html/fig2-1.png" width="672" />


#### Part B

Next, replicate figure 4A, which compares the study group (“Terrorism”-related articles) with a comparator group using keywords categorized under “DHS & Other Agencies” from the DHS list (see appendix [table 10](./keywords_table10.txt) and footnote 139). Interpret the findings.

{{< figure src="./images/fig4a.png" title="fig 4A" >}}


```r
# load table 10
comp_table <- read.delim("./data/keywords_table10.txt") %>% 
  janitor::clean_names()

# lets see
head(comp_table) %>% 
  knitr::kable() %>% 
  kable_styling(font_size = 11)
```

<table class="table" style="font-size: 11px; margin-left: auto; margin-right: auto;">
 <thead>
  <tr>
   <th style="text-align:left;"> topic_keyword </th>
   <th style="text-align:left;"> wikipedia_articles </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> Department of Homeland Security </td>
   <td style="text-align:left;"> https://en.wikipedia.org/wiki/United_States_Department_of_Homeland_Security </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Federal Emergency Management Agency </td>
   <td style="text-align:left;"> https://en.wikipedia.org/wiki/Federal_Emergency_Management_Agency </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Coast Guard </td>
   <td style="text-align:left;"> https://en.wikipedia.org/wiki/Coast_guard </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Customs and Border Protection </td>
   <td style="text-align:left;"> https://en.wikipedia.org/wiki/Customs_and_Border_Protection </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Border patrol </td>
   <td style="text-align:left;"> https://en.wikipedia.org/wiki/Border_Patrol </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Secret Service </td>
   <td style="text-align:left;"> https://en.wikipedia.org/wiki/Secret_Service </td>
  </tr>
</tbody>
</table>

```r
# get the trends
comp_trends <- comp_table$wikipedia_articles %>% 
  str_extract("(?<=wiki/)(.*)") %>% 
  str_to_lower() %>% 
  map_df(function(.kw){
    # "...over a 32-month period from the beginning of January 2012 to the end of August 2014..."
    trends_resp <- safe_wpTrend(
      page = .kw, 
      lang = c("en"), 
      from = "2012-01-01",
      to   = "2014-06-30"
    )
    # will return NULL inst
    return(trends_resp$result)
  })

# "...aggregated Wikipedia article view counts on a monthly basis..."
sec_articles <- comp_trends %>% 
  filter( views > 0 ) %>% 
  mutate(date = floor_date(date, "month") ) %>% 
  group_by(date) %>% 
  summarise( views = sum(views) ) %>% 
   # ... the Snowden revelations in June 2013...
  mutate( trend = if_else(date < ymd("20130601"),
                    "Control Group Articles Trend Pre-June",
                    "Control Group Articles Trend Post-June") ) %>% 
  ungroup()

sec_articles %>% 
  bind_rows(terrorism_articles) %>% 
  ggplot(aes(x=date, y=views, color=trend)) +
    geom_point(size=2) +
    geom_vline(xintercept = ymd("20130515"), color="dark grey", 
               linetype="dashed", size=1) +
    geom_smooth(method = "lm", formula = y~x) + 
    theme_minimal() +
    theme( legend.position = "right" ) +
    labs(title="Pre and After June 13 Articles Trends", 
         subtitle="Terrorism related keywords and Control Group",
         x="date",y="monthly page views")
```

<img src="{{< blogdown/postref >}}index.en_files/figure-html/domesticLoading-1.png" width="672" />

### Extra

#### The Statistical Model

From Jesse Lecy and Federica Fusi's [Interrupted Time Series](https://ds4ps.org/pe4ps-textbook/docs/p-020-time-series.html#the-statistical-model)[^2] we have the following scenario:

{{< figure src="./images/Picture3.4.png" title="" >}}

In mathematical terms, it means that the time series equation includes four key coefficients:

$$ Y=b_{0}+b_{1}T+b_{2}D+b_{3}P+e $$

Where:
* $ Y $ is the outcome variable;
* $ T $ is a continuous variable which indicates the time (e.g., days, months, years…) passed from the start of the observational period;
* $ D $ is a dummy variable indicating observation collected before (=0) or after (=1) the policy intervention;
* $ P $ is a continuous variable indicating time passed since the intervention has occured (before intervention has occured P is equal to 0).

To model this, We would to have a dataset with this format:


{{< figure src="./images/Picture5.png" title="" >}}


So, let's build ours



```r
# building the dummy vars
regr_data <- trends %>% 
  # group trends by months
  filter( views > 0 ) %>%
  mutate( date = floor_date(date, unit = "month")) %>% 
  group_by( date ) %>% 
  summarise( views = sum(views) ) %>% 
  ungroup() %>%
  arrange(date) %>%
  mutate(
    T = row_number(),         # time var
    D = if_else(T<=18,0,1),   # post-event data 18 is 2013-06-01
    P = if_else(T<=18,0,T-18) # post event time var
  ) %>% 
  rename( Y=views ) # just to make equal to the model
  
# what we have
regr_data %>% 
  filter( T>14, T<=22) %>% 
  knitr::kable() %>% 
  kable_styling(font_size = 11)
```

<table class="table" style="font-size: 11px; margin-left: auto; margin-right: auto;">
 <thead>
  <tr>
   <th style="text-align:left;"> date </th>
   <th style="text-align:right;"> Y </th>
   <th style="text-align:right;"> T </th>
   <th style="text-align:right;"> D </th>
   <th style="text-align:right;"> P </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> 2013-03-01 </td>
   <td style="text-align:right;"> 3868814 </td>
   <td style="text-align:right;"> 15 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 0 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2013-04-01 </td>
   <td style="text-align:right;"> 3595489 </td>
   <td style="text-align:right;"> 16 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 0 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2013-05-01 </td>
   <td style="text-align:right;"> 3235093 </td>
   <td style="text-align:right;"> 17 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 0 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2013-06-01 </td>
   <td style="text-align:right;"> 2725519 </td>
   <td style="text-align:right;"> 18 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 0 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2013-07-01 </td>
   <td style="text-align:right;"> 2399060 </td>
   <td style="text-align:right;"> 19 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 1 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2013-08-01 </td>
   <td style="text-align:right;"> 2451065 </td>
   <td style="text-align:right;"> 20 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 2 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2013-09-01 </td>
   <td style="text-align:right;"> 2559672 </td>
   <td style="text-align:right;"> 21 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 3 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2013-10-01 </td>
   <td style="text-align:right;"> 2550031 </td>
   <td style="text-align:right;"> 22 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 4 </td>
  </tr>
</tbody>
</table>


```r
# building the model
mod1 <- lm( Y ~ T + D + P, data=regr_data )

# let's see
regr_data %>% 
  mutate( pred = predict(mod1) ) %>% 
  ggplot(aes(x=date, color=D)) +
  geom_point(aes(y=Y)) +
  geom_line(aes(y=pred)) +
  geom_vline(xintercept = ymd(20130615), linetype="dashed", size=1) +
  theme_minimal() +
  theme( legend.position = "none" )+
  labs(
    title="Pre and After June 13 Articles Trends", 
    subtitle="Empirical Data and Model Prediction",
    x="Date", y="Monthly Page Views")
```

<img src="{{< blogdown/postref >}}index.en_files/figure-html/statModel-1.png" width="672" />



```r
summary(mod1)
```

```
## 
## Call:
## lm(formula = Y ~ T + D + P, data = regr_data)
## 
## Residuals:
##     Min      1Q  Median      3Q     Max 
## -775138 -288426   57308  195202  842379 
## 
## Coefficients:
##             Estimate Std. Error t value Pr(>|t|)    
## (Intercept)  2579316     194174  13.284 4.27e-13 ***
## T              51186      17939   2.853  0.00838 ** 
## D           -1078677     301608  -3.576  0.00140 ** 
## P             -59553      37578  -1.585  0.12510    
## ---
## Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
## 
## Residual standard error: 394900 on 26 degrees of freedom
## Multiple R-squared:  0.5415,	Adjusted R-squared:  0.4886 
## F-statistic: 10.23 on 3 and 26 DF,  p-value: 0.0001255
```

We can see the significant drop in the moment of the event $ D $ and also a change in the trend after $ P $ compared to $ T $.

### Statistical Model: Control Group

Yet from Jesse Lecy and Federica Fusi's [Interrupted Time Series](https://ds4ps.org/pe4ps-textbook/docs/p-020-time-series.html#validity-threats-control-groups-and-multiple-time-series)

A time series are also subject to threats to internal validity, such as:

* Another event occurred at the same time of the intervention and cause the immediate and sustained effect that we observe;
* Selection processes, as only some individuals are affected by the policy intervention.

To address these issues, you can:

* Use as a control a group that is not subject to the intervention (e.g., students who do not attend the well being class)

This design makes sure that the observed effect is the result of the policy intervention. The data will have two observations per each point in time and will include a dummy variable to differentiate the treatment (=1) and the control (=0). The model has a similar structure but (1) we will include a dummy variable that indicates the treatment and the control group and (2) we will interact the group dummy variable with all 3 time serie coefficients to see if there is a statistically significant difference across the 2 groups.

{{< figure src="./images/Picture10.1.png" title="" >}}

You can see this in the following equation, where $ G $ is a dummy indicating treatment and control group.

$$ Y=b_{0}+b_{1}∗T+b_{2}∗D+b_{3}∗P+b_{4}∗G+b_{5}∗G∗T+b_{6}∗G∗D+b_{7}∗G∗P $$


```r
# building the dataset with control group
regr_control <- comp_trends %>%
  # summarise by monthly
  filter( views > 0 ) %>%
  mutate( date = floor_date(date, unit = "month")) %>% 
  group_by( date ) %>% 
  summarise( views = sum(views) ) %>% 
  ungroup() %>% 
  mutate(
    T = row_number(),         # Time var in months
    D = if_else(T<=18,0,1),   # Mark Pre/Pos event data, 18 is 2013-06-01
    P = if_else(T<=18,0,T-18),# Time after the event
    G=0                       # Control Group is 0
  ) %>% 
  rename( Y=views ) %>% 
  # add the effected data marked as treatment data
  bind_rows( mutate(regr_data, G=1 ))

# let's see
regr_control %>% 
  filter( T>15, T<=21) %>%
  arrange(T,D,G,P) %>% 
  knitr::kable()  %>% 
  kable_styling(font_size = 11)
```

<table class="table" style="font-size: 11px; margin-left: auto; margin-right: auto;">
 <thead>
  <tr>
   <th style="text-align:left;"> date </th>
   <th style="text-align:right;"> Y </th>
   <th style="text-align:right;"> T </th>
   <th style="text-align:right;"> D </th>
   <th style="text-align:right;"> P </th>
   <th style="text-align:right;"> G </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> 2013-04-01 </td>
   <td style="text-align:right;"> 1032305 </td>
   <td style="text-align:right;"> 16 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 0 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2013-04-01 </td>
   <td style="text-align:right;"> 3595489 </td>
   <td style="text-align:right;"> 16 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 1 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2013-05-01 </td>
   <td style="text-align:right;"> 873192 </td>
   <td style="text-align:right;"> 17 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 0 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2013-05-01 </td>
   <td style="text-align:right;"> 3235093 </td>
   <td style="text-align:right;"> 17 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 1 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2013-06-01 </td>
   <td style="text-align:right;"> 747513 </td>
   <td style="text-align:right;"> 18 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 0 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2013-06-01 </td>
   <td style="text-align:right;"> 2725519 </td>
   <td style="text-align:right;"> 18 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 1 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2013-07-01 </td>
   <td style="text-align:right;"> 632677 </td>
   <td style="text-align:right;"> 19 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 0 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2013-07-01 </td>
   <td style="text-align:right;"> 2399060 </td>
   <td style="text-align:right;"> 19 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 1 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2013-08-01 </td>
   <td style="text-align:right;"> 641141 </td>
   <td style="text-align:right;"> 20 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:right;"> 0 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2013-08-01 </td>
   <td style="text-align:right;"> 2451065 </td>
   <td style="text-align:right;"> 20 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:right;"> 1 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2013-09-01 </td>
   <td style="text-align:right;"> 705947 </td>
   <td style="text-align:right;"> 21 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:right;"> 0 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2013-09-01 </td>
   <td style="text-align:right;"> 2559672 </td>
   <td style="text-align:right;"> 21 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:right;"> 1 </td>
  </tr>
</tbody>
</table>



```r
# lets fit the model
mod2 <- lm( Y ~ T + D + P + G + G*T + G*D + G*P, data=regr_control )

summary(mod2)
```

```
## 
## Call:
## lm(formula = Y ~ T + D + P + G + G * T + G * D + G * P, data = regr_control)
## 
## Residuals:
##     Min      1Q  Median      3Q     Max 
## -775138 -161714   28511  136682  842379 
## 
## Coefficients:
##             Estimate Std. Error t value Pr(>|t|)    
## (Intercept)   743019     151953   4.890 1.01e-05 ***
## T              10751      14038   0.766  0.44724    
## D             -86033     236027  -0.365  0.71696    
## P              -4588      29407  -0.156  0.87662    
## G            1836297     214894   8.545 1.77e-11 ***
## T:G            40435      19853   2.037  0.04678 *  
## D:G          -992644     333792  -2.974  0.00445 ** 
## P:G           -54965      41587  -1.322  0.19206    
## ---
## Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
## 
## Residual standard error: 309000 on 52 degrees of freedom
## Multiple R-squared:  0.924,	Adjusted R-squared:  0.9137 
## F-statistic: 90.28 on 7 and 52 DF,  p-value: < 2.2e-16
```

To interpret the coefficients you need to remember that the reference group is the treatment group (=1). The Group dummy $ b_{4} $ (coef $ G $) indicates the difference between the treatment and the control group. $ b_{5} $ (coef $ T:G $) represents the slope difference between the intervention and control group in the pre-intervention period. $ b_{6} $ (coef $ D:G $) represents the difference between the control and intervention group associated with the intervention. $ b_{7} $ (coef $ P:G $) represents the difference between the sustained effect of the control and intervention group after the intervention.


```r
# can we see the points (trend and control) and the model fitted
regr_control %>% 
  mutate(pred = predict(mod2)) %>%
  mutate( article = factor(G, labels = c("control","terror related"))) %>% 
  ggplot(aes(x=date, color=article, group=article)) +
  geom_point(aes(y=Y)) +
  geom_line(aes(y=pred)) +
  labs(title="Monthly Page Views",
       subtitle = "Terrorism Related Articles vs Control Group",
       y="page views") +
  theme_minimal()
```

<img src="{{< blogdown/postref >}}index.en_files/figure-html/unnamed-chunk-2-1.png" width="672" />


### Extra II

#### Finding Change Points in Time Series

After these analysis I was thinking if is possible to find automatically a change points in time series. The _Interrupted Time Series_ analysis assume a "change point" and check if the series, in fact, changes its behavior. How to check if this is a transition point indeed? As we know a linear regression made of arbitrary choice of points (interval in this case) can find false patterns.

Indeed, there is a plenty of R Packages can detect change points in a time series, ideal to make this type of analysis more robust. [Jonas Kristoffer Lindeløv](https://twitter.com/jonaslindeloev) compared some of these packages in [this vignette](https://lindeloev.github.io/mcp/articles/packages.html) of your [own new package](https://lindeloev.net/mcp-regression-with-multiple-change-points/): the [mcp package](https://lindeloev.github.io/mcp/) to detect and do regressions with [multiple change points](https://twitter.com/jonaslindeloev/status/1181515695948996609).

Let's try use this package in your scenario:


```r
library(mcp)

# lets detect "two" linear trends
# with interruption in the time series
models <- list( Y ~ 1 + T, ~ 1 + T)

# fit the models
set.seed(42)
fit_mcp <- mcp(models, data=regr_data, par_x = "T")
```

```
## Compiling model graph
##    Resolving undeclared variables
##    Allocating nodes
## Graph information:
##    Observed stochastic nodes: 30
##    Unobserved stochastic nodes: 6
##    Total graph size: 446
## 
## Initializing model
```

```r
# checking what we find
plot(fit_mcp)
```

<img src="{{< blogdown/postref >}}index.en_files/figure-html/mcpPackage-1.png" width="672" />

```r
# see the parameters
fit_mcp
```

```
## Family: gaussian(link = 'identity')
## Iterations: 9000 from 3 chains.
## Segments:
##   1: Y ~ 1 + T
##   2: Y ~ 1 ~ 1 + T
## 
## Population-level parameters:
##     name    mean    lower   upper Rhat n.eff
##     cp_1      17  8.6e+00      19  1.2   216
##    int_1 2617605  2.2e+06 3031343  1.3    58
##    int_2 2549948  2.1e+06 3567887  1.6    26
##  sigma_1  392620  2.8e+05  514340  1.0   545
##      T_1   45681 -1.2e+04   98605  1.5    22
##      T_2  -12569 -7.5e+04   30097  1.0  1213
```

That is cool, we can see that we detect a change point ( parameter $ cp_{1} $ ) around the 16o period, that is june, in your dataset. The model also show us the parameters fitted in each linear regression ( $ int $ for intercepts and $ T $ for slopes).

### References

[^1]: Penney, Jonathon. 2016. “Chilling Effects: Online Surveillance and Wikipedia Use.” Berkeley Technology Law Journal 31 (1): 117. doi:10.15779/Z38SS13. - https://papers.ssrn.com/sol3/papers.cfm?abstract_id=2769645

[^2]: Jesse Lecy and Federica Fusi. "Foundations of Program Evaluation: Regression Tools for Impact Analysis" - https://ds4ps.org/pe4ps-textbook/docs/index.html
