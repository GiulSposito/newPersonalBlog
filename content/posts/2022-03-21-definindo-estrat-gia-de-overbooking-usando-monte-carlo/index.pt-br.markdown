---
title: Definindo estratégia de overbooking usando Monte Carlo
author: Giuliano Sposito
date: '2022-03-21'
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
<script src="/rmarkdown-libs/kePrint/kePrint.js"></script>
<link href="/rmarkdown-libs/lightable/lightable.css" rel="stylesheet" />
<script src="/rmarkdown-libs/kePrint/kePrint.js"></script>
<link href="/rmarkdown-libs/lightable/lightable.css" rel="stylesheet" />
<script src="/rmarkdown-libs/kePrint/kePrint.js"></script>
<link href="/rmarkdown-libs/lightable/lightable.css" rel="stylesheet" />
<script src="/rmarkdown-libs/kePrint/kePrint.js"></script>
<link href="/rmarkdown-libs/lightable/lightable.css" rel="stylesheet" />
<script src="/rmarkdown-libs/kePrint/kePrint.js"></script>
<link href="/rmarkdown-libs/lightable/lightable.css" rel="stylesheet" />

Nem todos os passageiros que compram uma passagem de avião aparecem no momento do embarque. Os _no shows_ fazem os vôos ocorrerem com capacidade ociosa e incorrem num custo de oportunidade para a operadora. Para compensar, as companhias aérias fazem uso do _overbooking_ (venda da acentos acima da capacidade do vôo). Mas quantos acentos adicionais devemos oferecer sem que isso não vire um problema de crônico de remanejamento de passageiros?

<!--more-->

Fazendo _overbooking_ o risco que se corre é, no momento do embarque, ter mais passageiros do que o avião comporta, levando a custos maiores para remanejar os passageiros em outros vôos e causando desgaste da marca através da insatisfação dos usuários. Neste _post_ vamos analisar a distribuição da demanda e o comportamento dos _no shows_ a fim de encontrar a melhor estratégia de overbooking através da [simulação por Monte Carlo](https://pt.wikipedia.org/wiki/M%C3%A9todo_de_Monte_Carlo) para estabelecer uma política de _overbooking_ estatísticamente segura.

### Abordagem

A abordagem que usaremos para tentar encontrar a melhor estratégia de overbooking seguirá os seguintes passos:

1. Entender e modelar o comportamento (distribuição) da demanda
1. Simular situações de embarque usando Monte Carlo
1. Definir uma estratégia de _overbooking_ com base na probabilidade de remanejamento de passageiros 

### Os Dados e a Demanda

Como ponto de partida vamos carregar os dados de demanda e comparecimento de um determinado vôo comercial disponível [nesta planilha de excel](./assets/Flight-Overbooking-Data.xlsx) e fazer uma breve exploração dos dados e tentar entender o comportamento da demanda para que ela possa ser modelada.


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

É um dataset bem direto e simples contendo informações de data, demanda, quantos passageiros foram registrados, quantos apareceram e qual a taxa de presença (apareceram/registrados).  

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

Como vc pode ver, há um limite superior de 150 na coluna de registrados, indicando que essa é a capacidade do vôo, ou seja, 150 acentos.

#### Comportamento da Demanda

Vamos tentar modelar a demanda, fazendo o fit da sua distribuição, para tal usaremos o pacote `{fitdistrplus}`


```r
library(fitdistrplus)

# checking the empirical distribution
plotdist(flight_dt$demand, discrete = T)
```

<img src="/posts/2022-03-21-definindo-estrat-gia-de-overbooking-usando-monte-carlo/index.pt-br_files/figure-html/demandDistr-1.png" width="672" />

```r
# what are the distribution candidates?
descdist(flight_dt$demand, boot=1000, discrete = T)
```

<img src="/posts/2022-03-21-definindo-estrat-gia-de-overbooking-usando-monte-carlo/index.pt-br_files/figure-html/demandDistr-2.png" width="672" />

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
O pacote `{fitdistrplus}` indicou três candidatos como melhor fit para a distribuição da demanda: [normal](https://pt.wikipedia.org/wiki/Distribui%C3%A7%C3%A3o_normal), [poisson](https://pt.wikipedia.org/wiki/Distribui%C3%A7%C3%A3o_de_Poisson) ou [negative binomial](https://pt.wikipedia.org/wiki/Distribui%C3%A7%C3%A3o_binomial_negativa). Vamos testar quais das duas mais comuns tem o melhor fit.

##### Distribuição Normal


```r
# lets fit a normal and see what we get
fitdist(flight_dt$demand, "norm", discrete = T) %T>%
  plot() %>% 
  summary()
```

<img src="/posts/2022-03-21-definindo-estrat-gia-de-overbooking-usando-monte-carlo/index.pt-br_files/figure-html/fitNorm-1.png" width="672" />

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

##### Distribuição de Poisson


```r
# lets fit a poisson and see what we get
fitdist(flight_dt$demand, "pois", discrete = T) %T>%
  plot() %>% 
  summary()
```

<img src="/posts/2022-03-21-definindo-estrat-gia-de-overbooking-usando-monte-carlo/index.pt-br_files/figure-html/fitPois-1.png" width="672" />

```
## Fitting of the distribution ' pois ' by maximum likelihood 
## Parameters : 
##        estimate Std. Error
## lambda 150.3973  0.4538983
## Loglikelihood:  -2864.742   AIC:  5731.484   BIC:  5736.077
```

##### Melhor modelo

Observamos que a distribuição de Poisson tem, marginalmente, o melhor fit observando os indicadores [loglikehood](https://www.statology.org › likelihood-vs-probability), [IAC](https://pt.wikipedia.org/wiki/Crit%C3%A9rio_de_informa%C3%A7%C3%A3o_de_Akaike) e [BIC](https://en.wikipedia.org/wiki/Bayesian_information_criterion). Vamos então usar _poisson_ como nosso modelo de distribuição para a demanda.


```r
# Emp CDF fit for Poisson is a little better and IAC also is marginally better
demand.pois <- fitdist(flight_dt$demand, "pois", discrete = T)
```

#### Comparecimento

O _show up_ pode ser modelado como um sorteio [binomial](https://en.wikipedia.org/wiki/Binomial_distribution) em cima do número de passageiros registrados para o vôo com uma taxa de sucesso determinado pela média histórica.


```r
mean(flight_dt$rate)
```

```
## [1] 0.9194333
```

Constatamos que a taxa média histórica de presença para o vôo é de 92%, podemos usar essa informação para simular o processo de presença fazendo:


```r
pass_reg <- 145 # number of passengers registered for the fligth
show_ups <- rbinom(1, pass_reg, mean(flight_dt$rate)) # one random binomial draw with size of pass_reg at historic show_up rate
show_ups 
```

```
## [1] 124
```


### Modelo da Simulação

Vamos fazer um modelo para simular uma situação de embarque, neste primeiro modelo vamos estabelecer um número fixo para o overbooking de 15 posições, isto é, serão oferecidos para a venda 15 acentos adicionais além da capacidade do vôo (150 posições).


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
   <td style="text-align:right;"> 148 </td>
   <td style="text-align:right;"> 148 </td>
   <td style="text-align:right;"> 139 </td>
   <td style="text-align:right;"> 9 </td>
   <td style="text-align:right;"> 0.9391892 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 11 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 142 </td>
   <td style="text-align:right;"> 142 </td>
   <td style="text-align:right;"> 125 </td>
   <td style="text-align:right;"> 17 </td>
   <td style="text-align:right;"> 0.8802817 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 25 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 155 </td>
   <td style="text-align:right;"> 155 </td>
   <td style="text-align:right;"> 140 </td>
   <td style="text-align:right;"> 15 </td>
   <td style="text-align:right;"> 0.9032258 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 10 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 137 </td>
   <td style="text-align:right;"> 137 </td>
   <td style="text-align:right;"> 124 </td>
   <td style="text-align:right;"> 13 </td>
   <td style="text-align:right;"> 0.9051095 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 26 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 131 </td>
   <td style="text-align:right;"> 131 </td>
   <td style="text-align:right;"> 125 </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:right;"> 0.9541985 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 25 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 150 </td>
   <td style="text-align:right;"> 150 </td>
   <td style="text-align:right;"> 134 </td>
   <td style="text-align:right;"> 16 </td>
   <td style="text-align:right;"> 0.8933333 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 16 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 146 </td>
   <td style="text-align:right;"> 146 </td>
   <td style="text-align:right;"> 138 </td>
   <td style="text-align:right;"> 8 </td>
   <td style="text-align:right;"> 0.9452055 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 12 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 136 </td>
   <td style="text-align:right;"> 136 </td>
   <td style="text-align:right;"> 127 </td>
   <td style="text-align:right;"> 9 </td>
   <td style="text-align:right;"> 0.9338235 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 23 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 137 </td>
   <td style="text-align:right;"> 137 </td>
   <td style="text-align:right;"> 120 </td>
   <td style="text-align:right;"> 17 </td>
   <td style="text-align:right;"> 0.8759124 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 30 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 157 </td>
   <td style="text-align:right;"> 157 </td>
   <td style="text-align:right;"> 141 </td>
   <td style="text-align:right;"> 16 </td>
   <td style="text-align:right;"> 0.8980892 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 9 </td>
  </tr>
</tbody>
</table>

Com um modelo para simular uma situação de embarque, podemos fazer a análise do comportamento da frequencia do _overbooking_ real (ou seja) quantos passageiros, acima da capacidade real do avião (150 acentos), comparecem no portão de embarque e que precisariam ser remanejados para outros vôos (ou compensados financeiramente).


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
   <td style="text-align:right;"> 8822 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 245 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:right;"> 218 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:right;"> 221 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:right;"> 176 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:right;"> 119 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:right;"> 92 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:right;"> 55 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 8 </td>
   <td style="text-align:right;"> 33 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 9 </td>
   <td style="text-align:right;"> 11 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 10 </td>
   <td style="text-align:right;"> 8 </td>
  </tr>
</tbody>
</table>

```r
plotdist(sim$overbooked)
```

<img src="/posts/2022-03-21-definindo-estrat-gia-de-overbooking-usando-monte-carlo/index.pt-br_files/figure-html/bumped-1.png" width="672" />
#### Política de Overbooking

Com a visão de como se comporta o _overbooking real_ (# de passageiros remanejados) podemos então estabelecer uma política de _overbooking_, por exemplo, estabelecer que em 95% das situações de embarque deste vôo, o número de **passageiros remanejados não ultrapasse 2**. Então neste cenário de 15 acentos adicionais teríamos


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
## 0.9285
```

Neste esse perfil de demanda e comportamento de comparecimento não seria possível atender este critério oferecendo 15 acentos adicionais, então quanto acentos deveríamos oferecer para atender a política estabelecida.

### Simulando Overbooking

Vamos então analizar qual seria o número de posicionais adicionais a serem oferecidas que possibilite a empresa ficar dentro da política de overbooking definida acima, executando a simulação para várias situações de oferta de posição adicional (acima da capacidade), indo, por exemplo, de 1 à 20 posições extras.


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

<img src="/posts/2022-03-21-definindo-estrat-gia-de-overbooking-usando-monte-carlo/index.pt-br_files/figure-html/simulation-1.png" width="672" />

Podemos ver que oferecendo 13 acentos adicionais nós conseguiríamos atender a política de ter em apenas 5% dos vôos mais de 2 passageiros remanejados. Se a política fosse 95% de chance de ter 5 ou menos poderíamos oferecer 18 acentos em _overbooking_.

### Dependência entre demanda e show-up rate

Nós tinhamos assumido uma taxa constante de show-up, não importa a demanda para vôo em determinado dia, o comparecimento para embarque segue uma taxa constante. Mas será que essa hipótese é verdadeira?


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

Esta é uma taxa de correlação muita alta para ser ignorada, vamos refazer o modelo de embarque considerando essa dependência, incorporando um modelo linear de dependência entre a taxa de comparecimento e a demanda.


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

<img src="/posts/2022-03-21-definindo-estrat-gia-de-overbooking-usando-monte-carlo/index.pt-br_files/figure-html/showUpModel-1.png" width="672" />

```r
par(mfrow=c(1,1))
```

Vamos alterar a função que faz a simulação incorporando a dependência.


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
   <td style="text-align:right;"> 122 </td>
   <td style="text-align:right;"> 0.8777300 </td>
   <td style="text-align:right;"> 122 </td>
   <td style="text-align:right;"> 108 </td>
   <td style="text-align:right;"> 14 </td>
   <td style="text-align:right;"> 0.8852459 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 42 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 135 </td>
   <td style="text-align:right;"> 0.8968213 </td>
   <td style="text-align:right;"> 135 </td>
   <td style="text-align:right;"> 125 </td>
   <td style="text-align:right;"> 10 </td>
   <td style="text-align:right;"> 0.9259259 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 25 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 151 </td>
   <td style="text-align:right;"> 0.9203184 </td>
   <td style="text-align:right;"> 151 </td>
   <td style="text-align:right;"> 142 </td>
   <td style="text-align:right;"> 9 </td>
   <td style="text-align:right;"> 0.9403974 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 8 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 130 </td>
   <td style="text-align:right;"> 0.8894785 </td>
   <td style="text-align:right;"> 130 </td>
   <td style="text-align:right;"> 112 </td>
   <td style="text-align:right;"> 18 </td>
   <td style="text-align:right;"> 0.8615385 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 38 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 176 </td>
   <td style="text-align:right;"> 0.9570326 </td>
   <td style="text-align:right;"> 165 </td>
   <td style="text-align:right;"> 158 </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:right;"> 0.9575758 </td>
   <td style="text-align:right;"> 8 </td>
   <td style="text-align:right;"> 0 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 149 </td>
   <td style="text-align:right;"> 0.9173813 </td>
   <td style="text-align:right;"> 149 </td>
   <td style="text-align:right;"> 137 </td>
   <td style="text-align:right;"> 12 </td>
   <td style="text-align:right;"> 0.9194631 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 13 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 150 </td>
   <td style="text-align:right;"> 0.9188499 </td>
   <td style="text-align:right;"> 150 </td>
   <td style="text-align:right;"> 136 </td>
   <td style="text-align:right;"> 14 </td>
   <td style="text-align:right;"> 0.9066667 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 14 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 165 </td>
   <td style="text-align:right;"> 0.9408784 </td>
   <td style="text-align:right;"> 165 </td>
   <td style="text-align:right;"> 159 </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:right;"> 0.9636364 </td>
   <td style="text-align:right;"> 9 </td>
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
  <tr>
   <td style="text-align:right;"> 153 </td>
   <td style="text-align:right;"> 0.9232556 </td>
   <td style="text-align:right;"> 153 </td>
   <td style="text-align:right;"> 149 </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:right;"> 0.9738562 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 1 </td>
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
   <td style="text-align:right;"> 8019 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 200 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:right;"> 201 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:right;"> 214 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:right;"> 220 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:right;"> 221 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:right;"> 186 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:right;"> 164 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 8 </td>
   <td style="text-align:right;"> 166 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 9 </td>
   <td style="text-align:right;"> 155 </td>
  </tr>
</tbody>
</table>

```r
plotdist(sim$overbooked)
```

<img src="/posts/2022-03-21-definindo-estrat-gia-de-overbooking-usando-monte-carlo/index.pt-br_files/figure-html/simModelShowUpDependency-1.png" width="672" />

Podemos observar que a distribuição (para esse caso de 15 acentos adicionais) se espalha um pouco, agora há mais chances de remanejamento por ovebooking, aparentemente.


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
##  1580
```

E comprovadamente, apenas 84% de ter dois ou menos passageiros remanejados neste cenário, comparado à 93% do cenário anterior. Vamos refazer a simulação considerando várias estratégias para o _overbooking_, como fizemos no modelo anterior.


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

<img src="/posts/2022-03-21-definindo-estrat-gia-de-overbooking-usando-monte-carlo/index.pt-br_files/figure-html/simNewModel-1.png" width="672" />

Obtemos resultados significativamente diferentes quando consideramos que a taxa de show-up é dependente da demanda, de maneira que precisamos oferecer bem menos acentos adicionais a fim da manter uma eventual política de 95% dos vôos com 2 ou menos passageiros remanejados.

Resultados finais para a implatanção de política do _overbooking_:
* Para ter 2 ou menos passageiros remanejados em 95% dos vöos: 8 acentos adicionais
* Para ter 5 ou menos passageiros remanejados em 95% dos vöos: 12 acentos adicionais

### Referências

Este é um exercício extraído do curso [Advanced Business Analytics for Desicion Making](https://www.coursera.org/learn/business-analytics-decision-making) oferecida pela universidade de [Boulder Colorado](https://www.colorado.edu/) via [Coursera](https://www.coursera.org/).
