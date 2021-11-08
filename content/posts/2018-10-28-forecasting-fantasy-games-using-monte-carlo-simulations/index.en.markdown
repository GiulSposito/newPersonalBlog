---
title: Forecasting Fantasy Games Using Monte Carlo Simulations
author: Giuliano Sposito
date: '2018-10-28'
slug: 'forecasting-fantasy-games-using-monte-carlo-simulations'
categories:
  - data science
tags:
  - rstats
  - monte carlo
  - simulation
  - nfl
  - fantasy
subtitle: ''
lastmod: '2021-11-07T21:59:19-03:00'
authorLink: ''
description: ''
hiddenFromHomePage: no
hiddenFromSearch: no
featuredImage: 'images/fantasy_montecarlo_cover.jpg'
featuredImagePreview: 'images/fantasy_montecarlo_cover.jpg'
toc:
  enable: yes
math:
  enable: no
lightgallery: no
license: ''
disqusIdentifier: 'forecasting-fantasy-games-using-monte-carlo-simulations'
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

The football season is back, and with it the Fantasy Game! In this post, we will simulate the results and the scoring of my Fantasy League games. To do that, we'll project the scoring of teams using `Monte Carlo` simulation with data scraped from sites that predicts players' performances. We will combine the various possible scores of a team's players to estimate the team's score distribution, and then compare with the opposing team, and finally compute each team's chances of winning and losing.

<!--more-->

### Abstract

The season of [American football](https://en.wikipedia.org/wiki/American_football) is back, and with it the [Fantasy](http://fantasy.nfl.com/), the already traditional online game which you bring your friends or coworkers to play together in a virtual league, where each member rosters [NFL's](https://www.nfl.com/) players on virtual teams and hoping that they will score well in their real life games. The real life player's score goes to your virtual team score.

### ffanalytics package

The PhD in clinical psychology and assistant professor [Isaac Petersen](https://fantasyfootballanalytics.net/2013/03/isaac-petersen.html) author of the site [Fantasy Football Analytics](https://fantasyfootballanalytics.net), who does projections and analysis of Fantasy results, did a great job with the [ffanalytics package](https://fantasyfootballanalytics.net/2016/06/ffanalytics-r-package-fantasy-football-data-analysis.html) made available in [GitHub](https://github.com/FantasyFootballAnalytics/ffanalytics).

This package does [`data scrapping`](https://fantasyfootballanalytics.net/2014/06/scraping-fantasy-football-projections.html) in various sites that make predictions of player's performances such as [ESPN](https://games.espn.com/ffl/tools/projections), [CBS](https://www.cbssports.com/fantasy/football/stats/), [Yahoo](https://sports.yahoo.com/news/week-8-fantasy-football-rankings-helping-set-lineup-210614393.html) and the [NFL](http://m.fantasy.nfl.com/research/projections) website itself, after, applies the fantasy scoring rules (which can even be [cutomized](https://github.com/FantasyFootballAnalytics/ffanalytics/blob/master/R/scoring_rules.R) for your League) and [calculates the score](https://fantasyfootballanalytics.net/2014/06/custom-rankings-and-projections-for-your-league.html) possible for each of the projections.

Finally, the package analyzes the points obtained by making [performance projections](https://fantasyfootballanalytics.net/2014/06/custom-rankings-and-projections-for-your-league.html) of the results, aggregating in one vision the predictions of several sites. Isaac publishes weekly the [ranking of projections](https://fantasyfootballanalytics.net/2018/10/gold-mining-week-7-2018.html) by position for the games of the round, using some standards scoring rules.

With all the hard work of doing `data scrapping` and apply the rules of fantasy to calculate the score already made by the package, we can use these informations to project the results of teams scaled in fantasy leagues and to forecast game results, remaining only to obtain the teams and their rosters from Fantasy itself.



### Fantasy API - Getting the Team's Matchups and Rosters

In order to obtain the rounds of a fantasy league, we can use the [Web API](http://api.fantasy.nfl.com/) available by the Fantasy website. Although it has some *depreciated* methods they still work and serve the purpose of getting the information we want. In particular we need access the methods that tells us which games
[`/league/matchups`](http://api.fantasy.nfl.com/v1/docs/service?serviceName=leagueMatchups) is schedule for a week. This API receives as input parameters the authentication `token`, the` id` of the league and the `week` of interest, returning the games scheduled for that week. We also will use the API [`/league/team/matchup`](http://api.fantasy.nfl.com/v1/docs/service?serviceName=leagueTeamMatchup) that, in addition to the above parameters, also gets the team id to return the team roster.

We can invoke the API using the `httr` package and process the response json using` jsonlite`.


```r
# Storing the Access Token and League ID locally
# I use a yalm file to avoid hard-code them 
# or eventually version them in the GitHub :)
library(yaml)

config <- yaml.load_file("../../config/config.yml")
leagueId <- config$leagueId
authToken <- config$authToken
```




```r
# invoking the API
library(httr)
library(glue) # to easily replace vars in the url

# league/matchups url
url <- "http://api.fantasy.nfl.com/v1/league/matchups?leagueId={leagueId}&week={week}&format=json&authToken={authToken}"
week <- 5

# call the api
resp <- httr::GET(glue(url))
```


```r
# Is it ok?
resp$status_code
```

```
## [1] 200
```

Once the call response is obtained, we treat the return * json * to organize the data and obtain the team rosters.


```r
library(jsonlite)
library(tidyverse)
library(kableExtra)

# to convert the json in a "tabular-tibble form"
resp %>% 
  httr::content(as="text") %>%
  fromJSON(simplifyDataFrame = T) %$%  
  leagues %$%
  matchups %>%
  .[[1]] %>% 
  jsonlite::flatten() %>% 
  as.tibble() -> matchups

 matchups %>% 
   select(awayTeam.id, awayTeam.name, homeTeam.name, homeTeam.id) %>% 
   kable() %>%
   kable_styling(bootstrap_options = "striped", full_width = F, font_size = 11)
```

<table class="table table-striped" style="font-size: 11px; width: auto !important; margin-left: auto; margin-right: auto;">
 <thead>
  <tr>
   <th style="text-align:left;"> awayTeam.id </th>
   <th style="text-align:left;"> awayTeam.name </th>
   <th style="text-align:left;"> homeTeam.name </th>
   <th style="text-align:left;"> homeTeam.id </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> Change Robots </td>
   <td style="text-align:left;"> Rio Claro Pfeiferians </td>
   <td style="text-align:left;"> 6 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 7 </td>
   <td style="text-align:left;"> NJ's Bugre </td>
   <td style="text-align:left;"> Sorocaba Steelers </td>
   <td style="text-align:left;"> 5 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 11 </td>
   <td style="text-align:left;"> Campinas Giants </td>
   <td style="text-align:left;"> Amparo Bikers </td>
   <td style="text-align:left;"> 4 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> Sorocaba Wild Mules </td>
   <td style="text-align:left;"> Indaiatuba Riders </td>
   <td style="text-align:left;"> 3 </td>
  </tr>
</tbody>
</table>

We make new calls to the API to get the roster of each team in that week.



```r
# for each teamIds in the matchup
c(matchups$awayTeam.id) %>%
  map(
    function(.teamId, .week, .leagueId, .authToken, .url) {
      # make the API call
      httr::GET(glue(.url)) %>%
        httr::content(as = "text") %>%
        fromJSON(simplifyDataFrame = T) %>% # transform response body in json
        return()
    },
    .week      = week,
    .leagueId  = leagueId,
    .authToken = authToken,
    .url       = "http://api.fantasy.nfl.com/v1/league/team/matchup?leagueId={.leagueId}&teamId={.teamId}&week={.week}&authToken={.authToken}&format=json"
  )  -> rosters.json
```



```r
# this is a list with the team rosters used in this week
rosters.json[[1]]$leagues$matchup$homeTeam$name
```

```
## [1] "Rio Claro Pfeiferians"
```

```r
rosters.json[[1]]$leagues$matchup$homeTeam$players[[1]] %>%
  select(id, name, position, teamAbbr) %>% 
  as.tibble() %>% 
   kable() %>%
   kable_styling(bootstrap_options = "striped", full_width = F, font_size = 11)
```

<table class="table table-striped" style="font-size: 11px; width: auto !important; margin-left: auto; margin-right: auto;">
 <thead>
  <tr>
   <th style="text-align:left;"> id </th>
   <th style="text-align:left;"> name </th>
   <th style="text-align:left;"> position </th>
   <th style="text-align:left;"> teamAbbr </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> 2558125 </td>
   <td style="text-align:left;"> Patrick Mahomes </td>
   <td style="text-align:left;"> QB </td>
   <td style="text-align:left;"> KC </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2507164 </td>
   <td style="text-align:left;"> Adrian Peterson </td>
   <td style="text-align:left;"> RB </td>
   <td style="text-align:left;"> WAS </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2543773 </td>
   <td style="text-align:left;"> James White </td>
   <td style="text-align:left;"> RB </td>
   <td style="text-align:left;"> NE </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2508061 </td>
   <td style="text-align:left;"> Antonio Brown </td>
   <td style="text-align:left;"> WR </td>
   <td style="text-align:left;"> PIT </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2556370 </td>
   <td style="text-align:left;"> Michael Thomas </td>
   <td style="text-align:left;"> WR </td>
   <td style="text-align:left;"> NO </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2558266 </td>
   <td style="text-align:left;"> George Kittle </td>
   <td style="text-align:left;"> TE </td>
   <td style="text-align:left;"> SF </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2555430 </td>
   <td style="text-align:left;"> Alex Collins </td>
   <td style="text-align:left;"> RB </td>
   <td style="text-align:left;"> BAL </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 1581 </td>
   <td style="text-align:left;"> DeSean Jackson </td>
   <td style="text-align:left;"> WR </td>
   <td style="text-align:left;"> TB </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2540158 </td>
   <td style="text-align:left;"> Zach Ertz </td>
   <td style="text-align:left;"> TE </td>
   <td style="text-align:left;"> PHI </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2540160 </td>
   <td style="text-align:left;"> Jordan Reed </td>
   <td style="text-align:left;"> TE </td>
   <td style="text-align:left;"> WAS </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2558063 </td>
   <td style="text-align:left;"> Deshaun Watson </td>
   <td style="text-align:left;"> QB </td>
   <td style="text-align:left;"> HOU </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2558865 </td>
   <td style="text-align:left;"> Chris Carson </td>
   <td style="text-align:left;"> RB </td>
   <td style="text-align:left;"> SEA </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2559169 </td>
   <td style="text-align:left;"> Austin Ekeler </td>
   <td style="text-align:left;"> RB </td>
   <td style="text-align:left;"> LAC </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2507232 </td>
   <td style="text-align:left;"> Mason Crosby </td>
   <td style="text-align:left;"> K </td>
   <td style="text-align:left;"> GB </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 100011 </td>
   <td style="text-align:left;"> Green Bay Packers </td>
   <td style="text-align:left;"> DEF </td>
   <td style="text-align:left;"> GB </td>
  </tr>
</tbody>
</table>

With the team's rosters (*json* format) we process the data to facilitate the handling.


```r
# auxiliar transformation to extract team roster
extractTeam <- . %>% 
  .$players %>% 
  .[[1]] %>% 
  select( src_id=id, name, position, rosterSlot, fantasyPts ) %>%
  jsonlite::flatten() %>% 
  as.tibble() %>% 
  select(-fantasyPts.week.season, -fantasyPts.week.week ) %>% 
  rename(points = fantasyPts.week.pts) %>% 
  mutate(
    src_id = as.integer(src_id), 
    points = as.numeric(points)
  )

# extract each roster
rosters.json %>% 
  map(function(.json){
    matchup <- .json$leagues$matchup
    tibble(
      home.teamId = as.integer(matchup$homeTeam$id),
      home.name   = matchup$homeTeam$name,
      home.logo   = matchup$homeTeam$logoUrl,
      home.pts    = as.numeric(matchup$homeTeam$pts),
      home.roster = list(extractTeam(matchup$homeTeam)),
      away.teamId = as.integer(matchup$awayTeam$id),
      away.name   = matchup$awayTeam$name,
      away.logo   = matchup$awayTeam$logoUrl,
      away.pts    = as.numeric(matchup$awayTeam$pts),
      away.roster = list(extractTeam(matchup$awayTeam))
    ) %>% 
      return()
  }) %>% bind_rows() -> matchups.rosters

# check the matchups QBs for each team 
matchups.rosters %>% 
  mutate( away.qb = map(away.roster, function(roster) roster %>% filter(rosterSlot=="QB")),
          home.qb = map(home.roster, function(roster) roster %>% filter(rosterSlot=="QB")) ) %>%
  unnest(away.qb, home.qb, .sep=".") %>% 
  select(away.team = away.name, away.qb.name, home.qb.name, home.team=home.name ) %>% 
   kable() %>%
   kable_styling(bootstrap_options = "striped", full_width = F, font_size = 11)
```

<table class="table table-striped" style="font-size: 11px; width: auto !important; margin-left: auto; margin-right: auto;">
 <thead>
  <tr>
   <th style="text-align:left;"> away.team </th>
   <th style="text-align:left;"> away.qb.name </th>
   <th style="text-align:left;"> home.qb.name </th>
   <th style="text-align:left;"> home.team </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> Change Robots </td>
   <td style="text-align:left;"> Aaron Rodgers </td>
   <td style="text-align:left;"> Patrick Mahomes </td>
   <td style="text-align:left;"> Rio Claro Pfeiferians </td>
  </tr>
  <tr>
   <td style="text-align:left;"> NJ's Bugre </td>
   <td style="text-align:left;"> Russell Wilson </td>
   <td style="text-align:left;"> Ben Roethlisberger </td>
   <td style="text-align:left;"> Sorocaba Steelers </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Campinas Giants </td>
   <td style="text-align:left;"> Tom Brady </td>
   <td style="text-align:left;"> Drew Brees </td>
   <td style="text-align:left;"> Amparo Bikers </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Sorocaba Wild Mules </td>
   <td style="text-align:left;"> Matt Ryan </td>
   <td style="text-align:left;"> Cam Newton </td>
   <td style="text-align:left;"> Indaiatuba Riders </td>
  </tr>
</tbody>
</table>

Now we have a `tibble` with the games between the teams and, nested in each  registry, the respective rosters. Now you will need to use `ffanalytis package` to get the prediction performance and score of each player.

### Forecast players perform

Firstly, we will use the `ffanalytics package` to do the data scraping of the forecasts for each player in the league made by the main sites that follow and make this type of prediction.


```r
library(ffanalytics)
scrap <- scrape_data(pos = c("QB", "RB", "WR", "TE", "K", "DST"),
                     season = 2018,
                     week = week)
```


The `scrape_data` function returns a list by position, with the performance projections of the players in that position. This is because the predictions for each position have different attributes, for example, *Kickers* are evaluated by the number of *field goals* and distances of the kicks, and *Quaterbacks* by the numbers and distances of the passes.


```r
# Quaterback Projection Attributes
scrap$QB %>%  
  filter(player=="Drew Brees") %>% 
  select(4:10) %>% 
   kable() %>%
   kable_styling(bootstrap_options = "striped", full_width = F, font_size = 11)
```

<table class="table table-striped" style="font-size: 11px; width: auto !important; margin-left: auto; margin-right: auto;">
 <thead>
  <tr>
   <th style="text-align:left;"> player </th>
   <th style="text-align:left;"> team </th>
   <th style="text-align:right;"> pass_att </th>
   <th style="text-align:right;"> pass_comp </th>
   <th style="text-align:right;"> pass_yds </th>
   <th style="text-align:right;"> pass_tds </th>
   <th style="text-align:right;"> pass_int </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> Drew Brees </td>
   <td style="text-align:left;"> NO </td>
   <td style="text-align:right;"> 37.60 </td>
   <td style="text-align:right;"> 26.10 </td>
   <td style="text-align:right;"> 287.00 </td>
   <td style="text-align:right;"> 2.00 </td>
   <td style="text-align:right;"> 0.70 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Drew Brees </td>
   <td style="text-align:left;"> NO </td>
   <td style="text-align:right;"> 37.30 </td>
   <td style="text-align:right;"> 26.20 </td>
   <td style="text-align:right;"> 272.70 </td>
   <td style="text-align:right;"> 1.70 </td>
   <td style="text-align:right;"> 0.60 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Drew Brees </td>
   <td style="text-align:left;"> NO </td>
   <td style="text-align:right;"> 38.20 </td>
   <td style="text-align:right;"> 26.50 </td>
   <td style="text-align:right;"> 305.00 </td>
   <td style="text-align:right;"> 1.90 </td>
   <td style="text-align:right;"> 0.60 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Drew Brees </td>
   <td style="text-align:left;"> NO </td>
   <td style="text-align:right;"> 44.00 </td>
   <td style="text-align:right;"> 29.00 </td>
   <td style="text-align:right;"> 305.00 </td>
   <td style="text-align:right;"> 3.00 </td>
   <td style="text-align:right;"> 1.00 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Drew Brees </td>
   <td style="text-align:left;"> NO </td>
   <td style="text-align:right;"> 38.20 </td>
   <td style="text-align:right;"> 26.60 </td>
   <td style="text-align:right;"> 305.00 </td>
   <td style="text-align:right;"> 2.00 </td>
   <td style="text-align:right;"> 0.60 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Drew Brees </td>
   <td style="text-align:left;"> NO </td>
   <td style="text-align:right;"> 39.51 </td>
   <td style="text-align:right;"> 25.99 </td>
   <td style="text-align:right;"> 309.47 </td>
   <td style="text-align:right;"> 2.51 </td>
   <td style="text-align:right;"> 0.63 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Drew Brees </td>
   <td style="text-align:left;"> NO </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:right;"> 283.36 </td>
   <td style="text-align:right;"> 1.94 </td>
   <td style="text-align:right;"> 0.73 </td>
  </tr>
</tbody>
</table>

```r
# Kickers Projection Attributes
scrap$K %>%  
  filter(player=="Justin Tucker") %>% 
  select(4:10) %>% 
   kable() %>%
   kable_styling(bootstrap_options = "striped", full_width = F, font_size = 11)
```

<table class="table table-striped" style="font-size: 11px; width: auto !important; margin-left: auto; margin-right: auto;">
 <thead>
  <tr>
   <th style="text-align:left;"> player </th>
   <th style="text-align:left;"> team </th>
   <th style="text-align:right;"> fg </th>
   <th style="text-align:right;"> fg_att </th>
   <th style="text-align:right;"> fglg </th>
   <th style="text-align:right;"> xp </th>
   <th style="text-align:right;"> xpatt </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> Justin Tucker </td>
   <td style="text-align:left;"> BAL </td>
   <td style="text-align:right;"> 1.80 </td>
   <td style="text-align:right;"> 1.90 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 2.60 </td>
   <td style="text-align:right;"> 2.6 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Justin Tucker </td>
   <td style="text-align:left;"> Bal </td>
   <td style="text-align:right;"> 1.90 </td>
   <td style="text-align:right;"> 2.00 </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:right;"> 2.20 </td>
   <td style="text-align:right;"> NA </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Justin Tucker </td>
   <td style="text-align:left;"> BAL </td>
   <td style="text-align:right;"> 2.00 </td>
   <td style="text-align:right;"> 2.30 </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:right;"> 2.30 </td>
   <td style="text-align:right;"> NA </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Justin Tucker </td>
   <td style="text-align:left;"> BAL </td>
   <td style="text-align:right;"> 2.00 </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:right;"> 3.00 </td>
   <td style="text-align:right;"> NA </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Justin Tucker </td>
   <td style="text-align:left;"> BAL </td>
   <td style="text-align:right;"> 1.86 </td>
   <td style="text-align:right;"> 2.25 </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:right;"> 2.29 </td>
   <td style="text-align:right;"> NA </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Justin Tucker </td>
   <td style="text-align:left;"> Bal </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:right;"> 2.50 </td>
   <td style="text-align:right;"> NA </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Justin Tucker </td>
   <td style="text-align:left;"> BAL </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:right;"> 1.94 </td>
   <td style="text-align:right;"> NA </td>
  </tr>
</tbody>
</table>

Secondly, with projections in hand, we use `ffanalytics package` again to calculate how many points each player will make according with each prediction scraped from the sites. However, the package does not export the function that does the this individual calculation, but it is a necessary step to calculate the [projections table](https://github.com/FantasyFootballAnalytics/ffanalytics#calculating-projections) that the site uses in its [graphics](https://fantasyfootballanalytics.net/2018/10/gold-mining-week-7-2018.html).

But the package project is in the GitHub, so, it is possible to download the code, load the scripts directly and access the function that calculates the points per player and projection site. The function is called `source_points()`, and is present in the script [calc_projections.R](https://github.com/FantasyFootballAnalytics/ffanalytics/blob/master/R/calc_projections.R#L90). You can load the script (and its dependencies) to invoke it directly.



```r
# function to access 'source_points' directly
playerPointsProjections <- function(.scrap, .score_rules){
  source("../ffanalytics/R/calc_projections.R")
  source("../ffanalytics/R/stats_aggregation.R")
  source("../ffanalytics/R/source_classes.R")
  source("../ffanalytics/R/custom_scoring.R")
  source("../ffanalytics/R/scoring_rules.R")
  source("../ffanalytics/R/make_scoring.R")
  source("../ffanalytics/R/recode_vars.R")
  source("../ffanalytics/R/impute_funcs.R")
  source_points(.scrap, .score_rules)
}

# customized scoring rules
source("./score_settings.R") 
players.points <- playerPointsProjections(scrap, dudes.score.settings)
```
<table class="table table-striped" style="font-size: 11px; width: auto !important; margin-left: auto; margin-right: auto;">
 <thead>
  <tr>
   <th style="text-align:left;"> pos </th>
   <th style="text-align:left;"> data_src </th>
   <th style="text-align:right;"> id </th>
   <th style="text-align:right;"> points </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> K </td>
   <td style="text-align:left;"> CBS </td>
   <td style="text-align:right;"> 8359 </td>
   <td style="text-align:right;"> 10 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> K </td>
   <td style="text-align:left;"> CBS </td>
   <td style="text-align:right;"> 12956 </td>
   <td style="text-align:right;"> 9 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> K </td>
   <td style="text-align:left;"> CBS </td>
   <td style="text-align:right;"> 11936 </td>
   <td style="text-align:right;"> 9 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> K </td>
   <td style="text-align:left;"> CBS </td>
   <td style="text-align:right;"> 6789 </td>
   <td style="text-align:right;"> 9 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> K </td>
   <td style="text-align:left;"> CBS </td>
   <td style="text-align:right;"> 8930 </td>
   <td style="text-align:right;"> 9 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> K </td>
   <td style="text-align:left;"> CBS </td>
   <td style="text-align:right;"> 11384 </td>
   <td style="text-align:right;"> 9 </td>
  </tr>
</tbody>
</table>



### Merging Rosters and Predictions

We now have the teams rosters and the scoring projections of the sites for each player, so we need to join the datasets. But to do that it is necessary to *match* the players' ids. If you notice the data displayed, each player's ID is different on each of the sites, `ffanalytics package` names this `id` as `src_id`, but unifies the results to a unified, identificator named `id`.

The teams' rosters were obtained from the `fantasy` site, it follows the `src_id` identification of the `NFL`, to make the *merge* between the two dataset it will be necessary to map the `src_id` of the `NFL` to `id` of  `ffanalytics package`. We can extract this 'ids' mapping from `NFL` prediction scraped data:


```r
# look the presence of both ids in the projection table
scrap$WR %>% 
  filter( data_src=="NFL" ) %>% 
  select(1:4) %>% 
  head() %>% 
   kable() %>%
   kable_styling(bootstrap_options = "striped", full_width = F, font_size = 11)
```

<table class="table table-striped" style="font-size: 11px; width: auto !important; margin-left: auto; margin-right: auto;">
 <thead>
  <tr>
   <th style="text-align:left;"> data_src </th>
   <th style="text-align:left;"> id </th>
   <th style="text-align:left;"> src_id </th>
   <th style="text-align:left;"> player </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> NFL </td>
   <td style="text-align:left;"> 11675 </td>
   <td style="text-align:left;"> 2543495 </td>
   <td style="text-align:left;"> Davante Adams </td>
  </tr>
  <tr>
   <td style="text-align:left;"> NFL </td>
   <td style="text-align:left;"> 12181 </td>
   <td style="text-align:left;"> 2552600 </td>
   <td style="text-align:left;"> Nelson Agholor </td>
  </tr>
  <tr>
   <td style="text-align:left;"> NFL </td>
   <td style="text-align:left;"> 10651 </td>
   <td style="text-align:left;"> 2530660 </td>
   <td style="text-align:left;"> Kamar Aiken </td>
  </tr>
  <tr>
   <td style="text-align:left;"> NFL </td>
   <td style="text-align:left;"> 11222 </td>
   <td style="text-align:left;"> 2540154 </td>
   <td style="text-align:left;"> Keenan Allen </td>
  </tr>
  <tr>
   <td style="text-align:left;"> NFL </td>
   <td style="text-align:left;"> 9308 </td>
   <td style="text-align:left;"> 2649 </td>
   <td style="text-align:left;"> Danny Amendola </td>
  </tr>
  <tr>
   <td style="text-align:left;"> NFL </td>
   <td style="text-align:left;"> 12930 </td>
   <td style="text-align:left;"> 2556462 </td>
   <td style="text-align:left;"> Robby Anderson </td>
  </tr>
</tbody>
</table>




```r
# extracting id and src_id from all positions
scrap %>%
  map(function(dft){
    dft %>% 
      filter(data_src=="NFL") %>% 
      select(id, src_id, player, team, pos) %>% 
      return()
  }) %>% 
  bind_rows() %>%
  distinct() -> players.ids
```


```r
# ID mapping
head(players.ids) %>% 
   kable() %>%
   kable_styling(bootstrap_options = "striped", full_width = F, font_size = 11)
```

<table class="table table-striped" style="font-size: 11px; width: auto !important; margin-left: auto; margin-right: auto;">
 <thead>
  <tr>
   <th style="text-align:right;"> id </th>
   <th style="text-align:right;"> src_id </th>
   <th style="text-align:left;"> player </th>
   <th style="text-align:left;"> team </th>
   <th style="text-align:left;"> pos </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:right;"> 13589 </td>
   <td style="text-align:right;"> 2560955 </td>
   <td style="text-align:left;"> Josh Allen </td>
   <td style="text-align:left;"> BUF </td>
   <td style="text-align:left;"> QB </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 13125 </td>
   <td style="text-align:right;"> 2557922 </td>
   <td style="text-align:left;"> C.J. Beathard </td>
   <td style="text-align:left;"> SF </td>
   <td style="text-align:left;"> QB </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 11642 </td>
   <td style="text-align:right;"> 2543477 </td>
   <td style="text-align:left;"> Blake Bortles </td>
   <td style="text-align:left;"> JAX </td>
   <td style="text-align:left;"> QB </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 9817 </td>
   <td style="text-align:right;"> 497095 </td>
   <td style="text-align:left;"> Sam Bradford </td>
   <td style="text-align:left;"> ARI </td>
   <td style="text-align:left;"> QB </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 5848 </td>
   <td style="text-align:right;"> 2504211 </td>
   <td style="text-align:left;"> Tom Brady </td>
   <td style="text-align:left;"> NE </td>
   <td style="text-align:left;"> QB </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 4925 </td>
   <td style="text-align:right;"> 2504775 </td>
   <td style="text-align:left;"> Drew Brees </td>
   <td style="text-align:left;"> NO </td>
   <td style="text-align:left;"> QB </td>
  </tr>
</tbody>
</table>

Finally we can make the predictions *merging* of players to the team's rankings.


```r
# nest by "id" and merge with "src_id"
players.points %>% 
  select(-pos) %>% 
  group_by(id) %>% 
  nest(.key="points.range") %>%
  # merge ID with SRC_ID
  inner_join(players.ids, by = c("id")) %>%
  select(id, src_id, player, pos, team, points.range) %>% 
  # keep only "ids" at top level
  select(id, src_id, points.range) -> players.ids.points

# auxiliary function to merge roster with player points
mergePoints <- function(.roster, .points){
  .roster %>% 
    left_join(.points, by="src_id") %>% 
    return()
}

# merge points in rosters
matchups.rosters %>% 
  mutate(
    home.roster = map(home.roster, mergePoints, .points=players.ids.points),
    away.roster = map(away.roster, mergePoints, .points=players.ids.points)
  ) -> matchups.points
```

Note that we are using a structure of [nested data.frames](https://r4ds.had.co.nz/many-models.html), i.e., we have a *matchups data.frame*  where each line is a match. In each match there are two rosters columns ("home" and "visitor"), these columns hold another *data.frame*, containing the roster itself. In this *data.frame*, each line is a player, and for each player there is a column called *points.range* which also contains another *data.frame*, with the prediction of each site's player scores.


```r
# "father" dataframe and the first nested column
matchups.points %>% 
  select( home.name, home.roster ) 
```

```
## # A tibble: 4 x 2
##   home.name             home.roster      
##   <chr>                 <list>           
## 1 Rio Claro Pfeiferians <tibble [15 x 7]>
## 2 Sorocaba Steelers     <tibble [15 x 7]>
## 3 Amparo Bikers         <tibble [15 x 7]>
## 4 Indaiatuba Riders     <tibble [15 x 7]>
```

```r
# seeing the first nested data.frame
matchups.points[1,]$home.roster[[1]]
```

```
## # A tibble: 15 x 7
##     src_id name              position rosterSlot points    id points.range     
##      <int> <chr>             <chr>    <chr>       <dbl> <int> <list>           
##  1 2558125 Patrick Mahomes   QB       QB           15.8 13116 <tibble [9 x 2]> 
##  2 2507164 Adrian Peterson   RB       RB            4.2  8658 <tibble [9 x 2]> 
##  3 2543773 James White       RB       RB           13.7 11747 <tibble [9 x 2]> 
##  4 2508061 Antonio Brown     WR       WR           22.1  9988 <tibble [9 x 2]> 
##  5 2556370 Michael Thomas    WR       WR            7.4 12652 <tibble [9 x 2]> 
##  6 2558266 George Kittle     TE       TE            8.3 13299 <tibble [9 x 2]> 
##  7 2555430 Alex Collins      RB       W/R           6.6 12628 <tibble [8 x 2]> 
##  8    1581 DeSean Jackson    WR       BN            0    9075 <tibble [4 x 2]> 
##  9 2540158 Zach Ertz         TE       BN           17   11247 <tibble [10 x 2]>
## 10 2540160 Jordan Reed       TE       BN            2.1 11248 <tibble [9 x 2]> 
## 11 2558063 Deshaun Watson    QB       BN           21   13113 <tibble [9 x 2]> 
## 12 2558865 Chris Carson      RB       BN           12.7 13364 <tibble [8 x 2]> 
## 13 2559169 Austin Ekeler     RB       BN           11.9 13404 <tibble [6 x 2]> 
## 14 2507232 Mason Crosby      K        K             3    8742 <tibble [10 x 2]>
## 15  100011 Green Bay Packers DEF      DEF           2     523 <tibble [8 x 2]>
```

```r
# look the second level dataframe
matchups.points[1,]$home.roster[[1]][1,]$points.range[[1]]
```

```
## # A tibble: 9 x 2
##   data_src      points
##   <chr>          <dbl>
## 1 CBS             16  
## 2 ESPN            18.7
## 3 FantasyPros     22.3
## 4 FantasySharks   19.5
## 5 FFToday         20.5
## 6 FleaFlicker     24.7
## 7 NFL             19.1
## 8 NumberFire      24.6
## 9 Yahoo           18.8
```

[Nested data.frames](https://r4ds.had.co.nz/many-models.html) is a convenient model because it allows you to keep the data together and manipulate them easily.

### Monte Carlo Simulation

To simulate the result of round matches, we need to simulate the score obtained by each teams and for this we will simulate the score of the team members using [Monte Carlo](https://en.wikipedia.org/wiki/Monte_Carlo_method) simulation.

To simulate the players' scores we will consider that each of the players can make one of the scores projected by the forecast sites. For simplicity, in this post, we can assume that the odds are equal for any of the projected scores.

In this case the simulation of a match using Monte Carlo then consists in:

1. For each player of the team, draws one of the possible projected numbers
2. We sum the players' points drawed: this will be the team score
3. Compare the score of the *home* team with the *away* team to determine who won
4. A win is computed for the team with the highest score

This procedure is repeated *N* times, simulating several matchs, to determine the chances of winning a team, we sum the total number of times in which the team was a winner and divide by the total number of simulations. Thus we will have the chances of each team winning the match, once the simulations reflect the numerous combinations of scores between players and their teams.

Note that we assume that each player has equal chance of having any of the projected scores as a simulation score, more sophisticated models could consider different ranges with different probabilities between projections, including assessing the performance history of the site, but I'll leave this considerations to another future post.


```r
### Auxiliary functions

# function to generate .n possible pontuations from .points.range
# it's used to generate the .n simulations to each player
simPlayer <- function(.points.range, .n){

  # just check if the points.range isn't empty
  if(is.null(.points.range)) return( vector(mode = "numeric",.n) )
  if(nrow(.points.range)==0) return( vector(mode = "numeric",.n) )

  # generate a .n vector samples from points.range
  .points.range$points %>% 
    sample(size = .n, replace = T) %>%
    return()

}

# function to add the player pontuation to the team roster dataframe
simTeam <- function(.roster, .n){
  .roster %>% 
    mutate( sim.player = map(points.range, simPlayer, .n=.n) )  %>% 
    return()
}

# this function is in charge to sum the pontuations from 
# each player to generate the .n-size vector with team pontuation
simTeamPoints <- function(.roster){
  .roster %>% 
    filter(rosterSlot!="BN") %>%  # exclude player in bench
    pull(sim.player) %>%          # get the player pontuation simulation
    bind_cols() %>%               # binds the pontuation toghether 
    as.matrix() %>%               # now we have an matrix with # players x # .n simulations
    rowSums(na.rm = T) %>%        # sum each row (simuilation) to get a .n-vector 
    return()                      # each position in this vector is a possible team pontuation
}

### Simulation Code

# number of simulations
n <- 2000

# in the matchups dataframe
matchups.points %>% 
  mutate(
    # just team nicknames to shorter legends :)
    away.nickname = gsub("([a-zA-Z\']+ )?", "", away.name),
    home.nickname = gsub("([a-zA-Z\']+ )?", "", home.name)
  ) %>% 
  mutate(
    home.roster  = map(home.roster, simTeam, .n=n), # add players simulation points
    away.roster  = map(away.roster, simTeam, .n=n), # to each roster
    home.sim.pts = map(home.roster, simTeamPoints), # computes the team simulation
    away.sim.pts = map(away.roster, simTeamPoints)  # points
  ) %>% 
  mutate( 
    home.win    = map2(home.sim.pts, away.sim.pts, function(.x,.y) (.x > .y) ), # computes the 
    away.win    = map(home.win, function(.x) (!.x)), # number of victures of each team
    home.win.prob = map_dbl(home.win, mean, na.rm = T),  # the % of victories
    away.win.prob = map_dbl(away.win, mean, na.rm = T)   # the % of victories
  ) %>%
  mutate(
    # this calculate the difference of score points in each simulation
    score.diff    = map2(home.sim.pts, away.sim.pts, function(.x,.y){.x - .y})
  ) -> simulation
```

Now we have a pontuation curve for each player in the roster and also the pontuation curve of each team, let's see what are the results.

### Simulation Results

Let's compare the difference of score for each match in league, the difference of score will allow us to calculate the chances of victory that each team has, according to the amount of "winning" simulations.


```r
# return a summary as a tibble
summaryAsTibble <- . %>% summary() %>% as.list() %>% as.tibble()

# first, lets build team simulation summary
c("home","away") %>% 
  map(function(.prefix, .matchups.sim){
    .matchups.sim %>% 
      select( starts_with(.prefix)) %>% 
      set_names(gsub(pattern = paste0(.prefix,"\\."),replacement = "",x=names(.))) %>% 
      mutate( points = map(sim.pts, summaryAsTibble) ) %>% 
      select(-roster, -win) %>% 
      unnest(points, .sep=".") %>% 
      return()
  },
  .matchups.sim = simulation) %>% 
  bind_rows() -> sim.results

# visualizing the summary 
sim.results %>% 
  select(nickname, win.prob, points=points.Median) %>% 
  mutate(win.prob = win.prob * 100) %>% 
  mutate_at(2:3, round, digits=1) %>% 
  arrange(desc(points)) %>% 
   kable() %>%
   kable_styling(bootstrap_options = "striped", full_width = F, font_size = 11)
```

<table class="table table-striped" style="font-size: 11px; width: auto !important; margin-left: auto; margin-right: auto;">
 <thead>
  <tr>
   <th style="text-align:left;"> nickname </th>
   <th style="text-align:right;"> win.prob </th>
   <th style="text-align:right;"> points </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> Mules </td>
   <td style="text-align:right;"> 92.2 </td>
   <td style="text-align:right;"> 106.6 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Steelers </td>
   <td style="text-align:right;"> 92.2 </td>
   <td style="text-align:right;"> 105.9 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Robots </td>
   <td style="text-align:right;"> 77.5 </td>
   <td style="text-align:right;"> 104.8 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Giants </td>
   <td style="text-align:right;"> 68.0 </td>
   <td style="text-align:right;"> 104.0 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Bikers </td>
   <td style="text-align:right;"> 32.0 </td>
   <td style="text-align:right;"> 99.7 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Pfeiferians </td>
   <td style="text-align:right;"> 22.5 </td>
   <td style="text-align:right;"> 98.0 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Riders </td>
   <td style="text-align:right;"> 7.8 </td>
   <td style="text-align:right;"> 94.8 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Bugre </td>
   <td style="text-align:right;"> 7.8 </td>
   <td style="text-align:right;"> 92.4 </td>
  </tr>
</tbody>
</table>

We can see the points scored and the chance of victory (win.prob). We used the median of the distribution as the best projected score (the one who divides the simulated score by 50% chance). How "safe" is the projected score? We need to visualize the distribution of possible scores to get a better view of the certainty of the projected score.


```r
# lets plot the points distribution from simulation
library(tidybayes) # stat_intervalh
sim.results %>% 
  select( nickname, med.pts = points.Median, sim.pts ) %>% 
  mutate( 
    nickname = as.factor(nickname),
    sim.pts = map(sim.pts, base::sample, size=40) # just to reduce de number of point to be ploted
  ) %>% 
  unnest(sim.pts) %>% 
  ggplot(aes(y=reorder(nickname, med.pts))) +
  stat_intervalh(aes(x=sim.pts), .width = c(seq(.05,.95,.1))) +
  scale_color_brewer() +
  geom_point(aes(x=sim.pts), alpha=.1) +
  theme_minimal() +
  ylab("teams") + xlab("points") +
  theme(legend.position = "none")
```

<img src="{{< blogdown/postref >}}index.en_files/figure-html/scoreDistribution-1.png" width="672" />

Showing the distribution of points instead of just the most probable score it is possible to see more details about the possibles performances of a team. The same can be visualized with the chances of victory, instead of just counting the number of times that the simulations of the matches point to the victory of a team, we can visualize the distribution of the difference in the score in each game, generating a curve of probability for each possible outcome.


```r
simulation %>% 
  mutate(game=paste0(away.nickname, " @ ", home.nickname)) %>% 
  arrange(away.nickname) %>% 
  select(game, score.diff) %>%
  unnest() %>% 
  ggplot(aes(fill=game)) +
  geom_density(aes(score.diff), alpha=.6) +
  geom_vline(aes(xintercept=0),
             linetype=2, color="red") +
  facet_grid(rows=vars(game), switch = "x") +
  theme_minimal() +
  theme( legend.position = "bottom" )
```

<img src="{{< blogdown/postref >}}index.en_files/figure-html/scoreDiferences-1.png" width="672" />

```r
simulation %>% 
  arrange(away.nickname) %>% 
  mutate_at(vars(away.win.prob, home.win.prob), function(x) round(100*x,1)) %>% 
  select(away.nickname, away.win.prob, home.win.prob, home.nickname)  %>% 
   kable() %>%
   kable_styling(bootstrap_options = "striped", full_width = F, font_size = 11)
```

<table class="table table-striped" style="font-size: 11px; width: auto !important; margin-left: auto; margin-right: auto;">
 <thead>
  <tr>
   <th style="text-align:left;"> away.nickname </th>
   <th style="text-align:right;"> away.win.prob </th>
   <th style="text-align:right;"> home.win.prob </th>
   <th style="text-align:left;"> home.nickname </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> Bugre </td>
   <td style="text-align:right;"> 7.8 </td>
   <td style="text-align:right;"> 92.2 </td>
   <td style="text-align:left;"> Steelers </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Giants </td>
   <td style="text-align:right;"> 68.0 </td>
   <td style="text-align:right;"> 32.0 </td>
   <td style="text-align:left;"> Bikers </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Mules </td>
   <td style="text-align:right;"> 92.2 </td>
   <td style="text-align:right;"> 7.8 </td>
   <td style="text-align:left;"> Riders </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Robots </td>
   <td style="text-align:right;"> 77.5 </td>
   <td style="text-align:right;"> 22.5 </td>
   <td style="text-align:left;"> Pfeiferians </td>
  </tr>
</tbody>
</table>

### Conclusion

We have seen that it is possible to use NFL players' performance projections, available on various websites, to calculate `fantasy` scores and to simulate, using *Monte Carlo*, the outcame of a league games. More sophisticated simulation models can be used, taking into account the historical distribution of the accuracy of the estimates of these sites to calculate a greater number of results possibilities.

Today, in my league, before the start of the round, after *waivers* and the lineups, I I send a dashboard (made using [RMarkdown](https://rmarkdown.rstudio.com/) and [Flexdashboard](https: / /rmarkdown.rstudio.com/flexdashboard/using.html)) to members with simulation results and the performance of their *rosters*. You can see an example of it here: [http://rpubs.com/gsposito/ffsimulationDudes](http://rpubs.com/gsposito/ffsimulationDudes)]. As an evolution, in the future, I may tranform this in to a [ShinyApp](http://shiny.rstudio.com/) to members be abble to simulate several different rosters combinations to choose the most promising one.

### Prediction Evaluation

Before concluding it is worth comparing the simulation made with the actual scores, and evaluating how much the simulation projected came close to the obtained real result.


```r
# comparing simulated values with real values
simulation %>% 
  mutate( 
    away.win.real   = away.pts > home.pts,
    home.win.real   = home.pts > away.pts,
    score.diff.real = home.pts - away.pts,
    away.sim.pts = map_dbl(away.sim.pts, median, na.rm=T),
    home.sim.pts = map_dbl(home.sim.pts, median, na.rm=T),
    score.diff   = map_dbl(score.diff, median, na.rm=T )
  ) %>% 
  mutate_at( vars(away.win.prob, home.win.prob), function(x) round(100*x,2) )%>% 
  select( away.nickname, away.win.prob, away.win.real, away.sim.pts, away.pts, score.diff, score.diff.real, 
          home.pts, home.sim.pts, home.win.real, home.win.prob, home.nickname ) %>% 
  mutate_if(is.numeric, round, digits=1) %>% 
  arrange(away.nickname) %>% 
   kable() %>%
   kable_styling(bootstrap_options = "striped", full_width = F, font_size = 11)
```

<table class="table table-striped" style="font-size: 11px; width: auto !important; margin-left: auto; margin-right: auto;">
 <thead>
  <tr>
   <th style="text-align:left;"> away.nickname </th>
   <th style="text-align:right;"> away.win.prob </th>
   <th style="text-align:left;"> away.win.real </th>
   <th style="text-align:right;"> away.sim.pts </th>
   <th style="text-align:right;"> away.pts </th>
   <th style="text-align:right;"> score.diff </th>
   <th style="text-align:right;"> score.diff.real </th>
   <th style="text-align:right;"> home.pts </th>
   <th style="text-align:right;"> home.sim.pts </th>
   <th style="text-align:left;"> home.win.real </th>
   <th style="text-align:right;"> home.win.prob </th>
   <th style="text-align:left;"> home.nickname </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> Bugre </td>
   <td style="text-align:right;"> 7.8 </td>
   <td style="text-align:left;"> FALSE </td>
   <td style="text-align:right;"> 92.4 </td>
   <td style="text-align:right;"> 112.6 </td>
   <td style="text-align:right;"> 13.3 </td>
   <td style="text-align:right;"> 13.7 </td>
   <td style="text-align:right;"> 126.3 </td>
   <td style="text-align:right;"> 105.9 </td>
   <td style="text-align:left;"> TRUE </td>
   <td style="text-align:right;"> 92.2 </td>
   <td style="text-align:left;"> Steelers </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Giants </td>
   <td style="text-align:right;"> 68.0 </td>
   <td style="text-align:left;"> TRUE </td>
   <td style="text-align:right;"> 104.0 </td>
   <td style="text-align:right;"> 108.7 </td>
   <td style="text-align:right;"> -4.2 </td>
   <td style="text-align:right;"> -11.5 </td>
   <td style="text-align:right;"> 97.2 </td>
   <td style="text-align:right;"> 99.7 </td>
   <td style="text-align:left;"> FALSE </td>
   <td style="text-align:right;"> 32.0 </td>
   <td style="text-align:left;"> Bikers </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Mules </td>
   <td style="text-align:right;"> 92.2 </td>
   <td style="text-align:left;"> TRUE </td>
   <td style="text-align:right;"> 106.6 </td>
   <td style="text-align:right;"> 98.4 </td>
   <td style="text-align:right;"> -12.0 </td>
   <td style="text-align:right;"> -8.3 </td>
   <td style="text-align:right;"> 90.1 </td>
   <td style="text-align:right;"> 94.8 </td>
   <td style="text-align:left;"> FALSE </td>
   <td style="text-align:right;"> 7.8 </td>
   <td style="text-align:left;"> Riders </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Robots </td>
   <td style="text-align:right;"> 77.5 </td>
   <td style="text-align:left;"> TRUE </td>
   <td style="text-align:right;"> 104.8 </td>
   <td style="text-align:right;"> 113.6 </td>
   <td style="text-align:right;"> -6.7 </td>
   <td style="text-align:right;"> -30.4 </td>
   <td style="text-align:right;"> 83.1 </td>
   <td style="text-align:right;"> 98.0 </td>
   <td style="text-align:left;"> FALSE </td>
   <td style="text-align:right;"> 22.5 </td>
   <td style="text-align:left;"> Pfeiferians </td>
  </tr>
</tbody>
</table>

This was good! The simulated results were satisfactorily close to those obtained in 3 of the 4 games. All victories and defeats were correctly predicted. Only one of the games got a score difference far away from the one projected.


```r
# comparing score difference
simulation %>% 
  mutate(
    game=paste0(away.nickname, " @ ", home.nickname),
    score.diff.real = home.pts - away.pts
  ) %>% 
  arrange(away.nickname) %>% 
  select(game, score.diff, score.diff.real) %>%
  unnest() %>% 
  ggplot(aes(fill=game)) +
  geom_density(aes(score.diff), alpha=.6) +
  geom_vline(aes(xintercept=score.diff.real),
             linetype=1, size=1, color="black") +
  geom_vline(aes(xintercept=0),
             linetype=2, color="red") +
  facet_grid(rows=vars(game), switch = "x") +
  theme_minimal() +
  theme( legend.position = "bottom" )
```

<img src="{{< blogdown/postref >}}index.en_files/figure-html/scoreDistr-1.png" width="672" />

Perhaps the reason why the difference in scoring in the game between *Robots* and *Pfeiferians* has fallen so far from the most likely is also by such an unlikely event in the *Packers'* game against the *Lions*. Here's the lineup of the *house team*, the one who lost:


```r
# rosted home team
simulation[1,]$home.roster[[1]] %>% 
  filter(rosterSlot != "BN") %>% 
  mutate(points.sim = map_dbl(sim.player,median, na.rm=T)) %>% 
  select(name, position, points) %>% 
   kable() %>%
   kable_styling(bootstrap_options = "striped", full_width = F, font_size = 11)
```

<table class="table table-striped" style="font-size: 11px; width: auto !important; margin-left: auto; margin-right: auto;">
 <thead>
  <tr>
   <th style="text-align:left;"> name </th>
   <th style="text-align:left;"> position </th>
   <th style="text-align:right;"> points </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> Patrick Mahomes </td>
   <td style="text-align:left;"> QB </td>
   <td style="text-align:right;"> 15.82 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Adrian Peterson </td>
   <td style="text-align:left;"> RB </td>
   <td style="text-align:right;"> 4.20 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> James White </td>
   <td style="text-align:left;"> RB </td>
   <td style="text-align:right;"> 13.70 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Antonio Brown </td>
   <td style="text-align:left;"> WR </td>
   <td style="text-align:right;"> 22.10 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Michael Thomas </td>
   <td style="text-align:left;"> WR </td>
   <td style="text-align:right;"> 7.40 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> George Kittle </td>
   <td style="text-align:left;"> TE </td>
   <td style="text-align:right;"> 8.30 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Alex Collins </td>
   <td style="text-align:left;"> RB </td>
   <td style="text-align:right;"> 6.60 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Mason Crosby </td>
   <td style="text-align:left;"> K </td>
   <td style="text-align:right;"> 3.00 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Green Bay Packers </td>
   <td style="text-align:left;"> DEF </td>
   <td style="text-align:right;"> 2.00 </td>
  </tr>
</tbody>
</table>

In this game, Mason Crosby, Packers' *Kicker* missed [4 fields goals and 1 extra point](https://www.youtube.com/watch?v=15rt2quS774), with a total of 13 points, an event rare, [which has not happened since 1997](http://www.espn.com/nfl/story/_/id/24924994/mason-crosby-calls-4-missed-fg-1-missed-pat-anomaly-life?ex_cid=espnapi_public). If Crosby had hit the shots, which he habitually does, the score difference would be only 10 points away from the predicted score, not 23!

But after all, who wants to [predict accurately](https://www.youtube.com/watch?v=yGf6LNWY9AI) all possible situations?
