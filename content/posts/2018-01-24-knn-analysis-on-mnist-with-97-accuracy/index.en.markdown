---
title: kNN Analysis on MNIST with 97% accuracy
author: Giuliano Sposito
date: '2018-01-24'
slug: 'knn-analysis-on-mnist-with-97-accuracy'
categories:
  - data science
tags:
  - rstats
  - mnist
  - knn
  - pca
subtitle: ''
lastmod: '2021-11-03T20:20:41-03:00'
authorLink: ''
description: ''
hiddenFromHomePage: no
hiddenFromSearch: no
featuredImage: 'images/cover.jpg'
featuredImagePreview: 'images/cover.jpg'
toc:
  enable: yes
math:
  enable: no
lightgallery: no
license: ''
disqusIdentifier: 'knn-analysis-on-mnist-with-97-accuracy'
---

<script src="{{< blogdown/postref >}}index.en_files/htmlwidgets/htmlwidgets.js"></script>
<script src="{{< blogdown/postref >}}index.en_files/plotly-binding/plotly.js"></script>
<script src="{{< blogdown/postref >}}index.en_files/typedarray/typedarray.min.js"></script>
<script src="{{< blogdown/postref >}}index.en_files/jquery/jquery.min.js"></script>
<link href="{{< blogdown/postref >}}index.en_files/crosstalk/css/crosstalk.css" rel="stylesheet" />
<script src="{{< blogdown/postref >}}index.en_files/crosstalk/js/crosstalk.min.js"></script>
<link href="{{< blogdown/postref >}}index.en_files/plotly-htmlwidgets-css/plotly-htmlwidgets.css" rel="stylesheet" />
<script src="{{< blogdown/postref >}}index.en_files/plotly-main/plotly-latest.min.js"></script>

Usually Yann LeCun’s [MNIST database](http://yann.lecun.com/exdb/mnist/index.html) is used to explore [Artificial Neural Network](https://en.wikipedia.org/wiki/Artificial_neural_network) architectures for image recognition problem.

In the [last post](/2018/01/implementing-lenet-with-mxnet-in-r/) the use of a ANN (LeNet architecture) implemented using mxnet to resolve this classification problem.

But in this post, we’ll see that the MNIST problem isn’t a difficult one, only resolved by ANNs, analyzing the data set we can see that is possible, with a high degree of precision, resolving this classification problem with a simple [k-nearest neighbors algorithm](https://en.wikipedia.org/wiki/K-nearest_neighbors_algorithm).

<!--more-->

    # setup
    library(tidyverse)  # for plot and data manipulation
    library(factoextra) # to plot PCA values
    library(plotly)     # 3D interactive plots
    library(class)      # KNN algorithm
    library(caret)      # Near Zero Var removing

### MNist Dataset

Download all four data set files from [MNIST site](http://yann.lecun.com/exdb/mnist/) and gunzip them in the project directory.

The default MNIST data set is somewhat inconveniently formatted, but we use an adaptation of [gist from Brendan o’Connor](http://gist.github.com/39760) to read the files transforming them in a structure simple to use and access.

    ### load database

    # read function returns a list of datasets
    load_mnist <- function() {
      load_image_file <- function(filename) {
        ret = list()
        f = file(filename,'rb')
        readBin(f,'integer',n=1,size=4,endian='big')
        ret$n = readBin(f,'integer',n=1,size=4,endian='big')
        nrow = readBin(f,'integer',n=1,size=4,endian='big')
        ncol = readBin(f,'integer',n=1,size=4,endian='big')
        x = readBin(f,'integer',n=ret$n*nrow*ncol,size=1,signed=F)
        ret$x = matrix(x, ncol=nrow*ncol, byrow=T)
        close(f)
        ret
      }
      load_label_file <- function(filename) {
        f = file(filename,'rb')
        readBin(f,'integer',n=1,size=4,endian='big')
        n = readBin(f,'integer',n=1,size=4,endian='big')
        y = readBin(f,'integer',n=n,size=1,signed=F)
        close(f)
        y
      }
      train <- load_image_file('./data/train-images.idx3-ubyte')
      test <- load_image_file('./data/t10k-images.idx3-ubyte')
      
      train$y <- load_label_file('./data/train-labels.idx1-ubyte')
      test$y <- load_label_file('./data/t10k-labels.idx1-ubyte')  
      
      return(
        list(
          train = train,
          test = test
        )
      )
    }

    # load in 'mnist' var
    mnist <- load_mnist()

    # look the data format
    str(mnist)

    ## List of 2
    ##  $ train:List of 3
    ##   ..$ n: int 60000
    ##   ..$ x: int [1:60000, 1:784] 0 0 0 0 0 0 0 0 0 0 ...
    ##   ..$ y: int [1:60000] 5 0 4 1 9 2 1 3 1 4 ...
    ##  $ test :List of 3
    ##   ..$ n: int 10000
    ##   ..$ x: int [1:10000, 1:784] 0 0 0 0 0 0 0 0 0 0 ...
    ##   ..$ y: int [1:10000] 7 2 1 0 4 1 4 9 5 9 ...

The gist read the binary MNIST files and returns a convenient list for training cases and test cases, each with size (n), the pixels (x) and the labels (y).

Let’s see some of the images represented in the `x` variable.

    # functino plot one case digit (by 1d array of 784 pixels)
    show_digit <- function(arr784, col=gray(25:1/25), ...) {
      image(matrix(arr784, nrow=28)[,28:1], col=col, ...)
    }

    # showing first 25 cases
    labels <- paste(mnist$train$y[1:25],collapse = ", ")
    par(mfrow=c(5,5), mar=c(0.1,0.1,0.1,0.1))
    for(i in 1:25) show_digit(mnist$train$x[i,], axes=F)

<img src="{{< blogdown/postref >}}index.en_files/figure-html/plotDatabase-1.png" width="672" />

Each line in `x` var is a digit case, and each column represents the intensity of a pixel in a `28 x 28` image.

### Data Analysis

How the each pixels in the image behavior in the “average” for each digit? It’s possible to use this information to classify an digit?

#### Centroid

    # calc digits centroids
    centroids <- list()
    for(i in 0:9) {
      x <- mnist$train$x[(mnist$train$y == i),]
      centroids[[i+1]] <- colMeans(x) 
    }

    # ploting the centroids
    par(mfrow=c(2,5), mar=c(0.1,0.1,0.1,0.1))
    res <- lapply(X = centroids, show_digit, xaxt='n', yaxt='n')

<img src="{{< blogdown/postref >}}index.en_files/figure-html/calcCentroids-1.png" width="672" />

These averaged images are called centroids. We’re treating each image as a 784-dimensional point (28 by 28), and then taking the average of all points in each dimension individually.

We see that each centroid has a good representation of a digit, so each image in the data set are centralized in the image and there is not large variations. Maybe we can use one elementary machine learning method: **nearest centroid classifier**, would ask for each image which of these centroids it comes closest to.[^1]

#### Compare Centroids

How different one centroid is from other? We can simply take the difference between the pixel values for each digit pair like this:

    # compare cases
    compare <- tidyr::crossing(comp1 = 0:9, comp2 = 0:9)

    # calc features differences between the centroids
    res <- apply(compare, 1, function(x,m=centroids){
      unlist(m[x[1]+1]) - unlist(m[x[2]+1])
    }) %>% t() %>% as_tibble()

    centroids_diff <- bind_cols(compare, res)

    # plot them
    par(mfrow=c(10,10), mar=c(0,0,0,0))
    colFunc <- colorRampPalette(c("red","white","blue"))
    res <- sapply(1:100, FUN=function(x) show_digit(as.matrix(centroids_diff[x,3:786]),
                                                    col=colFunc(35),
                                                    axes=F))

<img src="{{< blogdown/postref >}}index.en_files/figure-html/compCentroids-1.png" width="672" />

From the image we can see some “patterns” emerging from this. As higher are stains in this image more separable a digit from another is. We look particularly for `0` and `1` digits are strongly separable. But in fade images we have a problem, because the pixels are not ‘that’ different from one digit from other, like `4` x `9` and `3` x `8`.

#### Distance

We can “measure” this difference, taking each pixel as a dimensions in the digit represent space and apply a simple *euclidian distance* between these data.

    # calculating the distance between the centroids in 786 dimensions
    dist <- apply(compare,1,function(x,m=centroids){
      sqrt(mean((unlist(m[x[1]+1])-unlist(m[x[2]+1]))^2))  
    }) %>% as_tibble()
    centroids_dist <- bind_cols(compare,dist)

    # ploting the distances
    ggplot(centroids_dist, aes(x=comp1, y=comp2, fill=value)) +
      geom_tile() + 
      geom_text(aes(label=round(value))) +
      scale_fill_gradient2(low = "blue", high = "red") +
      scale_x_continuous(breaks=0:9) + 
      scale_y_continuous(breaks=0:9) + 
      ylab("") + xlab("") + 
      theme_bw()

<img src="{{< blogdown/postref >}}index.en_files/figure-html/distance-1.png" width="672" />

The distance here, measures the degree of “difference” between the centroids, and this matrix bring us a coll view, look at `0`x`1` how distance they are (69), making them easier to classify. Look at `4`x`9`, they are more next (23), let’s compare this with the [confusion matrix](https://en.wikipedia.org/wiki/Confusion_matrix) generated by the LeNet ANN from the [last post](/2018/01/implementing-lenet-with-mxnet-in-r/):

    ##           Reference
    ## Prediction    0    1    2    3    4    5    6    7    8    9
    ##          0  974    0    1    0    0    2    3    0    2    0
    ##          1    1 1131    0    0    0    0    2    2    0    0
    ##          2    0    0 1025    1    1    0    0    2    0    0
    ##          3    0    0    0 1000    0    5    1    1    1    2
    ##          4    0    0    1    0  970    0    0    1    0    6
    ##          5    1    0    0    6    0  878    4    0    2    2
    ##          6    3    2    1    0    1    2  947    0    0    1
    ##          7    1    0    2    0    0    0    0 1016    0    3
    ##          8    0    2    2    3    0    4    1    1  966    1
    ##          9    0    0    0    0   10    1    0    5    3  994

We see the 16 mismatches involving cases `4`x`9`, the largest.

### Principal Component Analysis

We can improve this, it’s not all the pixels that have the same importance in the digit differentiation, some pixels (in the image borders, for example) don’t change its value along the data set and some pixels change very few from one digit to other. We transform the data sets to evidence the first removing the *zero variance* pixels and the second using [Principal component Analysis](https://en.wikipedia.org/wiki/Principal_component_analysis) or PCA.

    # transforming in a matrix
    tr.x <- mnist$train$x
    ts.x <- mnist$test$x
    all.x <- rbind(tr.x,ts.x)

    # calculating the PCA

    # removing zero or near zero variance features
    nzv <- nearZeroVar(all.x, saveMetrics = T)
    all.x <- all.x[,!nzv$zeroVar]

    # principal component analysis
    pca <- prcomp(all.x, center = T)
    saveRDS(pca, "pca.rds") # store to save time in the future
    print(paste0("Columns with zero variance: ", sum(nzv$zeroVar)))

    ## [1] "Columns with zero variance: 65"

#### Principal Componets

This is the classic view of the first 10 principal components, they explain 49% of total variance of data set.

    # principals component
    fviz_eig(pca)

<img src="{{< blogdown/postref >}}index.en_files/figure-html/principalComponents-1.png" width="672" />

#### Distribution of variance

Indeed, we see that the majority of the dimensions has near zero variance and few pixels explain a lot.

    # rebuilding features (transformed)
    tr.x <- pca$x[(1:mnist$train$n),]
    ts.x <- pca$x[(mnist$train$n+1):(mnist$train$n+mnist$test$n),]

    vars <- apply(pca$x, 2, var)  
    props <- vars / sum(vars)

    # distribuicao da % de sdev por
    # res <- dev.off() # reset plot parameters
    hist(props, breaks = 100, col="Red")

<img src="{{< blogdown/postref >}}index.en_files/figure-html/varianceDistribution-1.png" width="672" />

#### Cumulative Variance

Let’s see how much dimension of the PCA we need to consider.

    # ploting the cumulative variance
    data_frame(x=1:length(pca$sdev), sdev.cum=cumsum(props)) %>%
      ggplot(aes(x=x, y=sdev.cum)) +
      geom_line(color="darkblue", size=.8) +
      theme_minimal()

<img src="{{< blogdown/postref >}}index.en_files/figure-html/cumulativeVar-1.png" width="672" />

You can see in the chart above, we can get 90% of variance with only 80 of dimension from a universe of 719! This is a great information compression, almost 10:1!

### Ploting cases in new PCA space

Lets see how the 200 first cases in the data set are distributed in the first two dimensions (15% the variation).

    # lets see the distribution
    pca.idx <- sample(1:mnist$train$n, 200)
    cases <- tibble(
      label = as.factor(mnist$train$y[pca.idx]),
      x = tr.x[pca.idx,1],
      y = tr.x[pca.idx,2],
      z = tr.x[pca.idx,3]
    )

    # all cases
    cases %>%
      ggplot(aes(x=x, y=y, color=label)) +
      geom_point(size=2, alpha=.5) +
      theme_minimal()

<img src="{{< blogdown/postref >}}index.en_files/figure-html/casesDistribution-1.png" width="672" />

A little mess, but if we plot only the most distances centroids (`0`, `1` e `9`) we already see a separable structures if only two dimensions.

    # cases more "distant"
    cases %>%
      filter(label %in% c("0", "1", "9")) %>%
      ggplot(aes(x=x, y=y, color=label)) +
      geom_point(size=2, alpha=.5) +
      theme_minimal()

<img src="{{< blogdown/postref >}}index.en_files/figure-html/separableCases-1.png" width="672" />

This sound promising. An kNN approach with higher dimension may do a decent job classifying the digits. Lets put another one, increasing the *explained variation* to 23%.

<div id="htmlwidget-1" style="width:672px;height:480px;" class="plotly html-widget"></div>
<script type="application/json" data-for="htmlwidget-1">{"x":{"visdat":{"2af4316446f1":["function () ","plotlyVisDat"]},"cur_data":"2af4316446f1","attrs":{"2af4316446f1":{"x":{},"y":{},"z":{},"color":{},"alpha_stroke":1,"sizes":[10,100],"spans":[1,20],"type":"scatter3d","mode":"markers","size":1,"inherit":true}},"layout":{"margin":{"b":40,"l":60,"t":25,"r":10},"scene":{"xaxis":{"title":"x"},"yaxis":{"title":"y"},"zaxis":{"title":"z"}},"hovermode":"closest","showlegend":true},"source":"A","config":{"showSendToCloud":false},"data":[{"x":[-90.381701680939,-315.160346613124,-1108.09858321359,-564.370563480617,-66.7782320769006,-1050.59691015597,-1022.34730343354,-955.241699524595,-1585.1891897429,-1684.70070665969,-1230.56362193288,-2028.00574651208,-2323.64612609336,-1195.02892349866,-793.047695162291,-1647.33660636455,-1556.24112492478],"y":[-106.707879336116,-52.2845512383642,481.595986458317,146.978587471917,-93.5665660740055,239.04404616155,352.700027090188,239.608814399809,381.675980866791,126.059123591028,235.824094979927,106.84741825875,163.616218469722,80.5719561233827,25.2777191132984,101.159405242202,283.762438022684],"z":[-550.632907167607,-681.665397997304,392.331083599908,405.126754359744,574.168520553544,12.539383052454,391.193261099788,477.66618002472,-948.864228342762,362.130557840093,-61.7609239959156,-493.583459497026,52.9663757203993,-1029.21559219639,-36.8526161527377,-268.367449288846,-301.912499176363],"type":"scatter3d","mode":"markers","name":"0","marker":{"color":"rgba(102,194,165,1)","size":[55,55,55,55,55,55,55,55,55,55,55,55,55,55,55,55,55],"sizemode":"area","line":{"color":"rgba(102,194,165,1)"}},"textfont":{"color":"rgba(102,194,165,1)","size":55},"error_y":{"color":"rgba(102,194,165,1)","width":55},"error_x":{"color":"rgba(102,194,165,1)","width":55},"line":{"color":"rgba(102,194,165,1)","width":55},"frame":null},{"x":[609.057531712324,872.202109337246,937.200234598924,943.051721049885,968.644358934804,830.204918020356,737.786485503703,1011.87625775823,936.871697459437,920.791956133804,1003.11988026797,935.785269052851,924.27402935952,906.873270846977,959.708775971135,924.343111436276,849.11071871721,1013.68688569749,923.214778771909,506.626016638869,942.535274480996,831.852582681602,964.892969288109,914.637141246786,859.814904189737,750.300625707063],"y":[288.40874794966,325.639452521505,263.167458818378,575.48374712557,513.245585084732,62.8870008616198,132.378968631948,542.844451294881,619.784340417408,451.499085508521,453.97179805452,653.32892563703,497.453004308293,757.619759483907,234.928255645765,791.316502610972,151.686585690186,471.278688724814,271.566883689957,385.491229769296,438.493011925328,694.611938816386,691.493334991279,326.373554331689,372.527464153198,101.563127252527],"z":[-104.739157324839,-0.555163330902969,55.4683243757517,-166.308356045618,-73.6461471869771,233.07729719189,189.78696149039,-194.407595188593,-159.256583501139,-52.6807196539647,-207.472654281648,-259.511748379029,-367.608965862028,-226.50706839783,17.3303819414859,-340.357087109322,199.67567351474,-161.787989925125,38.1377765471669,-402.040696547191,-220.760579818614,-295.883670411904,-153.598743265822,-23.5075842589642,26.1127889957487,136.537498667147],"type":"scatter3d","mode":"markers","name":"1","marker":{"color":"rgba(228,156,113,1)","size":[55,55,55,55,55,55,55,55,55,55,55,55,55,55,55,55,55,55,55,55,55,55,55,55,55,55],"sizemode":"area","line":{"color":"rgba(228,156,113,1)"}},"textfont":{"color":"rgba(228,156,113,1)","size":55},"error_y":{"color":"rgba(228,156,113,1)","width":55},"error_x":{"color":"rgba(228,156,113,1)","width":55},"line":{"color":"rgba(228,156,113,1)","width":55},"frame":null},{"x":[-323.711528523028,-129.528199874099,-623.227430560123,300.37092021898,-670.076596037156,-633.672398595244,11.6419650516232,-931.040829101198,-343.231236116436,-614.809810702445,365.790357167918,-194.311440945203,346.193699962152,229.351936494873,64.7288427367501,-406.795975610359,-867.473090109079,86.4751703080202,368.84053841274,-180.669393829408],"y":[290.860997037289,199.046183514378,71.0056279602171,-198.045157441115,2.0822890146159,666.11915912793,377.278344186199,-298.026699350697,393.976547926428,674.588258334231,320.528715472847,364.995454892688,54.3038108385698,989.056684441264,523.869772083602,18.3967100575994,158.7136599615,90.3766167803289,803.682170723405,21.0572425427187],"z":[-748.506161817873,-453.973074472147,-1088.74190868815,-190.414586163443,-1130.22983747065,-951.826320792026,-274.640409543352,-44.4072295560354,-235.707492369533,387.464282147875,110.266458664518,91.6264299462238,61.8187603314459,385.628820007038,-323.072751487709,-932.345581737371,-1051.7474604308,10.0051438928819,182.409440583214,420.182452690016],"type":"scatter3d","mode":"markers","name":"2","marker":{"color":"rgba(201,152,157,1)","size":[55,55,55,55,55,55,55,55,55,55,55,55,55,55,55,55,55,55,55,55],"sizemode":"area","line":{"color":"rgba(201,152,157,1)"}},"textfont":{"color":"rgba(201,152,157,1)","size":55},"error_y":{"color":"rgba(201,152,157,1)","width":55},"error_x":{"color":"rgba(201,152,157,1)","width":55},"line":{"color":"rgba(201,152,157,1)","width":55},"frame":null},{"x":[246.034301197496,302.685610075722,-17.8016344951918,51.9452071617795,47.3513315403423,-822.688916573508,193.149287640629,-165.085727773271,281.114139030825,304.038146520067,-106.964406626932,-586.102784218864,-88.1111077219618,496.74497004763,-249.419983278227,-111.615706084071,370.110843765825,-221.393429581412,465.674006930552,-674.917233946277,218.753591718582],"y":[511.406218714463,170.854012449633,888.219862457378,364.702850442819,685.001083994956,901.141491335529,555.266469087485,805.561748199233,736.540575895682,463.62497059406,522.523715563761,877.870866193496,642.532825043122,94.3419553687294,975.782840621973,62.1779767808514,132.106909782116,439.335833522025,-312.421884294577,1103.6880045559,651.900861331564],"z":[-1.70406716508362,764.804237652943,376.960088445097,657.63063234623,824.462083483682,260.573113790741,834.052040086226,550.453534410114,-530.591249779105,1105.99523530061,898.354380945339,139.090495939295,870.638770705219,451.02556737792,771.650679003082,1046.14170934934,-654.670509359406,459.91550137858,383.126733890899,503.701242512705,-284.294073724364],"type":"scatter3d","mode":"markers","name":"3","marker":{"color":"rgba(175,154,200,1)","size":[55,55,55,55,55,55,55,55,55,55,55,55,55,55,55,55,55,55,55,55,55],"sizemode":"area","line":{"color":"rgba(175,154,200,1)"}},"textfont":{"color":"rgba(175,154,200,1)","size":55},"error_y":{"color":"rgba(175,154,200,1)","width":55},"error_x":{"color":"rgba(175,154,200,1)","width":55},"line":{"color":"rgba(175,154,200,1)","width":55},"frame":null},{"x":[99.3379073392943,570.48433665152,559.512871542464,-93.9742755205326,-275.181416338213,394.598712952207,89.3245933436716,185.054979582244,324.076329703876,591.879333056623,496.406016873643,39.7567301707706,333.804281332579,-159.727551246141,-288.310090076489,249.901563811805,294.415114318545,70.6485154308321,-633.172322619014,-265.035812180362,-501.56717171782,516.192327194167],"y":[-76.8999232115846,-267.77453691658,-374.474298698409,-602.027028340301,-804.69494489586,-212.535781241112,-805.178315736866,-401.432197406837,-477.527060475484,-324.168572204705,-44.8099911573193,-583.526123397422,-475.30849355122,211.716243225303,-768.20048238054,-310.088383608496,-392.604977815448,-534.875070360049,-1022.467316275,-416.669665103686,-946.773130740867,-320.351211711553],"z":[-445.346683229693,468.374278312772,489.186888376094,456.511266050623,-828.737128037996,539.32418312442,-548.19450176038,216.839070065426,315.102078857686,-127.975837150829,317.815876975133,-206.273102655656,338.82522619457,-769.839329285496,-309.358040979635,-451.429933641532,-748.464337333824,-409.369970484555,275.016212311247,100.811436462555,37.0756904555802,369.443856046154],"type":"scatter3d","mode":"markers","name":"4","marker":{"color":"rgba(226,148,184,1)","size":[55,55,55,55,55,55,55,55,55,55,55,55,55,55,55,55,55,55,55,55,55,55],"sizemode":"area","line":{"color":"rgba(226,148,184,1)"}},"textfont":{"color":"rgba(226,148,184,1)","size":55},"error_y":{"color":"rgba(226,148,184,1)","width":55},"error_x":{"color":"rgba(226,148,184,1)","width":55},"line":{"color":"rgba(226,148,184,1)","width":55},"frame":null},{"x":[587.417990921362,165.790959035345,-275.847177271571,-1057.14533917048,-315.724844644938,218.892368601598,-547.61186223455,-264.879507589089,326.749888742123,-717.566796197985,-453.806632412059,-117.758716713045,-36.4335625270642,-720.916901737829,94.0675319416424,-339.646820033828,-239.607320868613,-333.210114435021,4.27170259505296],"y":[89.1891640011507,480.959178821923,-258.415700405615,317.068042572053,-608.660600421153,-336.691775680365,262.715841951849,420.89946323703,-160.89467914333,121.306977074356,513.153822187962,495.65716598913,-627.651775013054,424.813817506665,-405.571044675094,212.128193785356,496.233837915112,-270.998328906693,-382.977157680652],"z":[-300.218477879836,121.097383998192,-44.4168947910509,713.193665565594,-45.7105790632632,-103.07566044989,940.571279914713,731.263708141178,-543.385143169672,939.146526038828,315.13721640904,350.610749685418,429.939322969555,835.081107075942,105.133345269115,-195.808052288275,511.790652720183,816.159214362917,-315.167145395542],"type":"scatter3d","mode":"markers","name":"5","marker":{"color":"rgba(176,208,99,1)","size":[55,55,55,55,55,55,55,55,55,55,55,55,55,55,55,55,55,55,55],"sizemode":"area","line":{"color":"rgba(176,208,99,1)"}},"textfont":{"color":"rgba(176,208,99,1)","size":55},"error_y":{"color":"rgba(176,208,99,1)","width":55},"error_x":{"color":"rgba(176,208,99,1)","width":55},"line":{"color":"rgba(176,208,99,1)","width":55},"frame":null},{"x":[576.424943811511,-85.4297356672145,89.9988546159802,-264.3122525002,437.82569243363,-236.359569877469,-937.717715090041,-281.051524887545,-284.542526752724,63.3896200174281,-487.8005895741,-667.763567642754,423.920945559457,-74.2506784889425],"y":[526.334073665234,-48.1360917393654,-41.0791876523496,192.787601929486,-9.79128749500012,-443.733033752842,97.8208089829546,5.39196737245965,-86.5548666591573,56.7543911763368,145.402923857147,326.019785330192,38.0368813448335,-327.752116370604],"z":[-519.960922298333,254.69919599139,-433.357415265823,-841.18992193955,-550.287433164225,-660.570662229655,-785.580119189251,-262.4585211553,-564.817452716794,-69.3157837639782,-768.726813459911,417.657237205149,-617.693112949752,-80.6399831436148],"type":"scatter3d","mode":"markers","name":"6","marker":{"color":"rgba(227,217,62,1)","size":[55,55,55,55,55,55,55,55,55,55,55,55,55,55],"sizemode":"area","line":{"color":"rgba(227,217,62,1)"}},"textfont":{"color":"rgba(227,217,62,1)","size":55},"error_y":{"color":"rgba(227,217,62,1)","width":55},"error_x":{"color":"rgba(227,217,62,1)","width":55},"line":{"color":"rgba(227,217,62,1)","width":55},"frame":null},{"x":[689.466265902594,785.56865227867,188.944405816834,-497.585356528516,371.612709660614,-20.7684462259027,873.422765673866,39.8563920234456,349.18669232116,0.983041568986469,-81.5964071227009,624.619601913654,800.397142004509,719.492698426465,457.436636299477,116.44872691857,590.658189237019,132.760463040403,773.54435422744,393.148695713716,-378.847701099628,-181.881564082139,17.2884594290438,330.546700140416,653.934576983737,674.97144061846,-183.120482436391,569.094536949002,625.115061052795],"y":[-455.320471830229,-348.237951258781,-587.039672939985,-796.506623069729,-480.877108624373,-643.796653630586,324.58381524744,-310.259937144065,-688.012546989798,-434.093128041562,-470.184059836028,-638.321522471429,-119.954980436624,-347.032455552211,-730.174189193715,-182.529988050129,-404.763384279035,-768.015031241762,-77.4022072610904,-516.135706512411,-1056.8751214892,-611.956103950159,-416.488309453157,-623.317015469135,513.675907012127,-654.041775078613,-1041.01914147219,-488.667649952199,-39.1286876605442],"z":[-74.8312604645601,268.260268708334,-697.999480097097,326.880842139684,-593.04958369163,-382.278436158695,-330.792034208114,-426.798223982154,-97.3619687485255,484.189768641056,-33.6214914365778,233.869651355597,301.203786099866,-25.0106099682757,-93.8982910856979,436.842518411889,-179.268362100922,-28.6663313946174,268.858085087981,719.818503276735,323.118039708012,680.598213848942,-157.149542324101,-331.778076020643,-109.087785880429,169.39216436993,358.371716610885,77.0109120619711,-102.743701714267],"type":"scatter3d","mode":"markers","name":"7","marker":{"color":"rgba(245,207,100,1)","size":[55,55,55,55,55,55,55,55,55,55,55,55,55,55,55,55,55,55,55,55,55,55,55,55,55,55,55,55,55],"sizemode":"area","line":{"color":"rgba(245,207,100,1)"}},"textfont":{"color":"rgba(245,207,100,1)","size":55},"error_y":{"color":"rgba(245,207,100,1)","width":55},"error_x":{"color":"rgba(245,207,100,1)","width":55},"line":{"color":"rgba(245,207,100,1)","width":55},"frame":null},{"x":[263.243678697286,244.824686710852,-484.374817458228,441.930477412824,307.890361384629,535.059191282489,388.909473886976,366.046773793441,-25.234106770571,175.186919285897,-187.76237922694,291.475630237036,443.860281717046,-350.845583648405,494.072035592537,-591.966535399792,136.319761892944,522.35409566389],"y":[121.800033917846,508.214970980695,414.660921733026,215.269476357078,59.2094371010176,316.2218579816,336.620714972041,352.505630420219,394.245983072418,-357.569199138207,-62.0291833465412,204.219909415297,359.549512649048,-137.307854245496,-112.161866368265,467.346823932369,-168.931810961405,343.13068817735],"z":[471.422011654059,-263.536317274595,943.091880475898,67.7053296971794,-329.860499391601,-20.0478136181724,175.207856503608,-324.620547507813,557.91460006303,72.3797144321148,757.437946732872,467.163347895711,-51.4205784919867,411.270544901039,66.480109133536,902.089573344517,102.045619699994,-14.0672267027116],"type":"scatter3d","mode":"markers","name":"8","marker":{"color":"rgba(219,192,155,1)","size":[55,55,55,55,55,55,55,55,55,55,55,55,55,55,55,55,55,55],"sizemode":"area","line":{"color":"rgba(219,192,155,1)"}},"textfont":{"color":"rgba(219,192,155,1)","size":55},"error_y":{"color":"rgba(219,192,155,1)","width":55},"error_x":{"color":"rgba(219,192,155,1)","width":55},"line":{"color":"rgba(219,192,155,1)","width":55},"frame":null},{"x":[702.905310312968,702.290450727822,472.687001598398,825.221037924324,293.996896212864,-19.1536580913427,-92.388473375366,223.407582248335,315.977504812413,79.936539567787,612.748622783562,318.517626495883,-288.778458725181,-160.058459645633],"y":[-285.869781004313,-203.28841292284,489.68071305298,-125.162853607429,-698.520655285718,-843.326632643336,-1192.8547375295,-714.384838300296,-654.416513871315,-577.564744582652,-361.557578474257,-611.397800327256,-447.195061306403,-846.516553582354],"z":[22.7304560770977,-120.107701826905,-566.399343840593,-119.726356134143,312.765084231078,-6.1393715558445,6.3942690217592,-335.205399050134,-190.703630369246,832.627038077763,-214.314572166261,695.980478557653,441.599241453427,825.998897005983],"type":"scatter3d","mode":"markers","name":"9","marker":{"color":"rgba(179,179,179,1)","size":[55,55,55,55,55,55,55,55,55,55,55,55,55,55],"sizemode":"area","line":{"color":"rgba(179,179,179,1)"}},"textfont":{"color":"rgba(179,179,179,1)","size":55},"error_y":{"color":"rgba(179,179,179,1)","width":55},"error_x":{"color":"rgba(179,179,179,1)","width":55},"line":{"color":"rgba(179,179,179,1)","width":55},"frame":null}],"highlight":{"on":"plotly_click","persistent":false,"dynamic":false,"selectize":false,"opacityDim":0.2,"selected":{"opacity":1},"debounce":0},"shinyEvents":["plotly_hover","plotly_click","plotly_selected","plotly_relayout","plotly_brushed","plotly_brushing","plotly_clickannotation","plotly_doubleclick","plotly_deselect","plotly_afterplot","plotly_sunburstclick"],"base_url":"https://plot.ly"},"evals":[],"jsHooks":[]}</script>

You can play around turning off the cases of some digits and rotating the chart. Can you see how the `0`, `1` and `9` clusters are distributed in the space? And the `4` and `9` cases?

### k-Nearest Neighbors

We saw that the PCA did a great job spreading the digits in the space, allow some separation, now let’s apply a kNN fit on this. We need to decide the number of dimension to be used (`n`) and the number of k-Nearest (`k`), to do this let’s make a cross validation search[^2].

    # knn cross validation
    part.idx <- sample(1:mnist$train$n, round(mnist$train$n/2))

    # cross validation parameters
    k <- seq(2,14, 2)
    n <- seq(5,80,10)
    cross.params <- crossing(k=k, n=n)

    # fit a kNN Model for each cross validation pair, and calc the accuracy
    result <- apply(X = cross.params,1, function(p, tr.idx = part.idx, x=tr.x, y=as.factor(mnist$train$y)){
      k_par <- as.integer(p[1])
      n_par <- as.integer(p[2])
      
      print(paste0("fitting: k=",k_par, " n=",n_par))

      y_hat <- knn(
        train = x[tr.idx,1:n_par], 
        test=x[-tr.idx,1:n_par], 
        cl=y[tr.idx],
        k=k_par
      )
      
      accuracy <- mean(y[-tr.idx]==y_hat)
      print(paste0("Accuracy: ", round(accuracy,4)))
      return(accuracy)
      
    })

    # build the CV results
    cv.results <- bind_cols(cross.params, accuracy=result)
    saveRDS(cv.results, "cv_result.rds") # to save time
    str(cv.results)

The result is a data frame contain a pair of `k` and `n`and the `accuracy` that the kNN classifier get from this configuration

    ## tibble [56 x 3] (S3: tbl_df/tbl/data.frame)
    ##  $ k       : num [1:56] 2 2 2 2 2 2 2 2 4 4 ...
    ##  $ n       : num [1:56] 5 15 25 35 45 55 65 75 5 15 ...
    ##  $ accuracy: num [1:56] 0.681 0.943 0.962 0.966 0.966 ...

Let’s see the *accuracy surface* defined by `k` and `n` parameters.

    # ploting the error "surface"
    cv.results %>%
      wireframe(accuracy~n*k, .)

<img src="{{< blogdown/postref >}}index.en_files/figure-html/plotAccuracySurface-1.png" width="672" />

    # which pair k and n are better ?
    best <- cv.results[which(cv.results$accuracy==max(cv.results$accuracy)),]

The best result was k=4 and n=35, with an accuracy of 97%. Not so bad, comparing the 99% accuracy of LeNet ANN from the [last post](/2018/01/implementing-lenet-with-mxnet-in-r/).

### Conclusion

As we see, the data analysis on the MNIST data set allow us to realize that the digit recognition problem can be solved, with great accuracy, by a simple kNN model. Of course this is not a complete image recognition problem, an ANN would learn to separate the classes without our intervention.

But the analysis show that, in this case, we don’t need jump directly to an expensive ANN, and better than that, it indicates that not all 784 pixels are necessary do identify a digit and we can, for sure, use the kNN´s pre-classification as another input for the ANN, or fit independent ANNs for difficult cases like `4`x`9`, showing another paths for model improvement.

#### References

This post was inspired by:

[^1]: http://varianceexplained.org/r/digit-eda/

[^2]: https://steven.codes/blog/ml/how-to-get-97-percent-on-MNIST-with-KNN/
