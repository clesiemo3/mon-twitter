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
	res <- dbSendQuery(con, "select * from tweets;")

	data <- dbFetch(res)

	#Clearing the result
	dbClearResult(res)

	#Function: dbClearResult (package DBI)
	res="PostgreSQLResult"

	#disconnect
	dbDisconnect(con)
	dbUnloadDriver(drv)
	return(data)
}

raw_dat <- get_data()

monsanto_tz <- "America/Chicago"
dat <- raw_dat %>% filter(grepl("(monsanto|gmo|bayer)",tolower(raw_dat$tweet))) %>% select(tweet_lang, timestamp_ms)
dat$timestamp_ms <- as.POSIXct(as.numeric(dat$timestamp_ms)/1000, origin="1970-01-01", tz="America/Chicago")

lims <- as.POSIXct(strptime(c("2016-09-11 00:00","2016-09-16 23:59"), tz=monsanto_tz, format = "%Y-%m-%d %H:%M"))
dat <- dat %>% filter(timestamp_ms >= lims[[1]] & timestamp_ms <= lims[[2]])

top_lang <- dat %>% group_by(tweet_lang) %>% summarise(n=n()) %>% top_n(5,n) %>% arrange(-n)
dat$tweet_lang <- factor(dat$tweet_lang, levels=top_lang$tweet_lang)

top <- top_lang$n[[1]]
digits <- 10 ** (nchar(top)-2)
cap <- ceiling(top/digits)*digits
plot_dat <- dat %>% filter(tweet_lang %in% top_lang$tweet_lang) %>% select(tweet_lang)
gplot1 <- plot_dat %>% ggplot(aes(tweet_lang)) +
			geom_bar(aes(fill=tweet_lang)) +
			labs(x="Tweet Language") +
			ggtitle("Tweets by Language 9-11 to 9-16") +
			scale_y_continuous(breaks=seq(0,cap,digits*2.5),
							   limits=c(0,cap),
							   labels=scales::comma)


gplot2 <- dat %>% ggplot(aes(timestamp_ms)) +
			geom_line(stat="bin", bins=50) +
			labs(x="day") +
			ggtitle("Tweets 9-11 to 9-16") +
			scale_y_continuous(labels=scales::comma) +
			scale_x_datetime(breaks=date_breaks("1 day"),
							 labels=date_format("%d"),
							 limits=lims)

lims <- as.POSIXct(strptime(c("2016-09-14 00:00","2016-09-14 23:59"), tz=monsanto_tz, format = "%Y-%m-%d %H:%M"))
plot_dat <- dat %>% filter(timestamp_ms >= lims[[1]] & timestamp_ms <= lims[[2]])
press_release_dt <- as.POSIXct(strptime("2016-09-14 06:30",tz=monsanto_tz, format = "%Y-%m-%d %H:%M"))
gplot3 <- plot_dat %>% ggplot(aes(timestamp_ms)) +
	geom_line(stat="bin", bins=50) +
	labs(x="Hour") +
	geom_vline(xintercept = as.numeric(press_release_dt)) +
	annotate("text", x=press_release_dt+3600*3, y=2000, label="<= Monsanto Tweets \nPress Release") +
	ggtitle("Tweets on 9-14 - Merger Announced") +
	scale_y_continuous(breaks=seq(0,8000,1000), labels=scales::comma) +
	scale_x_datetime(breaks=date_breaks("1 hour"),
					 labels=date_format("%H", tz=monsanto_tz),
					 limits=lims)

png("TweetStats.png", width=12, height=8, units="in", res=300)
grid.arrange(gplot1, gplot2, gplot3, layout_matrix=rbind(c(1,2),3), top="Tweets containing monsanto, gmo, and bayer", nrow = 2)
dev.off()

#source("common-words.R")
