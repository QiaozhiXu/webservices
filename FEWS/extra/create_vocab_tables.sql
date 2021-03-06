CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS fuzzystrmatch;
CREATE EXTENSION IF NOT EXISTS postgis_tiger_geocoder;
CREATE EXTENSION IF NOT EXISTS hstore;
CREATE SCHEMA IF NOT EXISTS factextract;

CREATE TABLE IF NOT EXISTS factextract.vocab_topic
(
    topic_id SERIAL PRIMARY KEY,
    topic VARCHAR(50) NOT NULL UNIQUE,
    schema VARCHAR(50) DEFAULT 'topic' NOT NULL
);

CREATE TABLE IF NOT EXISTS factextract.vocab_keyword
(
    keyword_id SERIAL PRIMARY KEY,
    topic_id INT NOT NULL REFERENCES factextract.vocab_topic (topic_id) ON DELETE CASCADE,
    keyword VARCHAR(50) NOT NULL,
    UNIQUE (topic_id, keyword)
);
