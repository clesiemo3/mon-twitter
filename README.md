# mon-twitter

Python for dumping tweets that contain a given string (e.g. "monsanto") into a database for analytics later.

Requires a .env file with the below. Alternatively a config.py file could be used and imported. If so, you do not need python-dotenv==0.5.1

```
TWITTER_KEY=
TWITTER_SECRET=
TWITTER_TOKEN=
TWITTER_TOKEN_SECRET=
DB_NAME=
DB_USER=
DB_PASS=
DB_HOST=
```