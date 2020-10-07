![](https://www.r-pkg.org/badges/version-last-release/LIHKGr)
![](https://cranlogs.r-pkg.org/badges/grand-total/LIHKGr)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)






# LIHKGr <img src="man/figures/lihkgr.png" align="right" height="200" />
The goal of LIHKGr is to scrape text data on the LIHKG, the Hong Kong version of Reddit, for analysis. LIHKG has gained popularity in 2016 and become a popular research data source during recent years. LIHKG is currently protected by Google's reCAPTCHA, this package currently builds on `RSelenium` and adopts a semi-manual approach to bypass it.

## Installation
```r
install.packages("LIHKGr")
```

## Instructions
`lihkgr.R` contains all the required functions. Please install the following packages: `RSelenium`, `raster`, `magrittr` `rvest`, and `purrr`. Follow the following workflow:

### Step 1: Create a scraper
For `RSelenium` to work, you need to specify the browser. If you are using Chrome, you need to also specify the version. For example,`create_lihkg(browser = "chrome", chromever = "83.0.4103.39")`. If a version is not supplied, by default it will run the most recent version. To see Chrome version currently sourced run `binman::list_versions("chromedriver")`.

```r
## Creating a Firefox instance with a random port.

lihkg <- create_lihkg(browser = "firefox", port = sample(10000:60000, 1), verbose = FALSE)
```

### Step 2: Scrape

```r
# It can accept a single post id
lihkg$scrape(2091171)

# Or a vector
lihkg$scrape(1610753:1610755)

# Another way to do it
postids <- c(1610753, 2091171)
lihkg$scrape(postids)
```

### Step 2.1: If any post id cannot be scraped, retry

```r
lihkg$retry()
```

### Step 3: Get / Save the data

To obtain the dataframe:
```r
lihkg$bag
```

To save as .RDS:
```r
lihkg$save("lihkg.RDS")
```
If you don't want to save the data as RDS, you can just save the bag as any format you like. It is just a regular data frame / tibble：
```r
rio::export(lihkg$bag, "lihkg.xlsx")
```

### Step 4: Destroy the scraper

```r
lihkg$finalize()
```

## Contributors

* Justin Chun-ting Ho
* Nick H. K. Or
* Chung-hong Chan
* Elgar Teo

## Citation
Ho, J.C. & Or, N.H.K. (2020). LIHKGr. An application for scraping LIHKG. Source code and releases available at https://github.com/justinchuntingho/LIHKGr.
