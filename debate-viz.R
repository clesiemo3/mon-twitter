library(RPostgreSQL)
library(ggplot2)
library(scales)
library(dplyr)
library(gridExtra)


get_data <- function(){
	drv <- dbDriver("PostgreSQL")
	con <- dbConnect(drv,
					 dbname="twitter",
					 host="192.168.1.254",
					 user=Sys.getenv("DB_USER"),
					 password=Sys.getenv("DB_PASS"),
					 port="5432")
	on.exit(dbDisconnect(con))
	res <- dbSendQuery(con, "select tweet, retweet, tweet_lang, timestamp_ms from tweets where create_dt >= (now() - '1 day'::INTERVAL);")

	data <- dbFetch(res)

	#Clearing the result
	dbClearResult(res)

	#Function: dbClearResult (package DBI)
	res="PostgreSQLResult"

	#disconnect
	dbUnloadDriver(drv)
	return(data)
}

raw_dat <- get_data()

cst <- "America/Chicago"

raw_dat <- raw_dat %>% mutate(combined=tolower(paste(raw_dat$tweet,raw_dat$retweet)))

raw_dat <- raw_dat %>%
			mutate(trump = grepl("trump",raw_dat$combined)) %>%
			mutate(clinton = grepl("clinton",raw_dat$combined)) %>%
			mutate(debate = grepl("debate",raw_dat$combined))

dat <- raw_dat %>% filter(trump | clinton | debate) %>%
					select(combined, tweet_lang, timestamp_ms, trump, clinton)
dat$timestamp_ms <- as.POSIXct(as.numeric(dat$timestamp_ms)/1000, origin="1970-01-01", tz="America/Chicago")

top_lang <- dat %>% group_by(tweet_lang) %>% summarise(n=n()) %>% top_n(5,n) %>% arrange(-n)
dat$tweet_lang <- factor(dat$tweet_lang, levels=top_lang$tweet_lang)

top <- top_lang$n[[1]]
digits <- 10 ** (nchar(top)-2)
cap <- ceiling(top/digits)*digits

lims <- as.POSIXct(strptime(c("2016-09-26 20:00","2016-09-27 12:00"), tz=cst, format = "%Y-%m-%d %H:%M"))
plot_dat <- dat %>% filter(timestamp_ms > lims[[1]] & timestamp_ms < lims[[2]])
plot_dat <- dat %>% filter(tweet_lang %in% top_lang$tweet_lang) %>% select(tweet_lang)
gplot1 <- plot_dat %>% ggplot(aes(tweet_lang)) +
			geom_bar(aes(fill=tweet_lang)) +
			labs(x="Tweet Language") +
			ggtitle("Tweets by Language") +
			scale_y_continuous(breaks=seq(0,cap,digits*2.5),
							   limits=c(0,cap),
							   labels=scales::comma)


lims <- as.POSIXct(strptime(c("2016-09-26 20:00","2016-09-27 12:00"), tz=cst, format = "%Y-%m-%d %H:%M"))
plot_dat <- dat %>% filter(timestamp_ms > lims[[1]] & timestamp_ms < lims[[2]])
start_dt <- as.POSIXct(strptime("2016-09-26 20:00",tz=cst, format = "%Y-%m-%d %H:%M"))
finish_dt <- as.POSIXct(strptime("2016-09-26 21:30",tz=cst, format = "%Y-%m-%d %H:%M"))
gplot2 <- plot_dat %>% ggplot(aes(timestamp_ms)) +
	geom_line(stat="bin", bins=50) +
	labs(x="Hour (CST)", y="Number of Tweets") +
	geom_vline(xintercept = as.numeric(start_dt)) +
	geom_vline(xintercept = as.numeric(finish_dt)) +
	ggtitle("Tweets During and After Debate") +
	scale_y_continuous(breaks=seq(0,60000,10000), labels=scales::comma) +
	scale_x_datetime(breaks=date_breaks("1 hour"),
					 labels=date_format("%H", tz=cst),
					 limits=lims)


lims <- as.POSIXct(strptime(c("2016-09-26 20:00","2016-09-26 21:30"), tz=cst, format = "%Y-%m-%d %H:%M"))
plot_dat <- dat %>% filter(timestamp_ms > lims[[1]] & timestamp_ms < lims[[2]])
gplot3 <- plot_dat %>% ggplot(aes(timestamp_ms, color = "All Tweets")) +
	geom_line(stat="bin", bins=50) +
	geom_line(data = plot_dat[plot_dat$trump,], stat="bin", bins=50, aes(timestamp_ms, color = "Trump")) +
	geom_line(data = plot_dat[plot_dat$clinton,], stat="bin", bins=50, aes(timestamp_ms, color = "Clinton")) +
	labs(x="Time (CST)", y="Number of Tweets") +
	ggtitle("Tweets During Debate") +
	scale_y_continuous(breaks=seq(0,50000,1000), labels=scales::comma) +
	scale_colour_manual("Tweet Mentions",
						breaks = c("All Tweets", "Trump", "Clinton"),
						values = c("black", "blue", "red")) +
	scale_x_datetime(breaks=date_breaks("10 min"),
					 labels=date_format("%H:%M", tz=cst),
					 limits=lims)

png("DebateTweetStats.png", width=12, height=8, units="in", res=300)
grid.arrange(gplot1, gplot2, gplot3, layout_matrix=rbind(c(1,2),3), top="Tweets about the first presidential debate", nrow = 2)
dev.off()

##################
### word cloud ###
##################

library(tm)
library(SnowballC)
library(wordcloud)


split_tweet <- function(tweet){
	text <- unlist(strsplit(tweet,"[^#@'’\"a-zA-Z0-9\\-]+"))
	return(text)
}

lims <- as.POSIXct(strptime(c("2016-09-26 20:00","2016-09-26 21:30"), tz=cst, format = "%Y-%m-%d %H:%M"))
plot_dat <- dat %>% filter(timestamp_ms > lims[[1]] & timestamp_ms < lims[[2]])

words <- sapply(plot_dat$combined, split_tweet, USE.NAMES=F)
words <- sapply(words,tolower,USE.NAMES = F)
words_ul <- as.character(unlist(words))
words_ul <- gsub("#","",words_ul)

built_in_stop <- unlist(sapply(top_lang[top_lang$tweet_lang!="und",]$tweet_lang, stopwords))
# remove twitter links/RT words
twitter_words <- c("t","co","http","https","rt","amp","#")
# common words
common_words <- c("the","The","to","of","a","in","is",
				  "and","","de","by","for","la","has",
				  "on","se","it","with","that","que",
				  "al","as","y","en","s","t","el","es",
				  "a","at","S","r","un","m","u","n","por",
				  "d","te","via","le","an","i","la","para",
				  "los","-")
my_stop_words <- c(built_in_stop,twitter_words,common_words)

words.df <- data.frame(table(words_ul))
words.df <- words.df %>% rename(words=words_ul)
words.df$words <- as.character(words.df$words)
words.filtered <- words.df %>% filter(!words %in% my_stop_words) %>% arrange(-Freq) %>% head(100)

# save the image in png format
png("DebateTweetCloud.png", width=12, height=8, units="in", res=300)
wordcloud(words.filtered$words,words.filtered$Freq, scale=c(6,.5),
		  max.words = 50, random.order=F,
		  colors=brewer.pal(8, "Dark2"))
dev.off()

