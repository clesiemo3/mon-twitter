# mon-twitter

Python for dumping tweets that contain a given string (or strings) (e.g. "monsanto") into a database for analytics later.

Requires a config.py file with the below information:

```
TWITTER_KEY = abc123
TWITTER_SECRET = def456
TWITTER_TOKEN = ghi789
TWITTER_TOKEN_SECRET = jkl101112
DB_NAME = mydb
DB_USER = username
DB_PASS = password
DB_HOST = 192.168.1.1
SEARCH_KEYS = ['monsanto', 'gmo']
```

R code uses the following .Renviron file:

```
TWITTER_KEY=
TWITTER_SECRET=
DB_USER=
DB_PASS=
```
