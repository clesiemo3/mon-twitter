import os
import json
import sys
from os.path import join, dirname
from dotenv import load_dotenv
import tweepy
from tweepy.streaming import StreamListener
from tweepy import OAuthHandler
from tweepy import Stream
import psycopg2


def db_start():
    con = None

    try:
        con = psycopg2.connect(database=os.environ.get("DB_NAME"),
                               user=os.environ.get("DB_USER"),
                               host=os.environ.get("DB_HOST"),
                               password=os.environ.get("DB_PASS"))
        return con
    except psycopg2.DatabaseError as e:

        if con:
            con.rollback()

        print('Error %s' % e)
        sys.exit(1)


def db_write(con, record):
    try:
        cur = con.cursor()
        query = 'INSERT INTO tweets( ' \
                'id, username, name, location, url, followers_count, friends_count, ' \
                'listed_count, favourites_count, statuses_count, user_lang, favorited, ' \
                'retweeted, tweet_lang, timestamp_ms) ' \
                'VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s);'
        cur.execute(query, record)
        con.commit()
        cur.close()

    except psycopg2.DatabaseError as e:
        if con:
            con.rollback()
        print('Error %s' % e)


class StdOutListener(StreamListener):
    """ A listener handles tweets that are received from the stream.
    This is a basic listener that just prints received tweets to stdout.
    """
    def on_data(self, data):
        try:
            data = data.rstrip('\r\n')
            dj = json.loads(data)
            db_record = (dj['id_str'],
                         dj['user']['screen_name'],
                         dj['user']['name'],
                         dj['user']['location'],
                         dj['user']['url'],
                         dj['user']['followers_count'],
                         dj['user']['friends_count'],
                         dj['user']['listed_count'],
                         dj['user']['favourites_count'],
                         dj['user']['statuses_count'],
                         dj['user']['lang'],
                         dj['favorited'],
                         dj['retweeted'],
                         dj['lang'],
                         dj['timestamp_ms']
                         )
            db_write(con, db_record)
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
    con = db_start()

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