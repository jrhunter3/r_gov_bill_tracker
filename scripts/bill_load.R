#install.packages('tidyverse')
#install.packages('lubridate')
#install.packages('rvest')
#install.packages('parallel')

library('tidyverse')
library('lubridate')
library('rvest')
library('parallel')
options(scipen = 999, stringsAsFactors = F)

num_cores <- detectCores()-1
cl <- makeCluster(num_cores)
clusterEvalQ(cl, library(rvest))

##### Pull House Bill List For Session #####
session <- 116
hr_blocks <- read_html(str_c('https://www.govinfo.gov/wssearch/rb//bills/',
                             session, '/hr?fetchChildrenOnly=1&offset=0&pageSize=500'))
hr_blocks <- html_text(hr_blocks)
hr_blocks <- str_extract_all(hr_blocks, pattern = '(?<=hr/).*?(?<=])')[[1]]
hr_blocks <- unique(str_replace_all(hr_blocks, ' ', ''))

##### Pull First 100 House Bill Information #####
hr_bills <- read_html(str_c('https://www.govinfo.gov/wssearch/rb//bills/116/hr/', 
                            hr_blocks[1], '?fetchChildrenOnly=1&offset=0&pageSize=500'))
hr_bills <- html_text(hr_bills)

##### Combining Information Into A DataFrame #####
bills_table <- data.frame(
  index = str_extract_all(hr_bills, pattern = '(?<=browseline1":").*?(?=\",)')[[1]],
  long_title = str_extract_all(hr_bills, pattern = '(?<=title":").*?(?=\",)')[[1]],
  short_title = str_extract_all(hr_bills, pattern = '(?<=shortTitle":").*?(?=\",)')[[1]],
  text_path = str_c('https://www.govinfo.gov/content/pkg/',
                    str_extract_all(hr_bills, pattern = '(?<=textfile":").*?(?=\",)')[[1]])
)

##### Testing Out Ways to Collect Bill Text For Analysis #####
short_test = head(bills_table)

clusterExport(cl, "short_test")

test_results <- do.call('rbind', parLapply(cl,
                                           1:nrow(short_test),
                                           function(x) {
                                             html_text(html_node(read_html(short_test$text_path[x]),
                                                                 xpath = '//pre'))
                                             }))

#html_text(html_node(read_html(bills_table$text_path[1]), xpath = '//pre'))


