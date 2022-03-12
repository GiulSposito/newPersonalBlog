---
title: Business Analytics | Modelo de classificação em um caso de Retorno do Investimento
author: Giuliano Sposito
date: '2022-01-18'
slug: 'classifier-model-and-return-of-investment'
categories:
  - data science
  - advanced business analytics
tags:
  - evaluation
  - machine learning
  - model
  - data science
  - classifier
  - random forest
  - metrics
subtitle: ''
lastmod: '2022-01-18T16:17:51-03:00'
authorLink: ''
description: ''
hiddenFromHomePage: no
hiddenFromSearch: no
featuredImage: 'images/post_cover.png'
featuredImagePreview: 'images/post_cover.png'
toc:
  enable: yes
math:
  enable: no
lightgallery: no
license: ''
---



Você pode imaginar um caso de negócios real onde você aplica aprendizado de máquina para construir um classificador (Random Forest) e a precisão do acurácia não é a (única) métrica a ser observada e levanda em conta? Em cenários reais os custos e benefícios podem afetar um modelo em diferentes aspectos, muitas vezes retorno de um investimento é dependente do comportamento da métrica precisão (_precision_).

<!--more-->

### Introdução

Consultas médicas perdidas custam ao sistema de saúde dos EUA mais de US$ 150 bilhões por ano. Elas causam diretamente a perda de receita e a subutilização dos escaços e preciosos recursos médicos, além disso, também leva a longos tempos de espera de pacientes e a longo prazo eleva os custos médicos como um todo.

Nesse contexto, vamos construir um modelo preditivo para estimar se um paciente perderá uma consulta e usar a previsão para como base para tomada de ação a fim de tentar evitar o cancelamento.

### Dados

Obtivemos um [conjunto de dados](./assets/data.xlsx) com 7.463 consultas médicas em um período de três anos em uma clínica especializada. Nesse conjunto de dados cada linha corresponde a um compromisso e indica se foi cancelado ou não.


```r
library(xlsx)
library(tidyverse)

# the life, the universe an everything else...
set.seed(42)

# data set
rawdata <- xlsx::read.xlsx("./assets/data.xlsx", sheetIndex = 1)

# basic clean_up
appdata <- rawdata %>% 
  as_tibble() %>% 
  janitor::clean_names() %>% 
  mutate_if(is.character, as.factor)

dim(appdata)
```

```
## [1] 7463   12
```

#### Visão geral dos dados

Vamos ver o aspecto geral do conjunto de dados


```r
skimr::skim(appdata)
```


Table: Table 1: Data summary

|                         |        |
|:------------------------|:-------|
|Name                     |appdata |
|Number of rows           |7463    |
|Number of columns        |12      |
|_______________________  |        |
|Column type frequency:   |        |
|factor                   |7       |
|numeric                  |5       |
|________________________ |        |
|Group variables          |None    |


**Variable type: factor**

|skim_variable  | n_missing| complete_rate|ordered | n_unique|top_counts                                 |
|:--------------|---------:|-------------:|:-------|--------:|:------------------------------------------|
|month          |         0|             1|FALSE   |       12|Aug: 815, May: 791, Jun: 721, Mar: 715     |
|weekday        |         0|             1|FALSE   |        5|Fri: 1733, Tue: 1715, Thu: 1640, Wed: 1448 |
|gender         |         0|             1|FALSE   |        2|F: 5176, M: 2287                           |
|marital_status |         0|             1|FALSE   |        4|MAR: 2504, SIN: 2434, OTH: 1505, DIV: 1020 |
|employment     |         0|             1|FALSE   |        4|UNE: 3824, RET: 1692, FUL: 1370, OTH: 577  |
|insurance      |         0|             1|FALSE   |        4|OTH: 2453, MED: 2366, HMO: 1982, PPO: 662  |
|status         |         0|             1|FALSE   |        2|Arr: 5801, Can: 1662                       |


**Variable type: numeric**

|skim_variable  | n_missing| complete_rate|        mean|          sd|      p0|      p25|      p50|      p75|     p100|hist  |
|:--------------|---------:|-------------:|-----------:|-----------:|-------:|--------:|--------:|--------:|--------:|:-----|
|date_id        |         0|             1|      525.13|      303.16|       1|      267|      505|      791|     1081|▇▇▇▆▆ |
|lag            |         0|             1|       27.24|       24.47|       0|       13|       20|       30|      126|▇▂▁▁▁ |
|mrn            |         0|             1| 34251294.01| 12244201.39| 7967755| 28165486| 41065688| 42621914| 44150534|▂▁▁▁▇ |
|age            |         0|             1|       54.09|       18.52|       6|       47|       57|       67|       90|▂▂▆▇▂ |
|time_since_reg |         0|             1|     4754.47|     2399.85|     179|     4374|     5686|     6196|     8421|▂▁▁▇▁ |

No total, 1.662 dos 7.463 agendamentos foram cancelados, podemos ver na coluna **status** (nossa variável _target_).

### Modelo

Como estamos interessados em cancelamentos de compromissos, a variável alvo é descobrir se um agendamento foi cancelado ou não e o sucesso nesse contexto específico significa prever corretamente que um agendamento foi cancelado.


```r
library(tidymodels)

# training & test data partition
appsplit <- initial_split(appdata)

# basic transformation
apprecp <- appsplit %>% 
  training() %>% 
  recipe(status ~ ., data=.) %>% 
  update_role(date_id, new_role = "id variable") %>% 
  update_role(status, new_role = "outcome") %>% 
  step_log(lag) %>% 
  step_dummy(all_nominal_predictors()) %>% 
  prep() 

# training & test set
app_tr <- juice(apprecp)
app_ts <- bake(apprecp, testing(appsplit))

# fit a model
app_model <- rand_forest(trees = 100, mode="classification") %>% 
  set_engine("ranger") %>% 
  fit(status ~ . - date_id, data=app_tr)
```

We build a simple and direct [random forest](https://en.wikipedia.org/wiki/Random_forest) model using [Ranger](https://www.rdocumentation.org/packages/ranger/versions/0.13.1/topics/ranger) implementation through [Tidymodels](https://www.tidymodels.org/) package. 


```r
app_model
```

```
## parsnip model object
## 
## Fit time:  443ms 
## Ranger result
## 
## Call:
##  ranger::ranger(x = maybe_data_frame(x), y = y, num.trees = ~100,      num.threads = 1, verbose = FALSE, seed = sample.int(10^5,          1), probability = TRUE) 
## 
## Type:                             Probability estimation 
## Number of trees:                  100 
## Sample size:                      5597 
## Number of independent variables:  30 
## Mtry:                             5 
## Target node size:                 10 
## Variable importance mode:         none 
## Splitrule:                        gini 
## OOB prediction error (Brier s.):  0.1617746
```

#### Avaliação

Quão bom é o nosso modelo?


```r
# eval it
app_pred <- predict(app_model, app_ts) %>%  # class outcome
  bind_cols(predict(app_model, app_ts, type = "prob")) %>% # class prob
  bind_cols(select(app_ts,status)) %>%  # true value
  relocate(status, everything())

# performance
cm <- app_pred %>% 
  conf_mat(status, .pred_class)

cm %>% 
  summary() %>% 
  select(-.estimator) %>% 
  knitr::kable()
```



|.metric              | .estimate|
|:--------------------|---------:|
|accuracy             | 0.7599143|
|kap                  | 0.1613651|
|sens                 | 0.9216366|
|spec                 | 0.2099057|
|ppv                  | 0.7986779|
|npv                  | 0.4405941|
|mcc                  | 0.1774102|
|j_index              | 0.1315423|
|bal_accuracy         | 0.5657711|
|detection_prevalence | 0.8917471|
|precision            | 0.7986779|
|recall               | 0.9216366|
|f_meas               | 0.8557630|

```r
# AUC
app_pred %T>% 
  roc_auc(.pred_Arrived, truth=status) %>% 
  roc_curve(.pred_Arrived, truth=status) %>% 
  autoplot()
```

<img src="/posts/2022-01-18-business-analytics-classifier-model-and-return-of-investment-case/index.pt-br_files/figure-html/modelEval-1.png" width="672" />

### Desião de Negócio para Tomada de Ação

Com a previsão em mãos, podemos fazer uma ação de negócio para tentar reverter os cancelamentos de agendamentos. Vamos supor que podemos fazer uma ligação telefônica para qualquer pessoa prevista como "Cancelada" com um ou dois dias de antecedência e isso poderá reverter em torno de 30% dos agendamentos que seriam cancelados. Será que essa ação uma abordagem viável? É economicamente viável? Ou, pelo menos, mais em conta do que deixar o paciente cancelar sua consulta?

Para decidir isso precisamos estabelecer o valor de algumas variáveis para um modelo econômico de retorno, para este exercício podemos assumir:

* Custo de um telefonema: $5.00
* Taxa de reversão do cancelamento de agendamento: 30%
* Benefício de uma consulta não perdida: $60.00

Assim, podemos calcular um *Retorno do Investimento* (_RoI_) desta ação neste cenário:


```r
# business variable
phone_cost   <- 5
reverse_rate <- .3
benefit      <- 60

# business case

# cost: phone to all patient predicted as "canceled"
total_cost  <- sum(cm$table["Cancelled",]) * phone_cost

# benefit: the reverse of 30% of patient that (in fact) would cancel the appointment
total_benefit <- cm$table["Cancelled","Cancelled"] * reverse_rate * benefit

# return of the investment
RoI <- total_benefit - total_cost
```

Então obtemos este resultado:

* Custo Total: 202 * $5 = $1010
* Benefício Total: 89 * 0.3 * $60 = $1602
* Retorno: $1602 - $1010 = $592

Como vimos, com um _RoI_ de $592 vale a pena tomar esta ação.

Um aspecto essencial para prestarmos atenção, fazemos uma ligação a todos os pacientes que estão previstos como "cancelamento", mas só obtemos retorno em 30% (taxa de reversão) daqueles verdadeiramente identificados como "cancelamento", a.k.a, **Positivos Verdadeiros** (TP). Em outras palavras, o custo da ação é função de **Verdadeiros Positivos** (TP) mais **Falsos Positivos** (FP) mas o benefício da ação é função apenas de **Verdadeiros Positivos** (TP). Isso porque um **Falso Positivo** (FP) é um paciente previsto como "cancelamento" mas ele irá à consulta, então o telefonema não tráz nenhum benefício, apenas custo nesses casos.

#### Melhorando a Performance da Ação

Podemos melhorar o retorno da ação sem (necessariamente) melhorar o modelo? Como o _RoI_ é função da taxa entre **Verdadeiros Positivos** (TP) e **Verdadeiros Positivos** (TP) + **Falsos Positivos** (FP) (também conhecido como _Métrica de Precisão_) na proporção dos benefícios e custos, podemos _ajustar_ nosso classificador alterando o [_logístic threshold_](https://deepchecks.com/glossary/classification-threshold/) para alterar a _metrica de precisão_ do modelo a fim de maximizar o _RoI_.

Para ver isso na prática, vamos calcular o que acontece com nosso _RoI_ alterando o _threshold_ do classificador de 0 para 1 em incrementos de 0,01:


```r
# generate the confusion metrics in function of an threshold
genConfMatrix <- function(.threshold, .evalData){
  # reply as a tibble row
  # new truth vs prediction table
  tibble(
      truth=.evalData$status, 
      # the prediction as function of the customized threshold
      estimate=unique(.evalData$status)[as.integer(.evalData$.pred_Cancelled>=.threshold)+1]
    ) %>%
    # gen the confusion matrix
    conf_mat(truth, estimate) %>% 
    return()
}

# calculates the RoI based in the result of a confusion matrix
calcRoi <- function(.cm, .benefit=60, .cost=5, .rev_rate=.3){
  tibble(
    TP = .cm$table["Cancelled","Cancelled"],
    FP = .cm$table["Cancelled","Arrived"] ) %>% 
    mutate(
      # cost: phone to all patient predicted as "canceled"
      cost    = (TP+FP) * .cost,
      # benefit: the reverse of 30% of patient that (in fact) would cancel the appointment
      benefit = TP * .rev_rate * .benefit,
      # return of the investment
      roi = benefit-cost
    ) %>% 
    return()
}

# using threshold from 0 to 1 in 0.01 increments
simulations <- tibble(threshold = seq(0,1,.01)) %>% 
  mutate( 
    # gen the confusion matrix and roi values for this threshold
    cm  = map(threshold, genConfMatrix, .evalData=app_pred),
    roi = map(cm, calcRoi)
  ) %>% 
  unnest(roi)

# what we get
simulations %>% 
  select(-cm) %>% 
  head(10) %>% 
  knitr::kable()
```



| threshold|  TP|   FP| cost| benefit|   roi|
|---------:|---:|----:|----:|-------:|-----:|
|      0.00| 424| 1442| 9330|    7632| -1698|
|      0.01| 422| 1098| 7600|    7596|    -4|
|      0.02| 408|  908| 6580|    7344|   764|
|      0.03| 404|  861| 6325|    7272|   947|
|      0.04| 402|  843| 6225|    7236|  1011|
|      0.05| 401|  829| 6150|    7218|  1068|
|      0.06| 401|  825| 6130|    7218|  1088|
|      0.07| 400|  818| 6090|    7200|  1110|
|      0.08| 398|  812| 6050|    7164|  1114|
|      0.09| 393|  797| 5950|    7074|  1124|

```r
# visualizing
simulations %>%           
  ggplot(aes(x=threshold, y=roi)) +
    # geom_point(size=2) +
    geom_line() +
    geom_hline(yintercept = 0, linetype="dashed", color="red") +
    geom_vline(xintercept = 0.5, linetype="dashed", color="darkgrey") +
    scale_x_continuous(breaks=seq(0,1,.1)) +
    ylim(c(-100,NA)) +
    labs(title="Return of Investment", subtitle = "Influence of the Threshold Parameter")
```

<img src="/posts/2022-01-18-business-analytics-classifier-model-and-return-of-investment-case/index.pt-br_files/figure-html/thresholdRange-1.png" width="672" />

Podemos ver que o melhor _RoI_ é obtido usando um _threshold_ entre 0.2 e 0.3, e não 0.5 como normalmente definido, mais do que isso, neste nível temos uma pior _acurácia_ do modelo, veja:


```r
simulations %>% 
  filter(threshold==.3) %>% 
  pull(cm) %>% 
  .[[1]] %>% 
  summary() %>% 
  select(-.estimator) %>% 
  knitr::kable()
```



|.metric              | .estimate|
|:--------------------|---------:|
|accuracy             | 0.6918542|
|kap                  | 0.2451063|
|sens                 | 0.7330097|
|spec                 | 0.5518868|
|ppv                  | 0.8476343|
|npv                  | 0.3780291|
|mcc                  | 0.2535561|
|j_index              | 0.2848965|
|bal_accuracy         | 0.6424483|
|detection_prevalence | 0.6682744|
|precision            | 0.8476343|
|recall               | 0.7330097|
|f_meas               | 0.7861659|
 


Compare esta métrica de _acurácia_ (0.6918542) com o valor obtido no primeiro cálculo acima (0.7599143).

### Métricas de Conclusão e Classificação

Como vimos, uma decisão de negócio não é apenas função da precisão do modelo, custos e benefícios podem afetar diferentes aspectos do modelo. Lembre-se de retornar à vida real ao aplicar o modelo em cenários e casos de negócios, para otimizar o objetivo correto.

E esteja sempre ciente das métricas de classificação.

![Classification Metrics](./images/classification_metrics.png)


```r
simulations %>% 
  mutate(
    metrics = map(cm, function(.x){
      .x %>% 
        summary() %>% 
        select(-.estimator) %>% 
        pivot_wider(names_from = .metric, values_from = .estimate) %>% 
        return()
    })) %>% 
  unnest(metrics) %>%
  select(threshold, accuracy, sens, spec, precision, recall) %>%
  pivot_longer(cols = -threshold, names_to = "metric", values_to = "value") %>% 
  ggplot(aes(x=threshold, y=value, color=metric))+
  geom_line() +
  labs(title="Main Classification Matrics", subtitle="Behavior in function of the logistic threshold") +
  theme_minimal()
```

<img src="/posts/2022-01-18-business-analytics-classifier-model-and-return-of-investment-case/index.pt-br_files/figure-html/classMetricBehavior-1.png" width="672" />
