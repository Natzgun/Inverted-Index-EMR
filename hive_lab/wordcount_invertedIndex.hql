show databases;

create database lab;
use lab;

show tables;

CREATE TABLE if not exists don_quijote (line STRING)
ROW FORMAT DELIMITED
LINES TERMINATED BY '\n'
STORED AS TEXTFILE;


LOAD DATA INPATH '/quijote/quijote_part1.txt' INTO TABLE don_quijote;
LOAD DATA INPATH '/quijote/quijote_part2.txt' INTO TABLE don_quijote;

select * from don_quijote;

CREATE TABLE IF NOT EXISTS words AS
SELECT explode(split(line, ' ')) as word
FROM don_quijote
where trim(line) != '';

select * from words;


select word, count(1) as count
from words
group by word
order by count desc
limit 100;


-- Indicie invetido

CREATE EXTERNAL TABLE documentos (
    linea STRING
)
STORED AS TEXTFILE
LOCATION 's3a://hdfs-emr-bigdeita/input/frequency/';

SELECT
    INPUT__FILE__NAME,
    linea
FROM documentos
LIMIT 10;


CREATE table if not EXISTS tokens AS
SELECT 
    lower(word) AS palabra,
    regexp_extract(INPUT__FILE__NAME,'[^/]+$',0) AS documento
FROM documentos
LATERAL VIEW explode(
    split(
        regexp_replace(linea,'[^a-zA-Z0-9 ]',''),
        ' '
    )
) t AS word
WHERE word != ''
AND lower(word) IN ('erick', 'hive', 'wikipedia')
GROUP BY 
    lower(word), 
    regexp_extract(INPUT__FILE__NAME,'[^/]+$',0);

CREATE table if not exists inverted_index AS
SELECT 
    palabra,
    collect_set(documento) AS documentos
FROM tokens
GROUP BY palabra;

SELECT *
FROM inverted_index
WHERE palabra = 'erick';




