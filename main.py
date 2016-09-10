import json
import sys
from datetime import datetime
import tweepy
from tweepy.streaming import StreamListener
from tweepy import OAuthHandler
from tweepy import Stream
import psycopg2
# Python Config file config.py in the same directory
import config


def db_start():
    con = None

    try:
        con = psycopg2.connect(database=config.DB_NAME,
                               user=config.DB_USER,
                               host=config.DB_HOST,
                               password=config.DB_PASS)
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
                'id, tweet, username, name, location, url, followers_count, friends_count, ' \
                'listed_count, favourites_count, statuses_count, user_lang, favorited, ' \
                'retweeted, tweet_lang, timestamp_ms) ' \
                'VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s);'
        cur.execute(query, record)
        con.commit()
        cur.close()

    except psycopg2.DatabaseError as e:
        if con:
            con.rollback()
        print('Error %s' % e)


class StdOutListener(StreamListener):
    """ A listener handles tweets that are received from the stream.
    Prints basic tweet info and logs items of interest to the database.
    """
    def on_data(self, data):
        try:
            data = data.rstrip('\r\n')
            data = data.splitlines()
            data = ' '.join(data)
            dj = json.loads(data)
            db_record = (dj['id_str'],
                         dj['text'],
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
            print("[%s] User: %s, Name: %s, Location: %s, Tweet: %s" % (
                datetime.strftime(datetime.now(), '%Y/%m/%d %H:%M:%S'),
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
    con = db_start()

    l = StdOutListener()
    auth = OAuthHandler(config.TWITTER_KEY, config.TWITTER_SECRET)
    auth.secure = True
    auth.set_access_token(config.TWITTER_TOKEN, config.TWITTER_TOKEN_SECRET)
    api = tweepy.API(auth)

    # If the authentication was successful, you should
    # see the name of the account print out
    print(api.me().name)

    stream = Stream(auth, l)

    while True:
        try:
            stream.filter(track=config.SEARCH_KEYS)
        except AttributeError as e:
            print(e)
            sleep(5)
            continue
        except KeyboardInterrupt:
            break

