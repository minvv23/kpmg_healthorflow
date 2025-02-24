library(RCurl)
library(XML)
library(stringr)
library(SnowballC)
library(tm)
library(wordcloud)
library(dplyr)
library(e1071)
library(xml2)
library(readr)
library(httr)
library(xlsx)

query <- c("가슴이+아파", "가슴이+두근", "열이+나")
word <- c("가슴이 아파", "가슴이 두근", "열이 나")

full.url <- paste0('https://www.hidoc.co.kr/integratesearch/searchhealthqnalist?query=', query, '&page=')
all.list <- list()

#all.q <- data.frame(0, 0, 0, 0, 0)
#colnames(all.q) <- c("주요증상", "주소", "질문제목", "질문내용", "답변내용")


for (k in 1:length(query)) {
  
  all.q <- data.frame(0, 0, 0, 0, 0)
  colnames(all.q) <- c("주요증상", "주소", "질문제목", "질문내용", "답변내용")
  
  num.url <- paste0(full.url[k], 1)
  num.html <- read_html(num.url, .encoding="UTF-8")
  num.html.parsed <- htmlParse(num.html)
  total.num <- xpathSApply(num.html.parsed, "//div[@class='coll_keyword']//strong[@class='fc_blue']", xmlValue)[2]
  total.num <- as.numeric(gsub("[^0-9.-]", "", total.num))
  total.page <- total.num%/%20 + 1
  total.page <- ifelse(total.page >= 250, 250, total.page)
  
  for (i in 1:total.page) {
    url <- paste0(full.url[k], i)
    html <- read_html(url, .encoding="UTF-8")
    html.parsed <- htmlParse(html)
    
    q_url <- xpathSApply(html.parsed, "//ul[@class='list_qna']/li/a", xmlGetAttr, 'href')
    q_url <- paste0("https://www.hidoc.co.kr", q_url)
    
    for (j in 1:length(q_url)) {
      q.url <- q_url[j]
      
      q_html <- read_html(q.url, .encoding = "UTF-8")
      q_html.parsed <- htmlParse(q_html)
      
      q.title <- xpathSApply(q_html.parsed, "//div[@class='box_type1 view_question']//strong[@class='tit']", xmlValue)
      
      q.exp <- xpathSApply(q_html.parsed, "//div[@class='box_type1 view_question']//div[@class='desc']", xmlValue)
      q.exp <- str_trim(q.exp)
      q.exp <- gsub(intToUtf8(160), "", q.exp)
      
      a.exp <- xpathSApply(q_html.parsed, "//div[@class='answer_body']//div[@class='desc']", xmlValue)[1]
      a.exp <- str_trim(a.exp)
      a.exp <- gsub(intToUtf8(160), "", a.exp)
      a.exp <- gsub(pattern = '\\.', replacement = ". ", a.exp)
      
      one.q = c(query[k], q.url, q.title, q.exp, a.exp)
      all.q <- rbind(all.q, one.q)
      
    }
  }
  file.name <- paste0(word[k], ".csv")
  all.q <- all.q[-c(1),]
  rownames(all.q) <- NULL
  write.csv(all.q, file = file.name)
}


####
chest <- read.csv("가슴이 두근.csv", stringsAsFactors = FALSE)
chest2 <- read.csv("흉통.csv", stringsAsFactors = FALSE)
chest <- rbind(chest1, chest2)
chest$X <- NULL
chest.all <- subset(chest, str_detect(chest$질문내용, "가슴|두근"))
chest.all <- chest.all %>% distinct(주소, .keep_all = TRUE)