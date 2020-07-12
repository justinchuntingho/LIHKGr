
# LIHKGr <img src="lihkgr.png" align="right" height="200" />
The goal of LIHKGr is to scrape text data on the LIHKG, the Hong Kong version of Reddit, for analysis. LIHKG has gained popularity in 2016 and become a popular research data source during recent years. LIHKG is currently protected by Google's reCAPTCHA, this package currently builds on `RSelenium` and adopts a semi-manual approach to bypass it.

## Instructions
`lihkgr.R` contains all the required functions. Please install the following packages: `RSelenium`, `raster`, `magrittr` `rvest`, and `purrr`. Follow the following workflow:

### Step 1: Create a scraper

```r
## Creating a Firefox instance with a random port.

lihkg <- create_lihkg(browser = "firefox", port = sample(10000:60000, 1), verbose = FALSE)
```

### Step 2: Scrape

```r
lihkg$scrape(1891333)
lihkg$scrape_alot(1610753:1610755)
```

### Step 2.1: If any post id cannot be scraped, retry

```r
lihkg$retry()
```

### Step 3: Get / Save the data

```r
lihkg$bag
lihkg$save("lihkg.RDS")

### If you don't want to save the data as RDS, you can just save the bag as any format you like. It is just a regular data frame / tibble.

rio::export(lihkg$bag, "lihkg.xlsx")
```

### Step 4: Destroy the scraper

```r
lihkg$finalize()
```

## Known Issues / To-do List

* Create R package using devtools
* Debug error scrapping empty last page

## Contributors

* Justin Chun-ting Ho
* Nick H. K. Or
* Chung-hong Chan
* Elgar Teo

## Citation
Ho, J.C. & Or, N.H.K. (2020). LIHKGr. An application for scraping LIHKG. Source code and releases available at https://github.com/justinchuntingho/LIHKGr.
