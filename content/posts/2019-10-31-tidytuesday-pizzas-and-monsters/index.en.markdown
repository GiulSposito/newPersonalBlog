---
title: 'TidyTuesday: Pizzas and Monsters'
author: Giuliano Sposito
date: '2019-10-31'
slug: 'tidytuesday-pizzas-and-monsters'
categories:
  - data science
tags:
  - rstats
  - data analysis
  - tidytuesday
  - tidytext
  - lasso
subtitle: ''
lastmod: '2021-11-09T02:06:01-03:00'
authorLink: ''
description: ''
hiddenFromHomePage: no
hiddenFromSearch: no
featuredImage: 'images/horror_pizza.jpg'
featuredImagePreview: 'images/horror_pizza.jpg'
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


We learn from the masters, doing the *math* by ourselves, so, in this post we reproduce two data analysis from David Robinson's *#TidyTuesday* screencasts, the first one about the horro movie ratings dataset where he uses a lasso regression to predict the ratings of a movie based on genre, cast and plot. The second is about a dataset of pizza ratings in NYC and other cities. There are goods data handling tricks using tidyverse in these analysis.

<!--more-->

In this post we reproduce two data analysis from [David Robinson's](https://twitter.com/drob) [#TidyTuesday](https://github.com/rfordatascience/tidytuesday) screencasts, the first one about the horror movie ratings dataset where he uses a lasso regression to predict the ratings of a movie based on genre, cast and plot. The second is about a dataset of pizza ratings in NYC and other cities.



#### Horror Movies

Under the halloween influence, we just reproduce the analysis of the [IMDB´s](https://www.imdb.com/) [Horror Movie Dataset](https://github.com/rfordatascience/tidytuesday/tree/master/data/2019/2019-10-22) made by [David Robinson's](https://twitter.com/drob) in one of famous screen cast. The dataset is available in the [#TidyTuesday GitHub Repo](https://github.com/rfordatascience/tidytuesday).

<!-- tweet --> 
<blockquote class="twitter-tweet"><p lang="en" dir="ltr">In this <a href="https://twitter.com/hashtag/tidytuesday?src=hash&amp;ref_src=twsrc%5Etfw">#tidytuesday</a> screencast, I analyze a dataset of horror movie ratings, and use lasso regression to predict ratings based on genre, cast, and plot.<br><br>What&#39;s 😱👍: Indian, animated, and drama films<br><br>What&#39;s 🙄👎: Sharks and Eric Roberts<a href="https://t.co/3qj7NoA4Pf">https://t.co/3qj7NoA4Pf</a> <a href="https://twitter.com/hashtag/rstats?src=hash&amp;ref_src=twsrc%5Etfw">#rstats</a> 🧛
♂️👻 <a href="https://t.co/OBI6x1O2zX">pic.twitter.com/OBI6x1O2zX</a></p>&mdash; David Robinson (@drob) <a href="https://twitter.com/drob/status/1186659010956713984?ref_src=twsrc%5Etfw">October 22, 2019</a></blockquote> <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>
<!-- tweet --> 

{{< tweet "1186659010956713984" >}}

#### Data loading and cleaning


```r
# basic setup
library(tidyverse)
library(knitr) # for kable
library(kableExtra) # to change tables font size
library(glue)
theme_set(theme_minimal()) # changing ggplot2 default theme

# data load
horror_movies_raw <- readr::read_csv("https://raw.githubusercontent.com/rfordatascience/tidytuesday/master/data/2019/2019-10-22/horror_movies.csv")

glimpse(horror_movies_raw)
```

```
## Rows: 3,328
## Columns: 12
## $ title             <chr> "Gut (2012)", "The Haunting of Mia Moss (2017)", "Sl~
## $ genres            <chr> "Drama| Horror| Thriller", "Horror", "Horror", "Come~
## $ release_date      <chr> "26-Oct-12", "13-Jan-17", "21-Oct-17", "23-Apr-13", ~
## $ release_country   <chr> "USA", "USA", "Canada", "USA", "USA", "UK", "USA", "~
## $ movie_rating      <chr> NA, NA, NA, "NOT RATED", NA, NA, "NOT RATED", NA, "P~
## $ review_rating     <dbl> 3.9, NA, NA, 3.7, 5.8, NA, 5.1, 6.5, 4.6, 5.4, 5.3, ~
## $ movie_run_time    <chr> "91 min", NA, NA, "82 min", "80 min", "93 min", "90 ~
## $ plot              <chr> "Directed by Elias. With Jason Vail, Nicholas Wilder~
## $ cast              <chr> "Jason Vail|Nicholas Wilder|Sarah Schoofs|Kirstianna~
## $ language          <chr> "English", "English", "English", "English", "Italian~
## $ filming_locations <chr> "New York, USA", NA, "Sudbury, Ontario, Canada", "Ba~
## $ budget            <chr> NA, "$30,000", NA, NA, NA, "$3,400,000", NA, NA, NA,~
```

We see here, besides a `release_date` attribute, there is also a *year* information inside the `title` field, let's extract this data into a new `year` column. Also, we have to correctly parsing the `budget` column. Note that the `plot` column also has a strange content.


```r
horror_movies_raw[1,]$plot
```

```
## [1] "Directed by Elias. With Jason Vail, Nicholas Wilder, Sarah Schoofs, Kirstianna Mueller. Family man Tom has seen something he can't forget, a mysterious video with an ugly secret that soon spreads into his daily life and threatens to dismantle everything around him."
```

It starts with the director of the movie, the cast and only after that the movie plot, we need to split these infos in diferent columns.


```r
# some data cleaning
horror_movies <- horror_movies_raw %>% 
  arrange(desc(review_rating)) %>% 
  # remove the "year" from title and put into a "year" column
  extract(title, "year", "\\((\\d\\d\\d\\d)\\)$", remove = F, convert = T) %>% 
  # using "parse_number" to correctly the buget column
  mutate(budget=parse_number(budget)) %>% 
  # Splitting the "plot" info. We split each sentence in diferent columns.
  # First one to the director, one for the actors and the remaings to the "plot"
  separate(plot, c("director","cast_sentence","plot"), sep="\\. ", extra="merge", fill="right") %>% 
  distinct(title, .keep_all = T)
```

Some *tidy functions* were pretty handy in this manipulation, worth to check the documentation and know how to use [`tidyr::extract()`](https://tidyr.tidyverse.org/reference/extract.html),  [`tidyr::separate()`](https://tidyr.tidyverse.org/reference/separate.html) and [`readr::parse_number()`](https://www.rdocumentation.org/packages/readr/versions/1.3.1/topics/parse_number).

#### Exploring the data

Let's see some aspects of the dataset


```r
# how much movies by genres?
horror_movies %>% 
  count(genres, sort=T) %>% 
  head(10) %>% 
  kable()
```

<table>
 <thead>
  <tr>
   <th style="text-align:left;"> genres </th>
   <th style="text-align:right;"> n </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> Horror </td>
   <td style="text-align:right;"> 1048 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Horror| Thriller </td>
   <td style="text-align:right;"> 469 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Comedy| Horror </td>
   <td style="text-align:right;"> 245 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Horror| Mystery| Thriller </td>
   <td style="text-align:right;"> 171 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Drama| Horror| Thriller </td>
   <td style="text-align:right;"> 159 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Drama| Horror </td>
   <td style="text-align:right;"> 72 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Horror| Sci-Fi| Thriller </td>
   <td style="text-align:right;"> 66 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Drama| Horror| Mystery| Thriller </td>
   <td style="text-align:right;"> 53 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Action| Horror| Thriller </td>
   <td style="text-align:right;"> 48 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Horror| Mystery </td>
   <td style="text-align:right;"> 47 </td>
  </tr>
</tbody>
</table>

```r
# by language
horror_movies %>% 
  count(language, sort=T) %>% 
  head(10) %>% 
  kable()
```

<table>
 <thead>
  <tr>
   <th style="text-align:left;"> language </th>
   <th style="text-align:right;"> n </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> English </td>
   <td style="text-align:right;"> 2407 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Spanish </td>
   <td style="text-align:right;"> 94 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Japanese </td>
   <td style="text-align:right;"> 75 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> 70 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Hindi </td>
   <td style="text-align:right;"> 37 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Filipino|Tagalog </td>
   <td style="text-align:right;"> 34 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Thai </td>
   <td style="text-align:right;"> 34 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> English|Spanish </td>
   <td style="text-align:right;"> 30 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Turkish </td>
   <td style="text-align:right;"> 29 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> German </td>
   <td style="text-align:right;"> 28 </td>
  </tr>
</tbody>
</table>

```r
# how is the bugdet distribution
horror_movies %>% 
  ggplot(aes(budget)) +
  geom_histogram() +
  scale_x_log10(labels=scales::dollar)
```

<img src="{{< blogdown/postref >}}index.en_files/figure-html/basicEDA-1.png" width="672" />

One of the things I didn't know was how to format the datatype in the chart axis, in the screencast David uses the function [`scales::dollar()`](https://www.rdocumentation.org/packages/scales/versions/0.4.1/topics/dollar_format) to transform the X axis in *money*. The package [`Scales`](https://www.rdocumentation.org/packages/scales/versions/0.2.0) map data to aesthetics, and provide methods for automatically determining breaks and labels for axs and legends, pretty handy.

Do higher budget movies end up higher rated?


```r
# plot budget x rating
horror_movies %>% 
  ggplot(aes(budget, review_rating)) +
  geom_point() +
  scale_x_log10(labels=scales::dollar) +
  geom_smooth(method="lm")
```

<img src="{{< blogdown/postref >}}index.en_files/figure-html/budget_x_rating-1.png" width="672" />

No relationshiop between budget and rating. How about `movie rating` (classification of film's suitability for certain audiences based on its content) and the `movie review` (people's movie evaluation)?


```r
# let's look movie_rating x review_rating
horror_movies %>% 
  mutate( movie_rating = fct_lump(movie_rating, 5),
          movie_rating = fct_reorder(movie_rating, review_rating, na.rm=T)
  ) %>% 
  ggplot(aes(movie_rating, review_rating)) +
  geom_boxplot() +
  coord_flip()
```

<img src="{{< blogdown/postref >}}index.en_files/figure-html/ratinge_x_review-1.png" width="672" />

Two [`forcats`](https://forcats.tidyverse.org/) functions were util here, the [`fct_lump()`](https://forcats.tidyverse.org/reference/fct_lump.html) used to collapse the least frequent values of a factor into “other” and [`fct_reorder()`](https://forcats.tidyverse.org/reference/fct_reorder.html) to reorder the factor `movie_rating` by another variable, in this case, the median (default function) of `movie_rating` itself. Doing this we can put the `movie_rating` in order on the chart.

Seems that there is a relationship between `movie_review` and `movie_rating`, how much?


```r
# Calculates the "anova" of Linear Regration between Rating and Review
horror_movies %>% 
  filter(!is.na(movie_rating)) %>% 
  mutate( movie_rating = fct_lump(movie_rating, 5) ) %>% 
  lm(review_rating ~ movie_rating, data=.) %>% 
  anova()
```

```
## Analysis of Variance Table
## 
## Response: review_rating
##                Df  Sum Sq Mean Sq F value    Pr(>F)    
## movie_rating    5   70.05 14.0092  9.1759 1.319e-08 ***
## Residuals    1424 2174.08  1.5267                      
## ---
## Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
```

Let's plot this in a better way.


```r
# plotting the mean and standard deviation of movie reviews
# for each movie rating
horror_movies %>% 
  filter(!is.na(movie_rating)) %>% 
  mutate( movie_rating = fct_lump(movie_rating, 5),
          movie_rating = fct_reorder(movie_rating, review_rating, na.rm=T) ) %>% 
  group_by(movie_rating) %>% 
  summarise(
    review_rating_mean = mean(review_rating, na.rm=T),
    review_rating_var  = var(review_rating, na.rm=T),
    review_rating_sd   = sd(review_rating, na.rm=T),
    review_rating_error = sqrt(review_rating_var/length(review_rating))
  ) %>% 
  ungroup() %>% 
  ggplot(aes(movie_rating, review_rating_mean)) +
  geom_point() +
  geom_errorbar(aes(ymin=review_rating_mean-review_rating_error, ymax=review_rating_mean+review_rating_error)) 
```

<img src="{{< blogdown/postref >}}index.en_files/figure-html/movie_x_review_better_plot-1.png" width="672" />

Is there genres better evaluated than others?


```r
horror_movies %>% 
  separate_rows(genres,sep="\\| ") %>% 
  filter(!is.na(genres)) %>% 
  mutate( genres = fct_lump(genres, 5)) %>% 
  ggplot(aes(genres, review_rating)) +
  geom_boxplot()
```

<img src="{{< blogdown/postref >}}index.en_files/figure-html/unnamed-chunk-1-1.png" width="672" />

There some preferences, but not too much difference.

#### Textual Analysis

Let's explore the `plot` field throught text analysis. Is there any word that influences the `review_rating`?


```r
library(tidytext) # to tokenize the plot text

# tokenize
horror_movies_unnested <- horror_movies %>% 
  # split tokens
  unnest_tokens(word, plot) %>% 
  # remove meaningless words
  anti_join(stop_words, by="word") %>% 
  filter(!is.na(word))

# lets check
horror_movies_unnested %>% 
  count(word, sort=T) %>% 
  head(10) %>% 
  kable()
```

<table>
 <thead>
  <tr>
   <th style="text-align:left;"> word </th>
   <th style="text-align:right;"> n </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> house </td>
   <td style="text-align:right;"> 318 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> friends </td>
   <td style="text-align:right;"> 313 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> life </td>
   <td style="text-align:right;"> 289 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> family </td>
   <td style="text-align:right;"> 271 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> night </td>
   <td style="text-align:right;"> 256 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> home </td>
   <td style="text-align:right;"> 254 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> woman </td>
   <td style="text-align:right;"> 244 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> horror </td>
   <td style="text-align:right;"> 241 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> mysterious </td>
   <td style="text-align:right;"> 234 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> town </td>
   <td style="text-align:right;"> 217 </td>
  </tr>
</tbody>
</table>

Visualizing `word` and the average of `review_rating`.


```r
# Visualizing word and the average of review_rating
horror_movies_unnested %>% 
  filter(!is.na(review_rating)) %>% 
  group_by(word) %>% 
  # by word, count and mean the review_rating
  summarise(
    movies=n(),
    avg_rating = mean(review_rating)
  ) %>% 
  arrange(desc(movies)) %>% 
  # words that appears in the plot of 100 or more movies only
  filter(movies>=100) %>%
  mutate(word=fct_reorder(word, avg_rating)) %>% 
  ggplot(aes(avg_rating, word)) +
  geom_point()
```

<img src="{{< blogdown/postref >}}index.en_files/figure-html/word_x_avg_rating-1.png" width="672" />

#### Lasso Regression for Predicting Review Rating on Words

Lasso stands for **Least Absolute Shrinkage Selector Operator**, it is a type of regression that allow you to regularize ("shrink") coefficients. This means that the estimated coefficients are pushed towards 0, to make them work better on new data-sets ("optimized for prediction"). This allows you to use complex models and avoid over-fitting at the same time.

You can learn details of this regressions on:

+ [A comprehensive beginners guide for Linear, Ridge and Lasso Regression in Python and R](https://www.analyticsvidhya.com/blog/2017/06/a-comprehensive-guide-for-linear-ridge-and-lasso-regression/) @ Analytics Vidhya Blog
+ [Regularization: Ridge, Lasso and Elastic Net](https://www.datacamp.com/community/tutorials/tutorial-ridge-lasso-elastic-net) @ Datacamp


```r
library(glmnet) # lasso
library(Matrix) # to handle sparse matrixes

# word sparse matrix
movie_word_matrix <- horror_movies_unnested %>% 
  filter(!is.na(review_rating)) %>% 
  add_count(word) %>% 
  # palavras que apareceram pelo menos 20 vezes
  filter(n>=20) %>% 
  count(title, word) %>% 
  # sparse matrix
  cast_sparse(title, word, n)

# let's see how many words are
dim(movie_word_matrix)
```

```
## [1] 2945  460
```

```r
# indexing review_rating by the word in the sparse matrix
rating <- horror_movies$review_rating[match(rownames(movie_word_matrix), horror_movies$title)]

# fitting the LASSO model
lasso_model <- cv.glmnet(movie_word_matrix, rating)
```

Let's see the characteristics of the fitted model.


```r
library(broom)

# lets see how the coeficient shrink for some "popular" terms
# conform the "lambda" term rises
tidy(lasso_model$glmnet.fit) %>% 
  filter(term %in% c("friends","evil", "college", "haunted", "mother", "life",
                     "woods","discover","abandoned", "woods")) %>% 
  ggplot(aes(lambda, estimate, color=term)) +
  geom_line() +
  scale_x_log10() +
  geom_hline(yintercept = 0, lty=2)
```

<img src="{{< blogdown/postref >}}index.en_files/figure-html/checkingTheModel-1.png" width="672" />

```r
# we are able to visualize the CV performance 
# in function of lambda parameter
plot(lasso_model)
```

<img src="{{< blogdown/postref >}}index.en_files/figure-html/checkingTheModel-2.png" width="672" />

```r
# the model give us the lambda for optimal performance
# (min square feet error)
log(lasso_model$lambda.min)
```

```
## [1] -3.051995
```

```r
# at that lambda level, let's see how each term
# weighted in the model
tidy(lasso_model$glmnet.fit) %>% 
  filter(lambda==lasso_model$lambda.min, 
         term != "(Intercept)") %>% 
  mutate( term = fct_reorder(term, estimate) ) %>% 
  ggplot(aes(term, estimate)) +
  geom_col() +
  coord_flip()
```

<img src="{{< blogdown/postref >}}index.en_files/figure-html/checkingTheModel-3.png" width="672" />

```r
# Let's see how the extrem terms shrink
# acording lambda
tidy(lasso_model$glmnet.fit) %>% 
  filter(
    term %in% c(
      "seek","quick","military","army", "teacher", "unexpected", "suddenly", # extremes
      "boy","move","mother","chris","virus","souls","hunters"  # intermediary
  )) %>% 
  ggplot(aes(lambda, estimate, color=term)) +
  geom_vline(xintercept=lasso_model$lambda.min) +
  geom_line() +
  scale_x_log10() +
  geom_hline(yintercept = 0, lty=2)
```

<img src="{{< blogdown/postref >}}index.en_files/figure-html/checkingTheModel-4.png" width="672" />

#### Lasso for words and other features

Throwing everthing into a linear model: director, cast, genre, rating, plot and words. David did a "generic" feature generator where he puts in the word sparse matrix other features as "words", see the code.


```r
# this is a generic feature generator
features <- horror_movies %>% 
  filter(!is.na(review_rating)) %>% 
  # features to be added
  select(title, genres, director, cast, movie_rating, language, release_country) %>% 
  # clean director column
  mutate( director = str_remove(director, "Directed by ")) %>% 
  # transform the info into a key value pair for each movie title
  # the type is the feature "column"
  gather(type, value, -title) %>% 
  filter(!is.na(value)) %>% 
  # if value field has more than one value (like genres) slip in multiple lines
  separate_rows(value, sep="\\| ?") %>% 
  # colapse two columns (type and values) in to column feature
  unite(feature, type, value, sep=": ") %>% 
  mutate(n=1)

movie_feature_matrix <- horror_movies_unnested %>% 
  filter(!is.na(review_rating)) %>% 
  count(title, feature=paste0("word: ", word)) %>%
  bind_rows(features) %>% 
  add_count(feature) %>% 
  filter( n>=5 ) %>% 
  cast_sparse(title, feature)
    
dim(movie_feature_matrix)
```

```
## [1] 4 4
```

With the steps to transform the feature columns in a *"key-value pair* an then colapse them into a *"feature-word"*, allow you add and remove features simply changing the `select` statement in the code above. David uses the convenient [`tidyr::unite()`](https://tidyr.tidyverse.org/reference/unite.html) function to do the concatenation between two columns.


```r
# indexing movie_rating by feature name matrix
rating <- horror_movies$review_rating[match(rownames(movie_feature_matrix), horror_movies$title)]

# new model
feature_lasso_model <- cv.glmnet(movie_feature_matrix, rating)
plot(feature_lasso_model)
```

<img src="{{< blogdown/postref >}}index.en_files/figure-html/newLassoModel-1.png" width="672" />

Let's see what are the most influent features in the lasso regression, but at this time, we'll see the coenficients at another level than minimal cross validation erro.

In the lasso model object, `lambda.min` is the value of *lambda* that gives **minimum mean cross-validated error**. The other parameter saved is `lambda.1se`, which gives the **most regularized model** such that error is within *one standard error of the minimum*. 

To use that, we only need to replace `lambda.min` with `lambda.1se`.


```r
# extracting the model coeficients
tidy(feature_lasso_model$glmnet.fit) %>% 
  # at lambda.1se level
  filter(lambda==feature_lasso_model$lambda.1se, 
         term != "(Intercept)") %>% 
  mutate( term = fct_reorder(term, estimate) ) %>% 
  ggplot(aes(term, estimate)) +
  geom_col() +
  coord_flip() +
  labs(x="", y="Coefficent for predicting horror movie ratings",
       title="What affects a horror movie rating?",
       subtitle = "Based on a lasso regression to predict IMDb ratings of ~3000 movies")
```

<img src="{{< blogdown/postref >}}index.en_files/figure-html/featureRank-1.png" width="672" />

#### What am I going to watch?

The end this analysis, let's do a simple query to see what horror movie we could watch.


```r
# lets take the dataset
horror_movies %>% 
  filter(
    # selecting a horror movie that is also a commedy
    str_detect(genres, "Comedy"),
    !is.na(movie_rating), 
    !is.na(budget), 
    movie_rating != "PG" 
  ) %>% 
  arrange(desc(review_rating)) %>% 
  select(title, review_rating, plot, director, budget, language) %>% 
  head(5) %>% 
  kable() %>% 
  kable_styling(font_size = 10)
```

<table class="table" style="font-size: 10px; margin-left: auto; margin-right: auto;">
 <thead>
  <tr>
   <th style="text-align:left;"> title </th>
   <th style="text-align:right;"> review_rating </th>
   <th style="text-align:left;"> plot </th>
   <th style="text-align:left;"> director </th>
   <th style="text-align:right;"> budget </th>
   <th style="text-align:left;"> language </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> What We Do in the Shadows (2014) </td>
   <td style="text-align:right;"> 7.6 </td>
   <td style="text-align:left;"> A documentary team films the lives of a group of vampires for a few months. The vampires share a house in Wellington, New Zealand. Turns out vampires have their own domestic problems too. </td>
   <td style="text-align:left;"> Directed by Jemaine Clement, Taika Waititi </td>
   <td style="text-align:right;"> 1600000 </td>
   <td style="text-align:left;"> English|German|Spanish </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Only Lovers Left Alive (2013) </td>
   <td style="text-align:right;"> 7.3 </td>
   <td style="text-align:left;"> A depressed musician reunites with his lover. Though their romance, which has already endured several centuries, is disrupted by the arrival of her uncontrollable younger sister. </td>
   <td style="text-align:left;"> Directed by Jim Jarmusch </td>
   <td style="text-align:right;"> 7000000 </td>
   <td style="text-align:left;"> English|French|Arabic|Turkish </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Holla II (2013) </td>
   <td style="text-align:right;"> 6.9 </td>
   <td style="text-align:left;"> With Vanessa Bell Calloway, Kiely Williams, Greg Cipes, Trae Ireland. After narrowly escaping with her life at the hands of her mentally ill sister Veronica, Monica, with the help of her Mother, Marion, has taken great measures to ensure her safety, including changing her face and relocating to the South. Six years has past and now she finally believes she is safe from Veronica. Little does she know that death and betrayal still await her and her friends on the eve... </td>
   <td style="text-align:left;"> Directed by H.M </td>
   <td style="text-align:right;"> 1000000 </td>
   <td style="text-align:left;"> English </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Wild Men (2017) </td>
   <td style="text-align:right;"> 6.9 </td>
   <td style="text-align:left;"> The inept cast and crew of a surprise hit reality-TV show travel deep into the Adirondack mountains for their second season to find proof that Bigfoot exists. Any remaining skepticism they have is ripped to pieces. </td>
   <td style="text-align:left;"> Directed by Bobby Sansivero </td>
   <td style="text-align:right;"> 97948 </td>
   <td style="text-align:left;"> English </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Night Terrors (2014) </td>
   <td style="text-align:right;"> 6.9 </td>
   <td style="text-align:left;"> A devious older sister fills her brother's head with bizarre tales of terror, blood soaked memories, and nightmares of perversion after finding out that she has to babysit and miss the party. </td>
   <td style="text-align:left;"> Directed by Alex Lukens, Jason Zink </td>
   <td style="text-align:right;"> 5000 </td>
   <td style="text-align:left;"> English </td>
  </tr>
</tbody>
</table>

### Pizza Ratings

In the last [#TidyTuesday](https://github.com/rfordatascience/tidytuesday) analysis in this post, we'll analyze a dataset of pizza ratings, just for fun and because everybody likes pizza. :)

<!-- tweet --> 
<blockquote class="twitter-tweet"><p lang="en" dir="ltr">In this <a href="https://twitter.com/hashtag/tidytuesday?src=hash&amp;ref_src=twsrc%5Etfw">#tidytuesday</a> screencast, I analyze a dataset of pizza ratings and discover the best and worse 🍕 in NYC and other cities 📊 <a href="https://t.co/ldUUzsV6MU">https://t.co/ldUUzsV6MU</a> <a href="https://twitter.com/hashtag/rstats?src=hash&amp;ref_src=twsrc%5Etfw">#rstats</a> <a href="https://t.co/nPth3hqdnS">pic.twitter.com/nPth3hqdnS</a></p>&mdash; David Robinson (@drob) <a href="https://twitter.com/drob/status/1179080465162145792?ref_src=twsrc%5Etfw">October 1, 2019</a></blockquote> <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>
<!-- tweet --> 

{{< tweet 1179080465162145792 >}}

The pizza evaluation datasets are available in the [GitHub's TidyTueday Repo](https://github.com/rfordatascience/tidytuesday/tree/master/data/2019/2019-10-01) there are three different data sources, let's see explore one of them.


```r
# getting data from github
pizza_jared <- readr::read_csv("https://raw.githubusercontent.com/rfordatascience/tidytuesday/master/data/2019/2019-10-01/pizza_jared.csv")

# overal look
pizza_jared %>% 
  head(10) %>% 
  kable() %>% 
  kable_styling(font_size = 11)
```

<table class="table" style="font-size: 11px; margin-left: auto; margin-right: auto;">
 <thead>
  <tr>
   <th style="text-align:right;"> polla_qid </th>
   <th style="text-align:left;"> answer </th>
   <th style="text-align:right;"> votes </th>
   <th style="text-align:right;"> pollq_id </th>
   <th style="text-align:left;"> question </th>
   <th style="text-align:left;"> place </th>
   <th style="text-align:right;"> time </th>
   <th style="text-align:right;"> total_votes </th>
   <th style="text-align:right;"> percent </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> Excellent </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> How was Pizza Mercato? </td>
   <td style="text-align:left;"> Pizza Mercato </td>
   <td style="text-align:right;"> 1344361527 </td>
   <td style="text-align:right;"> 13 </td>
   <td style="text-align:right;"> 0.0000 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> Good </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> How was Pizza Mercato? </td>
   <td style="text-align:left;"> Pizza Mercato </td>
   <td style="text-align:right;"> 1344361527 </td>
   <td style="text-align:right;"> 13 </td>
   <td style="text-align:right;"> 0.4615 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> Average </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> How was Pizza Mercato? </td>
   <td style="text-align:left;"> Pizza Mercato </td>
   <td style="text-align:right;"> 1344361527 </td>
   <td style="text-align:right;"> 13 </td>
   <td style="text-align:right;"> 0.3077 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> Poor </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> How was Pizza Mercato? </td>
   <td style="text-align:left;"> Pizza Mercato </td>
   <td style="text-align:right;"> 1344361527 </td>
   <td style="text-align:right;"> 13 </td>
   <td style="text-align:right;"> 0.0769 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> Never Again </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> How was Pizza Mercato? </td>
   <td style="text-align:left;"> Pizza Mercato </td>
   <td style="text-align:right;"> 1344361527 </td>
   <td style="text-align:right;"> 13 </td>
   <td style="text-align:right;"> 0.1538 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> Excellent </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> How was Maffei's Pizza? </td>
   <td style="text-align:left;"> Maffei's Pizza </td>
   <td style="text-align:right;"> 1348120800 </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:right;"> 0.1429 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> Good </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> How was Maffei's Pizza? </td>
   <td style="text-align:left;"> Maffei's Pizza </td>
   <td style="text-align:right;"> 1348120800 </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:right;"> 0.1429 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> Average </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> How was Maffei's Pizza? </td>
   <td style="text-align:left;"> Maffei's Pizza </td>
   <td style="text-align:right;"> 1348120800 </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:right;"> 0.4286 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> Poor </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> How was Maffei's Pizza? </td>
   <td style="text-align:left;"> Maffei's Pizza </td>
   <td style="text-align:right;"> 1348120800 </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:right;"> 0.1429 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> Never Again </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> How was Maffei's Pizza? </td>
   <td style="text-align:left;"> Maffei's Pizza </td>
   <td style="text-align:right;"> 1348120800 </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:right;"> 0.1429 </td>
  </tr>
</tbody>
</table>

#### Simple EDA

Let's look the distribution of answers by place


```r
answer_order <- c("Never Again","Poor", "Average", "Good","Excellent")

by_place_answer <- pizza_jared %>% 
  mutate( time = as.POSIXct(time, origin="1970-01-01"),
          date = as.Date(time),
          answer = fct_relevel(answer, answer_order)) %>% 
  group_by(place, answer) %>% 
  summarise(votes=sum(votes)) %>% 
  mutate(total = sum(votes)) %>% 
  mutate(percent = votes/total,
         answer_integer = as.integer(answer),
         average=sum(answer_integer*percent)) %>% 
  ungroup()

by_place_answer %>% 
  head(10) %>% 
  kable() %>% 
  kable_styling(font_size = 10)
```

<table class="table" style="font-size: 10px; margin-left: auto; margin-right: auto;">
 <thead>
  <tr>
   <th style="text-align:left;"> place </th>
   <th style="text-align:left;"> answer </th>
   <th style="text-align:right;"> votes </th>
   <th style="text-align:right;"> total </th>
   <th style="text-align:right;"> percent </th>
   <th style="text-align:right;"> answer_integer </th>
   <th style="text-align:right;"> average </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> 5 Boroughs Pizza </td>
   <td style="text-align:left;"> Never Again </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:right;"> 0.0000000 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 3.666667 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 5 Boroughs Pizza </td>
   <td style="text-align:left;"> Poor </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:right;"> 0.0000000 </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:right;"> 3.666667 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 5 Boroughs Pizza </td>
   <td style="text-align:left;"> Average </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:right;"> 0.6666667 </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:right;"> 3.666667 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 5 Boroughs Pizza </td>
   <td style="text-align:left;"> Good </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:right;"> 0.0000000 </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:right;"> 3.666667 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 5 Boroughs Pizza </td>
   <td style="text-align:left;"> Excellent </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:right;"> 0.3333333 </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:right;"> 3.666667 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Artichoke Basille's Pizza </td>
   <td style="text-align:left;"> Never Again </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 10 </td>
   <td style="text-align:right;"> 0.0000000 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 4.100000 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Artichoke Basille's Pizza </td>
   <td style="text-align:left;"> Poor </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 10 </td>
   <td style="text-align:right;"> 0.1000000 </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:right;"> 4.100000 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Artichoke Basille's Pizza </td>
   <td style="text-align:left;"> Average </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 10 </td>
   <td style="text-align:right;"> 0.1000000 </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:right;"> 4.100000 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Artichoke Basille's Pizza </td>
   <td style="text-align:left;"> Good </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:right;"> 10 </td>
   <td style="text-align:right;"> 0.4000000 </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:right;"> 4.100000 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Artichoke Basille's Pizza </td>
   <td style="text-align:left;"> Excellent </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:right;"> 10 </td>
   <td style="text-align:right;"> 0.4000000 </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:right;"> 4.100000 </td>
  </tr>
</tbody>
</table>

```r
# by place
by_place_answer %>% 
  # with at least 29 evaluations (cabalistic number to show 9 facets!)
  filter(total >= 29) %>% 
  # controls the order of the facets (worst->better)
  mutate(place = fct_reorder(place, average)) %>%  
  ggplot(aes(answer, percent)) +
  geom_col() +
  facet_wrap(~place) +
  theme(axis.text.x=element_text(angle=90, hjust = 1)) +
  labs(x="", y="",
       title="What is the most popular pizza place in Open Stats meetup?",
       subtitle="Only the 9 pizza places with the most respondents")
```

<img src="{{< blogdown/postref >}}index.en_files/figure-html/visualizingAnswersByPlace-1.png" width="672" />

David apply a trick to control the number of places that will be show in the plot.


```r
by_place_answer %>% 
  # trick to choose "top N"
  # reorder by total de votes in reverse order
  # convert to integer and get "rank" <= N
  filter(as.integer(fct_reorder(place, total, .desc = T))<=16,
         answer!="Fair") %>% # there just one vote with answer 'fair'
  mutate(place = glue("{place} ({total})"), # number of samples
         place = fct_reorder(place, average)) %>% 
  ggplot(aes(answer, percent)) +
  geom_col() +
  facet_wrap(~place) +
  theme(axis.text.x=element_text(angle=90, hjust = 1)) +
  labs(x="", y="",
       title="What is the most popular pizza place in Open Stats meetup?",
       subtitle="Only the 16 pizza places with the most respondents")
```

<img src="{{< blogdown/postref >}}index.en_files/figure-html/bestPlacesFirst-1.png" width="672" />

#### Where is the best places?

Now we'll plot the evaluations of each place but also plot the confidence interval of each evaluation. First we build an auxiliary function to use with our dataset that sums each answer by place.


```r
# generate a sample from 'x' with each 'frequency'
# then apply a t.test
t_test_repeated <- function(x,frequency){
  tidy(t.test(rep(x,frequency)))
}

# check
t_test_repeated(c(1,2,3,4,5),c(5,10,100,50,30))
```

```
## # A tibble: 1 x 8
##   estimate statistic   p.value parameter conf.low conf.high method   alternative
##      <dbl>     <dbl>     <dbl>     <dbl>    <dbl>     <dbl> <chr>    <chr>      
## 1     3.46      53.5 4.45e-118       194     3.33      3.59 One Sam~ two.sided
```



```r
# ploting the values
by_place_answer %>% 
  # pelo menos cinco votos
  filter(total>=5) %>% 
  # por local
  group_by(place, total) %>% 
  # apply t.test in the answers
  # look that the column answer an votes, grouped by place, are "vectors"
  summarise(t_test_result=list(t_test_repeated(answer_integer, votes))) %>% 
  ungroup() %>% 
  unnest(t_test_result) %>% 
  select(place, total, average=estimate, low=conf.low, high=conf.high) %>% 
  mutate(place = glue("{place} ({total})"), # number of samples
         place=fct_reorder(place, average)) %>% 
  top_n(16,total) %>% 
  ggplot(aes(average, place)) +
  geom_point(aes(size=total)) +
  geom_errorbarh(aes(xmin=low, xmax=high)) +
  labs(x="Average score (1-5 Likert Scale)",
       y="",
       title="What is the most popular pizza place in Open Stats meetup?",
       subtitle = "Only the 16 pizza places with the most respondents",
       size="Respondents")
```

<img src="{{< blogdown/postref >}}index.en_files/figure-html/plotAnswerAndCI-1.png" width="672" />

```r
by_place <- by_place_answer %>% 
  distinct(place, total, average)
```

#### Barstool Sports Dataset

Now, let's look another dataset, from [Barstool Sports](https://www.barstoolsports.com/).


```r
# reading from github
pizza_barstool <- readr::read_csv("https://raw.githubusercontent.com/rfordatascience/tidytuesday/master/data/2019/2019-10-01/pizza_barstool.csv")

pizza_barstool %>% 
  glimpse()
```

```
## Rows: 463
## Columns: 22
## $ name                                 <chr> "Pugsley's Pizza", "Williamsburg ~
## $ address1                             <chr> "590 E 191st St", "265 Union Ave"~
## $ city                                 <chr> "Bronx", "Brooklyn", "New York", ~
## $ zip                                  <dbl> 10458, 11211, 10017, 10036, 10003~
## $ country                              <chr> "US", "US", "US", "US", "US", "US~
## $ latitude                             <dbl> 40.85877, 40.70808, 40.75370, 40.~
## $ longitude                            <dbl> -73.88484, -73.95090, -73.97411, ~
## $ price_level                          <dbl> 1, 1, 1, 2, 2, 1, 1, 1, 2, 2, 1, ~
## $ provider_rating                      <dbl> 4.5, 3.0, 4.0, 4.0, 3.0, 3.5, 3.0~
## $ provider_review_count                <dbl> 121, 281, 118, 1055, 143, 28, 95,~
## $ review_stats_all_average_score       <dbl> 8.011111, 7.774074, 5.666667, 5.6~
## $ review_stats_all_count               <dbl> 27, 27, 9, 2, 1, 4, 5, 17, 14, 6,~
## $ review_stats_all_total_score         <dbl> 216.3, 209.9, 51.0, 11.2, 7.1, 16~
## $ review_stats_community_average_score <dbl> 7.992000, 7.742308, 5.762500, 0.0~
## $ review_stats_community_count         <dbl> 25, 26, 8, 0, 0, 3, 4, 16, 13, 4,~
## $ review_stats_community_total_score   <dbl> 199.8, 201.3, 46.1, 0.0, 0.0, 13.~
## $ review_stats_critic_average_score    <dbl> 8.8, 0.0, 0.0, 4.3, 0.0, 0.0, 0.0~
## $ review_stats_critic_count            <dbl> 1, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, ~
## $ review_stats_critic_total_score      <dbl> 8.8, 0.0, 0.0, 4.3, 0.0, 0.0, 0.0~
## $ review_stats_dave_average_score      <dbl> 7.7, 8.6, 4.9, 6.9, 7.1, 3.2, 6.1~
## $ review_stats_dave_count              <dbl> 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, ~
## $ review_stats_dave_total_score        <dbl> 7.7, 8.6, 4.9, 6.9, 7.1, 3.2, 6.1~
```

#### Basic EDA

Do higher price place makes better evaluated pizzas?


```r
# from places with more than 50 evaluations
pizza_barstool %>% 
  top_n(50, review_stats_all_count) %>% 
  # plot price level vs review
  ggplot(aes(price_level, review_stats_all_average_score, group=price_level)) +
  geom_boxplot()
```

<img src="{{< blogdown/postref >}}index.en_files/figure-html/pizzaPriceScore-1.png" width="672" />

What are the places with best pizzas?


```r
# from places with more than 50 evaluations
pizza_barstool %>% 
  filter(review_stats_all_count>=50) %>% 
  mutate(name = fct_reorder(name, review_stats_all_average_score)) %>% 
  ggplot(aes(review_stats_all_average_score, name, size=review_stats_all_count)) +
  geom_point() +
  labs(x="Average rating", size="# of review", y="",
       title="Barstool Sports ratings of pizza places",
       subtitle = "only places with at least 50 reviews")
```

<img src="{{< blogdown/postref >}}index.en_files/figure-html/barstoolEDA-1.png" width="672" />

Where are these places?


```r
# What places have best pizzas?
pizza_barstool %>%
  filter( review_stats_all_count >= 20 ) %>% 
  # by city
  add_count(city) %>% 
  # cities with at least 6 places
  filter(n>=6) %>% 
  mutate( city = glue("{city} ({n})") ) %>% 
  ggplot(aes(city, review_stats_all_average_score)) +
  geom_boxplot() +
  labs(subtitle = "Only pizza places with at least 20 reviews", y="review", x="")
```

<img src="{{< blogdown/postref >}}index.en_files/figure-html/pizzaCitie-1.png" width="672" />

Brooklyn has the best pizzas!

#### Comparing Reviews

The dataset has two kinds of pizza evaluation, let's check the differences.


```r
# select the reviews
pizza_barstool %>% 
  select(place=name,
         price_level, 
         contains("review")) %>% 
  rename_all(~str_remove(., "review_stats_")) %>% 
  select(-contains("provider")) %>% 
  select(contains("count")) %>% 
  gather(key, value) %>% 
  ggplot(aes(value)) +
  geom_histogram() +
  facet_wrap(~key)
```

<img src="{{< blogdown/postref >}}index.en_files/figure-html/unnamed-chunk-2-1.png" width="672" />

Does Barstool Sports' Dave agree with the critics?


```r
#  taking the name, price and reviews
pizza_cleaned <- pizza_barstool %>% 
  select(place=name,
         price_level, 
         contains("review")) %>% 
  # cleaning column names
  rename_all(~str_remove(., "review_stats_")) %>% 
  select(-contains("provider"))

# ploting Daves x Critics
pizza_cleaned %>% 
  filter(critic_count>0) %>% 
  ggplot(aes(critic_average_score, dave_average_score)) +
  geom_point() +
  geom_abline(color="red", linetype="dashed") + # reference line
  geom_smooth(method = "lm") +
  labs(x="Critic average score", y="Dave score", 
       title="Does Barstool Sports' Dave agree with the critics?")
```

<img src="{{< blogdown/postref >}}index.en_files/figure-html/daveVsCritics-1.png" width="672" />

In overal the evaluations has some correlation. Let's see Community vs Critics


```r
pizza_cleaned %>% 
  filter( community_count >=20,
          critic_count > 0) %>% 
  ggplot(aes(critic_average_score, community_average_score)) +
  geom_point() +
  geom_abline(color="red") +
  geom_smooth(method="lm")
```

<img src="{{< blogdown/postref >}}index.en_files/figure-html/communityVsCritics-1.png" width="672" />

That is very bad, and Dave vs. Critics?


```r
pizza_cleaned %>% 
  filter( community_count >=20 ) %>% 
  ggplot(aes(community_average_score, dave_average_score)) +
  geom_point(aes( size=community_count)) +
  geom_abline(color="red", linetype="dashed") +
  geom_smooth(method="lm") +
  labs(size="# of community reviews", x="community score", y="Dave score")
```

<img src="{{< blogdown/postref >}}index.en_files/figure-html/unnamed-chunk-3-1.png" width="672" />

Dave score are remarkable close to the community reviews.
