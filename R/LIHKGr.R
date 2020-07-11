#########
### R6 version
require(R6)
require(purrr)
require(tibble) # >= 3.0.3
require(dplyr)
library(RSelenium)
library(raster)
library(magrittr)
library(rvest)
require(xml2)

.lay_low <- function(){
  Sys.sleep(sample(seq(1, 2, by=0.001), 1))
}


.gen_remote_driver <- function(...) {
    driver <- RSelenium::rsDriver(...)
    remote_driver <- driver[["client"]]
    remote_driver$navigate("https://lihkg.com")
    return(list(driver, remote_driver))
}

.crack_it <- function(url, remote_driver){
    remote_driver$navigate(url)
    Sys.sleep(sample(seq(3, 5, by=0.001), 1))
    collapsed <- remote_driver$findElements("xpath", "//div[@class='_1d3Z5jQRq3WnuIm0hnMh0c']")
    if (length(collapsed)) { # click collapsed comments if any
        for (x in collapsed) {
            x$clickElement()
        }
    }
    html <- remote_driver$getPageSource()
    if(grepl("recaptcha_widget", html[[1]])){
        readline(prompt="Captcha Detected. Press [enter] to continue after solving")
        return(.crack_it(url, remote_driver)) # make sure collapsed comments are expanded
    }
    pg <-  xml2::read_html(html[[1]])
    if (length(collapsed)) { # remove any additional page accidentally loaded when clicking collapsed comments
        xml2::xml_remove(xml2::xml_find_all(pg, "//div[@class='_3jxQCFWg9LDtkSkIVLzQ8L']")[-1])
    }
    return(pg)
}

.scrape_page <- function(html, postid){
    ##get_number
    number <- html %>% rvest::html_nodes("._36ZEkSvpdj_igmog0nluzh") %>%
        rvest::html_node("div div small ._3SqN3KZ8m8vCsD9FNcxcki") %>%
        rvest::html_text()
    ##get_date
    date <- html %>% rvest::html_nodes("._36ZEkSvpdj_igmog0nluzh") %>%
        rvest::html_node("div div small .Ahi80YgykKo22njTSCzs_") %>%
        rvest::html_attr("data-tip")
    ##get_uid
    uid <- html %>% rvest::html_nodes("._36ZEkSvpdj_igmog0nluzh") %>%
        rvest::html_node("div div small .ZZtOrmcIRcvdpnW09DzFk a") %>%
        rvest::html_attr('href')
    ##get_probation
    probation <- html %>% rvest::html_nodes("._36ZEkSvpdj_igmog0nluzh") %>%
        rvest::html_node("div div small ._10ZVxePYNpBeLjzkQ88wtj") %>%
        rvest::html_text() %>%
        is.na() %>%
        magrittr::not()
    ##get_text
    text <- html %>% rvest::html_nodes("._36ZEkSvpdj_igmog0nluzh") %>%
        rvest::html_node("div div .GAagiRXJU88Nul1M7Ai0H ._2cNsJna0_hV8tdMj3X6_gJ") %>%
        rvest::html_text()
    ##get_upvote
    upvote <- html %>% rvest::html_nodes("._36ZEkSvpdj_igmog0nluzh") %>%
        rvest::html_node("._1jvTHwVJobs9nsM0JDYqKB+ ._1drI9FJC8tyquOpz5QRaqf") %>% rvest::html_text()
    ##get_downvote
    downvote <- html %>% rvest::html_nodes("._36ZEkSvpdj_igmog0nluzh") %>%
        rvest::html_node("._2_VFV1QOZok8YhOTGa_3h9+ ._1drI9FJC8tyquOpz5QRaqf") %>% rvest::html_text()
    ##get_collection_time
    collection_time <- Sys.time()
    ##get_title
    top.text <- html %>% rvest::html_nodes("._2k_IfadJWjcLJlSKkz_R2- span") %>% rvest::html_text()
    title <- top.text[2]
    board <- top.text[1]
    newdf <- tibble::as_tibble(cbind(number, date, uid, probation, text, upvote, downvote))
    newdf$postid <- postid # This bit might fail if date etc is NULL
    newdf$title <- title
    newdf$board <- board
    newdf$collection_time <- collection_time
    return(newdf)
}

.print_v <- function(..., verbose) {
    if (verbose) {
        print(...)
    }
}

.scrape_post <- function(postid, remote_driver, verbose) {
  posts <- tibble::tibble()
  for(i in 1:999){
    attempt <- 1
    notdone <- TRUE
    nextpage <- FALSE

    while( notdone && attempt <= 4 ) { # Auto restart when fails
      .print_v(paste0("Attempt: ", attempt), verbose = verbose)
      attempt <- attempt + 1
      try({
        html <- .crack_it(paste0("https://lihkg.com/thread/", postid, "/page/", i), remote_driver)
        next.page <- html %>% rvest::html_node("._3omJTNzI7U7MErH1Cfr3gE+ ._3omJTNzI7U7MErH1Cfr3gE a") %>% rvest::html_text()
        titlewords <- html %>% rvest::html_nodes("._2k_IfadJWjcLJlSKkz_R2- span") %>% rvest::html_text() %>% length()
        if ("下一頁" %in% next.page){
            .print_v(paste0("page ", i, " (to be continued)"),  verbose = verbose)
            post <- .scrape_page(html, postid)
            posts <- dplyr::bind_rows(posts, post)
            nextpage <- TRUE
            notdone <- FALSE
        } else if (titlewords == 1){
            notdone <- FALSE
            posts <- tibble::tibble(number = "ERROR", date = "ERROR", uid = "ERROR", probation = "ERROR", text = "ERROR", upvote = "ERROR", downvote = "ERROR", postid = postid, title = "Deleted Post", board = "ERROR", collection_time = Sys.time())
            .print_v("Empty Post, Skipping",  verbose = verbose)
        } else {
            .print_v(paste0("page ", i, " (last page)"), verbose = verbose)
            post <- .scrape_page(html, postid)
            posts <- dplyr::bind_rows(posts, post)
            notdone <- FALSE
        }
        .lay_low()
      })
    } # End of While Loop
    if( notdone && attempt > 4 ){
        if (titlewords == 2 && nrow(posts) > 1){
            warning <- tibble::tibble(number = "EMPTY LAST PAGE", date = "EMPTY LAST PAGE", uid = "ERROR", probation = "ERROR", text = "ERROR", upvote = "ERROR", downvote = "ERROR", postid = postid, title = "Deleted Last Page", board = "ERROR", collection_time = Sys.time())
            posts <- dplyr::bind_rows(posts, warning)
            .print_v("Empty Last Page Detected",  verbose = verbose)
            notdone <- FALSE
        } else {
            stop("Error, Stopping")
        }
    }
    if(nextpage){
        next
    } else if(!notdone){
        break
    }
  } # End of For Loop
  return(posts)
}

Lihkg_reader <- R6::R6Class(
    "lihkg_reader",
    public = list(
        initialize = function(..., verbose = TRUE) {
            res <- .gen_remote_driver(...)
            private$remote_driver <- res[[2]]
            private$driver <- res[[1]]
            private$verbose <- verbose
        },
        scrape = function(postid) {
            self$bag <- rbind(self$bag, .scrape_post(postid, private$remote_driver, private$verbose))
        },
        save = function(file_name) {
            saveRDS(self$bag, file_name)
        },
        scrape_alot = function(postids) {
            res <- purrr::map(postids, purrr::safely(.scrape_post), remote_driver = private$remote_driver, verbose = private$verbose)
            failed_ids <- postids[!purrr::map_lgl(purrr::map(res, "error"), is.null)]
            if (length(failed_ids) >= 1) {
                private$failed <- append(private$failed, failed_ids)
            }
            self$bag <- dplyr::bind_rows(self$bag, purrr::map_df(res, "result"))
        },
        retry = function() {
            if (length(private$failed) == 0) {
                stop("No failed post id.")
            }
            self$scrape_alot(private$failed)
        },
        clear = function() {
            self$bag <- tibble::tibble()
        },
        finalize = function() {
            private$remote_driver$close()
            private$driver[["server"]]$stop()            
        },
        bag = tibble::tibble()
        ),
    private = list(
        remote_driver = NULL,
        driver = NULL,
        failed = c(),
        verbose = NULL
    )
)

#' Create a lihkg scraper
#'
#' This function creates a lihkg scraper
#'
#' @param ... parameters to be passed to RSelenium::rsDriver(). For example, you can use create_lihkg(browser = "firefox", port = sample(10000:60000, 1)) to generate a Selenium instance of Firefox.
#' @param verbose logical, whether debug information is printed out.
#' @return a lihkg scraper
#' @export
create_lihkg <- function(..., verbose = FALSE) {
    Lihkg_reader$new(..., verbose = FALSE)
}

### This method of using ... is better because some people (actually a lot of people) are using selenium inside Docker. So that they don't need to be restricted with only running it on their own machine.

lihkg <- create_lihkg(browser = "firefox", port = sample(10000:60000, 1), verbose = FALSE)
require(magrittr)
lihkg$scrape(1891333)
### the bag is now public.
lihkg$bag

### Reproduce the original one.
### TODO: mock a test for failed scraping.
lihkg$scrape_alot(1610753:1610755)

lihkg$bag %>% print(n = 1000)

### IF there is anything missed, one can do this. (Haven't tested.)
lihkg$retry()

lihkg$save("lihkg.RDS")

lihkg$finalize()
