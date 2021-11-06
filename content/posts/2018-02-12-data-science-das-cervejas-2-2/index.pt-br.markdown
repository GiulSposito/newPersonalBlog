---
title: Data Science das Cervejas (2/2)
author: Giuliano Sposito
date: '2018-02-12'
slug: 'data-science-das-cervejas-2-2'
categories:
  - data science
tags:
  - beers
  - rstats
  - text mining
  - rvest
  - tidytext
  - web scraping
  - data analysis
  - hierarchical clustering
  - hclust
  - correlation
subtitle: ''
lastmod: '2021-11-06T12:31:50-03:00'
authorLink: ''
description: ''
hiddenFromHomePage: no
hiddenFromSearch: no
featuredImage: 'images/beertm_2b_cover.jpg'
featuredImagePreview: 'images/beertm_2b_cover.jpg'
toc:
  enable: yes
math:
  enable: no
lightgallery: no
license: ''
---
<script src="/rmarkdown-libs/kePrint/kePrint.js"></script>
<link href="/rmarkdown-libs/lightable/lightable.css" rel="stylesheet" />


Esta é a segunda parte do post sobre _text mining_ usando como base, a avaliações de cervejas extraído de um blog na web. Neste post analisaremos as semelhanças entre os diversos tipos através de suas características de sabor, cor e malte. Quais tipos de cervejas são semelhantes entre si e como tipos semelhantes ainda se diferem. Esse tipo de análise é um aspecto importante no campo de _Data Science_, pois permite construir um processo de "sugestões" para consumo, tomando como base o gosto atual dos usuários.

<!--more-->




### Que cerveja é similar a outra?

O primeiro passo neste processo é encontrar que semelhanças aproximam os diferentes tipos de cerveja, para tal, vamos recuperar os dados obtidos no [post anterior](https://yetanotheriteration.netlify.com/2018/02/data-science-das-cervejas-1-2/). A nossa base de avaliações de cervejas, obtido via _data scraping_ do blog [Cerva Nossa](https://cervanossa.wordpress.com/) do Marcos Nogueira, e a contagem de palavras por tipo.


```r
# libs
library(tidyverse) # pipe, maps and tibble

# recuperando contagem de palavras gravada no post anterior
beers <- readRDS("./data/beers.rds")
beer_wordc <- readRDS("./data/beer_wordc.rds")
glimpse(beer_wordc)
```

```
## Rows: 12,581
## Columns: 4
## $ word       <chr> "12", "15", "15", "20", "20", "22", "30", "30", "35", "40",~
## $ tipo       <chr> "Lambic (Fruit)", "Ale (Dubbel)", "Lambic (Fruit)", "Ale", ~
## $ super.tipo <chr> "Lambic", "Ale", "Lambic", "Ale", "Brown Ale", "Ale", "Lamb~
## $ n          <int> 1, 1, 1, 1, 1, 1, 4, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1,~
```

#### Correlação

A técnica mais óbvia para determinar semelhança entre tipos é correlacionar a frequência das palavras encontradas nas descrições entre os diversos tipos. Ou seja, tipos que possuem frequentemente a mesma palavra são tipos que são semelhantes entre si.

Por exemplo, se a Weiss é descrita com "sabor de trigo" e a WitBier também contém "trigo" na descrição, então elas são semelhantes, mais semelhantes conforme a frequência de "trigo" aparece nas descrições das diversas cervejas de ambas categorias.

Então, vamos tabular a frequência de cada uma das palavras em cada um dos tipos de cerveja.


```r
# vamos limitar a analise aos tipos que possuem mais de 3 avaliações
# para facilitar a visualização dos dados 
beers %>% 
  group_by(tipo) %>% 
  tally() %>% 
  filter(n>3) -> selected.types

# a partir da contagem de palavras por tipo
beer_corr <- beer_wordc %>%
  # selecionar os tipos que interessam
  filter(tipo %in% selected.types$tipo) %>%
  select(-super.tipo) %>%
  # por tipo calcular a porporcao em que a palavra aparece
  group_by(tipo) %>%
  mutate(proporcao = n / sum(n))  %>%
  # manter as palavras (por tipo) que aparecem com mais frequencia
  subset(n >= 5) %>%
  select(-n) %>%
  # pivotar para ter "palavra" x "tipo"
  spread(tipo, proporcao)

# zerar as células em que o tipo não possuem a palavra (NA -> 0)
beer_corr[is.na(beer_corr)] <- 0 

# mostrando um subset da tabulacao
beer_corr[1:10, 1:5] %>%
  kable() %>% 
  kableExtra::kable_styling(font_size = 11)
```

<table class="table" style="font-size: 11px; margin-left: auto; margin-right: auto;">
 <thead>
  <tr>
   <th style="text-align:left;"> word </th>
   <th style="text-align:right;"> Abadia (Ale) </th>
   <th style="text-align:right;"> Ale </th>
   <th style="text-align:right;"> Ale (English Pale Ale) </th>
   <th style="text-align:right;"> Amber Ale </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> abundante </td>
   <td style="text-align:right;"> 0.0400000 </td>
   <td style="text-align:right;"> 0.0294785 </td>
   <td style="text-align:right;"> 0.0000000 </td>
   <td style="text-align:right;"> 0.0000000 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> acidez </td>
   <td style="text-align:right;"> 0.0000000 </td>
   <td style="text-align:right;"> 0.0000000 </td>
   <td style="text-align:right;"> 0.0000000 </td>
   <td style="text-align:right;"> 0.0000000 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> açúcar </td>
   <td style="text-align:right;"> 0.0000000 </td>
   <td style="text-align:right;"> 0.0158730 </td>
   <td style="text-align:right;"> 0.0000000 </td>
   <td style="text-align:right;"> 0.0000000 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> adocicado </td>
   <td style="text-align:right;"> 0.0000000 </td>
   <td style="text-align:right;"> 0.0158730 </td>
   <td style="text-align:right;"> 0.0000000 </td>
   <td style="text-align:right;"> 0.0000000 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> agradável </td>
   <td style="text-align:right;"> 0.0000000 </td>
   <td style="text-align:right;"> 0.0000000 </td>
   <td style="text-align:right;"> 0.0000000 </td>
   <td style="text-align:right;"> 0.0000000 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> álcool </td>
   <td style="text-align:right;"> 0.0000000 </td>
   <td style="text-align:right;"> 0.0000000 </td>
   <td style="text-align:right;"> 0.0000000 </td>
   <td style="text-align:right;"> 0.0000000 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> amadeirado </td>
   <td style="text-align:right;"> 0.0342857 </td>
   <td style="text-align:right;"> 0.0408163 </td>
   <td style="text-align:right;"> 0.0000000 </td>
   <td style="text-align:right;"> 0.0000000 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> amarelo </td>
   <td style="text-align:right;"> 0.0285714 </td>
   <td style="text-align:right;"> 0.0158730 </td>
   <td style="text-align:right;"> 0.0000000 </td>
   <td style="text-align:right;"> 0.0000000 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> amargor </td>
   <td style="text-align:right;"> 0.0628571 </td>
   <td style="text-align:right;"> 0.0544218 </td>
   <td style="text-align:right;"> 0.0697674 </td>
   <td style="text-align:right;"> 0.0561798 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> âmbar </td>
   <td style="text-align:right;"> 0.0000000 </td>
   <td style="text-align:right;"> 0.0113379 </td>
   <td style="text-align:right;"> 0.0000000 </td>
   <td style="text-align:right;"> 0.0000000 </td>
  </tr>
</tbody>
</table>


Contamos então a frequência com que cada uma das palavras (linhas) aparece, frente as outras palavras, e tabulando para cada tipo de cerveja (colunas). Para descobrir qual tipo é mais semelhante com o outro, basta calcular a correlação entre essas frequências, usaremos a função `cor()` para gerar uma matriz de correção (entre os tipo) e a função `corrplot` para visualizá-la.


```r
# definindo uma palheta de cores para escala de correlação [-1,1]
mycol <- colorRampPalette(c("red", "lightsalmon", "white", "paleturquoise", "blue"))

# calculando a correlação (tirando a primeira coluna que é a palavra)
library(corrplot)  # correlation plot
cor(beer_corr[,-1], use = "pairwise.complete.obs") %>%  
  # plotando a correlação, organizando como um hclust
  corrplot(method="color", order="hclust", diag=FALSE, 
           tl.col = "black", tl.srt = 45, tl.cex=0.7,
           col=mycol(100), 
           # triangulo inferior (já que é uma matriz simétrica)
           type="lower",
           title="Correlaçao entre Tipos de Cerveja",
           mar=c(0,0,1,0))
```

<img src="/posts/2018-02-12-data-science-das-cervejas-2-2/index.pt-br_files/figure-html/plotCorr-1.png" width="960" />

Podemos observar o grau de similaridade entre os tipos de cerveja e verificar que há estruturas entre eles. Configuramos o plot aproximar os itens semelhantes entre si (via parâmetro `hclust`), então a ordenação reflete essa informação, os tipos mais próximos estão mais relacionados entre si.

#### Clusters

Outra maneira de encontrar os tipos mais semelhantes é _clusterizar_, para tal, tratamos cada palavra como uma dimensão no espaço de descrições, e então usamos a frequência com que ela ocorre como um ponto neste espaço, a partir daí calculamos a distancia entre cada um dos pontos e então _clusterizamos_, agrupando os tipos mais próximos entre si.


```r
# removendo a coluna da palavra
beer_corr[,-1] %>%
  # transpondo: observação (tipo) na linha e features nas colunas (palavras)
  t() %>%
  # calculando a distancia (euclidiana) entre as observações
  dist(method="euclidean") -> beer.dist

beer.dist %>%
  # clusterizando (hierarquicamente)
  hclust(method="ward.D") -> beer.clusters

# agrupando em 10 tipos distintos
clusters = cutree(beer.clusters, 10)

# palheta de cores para visualizacao (10 grupos)
library(RColorBrewer) # color palette
colors = RColorBrewer::brewer.pal(10,"Paired")

# plotando como uma "roda"
library(ape)       # disk dendogram : implementa o "as.phylo"
plot(as.phylo(beer.clusters), type = "fan", tip.color = colors[clusters],
     label.offset = 0, cex = 0.9)
```

<img src="/posts/2018-02-12-data-science-das-cervejas-2-2/index.pt-br_files/figure-html/hclusterPlot-1.png" width="864" />

A clusterização aproxima tipos de cervejas diferentes mas que possuem as mesmas características de sabor, cor e malte. Note que o número de grupos é relativamente "arbitrário", nos escolhemos agrupar por distância em 10 grupos quando aplicamos o `cutree`. 


Vamos ver quais as palavras que definem dois tipos diferentes que foram colocados juntos: a _English Poter_ e a _American Brown Ale_.


```r
# pacote para tratamento de textos do tidyverse 
library(tidytext)

# partindo da contagem de palavras
beer_wordc %>%
  # somente os tipos de interesse
  filter( tipo %in% c("Porter (English Porter)","Brown Ale (American Brown Ale)"),
          n>1) %>%
  # conta por tipo
  group_by(word, super.tipo) %>%
  summarise(n=sum(n)) %>%
  group_by(super.tipo) %>%
  # seleciona as 15 mais frequentes palavras
  top_n(15, n) %>%
  # garante que são  somente as 15 mesmos
  filter(row_number() <= 15) %>%
  # ordena 
  arrange(super.tipo, desc(n)) %>%
  ungroup() %>%
  # atribui um rank para cada palavra dentro do tipo (facilitar o plot) 
  mutate(Rank = rep(15:1, 2)) %>%
  # plota um bar chart na horizontal de palavras
  # para cada um dos tipos, mostrando as top 15
  ggplot(aes(x=as.factor(Rank), y=n)) +  
    geom_bar(stat="identity", fill="cadetblue", alpha=0.5) + 
    coord_flip() + facet_wrap(~super.tipo,ncol=4) + 
    geom_text(aes(label=word, x=Rank), y=0,hjust=0, size=4) +
    labs(title="15 palavras mais comuns para cada tipo", 
         x="", y="n") +
    theme_bw() + 
    theme(axis.title.y=element_blank(),
          axis.text.y=element_blank(),
          axis.ticks.y=element_blank(),
          panel.grid.major = element_blank(),
          panel.grid.minor = element_blank())
```

<img src="/posts/2018-02-12-data-science-das-cervejas-2-2/index.pt-br_files/figure-html/twoSimilarBeers-1.png" width="672" />
 
 Podemos notar que há uma série de palavras comuns descrevendo ambos os tipos, como _maltada_, _café_, _cevada_, _espuma_ e _duradouro_, que são características comuns entre os dois.
 
 Mas e se quiséssemos evidenciar o que difere uma tipo do outro? Usaríamos a mesma técnica usada no [post anterior](https://yetanotheriteration.netlify.com/2018/02/data-science-das-cervejas-1-2/), calcularíamos quais as palavras mais importantes, distintas entre as descrições dos dois tipos, usando [TF_IDF](https://en.wikipedia.org/wiki/Tf%E2%80%93idf).



```r
# partindo da contagem de palavras
beer_wordc %>%
  # somente dos tipos em que estamos interessaods
  filter( tipo %in% c("Porter (English Porter)","Brown Ale (American Brown Ale)"),
          n>1) %>%
  # agrupa a contagem por tipo
  group_by(word, super.tipo) %>%
  summarise(n=sum(n)) %>%
  # calcula o total por palavra
  group_by(word) %>%
  mutate(word_total = sum(n)) %>%
  # calcula o TF_IDF
  bind_tf_idf(word, super.tipo, n)  %>%
  # remove quem obteve zero de score e ordena descrescente
  subset(tf_idf > 0) %>%
  arrange(desc(tf_idf)) %>%
  group_by(super.tipo) %>%
  top_n(10, tf_idf) %>% 
  filter(row_number() <= 10) %>% 
  # ordena por tipo e score (desc)
  arrange(super.tipo, desc(tf_idf)) %>%
  ungroup() %>%
  # atribui um rank para cada palavra dentro do tipo (facilitar o plot) 
  mutate(Rank = rep(10:1, 2)) %>%
  # plota um bar chart na horizontal de palavras
  # para cada um dos tipos, mostrando as top 10
  ggplot(aes(x=as.factor(Rank), y=tf_idf)) +  
    geom_bar(stat="identity", fill="cadetblue", alpha=0.5) + 
    coord_flip() + facet_wrap(~super.tipo,ncol=4) + 
    geom_text(aes(label=word, x=Rank), y=0,hjust=0, size=4) +
    labs(title="10 palavras com mais TF-IDF por tipo de cerveja", 
         x="", y="tf-idf") +
    theme_bw() + 
    theme(axis.title.y=element_blank(),
          axis.text.y=element_blank(),
          axis.ticks.y=element_blank(),
          panel.grid.major = element_blank(),
          panel.grid.minor = element_blank())
```

<img src="/posts/2018-02-12-data-science-das-cervejas-2-2/index.pt-br_files/figure-html/twoBeersDifferences-1.png" width="672" />

Agora podemos observar que elementos como `caramelo x chocolate`, `marrom x preta`, `coco x baunilha` e `herbáceo x seco` são elementos que diferencia a _American Brown Ale_ de uma _English Porter_.

Essas informações são interessantes em um sistema de sugestões, você pode procurar primeiro pelo cluster similar à um produto o usuário já aprecia e então dentro do cluster oferecer similares, ou então, navegar pelas diferenças, sugerindo direções como `+frutada`, `+chocolate`, `+leve`, etc, e a partir disto oferecer as cervejas que cumprem esses quesitos.

### Conclusão

Podemos observar como técnicas de processamento de texto e simples contagens de palavras nos dão _insights_ relevantes sobre produtos. A extração dessas informações e disponibilização delas para outras ferramentas de análise deados podem nos dar graus de similaridade/dissimilaridade, oferecendo oportunidades econômicas interessantes.
