show databases;
create database newyork;
use newyork;

show tables;

DROP TABLE IF EXISTS yellow_taxi_raw;

CREATE EXTERNAL TABLE yellow_taxi_raw (
    VendorID INT,
    tpep_pickup_datetime BIGINT,
    tpep_dropoff_datetime BIGINT,
    passenger_count DOUBLE,
    trip_distance DOUBLE,
    RatecodeID DOUBLE,
    store_and_fwd_flag STRING,
    PULocationID INT,
    DOLocationID INT,
    payment_type DOUBLE,
    fare_amount DOUBLE,
    extra DOUBLE,
    mta_tax DOUBLE,
    tip_amount DOUBLE,
    tolls_amount DOUBLE,
    improvement_surcharge DOUBLE,
    total_amount DOUBLE,
    congestion_surcharge DOUBLE,
    airport_fee DOUBLE,
    cbd_congestion_fee DOUBLE
)
STORED AS PARQUET
LOCATION '/user/hadoop/yellow_taxi/raw';

select * from yellow_taxi_raw limit 10;


SET hive.exec.dynamic.partition = true;
SET hive.exec.dynamic.partition.mode = nonstrict;


drop table yellow_taxi_partitioned;

CREATE EXTERNAL TABLE yellow_taxi_partitioned (
    VendorID              INT,
    tpep_pickup_datetime  TIMESTAMP,
    tpep_dropoff_datetime TIMESTAMP,
    passenger_count       DOUBLE,
    trip_distance         DOUBLE,
    RatecodeID            DOUBLE,
    store_and_fwd_flag    STRING,
    PULocationID          INT,
    DOLocationID          INT,
    payment_type          DOUBLE,
    fare_amount           DOUBLE,
    extra                 DOUBLE,
    mta_tax               DOUBLE,
    tip_amount            DOUBLE,
    tolls_amount          DOUBLE,
    improvement_surcharge DOUBLE,
    total_amount          DOUBLE,
    congestion_surcharge  DOUBLE,
    airport_fee           DOUBLE,
    cbd_congestion_fee    DOUBLE
)
PARTITIONED BY (year INT, month INT)
STORED AS PARQUET
LOCATION '/user/hadoop/yellow_taxi/partitioned';


INSERT INTO TABLE yellow_taxi_partitioned
PARTITION (year, month)
SELECT
    VendorID,
    FROM_UNIXTIME(CAST(tpep_pickup_datetime  / 1000000 AS BIGINT)) AS tpep_pickup_datetime,
    FROM_UNIXTIME(CAST(tpep_dropoff_datetime / 1000000 AS BIGINT)) AS tpep_dropoff_datetime,
    passenger_count,
    trip_distance,
    RatecodeID,
    store_and_fwd_flag,
    PULocationID,
    DOLocationID,
    payment_type,
    fare_amount,
    extra,
    mta_tax,
    tip_amount,
    tolls_amount,
    improvement_surcharge,
    total_amount,
    congestion_surcharge,
    airport_fee,
    cbd_congestion_fee,
    YEAR(FROM_UNIXTIME(CAST(tpep_pickup_datetime  / 1000000 AS BIGINT))) AS year,
    MONTH(FROM_UNIXTIME(CAST(tpep_pickup_datetime / 1000000 AS BIGINT))) AS month
FROM yellow_taxi_raw
WHERE tpep_pickup_datetime IS NOT NULL
  AND YEAR(FROM_UNIXTIME(CAST(tpep_pickup_datetime / 1000000 AS BIGINT))) = 2026;


SHOW PARTITIONS yellow_taxi_partitioned;

select * from yellow_taxi_partitioned limit 10;

-- Ejercicios
-- (Total viajes, promedio distancia, Horas mayor tráfico, métodos
-- de pago utilizado, Top viajes costosos, consultas con particiones)

-- Total viajes

select count(1) as total_viajes
from yellow_taxi_partitioned;

select count(1) as total_viajes_abril
from yellow_taxi_partitioned
where year = 2026 and month = 4;

-- Promedio distancia

select 
	year,
	month,
	count(*) as total_viajes,
	round(avg(trip_distance), 2) as distancia_promedio_millas,
	round(avg(fare_amount), 2) as tarifa_promedio,
	round(avg(total_amount), 2) as promedio_total
from yellow_taxi_partitioned
group by year, month
order by year, month;
	

-- Horas con mayor trafico

select
	HOUR(tpep_pickup_datetime) as hora,
	count(1) as total_viajes,
	round(avg(trip_distance),2) as distancia_promedio
from yellow_taxi_partitioned
group by hour(tpep_pickup_datetime)
order by total_viajes desc;

-- Tipos de pago

CREATE TEMPORARY MACRO metodo_pago(tipo INT)
CASE tipo
    WHEN 0 THEN 'Flex Fare Trip'
    WHEN 1 THEN 'Credit Card'
    WHEN 2 THEN 'Cash'
    WHEN 3 THEN 'No Charge'
    WHEN 4 THEN 'Dispute'
    WHEN 5 THEN 'Unknown'
    ELSE 'voided trip'
END;

select 
    metodo_pago(cast(payment_type as int)) as payment_method,
    count(1) as total_viajes
from yellow_taxi_partitioned
group by metodo_pago(cast(payment_type as int));


-- TOP 10 viajes costos

select
    tpep_pickup_datetime as fecha,
	total_amount as pago_total,
	tip_amount as propina,
	ROUND(
        (UNIX_TIMESTAMP(tpep_dropoff_datetime) - UNIX_TIMESTAMP(tpep_pickup_datetime)) / 3600
    , 1) duracion_viaje_horas
from yellow_taxi_partitioned
order by total_amount desc
limit 10;
	

-- Comparativa de los 4 meses
SELECT
    month,
    COUNT(*) AS total_viajes,
    ROUND(AVG(trip_distance), 2) AS promedio_distancia,
    ROUND(AVG(total_amount), 2) AS promedio_tarifa,
    ROUND(SUM(total_amount), 2) AS ingresos_totales
FROM yellow_taxi_partitioned
WHERE year = 2026 AND month IN (1, 2, 3, 4)
GROUP BY month
ORDER BY month;


-- Dia de la semana con mas viajes
SELECT
    DAYOFWEEK(tpep_pickup_datetime)  AS dia_semana,
    CASE DAYOFWEEK(tpep_pickup_datetime)
        WHEN 1 THEN 'Domingo'
        WHEN 2 THEN 'Lunes'
        WHEN 3 THEN 'Martes'
        WHEN 4 THEN 'Miercoles'
        WHEN 5 THEN 'Jueves'
        WHEN 6 THEN 'Viernes'
        WHEN 7 THEN 'Sabado'
    END AS nombre_dia,
    COUNT(1) AS total_viajes
FROM yellow_taxi_partitioned
WHERE year = 2026 AND month = 1
GROUP BY DAYOFWEEK(tpep_pickup_datetime)
ORDER BY total_viajes DESC;


	
	
	
	
	


