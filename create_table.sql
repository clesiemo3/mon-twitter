CREATE TABLE tweets
(
  id character varying NOT NULL,
  tweet character varying,
  username character varying,
  name character varying,
  location character varying,
  url character varying,
  followers_count integer,
  friends_count integer,
  listed_count integer,
  favourites_count integer,
  statuses_count integer,
  user_lang character varying,
  favorited boolean,
  retweeted boolean,
  tweet_lang character varying,
  timestamp_ms character varying,
  create_dt timestamp with time zone NOT NULL DEFAULT now(),
  inactive_dt timestamp with time zone DEFAULT '9999-09-09 00:00:00-05'::timestamp with time zone,
  CONSTRAINT tweets_pkey PRIMARY KEY (id)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE tweets
  OWNER TO twpy;
