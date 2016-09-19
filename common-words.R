#word stats#
library(tm)
library(SnowballC)
library(wordcloud)


split_tweet <- function(tweet){
	text <- unlist(strsplit(tweet,"[^#@'’\"a-zA-Z0-9\\-]+"))
	return(text)
}

# Use raw_dat from tweet-viz.R
monsanto_tz <- "America/Chicago"
dat <- raw_dat %>% filter(grepl("(monsanto|gmo|bayer)",tolower(raw_dat$tweet))) %>% select(tweet, timestamp_ms)
dat$timestamp_ms <- as.POSIXct(as.numeric(dat$timestamp_ms)/1000, origin="1970-01-01", tz="America/Chicago")

lims <- as.POSIXct(strptime(c("2016-09-11 00:00","2016-09-16 23:59"), tz=monsanto_tz, format = "%Y-%m-%d %H:%M"))
dat <- dat %>% filter(timestamp_ms >= lims[[1]] & timestamp_ms <= lims[[2]])

words <- sapply(dat$tweet, split_tweet, USE.NAMES=F)
words <- sapply(words,tolower,USE.NAMES = F)
words_ul <- as.character(unlist(words))
words_ul <- gsub("#","",words_ul)

built_in_stop <- unlist(sapply(top_lang$tweet_lang, stopwords))
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
words.filtered <- words.df %>% filter(!words %in% my_stop_words) %>% arrange(-Freq) %>% head(50)

# save the image in png format
png("TweetCloud.png", width=12, height=8, units="in", res=300)
wordcloud(words.filtered$words,words.filtered$Freq, scale=c(6,.5),
		  max.words = 25, random.order=F,
		  colors=brewer.pal(8, "Dark2"))
dev.off()
