import os
import json
from os.path import join, dirname
from dotenv import load_dotenv
import tweepy
from tweepy.streaming import StreamListener
from tweepy import OAuthHandler
from tweepy import Stream


class StdOutListener(StreamListener):
    """ A listener handles tweets that are received from the stream.
    This is a basic listener that just prints received tweets to stdout.
    """
    def on_data(self, data):
        try:
            data = data.rstrip('\r\n')
            dj = json.loads(data)
            print("User: %s, Name: %s, Location: %s, Tweet: %s" % (
                dj['user']['screen_name'],
                dj['user']['name'],
                dj['user']['location'],
                dj['text']))
        except KeyError:
            print(data)
        return True

    def on_error(self, status):
        print(status)

if __name__ == '__main__':
    dotenv_path = join(dirname(__file__), '.env')
    load_dotenv(dotenv_path)

    l = StdOutListener()
    auth = tweepy.OAuthHandler(os.environ.get("TWITTER_KEY"), os.environ.get("TWITTER_SECRET"))
    auth.secure = True
    auth.set_access_token(os.environ.get("TWITTER_TOKEN"), os.environ.get("TWITTER_TOKEN_SECRET"))
    api = tweepy.API(auth)

    # If the authentication was successful, you should
    # see the name of the account print out
    print(api.me().name)

    stream = Stream(auth, l)
    stream.filter(track=['monsanto'])
