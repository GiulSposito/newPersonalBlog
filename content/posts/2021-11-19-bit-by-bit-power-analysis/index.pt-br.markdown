---
title: Introdução à Analise de Potência em R
author: Giuliano Sposito
date: '2021-11-20'
slug: 'bit-by-Bit-power-analysis-01-02'
categories:
  - data science
tags:
  - rstats
  - power analysis
  - hypothesis test
  - simulation
  - sample size
subtitle: 'Análise de Potência - Parte 01 - Introdução'
lastmod: '2021-11-15T17:38:47-03:00'
draft: no
authorLink: ''
description: ''
hiddenFromHomePage: no
hiddenFromSearch: no
featuredImage: 'images/hypothesis.jpg'
featuredImagePreview: 'images/hypothesis_featured.jpg'
toc:
  enable: yes
math:
  enable: yes
lightgallery: no
license: ''
---

Este _post_ explora a técnica de análise de potência. Potência é a probabilidade de detectar um efeito, dado que o efeito realmente existe. Em outras palavras, é a probabilidade de rejeitar a hipótese nula quando ela é de fato falsa. Por exemplo, digamos que em um estudo com a droga A e um grupo de placebo, como garantir detectar que a que a droga é realmente eficaz; a potênica é a probabilidade de encontrar uma diferença entre os dois grupos[^ucla].

<!--more-->

### Introdução

Então, imagine que tivéssemos uma potência de 0,8 e que este estudo simples foi realizado muitas vezes. Tendo **potênica de 0,8 significa que 80% do tempo**, obteríamos **uma diferença estatisticamente significativa** entre os grupos de medicamento A e placebo. Isso também significa que **20% das vezes que executamos esta experiência, não obteremos um efeito estatisticamente significativo entre os dois grupos, embora realmente haja um efeito na realidade&&.

Talvez **o uso mais comum seja determinar o número necessário de amostras para detectar um efeito de um determinado tamanho**. Observe que tentar encontrar o número mínimo absoluto de amostras necessários no estudo muitas vezes não é uma boa ideia. Por outro lado, **a análise de potênica pode ser usada para determinar a potênica, dado um tamanho de efeito e o número de amostras disponíveis**. Você pode fazer isso quando sabe, por exemplo, que apenas 75 amostras estão disponíveis para a análise (ou que você só tem orçamento só para 75 amostragens) e deseja saber se terá potênica suficiente para justificar a realização do estudo. Em muitos casos, **realmente não há sentido em conduzir um estudo seriamente insuficiente**.

Além da questão do número de amostras necessárias, existem outras boas razões para fazer uma análise de potência. Por exemplo, muitas vezes é necessária uma análise de potência como parte de uma proposta de financiamento. E, finalmente, fazer uma análise de potência costuma ser apenas parte de fazer uma boa pesquisa; Uma análise de potência é uma boa maneira de garantir que você pensou em todos os aspectos do estudo e da análise estatística antes de começar a coletar dados.



### Exemplos

#### Encontrando o tamanho da amostra

Vamos aplicar a *análise de potência* no seu caso mais comum, determinar o número necessário de amostras para detectar um determinado efeito, neste caso vamos usar o [`{pacote pwr}`](https://cran.r-project.org/web/packages/pwr/pwr.pdf) em um cenário de tratamento com drogas. Vamos considerar um grupo de controle e um grupo de tratamento para COVID-19, por exemplo. Para simplificar o caso, assumimos que o tempo de recuperação para COVID-19 é _normalmente distribuído_ em torno de 21,91 dias (média) e com um desvio padrão de 5,33 dias [^covid], quantos indivíduos precisaremos ter na amostra para detectar um tratamento que pode encurtar o tempo de recuperação em 5 dias?



```r
# install.packages("pwr")
library(pwr)
library(broom)
library(tidyverse)

# covid recovery time (mean and sd)
mo <- 21.91
s0 <- 5.33

# we want to detect 5 day early-recovery time (at same standard deviation) 
mt <- mo-5

# simulation the populations
popCntrl <- rnorm(10000, mo, s0) #control
popTreat <- rnorm(10000, mt, s0) #under treatment

# lets see the populations 
data.frame(
  recoveryTime = c(popCntrl, popTreat),
  group = rep(c("control","popTreat"), each=10000)
) %>%
  ggplot(aes(x=recoveryTime, fill=group, group=group))+
  geom_histogram(alpha=.5, position = 'identity') +
  theme_minimal() +
  labs(title = "Distribuição da População", subtitle = "Comparando grupos de controle e tratamento")
```

<img src="/posts/2021-11-19-bit-by-bit-power-analysis/index.pt-br_files/figure-html/simpleCasePops-1.png" width="672" />

Geramos duas populações diferentes cujo tamanho da diferença média é bem evidente, e então vamos fazer uma análise de poder para definir o tamanho da amostra necessário para detectar essa diferença média (~5 dias).

Para fazer isso, temos que calcular o parâmetro _tamanho do efeito_, neste caso usamos a própria medida da diferença média em desvios padrão da população (um desvio padrão composto de duas populações, mas neste caso, para simplificar, vamos considerar o mesmo em ambas as populações)[^stats].

Portanto, a fórmula _tamanho do efeito_ é:

$$ d=\frac{|\mu_{control}-\mu_{popTreat}|}{\sigma} $$

Onde $ \mu $ são as respectivas médias do grupos e $ \sigma $ é o desvio padrão comum. Portanto, podemos usar o pacote `{pwr}` para calcular o tamanho da amostra necessária para rejeitar a hipótese nula com 80% de _potência estatística_.


```r
# size efect 21.91 to 16.91
# in this case (simple t.test) the effect size is the mean difference in
# standard deviations (like z-score)
es <- (mo-mt)/s0

# Power Analysis 
pa <- pwr.t.test(sig.level = 0.05, power = .8, d = es)
pa
```

```
## 
##      Two-sample t test power calculation 
## 
##               n = 18.84853
##               d = 0.9380863
##       sig.level = 0.05
##           power = 0.8
##     alternative = two.sided
## 
## NOTE: n is number in *each* group
```

Obtemos o tamanho mínimo da amostra para este caso como 19 indicado pelo parâmetro `n` no valor de retorno. Vamos checar:


```r
# samples from control and treatment groups
smpC <- sample(popCntrl, ceiling(pa$n))
smpT <- sample(popTreat, ceiling(pa$n))

# perform a hypothesis test
t <- t.test(smpT, smpC)
t
```

```
## 
## 	Welch Two Sample t-test
## 
## data:  smpT and smpC
## t = -2.193, df = 26.52, p-value = 0.03727
## alternative hypothesis: true difference in means is not equal to 0
## 95 percent confidence interval:
##  -8.2565512 -0.2710736
## sample estimates:
## mean of x mean of y 
##  16.77456  21.03837
```

Como você pode ver, podemos testar a hipótese com um _p.value_ de 0.0373, mostrando que as duas amostras vieram de fato de populações diferentes.

Para entender essa análise, vamos ver como o comportamento do _p.value_ neste caso, para diferentes tamanhos de amostras vamos repetir a amostragem e o teste estatístico 100 vezes e observar a distribuição do seu valor.


```r
# different samples to check how p.value behaviors 
# from 3 (minimal) to the power analysis sujestions (and more 2)
n_samples <- 3:(ceiling(pa$n)+2)

# for each sample size we perform a hypothesis test 100 times
# we are interesting in the 'p.value' distribution 
iter.tests <- 1:100 %>% 
  map_df(function(.i){
    # for each sample size 
    n_samples %>% 
      map_df(function(n){
      t.test(sample(popCntrl,n), sample(popTreat,n)) %>% 
        tidy() %>% 
        select(p.value) %>% 
        mutate(sample_size=n) %>% 
        return()
      }) 
  })

# ploting the p.values distribution along each sample size
iter.tests %>% 
  ggplot(aes(x=as.factor(sample_size), y=p.value)) +
  geom_boxplot() +
  geom_hline(yintercept = 0.05, color="red", linetype="dashed")+
  theme_minimal() + 
  labs(title = "Efeito do tamanho da amostra no p-value",
       subtitle = "Distribuição do P-Value encontrato em 100 testes estatísticos à diferentes tamanhos de amostras",
       y = "distribuição do valor do p.value",
       x = "tamanho da amostra")
```

<img src="/posts/2021-11-19-bit-by-bit-power-analysis/index.pt-br_files/figure-html/phaking-1.png" width="672" />

Você pode ver que o teste de hipótese de duas amostras provenientes de populações diferentes começa a indicar uma significância estatística de 0,05 (na maioria dos casos) para rejeitar a _hipótese nula_ quando o tamanho da amostra se aproxima do número sugerido pela análise de poder (19), também podemos medir a frequência com que um _t.test_ encontra significância estatística para cada tamanho de amostra diferente.


```r
# lets count (for each sample size) in how many of the 100 trials
# we obtain a statistical significance (pvalue <= 0.05)
iter.tests %>% 
  mutate( rejected = p.value <=0.05 ) %>% 
  count(rejected, sample_size) %>% 
  mutate(n=n/100) %>% # pct
  filter(rejected==T) %>% 
  # lets see the proportion 
  ggplot(aes(x=sample_size, y=n)) +
  # power parameter 
  geom_hline(yintercept = pa$power, color="red", linetype="dashed" ) +
  # sample size to detect the desired effect size at 80% of power
  geom_vline(xintercept = ceiling(pa$n), color="red", linetype="dashed") +
  geom_point() + 
  ylim(0,1) +
  theme_minimal() +
  labs(title = "Potência Estatística",
       subtitle="Probabilitdade que o seu teste irá encontrar uma significância estatística verdadeira.",
       x="tamanho da amostraa", y="potência estatística")
```

<img src="/posts/2021-11-19-bit-by-bit-power-analysis/index.pt-br_files/figure-html/unnamed-chunk-1-1.png" width="672" />

A frequência com que o _t.test_ passa a obter 0,05 como _p.value_ para rejeitar a _hipótese nula_ ultrapassa 80% (_parâmetro de potência_) quando o tamanho da amostra chega perto do 19, como era e se esperar, uma vez que realizamos a _análise de potência_ com 0,8 como parâmetro _potência_.

#### Que tamanho de efeito podemos detectar em uma situação?

Outra maneira de usar a _análise de potência_ é encontrar, em algumas condições ou cenário de pesquisa, qual é o menor _tamanho do efeito_ que podemos detectar (com significância estatística). Por exemplo, no mesmo cenário acima, para um tempo de recuperação de COVID-19 ($ \mu=21,9, \sigma=5,33 $), se os pesquisadores executarem um ensaio para uma droga com 50 indivíduos, 25 no controle e 25 no tratamento, qual é o menor _tamanho do efeito_ que podemos detectar?

Usando o mesmo pacote e função, mas agora, passando nos parâmetros o tamanho da amostra e não _defeito o tamanho_:


```r
# Power Analysis 
pa2 <- pwr.t.test(sig.level = 0.05, power = .8, n=25)
pa2
```

```
## 
##      Two-sample t test power calculation 
## 
##               n = 25
##               d = 0.8087121
##       sig.level = 0.05
##           power = 0.8
##     alternative = two.sided
## 
## NOTE: n is number in *each* group
```

Assim, obtemos que o _tamanho do efeito_ que podemos detectar estatisticamente é de 0.938, que neste caso representa 5 em dias de recuperação ($ h * \sigma $).

### Conclusão

_Análise de Potência_ desempenha um papel importante em uma pesquisa estatística, podemos usar esta técnica para evitar _p.hacking_ e definir os parâmetros de pesquisa antes de realizá-la a fim de reforçar nossas conclusões e diminir viéses.

### Continua

No próximo post, vamos explorar um caso de uso para análise de poder tirado do livro de Matthew J. Salganik [Bit by Bit: Social Research in the Digital Age](https://www.amazon.com/Bit-Social-Research-Digital-Age/dp/0691158649) mostrando como é difícil medir o retorno sobre o investimento de anúncios online, mesmo com experimentos digitais envolvendo milhões de clientes.

### Referências

[^ucla]: [Introduction to Power Analysis, UCLA](https://stats.idre.ucla.edu/other/mult-pkg/seminars/intro-power/)

[^covid]: [Estimation of COVID-19 recovery and decease periods in Canada using machine learning algorithms](https://www.medrxiv.org/content/10.1101/2021.07.16.21260675v1.full)

[^stats]: [Power Analysis Overview](https://www.statmethods.net/stats/power.html)

<!-- dolar &#36; --> 
