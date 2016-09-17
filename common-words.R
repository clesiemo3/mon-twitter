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
words_ul <- as.character(unlist(words))

built_in_stop <- unlist(sapply(top_lang$tweet_lang, stopwords))
# remove twitter links/RT words
twitter_words <- c("t","co","http","https","RT","amp")
# common words
common_words <- c("the","The","to","of","a","in","is",
				 "and","","de","by","for","la","has",
				 "on","se","it","with","that","que",
				 "al","as","y","en","s","t","el","es",
				 "A","at","S","r","un","m","U","n","por",
				 "d","te","via","le","an","I","La","para",
				 "los","-")
my_stop_words <- c(built_in_stop,twitter_words,common_words)

#corpus-ify
#294k 1.2Gb
my_corpus <- Corpus(VectorSource(words))

#convert to text doc
my_corpus <- tm_map(my_corpus, PlainTextDocument)

#remove undesirables
my_corpus <- tm_map(my_corpus, removePunctuation)
my_corpus <- tm_map(my_corpus, removeWords, my_stop_words)

#stem
my_corpus <- tm_map(my_corpus, stemDocument)

#cloud
wordcloud(my_corpus, max.words = 50, random.order = FALSE, use.r.layout = T)
