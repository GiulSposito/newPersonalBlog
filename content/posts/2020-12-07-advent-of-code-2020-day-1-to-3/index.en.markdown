---
title: Advent Of Code 2020 | Day 1 to 3
author: Giuliano Sposito
date: '2020-12-07'
slug: 'advent-of-code-2020-01-03'
categories:
  - R
tags:
  - rstats
  - tidyverse
  - advend of code
  - data handling
subtitle: ''
lastmod: '2021-11-09T22:40:18-03:00'
authorLink: ''
description: ''
hiddenFromHomePage: no
hiddenFromSearch: no
featuredImage: 'images/advent_of_code_header.jpg'
featuredImagePreview: ''
toc:
  enable: yes
math:
  enable: no
lightgallery: no
license: ''
---
<script src="{{< blogdown/postref >}}index.en_files/kePrint/kePrint.js"></script>
<link href="{{< blogdown/postref >}}index.en_files/lightable/lightable.css" rel="stylesheet" />


Advent of Code is an Advent calendar of small programming puzzles for a variety of skill sets and skill levels that can be solved in any programming language you like. These are my six solutions to the 'Advent of Code 2020' puzzles, from day 1 to day 3, using R.

<!--more-->

Advent of Code is an Advent calendar of small programming puzzles for a variety of skill sets and skill levels that can be solved in any programming language you like. These are my six solutions to the 'Advent of Code 2020' puzzles, from day 1 to day 3, using R.

### Advent of Code

[Advent of Code](https://adventofcode.com/2020) is an Advent calendar of small programming puzzles for a variety of skill sets and skill levels that can be solved in any programming language you like. You don't need a computer science background to participate - just a little programming knowledge and some problem solving skills will get you pretty far. Nor do you need a fancy computer; every problem has a solution that completes in at most 15 seconds on ten-year-old hardware.

I try to answer the puzzles using R, let's see what we get...

### Day 1: Report Repair 

#### Part One

After saving Christmas five years in a row, you've decided to take a vacation at a nice resort on a tropical island. Surely, Christmas will go on without you.

The tropical island has its own currency and is entirely cash-only. The gold coins used there have a little picture of a starfish; the locals just call them stars. None of the currency exchanges seem to have heard of them, but somehow, you'll need to find fifty of these coins by the time you arrive so you can pay the deposit on your room.

To save your vacation, you need to get all fifty stars by December 25th.

Collect stars by solving puzzles. Two puzzles will be made available on each day in the Advent calendar; the second puzzle is unlocked when you complete the first. Each puzzle grants one star. Good luck!

Before you leave, the Elves in accounting just need you to fix your expense report (your puzzle input); apparently, something isn't quite adding up.

Specifically, they need you to find the two entries that sum to `2020` and then multiply those two numbers together.

For example, suppose your expense report contained the following:

```
1721
979
366
299
675
1456
```

In this list, the two entries that sum to `2020` are `1721` and `299.` Multiplying them together produces `1721 * 299 = 514579`, so the correct answer is 514579.

Of course, your expense report is much larger. Find the two entries that sum to 2020; what do you get if you multiply them together?

##### Solution

I'll make a matrix with combination of 2 of all elements in the input, sum then up and check which pair has `2020` as result.



```r
# solution using base r

# read the input as vector
input <- read.csv("data/day01_input.txt", header = F)[,1]

# generate all combination of 2 
comb <- combn(input, 2)

# sum each combinations
sums <- colSums(comb)

# find which one has the sum equals 2020
vals <- comb[,sums==2020]

# multiply them
resp <- prod(vals)

resp
```

```
## [1] 866436
```

#### Part two

The Elves in accounting are thankful for your help; one of them even offers you a starfish coin they had left over from a past vacation. They offer you a second one if you can find three numbers in your expense report that meet the same criteria.

Using the above example again, the three entries that sum to `2020` are `979, 366,` and `675`. Multiplying them together produces the answer, `241861950`.

In your expense report, what is the product of the three entries that sum to 2020?

##### Solution

The same strategy, but in this case we make combinations of 3.


```r
# keeping within base r

# generic solution for combinations of N
findCombSum <- function(in.data, n.comb, match.value){

  # generate all combination of 'n.comb' 
  comb <- combn(in.data, n.comb)
  
  # sum each combinations
  sums <- colSums(comb)
  
  # find which one has the sum equals 'match.value'
  vals <- comb[,sums==match.value]
  
  # multiply them
  resp <- prod(vals)
  
  return(resp)
  
}

# read the input as vector
input <- read.csv("data/day01_input.txt", header = F)[,1]

# part 1
findCombSum(input, 2, 2020)
```

```
## [1] 866436
```

```r
# part 2
findCombSum(input, 3, 2020)
```

```
## [1] 276650720
```

### Day 2: Password Philosophy

#### Parte One

Your flight departs in a few days from the coastal airport; the easiest way down to the coast from here is via toboggan.

The shopkeeper at the North Pole Toboggan Rental Shop is having a bad day. "Something's wrong with our computers; we can't log in!" You ask if you can take a look.

Their password database seems to be a little corrupted: some of the passwords wouldn't have been allowed by the Official Toboggan Corporate Policy that was in effect when they were chosen.

To try to debug the problem, they have created a list (your puzzle input) of passwords (according to the corrupted database) and the corporate policy when that password was set.

For example, suppose you have the following list:

```
1-3 a: abcde
1-3 b: cdefg
2-9 c: ccccccccc
```

Each line gives the password policy and then the password. The password policy indicates the lowest and highest number of times a given letter must appear for the password to be valid. For example, `1-3 a` means that the password must contain `a` at `least 1` time and at `most 3` times.

In the above example, 2 passwords are valid. The middle password, `cdefg`, is not; it contains no instances of `b`, but needs `at least 1`. The first and third passwords are valid: they contain `one a or nine c`, both within the limits of their respective policies.

How many passwords are valid according to their policies?

##### Solution

I'll process the input separating the policy and the password, after that we split the policy in the letter to be checked and the min and max appearing range.


```r
# tidyr::separate() and stringr::str_count() come in handy for this
library(tidyverse)
library(kableExtra)
library(knitr)

# reads the input data as data frame with a column named 'input'
password.check <- read.csv("data/day02_input.txt", header = F) %>% 
  set_names(c("input")) %>% 
  # splits each input into a password and a policy field
  separate(input, c("policy","password"), sep=": ", remove=F) %>% 
  # splits the policy into range values and the letter to be checked
  separate(policy, c("pol.range.min", "pol.range.max","pol.letter"),
           sep="-| ", convert=T) %>% 
  # counts the number of letter to be checked appearing in the password and
  # checks if witin the policy range
  mutate( count.letter = str_count(password, pol.letter),  
          is.valid = count.letter >= pol.range.min &
                     count.letter <= pol.range.max )

# let's see what we got
head(password.check) %>% 
  kable() %>% 
  kable_styling(font_size = 10)
```

<table class="table" style="font-size: 10px; margin-left: auto; margin-right: auto;">
 <thead>
  <tr>
   <th style="text-align:left;"> input </th>
   <th style="text-align:right;"> pol.range.min </th>
   <th style="text-align:right;"> pol.range.max </th>
   <th style="text-align:left;"> pol.letter </th>
   <th style="text-align:left;"> password </th>
   <th style="text-align:right;"> count.letter </th>
   <th style="text-align:left;"> is.valid </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> 16-18 h: hhhhhhhhhhhhhhhhhh </td>
   <td style="text-align:right;"> 16 </td>
   <td style="text-align:right;"> 18 </td>
   <td style="text-align:left;"> h </td>
   <td style="text-align:left;"> hhhhhhhhhhhhhhhhhh </td>
   <td style="text-align:right;"> 18 </td>
   <td style="text-align:left;"> TRUE </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 17-18 d: ddddddddddddddddzn </td>
   <td style="text-align:right;"> 17 </td>
   <td style="text-align:right;"> 18 </td>
   <td style="text-align:left;"> d </td>
   <td style="text-align:left;"> ddddddddddddddddzn </td>
   <td style="text-align:right;"> 16 </td>
   <td style="text-align:left;"> FALSE </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 15-18 c: cccccccccccccczcczc </td>
   <td style="text-align:right;"> 15 </td>
   <td style="text-align:right;"> 18 </td>
   <td style="text-align:left;"> c </td>
   <td style="text-align:left;"> cccccccccccccczcczc </td>
   <td style="text-align:right;"> 17 </td>
   <td style="text-align:left;"> TRUE </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 3-9 r: pplzctdrc </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:right;"> 9 </td>
   <td style="text-align:left;"> r </td>
   <td style="text-align:left;"> pplzctdrc </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:left;"> FALSE </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 4-14 d: lxdmddfddddddd </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:right;"> 14 </td>
   <td style="text-align:left;"> d </td>
   <td style="text-align:left;"> lxdmddfddddddd </td>
   <td style="text-align:right;"> 10 </td>
   <td style="text-align:left;"> TRUE </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 8-14 v: pvxlknfvplgktv </td>
   <td style="text-align:right;"> 8 </td>
   <td style="text-align:right;"> 14 </td>
   <td style="text-align:left;"> v </td>
   <td style="text-align:left;"> pvxlknfvplgktv </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> FALSE </td>
  </tr>
</tbody>
</table>

```r
# how many password are valid?
sum(password.check$is.valid)
```

```
## [1] 465
```

#### Part Two

While it appears you validated the passwords correctly, they don't seem to be what the Official Toboggan Corporate Authentication System is expecting.

The shopkeeper suddenly realizes that he just accidentally explained the password policy rules from his old job at the sled rental place down the street! The Official Toboggan Corporate Policy actually works a little differently.

Each policy actually describes two positions in the password, where 1 means the first character, 2 means the second character, and so on. (Be careful; Toboggan Corporate Policies have no concept of "index zero"!) Exactly one of these positions must contain the given letter. Other occurrences of the letter are irrelevant for the purposes of policy enforcement.

Given the same example list from above:

```
1-3 a: abcde is valid: position 1 contains a and position 3 does not.
1-3 b: cdefg is invalid: neither position 1 nor position 3 contains b.
2-9 c: ccccccccc is invalid: both position 2 and position 9 contain c.
```

How many passwords are valid according to the new interpretation of the policies?

##### Solution

I'll use the same solution here, but change the interpretation of the policy following the new philosophy.


```r
# tidyr::separate() and stringr::str_count() come in handy for this
library(tidyverse)

# reads the input data as data frame with a column named 'input'
password.check <- read.csv("data/day02_input.txt", header = F) %>% 
  set_names(c("input")) %>% 
  # splits each input into the password and policy columns
  separate(input, c("policy","password"), sep=": ", remove=F) %>% 
  # splits the policy into range/position values and the letter to be checke
  separate(policy, c("pol.range.min", "pol.range.max","pol.letter"),
           sep="-| ", convert=T) %>% 
  # part 1 
  # counts the number of letter to be checked appearing in the password and
  # checks if witin the policy range
  mutate( count.letter = str_count(password, pol.letter),  
          is.valid.part1 = count.letter >= pol.range.min &
                           count.letter <= pol.range.max ) %>% 
  # part 2
  # gets the letters in positions 'min' and 'max"' and do a "XOR" check
  mutate(
    letter.at.pos1 = str_sub(password, pol.range.min, pol.range.min),
    letter.at.pos2 = str_sub(password, pol.range.max, pol.range.max),
    is.valid.part2 = xor(letter.at.pos1==pol.letter, letter.at.pos2==pol.letter)
  )

# part one: how many password are valid (repeat letter policy)?
sum(password.check$is.valid.part1)
```

```
## [1] 465
```

```r
# part tow: how many password are valid (letter at position xor policy?
sum(password.check$is.valid.part2)
```

```
## [1] 294
```

### Day 3: Toboggan Trajectory

#### Part 1

With the toboggan login problems resolved, you set off toward the airport. While travel by toboggan might be easy, it's certainly not safe: there's very minimal steering and the area is covered in trees. You'll need to see which angles will take you near the fewest trees.

Due to the local geology, trees in this area only grow on exact integer coordinates in a grid. You make a map (your puzzle input) of the open squares (`.`) and trees (`#`) you can see. For example:

```
..##.......
#...#...#..
.#....#..#.
..#.#...#.#
.#...##..#.
..#.##.....
.#.#.#....#
.#........#
#.##...#...
#...##....#
.#..#...#.#
```

These aren't the only trees, though; due to something you read about once involving arboreal genetics and biome stability, the same pattern repeats to the right many times:


```
..##.........##.........##.........##.........##.........##.......  --->
#...#...#..#...#...#..#...#...#..#...#...#..#...#...#..#...#...#..
.#....#..#..#....#..#..#....#..#..#....#..#..#....#..#..#....#..#.
..#.#...#.#..#.#...#.#..#.#...#.#..#.#...#.#..#.#...#.#..#.#...#.#
.#...##..#..#...##..#..#...##..#..#...##..#..#...##..#..#...##..#.
..#.##.......#.##.......#.##.......#.##.......#.##.......#.##.....  --->
.#.#.#....#.#.#.#....#.#.#.#....#.#.#.#....#.#.#.#....#.#.#.#....#
.#........#.#........#.#........#.#........#.#........#.#........#
#.##...#...#.##...#...#.##...#...#.##...#...#.##...#...#.##...#...
#...##....##...##....##...##....##...##....##...##....##...##....#
.#..#...#.#.#..#...#.#.#..#...#.#.#..#...#.#.#..#...#.#.#..#...#.#  --->
```

You start on the open square (`.`) in the top-left corner and need to reach the bottom (below the bottom-most row on your map).

The toboggan can only follow a few specific slopes (you opted for a cheaper model that prefers rational numbers); start by counting all the trees you would encounter for the slope right 3, down 1:

From your starting position at the top-left, check the position that is right 3 and down 1. Then, check the position that is right 3 and down 1 from there, and so on until you go past the bottom of the map.

The locations you'd check in the above example are marked here with `O` where there was an open square and `X` where there was a tree:

```
..##.........##.........##.........##.........##.........##.......  --->
#..O#...#..#...#...#..#...#...#..#...#...#..#...#...#..#...#...#..
.#....X..#..#....#..#..#....#..#..#....#..#..#....#..#..#....#..#.
..#.#...#O#..#.#...#.#..#.#...#.#..#.#...#.#..#.#...#.#..#.#...#.#
.#...##..#..X...##..#..#...##..#..#...##..#..#...##..#..#...##..#.
..#.##.......#.X#.......#.##.......#.##.......#.##.......#.##.....  --->
.#.#.#....#.#.#.#.O..#.#.#.#....#.#.#.#....#.#.#.#....#.#.#.#....#
.#........#.#........X.#........#.#........#.#........#.#........#
#.##...#...#.##...#...#.X#...#...#.##...#...#.##...#...#.##...#...
#...##....##...##....##...#X....##...##....##...##....##...##....#
.#..#...#.#.#..#...#.#.#..#...X.#.#..#...#.#.#..#...#.#.#..#...#.#  --->
```

In this example, traversing the map using this slope would cause you to encounter 7 trees.

Starting at the top-left corner of your map and following a slope of right 3 and down 1, how many trees would you encounter?

##### Solution

The idea is to change the `tree char map` of dots and hashtags into a `0/1` matrix marking the trees with `1`. After that I iterate the trajectory to find the slope down positions (coordinates) until the end of the hill (bottom of the matrix). As the trees are repeating them pattern, it's necessary to keep the `y-coordinate` in the range of the size of the matrix.


```r
# reads the file as vector of string
input <- read.csv("data/day03_input.txt", header = F)[,1]

# creates a "char" matrix of "." and "#"
char_map <- strsplit(input, "") %>% 
  unlist() %>% 
  matrix(nrow = length(input), byrow = T)

# converts in to 0 and 1 (1 for the trees) 
int_map <- 1*(char_map == "#")

# lets subset the matrix with the trajectory

# the hill trajectory: 3 to the left and 1 to the bottom
shift <- c(1,3)

# starting from top left
base_pos <- c(1,1)
trajectory <- base_pos

# until the last row
for(i in 1:(nrow(int_map)-1)){
  step <- base_pos + shift
  base_pos <- step
  trajectory <- rbind(trajectory, base_pos)
}

# keeps the y coord within the matrix range
y_coords <- trajectory[,2] %% ncol(int_map)
y_coords[y_coords==0] <- ncol(int_map) # adjust mod=0 is the most right y coord
trajectory[,2] <- y_coords

# subsets the matrix in the trajectory and sum (count) the number of trees
sum(int_map[trajectory])
```

```
## [1] 237
```

#### Part 2

Time to check the rest of the slopes - you need to minimize the probability of a sudden arboreal stop, after all.

Determine the number of trees you would encounter if, for each of the following slopes, you start at the top-left corner and traverse the map all the way to the bottom:

```
Right 1, down 1.
Right 3, down 1. (This is the slope you already checked.)
Right 5, down 1.
Right 7, down 1.
Right 1, down 2.
```

In the above example, these slopes would find 2, 7, 3, 4, and 2 tree(s) respectively; multiplied together, these produce the answer 336.

What do you get if you multiply together the number of trees encountered on each of the listed slopes?

##### Solution

The same idea here, but I'll make a generic solution (a function) to test several "slope strategy".


```r
# counts trees in a trajectory
# receives a int matrix where "1" is a tree and "0" not
# receives a "shift pattern" for each step down
countTreesByShift <- function(shift.pattern, area.map){
  
  # starting from top left
  base_pos <- c(1,1)
  trajectory <- base_pos

  # apply the pattern until the bottom
  for(i in 1:(nrow(area.map)-1)){
    step <- base_pos + shift.pattern
    base_pos <- step
    trajectory <- rbind(trajectory, step)
  }
  
  # keeps the y coord within the matrix range
  y_coords <- trajectory[,2] %% ncol(area.map)
  y_coords[y_coords==0] <- ncol(area.map)
  trajectory[,2] <- y_coords
  
  # avoids out of index in the number of rows
  trajectory <- trajectory[trajectory[,1]<=nrow(area.map),]
  
  # subsets the map with trajectory coordinates and sum
  return(sum(int_map[trajectory]))
}

# reads the file as vector of string
input <- read.csv("data/day03_input.txt", header = F)[,1]

# creates a "char" matrix of "." and "#"
char_map <- strsplit(input, "") %>% 
  unlist() %>% 
  matrix(nrow = length(input), byrow = T)

# converts in to 0 and 1 (1 for the trees) 
int_map <- 1*(char_map == "#")

# testing the patterns

# part 1
countTreesByShift(c(1,3),int_map)
```

```
## [1] 237
```

```r
# part 2
c(1,1,1,3,1,5,1,7,2,1) %>% 
  matrix(ncol=2, byrow = T) %>%
  split(1:nrow(.)) %>% 
  purrr::map_dbl(countTreesByShift, area.map=int_map) %>% 
  prod()
```

```
## [1] 2106818610
```

#### To be continued...

I'll make the rest of puzzles in the next days and publish them here, see you...
