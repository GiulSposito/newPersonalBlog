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

Nem todos os passageiros que compram uma passagem de avião parecem no momento embarque. Os _no shows_ fazem os vôos ocorrerem com apacidade ociosa e incorrem num custo de oportunidade para a operadora que fazem uso do _overbooking_ (venda da acentos acima da capacidade do vôo) para tentar compensar esse gap. Mas quantos acentos adicionais devemos oferecer sem que isso não vire um problema de crônico de remanejamento de passageiros?

<!--more-->

O risco que se corre é no momento do embarque ter mais passageiros do que o avião comporta, levando a custos maiores para remanejar os passageiros em outros vôos causando desgaste da marca e satisfação dos usuários. Neste post vamos analisar a distribuição da demanda e o comportamento dos "no shows" a fim de encontrar a melhor estratégia de overbooking através da [simulação por Monte Carlo](https://pt.wikipedia.org/wiki/M%C3%A9todo_de_Monte_Carlo).

### Abordagem

A abordagem que usaremos para tentar encontrar a melhor estratégia de overbooking seguirá os seguintes passos:

1. Entender o comportamento (distribuição) da demanda
1. Com base na distribuição da demanda, simular usando Monte Carlo 10 mil vôos
1. Definir o critério que gostaríamos de atender e então encontrar a melhor estratégia de overbooking

### Os Dados e a Demanda

Como ponto de partida vamos carregar os dados de demanda e comparecimento de um determinado vôo comercial, disponível [nesta planilha de excel](./assets/Flight-Overbooking-Data.xlsx) e fazer uma breve exploração dos dados e tentar entender o comportamento da demanda para que ela possa ser simulada.


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
  knitr::kable()
```



|date       | demand| booked| shows|      rate|
|:----------|------:|------:|-----:|---------:|
|2014-01-01 |    132|    132|   117| 0.8863636|
|2014-01-02 |    154|    150|   142| 0.9466667|
|2014-01-03 |    142|    142|   126| 0.8873239|
|2014-01-04 |    152|    150|   141| 0.9400000|
|2014-01-05 |    162|    150|   142| 0.9466667|
|2014-01-06 |    146|    146|   131| 0.8972603|
|2014-01-07 |    134|    134|   118| 0.8805970|
|2014-01-08 |    158|    150|   140| 0.9333333|
|2014-01-09 |    165|    150|   138| 0.9200000|
|2014-01-10 |    156|    150|   139| 0.9266667|

É um dataset bem direto e simples, com as colunas de demanda, quantos passageiros foram registrados, quantos apareceram e qual a taxa de presença (apareceram/registrados).  

#### Data Overview


```r
# overview
flight_dt %>% 
  skimr::skim()
```


Table: Table 1: Data summary

|                         |           |
|:------------------------|:----------|
|Name                     |Piped data |
|Number of rows           |730        |
|Number of columns        |5          |
|_______________________  |           |
|Column type frequency:   |           |
|numeric                  |4          |
|POSIXct                  |1          |
|________________________ |           |
|Group variables          |None       |


**Variable type: numeric**

|skim_variable | n_missing| complete_rate|   mean|    sd|     p0|   p25|    p50|    p75|   p100|hist  |
|:-------------|---------:|-------------:|------:|-----:|------:|-----:|------:|------:|------:|:-----|
|demand        |         0|             1| 150.40| 12.28| 117.00| 142.0| 150.00| 158.00| 191.00|▁▆▇▂▁ |
|booked        |         0|             1| 145.32|  6.85| 117.00| 142.0| 150.00| 150.00| 150.00|▁▁▁▂▇ |
|shows         |         0|             1| 133.73|  9.10| 106.00| 127.0| 138.00| 141.00| 147.00|▁▂▃▂▇ |
|rate          |         0|             1|   0.92|  0.03|   0.88|   0.9|   0.92|   0.94|   0.99|▇▃▇▃▁ |


**Variable type: POSIXct**

|skim_variable | n_missing| complete_rate|min        |max        |median              | n_unique|
|:-------------|---------:|-------------:|:----------|:----------|:-------------------|--------:|
|date          |         0|             1|2014-01-01 |2015-12-31 |2014-12-31 12:00:00 |      730|

Como vc pode ver, há um limite superior de 150 na coluna de registrados, indicando que essa é a capacidade do vôo, ou seja, 150 acentos.

#### Demand Distribuition

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

##### Normal


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

##### Poisson


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

##### Best Fit

Observamos que a distribuição de Poisson tem, marginalmente, p melhor fit observando os indicadores [loglikehood](
Likelihood vs. Probability: What's the Difference? - Statologyhttps://www.statology.org › likelihood-vs-probability), [IAC](https://pt.wikipedia.org/wiki/Crit%C3%A9rio_de_informa%C3%A7%C3%A3o_de_Akaike) e [BIC](https://en.wikipedia.org/wiki/Bayesian_information_criterion). Vamos então usar poisson como nosso modelo de distribuição para a demanda.


```r
# Emp CDF fit for Poisson is a little better and IAC also is marginally better
demand.pois <- fitdist(flight_dt$demand, "pois", discrete = T)
```

#### Show Up

O show up pode ser modelado como um sorteio binomial em cima do número de passageiros registrados para o vôo com uma taxa de sucesso determinado pela média histórica.


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
## [1] 133
```


### Modeling

Vamos fazer um modelo para simular n vezes uma situação de voo, neste primeiro modelo vamos estabelecer um número fixo para o overbooking de 15 posições, isto é, 


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
  knitr::kable()
```



| demand| booked| shows| no_shows| showup_rate| overbooked| empty_seats|
|------:|------:|-----:|--------:|-----------:|----------:|-----------:|
|    146|    146|   133|       13|   0.9109589|          0|          17|
|    152|    152|   136|       16|   0.8947368|          0|          14|
|    166|    165|   148|       17|   0.8969697|          0|           2|
|    149|    149|   137|       12|   0.9194631|          0|          13|
|    126|    126|   114|       12|   0.9047619|          0|          36|
|    134|    134|   122|       12|   0.9104478|          0|          28|
|    170|    165|   155|       10|   0.9393939|          5|           0|
|    136|    136|   129|        7|   0.9485294|          0|          21|
|    172|    165|   154|       11|   0.9333333|          4|           0|
|    156|    156|   145|       11|   0.9294872|          0|           5|

Com as situações de embarque simuladas, podemos fazer a análise do comportamento do overbooking real (ou seja) quantos passageiros, acima da capacidade real do avião (150 acentos) de fato aparecerram no portão de embarque e que precisariam ser remanejados:


```r
# lets visualize the overbooked passengers distribution
sim %>% 
  count(overbooked) %>% 
  knitr::kable()
```



| overbooked|    n|
|----------:|----:|
|          0| 8803|
|          1|  255|
|          2|  225|
|          3|  211|
|          4|  173|
|          5|  121|
|          6|   89|
|          7|   64|
|          8|   34|
|          9|   14|
|         10|    7|
|         11|    3|
|         12|    1|

```r
plotdist(sim$overbooked)
```

<img src="/posts/2022-03-21-definindo-estrat-gia-de-overbooking-usando-monte-carlo/index.pt-br_files/figure-html/bumped-1.png" width="672" />
#### Overbooking Criteria

Com a visão de como se comporta o overbooking real (# de passageiros remanejados) numa estratégia de 15 acentos podemos estabelecer uma política (ou estratégia) de overbooking, por exemplo, estabelecer que em 95% das situações o número de passageiros remanejados não ultrapasse 2. Então neste cenário teríamos


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
## 0.9283
```

Neste cenário de 15 acentos adicionais para este voo, com esse perfil de demanda e comportamento de comparecimento não seria possível atender o critério de ter até dois passageiros remanejados em 95% das vezes.

### Cenario simultaions

Vamos então analizar qual seria o número de posicionais adicionais a serem oferecidas que possibilite a empresa ficar dentro da política de overbooking definida acima.


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

we can see that offering 13 additional seats (over plain capacity) we have less than 5% of chance to bumped more than 2 passengers. Offering 18 additional seats (over plain capacity) we have less than 5% of chance to bump more than 5 passengers

### Dependência entre demanda e show-up rate

Nós tinhamos assumido uma taxa constante de show-up, não importa a demanda do vôo o comparecimento para embarque segue uma taxa constante, mas podemos comprovar essa hipótese


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

Esta é uma taxa de correlação muita alta para ser ignorada, vamos refazer o modelo considerando essa dependência.


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
Vamos considerar um simples modelo linear entre a demanda e o show-up rate e vamos incorporar esse modelo dentro da nossa simulação


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
sim
```

```
## # A tibble: 10,000 × 8
##    demand predShowup_rate booked shows no_shows showup_rate overbooked
##     <int>           <dbl>  <dbl> <dbl>    <dbl>       <dbl>      <dbl>
##  1    167           0.944    165   159        6       0.964          9
##  2    153           0.923    153   136       17       0.889          0
##  3    159           0.932    159   146       13       0.918          0
##  4    139           0.903    139   126       13       0.906          0
##  5    142           0.907    142   131       11       0.923          0
##  6    143           0.909    143   128       15       0.895          0
##  7    144           0.910    144   128       16       0.889          0
##  8    142           0.907    142   125       17       0.880          0
##  9    149           0.917    149   135       14       0.906          0
## 10    181           0.964    165   154       11       0.933          4
## # … with 9,990 more rows, and 1 more variable: empty_seats <dbl>
```

```r
# lets visualize the overbooked passengers distribution
sim %>%  
  count(overbooked) %>% 
  head(10) %>% 
  knitr::kable()
```



| overbooked|    n|
|----------:|----:|
|          0| 8014|
|          1|  206|
|          2|  230|
|          3|  223|
|          4|  231|
|          5|  199|
|          6|  193|
|          7|  188|
|          8|  159|
|          9|  126|

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
##  1550
```

E comprovadamente, apenas 84% de ter dois ou menos passageiros remanejados neste cenário, comparado à 93% do cenário anterior. Vamos refazer a simulação considerando várias estratégias para o overbooking, como fizemos no modelo anterior.


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
