---
title: Using ggmap and gganimation to visualize oil spill in Brazil coastline
author: Giuliano Sposito
date: '2019-12-31'
slug: 'using-ggmap-and-gganimation-to-visualize-oil-spill-in-brazil-coastilne'
categories:
  - data science
tags:
  - gganimate
  - rstats
  - data analysis
  - rvest
  - ggmap
  - animation
subtitle: ''
lastmod: '2021-11-09T19:09:27-03:00'
authorLink: ''
description: ''
hiddenFromHomePage: no
hiddenFromSearch: no
featuredImage: 'images/oil_spill.jpg'
featuredImagePreview: 'images/oil_spill.jpg'
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

In 2019, a crude oil spill struck more than 2,000 kilometers off the coast of Brazil's Northeast and Southeast, affecting more than 400 beaches in more than 200 different municipalities. The first reports of the spill occurred at the end of August with sightings still spreading later this year. This post explores the sighting records available on the IBAMA website to view the impact of the leak using ggmap and gganimation.

<!--more--> 

In 2019, [a crude oil spill](https://en.wikipedia.org/wiki/2019_Northeast_Brazil_oil_spill) struck more than 2,000 kilometers off the coast of Brazil's Northeast and Southeast, affecting more than 400 beaches in more than 200 different municipalities. The first reports of the spill occurred at the end of August with sightings still spreading later this year. More than a thousand tons of oil have already been collected from the beaches, which is the worst oil leak in Brazil's history and the largest environmental disaster on the Brazilian coastline.


In this post we will explore [the oil sighting data](http://www.ibama.gov.br/manchasdeoleo), published on the [IBAMA](http://www.ibama.gov.br) website (the Brazilian Institute of the Environment and Renewable Natural Resources), a state agency from the [Ministry of the Environment](https://www.mma.gov.br/) responsible for implementing federal environmental preservation policies. We'll try to view the oil spill extension and evolution using the `ggmap` and` gganimation` R packages.

### Site and Dataset

IBAMA has made the oil spill data and information available on a [subsection of its site](http://www.ibama.gov.br/manchasdeoleo-localidades-atingidas), keeping a [daily record of status](http://www.ibama.gov.br/manchasdeoleo-localidades-atingidas) and spotting sightings.

Part of the records provided are available in excel format, and according with it's description, the files contain: the name of each spotted location, the county, the date of first sighting, the state, latitude, longitude, date where the location was revisited and oil spill status at the moment.

### Data Scrapping

Although the site offers PDF and XLXS, and it is possible to explore the sightings table within PDF files through the [`tabulizer` package](https://cran.r-project.org/web/packages/tabulizer/vignettes/tabulizer.html), in this post we'll only explore the contents of the excel files. The first step to this is to scrap the page that provides the files to download, to extract its links, we'll use [`rvest` package](https://www.datacamp.com/community/tutorials/r-web-scraping-rvest) to do this job.


```r
library(tidyverse)  # of course
library(rvest)      # to handle html scrapping
library(lubridate)  # handle datetime formats
library(glue)       # easily concat texts
library(knitr)      # markdown output tables
library(kableExtra) # formate markdown tables

# scrap and build url table
base_url <- "http://www.ibama.gov.br"

# page with update table
page <- read_html("http://www.ibama.gov.br/manchasdeoleo-localidades-atingidas")

# get the table
updates <- page %>% 
  html_table() %>% 
  .[[1]]

# get the href links
doc_links <- page %>%
  html_nodes(xpath = "//td/a") %>% 
  html_attr("href")

# put then togheter
doc_list <- updates %>% 
  set_names(c("date","description","items")) %>% 
  mutate( type = str_extract(items, "^[\\w]+") ) %>% 
  mutate( type = ifelse(type=="XLS","XLSX", type)) %>% # one file with "xls" extension
  mutate( link = paste0(base_url, doc_links) ) %>% 
  mutate( date=dmy(date) ) %>%
  as_tibble()

# save it, just in case we want to recover later
saveRDS(doc_list,"./data/oil_leakage_doc_list.rds")

# let's see the links list
doc_list %>% 
  head(10) %>% 
  kable() %>% 
  kableExtra::kable_styling(font_size = 10)
```


<table class="table" style="font-size: 10px; margin-left: auto; margin-right: auto;">
 <thead>
  <tr>
   <th style="text-align:left;"> date </th>
   <th style="text-align:left;"> description </th>
   <th style="text-align:left;"> items </th>
   <th style="text-align:left;"> type </th>
   <th style="text-align:left;"> link </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> 2019-12-14 </td>
   <td style="text-align:left;"> Localidades Atingidas </td>
   <td style="text-align:left;"> PDF - 32MB </td>
   <td style="text-align:left;"> PDF </td>
   <td style="text-align:left;"> http://www.ibama.gov.br/phocadownload/emergenciasambientais/2019/manchasdeoleo/2019-12-14_LOCALIDADES_AFETADAS.pdf </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2019-12-14 </td>
   <td style="text-align:left;"> Localidades Atingidas </td>
   <td style="text-align:left;"> XLSX - 74KB </td>
   <td style="text-align:left;"> XLSX </td>
   <td style="text-align:left;"> http://www.ibama.gov.br/phocadownload/emergenciasambientais/2019/manchasdeoleo/2019-12-14_LOCALIDADES_AFETADAS.xlsx </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2019-12-13 </td>
   <td style="text-align:left;"> Localidades Atingidas </td>
   <td style="text-align:left;"> PDF - 32MB </td>
   <td style="text-align:left;"> PDF </td>
   <td style="text-align:left;"> http://www.ibama.gov.br/phocadownload/emergenciasambientais/2019/manchasdeoleo/2019-12-13_LOCALIDADES-AFETADAS.pdf </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2019-12-13 </td>
   <td style="text-align:left;"> Localidades Atingidas </td>
   <td style="text-align:left;"> XLSX - 73KB </td>
   <td style="text-align:left;"> XLSX </td>
   <td style="text-align:left;"> http://www.ibama.gov.br/phocadownload/emergenciasambientais/2019/manchasdeoleo/2019-12-13_LOCALIDADES-AFETADAS_planilha.xlsx </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2019-12-12 </td>
   <td style="text-align:left;"> Localidades Atingidas </td>
   <td style="text-align:left;"> PDF - 31,3MB </td>
   <td style="text-align:left;"> PDF </td>
   <td style="text-align:left;"> http://www.ibama.gov.br/phocadownload/emergenciasambientais/2019/manchasdeoleo/2019-12-12_LOCALIDADES_AFETADAS.pdf </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2019-12-12 </td>
   <td style="text-align:left;"> Localidades Atingidas </td>
   <td style="text-align:left;"> XLSX - 72.2KB </td>
   <td style="text-align:left;"> XLSX </td>
   <td style="text-align:left;"> http://www.ibama.gov.br/phocadownload/emergenciasambientais/2019/manchasdeoleo/2019-12-12_LOCALIDADES_AFETADAS.xlsx </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2019-12-11 </td>
   <td style="text-align:left;"> Localidades Atingidas </td>
   <td style="text-align:left;"> PDF - 31.4MB </td>
   <td style="text-align:left;"> PDF </td>
   <td style="text-align:left;"> http://www.ibama.gov.br/phocadownload/emergenciasambientais/2019/manchasdeoleo/2019-12-11_LOCALIDADES_AFETADAS.pdf </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2019-12-11 </td>
   <td style="text-align:left;"> Localidades Atingidas </td>
   <td style="text-align:left;"> XLSX - 78KB </td>
   <td style="text-align:left;"> XLSX </td>
   <td style="text-align:left;"> http://www.ibama.gov.br/phocadownload/emergenciasambientais/2019/manchasdeoleo/2019-12-11_LOCALIDADES_AFETADAS_planilha.xlsx </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2019-12-10 </td>
   <td style="text-align:left;"> Localidades Atingidas </td>
   <td style="text-align:left;"> PDF - 31MB </td>
   <td style="text-align:left;"> PDF </td>
   <td style="text-align:left;"> http://www.ibama.gov.br/phocadownload/emergenciasambientais/2019/manchasdeoleo/2019-12-10_LOCALIDADES-AFETADAS.pdf </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2019-12-10 </td>
   <td style="text-align:left;"> Localidades Atingidas </td>
   <td style="text-align:left;"> XLSX - 68KB </td>
   <td style="text-align:left;"> XLSX </td>
   <td style="text-align:left;"> http://www.ibama.gov.br/phocadownload/emergenciasambientais/2019/manchasdeoleo/2019-12-10_LOCALIDADES-AFETADAS.xlsx </td>
  </tr>
</tbody>
</table>

Now that we have the links in hand, let's download the XLSX files.


```r
# check the pre existence of destination folders
XLSX_DEST_FOLDER <- "./data/oil_leakage_raw"
if(!file.exists("./data")) dir.create("./data")
if(!file.exists(XLSX_DEST_FOLDER)) dir.create(XLSX_DEST_FOLDER)

# download xlsx files
xlsx_filenames <- doc_list %>% 
  filter(type=="XLSX") %>% 
  select(date, link) %>% 
  arrange(date) %>% 
  split(1:nrow(.)) %>% 
  map_chr(function(.x){
    filename <- paste0(XLSX_DEST_FOLDER, "/",as.character(.x$date[1]), ".xlsx")
    download.file(url=.x$link[1], destfile = filename, mode = "wb")
    return(filename)
  })

# save an excel filename index
xlsx_index <- doc_list %>% 
  filter( type=="XLSX" ) %>% 
  arrange(date) %>% 
  mutate( filename = xlsx_filenames )

# save it
saveRDS(xlsx_index, "./data/excel_file_index.rds")

# let's see what we have
xlsx_index %>% 
  head(10) %>% 
  kable() %>% 
  kable_styling(font_size = 9)
```

<table class="table" style="font-size: 9px; margin-left: auto; margin-right: auto;">
 <thead>
  <tr>
   <th style="text-align:left;"> date </th>
   <th style="text-align:left;"> description </th>
   <th style="text-align:left;"> items </th>
   <th style="text-align:left;"> type </th>
   <th style="text-align:left;"> link </th>
   <th style="text-align:left;"> filename </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> 2019-10-16 </td>
   <td style="text-align:left;"> Localidades Atingidas </td>
   <td style="text-align:left;"> XLSX - 15KB </td>
   <td style="text-align:left;"> XLSX </td>
   <td style="text-align:left;"> http://www.ibama.gov.br/phocadownload/emergenciasambientais/2019/manchasdeoleo/2019-10-16_LOCALIDADES_AFETADAS.xlsx </td>
   <td style="text-align:left;"> ./data/oil_leakage_raw/2019-10-16.xlsx </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2019-10-17 </td>
   <td style="text-align:left;"> Localidades Atingidas </td>
   <td style="text-align:left;"> XLSX - 15KB </td>
   <td style="text-align:left;"> XLSX </td>
   <td style="text-align:left;"> http://www.ibama.gov.br/phocadownload/emergenciasambientais/2019/manchasdeoleo/2019-10-17_LOCALIDADES_AFETADAS.xlsx </td>
   <td style="text-align:left;"> ./data/oil_leakage_raw/2019-10-17.xlsx </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2019-10-18 </td>
   <td style="text-align:left;"> Localidades Atingidas </td>
   <td style="text-align:left;"> XLSX - 15KB </td>
   <td style="text-align:left;"> XLSX </td>
   <td style="text-align:left;"> http://www.ibama.gov.br/phocadownload/emergenciasambientais/2019/manchasdeoleo/2019-10-18_LOCALIDADES_AFETADAS.xlsx </td>
   <td style="text-align:left;"> ./data/oil_leakage_raw/2019-10-18.xlsx </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2019-10-19 </td>
   <td style="text-align:left;"> Localidades Atingidas </td>
   <td style="text-align:left;"> XLSX - 44KB </td>
   <td style="text-align:left;"> XLSX </td>
   <td style="text-align:left;"> http://www.ibama.gov.br/phocadownload/notas/2019/2019-10-19_LOCALIDADES_AFETADAS_PLANILHA.xls </td>
   <td style="text-align:left;"> ./data/oil_leakage_raw/2019-10-19.xlsx </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2019-10-22 </td>
   <td style="text-align:left;"> Localidades Atingidas </td>
   <td style="text-align:left;"> XLSX - 17KB </td>
   <td style="text-align:left;"> XLSX </td>
   <td style="text-align:left;"> http://www.ibama.gov.br/phocadownload/emergenciasambientais/2019/manchasdeoleo/2019-10-22_LOCALIDADES_AFETADAS.xlsx </td>
   <td style="text-align:left;"> ./data/oil_leakage_raw/2019-10-22.xlsx </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2019-10-23 </td>
   <td style="text-align:left;"> Localidades Atingidas </td>
   <td style="text-align:left;"> XLSX -17KB </td>
   <td style="text-align:left;"> XLSX </td>
   <td style="text-align:left;"> http://www.ibama.gov.br/phocadownload/emergenciasambientais/2019/manchasdeoleo/2019-10-23_LOCALIDADES_AFETADAS.xlsx </td>
   <td style="text-align:left;"> ./data/oil_leakage_raw/2019-10-23.xlsx </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2019-10-24 </td>
   <td style="text-align:left;"> Localidades Atingidas </td>
   <td style="text-align:left;"> XLSX - 20KB </td>
   <td style="text-align:left;"> XLSX </td>
   <td style="text-align:left;"> http://www.ibama.gov.br/phocadownload/notas/2019/2019-10-24_LOCALIDADES_AFETADAS_GERAL.xlsx </td>
   <td style="text-align:left;"> ./data/oil_leakage_raw/2019-10-24.xlsx </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2019-10-25 </td>
   <td style="text-align:left;"> Localidades Atingidas </td>
   <td style="text-align:left;"> XLSX - 21KB </td>
   <td style="text-align:left;"> XLSX </td>
   <td style="text-align:left;"> http://www.ibama.gov.br/phocadownload/notas/2019/2019-10-25_LOCALIDADES_AFETADAS_GERAL.xlsx </td>
   <td style="text-align:left;"> ./data/oil_leakage_raw/2019-10-25.xlsx </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2019-10-26 </td>
   <td style="text-align:left;"> Localidades Atingidas </td>
   <td style="text-align:left;"> XLSX - 18KB </td>
   <td style="text-align:left;"> XLSX </td>
   <td style="text-align:left;"> http://www.ibama.gov.br/phocadownload/emergenciasambientais/2019/manchasdeoleo/2019-10-26_LOCALIDADES_AFETADAS.xlsx </td>
   <td style="text-align:left;"> ./data/oil_leakage_raw/2019-10-26.xlsx </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2019-10-27 </td>
   <td style="text-align:left;"> Localidades Atingidas </td>
   <td style="text-align:left;"> XLSX - 35KB </td>
   <td style="text-align:left;"> XLSX </td>
   <td style="text-align:left;"> http://www.ibama.gov.br/phocadownload/notas/2019/2019-10-27_LOCALIDADES_AFETADAS.xlsx </td>
   <td style="text-align:left;"> ./data/oil_leakage_raw/2019-10-27.xlsx </td>
  </tr>
</tbody>
</table>

### Import Data

Let's use the [`xlsx` package](http://www.sthda.com/english/wiki/r-xlsx-package-a-quick-start-guide-to-manipulate-excel-files-in-r) to read excel files and import them into a` data.frame`. Let's take a look at one of them.


```r
library(xlsx) # import excel files (requires java/rjava)
```

```
## Warning: package 'xlsx' was built under R version 4.0.5
```

```r
xlsx_file <- read.xlsx(file = "./data/2019-12-14.xlsx",sheetIndex = 1)

xlsx_file %>% 
  head(10) %>% 
  kable() %>% 
  kable_styling(font_size = 10)
```

<table class="table" style="font-size: 10px; margin-left: auto; margin-right: auto;">
 <thead>
  <tr>
   <th style="text-align:left;"> geocodigo </th>
   <th style="text-align:left;"> localidade </th>
   <th style="text-align:left;"> loc_id </th>
   <th style="text-align:left;"> municipio </th>
   <th style="text-align:left;"> estado </th>
   <th style="text-align:left;"> sigla_uf </th>
   <th style="text-align:left;"> Data_Avist </th>
   <th style="text-align:left;"> Data_Revis </th>
   <th style="text-align:left;"> Status </th>
   <th style="text-align:left;"> Latitude </th>
   <th style="text-align:left;"> Longitude </th>
   <th style="text-align:left;"> Hora </th>
   <th style="text-align:left;"> cou </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> 2925303 </td>
   <td style="text-align:left;"> Praia de Taperapuã </td>
   <td style="text-align:left;"> 2925303_45 </td>
   <td style="text-align:left;"> Porto Seguro </td>
   <td style="text-align:left;"> Bahia </td>
   <td style="text-align:left;"> BA </td>
   <td style="text-align:left;"> 2019-11-04 </td>
   <td style="text-align:left;"> 2019-12-14 </td>
   <td style="text-align:left;"> Oleo Nao Observado </td>
   <td style="text-align:left;"> 16° 25' 15.03" S </td>
   <td style="text-align:left;"> 39° 3' 13.45" W </td>
   <td style="text-align:left;"> 10:14:18 </td>
   <td style="text-align:left;"> 1 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2925303 </td>
   <td style="text-align:left;"> Praia de Mucugê </td>
   <td style="text-align:left;"> 2925303_46 </td>
   <td style="text-align:left;"> Porto Seguro </td>
   <td style="text-align:left;"> Bahia </td>
   <td style="text-align:left;"> BA </td>
   <td style="text-align:left;"> 2019-10-31 </td>
   <td style="text-align:left;"> 2019-12-11 </td>
   <td style="text-align:left;"> Oleo Nao Observado </td>
   <td style="text-align:left;"> 16° 29' 43.41" S </td>
   <td style="text-align:left;"> 39° 4' 7.187" W </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> 1 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2805307 </td>
   <td style="text-align:left;"> Praia da Ponta dos Mangues </td>
   <td style="text-align:left;"> 2805307_26 </td>
   <td style="text-align:left;"> Pirambu </td>
   <td style="text-align:left;"> Sergipe </td>
   <td style="text-align:left;"> SE </td>
   <td style="text-align:left;"> 2019-11-13 </td>
   <td style="text-align:left;"> 2019-11-16 </td>
   <td style="text-align:left;"> Oleo Nao Observado </td>
   <td style="text-align:left;"> 10° 43' 54.29" S </td>
   <td style="text-align:left;"> 36° 50' 24.42" W </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> 1 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2925303 </td>
   <td style="text-align:left;"> Praia de Itaquena </td>
   <td style="text-align:left;"> 2925303_47 </td>
   <td style="text-align:left;"> Porto Seguro </td>
   <td style="text-align:left;"> Bahia </td>
   <td style="text-align:left;"> BA </td>
   <td style="text-align:left;"> 2019-11-02 </td>
   <td style="text-align:left;"> 2019-11-19 </td>
   <td style="text-align:left;"> Oleo Nao Observado </td>
   <td style="text-align:left;"> 16° 39' 7.314" S </td>
   <td style="text-align:left;"> 39° 5' 40.20" W </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> 1 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2805307 </td>
   <td style="text-align:left;"> Praia Pirambu </td>
   <td style="text-align:left;"> 2805307_21 </td>
   <td style="text-align:left;"> Pirambu </td>
   <td style="text-align:left;"> Sergipe </td>
   <td style="text-align:left;"> SE </td>
   <td style="text-align:left;"> 2019-11-07 </td>
   <td style="text-align:left;"> 2019-12-07 </td>
   <td style="text-align:left;"> Oleada - Vestigios / Esparsos </td>
   <td style="text-align:left;"> 10° 40' 55.80" S </td>
   <td style="text-align:left;"> 36° 46' 31.49" W </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> 1 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2805307 </td>
   <td style="text-align:left;"> Praia Pirambu </td>
   <td style="text-align:left;"> 2805307_22 </td>
   <td style="text-align:left;"> Pirambu </td>
   <td style="text-align:left;"> Sergipe </td>
   <td style="text-align:left;"> SE </td>
   <td style="text-align:left;"> 2019-11-09 </td>
   <td style="text-align:left;"> 2019-11-26 </td>
   <td style="text-align:left;"> Oleada - Vestigios / Esparsos </td>
   <td style="text-align:left;"> 10° 41' 14.27" S </td>
   <td style="text-align:left;"> 36° 47' 2.093" W </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> 1 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2805307 </td>
   <td style="text-align:left;"> Praia Pirambu </td>
   <td style="text-align:left;"> 2805307_23 </td>
   <td style="text-align:left;"> Pirambu </td>
   <td style="text-align:left;"> Sergipe </td>
   <td style="text-align:left;"> SE </td>
   <td style="text-align:left;"> 2019-12-09 </td>
   <td style="text-align:left;"> 2019-12-09 </td>
   <td style="text-align:left;"> Oleada - Vestigios / Esparsos </td>
   <td style="text-align:left;"> 10° 41' 32.37" S </td>
   <td style="text-align:left;"> 36° 47' 28.42" W </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> 1 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2504603 </td>
   <td style="text-align:left;"> Praia do Amor </td>
   <td style="text-align:left;"> 2504603_1 </td>
   <td style="text-align:left;"> Conde </td>
   <td style="text-align:left;"> Paraíba </td>
   <td style="text-align:left;"> PB </td>
   <td style="text-align:left;"> 2019-09-30 </td>
   <td style="text-align:left;"> 2019-11-14 </td>
   <td style="text-align:left;"> Oleo Nao Observado </td>
   <td style="text-align:left;"> 7° 16' 17.60" S </td>
   <td style="text-align:left;"> 34° 48' 8.354" W </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> 1 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2504603 </td>
   <td style="text-align:left;"> Praia de Jacumã </td>
   <td style="text-align:left;"> 2504603_2 </td>
   <td style="text-align:left;"> Conde </td>
   <td style="text-align:left;"> Paraíba </td>
   <td style="text-align:left;"> PB </td>
   <td style="text-align:left;"> 2019-08-30 </td>
   <td style="text-align:left;"> 2019-12-12 </td>
   <td style="text-align:left;"> Oleo Nao Observado </td>
   <td style="text-align:left;"> 7° 16' 48.85" S </td>
   <td style="text-align:left;"> 34° 47' 57.13" W </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> 1 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2504603 </td>
   <td style="text-align:left;"> Praia de Gramame </td>
   <td style="text-align:left;"> 2504603_3 </td>
   <td style="text-align:left;"> Conde </td>
   <td style="text-align:left;"> Paraíba </td>
   <td style="text-align:left;"> PB </td>
   <td style="text-align:left;"> 2019-08-30 </td>
   <td style="text-align:left;"> 2019-11-14 </td>
   <td style="text-align:left;"> Oleo Nao Observado </td>
   <td style="text-align:left;"> 7° 15' 11.17" S </td>
   <td style="text-align:left;"> 34° 48' 21.93" W </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> 1 </td>
  </tr>
</tbody>
</table>

We can see that the file contains: a _geocode_, the name of each location, a _id_ for that spot, the county name, state name and federation unit acronym, the date of the first spill sighting, the revision date (last status position), the current information about the spill state of the locality, latitude and longitude, plus an "hour" and an unknown `cou` column.

Attention: note every excel files has the same format, the code bellow handles some differences between then.

To read the files and use its data, we have to clean then first: resolving encoding, transforming the status information in a factor class, and turn the degree notations for latitude and longitude into decimal notation.

#### Importation 


```r
# import each xlsx_file
files <- xlsx_index %>%
  split(1:nrow(.)) %>% 
  map(function(.x){
    print(.x$filename)
    read.xlsx(file = .x$filename[1], sheetIndex = 1, colClasses="character", stringsAsFactors=F) %>% 
      as_tibble() %>% 
      mutate(file.date=.x$date[1])
  })

# save it as cache
saveRDS(files, "./data/oil_leakage_imported_raw_excel.rds")
```

#### Data Clean-up


```r
# auxiliary function to translate the degree coordinates to decimal coordinates
translateCoord <- function(.coords){
  
  # extract orientation (N,S,W,E)
  directions <- str_extract(.coords,"\\w$")
  
  # split the numbers and rebuilds as xxDyy'zz"
  numbers <- .coords %>% 
    str_extract_all("(\\d\\.*)+") %>% 
    purrr::map(~paste0(.x[1],"d",.x[2],"'",.x[3],"\""))
  
  # modify char2dms to a safity call
  safe_char2dms <- safely(sp::char2dms, otherwise = NA)
  
  # readd orientation(NSWE) and converts to decimal
  numbers %>% 
    purrr::map2(directions, ~paste0(.x, .y)) %>% 
    purrr::map(safe_char2dms) %>% 
    purrr::map(purrr::pluck("result")) %>% 
    purrr::map(as.numeric) %>% 
    unlist() %>% 
    return()
}

# clean ant transform status data in to ordenated factor
statusToFactor <- function(.status){
  tibble( from_status = tolower(.status) )  %>% 
    mutate(
      to_status = case_when(
        str_detect(from_status, "manchas")   ~ "stains",
        str_detect(from_status, "esparsos")  ~ "traces/sparse",
        str_detect(from_status, "observado") ~ "not observed",
        T ~ as.character(NA)
      )
    ) %>% 
    mutate( fct_status = factor(to_status, levels = c("not observed", "traces/sparse", "stains"), ordered = T) ) %>% 
    pull(fct_status) %>% 
    return()
}

# read the raw excel importation
files <- readRDS("./data/oil_leakage_imported_raw_excel.rds")

# put all the excels in one dataframe
# perform a data cleanup
stains_raw <- files %>% 
  # the file form day 2019-11-06 hasn't coordinates
  keep(function(.x){ .x$file.date[1] != "2019-11-06"} ) %>% 
  # for each "excel" data
  map_df(function(.x){
    
    # some excels have two "municipio" columns
    if("municipio_" %in% names(.x)) .x <- select(.x, -municipio)
    
    # clean and normalize colnames
    col.names <- .x %>%
      names() %>% 
      tolower() %>%
      str_replace_all("munic.+pi.*", "municipio") %>% # acento no municipio 
      str_replace_all("name", "localidade") %>% 
      str_replace_all("latitutde","latitude")
    
    # rename the cols and select what we'll use
    .x %>% 
      set_names(col.names) %>% 
      select(file.date, localidade, municipio, 
             estado, data_avist, data_revis,
             latitude, longitude, status) %>% 
      
      # handle portuguese accents
      mutate(
        localidade = iconv(localidade, from="UTF-8", to="LATIN1"),
        municipio  = iconv(municipio, from="UTF-8", to="LATIN1"),
        estado     = iconv(estado, from="UTF-8", to="LATIN1"),
        status     = iconv(status, from="UTF-8", to="LATIN1"),
        data_avist = ymd(as.character(data_avist)), 
        data_revis = ymd(as.character(data_revis))
      ) %>% 
      return()
  })

# we have to translate degree coordinates to decimal
stains_coord <- stains_raw %>%   
  mutate(
    lat.degree = translateCoord(latitude),
    lon.degree = translateCoord(longitude)
  ) %>% 
  # in some of the files, the coordinates are indeed in decimal 
  mutate(
    lat.degree = ifelse(is.na(lat.degree), as.numeric(latitude), lat.degree),
    lon.degree = ifelse(is.na(lon.degree), as.numeric(longitude), lon.degree)
  )

# in some files, the "UF" column has the name of the states 
# and others the code of states, we handle this making a name<->code table
estado_uf <- files %>% 
  tail(1) %>% 
  .[[1]] %>% 
  mutate(
    estado = iconv(estado, from="UTF-8", to="LATIN1")
  ) %>% 
  select(estado, sigla_uf) %>% 
  distinct() %>% 
  arrange(estado)

# join the state name<->code table
stains_clean <- stains_coord %>% 
  left_join(estado_uf, by = "estado") %>% 
  # handle when the info is correct/incorrect
  mutate(sigla_uf = ifelse(is.na(sigla_uf),estado,sigla_uf)) %>% 
  # there is files without state code
  filter(!is.na(sigla_uf)) %>% 
  select(-estado) %>% 
  # rebuild state name
  inner_join(estado_uf, by="sigla_uf") %>% 
  # reselect only interesting cols
  select(file.date, data_avist, data_revis, sigla_uf, estado, municipio, localidade, lat.degree, lon.degree, status)

# transform the "status" info in a factor column
stains <- stains_clean %>% 
  mutate( status = statusToFactor(status) ) %>% 
  filter(complete.cases(.)) %>% 
  # english col names
  set_names(c("file.date", "sighting_date","revision_date","uf","state","county",
              "local","lat.degree","lon.degree","status")) %>% 
  # last clean-up
  filter(
    lon.degree < 0, # anything greater than that is a error
    revision_date < ymd(20200101), # anything greater than that is a error
    sighting_date < ymd(20200101), # anything greater than that is a error
    complete.cases(.) # missing data is not relevant
  )

# save it, just in case
saveRDS(stains, "./data/oil_leakage.rds")
```

Now we have all the data from the excel files concatenated, cleaned, treated and stored in a data.frame, let's look at the final data format.


```r
stains <- readRDS("./data/oil_leakage.rds")

# checking the final format
stains %>% 
  head(10) %>% 
  kable() %>% 
  kable_styling(font_size = 8)
```

<table class="table" style="font-size: 8px; margin-left: auto; margin-right: auto;">
 <thead>
  <tr>
   <th style="text-align:left;"> file.date </th>
   <th style="text-align:left;"> sighting_date </th>
   <th style="text-align:left;"> revision_date </th>
   <th style="text-align:left;"> uf </th>
   <th style="text-align:left;"> state </th>
   <th style="text-align:left;"> county </th>
   <th style="text-align:left;"> local </th>
   <th style="text-align:right;"> lat.degree </th>
   <th style="text-align:right;"> lon.degree </th>
   <th style="text-align:left;"> status </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> 2019-10-16 </td>
   <td style="text-align:left;"> 2019-09-10 </td>
   <td style="text-align:left;"> 2019-10-15 </td>
   <td style="text-align:left;"> RN </td>
   <td style="text-align:left;"> Rio Grande do Norte </td>
   <td style="text-align:left;"> N¡sia Floresta </td>
   <td style="text-align:left;"> Barra de Tabatinga - Tartarugas </td>
   <td style="text-align:right;"> -6.057081 </td>
   <td style="text-align:right;"> -35.09679 </td>
   <td style="text-align:left;"> stains </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2019-10-16 </td>
   <td style="text-align:left;"> 2019-09-07 </td>
   <td style="text-align:left;"> 2019-10-16 </td>
   <td style="text-align:left;"> AL </td>
   <td style="text-align:left;"> Alagoas </td>
   <td style="text-align:left;"> Japaratinga </td>
   <td style="text-align:left;"> Praia de Japaratinga </td>
   <td style="text-align:right;"> -9.093531 </td>
   <td style="text-align:right;"> -35.25822 </td>
   <td style="text-align:left;"> stains </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2019-10-16 </td>
   <td style="text-align:left;"> 2019-09-18 </td>
   <td style="text-align:left;"> 2019-10-14 </td>
   <td style="text-align:left;"> AL </td>
   <td style="text-align:left;"> Alagoas </td>
   <td style="text-align:left;"> Passo de Camaragibe </td>
   <td style="text-align:left;"> Praia do Carro Quebrado </td>
   <td style="text-align:right;"> -9.341689 </td>
   <td style="text-align:right;"> -35.44870 </td>
   <td style="text-align:left;"> stains </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2019-10-16 </td>
   <td style="text-align:left;"> 2019-09-22 </td>
   <td style="text-align:left;"> 2019-10-13 </td>
   <td style="text-align:left;"> AL </td>
   <td style="text-align:left;"> Alagoas </td>
   <td style="text-align:left;"> Roteiro </td>
   <td style="text-align:left;"> Praia do Gunga </td>
   <td style="text-align:right;"> -9.903094 </td>
   <td style="text-align:right;"> -35.93877 </td>
   <td style="text-align:left;"> stains </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2019-10-16 </td>
   <td style="text-align:left;"> 2019-09-02 </td>
   <td style="text-align:left;"> 2019-10-02 </td>
   <td style="text-align:left;"> SE </td>
   <td style="text-align:left;"> Sergipe </td>
   <td style="text-align:left;"> Barra dos Coqueiros </td>
   <td style="text-align:left;"> Atalaia Nova </td>
   <td style="text-align:right;"> -10.952222 </td>
   <td style="text-align:right;"> -37.02944 </td>
   <td style="text-align:left;"> stains </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2019-10-16 </td>
   <td style="text-align:left;"> 2019-10-04 </td>
   <td style="text-align:left;"> 2019-10-05 </td>
   <td style="text-align:left;"> BA </td>
   <td style="text-align:left;"> Bahia </td>
   <td style="text-align:left;"> Janda¡ra </td>
   <td style="text-align:left;"> Janda¡ra </td>
   <td style="text-align:right;"> -11.528550 </td>
   <td style="text-align:right;"> -37.40157 </td>
   <td style="text-align:left;"> stains </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2019-10-16 </td>
   <td style="text-align:left;"> 2019-10-04 </td>
   <td style="text-align:left;"> 2019-10-13 </td>
   <td style="text-align:left;"> BA </td>
   <td style="text-align:left;"> Bahia </td>
   <td style="text-align:left;"> Conde </td>
   <td style="text-align:left;"> S¡tio do Conde </td>
   <td style="text-align:right;"> -11.852953 </td>
   <td style="text-align:right;"> -37.56399 </td>
   <td style="text-align:left;"> stains </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2019-10-16 </td>
   <td style="text-align:left;"> 2019-10-07 </td>
   <td style="text-align:left;"> 2019-10-08 </td>
   <td style="text-align:left;"> BA </td>
   <td style="text-align:left;"> Bahia </td>
   <td style="text-align:left;"> Esplanada </td>
   <td style="text-align:left;"> Mamucabo </td>
   <td style="text-align:right;"> -12.163006 </td>
   <td style="text-align:right;"> -37.72419 </td>
   <td style="text-align:left;"> stains </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2019-10-16 </td>
   <td style="text-align:left;"> 2019-09-27 </td>
   <td style="text-align:left;"> 2019-10-07 </td>
   <td style="text-align:left;"> AL </td>
   <td style="text-align:left;"> Alagoas </td>
   <td style="text-align:left;"> Coruripe </td>
   <td style="text-align:left;"> Lagoa do Pau </td>
   <td style="text-align:right;"> -10.129733 </td>
   <td style="text-align:right;"> -36.11001 </td>
   <td style="text-align:left;"> stains </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2019-10-16 </td>
   <td style="text-align:left;"> 2019-10-01 </td>
   <td style="text-align:left;"> 2019-10-15 </td>
   <td style="text-align:left;"> BA </td>
   <td style="text-align:left;"> Bahia </td>
   <td style="text-align:left;"> Mata de SÆo JoÆo </td>
   <td style="text-align:left;"> Santo Ant"nio </td>
   <td style="text-align:right;"> -12.459700 </td>
   <td style="text-align:right;"> -37.93229 </td>
   <td style="text-align:left;"> stains </td>
  </tr>
</tbody>
</table>

### Plotting as a Map

With the data in hand, we'll try to visualize the communities affected by the oil spill placing the data in a map. There are several frameworks for plotting maps in R, in this post we will use the [`ggmap` package](https://www.littlemissdata.com/blog/maps), which we already have used [previously in the past](https://yetanotheriteration.netlify.com/2018/01/ploting-your-mtb-track-with-r/).

Before to use `ggmap`, we'll need to get the Google Map API Key and register it, but the procedure is pretty straightforward, [just following these instructions](https://developers.google.com/maps/documentation/embed/get-api-key). In my code, I always store the keys and others sensible information in [`yalm` files](https://en.wikipedia.org/wiki/YAML) to avoid accidentaly publish then in the GitHub, [I also commented about this strategy in a older post](https://yetanotheriteration.netlify.com/2019/03/comparing-fitbit-and-polar-h7-heart-rate-data/). 



```r
# ggmap
library(ggmap)
library(yaml) # used to not version the google's map key

# before use ggmap with google maps it's necessary
# read and register a Key for Google Map API
# config <- yaml::read_yaml("./config.yml")
# register_google(key=config$google_map_key)

# get the map area
bbox <- make_bbox(lon = stains$lon.degree, lat=stains$lat.degree, f = .1)
gmap <- get_map(location=bbox, source="google", maptype="terrain")

# plot the data of observations on revision date 2019-11-10
# of location with stains or sparse residuos
ggmap(gmap) +
  geom_point(data=filter(stains, status!="not observed", revision_date==ymd(20191110)),
             aes(x=lon.degree, y=lat.degree, color=status), size=2, alpha=.8) +
  scale_color_manual(values=c("#888888","black","green")) +
  theme_void() +
  ggplot2::coord_fixed() 
```

<img src="{{< blogdown/postref >}}index.en_files/figure-html/ggmapTest-1.png" width="672" />

### The animation

Now the last step is to animate the map in the time dimension, we'll do this using the great [`gganimate` package](https://gganimate.com/articles/gganimate.html), adding a transition function in the `ggplot2 + ggmap` stack.


```r
library(gganimate)
bbox <- make_bbox(lon = stains$lon.degree, lat=stains$lat.degree, f = .1)
gmap <- get_map(location=bbox, source="google", maptype="terrain")

p <- ggmap(gmap) +
  geom_point(data=filter(stains, status!="not observed"),
             aes(x=lon.degree, y=lat.degree,
                 color=status, group=county),
             size=3, alpha=.8) +
  scale_color_manual(values=c("#888888","black")) +
  theme_void()

anim <- p  +
  theme( legend.position = "bottom" ) +
  transition_time(revision_date) +
  labs(title="Oil Sighting on Brazil Coast",
       subtitle = "Date:  {frame_time} - source: IBAMA") +
  shadow_wake(wake_length = .15)

anim
```

![](index.en_files/figure-html/animation-1.gif)<!-- -->

### Visualizing the spill evolution in one plot

The animated map view gives us an great idea of the size of the ecological impact of the oil spill off the coast of Brazil. But to analytical purpose the animation does not allow you to see the full evolution history at one same time, allowing us to gauge how the spill is progressing. 

To do this trick, let's plot the information as a heatmap, where each location will be on the Y axis, indexed by its latitude, and on the X axis we'll use the date information.



```r
# let's organize the "county/locality" by latitude
stains %>% 
  select(local, lat.degree, revision_date, status) %>% 
  group_by(local) %>% 
  # calculates a unique latitude for local
  mutate( avg.lat = mean(lat.degree) ) %>% 
  ungroup() %>% 
  # put the locals in latitude order
  mutate( local = fct_reorder(local, avg.lat) ) %>% 
  select( local, revision_date, status ) %>% 
  distinct() %>% 
  # plot as a tile chart (local x date)
  arrange( local, revision_date ) %>% 
  ggplot(aes(x=revision_date, y=local)) +
  geom_tile(aes(fill=status)) +
  scale_fill_manual(values = c("lightgreen", "#888888", "black")) +
  theme_minimal() +
  theme( axis.text.y = element_blank() ) +
  labs(title="Oil Sighting by Latitude and Date", x="date", y="local/latitude")
```

<img src="{{< blogdown/postref >}}index.en_files/figure-html/tileChart-1.png" width="672" />

In this graph, we can visualize how the the oil spill are progressing to the south, following the maritime currents, over the months of October and November, reaching the most extreme point a few days,  before December.

The intermittent nature of the chart shows that information registring is not done daily in all locations, and some communities has more status updates than others we should handle this caracteristic to correctly plot the information, but we'll leave this to other post.
