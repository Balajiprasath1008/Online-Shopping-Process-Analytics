create database miniproject;
use miniproject;
select * from cust_dimen;
select * from market_fact;
select * from orders_dimen;
select * from prod_dimen;
select * from shipping_dimen;

-- 1) Join all the tables and create a new table called combined_table.
-- (market_fact, cust_dimen, orders_dimen, prod_dimen, shipping_dimen)

create table combined_table as 
select a.customer_name ,a.province ,a.customer_segment ,a.cust_id ,b.prod_id ,b.sales,b.discount,
c.order_id,c.order_date,c.order_priority ,d.ship_mode ,d.ship_id, e.product_category  from cust_dimen as a join market_fact as b on a.cust_id=b.cust_id
 join orders_dimen as c on b.ord_id=c.ord_id join shipping_dimen as d 
on d.order_id = c.order_id join prod_dimen as e on e.prod_id =b.prod_id ;
select * from combined_table;

-- 2.	Find the top 3 customers who have the maximum number of orders
select distinct a.customer_name , a.cust_id ,count(b.prod_id) as total_count from cust_dimen as a join 
market_fact as b on a.cust_id =b.cust_id group by b.prod_id order by total_count desc limit 3 ;

select distinct a.customer_name , sum(order_quantity) over (partition by b.ord_id )as cnt from cust_dimen as a join 
market_fact as b on a.cust_id =b.cust_id group by a.customer_name order  by cnt desc limit 3  ; 

-- 3.	Create a new column DaysTakenForDelivery that contains the date difference of Order_Date and Ship_Date.
select * from shipping_dimen;
select * from orders_dimen;

select *,datediff(a,b) as daystaken_fordelivery from(select a.order_id , str_to_date(a.ship_date,'%d- %m- %y')a , str_to_date(b
.order_date,'%d- %m- %y')b , b.order_date 
from shipping_dimen as a join orders_dimen as b on a.order_id = b.order_id)t ;

-- 4.	Find the customer whose order took the maximum time to get delivered.
select *,datediff(a,b) as daystaken_fordelivery from(select a.order_id , str_to_date(a.ship_date,'%d- %m- %y')a , str_to_date(b
.order_date,'%d- %m- %y')b , b.order_date 
from shipping_dimen as a join orders_dimen as b on a.order_id = b.order_id)t order by daystaken_fordelivery desc limit 1 ;

-- 5.	Retrieve total sales made by each product from the data (use Windows function)
select * from market_fact;
select * from prod_dimen;
select distinct a.prod_id,b.product_category ,sum(a.sales) over(partition by a.prod_id ) from market_fact as a join prod_dimen as b on a.prod_id=b.prod_id ;
select distinct a.prod_id, b.product_category ,sum(a.sales) over(partition by b.product_sub_category) from market_fact as a join prod_dimen as b on a.prod_id=b.prod_id ;



-- 6.	Retrieve total profit made from each product from the data (use windows function)
select distinct a.prod_id,b.product_category ,sum(a.profit) over(partition by b.product_sub_category ) from market_fact as a join prod_dimen as b on a.prod_id=b.prod_id ;

-- 7.	Count the total number of unique customers in January and how many of them came back every month over the entire year in 2011
select * from cust_dimen;
select * from orders_dimen;
select * from market_fact;

-- (select * from man where YEARS LIKE '%JANUARY%' and years like '%2011%' )as jan_only 

-- select *, count(t.customer_name ) as jan2011,years as jan_only from (
-- select *, count(man.customer_name ) as tw11 ,years as total_years_counnt from 

-- (select  a.customer_name, count(a.customer_name ), a.cust_id,b.ord_id,date_format(str_to_date(c.order_date,'%d-%m-%Y'),"%M %Y") AS YEARS 
 -- from cust_dimen as a join market_fact as b on a.cust_id=b.cust_id 
-- join orders_dimen as c on c.ord_id=b.ord_id GROUP BY a.customer_name)man having years like '%2011%')t having years like '%JANUARY%' and years like '%2011% ;

select * from 
(select distinct a.customer_name, count(a.customer_name ), a.cust_id,b.ord_id,date_format(str_to_date(c.order_date,'%d-%m-%Y'),"%M %Y") AS YEARS 
 from cust_dimen as a join market_fact as b on a.cust_id=b.cust_id 
 join orders_dimen as c on c.ord_id=b.ord_id group by  a.cust_id HAVING  YEARS LIKE '%jan%' and years like '%2011%' )day1  inner join 
 
(select distinct a.customer_name, count(a.customer_name), a.cust_id,b.ord_id,date_format(str_to_date(c.order_date,'%d-%m-%Y'),"%M %Y") AS YEARS 
 from cust_dimen as a join market_fact as b on a.cust_id=b.cust_id   
 join orders_dimen as c on c.ord_id=b.ord_id group by  a.cust_id HAVING  years like '%2011%')day2 on day1.cust_id = day2.cust_id  ;

create table tab as 
(select distinct a.customer_name, count(a.customer_name), a.cust_id,b.ord_id,date_format(str_to_date(c.order_date,'%d-%m-%Y'),"%M %Y") AS YEARS 
 from cust_dimen as a join market_fact as b on a.cust_id=b.cust_id   
 join orders_dimen as c on c.ord_id=b.ord_id group by a.customer_name) ;

select * from tab;
select e1.customer_name , e1.years as only_2011, years < any (select e1.years from tab where e1.years like  '%jan%') 
from tab as e1 join tab as e2 on e1.ord_id = e2.ord_id where e1.years like '%2011%' and e1.years like '%jan%' ; 
-- and e2.years like '%2011%' and '%jan%';


 -- AND YEARS LIKE '%2011%'  HAVING YEARS LIKE '%2011' 
 
 -- 8.	Retrieve month-by-month customer retention rate since the start of the business.(using views)
 
 select * from cust_dimen;
 select * from orders_dimen;
select * from market_fact;

select * from combined_table;

select distinct customer_name,cust_id,prod_id,order_id,orders_date ,lagdate ,date_diff, case 
when date_diff <= 1 then "retained "
when date_diff > 1 then "irregular"
when date_diff is null then "churned"
end as summary
from 
(select customer_name,cust_id,prod_id,order_id,orders_date ,lag(orders_date) over(partition by cust_id order by orders_date) as lagdate,
(datediff(orders_date,difference_date))/31 as date_diff from
(select customer_name,cust_id,prod_id,orders_date,order_id , lag(orders_date) over(partition by cust_id order by orders_date) difference_date from
(select distinct customer_name,cust_id,prod_id,order_id,str_to_date(order_date,'%d-%m-%y') as orders_date from combined_table)A)B)C;

 
 