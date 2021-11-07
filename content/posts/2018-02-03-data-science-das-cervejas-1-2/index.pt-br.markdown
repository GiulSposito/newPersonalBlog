---
title: Data Science das Cervejas (1/2)
author: Giuliano Sposito
date: '2018-02-03'
slug: 'data-science-das-cervejas-1-2'
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
subtitle: ''
lastmod: '2021-11-06T12:05:19-03:00'
authorLink: ''
description: ''
hiddenFromHomePage: no
hiddenFromSearch: no
featuredImage: 'images/beertm_cover.jpg'
featuredImagePreview: 'images/beertm_cover.jpg'
toc:
  enable: yes
math:
  enable: no
lightgallery: no
license: ''
disqusIdentifier: 'data-science-das-cervejas'
---
<script src="/rmarkdown-libs/kePrint/kePrint.js"></script>
<link href="/rmarkdown-libs/lightable/lightable.css" rel="stylesheet" />
<script src="/rmarkdown-libs/kePrint/kePrint.js"></script>
<link href="/rmarkdown-libs/lightable/lightable.css" rel="stylesheet" />
<script src="/rmarkdown-libs/kePrint/kePrint.js"></script>
<link href="/rmarkdown-libs/lightable/lightable.css" rel="stylesheet" />
<script src="/rmarkdown-libs/kePrint/kePrint.js"></script>
<link href="/rmarkdown-libs/lightable/lightable.css" rel="stylesheet" />




Neste post vamos extrair, via _data scraping_, textos e dados de um blog de avaliações de cerveja para encontrar os termos que melhor caracterizam e descrevem os diversos tipos de cerveja através das descrições dos sabores, cores e maltes das mesmas.

<!--more-->

### Base de dados com avaliação das cervejas

O uso de avaliações de cerveja para análise de texto é bem comum[^6], e uma ótima maneira de exercitar técnicas de análise de texto (NLP) para evidenciar diferenças e semelhança entre elementos via descrição textual, e fica ainda mais interessante se você é também um apreciador de cervejas! :)

O primeiro passo é obter os dados descritivos das cervejas. Como não existe uma em português dando sopa por aí, a estratégia é buscar algum site de avaliação de cervejas, com uma boa quantidade de informações, e extrair os dados de lá, montando uma base própria.

#### Data Scraping das avaliações

**Data scraping** (do inglês, raspagem de dados) é uma técnica computacional na qual um programa extrai dados de saída legível somente para humanos, proveniente de um serviço ou aplicativo. Os dados extraídos geralmente são minerados e estruturados em um formato padrão como CSV, XML ou JSON.

**Rvest**[^4] é um pacote que facilita o _scraping_ de dados de páginas web html. Ele é projetado para trabalhar com _magrittr_ para que você possa expressar operações complexas como pipelines facilmente compreendidos.

Com possibilidade de aplicar _seletores CSS_[^5] para capturar elementos específicos e pré-tratamento de listas e tabelas.

#### Blog Cerva Nossa

Usaremos o [blog Cerva Nossa](https://cervanossa.wordpress.com) como fonte para uma descrição das cervejas. O M. Nogueira, autor dos posts do blog, sempre avalia 9 aspectos: País, Tipo, Teor Alcoólico, Cor, Sabor, Malte, Avaliação, Preço e Volume, além da descrição comercial, da imagem da mesma e um link para o site da cervejaria.

![Formato de um post de avaliação](images/cervanossa.png)

Embora as informações estejam num corpo de texto corrido dentro do post, ou seja, não é possível capturá-las individualmente usando um seletores de CSS, o fato do post ter sempre o mesmo formato facilita o tratamento de strings.

O blog gerado em _wordpress_ divide o site em _pages_ e cada uma delas contém 7 posts, aproximadamente com o mesmo código HTML e formato de texto cada um:

```html

<div class="main">
	<p>
	  <img data-attachment-id="7293" src="https://cervanossa.files.wordpress.com/2017/06/ashby-pale-ale.jpg?w=96&#038;h=300" alt="Ashby - Pale Ale" width="96" height="300"/>
	</p>
  <p>
    País: Brasil.<br/>
    Tipo: Pale Ale (English Pale Ale).<br/>
    Teor alcoólico: 5,1%<br/>
    Cor: Amarelo dourado.<br/>
    Sabor: É uma cerveja que equilibra um amargor sutil com um toque caramelado e conjugado com uma boa base maltada. Apresenta breves notas frutadas, resultando numa cerveja fácil de beber. Espuma de boa formação, densa e duradoura; aroma frutado e maltado.<br/>
    Malte: Cevada, cereais não maltados e carboidratos.<br/>
    Avaliação: 8<br/>
    Preço: R$ 9,40<br/>
    Volume: 600 ml
  </p>
  <p style="text-align:justify;">
    <strong>Descrição comercial:</strong><br/>
    A nossa receita vem da tradição inglesa do século XIX e ganha como aliada as águas cristalinas da Serra da Mantiqueira, o que dá um toque especial e a deixa perfeita para paladares mais exigentes. O malte especial, combinado com o lúpulo selecionado, resulta em uma cerveja clara, com amargor leve e distinto.
  </p>
  <p style="text-align:justify;">
    Harmonização: bacalhau, bife grelhado, churrasco, cordeiro grelhado, frango assado e kebab de carne. IBU: 18.
  </p>
  <p style="text-align:justify;">
    História da Cervejaria: A Cervejaria Ashby foi fundada no ano de 1993, na cidade de Amparo/SP, inspirada nas cervejarias norte-americanas e europeias que se dedicavam à pesquisa e ao feitio de bebidas de alta qualidade.
  </p>
  <p>
    Endereço na internet: <a href="http://www.ashby.com.br" target="_blank" rel="noopener">www.ashby.com.br</a>
  </p>
</div>

```

Vamos declarar uma função para processar uma página por vez e chamá-la para as diversas páginas do site, cada chamada retorna um `tibble` com dados dos posts da página:


```r
# funcao que recebe a url da pagina e processa os posts
scrapBeerPage <- function(base.url) {

  # logging
  print(paste0("Scrapping: ", base.url))
  
  # faz o fetch da url e estrutura em um html doc (xml)
  html_doc <- read_html(base.url)
  
  # extração do nome da cerveja que está no título do post,
  # dentro do link para o próprio post
  html_doc %>% 
    html_nodes("div .post") %>%         # div que contem o post
    html_nodes("h2 a:first-child") %>%  # primeiro link do post em um H2
    html_text() %>%                     # pega o texto da tag
    str_replace("\u00A0"," ") %>%       # no nome há &nbsp; e &#8209;
    str_replace("\u2011","-") %>%       # removendo
    as.tibble() %>%                     # transforma em tibble
    rename(nome.completo=value) %>%     # nome completo
    mutate(
      # o nome está composto por "cervejaria - cerveja" criamos colunas 
      # separadas para o valores
      cervejaria = str_split(nome.completo, " . ", simplify = T)[,1],
      cerveja = str_split(nome.completo," . ", simplify = T)[,2]
    ) -> beers.name

  # mesmo CSS seletor do nome para capturar o link para a valiacao
  html_doc %>% 
    html_nodes("div .post") %>%
    html_nodes("h2 a:first-child") %>%
    html_attr("href") %>%               # busca o href dentro da <a ...
    as.tibble() %>%
    rename(link.avaliacao=value) -> beers.eval_link

  # captura o link para a imagem da cerveja
  # geralmente o primeiro <img...> dentro do post
  html_doc %>% 
    html_nodes(".main") %>% 
    map(function(x){
      html_node(x,"img") %>% 
        html_attr("src") %>%
        head(1)        
    }) %>%
    # a url está acompanhada de uma query string - limpando
    str_replace("\\?.*","") %>% 
    as.tibble() %>% 
    rename(image=value) -> beers.image
  
  # captura a avaliação: ela é um "texto corrido" dentre de um <p>,
  # que está dentro do div do post (main)
  # pode vir outros textos de outros p's 
  html_doc %>%
    html_nodes(".main p") %>%
    html_text() %>%
    # so me interessa o texto que contiver "País: "
    map( ~Filter(function(x) str_count(x,"País: ")>0,.) ) %>% 
    # cada atributo classificado está numa linha (/n)
    unlist() %>% str_split("\n") %>%
    # extrai os valores dos atributos que estão como pares "chave:valor"
    # por exemplo: País: Brasil /n Tipo: Lagger/m
    map(function(texts){
      str_replace(texts, ".+: ", "") %>%
        str_replace(.,"\\.+$","") %>%
        # somente nove atributos, há algumas "obs:" em alguns posts
        head(9) 
    }) %>%
    unlist() %>% as.vector() %>%
    matrix(ncol=9, byrow = T) %>%
    # convert em tibble e "re-seta" os nomes dos atributos
    as.tibble() %>% 
    setNames(c("pais","tipo","alcool",
               "cor","sabor","malte",
               "avaliacao","preco","volume")) -> beers.eval
  
  # captura o link para o site da cervejaria
  # geralmente dentre de um "<a...>" no último <p> do post
  html_doc %>%
    html_nodes(".main p:last-of-type") %>% 
    map(function(x){
      link <- html_nodes(x,"a:first-child")
    }) %>%
    # nem todo post tem link para a cervejaria
    # e alguns tem mais de um
    # então esse map volta NA quando não encontrar o link no post
    map(function(x){
      if (length(x)>0) { html_attr(x,"href") }
        else {return(NA)}
    }) %>% unlist() %>%
    as.tibble() %>% 
    rename(url=value) -> beers.url
  
  # captura a data de avalicao
  # Está no último "p" de uma "div" com class "signature"
  html_doc %>%
    html_nodes(".signature p:last-of-type") %>%
    html_text() %>%
    dmy_hm() %>%     # convert para data.hora
    as.tibble() %>%
    rename(data.avalicao=value) -> beers.eval_date
  
  # combina os dados extraídos em um único tibble
  bind_cols( beers.name, beers.eval, beers.eval_date,
             beers.eval_link, beers.url, beers.image) %>% return()

}
```

A função retorna um `tibble` com os dados dos posts de cada página, bastando então chamar a função repetidamente para todas as páginas do site (hoje, 203 páginas)


```r
# url base do blog e sequencia de paginas
base.url <- "https://cervanossa.wordpress.com/"
pages <- 1:203

# percorre as paginas fazendo o scrap
pages %>%                                    
  paste0(base.url, "page/", .) %>%
  map_df(possibly(scrapBeerPage,NULL)) -> raw_beers

# salva localmente para não precisar reprocessar toda hora
saveRDS(raw_beers,"./data/raw_beers.rds")

# quantas avaliacoes foram capturadas ?
dim(raw_beers)
```


```
## [1] 1193   16
```

Possivelmente nem todos os posts serão exatamente iguais, então pode ser que algum deles possa algum formato que impeça o processamento do site todo, gerando uma falha, para evitar a interrupção usamos o `purrr::possibly()`. Essa função permite evitar que uma falha no scrap de uma página pare o processo, em vez de falhar, volta-se um resultado nulo para aquela página, e que não será concatenado pelo `purrr::map_df`, e o processo continua para as demais.

O procedimento correto, seria olhar cada caso de falha e alterar a função de scrap para tratá-las, ou então "desviar" as páginas que falharam para rotinas que as tratam especificamente. Fiz isso para boa parte do site, mas não para ele todo neste post.

Feita a extração vamos apenas arrumar a tipagem das colunas (já que tudo veio como "char" do html) e salvar localmente o resultado.


```r
# ajustando as tipagens de algumas colunas
raw_beers %>%
  mutate(
    # corrigindo os tipos 'cervejaria', 'pais' e 'avalicao'
    cervejaria = as.factor(cervejaria), 
    pais = as.factor(pais),             
    avaliacao = as.integer(avaliacao),  
    # transformando o teor alcoólico de texto "6.5%" para num "0.065"
    alcool = as.numeric(str_replace(str_replace(alcool,"%",""),",","."))/100) %>%
  mutate(
    # criando uma estrutura de tipos e subtipos
    super.tipo = str_replace(tipo, " +\\(.+\\).*", ""),
    sub.tipo   = str_match(tipo, "\\(([^)]+)\\)")[,2]
  ) %>%
  # o autor sempre dá uma nota para a cerveja
  # se durante o casting houve um NA então o scrap nao tinha sido 
  # feito corretamente, retiramos esse registro
  filter( !is.na(alcool) ) -> beers

# salva base intermediaria de cervejas
saveRDS(beers,"./data/beers.rds")

dim(beers)
```

```
## [1] 1162   18
```

Aproveitamos e criamos duas informação derivadas de tipo: `super.tipo` e `sub.tipo`. O autor do blog sempre classifica as cervejas com base em uma hierarquia de dois níveis, colocando nível mais específico dentro de um parênteses. Vamos derivar essa estrutura extraindo e separando essas informações.


```r
# vendo uma parte dessa hierarquia
beers %>%
  select(tipo, super.tipo, sub.tipo) %>%
  head(10) %>%
  kable() %>% 
  kableExtra::kable_styling(font_size = 11)
```

<table class="table" style="font-size: 11px; margin-left: auto; margin-right: auto;">
 <thead>
  <tr>
   <th style="text-align:left;"> tipo </th>
   <th style="text-align:left;"> super.tipo </th>
   <th style="text-align:left;"> sub.tipo </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> Bock (Doppelbock) </td>
   <td style="text-align:left;"> Bock </td>
   <td style="text-align:left;"> Doppelbock </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Pale Lager (Munich Helles) </td>
   <td style="text-align:left;"> Pale Lager </td>
   <td style="text-align:left;"> Munich Helles </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Bock </td>
   <td style="text-align:left;"> Bock </td>
   <td style="text-align:left;"> NA </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Pale Ale (British Golden Ale) </td>
   <td style="text-align:left;"> Pale Ale </td>
   <td style="text-align:left;"> British Golden Ale </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Amber Ale (English India Pale Ale – IPA) </td>
   <td style="text-align:left;"> Amber Ale </td>
   <td style="text-align:left;"> English India Pale Ale – IPA </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Amber Ale (English Pale Ale / Strong Bitter) </td>
   <td style="text-align:left;"> Amber Ale </td>
   <td style="text-align:left;"> English Pale Ale / Strong Bitter </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Pilsen (German Pilsner) </td>
   <td style="text-align:left;"> Pilsen </td>
   <td style="text-align:left;"> German Pilsner </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Brown Ale (American Brown Ale) </td>
   <td style="text-align:left;"> Brown Ale </td>
   <td style="text-align:left;"> American Brown Ale </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Amber Ale (American Pale Ale) </td>
   <td style="text-align:left;"> Amber Ale </td>
   <td style="text-align:left;"> American Pale Ale </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Pale Ale (American Double India Pale Ale – IPA) </td>
   <td style="text-align:left;"> Pale Ale </td>
   <td style="text-align:left;"> American Double India Pale Ale – IPA </td>
  </tr>
</tbody>
</table>

Agora nós temos uma boa base de avaliações, com mais de mil cervejas avaliadas.


```r
# contando tipo, subtipos e supertipos
num_sprtp <- unique(beers$super.tipo) %>% length()
num_subtp <- unique(beers$sub.tipo) %>% length()
num_tipo  <- unique(beers$tipo) %>% length()

# overview do dataset
glimpse(beers)
```

```
## Rows: 1,162
## Columns: 18
## $ nome.completo  <chr> "Hohenthanner – St. Sixtus Doppelbock", "Fürst Wallerst~
## $ cervejaria     <fct> Hohenthanner, Fürst Wallerstein, Barba Roja, Otro Mundo~
## $ cerveja        <chr> "St. Sixtus Doppelbock", "Stammgast Lager", "Morena Boc~
## $ pais           <fct> "Alemanha", "Alemanha", "Argentina", "Argentina", "Arge~
## $ tipo           <chr> "Bock (Doppelbock)", "Pale Lager (Munich Helles)", "Boc~
## $ alcool         <dbl> 0.080, 0.050, 0.055, 0.055, 0.087, 0.065, 0.055, 0.055,~
## $ cor            <chr> "Marrom escuro e avermelhado", "Amarelo dourado", "Marr~
## $ sabor          <chr> "É intensa e encorpada, com amargor sutil e toque adoci~
## $ malte          <chr> "Cevada", "Cevada", "Cevada", "Cevada", "Cevada", "Ceva~
## $ avaliacao      <int> 9, 8, 8, 8, 8, 7, 8, 7, 8, 7, 8, 8, 8, 9, 8, 8, 9, 8, 7~
## $ preco          <chr> "R$ 23,00", "R$ 11,90", "ARS 109,00 (pesos argentinos)"~
## $ volume         <chr> "500 ml", "500 ml", "330 ml", "500 ml", "330 ml", "330 ~
## $ data.avalicao  <dttm> 2018-01-21 17:07:00, 2018-01-21 15:21:00, 2018-01-13 2~
## $ link.avaliacao <chr> "https://cervanossa.wordpress.com/2018/01/21/hohenthann~
## $ url            <chr> "http://www.hohenthanner.de", "http://www.fuerstwallers~
## $ image          <chr> "https://cervanossa.files.wordpress.com/2018/01/hohenth~
## $ super.tipo     <chr> "Bock", "Pale Lager", "Bock", "Pale Ale", "Amber Ale", ~
## $ sub.tipo       <chr> "Doppelbock", "Munich Helles", NA, "British Golden Ale"~
```

São 29 tipos de cervejas diferentes combinados com 231 sub.tipos, formando 357 combinações diferentes.


```r
# 10 tipos de cerveja mais avaliados 
beers %>%
  count(super.tipo, sub.tipo, sort=T) %>% 
  head(10) %>%
  kable() %>% 
  kableExtra::kable_styling(font_size = 11)
```

<table class="table" style="font-size: 11px; margin-left: auto; margin-right: auto;">
 <thead>
  <tr>
   <th style="text-align:left;"> super.tipo </th>
   <th style="text-align:left;"> sub.tipo </th>
   <th style="text-align:right;"> n </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> Pilsen </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> 50 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Pale Ale </td>
   <td style="text-align:left;"> Saison / Farmhouse Ale </td>
   <td style="text-align:right;"> 40 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Lager </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> 35 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Pale Ale </td>
   <td style="text-align:left;"> American India Pale Ale – IPA </td>
   <td style="text-align:right;"> 30 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Amber Ale </td>
   <td style="text-align:left;"> American Pale Ale </td>
   <td style="text-align:right;"> 27 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Ale </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> 25 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Amber Ale </td>
   <td style="text-align:left;"> American India Pale Ale – IPA </td>
   <td style="text-align:right;"> 24 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Pale Ale </td>
   <td style="text-align:left;"> American Pale Ale </td>
   <td style="text-align:right;"> 24 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Wheat Beer </td>
   <td style="text-align:left;"> Witbier </td>
   <td style="text-align:right;"> 23 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Pilsen </td>
   <td style="text-align:left;"> German Pilsener </td>
   <td style="text-align:right;"> 22 </td>
  </tr>
</tbody>
</table>

### Características dos Tipos de Cerveja

Com o data set de avaliações em mãos, agora é possível fazer uma analise comparativa entre os diversos tipos com base nas descrições usadas no texto de descrição de sabor, malte e cor das cervejas, usando técnicas de [text mining](https://en.wikipedia.org/wiki/Text_mining), ou, _mineração de textos_, em português.

O processo de _text mining_ geralmente envolve a contagem das palavras para encontrar similaridades e diferenças entre registros ou entidades. Usaremos essa técnica para tentar evidenciar a diferença entre os tipos de cerveja.


```r
# bibliotecas
library(tidytext) # pacote para tratamento de textos do tidyverse 
library(ptstem)   # pacote que faz o steming de termos em português
```

#### Steam & Stop Words

Antes de fazer a contagem das palavras e aplicar o TF-IDF é necessário fazer uma limpeza no texto das descrições, que envolve a remoção das palavras sem significado, as chamadas _stopwords_. Stop words[^2] são palavras que podem ser consideradas irrelevantes para o conjunto de resultados a ser exibido em uma busca realizada em uma search engine (de, da, para, em, etc.). E também é necessário fazer o _steming_, processo que elimina a flexão das palavras, por exemplo:


```r
# exemplo
palavras <- c("notas","aromáticas", "nota", "aromática", "sabores", "distintos",
              "sabor", "distinto", "frutas", "frutado")
ptstem(palavras)
```

```
##  [1] "notas"      "aromáticas" "notas"      "aromáticas" "sabores"   
##  [6] "distintos"  "sabores"    "distintos"  "frutas"     "frutas"
```

Esse processo equaliza as palavras facilitando a contagem


```r
# carrega stop words (do git https://gist.github.com/alopes/5358189)
pt_stopwords <- read_table("./data/stopwords.txt", col_names = "word")

# algumas stop words relevantes para esse problema (toque, algo, gosto, paladar)
# sao palavras que presentes nas descrições do sabor mas não agrega informação
my_stopwords <- read_table("./data/my_stopwords.txt", col_names = "word")

# combina as stop words
stopwords <- bind_rows(pt_stopwords, my_stopwords)

# removendo stop-words, stem e contando
beers %>%
  # Concatena os campos de texto Malte, Sabor e Cor
  mutate( review = paste0(malte, " ", sabor, " ", cor) ) %>%
  # Seleciona campoas de interesse para a analise
  select( tipo, super.tipo, sub.tipo, review ) %>%
  # separa as palavras do texto em vários registros
  unnest_tokens( word, review ) %>% 
  # remove as stopwords
  anti_join( stopwords ) %>% 
  # stem das palavras
  mutate( word = ptstem(word) ) %>%
  # contagem das palavars
  count( word, tipo, super.tipo ) -> beer_wordc

# salva base intermediaria
saveRDS(beer_wordc,"./data/beer_wordc.rds")

# breve formato do tibble
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

#### Term Frequency-Inverse Document Frequency

O que nós temos agora então é um mapa, para cada palavra a contagem de aparições nas descrição de sabor, cor e malte para cada tipo de cerveja. Mas nem todas as palavras tem o mesmo significado, algum delas aparecem em quase todas as descrições, o que a torna irrelevante para diferenciar uma cerveja da outra, para melhorar isso, atribuímos pesos diferentes às palavras através do _Term Frequency-Inverse Document Frequency_, ou [TF-IDF](https://en.wikipedia.org/wiki/Tf%E2%80%93idf) que é uma ponderação freqüentemente usada para identificar palavras-chave para recuperação de documentos pelos motores de busca e em sistemas de recomendação para sugerir itens similares. Ele procura termos que são freqüentes em um documento específico, mas raros em outros documentos, evidenciando palavras mais importantes na diferenciação das entidades.

A função `bind_tf_idf` do pacote `tidytext`calcula o TF_IDF ao passar um `tibble` contendo a contagem de um termo por linha e informando a coluna que contem o termo, o ID do agrupamento e a coluna que tem a contagem (n).

Vamos aplicar essa técnica para os tipos (super.tipos) de cerveja, para visualizar como é a diferença entre eles:


```r
# partindo da contagem
beer_wordc %>% 
  # agrupa a contagem no supertipo
  group_by(word, super.tipo) %>%
  summarise(n=sum(n)) %>%
  # calcula o total por palavra
  group_by(word) %>%
  mutate(word_total = sum(n)) %>%
  # calcula o TF_IDF
  bind_tf_idf(word, super.tipo, n)  %>%
  # remove quem obteve zero de score e ordena descrescente
  subset(tf_idf > 0) %>%
  arrange(desc(tf_idf)) -> tipo_tf_idf

# dando uma olhada no resultado
tipo_tf_idf %>%
  head(10) %>%
  kable() %>% 
  kableExtra::kable_styling(font_size = 11)
```

<table class="table" style="font-size: 11px; margin-left: auto; margin-right: auto;">
 <thead>
  <tr>
   <th style="text-align:left;"> word </th>
   <th style="text-align:left;"> super.tipo </th>
   <th style="text-align:right;"> n </th>
   <th style="text-align:right;"> word_total </th>
   <th style="text-align:right;"> tf </th>
   <th style="text-align:right;"> idf </th>
   <th style="text-align:right;"> tf_idf </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> amagor </td>
   <td style="text-align:left;"> Porter/Stout </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:right;"> 0.0625000 </td>
   <td style="text-align:right;"> 1.7578579 </td>
   <td style="text-align:right;"> 0.1098661 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> defumado </td>
   <td style="text-align:left;"> Rauchbier </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:right;"> 34 </td>
   <td style="text-align:right;"> 0.1176471 </td>
   <td style="text-align:right;"> 0.8823892 </td>
   <td style="text-align:right;"> 0.1038105 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> definido </td>
   <td style="text-align:left;"> Amber Lager / Hybrid </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 0.0270270 </td>
   <td style="text-align:right;"> 3.3672958 </td>
   <td style="text-align:right;"> 0.0910080 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> rústico </td>
   <td style="text-align:left;"> Amber Lager / Hybrid </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 0.0270270 </td>
   <td style="text-align:right;"> 3.3672958 </td>
   <td style="text-align:right;"> 0.0910080 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> tinto </td>
   <td style="text-align:left;"> Sour Ale </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:right;"> 0.0333333 </td>
   <td style="text-align:right;"> 2.6741486 </td>
   <td style="text-align:right;"> 0.0891383 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> entretanto </td>
   <td style="text-align:left;"> Brown Porter </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 0.0263158 </td>
   <td style="text-align:right;"> 3.3672958 </td>
   <td style="text-align:right;"> 0.0886130 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> estar </td>
   <td style="text-align:left;"> Brown Porter </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 0.0263158 </td>
   <td style="text-align:right;"> 3.3672958 </td>
   <td style="text-align:right;"> 0.0886130 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> necessário </td>
   <td style="text-align:left;"> Brown Porter </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 0.0263158 </td>
   <td style="text-align:right;"> 3.3672958 </td>
   <td style="text-align:right;"> 0.0886130 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> presentes </td>
   <td style="text-align:left;"> Brown Porter </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 0.0263158 </td>
   <td style="text-align:right;"> 3.3672958 </td>
   <td style="text-align:right;"> 0.0886130 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> preta </td>
   <td style="text-align:left;"> Porter/Stout </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 56 </td>
   <td style="text-align:right;"> 0.0625000 </td>
   <td style="text-align:right;"> 1.2878543 </td>
   <td style="text-align:right;"> 0.0804909 </td>
  </tr>
</tbody>
</table>


Vemos que o `bind_tf_idf` adicionou as estatísticas para o cálculo do TF_IDF, agora podemos visualizar como os tipos de cerveja se diferenciam nas descrições de sabor, ponderados por esse _score_.


```r
# vamos pegar os 16 "tipos" de cerveja mais frequentes
count(beers, super.tipo, sort=T) %>%
  top_n(16,n) %>%
  head(16) -> top_beer_types

# obter as estatíticas das principais palavras para cada um destes tipos
beer_type_top10_tf_idf <- tipo_tf_idf %>%  
  # obtem as palavras dos tipos selecionados cuja as 
  # descrições tem pelo menos 10 palavras
  subset(super.tipo %in% top_beer_types$super.tipo & word_total >= 10) %>% 
  # agrupa por tipo e obtem os 10 dez termos com melhor tf-idf
  group_by(super.tipo) %>%
  top_n(10, tf_idf) %>% 
  filter(row_number() <= 10) %>% 
  # ordena por tipo e score (desc)
  arrange(super.tipo, desc(tf_idf)) %>%
  ungroup() %>%
  # atribui um rank para cada palavra dentro do tipo (facilitar o plot) 
  mutate(Rank = rep(10:1, 16))

# overview 
beer_type_top10_tf_idf %>%
  head(10) %>%
  kable() %>% 
  kableExtra::kable_styling(font_size = 11)
```

<table class="table" style="font-size: 11px; margin-left: auto; margin-right: auto;">
 <thead>
  <tr>
   <th style="text-align:left;"> word </th>
   <th style="text-align:left;"> super.tipo </th>
   <th style="text-align:right;"> n </th>
   <th style="text-align:right;"> word_total </th>
   <th style="text-align:right;"> tf </th>
   <th style="text-align:right;"> idf </th>
   <th style="text-align:right;"> tf_idf </th>
   <th style="text-align:right;"> Rank </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> frutada </td>
   <td style="text-align:left;"> Abadia </td>
   <td style="text-align:right;"> 48 </td>
   <td style="text-align:right;"> 997 </td>
   <td style="text-align:right;"> 0.0770465 </td>
   <td style="text-align:right;"> 0.2318016 </td>
   <td style="text-align:right;"> 0.0178595 </td>
   <td style="text-align:right;"> 10 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> especiarias </td>
   <td style="text-align:left;"> Abadia </td>
   <td style="text-align:right;"> 10 </td>
   <td style="text-align:right;"> 224 </td>
   <td style="text-align:right;"> 0.0160514 </td>
   <td style="text-align:right;"> 0.8023465 </td>
   <td style="text-align:right;"> 0.0128788 </td>
   <td style="text-align:right;"> 9 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> encorpada </td>
   <td style="text-align:left;"> Abadia </td>
   <td style="text-align:right;"> 23 </td>
   <td style="text-align:right;"> 326 </td>
   <td style="text-align:right;"> 0.0369181 </td>
   <td style="text-align:right;"> 0.3227734 </td>
   <td style="text-align:right;"> 0.0119162 </td>
   <td style="text-align:right;"> 8 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> açúcar </td>
   <td style="text-align:left;"> Abadia </td>
   <td style="text-align:right;"> 14 </td>
   <td style="text-align:right;"> 165 </td>
   <td style="text-align:right;"> 0.0224719 </td>
   <td style="text-align:right;"> 0.4769241 </td>
   <td style="text-align:right;"> 0.0107174 </td>
   <td style="text-align:right;"> 7 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> quente </td>
   <td style="text-align:left;"> Abadia </td>
   <td style="text-align:right;"> 11 </td>
   <td style="text-align:right;"> 100 </td>
   <td style="text-align:right;"> 0.0176565 </td>
   <td style="text-align:right;"> 0.5947071 </td>
   <td style="text-align:right;"> 0.0105004 </td>
   <td style="text-align:right;"> 6 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> amarelo </td>
   <td style="text-align:left;"> Abadia </td>
   <td style="text-align:right;"> 10 </td>
   <td style="text-align:right;"> 616 </td>
   <td style="text-align:right;"> 0.0160514 </td>
   <td style="text-align:right;"> 0.5947071 </td>
   <td style="text-align:right;"> 0.0095459 </td>
   <td style="text-align:right;"> 5 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> dourado </td>
   <td style="text-align:left;"> Abadia </td>
   <td style="text-align:right;"> 8 </td>
   <td style="text-align:right;"> 359 </td>
   <td style="text-align:right;"> 0.0128411 </td>
   <td style="text-align:right;"> 0.7282385 </td>
   <td style="text-align:right;"> 0.0093514 </td>
   <td style="text-align:right;"> 4 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> amadeirado </td>
   <td style="text-align:left;"> Abadia </td>
   <td style="text-align:right;"> 15 </td>
   <td style="text-align:right;"> 233 </td>
   <td style="text-align:right;"> 0.0240770 </td>
   <td style="text-align:right;"> 0.3227734 </td>
   <td style="text-align:right;"> 0.0077714 </td>
   <td style="text-align:right;"> 3 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> cítrico </td>
   <td style="text-align:left;"> Abadia </td>
   <td style="text-align:right;"> 8 </td>
   <td style="text-align:right;"> 543 </td>
   <td style="text-align:right;"> 0.0128411 </td>
   <td style="text-align:right;"> 0.5947071 </td>
   <td style="text-align:right;"> 0.0076367 </td>
   <td style="text-align:right;"> 2 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> álcool </td>
   <td style="text-align:left;"> Abadia </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:right;"> 170 </td>
   <td style="text-align:right;"> 0.0096308 </td>
   <td style="text-align:right;"> 0.7282385 </td>
   <td style="text-align:right;"> 0.0070135 </td>
   <td style="text-align:right;"> 1 </td>
  </tr>
</tbody>
</table>

#### Termos chaves para os tipos de cervejas.

Para cada tipo temos as 10 mais importantes palavras, vamos visualizar a diferença entre os grupos.



```r
# plotando as principais palavras
ggplot(beer_type_top10_tf_idf, aes(x=as.factor(Rank), y=tf_idf)) +  
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

<img src="/posts/2018-02-03-data-science-das-cervejas-1-2/index.pt-br_files/figure-html/plotSuperType-1.png" width="960" />

### Conclusão

Podemos perceber que via _text mining_ conseguimos isolar os termos mais característicos para cada tipo de cerveja. No próximo post vamos explorar as diferenças e semelhanças entre os diversos tipos e explorar a capacidade de fazer sugestões de cerveja de acordo com a características desejadas.


[^1]: R Package para _Stemming_ em Português  - https://cran.r-project.org/web/packages/ptstem/vignettes/ptstem.html

[^2]: _stop words_ para português  - https://gist.github.com/alopes/5358189

[^3]: Beer Text Mining with Tidytext - http://kaylinwalker.com/tidy-text-beer/

[^4]: Tutoriais de **rvest**
 - https://stat4701.github.io/edav/2015/04/02/rvest_tutorial/
 - https://www.analyticsvidhya.com/blog/2017/03/beginners-guide-on-web-scraping-in-r-using-rvest-with-hands-on-knowledge/
 
[^5]: CSS Selectors - https://www.w3schools.com/cssref/css_selectors.asp

[^6]: Tidy Text Mining Beer Review - http://kaylinwalker.com/tidy-text-beer/
