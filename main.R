library(httr)
library(twitteR)

myapp <- oauth_app("twitter",Sys.getenv("TWITTER_KEY"),Sys.getenv("TWITTER_SECRET"))
# The first time will ask to cache in local file .httr-oauth.
# Enter 1 for your selection and let the browser authenticate
twitter_token <- oauth1.0_token(oauth_endpoints("twitter"), myapp)
use_oauth_token(twitter_token)

tweets <- searchTwitter("monsanto",n=1500)
tw.df <- twListToDF(tweets)

words <- character()

for(tweet in tw.df[[1]]){
	text <- unlist(strsplit(tweet,"[^#@'’\"a-zA-Z0-9\\-]+"))
	# remove twitter links/RT words
	twitterWords <- c("t","co","http","https","RT","amp")
	text <- text[!text %in% twitterWords]
	# remove common words; mix of languages
	commonWords <- c("the","The","to","of","a","in","is",
					 "and","","de","by","for","la","has",
					 "on","se")
	text <- text[!text %in% commonWords]
	words <- c(words,text)
}

print(sort(table(words), decreasing=T)[1:25])
