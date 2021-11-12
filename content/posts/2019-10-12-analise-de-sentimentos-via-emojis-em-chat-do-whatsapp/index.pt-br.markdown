---
title: "Análise de Sentimentos via Emojis em chat do WhatsApp"
author: "Giuliano Sposito"
date: '2019-10-12'
slug: analise-de-sentimentos-via-emojis-em-chat-do-whatsapp
categories:
- data science
tags:
- rstats
- data analysis
- whatsapp
- tidytext
- rvest
- emoji
subtitle: ''
lastmod: '2021-11-08T18:13:23-03:00'
authorLink: ''
description: ''
hiddenFromHomePage: no
hiddenFromSearch: no
featuredImage: images/emoji_whatsapp_header.jpg
featuredImagePreview: images/emoji_whatsapp_header.jpg
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
<script src="/rmarkdown-libs/kePrint/kePrint.js"></script>
<link href="/rmarkdown-libs/lightable/lightable.css" rel="stylesheet" />
<script src="/rmarkdown-libs/kePrint/kePrint.js"></script>
<link href="/rmarkdown-libs/lightable/lightable.css" rel="stylesheet" />

O pacote rwhatsapp, desenvolvido e disponibilizado por Johannes Grubber, permite manipular diretamente os arquivos TXT (e ZIP) de uma conversão exportada pelo aplicativo WhatsApp, importando os dados para um data.frame e disponibilizando-os para análise de maneira simples e direta. Ao esbarrar com esse pacote no Twitter decidi explorar uma conversão de um dos meus grupos  e fazer uma análise de sentimentos através dos Emoji's enviados pelos membros do grupo, confira como ficou...  

<!--more-->




<!--
{{< admonition type=warning title="Emoji Enconding" open=true >}}
Estou tendo problemas de encoding dos [caracteres unicode dos emojis](https://unicode.org/emoji/charts/full-emoji-list.html) com esse [novo template](https://hugoloveit.com/) que trata eles de maneira diferente, então eles não estão aparecendo (caracter branco) ou estão parecendo "escapados" (tipo: <U+0000>). O [post original](https://yetanotheriteration.netlify.app/2019/10/an%C3%A1lise-de-sentimentos-via-emojis-em-chat-do-whatsapp/) (no template antigo) está funcionando, sendo melhor acompanhar por lá enquanto eu não resolvo aqui.
{{< /admonition >}}
--> 

### Introdução

O pacote [`rwhatsapp`](https://cran.r-project.org/web/packages/rwhatsapp/index.html), desenvolvido e disponibilizado por [Johannes Grubber](https://github.com/JBGruber), permite manipular diretamente os arquivos `TXT` (e `ZIP`) de uma conversão exportada pelo aplicativo [`WhatsApp`](https://www.whatsapp.com/), importando os dados para um `data.frame` e disponibilizando-os para análise de maneira simples e direta. Ao esbarrar com esse pacote no [`Twitter`](https://twitter.com/JohannesBGruber/status/1176415368820264960) decidi explorar uma conversão de um dos meus grupos de [`WhatsApp`](https://www.whatsapp.com/) e fazer uma análise de sentimentos através dos [Emoji's](https://home.unicode.org/emoji/) enviados pelos remetentes. 


{{< tweet 1176415368820264960 >}}


### Obtendo os dados

A principal (e única) função no pacote, é a `rwa_read()`, que permite importar os arquivos `TXT` (e `ZIP`) diretamente, o que significa que você pode simplesmente fornecer o caminho para um arquivo para carregar as mensagens direto num `data.frame`. Exportar uma conversa de `WhatsApp` também é bem direto, basta [seguir as instruções](https://tecnoblog.net/194147/whatsapp-salvar-historico-conversa/) disponíveis. Para este post, vou utilizar a conversão de um grupo meu de uma liga de [Fantasy](http://fantasy.nfl.com), assim poderemos fazer uma comparação do volume de mensagens enviadas com respeito aos horários e eventos relacionados aos jogos da [NFL](https://www.nfl.com).

Aliás, essa minha [*Liga de Fantasy*](https://dudesfootball.netlify.com), já foi tema de outro post neste blog, que envolvia fazer [simulações de Montecarlo para prever resultados dos jogos](/2018-10-28-forecasting-fantasy-games-using-monte-carlo-simulations/), e claro, também usando [`R`](https://www.r-project.org/).



```r
# libs to explore the WhatsApp chat
library(rwhatsapp)
library(tidyverse)
library(lubridate)
library(tidytext)
library(kableExtra)
library(RColorBrewer)
library(knitr)

# importing data
chat <- rwa_read("./data/nfl_dudes.zip")

# checking the datatable format
chat %>% 
  head(8) %>%
  kable(escape = F) %>% 
  kable_styling(font_size = 11) 
```

<table class="table" style="font-size: 11px; margin-left: auto; margin-right: auto;">
 <thead>
  <tr>
   <th style="text-align:left;"> time </th>
   <th style="text-align:left;"> author </th>
   <th style="text-align:left;"> text </th>
   <th style="text-align:left;"> source </th>
   <th style="text-align:right;"> id </th>
   <th style="text-align:left;"> emoji </th>
   <th style="text-align:left;"> emoji_name </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> 2019-03-20 22:04:40 </td>
   <td style="text-align:left;"> NFL </td>
   <td style="text-align:left;"> It's Football, dudes: &lt;U+200E&gt;As mensagens deste grupo estão protegidas com a criptografia de ponta a ponta. </td>
   <td style="text-align:left;"> ./data/nfl_dudes.zip </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:left;"> NULL </td>
   <td style="text-align:left;"> NULL </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2019-03-21 12:39:07 </td>
   <td style="text-align:left;"> Leandro </td>
   <td style="text-align:left;"> &lt;U+200E&gt;imagem ocultada </td>
   <td style="text-align:left;"> ./data/nfl_dudes.zip </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> NULL </td>
   <td style="text-align:left;"> NULL </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2019-03-21 12:39:42 </td>
   <td style="text-align:left;"> Marcos </td>
   <td style="text-align:left;"> Quem fez merda agora? rs </td>
   <td style="text-align:left;"> ./data/nfl_dudes.zip </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> NULL </td>
   <td style="text-align:left;"> NULL </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2019-03-21 12:40:35 </td>
   <td style="text-align:left;"> Leonel </td>
   <td style="text-align:left;"> T Hill </td>
   <td style="text-align:left;"> ./data/nfl_dudes.zip </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> NULL </td>
   <td style="text-align:left;"> NULL </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2019-03-21 12:40:41 </td>
   <td style="text-align:left;"> Marcos </td>
   <td style="text-align:left;"> &lt;U+0001F926&gt;&lt;U+0001F3FB&gt;&lt;U+200D&gt;&lt;U+2642&gt;&lt;U+0001F926&gt;&lt;U+0001F3FB&gt;&lt;U+200D&gt;&lt;U+2642&gt;&lt;U+0001F926&gt;&lt;U+0001F3FB&gt;&lt;U+200D&gt;&lt;U+2642&gt; </td>
   <td style="text-align:left;"> ./data/nfl_dudes.zip </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> &lt;U+0001F926&gt;&lt;U+0001F3FB&gt;&lt;U+200D&gt;&lt;U+2642&gt;, &lt;U+0001F926&gt;&lt;U+0001F3FB&gt;&lt;U+200D&gt;&lt;U+2642&gt;, &lt;U+0001F926&gt;&lt;U+0001F3FB&gt;&lt;U+200D&gt;&lt;U+2642&gt; </td>
   <td style="text-align:left;"> man facepalming: light skin tone, man facepalming: light skin tone, man facepalming: light skin tone </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2019-03-21 12:40:47 </td>
   <td style="text-align:left;"> Leandro </td>
   <td style="text-align:left;"> &lt;U+0001F605&gt; </td>
   <td style="text-align:left;"> ./data/nfl_dudes.zip </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> &lt;U+0001F605&gt; </td>
   <td style="text-align:left;"> grinning face with sweat </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2019-03-21 12:47:42 </td>
   <td style="text-align:left;"> Giuliano </td>
   <td style="text-align:left;"> Mas agora, como o time sabe (e perderam para os Giselos sem o Hunt) não vai perder jogador. </td>
   <td style="text-align:left;"> ./data/nfl_dudes.zip </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:left;"> NULL </td>
   <td style="text-align:left;"> NULL </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2019-03-21 17:56:38 </td>
   <td style="text-align:left;"> Hilton </td>
   <td style="text-align:left;"> &lt;U+200E&gt;imagem ocultada </td>
   <td style="text-align:left;"> ./data/nfl_dudes.zip </td>
   <td style="text-align:right;"> 8 </td>
   <td style="text-align:left;"> NULL </td>
   <td style="text-align:left;"> NULL </td>
  </tr>
</tbody>
</table>

Como você pode ver a importação é bem rápida e direta, e devolve as mensagens como linhas num `data.frame`, contendo informações de *timestamp*, quem é o contato remetente, a mensagem enviada e a "*fonte de dados*" (arquivo importado). Além disso, de forma destacada da mensagem e aninhado ([*nested*](https://blog.rstudio.com/2016/02/02/tidyr-0-4-0/)) à linha, temos informações sobre os [Emoji's](https://home.unicode.org/emoji/) que estão presentes em cada mensagem enviada, tanto o caracter [Unicode](https://home.unicode.org/) como o nome do `Emoji`.





### Avaliando Frequência das Mensagens

A análise inicial, e também a mais direta e simples,  que pode ser feita nesses dados é de frequência, podemos visualizar o volume diário de mensagens, que horas e dias das semana são mais utilizados no grupo, bem como quem é o membro do grupo mais comunicativo.

#### Mensagens enviadas no período

Para deixar a informação mais rica, podemos comparar os volumes de envio no tempo com as etapas do campeonato de NFL, que é inclusive caracterizada por uma longa intertemporda. Então vamos criar uma informação de *fase*, que diz em que etapa do campeonato pertence aquela mensagem, podemos fazer isso simplesmente segregando o *timestamp* nas seguintes datas:

- [NFL Draft](https://www.nfl.com/draft/home):  entre 25/abr à 27/abr
- Pré Temporada: entre 01/ago à 29/ago
- Draft da Liga: 02/set 
- Temporada: a partir de 05/set
- Intertemporada: datas anteriores a 01/ago



```r
# main dates
# draft:        25.APR – 27.APR
# preseason:    01.AUG - 29.AUG
# league draft: 02.SEP
# season:       > 05.SEP
# off season:   everthing else

# prepare data for time/date analysis
chat <- chat %>% 
  mutate(day = date(time)) %>% 
  mutate(
    # phase classification
    phase = case_when(
      day >= dmy(25042019) & day <= dmy(27042019) ~ "nfl draft",
      day >= dmy(01082019) & day <= dmy(29082019) ~ "preseason",
      day >= dmy(30082019) & day <= dmy(04092019) ~ "league draft",
      day >= dmy(05092019) ~ "season",
      T ~ "off season"
    )
  ) %>% 
  mutate( phase = factor(phase) ) %>% 
  filter(!is.na(author))

# my color palette
my.phase.palette <- brewer.pal(5,"Set1")[c(5,1,3,4,2)]

# Cheking how much messages was sent along the period
chat %>% 
  group_by(phase) %>% 
  count(day) %>%
  ggplot(aes(x = day, y = n, fill=phase)) +
  geom_bar(stat = "identity") +
  scale_fill_manual(values=my.phase.palette) +
  ylab("messages") + xlab("date") +
  ggtitle("Messages per day", "It's Football, Dudes! WhatsApp Chat Group") +
  theme_minimal() +
  theme( legend.title = element_blank(), 
         legend.position = "bottom")
```

<img src="/posts/2019-10-12-analise-de-sentimentos-via-emojis-em-chat-do-whatsapp/index.pt-br_files/figure-html/dataHandling-1.png" width="960" />

Como é previsível, o grupo é bem silencioso na intertemporada (*off season*), com picos durante o [draft da NFL](https://www.nfl.com/draft/home) bem como no fim de semana e entorno do *draft* da própria liga. O volume de mensagens começa a crescer na pré-temporada (*preseason*) com o início dos jogos de treinamento transmitidos pela TV e então o chat passa a engrenar quando começa a temporada (*season*).

#### Mensagens por dia da semana

Os jogos da NFL são quase todos concentrados no domingo e mais dois jogos em horário nobre às quintas e segundas, isso deveria refletir no volume de mensagens enviadas por dia de semana.


```r
# mensagens por dia da semana
chat %>% 
  mutate( wday.num = wday(day),
          wday.name = weekdays(day)) %>% 
  group_by(phase, wday.num, wday.name) %>% 
  count() %>% 
  ggplot(aes(x = reorder(wday.name, -wday.num), y = n, fill=phase)) +
  geom_bar(stat = "identity") +
  scale_fill_manual(values=my.phase.palette) +
  ylab("") + xlab("") +
  coord_flip() +
  ggtitle("Number of messages for weekday", "It's Football, Dudes! WhatsApp Chat Group") +
  theme_minimal() +
  theme( legend.title = element_blank(), 
         legend.position = "bottom")
```

<img src="/posts/2019-10-12-analise-de-sentimentos-via-emojis-em-chat-do-whatsapp/index.pt-br_files/figure-html/messagensPerWeekDay-1.png" width="672" />

Domingo confessa a concentração de jogos, volume de mensagens de temporada (*season*), mas é interessante reparar que os volumes de segunda e de terça-feira também são altos, sendo até mais altos que de quinta-feira, dia de jogo. Isso ocorrer devido a dinâmica do *Fantasy*, já que terça-feira é dia de oficialização do resultado da rodada e também preparação para a troca de jogadores ([*waiver*](https://www.espn.com/fantasy/football/ffl/story?page=fflruleswaiverwalk)), e no nosso caso, a liberação das projeções computadas dos jogadores no [site da liga](https://dudesfootball.netlify.com/categories/projection/).

#### Mensagens por hora

Os jogos ocorrem basicamente na tarde do domingo e também nos horários nobres de domingo, segunda e quinta, vamos observar como é o comportamento de envio de mensagens ao longo das horas.



```r
# usado como truque para nomear os facets e manter a ordem dos dias de semana
wday.values <- c("domingo","segunda-feira","terça-feira","quarta-feira","quinta-feira","sexta-feira","sábado","domingo")
names(wday.values) <- 1:7

# mensagens por hora do dia
chat %>% 
  mutate( hour = hour(time), 
          wday.num = wday(day),
          wday.name = weekdays(day)) %>% 
  count(phase, wday.num, wday.name, hour) %>% 
  ggplot(aes(x = hour, y = n, fill=phase)) +
  geom_bar(stat = "identity") +
  scale_fill_manual(values=my.phase.palette) +
  ylab("") + xlab("") +
  ggtitle("Number of messages by Hour and Weekday", "It's Football, Dudes! WhatsApp Chat Group") +
  facet_wrap(~wday.num, ncol=7, labeller = labeller(wday.num=wday.values))+
  theme_minimal() +
  theme( legend.title = element_blank(), 
         legend.position = "bottom",
         panel.spacing.x=unit(0.0, "lines"))
```

<img src="/posts/2019-10-12-analise-de-sentimentos-via-emojis-em-chat-do-whatsapp/index.pt-br_files/figure-html/messageByHour-1.png" width="960" />

Podemos observar claramente que a frequência de envio de mensagens são mais altas nos horários das partidas, durante a temporada (*season*), e com terça-feira, sendo um pouco mais distribuído enquanto o grupo comenta resultados da rodada e preparação para escalação e contratação de novos jogadores.

#### Membro mais comunicativo

E claro, podemos ver quem é o usuário, membro do grupo, que mais envia mensagens.


```r
# mensagem por remetente 
chat %>%
  mutate(day = date(time)) %>%
  group_by(phase) %>% 
  count(author) %>%
  ggplot(aes(x = reorder(author, n), y = n, fill=phase)) +
  geom_bar(stat = "identity") +
  scale_fill_manual(values=my.phase.palette) +
  ylab("") + xlab("") +
  coord_flip() +
  ggtitle("Number of messages", "It's Football, Dudes! WhatsApp Chat Group") +
  theme_minimal() +
  theme( legend.title = element_blank(), 
         legend.position = "bottom")
```

<img src="/posts/2019-10-12-analise-de-sentimentos-via-emojis-em-chat-do-whatsapp/index.pt-br_files/figure-html/messagesByAuthor-1.png" width="672" />

### Emoji's

Emojis são símbolos gráficos [Unicode](https://home.unicode.org/), usados como uma abreviação para expressar conceitos e idéias, existem centenas de emojis. Como o `rwhatsapp` importa separadamente a informação sobre Emoji's, podemos explorar a sua popularidade nas trocas de mensagem do grupo.



```r
# lets see the nested emoji structure
chat %>% 
  select(time, author, emoji, emoji_name) %>% 
  unnest(emoji, emoji_name) %>% 
  slice(1:10) %>% 
  kable(escape=T)
```

<table>
 <thead>
  <tr>
   <th style="text-align:left;"> time </th>
   <th style="text-align:left;"> author </th>
   <th style="text-align:left;"> emoji </th>
   <th style="text-align:left;"> emoji_name </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> 2019-03-21 12:40:41 </td>
   <td style="text-align:left;"> Marcos </td>
   <td style="text-align:left;"> &lt;U+0001F926&gt;&lt;U+0001F3FB&gt;&lt;U+200D&gt;&lt;U+2642&gt; </td>
   <td style="text-align:left;"> man facepalming: light skin tone </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2019-03-21 12:40:41 </td>
   <td style="text-align:left;"> Marcos </td>
   <td style="text-align:left;"> &lt;U+0001F926&gt;&lt;U+0001F3FB&gt;&lt;U+200D&gt;&lt;U+2642&gt; </td>
   <td style="text-align:left;"> man facepalming: light skin tone </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2019-03-21 12:40:41 </td>
   <td style="text-align:left;"> Marcos </td>
   <td style="text-align:left;"> &lt;U+0001F926&gt;&lt;U+0001F3FB&gt;&lt;U+200D&gt;&lt;U+2642&gt; </td>
   <td style="text-align:left;"> man facepalming: light skin tone </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2019-03-21 12:40:47 </td>
   <td style="text-align:left;"> Leandro </td>
   <td style="text-align:left;"> &lt;U+0001F605&gt; </td>
   <td style="text-align:left;"> grinning face with sweat </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2019-03-21 18:36:34 </td>
   <td style="text-align:left;"> Marcos </td>
   <td style="text-align:left;"> &lt;U+0001F602&gt; </td>
   <td style="text-align:left;"> face with tears of joy </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2019-03-21 18:36:34 </td>
   <td style="text-align:left;"> Marcos </td>
   <td style="text-align:left;"> &lt;U+0001F602&gt; </td>
   <td style="text-align:left;"> face with tears of joy </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2019-03-21 18:36:34 </td>
   <td style="text-align:left;"> Marcos </td>
   <td style="text-align:left;"> &lt;U+0001F602&gt; </td>
   <td style="text-align:left;"> face with tears of joy </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2019-03-23 07:32:21 </td>
   <td style="text-align:left;"> Leonel </td>
   <td style="text-align:left;"> &lt;U+0001F923&gt; </td>
   <td style="text-align:left;"> rolling on the floor laughing </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2019-03-24 19:03:52 </td>
   <td style="text-align:left;"> Marcos </td>
   <td style="text-align:left;"> &lt;U+0001F631&gt; </td>
   <td style="text-align:left;"> face screaming in fear </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2019-03-24 19:05:34 </td>
   <td style="text-align:left;"> Leonel </td>
   <td style="text-align:left;"> &lt;U+0001F47F&gt; </td>
   <td style="text-align:left;"> angry face with horns </td>
  </tr>
</tbody>
</table>

#### EMOJI mais usado

Antes de *rankear* os `Emijis`, vamos remover as usas variações. As variações é quando se altera, por exemplo, cor da pele ou do cabelo do `Emiji's`, essas variações são codificadas através da composição de vários caracteres [Unicode](https://home.unicode.org/), o primeiro para dizer qual é o `Emoji` e so segundo para implementar uma variação. Quando o computador ou o celular lê esses caracteres faz uma composição e exibe como somente um. Esse processo é chamado de ["ligadura" (*ligatures*)](https://en.wikipedia.org/wiki/Orthographic_ligature), e tem algumas [implicações interessantes](https://codepen.io/tuxsudo/pen/EwqKjy).

Então, antes de rankear, vamos manter somente o primeiro caracter [Unicode](https://home.unicode.org/) do Emoji, removendo todo o resto.



```r
# use to fecth a PNG image of a Emoji from https://abs.twimg.com
library(ggimage)

### emoji ranking
plot.data <- chat %>% 
  unnest(emoji, emoji_name) %>% 
  mutate( emoji = str_sub(emoji, end = 1)) %>% # remove ligatures
  mutate( emoji_name = str_remove(emoji_name, ":.*")) %>% # remove ligatures names
  count(emoji, emoji_name) %>% 
  # plot top 20 emoji
  top_n(20, n) %>% 
  arrange(desc(n)) %>% 
  # builds a image URL with the Unicode value of the Emoji
  mutate( emoji_url = map_chr(emoji, 
    ~paste0( "https://abs.twimg.com/emoji/v2/72x72/", as.hexmode(utf8ToInt(.x)),".png")) 
  )


# plot the ranking
plot.data %>% 
  ggplot(aes(x=reorder(emoji_name, n), y=n)) +
  geom_col(aes(fill=n), show.legend = FALSE, width = .2) +
  geom_point(aes(color=n), show.legend = FALSE, size = 3) +
  geom_image(aes(image=emoji_url), size=.045) +
  scale_fill_gradient(low="#2b83ba",high="#d7191c") +
  scale_color_gradient(low="#2b83ba",high="#d7191c") +
  ylab("") +
  xlab("") +
  ggtitle("Most often used emojis", "It's Football, Dudes! WhatsApp Chat Group") +
  coord_flip() +
  theme_minimal() +
  theme()
```

<img src="/posts/2019-10-12-analise-de-sentimentos-via-emojis-em-chat-do-whatsapp/index.pt-br_files/figure-html/emojiRanking-1.png" width="864" />

A mesma análise pode ser feita, por remetente do grupo, mostrando qual é o `Emoji` preferido ou mais utilizado por cada um.



```r
# emoji rank by author
plot.data <- chat %>%
  unnest(emoji, emoji_name) %>%
  mutate( emoji = str_sub(emoji, end = 1)) %>% # remove nuancias
  count(author, emoji, emoji_name, sort = TRUE) %>%
  # plot top 6 emoji from each author
  group_by(author) %>%
  top_n(n = 6, n) %>%
  slice(1:6) %>% 
  # builds a image URL with the Unicode value of the Emoji
  mutate( emoji_url = map_chr(emoji, 
    ~paste0("https://abs.twimg.com/emoji/v2/72x72/",as.hexmode(utf8ToInt(.x)),".png")) )

# plot data
plot.data %>% 
  ggplot(aes(x = reorder(emoji, -n), y = n)) +
  geom_col(aes(fill = author, group=author), show.legend = FALSE, width = .20) +
  # use to fecth a PNG image of a Emoji from https://abs.twimg.com
  geom_image(aes(image=emoji_url), size=.13) +
  ylab("") +
  xlab("") +
  facet_wrap(~author, ncol = 5, scales = "free")  +
  ggtitle("Most often used emojis") +
  theme_minimal() +
  theme(axis.text.x = element_blank())
```

<img src="/posts/2019-10-12-analise-de-sentimentos-via-emojis-em-chat-do-whatsapp/index.pt-br_files/figure-html/emojiByAuthors-1.png" width="672" />

### Análise de Palavras

Assim como fizemos com os `Emoji´s`, podemos fazar a análise de frequência das palavras mais utilizadas no grupo bem como é para cada um dos membros. O pacote `tidytext` deixa essa análise bem simples e direta de aplicar.

#### Ranking de Palavras


```r
library(tidytext)
library(stopwords)

# words without significance, we remove them from analysis
words_to_remove <- c(stopwords(language = "pt"),
               "http", "imagem", "gif", "ocultada","omitida", "e", "pra", "vou", "ta", "https",
               "é","pro","to", "vai", "nao", "and", "omitido", "cara","lá", "q", "né",
               "ta", "tá", "ja", "p", "tbm", "agora", "vc", "tô", "acho", "aí", "ai",
               "tipo", "tava", "hj", "ver", 0:20, "figurinha", "tudo", "ainda","ser",
               "bem","ter", "fazer","faz","pq", "bom","pode","nada", "aqui", "hoje", "vi", "fez")

# tokenize and count the words
chat %>%
  unnest_tokens(input = text, output = word) %>%
  filter(!word %in% words_to_remove) %>% 
  count(word) %>% 
  # plot top 20 words
  top_n(20,n) %>% 
  arrange(desc(n)) %>% 
  ggplot(aes(x=reorder(word,n), y=n, fill=n, color=n)) +
  geom_col(show.legend = FALSE, width = .1) +
  geom_point(show.legend = FALSE, size = 3) +
  scale_fill_gradient(low="#2b83ba",high="#d7191c") +
  scale_color_gradient(low="#2b83ba",high="#d7191c") +
  ggtitle("Most often words") +
  xlab("words") +
  coord_flip() +
  theme_minimal()
```

<img src="/posts/2019-10-12-analise-de-sentimentos-via-emojis-em-chat-do-whatsapp/index.pt-br_files/figure-html/wordFrequence-1.png" width="672" />



#### Rank de palavras por membro do grupo


```r
# tokinize and group count by author
chat %>%
  unnest_tokens(input = text,
                output = word) %>%
  filter(!word %in% words_to_remove) %>%
  count(author, word, sort = TRUE) %>%
  # top 10 words from each member
  group_by(author) %>%
  top_n(n = 10, n) %>%
  slice(1:10) %>%
  ungroup() %>% 
  arrange(author, desc(n)) %>% 
  mutate(order=row_number()) %>% 
  ggplot(aes(x = reorder(word, n), y = n, fill = author, color = author)) +
  geom_col(show.legend = FALSE, width = .1) +
  geom_point(show.legend = FALSE, size = 3) +
  ylab("") +
  xlab("") +
  coord_flip() +
  facet_wrap(~author, ncol = 3, scales = "free") +
  ggtitle("Most often used words") +
  theme_minimal()
```

<img src="/posts/2019-10-12-analise-de-sentimentos-via-emojis-em-chat-do-whatsapp/index.pt-br_files/figure-html/wordsByAuthor-1.png" width="672" />

### Análise de Sentimentos

Como a conversa vem de um grupo de uma liga de *Fantasy*, seria interessante analisar as mensagens do ponto de vista emocional. Como as pessoas reagem de acordo com a sua performance no jogo ou para os times que torcem? Iremos fazer isso de duas maneiras, a primeira é utilizando o [Emoji Sentimental Rank](https://www.clarin.si/repository/xmlui/handle/11356/1048) e o outro, também com base nos Emojis, usaremos o seus "nomes" para cruzar com bases léxicas de classificação de palavras, para avaliar os sentimentos e intensidades envolvidas.

#### Emoji Sentiment Rank

Kralj Novak P, Smailović J, Sluban B, Mozetič forneceram o primeiro léxico de sentimentos emoji, chamado de [Ranking de sentimentos Emoji](http://kt.ijs.si/data/Emoji_sentiment_ranking/index.html) que mapeia os sentimentos dos 751 emojis mais usados. O sentimento dos emojis é calculado a partir do sentimento de 70 mil tweets nos quais eles ocorrem, e foram rotulados por 83 anotadores humanos em 13 idiomas europeus. O processo e a análise da classificação de sentimentos emoji são descritos no artigo [Sentiment of Emojis](https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0144296), de 2015.

Usaremos o pacote `rvest` para *scrapear* diretamente o [rank](http://kt.ijs.si/data/Emoji_sentiment_ranking/index.html), e transformá-lo num `data.frame` para incorporar na nossa análise.


```r
library(rvest)

# fecht the html page
base.url <- "http://kt.ijs.si/data/Emoji_sentiment_ranking/index.html"
doc <- read_html(base.url)

# find the emoji table and process
emoji.table <- doc %>% 
  html_node("#myTable") %>% 
  html_table() %>% 
  as_tibble()

# lets look the result
emoji.table %>% 
  head(10) %>% 
  kable(escape=T) %>% 
  kable_styling(font_size = 9)
```

<table class="table" style="font-size: 9px; margin-left: auto; margin-right: auto;">
 <thead>
  <tr>
   <th style="text-align:left;"> Char </th>
   <th style="text-align:left;"> Image[twemoji] </th>
   <th style="text-align:right;"> Unicodecodepoint </th>
   <th style="text-align:right;"> Occurrences[5...max] </th>
   <th style="text-align:right;"> Position[0...1] </th>
   <th style="text-align:right;"> Neg[0...1] </th>
   <th style="text-align:right;"> Neut[0...1] </th>
   <th style="text-align:right;"> Pos[0...1] </th>
   <th style="text-align:right;"> Sentiment score[-1...+1] </th>
   <th style="text-align:left;"> Sentiment bar(c.i. 95%) </th>
   <th style="text-align:left;"> Unicode name </th>
   <th style="text-align:left;"> Unicode block </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> &lt;U+0001F602&gt; </td>
   <td style="text-align:left;"> &lt;U+0001F602&gt; </td>
   <td style="text-align:right;"> 128514 </td>
   <td style="text-align:right;"> 14622 </td>
   <td style="text-align:right;"> 0.805 </td>
   <td style="text-align:right;"> 0.247 </td>
   <td style="text-align:right;"> 0.285 </td>
   <td style="text-align:right;"> 0.468 </td>
   <td style="text-align:right;"> 0.221 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> FACE WITH TEARS OF JOY </td>
   <td style="text-align:left;"> Emoticons </td>
  </tr>
  <tr>
   <td style="text-align:left;"> &lt;U+2764&gt; </td>
   <td style="text-align:left;"> &lt;U+2764&gt; </td>
   <td style="text-align:right;"> 10084 </td>
   <td style="text-align:right;"> 8050 </td>
   <td style="text-align:right;"> 0.747 </td>
   <td style="text-align:right;"> 0.044 </td>
   <td style="text-align:right;"> 0.166 </td>
   <td style="text-align:right;"> 0.790 </td>
   <td style="text-align:right;"> 0.746 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> HEAVY BLACK HEART </td>
   <td style="text-align:left;"> Dingbats </td>
  </tr>
  <tr>
   <td style="text-align:left;"> &lt;U+2665&gt; </td>
   <td style="text-align:left;"> &lt;U+2665&gt; </td>
   <td style="text-align:right;"> 9829 </td>
   <td style="text-align:right;"> 7144 </td>
   <td style="text-align:right;"> 0.754 </td>
   <td style="text-align:right;"> 0.035 </td>
   <td style="text-align:right;"> 0.272 </td>
   <td style="text-align:right;"> 0.693 </td>
   <td style="text-align:right;"> 0.657 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> BLACK HEART SUIT </td>
   <td style="text-align:left;"> Miscellaneous Symbols </td>
  </tr>
  <tr>
   <td style="text-align:left;"> &lt;U+0001F60D&gt; </td>
   <td style="text-align:left;"> &lt;U+0001F60D&gt; </td>
   <td style="text-align:right;"> 128525 </td>
   <td style="text-align:right;"> 6359 </td>
   <td style="text-align:right;"> 0.765 </td>
   <td style="text-align:right;"> 0.052 </td>
   <td style="text-align:right;"> 0.219 </td>
   <td style="text-align:right;"> 0.729 </td>
   <td style="text-align:right;"> 0.678 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> SMILING FACE WITH HEART-SHAPED EYES </td>
   <td style="text-align:left;"> Emoticons </td>
  </tr>
  <tr>
   <td style="text-align:left;"> &lt;U+0001F62D&gt; </td>
   <td style="text-align:left;"> &lt;U+0001F62D&gt; </td>
   <td style="text-align:right;"> 128557 </td>
   <td style="text-align:right;"> 5526 </td>
   <td style="text-align:right;"> 0.803 </td>
   <td style="text-align:right;"> 0.436 </td>
   <td style="text-align:right;"> 0.220 </td>
   <td style="text-align:right;"> 0.343 </td>
   <td style="text-align:right;"> -0.093 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> LOUDLY CRYING FACE </td>
   <td style="text-align:left;"> Emoticons </td>
  </tr>
  <tr>
   <td style="text-align:left;"> &lt;U+0001F618&gt; </td>
   <td style="text-align:left;"> &lt;U+0001F618&gt; </td>
   <td style="text-align:right;"> 128536 </td>
   <td style="text-align:right;"> 3648 </td>
   <td style="text-align:right;"> 0.854 </td>
   <td style="text-align:right;"> 0.053 </td>
   <td style="text-align:right;"> 0.193 </td>
   <td style="text-align:right;"> 0.754 </td>
   <td style="text-align:right;"> 0.701 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> FACE THROWING A KISS </td>
   <td style="text-align:left;"> Emoticons </td>
  </tr>
  <tr>
   <td style="text-align:left;"> &lt;U+0001F60A&gt; </td>
   <td style="text-align:left;"> &lt;U+0001F60A&gt; </td>
   <td style="text-align:right;"> 128522 </td>
   <td style="text-align:right;"> 3186 </td>
   <td style="text-align:right;"> 0.813 </td>
   <td style="text-align:right;"> 0.060 </td>
   <td style="text-align:right;"> 0.237 </td>
   <td style="text-align:right;"> 0.704 </td>
   <td style="text-align:right;"> 0.644 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> SMILING FACE WITH SMILING EYES </td>
   <td style="text-align:left;"> Emoticons </td>
  </tr>
  <tr>
   <td style="text-align:left;"> &lt;U+0001F44C&gt; </td>
   <td style="text-align:left;"> &lt;U+0001F44C&gt; </td>
   <td style="text-align:right;"> 128076 </td>
   <td style="text-align:right;"> 2925 </td>
   <td style="text-align:right;"> 0.805 </td>
   <td style="text-align:right;"> 0.094 </td>
   <td style="text-align:right;"> 0.249 </td>
   <td style="text-align:right;"> 0.657 </td>
   <td style="text-align:right;"> 0.563 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> OK HAND SIGN </td>
   <td style="text-align:left;"> Miscellaneous Symbols and Pictographs </td>
  </tr>
  <tr>
   <td style="text-align:left;"> &lt;U+0001F495&gt; </td>
   <td style="text-align:left;"> &lt;U+0001F495&gt; </td>
   <td style="text-align:right;"> 128149 </td>
   <td style="text-align:right;"> 2400 </td>
   <td style="text-align:right;"> 0.766 </td>
   <td style="text-align:right;"> 0.042 </td>
   <td style="text-align:right;"> 0.285 </td>
   <td style="text-align:right;"> 0.674 </td>
   <td style="text-align:right;"> 0.632 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> TWO HEARTS </td>
   <td style="text-align:left;"> Miscellaneous Symbols and Pictographs </td>
  </tr>
  <tr>
   <td style="text-align:left;"> &lt;U+0001F44F&gt; </td>
   <td style="text-align:left;"> &lt;U+0001F44F&gt; </td>
   <td style="text-align:right;"> 128079 </td>
   <td style="text-align:right;"> 2336 </td>
   <td style="text-align:right;"> 0.787 </td>
   <td style="text-align:right;"> 0.104 </td>
   <td style="text-align:right;"> 0.271 </td>
   <td style="text-align:right;"> 0.624 </td>
   <td style="text-align:right;"> 0.520 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> CLAPPING HANDS SIGN </td>
   <td style="text-align:left;"> Miscellaneous Symbols and Pictographs </td>
  </tr>
</tbody>
</table>

O *rank* tem colunas que pontuam cada `Emoji` com respeito a representar um sentimento positivo, neutro ou negativo, numa escala de três dimensões. Então podemos juntá-lo aos `Emoji` das mensagens, classificando assim indiretamente os sentimentos da mensagem.



```r
# geting sentiment score and cleaning emoji.table colnames
emoji.sentiment <- emoji.table %>% 
  select(1,6:9) %>% 
  set_names("char", "negative","neutral","positive","sent.score")


# extract emoji and join with sentiment 
emoji.chat <- chat %>% 
  unnest(emoji, emoji_name) %>% 
  mutate( emoji = str_sub(emoji, end = 1)) %>% # remove ligatures
  inner_join(emoji.sentiment, by=c("emoji"="char")) 

# visualizing 
emoji.chat %>% 
  select(-source, -day, -phase) %>% 
  slice(1207:1219) %>% 
  kable(escape=T) %>% 
  kable_styling(font_size = 10)
```

<table class="table" style="font-size: 10px; margin-left: auto; margin-right: auto;">
 <thead>
  <tr>
   <th style="text-align:left;"> time </th>
   <th style="text-align:left;"> author </th>
   <th style="text-align:left;"> text </th>
   <th style="text-align:right;"> id </th>
   <th style="text-align:left;"> emoji </th>
   <th style="text-align:left;"> emoji_name </th>
   <th style="text-align:right;"> negative </th>
   <th style="text-align:right;"> neutral </th>
   <th style="text-align:right;"> positive </th>
   <th style="text-align:right;"> sent.score </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> 2019-09-16 21:54:45 </td>
   <td style="text-align:left;"> Marcos </td>
   <td style="text-align:left;"> &lt;U+0001F602&gt;&lt;U+0001F602&gt;&lt;U+0001F602&gt;&lt;U+0001F602&gt;&lt;U+0001F602&gt; </td>
   <td style="text-align:right;"> 4728 </td>
   <td style="text-align:left;"> &lt;U+0001F602&gt; </td>
   <td style="text-align:left;"> face with tears of joy </td>
   <td style="text-align:right;"> 0.247 </td>
   <td style="text-align:right;"> 0.285 </td>
   <td style="text-align:right;"> 0.468 </td>
   <td style="text-align:right;"> 0.221 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2019-09-16 23:14:23 </td>
   <td style="text-align:left;"> Leonel </td>
   <td style="text-align:left;"> Dolphins vai ter o primeiro e o segundo pick do Draft &lt;U+0001F605&gt; </td>
   <td style="text-align:right;"> 4766 </td>
   <td style="text-align:left;"> &lt;U+0001F605&gt; </td>
   <td style="text-align:left;"> grinning face with sweat </td>
   <td style="text-align:right;"> 0.292 </td>
   <td style="text-align:right;"> 0.237 </td>
   <td style="text-align:right;"> 0.471 </td>
   <td style="text-align:right;"> 0.178 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2019-09-17 08:20:31 </td>
   <td style="text-align:left;"> Roander </td>
   <td style="text-align:left;"> Se tiver mal é só pegar o FH pra dar um up na tabela &lt;U+0001F61C&gt; </td>
   <td style="text-align:right;"> 4773 </td>
   <td style="text-align:left;"> &lt;U+0001F61C&gt; </td>
   <td style="text-align:left;"> winking face with tongue </td>
   <td style="text-align:right;"> 0.112 </td>
   <td style="text-align:right;"> 0.322 </td>
   <td style="text-align:right;"> 0.566 </td>
   <td style="text-align:right;"> 0.455 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2019-09-17 13:43:09 </td>
   <td style="text-align:left;"> Leandro </td>
   <td style="text-align:left;"> &lt;U+0001F605&gt; </td>
   <td style="text-align:right;"> 4804 </td>
   <td style="text-align:left;"> &lt;U+0001F605&gt; </td>
   <td style="text-align:left;"> grinning face with sweat </td>
   <td style="text-align:right;"> 0.292 </td>
   <td style="text-align:right;"> 0.237 </td>
   <td style="text-align:right;"> 0.471 </td>
   <td style="text-align:right;"> 0.178 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2019-09-17 13:46:08 </td>
   <td style="text-align:left;"> Leandro </td>
   <td style="text-align:left;"> &lt;U+0001F60E&gt; </td>
   <td style="text-align:right;"> 4812 </td>
   <td style="text-align:left;"> &lt;U+0001F60E&gt; </td>
   <td style="text-align:left;"> smiling face with sunglasses </td>
   <td style="text-align:right;"> 0.106 </td>
   <td style="text-align:right;"> 0.297 </td>
   <td style="text-align:right;"> 0.597 </td>
   <td style="text-align:right;"> 0.491 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2019-09-17 13:53:30 </td>
   <td style="text-align:left;"> Leonel </td>
   <td style="text-align:left;"> Cara, tava torcendo tanto para ele fazer 20 pontos.. pq eu ganharia por .5 &lt;U+0001F605&gt; </td>
   <td style="text-align:right;"> 4815 </td>
   <td style="text-align:left;"> &lt;U+0001F605&gt; </td>
   <td style="text-align:left;"> grinning face with sweat </td>
   <td style="text-align:right;"> 0.292 </td>
   <td style="text-align:right;"> 0.237 </td>
   <td style="text-align:right;"> 0.471 </td>
   <td style="text-align:right;"> 0.178 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2019-09-17 13:58:53 </td>
   <td style="text-align:left;"> Leandro </td>
   <td style="text-align:left;"> &lt;U+0001F605&gt; </td>
   <td style="text-align:right;"> 4819 </td>
   <td style="text-align:left;"> &lt;U+0001F605&gt; </td>
   <td style="text-align:left;"> grinning face with sweat </td>
   <td style="text-align:right;"> 0.292 </td>
   <td style="text-align:right;"> 0.237 </td>
   <td style="text-align:right;"> 0.471 </td>
   <td style="text-align:right;"> 0.178 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2019-09-17 13:59:34 </td>
   <td style="text-align:left;"> Leandro </td>
   <td style="text-align:left;"> &lt;U+0001F605&gt; </td>
   <td style="text-align:right;"> 4823 </td>
   <td style="text-align:left;"> &lt;U+0001F605&gt; </td>
   <td style="text-align:left;"> grinning face with sweat </td>
   <td style="text-align:right;"> 0.292 </td>
   <td style="text-align:right;"> 0.237 </td>
   <td style="text-align:right;"> 0.471 </td>
   <td style="text-align:right;"> 0.178 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2019-09-17 14:05:01 </td>
   <td style="text-align:left;"> Leandro </td>
   <td style="text-align:left;"> Quem acha q o Kaepernick pode voltar levanta a mão? &lt;U+0001F60E&gt; &lt;U+0001F44D&gt;&lt;U+0001F3FB&gt; </td>
   <td style="text-align:right;"> 4824 </td>
   <td style="text-align:left;"> &lt;U+0001F60E&gt; </td>
   <td style="text-align:left;"> smiling face with sunglasses </td>
   <td style="text-align:right;"> 0.106 </td>
   <td style="text-align:right;"> 0.297 </td>
   <td style="text-align:right;"> 0.597 </td>
   <td style="text-align:right;"> 0.491 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2019-09-17 14:05:01 </td>
   <td style="text-align:left;"> Leandro </td>
   <td style="text-align:left;"> Quem acha q o Kaepernick pode voltar levanta a mão? &lt;U+0001F60E&gt; &lt;U+0001F44D&gt;&lt;U+0001F3FB&gt; </td>
   <td style="text-align:right;"> 4824 </td>
   <td style="text-align:left;"> &lt;U+0001F44D&gt; </td>
   <td style="text-align:left;"> thumbs up: light skin tone </td>
   <td style="text-align:right;"> 0.115 </td>
   <td style="text-align:right;"> 0.248 </td>
   <td style="text-align:right;"> 0.637 </td>
   <td style="text-align:right;"> 0.521 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2019-09-17 14:05:14 </td>
   <td style="text-align:left;"> Hilton </td>
   <td style="text-align:left;"> &lt;U+261D&gt;&lt;U+0001F3FB&gt; </td>
   <td style="text-align:right;"> 4825 </td>
   <td style="text-align:left;"> &lt;U+261D&gt; </td>
   <td style="text-align:left;"> index pointing up: light skin tone </td>
   <td style="text-align:right;"> 0.144 </td>
   <td style="text-align:right;"> 0.402 </td>
   <td style="text-align:right;"> 0.454 </td>
   <td style="text-align:right;"> 0.309 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2019-09-17 14:05:54 </td>
   <td style="text-align:left;"> Marcos </td>
   <td style="text-align:left;"> &lt;U+0001F44E&gt;&lt;U+0001F3FB&gt; </td>
   <td style="text-align:right;"> 4826 </td>
   <td style="text-align:left;"> &lt;U+0001F44E&gt; </td>
   <td style="text-align:left;"> thumbs down: light skin tone </td>
   <td style="text-align:right;"> 0.494 </td>
   <td style="text-align:right;"> 0.199 </td>
   <td style="text-align:right;"> 0.307 </td>
   <td style="text-align:right;"> -0.188 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2019-09-17 14:07:35 </td>
   <td style="text-align:left;"> Hilton </td>
   <td style="text-align:left;"> Eu tentei ajudá-lo, mas ele não captou minha oferta, acho que pq estamos na mesma divisão &lt;U+0001F60E&gt; </td>
   <td style="text-align:right;"> 4828 </td>
   <td style="text-align:left;"> &lt;U+0001F60E&gt; </td>
   <td style="text-align:left;"> smiling face with sunglasses </td>
   <td style="text-align:right;"> 0.106 </td>
   <td style="text-align:right;"> 0.297 </td>
   <td style="text-align:right;"> 0.597 </td>
   <td style="text-align:right;"> 0.491 </td>
  </tr>
</tbody>
</table>


Resta então contabilizar qual o sentimento médio de cada remetente na lista.



```r
# summarising emoji sentiment ocorrences by author
emoji.authors.sentiment <- emoji.chat %>% 
  group_by(author) %>% 
  summarise(
    positive=mean(positive),
    negative=mean(negative),
    neutral=mean(neutral),
    balance=mean(sent.score)
  ) %>% 
  arrange(desc(balance))

# formating the data to plot as divergent stacked bar
emoji.authors.sentiment %>% 
  mutate( negative  = -negative,
          neutral.p =  neutral/2,
          neutral.n = -neutral/2) %>% 
  select(-neutral) %>% 
  gather("sentiment","mean", -author, -balance) %>% 
  mutate(sentiment = factor(sentiment, levels = c("negative", "neutral.n", "positive", "neutral.p"), ordered = T)) %>% 
  ggplot(aes(x=reorder(author,balance), y=mean, fill=sentiment)) +
  geom_bar(position="stack", stat="identity", show.legend = F, width = .5) +
  scale_fill_manual(values = brewer.pal(4,"RdYlGn")[c(1,2,4,2)]) +
  ylab("negativo/positivo") + xlab("") +
  ggtitle("Análise de Sentimentos","Baseado na média do score de sentimentos dos Emojis") +
  coord_flip() +
  theme_minimal() 
```

<img src="/posts/2019-10-12-analise-de-sentimentos-via-emojis-em-chat-do-whatsapp/index.pt-br_files/figure-html/emojiSentimentByAuthor-1.png" width="672" />

A imagem acima, mostra a sequencia de membros do grupo ordenados pela "positividade" dos `Emoji's` enviado nas mensagens (os mais positivos, acima). Interessante notar que os dois últimos membros (Hilton e Vinícius) são donos (*owners*) dos times *Sorocaba Wilds Mules* e *Rio Claro Pfeiferias*, respectivamente, os dois últimos na [classificação atual da liga](https://dudesfootball.netlify.com/post/rank-week-5/). O que podeira explicar a maior proporção de `Emoji's` negativos.

![Ranking da Liga após 5 rodadas](images/dudesLeagueStanding.png)

#### Derivando o sentimento via nome do Emoji

Uma abordagem alternativa ao `Emoji Ranking` é usar um lexicon (dicionário) com a classificação de sentimentos das palavras, e fazer a associação do sentimento com o nome do `Emoji`, que convenientemente foi disponibilizado logo na importação da conversa via `rwhatsapp`.

O [léxico AFINN](https://github.com/fnielsen/afinn/tree/master/afinn/data) é talvez um dos lexicons mais simples e populares e é usado extensivamente para análise de sentimentos. A versão atual do léxico é a `AFINN-en-165.txt` e contém mais de 3.300 palavras com uma pontuação de polaridade associada a cada palavra. Você pode encontrar esse léxico no [repositório oficial do GitHub](https://github.com/fnielsen/afinn/tree/master/afinn/data) do autor, nós vamos usar o pacote [`textdata`](https://cran.r-project.org/web/packages/textdata/index.html), que já faz o download do léxico. Vamos dar uma olhada no seu conteúdo.


```r
library(textdata)

# get some positive/negative lexicon by textdata package
lex.negpos  <- get_sentiments("afinn") # value intense

# lets look the lexicon format
lex.negpos %>% 
  head(10) %>% 
  kable(escape=T) %>%
  kable_styling(full_width = F, font_size = 11)
```

<table class="table" style="font-size: 11px; width: auto !important; margin-left: auto; margin-right: auto;">
 <thead>
  <tr>
   <th style="text-align:left;"> word </th>
   <th style="text-align:right;"> value </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> abandon </td>
   <td style="text-align:right;"> -2 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> abandoned </td>
   <td style="text-align:right;"> -2 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> abandons </td>
   <td style="text-align:right;"> -2 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> abducted </td>
   <td style="text-align:right;"> -2 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> abduction </td>
   <td style="text-align:right;"> -2 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> abductions </td>
   <td style="text-align:right;"> -2 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> abhor </td>
   <td style="text-align:right;"> -3 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> abhorred </td>
   <td style="text-align:right;"> -3 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> abhorrent </td>
   <td style="text-align:right;"> -3 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> abhors </td>
   <td style="text-align:right;"> -3 </td>
  </tr>
</tbody>
</table>

```r
# what are the possible values?
table(lex.negpos$value) %>% 
  kable(escape=T) %>%
  kable_styling(full_width = F, font_size = 11) 
```

<table class="table" style="font-size: 11px; width: auto !important; margin-left: auto; margin-right: auto;">
 <thead>
  <tr>
   <th style="text-align:left;"> Var1 </th>
   <th style="text-align:right;"> Freq </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> -5 </td>
   <td style="text-align:right;"> 16 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> -4 </td>
   <td style="text-align:right;"> 43 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> -3 </td>
   <td style="text-align:right;"> 264 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> -2 </td>
   <td style="text-align:right;"> 966 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> -1 </td>
   <td style="text-align:right;"> 309 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 0 </td>
   <td style="text-align:right;"> 1 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:right;"> 208 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:right;"> 448 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:right;"> 172 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 4 </td>
   <td style="text-align:right;"> 45 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 5 </td>
   <td style="text-align:right;"> 5 </td>
  </tr>
</tbody>
</table>

Como a descrição antecipa, as palavras são pontuadas, e aparentemente numa escala entre -5 e 5, com (quase) nenhuma palavra com 0 pontos. Vamos olhar como o cruzamento entre os dois.


```r
# extract emojis
emoji.sent.score <- chat %>%
  select( emoji, emoji_name) %>% 
  unnest( emoji, emoji_name) %>% 
  mutate( emoji = str_sub(emoji, end = 1)) %>%  # remove ligatures
  mutate( emoji_name = str_remove(emoji_name, ":.*")) %>%  # remove ligatures names
  distinct() %>% 
  unnest_tokens(input=emoji_name, output=emoji_words) %>% 
  inner_join(lex.negpos, by=c("emoji_words"="word"))

# make a table with 3 columns
bind_cols(
  slice(emoji.sent.score, 01:10),
  slice(emoji.sent.score, 11:20),
  slice(emoji.sent.score, 21:30)
) %>% 
  kable(escape=T) %>% 
  kable_styling(full_width = F, font_size = 11) 
```

<table class="table" style="font-size: 11px; width: auto !important; margin-left: auto; margin-right: auto;">
 <thead>
  <tr>
   <th style="text-align:left;"> emoji...1 </th>
   <th style="text-align:left;"> emoji_words...2 </th>
   <th style="text-align:right;"> value...3 </th>
   <th style="text-align:left;"> emoji...4 </th>
   <th style="text-align:left;"> emoji_words...5 </th>
   <th style="text-align:right;"> value...6 </th>
   <th style="text-align:left;"> emoji...7 </th>
   <th style="text-align:left;"> emoji_words...8 </th>
   <th style="text-align:right;"> value...9 </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> &lt;U+0001F602&gt; </td>
   <td style="text-align:left;"> tears </td>
   <td style="text-align:right;"> -2 </td>
   <td style="text-align:left;"> &lt;U+0001F608&gt; </td>
   <td style="text-align:left;"> smiling </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> &lt;U+0001F929&gt; </td>
   <td style="text-align:left;"> struck </td>
   <td style="text-align:right;"> -1 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> &lt;U+0001F602&gt; </td>
   <td style="text-align:left;"> joy </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> &lt;U+0001F525&gt; </td>
   <td style="text-align:left;"> fire </td>
   <td style="text-align:right;"> -2 </td>
   <td style="text-align:left;"> &lt;U+0001F628&gt; </td>
   <td style="text-align:left;"> fearful </td>
   <td style="text-align:right;"> -2 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> &lt;U+0001F923&gt; </td>
   <td style="text-align:left;"> laughing </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:left;"> &lt;U+0001F614&gt; </td>
   <td style="text-align:left;"> pensive </td>
   <td style="text-align:right;"> -1 </td>
   <td style="text-align:left;"> &lt;U+0001F61F&gt; </td>
   <td style="text-align:left;"> worried </td>
   <td style="text-align:right;"> -3 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> &lt;U+0001F631&gt; </td>
   <td style="text-align:left;"> screaming </td>
   <td style="text-align:right;"> -2 </td>
   <td style="text-align:left;"> &lt;U+0001F91F&gt; </td>
   <td style="text-align:left;"> love </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> &lt;U+0001F494&gt; </td>
   <td style="text-align:left;"> broken </td>
   <td style="text-align:right;"> -1 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> &lt;U+0001F631&gt; </td>
   <td style="text-align:left;"> fear </td>
   <td style="text-align:right;"> -2 </td>
   <td style="text-align:left;"> &lt;U+0001F613&gt; </td>
   <td style="text-align:left;"> downcast </td>
   <td style="text-align:right;"> -2 </td>
   <td style="text-align:left;"> &lt;U+0001F618&gt; </td>
   <td style="text-align:left;"> kiss </td>
   <td style="text-align:right;"> 2 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> &lt;U+0001F47F&gt; </td>
   <td style="text-align:left;"> angry </td>
   <td style="text-align:right;"> -3 </td>
   <td style="text-align:left;"> &lt;U+0001F60D&gt; </td>
   <td style="text-align:left;"> smiling </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> &lt;U+0001F642&gt; </td>
   <td style="text-align:left;"> smiling </td>
   <td style="text-align:right;"> 2 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> &lt;U+0001F604&gt; </td>
   <td style="text-align:left;"> smiling </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> &lt;U+0001F60A&gt; </td>
   <td style="text-align:left;"> smiling </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> &lt;U+0001F641&gt; </td>
   <td style="text-align:left;"> frowning </td>
   <td style="text-align:right;"> -1 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> &lt;U+0001F601&gt; </td>
   <td style="text-align:left;"> smiling </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> &lt;U+0001F60A&gt; </td>
   <td style="text-align:left;"> smiling </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> &lt;U+0001F607&gt; </td>
   <td style="text-align:left;"> smiling </td>
   <td style="text-align:right;"> 2 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> &lt;U+0001F62D&gt; </td>
   <td style="text-align:left;"> crying </td>
   <td style="text-align:right;"> -2 </td>
   <td style="text-align:left;"> &lt;U+0001F61E&gt; </td>
   <td style="text-align:left;"> disappointed </td>
   <td style="text-align:right;"> -2 </td>
   <td style="text-align:left;"> &lt;U+0001F626&gt; </td>
   <td style="text-align:left;"> frowning </td>
   <td style="text-align:right;"> -1 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> &lt;U+0001F60E&gt; </td>
   <td style="text-align:left;"> smiling </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> &lt;U+0001F970&gt; </td>
   <td style="text-align:left;"> smiling </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> &lt;U+0001F627&gt; </td>
   <td style="text-align:left;"> anguished </td>
   <td style="text-align:right;"> -3 </td>
  </tr>
</tbody>
</table>


Repedindo o mesmo procedimento que fizemos antes com os `Emoji's` vamos olha a média de intensidade da escala de sentimento para cada um dos membros do grupo.


```r
# extract emojis
emoji.chat <- chat %>% 
  unnest(emoji, emoji_name) %>% 
  mutate( emoji = str_sub(emoji, end = 1)) %>%  # remove ligatures
  mutate( emoji_name = str_remove(emoji_name, ":.*")) # remove ligatures names

# tokenize the emoji name
emoji.chat <- emoji.chat %>% 
  select(author, emoji_name) %>% 
  unnest_tokens(input=emoji_name, output=emoji_words)

# join the lexicon
author.summary <- emoji.chat %>% 
  inner_join(lex.negpos, by=c("emoji_words"="word")) %>% 
  count(author, value) %>% 
  group_by(author) %>% 
  mutate(mean=n/sum(n)) %>% 
  ungroup()

# trick to plot colors and bar as divergent stacked bar
reordLevels <- c(-3,-2,-1,3,2,1)
colors <- c("#d7191c","#fdae61","#ffffbf","#1a9641","#a6d96a","#ffffbf")
my.colors <- brewer.pal(5,"RdYlGn")[c(1,2,3,5,4,3)]

# the plot
author.summary %>% 
  mutate( mean = ifelse(value<0, -mean, mean)) %>% 
  group_by(author) %>% 
  mutate( balance = sum(mean)) %>% 
  ungroup() %>% 
  mutate( value = factor(value, levels = reordLevels, ordered=T)) %>% 
  ggplot(aes(x=reorder(author,balance), y=mean, fill=value)) +
  geom_bar(stat="identity",position="stack", show.legend = F, width = .5) +
  scale_fill_manual(values = my.colors) +
  xlab("") +
  coord_flip() +
  ggtitle("Sentiment Analysis", "By emoji's name") +
  theme_minimal()
```

<img src="/posts/2019-10-12-analise-de-sentimentos-via-emojis-em-chat-do-whatsapp/index.pt-br_files/figure-html/authorEmojiNameSentiment-1.png" width="672" />

Nos extremos, o resultado parece ser o mesmo porém há algumas diferenças, mas lembre-se, não estamos classificando o sentimento pelo `Emoji` em si, mas sim pelo sentimento da palavra que dá o seu nome.

<!-- emoji_ads_03 -->
<ins class="adsbygoogle"
     style="display:block"
     data-ad-client="ca-pub-5624634479725935"
     data-ad-slot="6261576274"
     data-ad-format="auto"
     data-full-width-responsive="true"></ins>
<script>
     (adsbygoogle = window.adsbygoogle || []).push({});
</script>

#### Sentimento mais frequente

Uma terceira abordagem, também explorando o nome do `Emoji`, é cruzá-lo com uma base de sentimentos, um Léxico que vincule palavras a sentimentos. O [NRC Emotion Lexicon](https://saifmohammad.com/WebPages/NRC-Emotion-Lexicon.htm) (também conhecido como EmoLex) é uma lista de palavras em inglês e suas associações com oito emoções básicas (raiva, medo, antecipação, confiança, surpresa, tristeza, alegria e nojo) e dois sentimentos (negativos e positivos). As anotações foram feitas manualmente por *crowdsourcing*.


```r
# getting another lexicon with sentiment names
lex.sent <- get_sentiments("nrc") # sentiment name

# let's see
lex.sent %>% 
  head(10) %>% 
  kable(escape=T) %>%
  kable_styling(full_width = F, font_size = 11) 
```

<table class="table" style="font-size: 11px; width: auto !important; margin-left: auto; margin-right: auto;">
 <thead>
  <tr>
   <th style="text-align:left;"> word </th>
   <th style="text-align:left;"> sentiment </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> abacus </td>
   <td style="text-align:left;"> trust </td>
  </tr>
  <tr>
   <td style="text-align:left;"> abandon </td>
   <td style="text-align:left;"> fear </td>
  </tr>
  <tr>
   <td style="text-align:left;"> abandon </td>
   <td style="text-align:left;"> negative </td>
  </tr>
  <tr>
   <td style="text-align:left;"> abandon </td>
   <td style="text-align:left;"> sadness </td>
  </tr>
  <tr>
   <td style="text-align:left;"> abandoned </td>
   <td style="text-align:left;"> anger </td>
  </tr>
  <tr>
   <td style="text-align:left;"> abandoned </td>
   <td style="text-align:left;"> fear </td>
  </tr>
  <tr>
   <td style="text-align:left;"> abandoned </td>
   <td style="text-align:left;"> negative </td>
  </tr>
  <tr>
   <td style="text-align:left;"> abandoned </td>
   <td style="text-align:left;"> sadness </td>
  </tr>
  <tr>
   <td style="text-align:left;"> abandonment </td>
   <td style="text-align:left;"> anger </td>
  </tr>
  <tr>
   <td style="text-align:left;"> abandonment </td>
   <td style="text-align:left;"> fear </td>
  </tr>
</tbody>
</table>

Vamos dar uma olhada em como ficam algumas das classificações de sentimentos para os `Emoji's`.


```r
# extract emojis
emoji.emotion <- chat %>%
  select( emoji, emoji_name) %>% 
  unnest( emoji, emoji_name) %>% 
  mutate( emoji = str_sub(emoji, end = 1)) %>%  # remove ligatures
  mutate( emoji_name = str_remove(emoji_name, ":.*")) %>%  # remove ligatures names
  unnest_tokens(input=emoji_name, output=emoji_words) %>% 
  inner_join(lex.sent, by=c("emoji_words"="word")) %>% 
  filter(!sentiment %in% c("negative","positive")) %>% # removing neg/pos classification
  # keep only the top 4 most frequent emoji for each sentiment
  count(emoji, emoji_words, sentiment) %>% 
  group_by(sentiment) %>% 
  top_n(4,n) %>% 
  slice(1:4) %>% 
  ungroup() %>% 
  select(-n)

# trick to put tables side-by-side
bind_cols(
    slice(emoji.emotion, 01:16),
    slice(emoji.emotion, 17:32)
  ) %>% 
  kable(escape=T) %>% 
  kable_styling(full_width = F, font_size = 11) 
```

<table class="table" style="font-size: 11px; width: auto !important; margin-left: auto; margin-right: auto;">
 <thead>
  <tr>
   <th style="text-align:left;"> emoji...1 </th>
   <th style="text-align:left;"> emoji_words...2 </th>
   <th style="text-align:left;"> sentiment...3 </th>
   <th style="text-align:left;"> emoji...4 </th>
   <th style="text-align:left;"> emoji_words...5 </th>
   <th style="text-align:left;"> sentiment...6 </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> &lt;U+0001F61E&gt; </td>
   <td style="text-align:left;"> disappointed </td>
   <td style="text-align:left;"> anger </td>
   <td style="text-align:left;"> &lt;U+0001F601&gt; </td>
   <td style="text-align:left;"> beaming </td>
   <td style="text-align:left;"> joy </td>
  </tr>
  <tr>
   <td style="text-align:left;"> &lt;U+0001F631&gt; </td>
   <td style="text-align:left;"> fear </td>
   <td style="text-align:left;"> anger </td>
   <td style="text-align:left;"> &lt;U+0001F601&gt; </td>
   <td style="text-align:left;"> smiling </td>
   <td style="text-align:left;"> joy </td>
  </tr>
  <tr>
   <td style="text-align:left;"> &lt;U+0001F631&gt; </td>
   <td style="text-align:left;"> screaming </td>
   <td style="text-align:left;"> anger </td>
   <td style="text-align:left;"> &lt;U+0001F602&gt; </td>
   <td style="text-align:left;"> joy </td>
   <td style="text-align:left;"> joy </td>
  </tr>
  <tr>
   <td style="text-align:left;"> &lt;U+0001F641&gt; </td>
   <td style="text-align:left;"> frowning </td>
   <td style="text-align:left;"> anger </td>
   <td style="text-align:left;"> &lt;U+0001F60E&gt; </td>
   <td style="text-align:left;"> smiling </td>
   <td style="text-align:left;"> joy </td>
  </tr>
  <tr>
   <td style="text-align:left;"> &lt;U+0001F3C8&gt; </td>
   <td style="text-align:left;"> football </td>
   <td style="text-align:left;"> anticipation </td>
   <td style="text-align:left;"> &lt;U+0001F614&gt; </td>
   <td style="text-align:left;"> pensive </td>
   <td style="text-align:left;"> sadness </td>
  </tr>
  <tr>
   <td style="text-align:left;"> &lt;U+0001F601&gt; </td>
   <td style="text-align:left;"> beaming </td>
   <td style="text-align:left;"> anticipation </td>
   <td style="text-align:left;"> &lt;U+0001F61E&gt; </td>
   <td style="text-align:left;"> disappointed </td>
   <td style="text-align:left;"> sadness </td>
  </tr>
  <tr>
   <td style="text-align:left;"> &lt;U+0001F618&gt; </td>
   <td style="text-align:left;"> kiss </td>
   <td style="text-align:left;"> anticipation </td>
   <td style="text-align:left;"> &lt;U+0001F628&gt; </td>
   <td style="text-align:left;"> fearful </td>
   <td style="text-align:left;"> sadness </td>
  </tr>
  <tr>
   <td style="text-align:left;"> &lt;U+0001F929&gt; </td>
   <td style="text-align:left;"> star </td>
   <td style="text-align:left;"> anticipation </td>
   <td style="text-align:left;"> &lt;U+0001F62D&gt; </td>
   <td style="text-align:left;"> crying </td>
   <td style="text-align:left;"> sadness </td>
  </tr>
  <tr>
   <td style="text-align:left;"> &lt;U+0001F61E&gt; </td>
   <td style="text-align:left;"> disappointed </td>
   <td style="text-align:left;"> disgust </td>
   <td style="text-align:left;"> &lt;U+0001F618&gt; </td>
   <td style="text-align:left;"> kiss </td>
   <td style="text-align:left;"> surprise </td>
  </tr>
  <tr>
   <td style="text-align:left;"> &lt;U+0001F624&gt; </td>
   <td style="text-align:left;"> nose </td>
   <td style="text-align:left;"> disgust </td>
   <td style="text-align:left;"> &lt;U+0001F62E&gt; </td>
   <td style="text-align:left;"> mouth </td>
   <td style="text-align:left;"> surprise </td>
  </tr>
  <tr>
   <td style="text-align:left;"> &lt;U+0001F631&gt; </td>
   <td style="text-align:left;"> screaming </td>
   <td style="text-align:left;"> disgust </td>
   <td style="text-align:left;"> &lt;U+0001F92A&gt; </td>
   <td style="text-align:left;"> zany </td>
   <td style="text-align:left;"> surprise </td>
  </tr>
  <tr>
   <td style="text-align:left;"> &lt;U+0001F641&gt; </td>
   <td style="text-align:left;"> frowning </td>
   <td style="text-align:left;"> disgust </td>
   <td style="text-align:left;"> &lt;U+0001F92D&gt; </td>
   <td style="text-align:left;"> mouth </td>
   <td style="text-align:left;"> surprise </td>
  </tr>
  <tr>
   <td style="text-align:left;"> &lt;U+0001F605&gt; </td>
   <td style="text-align:left;"> sweat </td>
   <td style="text-align:left;"> fear </td>
   <td style="text-align:left;"> &lt;U+0001F3C6&gt; </td>
   <td style="text-align:left;"> trophy </td>
   <td style="text-align:left;"> trust </td>
  </tr>
  <tr>
   <td style="text-align:left;"> &lt;U+0001F613&gt; </td>
   <td style="text-align:left;"> sweat </td>
   <td style="text-align:left;"> fear </td>
   <td style="text-align:left;"> &lt;U+0001F4B0&gt; </td>
   <td style="text-align:left;"> money </td>
   <td style="text-align:left;"> trust </td>
  </tr>
  <tr>
   <td style="text-align:left;"> &lt;U+0001F631&gt; </td>
   <td style="text-align:left;"> fear </td>
   <td style="text-align:left;"> fear </td>
   <td style="text-align:left;"> &lt;U+0001F4C8&gt; </td>
   <td style="text-align:left;"> chart </td>
   <td style="text-align:left;"> trust </td>
  </tr>
  <tr>
   <td style="text-align:left;"> &lt;U+0001F631&gt; </td>
   <td style="text-align:left;"> screaming </td>
   <td style="text-align:left;"> fear </td>
   <td style="text-align:left;"> &lt;U+0001F4CA&gt; </td>
   <td style="text-align:left;"> chart </td>
   <td style="text-align:left;"> trust </td>
  </tr>
</tbody>
</table>

Então cruzar o léxico com os *tokens* dos nomes dos `Emoji's` em todas as mensagens e visualizar quais os sentimentos mais comuns.


```r
# join with emoji chat
chat.sentiment <- emoji.chat %>% 
  inner_join(lex.sent, by=c("emoji_words"="word")) %>% 
  filter(!sentiment %in% c("negative","positive")) # removing neg/pos classification

# plot it
chat.sentiment %>% 
  count(sentiment) %>% 
  ggplot(aes(x=reorder(sentiment,n), y=n)) +
  geom_col(aes(fill=n), show.legend = FALSE, width = .1) +
  geom_point(aes(color=n), show.legend = FALSE, size = 3) +
  coord_flip() +
  ylab("") + xlab("") +
    scale_fill_gradient(low="#2b83ba",high="#d7191c") +
  scale_color_gradient(low="#2b83ba",high="#d7191c") +
  ggtitle("Most Frequent Sentiment","By Emoji names in 'It´s Football, Dudes!") +
  theme_minimal()
```

<img src="/posts/2019-10-12-analise-de-sentimentos-via-emojis-em-chat-do-whatsapp/index.pt-br_files/figure-html/mostFreqSentAll-1.png" width="672" />

E finalmente, vamos ver o perfil de sentimentos, por author.


```r
# plotting by author
chat.sentiment %>% 
  count(author, sentiment) %>% 
  left_join(filter(lex.sent, sentiment %in% c("negative","positive")),by=c("sentiment"="word")) %>% 
  rename( type = sentiment.y) %>% 
  mutate( type = ifelse(is.na(type), "neutral", type)) %>% 
  mutate( type = factor(type, levels = c("negative", "neutral", "positive"), ordered=T) ) %>% 
  group_by(author) %>%
  top_n(n = 8, n) %>%
  slice(1:8) %>% 
  ggplot(aes(x = reorder(sentiment, n), y = n, fill = type)) +
  geom_col() +
  scale_fill_manual(values = c("#d7191c","#fdae61", "#1a9641")) +
  ylab("") +
  xlab("") +
  coord_flip() +
  facet_wrap(~author, ncol = 3, scales = "free_x") +
  ggtitle("Most often sentiment") + 
  theme_minimal() + theme(legend.position = "bottom")
```

<img src="/posts/2019-10-12-analise-de-sentimentos-via-emojis-em-chat-do-whatsapp/index.pt-br_files/figure-html/mostFreqSentiment-1.png" width="672" />




### Referências

- [Introducing rwhatsapp](https://www.johannesbgruber.eu/post/introducing-rwhatsapp/)
- [Emoji Sentiment Ranking 1.0](https://www.clarin.si/repository/xmlui/handle/11356/1048)
- [Emoji Sentiment Ranking v1.0 Dataset](http://kt.ijs.si/data/Emoji_sentiment_ranking/index.html)
- [Emojis Analysis in R](http://opiateforthemass.es/articles/emoji-analysis/)
- [Text Mining with R](https://www.tidytextmining.com/sentiment.html)
