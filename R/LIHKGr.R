library(RSelenium)
library(raster)
library(magrittr)
library(rvest)

init_scraper <- function(startn, stopn, windows = FALSE){
  Sys.setenv(TZ = "Asia/Hong_Kong") # Setting Time Zone to HK
  if(windows){
    Sys.setlocale("LC_CTYPE", locale="Chinese (Traditional)")
  }
  n <<- startn
  stopn <<- stopn
  lihkg_df <<- c()
  postid <<- c()
  failed <<- c()
}

launch_browser <- function(browser=c("chrome"), chromever = "77.0.3865.40", port = sample(1000:60000, 1)){
  driver <<- rsDriver(browser=browser, chromever = chromever, port = port)
  remote_driver <<- driver[["client"]]
  remote_driver$navigate("https://lihkg.com")
}

crack_it <- function(url){
  remote_driver$navigate(url)
  Sys.sleep(sample(seq(3, 5, by=0.001), 1))
  html <- remote_driver$getPageSource()
  if(grepl("recaptcha_widget", html[[1]])){
    readline(prompt="Captcha Detected. Press [enter] to continue after solving")
  }
  pg <-  read_html(html[[1]])
  return(pg)
}

scrape_page <- function(html, postid){
  #get_number
  number <- html %>% html_nodes("._36ZEkSvpdj_igmog0nluzh") %>%
    html_node("div div small ._3SqN3KZ8m8vCsD9FNcxcki") %>%
    html_text()
  #get_date
  date <- html %>% html_nodes("._36ZEkSvpdj_igmog0nluzh") %>%
    html_node("div div small .Ahi80YgykKo22njTSCzs_") %>%
    html_attr("data-tip")
  #get_uid
  uid <- html %>% html_nodes("._36ZEkSvpdj_igmog0nluzh") %>%
    html_node("div div small .ZZtOrmcIRcvdpnW09DzFk a") %>%
    html_attr('href')
  #get_text
  text <- html %>% html_nodes("._36ZEkSvpdj_igmog0nluzh") %>%
    html_node("div div .GAagiRXJU88Nul1M7Ai0H ._2cNsJna0_hV8tdMj3X6_gJ") %>%
    html_text()
  #get_upvote
  upvote <- html %>% html_nodes("._36ZEkSvpdj_igmog0nluzh") %>%
    html_node("._1jvTHwVJobs9nsM0JDYqKB+ ._1drI9FJC8tyquOpz5QRaqf") %>% html_text()
  #get_downvote
  downvote <- html %>% html_nodes("._36ZEkSvpdj_igmog0nluzh") %>%
    html_node("._2_VFV1QOZok8YhOTGa_3h9+ ._1drI9FJC8tyquOpz5QRaqf") %>% html_text()
  #get_collection_time
  collection_time <- Sys.time()
  #get_title
  top.text <- html %>% html_nodes("._2k_IfadJWjcLJlSKkz_R2- span") %>%
    html_text()
  title <- top.text[2]
  board <- top.text[1]
  newdf <- as.data.frame(cbind(number, date, uid, text, upvote, downvote))
  newdf$postid <- postid # This bit might fail if date etc is NULL
  newdf$title <- title
  newdf$board <- board
  newdf$collection_time <- collection_time
  return(newdf)
}

scrape_post <- function(postid){
  posts <- c()
  for(i in 1:999){
    attempt <- 1
    notdone <- TRUE
    nextpage <- FALSE

    while( notdone && attempt <= 4 ) { # Auto restart when fails
      print(paste0("Attempt: ", attempt))
      attempt <- attempt + 1
      try({
        html <- crack_it(paste0("https://lihkg.com/thread/", postid, "/page/", i))
        next.page <- html %>% html_node("._3omJTNzI7U7MErH1Cfr3gE+ ._3omJTNzI7U7MErH1Cfr3gE a") %>% html_text()
        titlewords <- html %>% html_nodes("._2k_IfadJWjcLJlSKkz_R2- span") %>% html_text() %>% length()
        if ("下一頁" %in% next.page){
          print(paste0("page ", i, " (to be continued)"))
          post <- scrape_page(html, postid)
          posts <- rbind(posts, post)
          nextpage <- TRUE
          notdone <- FALSE
        } else if (titlewords == 1){
          notdone <- FALSE
          posts <- data.frame(number = "ERROR", date = "ERROR", uid = "ERROR", text = "ERROR", upvote = "ERROR", downvote = "ERROR", postid = postid, title = "Deleted Post", board = "ERROR", collection_time = Sys.time())
          print("Empty Post, Skipping")
        } else {
          print(paste0("page ", i, " (last page)"))
          post <- scrape_page(html, postid)
          posts <- rbind(posts, post)
          notdone <- FALSE
        }
        lay_low()
      })
    } # End of While Loop
    if( notdone && attempt > 4 ){
      if (titlewords == 2 && nrow(posts) > 1){
        warning <- data.frame(number = "EMPTY LAST PAGE", date = "EMPTY LAST PAGE", uid = "ERROR", text = "ERROR", upvote = "ERROR", downvote = "ERROR", postid = postid, title = "Deleted Last Page", board = "ERROR", collection_time = Sys.time())
        posts <- rbind(posts, warning)
        print("Empty Last Page Detected")
        notdone <- FALSE
      } else {
        stop("Error, Stopping")
      }
    }
    if(nextpage){
      next
    }else if(!notdone){
      break
    }
  } # End of For Loop
  return(posts)
}

lay_low <- function(){
  Sys.sleep(sample(seq(1, 2, by=0.001), 1))
}

start_scraping <- function(){
  for (i in n:stopn){
    print(paste0("Downloading post: ", i))
    postid <<- i
    new.df <- scrape_post(i)
    lihkg_df <<- rbind(lihkg_df, new.df)
    print(tail(lihkg_df, 3))
    print(paste0("Displaying 3 of ", nrow(new.df), " new posts."))
    print(paste0("Corpus size: ", nrow(lihkg_df)))
    print(paste0("Finished scraping: ", i))

    if ((i / 5) %% 1 == 0){
      save.image("lihkg.RData")
      saveRDS(lihkg_df, file = "lihkg_df.rds")
      write.csv(lihkg_df, "lihkg_df.csv", row.names=FALSE, fileEncoding = "UTF-8")
      writeLines(as.character(postid), "lihkg_df_postid.txt")
      print(paste0("Backed up at post id: ", i))
    }
    n <<- i-1
  }
}

################ Step 1: Set Up (Only do once) ################
# You have to set the working directory
setwd("################")
# Only run the following ONCE, as this will remove all the data
init_scraper(startn = 1610753, stopn = 1610755, windows = FALSE)

################ Step 2: Launch Browser and Solve Captcha ################
launch_browser()
# Note: If your browser crashed, launch this again

################ Step 3: Start Scraping ################
start_scraping()
# Note: If your scraping stopped, run this again, it will continue automatically
