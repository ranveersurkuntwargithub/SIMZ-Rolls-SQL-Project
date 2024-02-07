Create database rolls_information ;
Use rolls_information;
drop table if exists driver;
CREATE TABLE driver(driver_id integer,reg_date date); 

INSERT INTO driver (driver_id, reg_date)
VALUES 
    (1, '2021-01-01'),
    (2, '2021-01-03'),
    (3, '2021-01-08'),
    (4, '2021-01-15');


drop table if exists ingredients;
CREATE TABLE ingredients(ingredients_id integer,ingredients_name varchar(60)); 

INSERT INTO ingredients(ingredients_id ,ingredients_name) 
 VALUES (1,'BBQ Chicken'),
(2,'Chilli Sauce'),
(3,'Chicken'),
(4,'Cheese'),
(5,'Kebab'),
(6,'Mushrooms'),
(7,'Onions'),
(8,'Egg'),
(9,'Peppers'),
(10,'schezwan sauce'),
(11,'Tomatoes'),
(12,'Tomato Sauce');

drop table if exists rolls;
CREATE TABLE rolls(roll_id integer,roll_name varchar(30)); 

INSERT INTO rolls(roll_id ,roll_name) 
 VALUES (1	,'Non Veg Roll'),
(2	,'Veg Roll');

drop table if exists rolls_recipes;
CREATE TABLE rolls_recipes(roll_id integer,ingredients varchar(24)); 

INSERT INTO rolls_recipes(roll_id ,ingredients) 
 VALUES (1,'1,2,3,4,5,6,8,10'),
(2,'4,6,7,9,11,12');

drop table if exists driver_order;
CREATE TABLE driver_order(order_id integer,driver_id integer,pickup_time datetime,distance VARCHAR(7),duration VARCHAR(10),cancellation VARCHAR(23));
INSERT INTO driver_order (order_id, driver_id, pickup_time, distance, duration, cancellation)
VALUES 
    (1, 1, '2021-01-01 18:15:34', '20km', '32 minutes', ''),
    (2, 1, '2021-01-01 19:10:54', '20km', '27 minutes', ''),
    (3, 1, '2021-01-03 00:12:37', '13.4km', '20 mins', 'NaN'),
    (4, 2, '2021-01-04 13:53:03', '23.4', '40', 'NaN'),
    (5, 3, '2021-01-08 21:10:57', '10', '15', 'NaN'),
    (6, 3, NULL, NULL, NULL, 'Cancellation'),
    (7, 2, '2020-01-08 21:30:45', '25km', '25mins', NULL),
    (8, 2, '2020-01-10 00:15:02', '23.4 km', '15 minute', NULL),
    (9, 2, NULL, NULL, NULL, 'Customer Cancellation'),
    (10, 1, '2020-01-11 18:50:20', '10km', '10minutes', NULL);


drop table if exists customer_orders;
CREATE TABLE customer_orders(order_id integer,customer_id integer,roll_id integer,not_include_items VARCHAR(4),extra_items_included VARCHAR(4),order_date datetime);
INSERT INTO customer_orders (order_id, customer_id, roll_id, not_include_items, extra_items_included, order_date)
VALUES 
    (1, 101, 1, '', '', '2021-01-01 18:05:02'),
    (2, 101, 1, '', '', '2021-01-01 19:00:52'),
    (3, 102, 1, '', '', '2021-01-02 23:51:23'),
    (3, 102, 2, '', 'NaN', '2021-01-02 23:51:23'),
    (4, 103, 1, '4', '', '2021-01-04 13:23:46'),
    (4, 103, 1, '4', '', '2021-01-04 13:23:46'),
    (4, 103, 2, '4', '', '2021-01-04 13:23:46'),
    (5, 104, 1, NULL, '1', '2021-01-08 21:00:29'),
    (6, 101, 2, NULL, NULL, '2021-01-08 21:03:13'),
    (7, 105, 2, NULL, '1', '2021-01-08 21:20:29'),
    (8, 102, 1, NULL, NULL, '2021-01-09 23:54:33'),
    (9, 103, 1, '4', '1,5', '2021-01-10 11:22:59'),
    (10, 104, 1, NULL, NULL, '2021-01-11 18:34:49'),
    (10, 104, 1, '2,6', '1,4', '2021-01-11 18:34:49');



select * from customer_orders;
select * from driver_order;
select * from ingredients;
select * from driver;
select * from rolls;
select * from rolls_recipes;





-- 1. How many rolls were ordered?
SELECT 
    COUNT(roll_id) AS total_rolls
FROM
    customer_orders;

-- 2. How many customers  ordered rolls?

SELECT 
    COUNT(DISTINCT order_id) AS total_orders
FROM
    customer_orders;


-- 3. How many orders were successfully delivered by each driver?

SELECT 
    do.driver_id, COUNT(do.order_id) AS total_orders
FROM
    driver_order AS do
WHERE
    do.cancellation NOT IN ('cancellation' , 'Customer Cancellation')
GROUP BY do.driver_id;

-- 4. How many each type of rolls were delivered?

with total_delivers as (
    select order_id, r.roll_name, r.roll_id, count(order_id) as total_orders 
    from rolls r 
    join customer_orders co on r.roll_id = co.roll_id 
    group by roll_name, roll_id, order_id
)
select roll_name, roll_id, sum(total_orders) as total_orders
from total_delivers 
where order_id not in ( 
    select order_id 
    from driver_order 
    where cancellation in ('cancellation', 'Customer Cancellation')
)
group by roll_name, roll_id;


-- 5. How many veg and non-veg rolls  were ordered by each customer?

SELECT 
    co.customer_id,
    r.roll_name,
    COUNT(co.order_id) AS total_orders
FROM
    customer_orders AS co
        JOIN
    rolls AS r ON r.roll_id = co.roll_id
GROUP BY co.customer_id , r.roll_name
order by customer_id ;

-- 6. What was the maximum number of rolls delivered in single delivery?

with max_order as ( select order_id,count(order_id) as total_orders 
from  customer_orders 
group by order_id 
order by total_orders desc limit 1 )
select * from max_order 
where order_id not in (select order_id from driver_order where cancellation in ('cancellation', 'Customer Cancellation'));


-- 7. How many rolls were delivered which had both inclusions and extras?

SELECT 
    COUNT(roll_id) AS total_rolls_delivered
FROM
    customer_orders
WHERE
    not_include_items
        OR extra_items_included > 0
        AND order_id NOT IN (SELECT 
            order_id
        FROM
            driver_order
        WHERE
            cancellation IN ('cancellation' , 'Customer Cancellation'));


-- 8. What was the total number of rolls ordered each hour?

SELECT 
    CONCAT(EXTRACT(HOUR FROM order_date),
            ' to ',
            EXTRACT(HOUR FROM order_date) + 1) AS hour_interval,
    COUNT(order_id) AS total_orders_per_hour
FROM
    customer_orders
GROUP BY hour_interval
ORDER BY hour_interval;


-- 9. What was the number of orders for each day of the week?

SELECT 
    DAYNAME(order_date) AS day_of_week,
    COUNT( distinct order_id) AS total_orders_of_day
FROM
    customer_orders
GROUP BY day_of_week
ORDER BY day_of_week;

-- 10. What was the average  distance travelled for each customer?

SELECT 
    customer_id, ROUND(AVG(distance), 2) AS avg_distance_km
FROM
    driver_order do
        JOIN
    customer_orders co ON do.order_id = co.order_id
GROUP BY customer_id;

-- 11. What is the average  time taken to deliver an order?

WITH cte AS (
    SELECT 
        COUNT(order_id) AS total_order,
        SUM(duration) AS total_duration 
    FROM 
        driver_order 
    WHERE 
        duration IS NOT NULL
)
SELECT 
    CAST(total_duration AS float ) / total_order AS Average_duration_for_an_Delivery 
FROM 
    cte;


-- 12.What is the difference  between the longest and the shortest delivery time for all orders?

SELECT 
    CONCAT(MAX(duration), ' ', 'Minutes') AS longest_time,
    MIN(duration) AS shortest_time,
    CONCAT(MAX(duration) - MIN(duration),
            ' ',
            'Minutes') AS diff_delivery_time
FROM
    driver_order;



-- 13.What is the average speed for each driver each delivery?
SELECT 
    order_id,
    driver_id,
    distance,
    duration,
    ROUND(CONCAT((distance* 1000) / (duration * 60),2), ' m/s') AS 'speed in (m/s)'
FROM (
    SELECT 
        order_id, 
        driver_id,
        CAST((distance) AS FLOAT) AS distance,
        CAST(LEFT(duration, 2) AS FLOAT) AS duration
    FROM 
        driver_order 
    WHERE 
        distance IS NOT NULL
) AS a;



-- 14. What is cancellation percentage for each driver?

WITH cte AS (
    SELECT 
        driver_id,
        COUNT(driver_id) AS total_orders,
        SUM(CASE WHEN cancellation IN ('cancellation', 'Customer Cancellation') THEN 1 ELSE 0 END) AS total_cancellations
    FROM 
        driver_order 
    GROUP BY 
        driver_id
)
SELECT 
    driver_id,
    CONCAT(ROUND((total_cancellations * 100.0) / total_orders, 2), '%') AS cancellation_percentage
FROM 
    cte; 
