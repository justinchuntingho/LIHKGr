![LIHKGr](lihkgr.png)

# LIHKGr
The goal of LIHKGr is to scrape text data on the LIHKG, the Hong Kong version of Reddit, for analysis. LIHKG has gained popularity in 2016 and become a popular research data source during recent years. LIHKG is currently protected by Google's reCAPTCHA, this package currently builds on `rselenium` and adopts a semi-manual approach to bypass it.

## Instructions
`lihkgr.R` contains all the required functions. Please install the following packages: `RSelenium`, `raster`, `magrittr`, and `rvest` and follow the following workflows:

1. Run the R sciprt to load the packages and define all the functions.
2. Set working directory, temporary files will be stored here.
3. Run `init_scraper()` to initiate scraper. Specify the range of post ids to scrape.
4. Run `launch_browser()` and solve reCAPTCHA when needed. The default browser is Chrome (77.0.3865.40), change browser and version if neccessary. This function builts on `RSelenium::rsDriver()`, see help file for more information about supported browsers.
5. Run `start_scraping()` to strat scrapping. The function currently produces the following files: `LIHKGr.RData` which saves the workspace, `lihkg_df.rds` and `lihkg_df.csv` which save the dataframe as .rds and .csv respectively, and `lihkg_df_postid.txt` which save the last scraped post id.

If the browser has crashed, repeat step 4 and 5. If R has crashed, read in `LIHKGr.RData` and repeat step 4 and 5.

## Known Issues / To-do List

* Create R package using devtools
* Create arguments for specifying file outputs.
* Debug error scrapping empty last page
* Debug error scraping hidden posts

## Contributors

* Justin Chun-ting Ho
* Nick H. K. Or

## Citation
Ho, J.C. & Or, N.H.K. (2020). LIHKGr. An application for scraping LIHKG. Source code and releases available at https://github.com/justinchuntingho/LIHKGr.
