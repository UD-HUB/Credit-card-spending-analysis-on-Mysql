select * from credit_card.credit_card_transactions;
UPDATE credit_card.credit_card_transactions SET transaction_date = STR_TO_DATE(transaction_date, '%d-%b-%y');
select max(transaction_date),min(transaction_date) from credit_card.credit_card_transactions; -- 10-2013 - 05-2015
select distinct card_type from credit_card.credit_card_transactions; -- Gold, Platinum, Silver, Signature
select distinct exp_type from credit_card.credit_card_transactions; -- Bills, Food, Entertainment, Grocery, Fuel, Travel

#1- write a query to print top 5 cities with highest spends and 
-- their percentage contribution of total credit card spends 
with total_spend as (select city, sum(amount) as total_spent
from credit_card.credit_card_transactions
group by city),
total_amount as (select sum(amount) as total_amount from credit_card.credit_card_transactions)
select city, total_spent, 100*(total_spent/total_amount) as percent_contribution
from total_spend, total_amount
order by total_spent desc
limit 5;


#2- write a query to print highest spend month and 
-- amount spent in that month for each card type
select mon, yr, card_type, total from
(select month(transaction_date) as mon, year(transaction_date) as yr, card_type, sum(amount) as total, 
dense_rank()over(partition by card_type order by sum(amount) desc) as rnk
from credit_card.credit_card_transactions
group by month(transaction_date), card_type,year(transaction_date))a
where rnk = 1;

#3 write a query to print the transaction details (all columns from the table)
-- for each card type when it reaches a cumulative of 1000000 total spends
-- (We should have 4 rows in the o/p one for each card type)
with cte as (select *, sum(amount)over (partition by card_type order by transaction_date,transaction_id ) cs
from credit_card_transactions),
cte2 as (select *, dense_rank() over (partition by card_type order by cs) ds from cte
where cs>1000000)
select * from cte2 where ds =1;

#4 write a query to find city which had lowest percentage spend for gold card type
-- total gold card spendings
with citygold as (select city, card_type, sum(amount) as total_spent 
from credit_card.credit_card_transactions
where card_type = 'gold'
group by city, card_type),
totalgold as ( select sum(amount) as gold_total from credit_card.credit_card_transactions where card_type = 'gold')
select city, card_type, 100*(total_spent/gold_total) as perc_spend from citygold,totalgold
order by perc_spend
limit 1;

-- city wise gold card spending
with cte1 as (
select city, card_type, sum(amount) as total_amount, sum(case when card_type = 'gold' then amount end) as gold_amount
from credit_card.credit_card_transactions
group by city, card_type)
select city, card_type,gold_amount, 100*(gold_amount/city_total) as perc_gold from (select city, card_type, gold_amount,sum(total_amount) over (partition by city) as city_total from cte1)a
where card_type = 'gold'
order by perc_gold asc
limit 1;

-- city don't spend for gold card
with cte1 as (
select city, card_type, sum(amount) as total_amount, 
sum(case when card_type = 'gold' then amount else 0 end) as gold_amount
from credit_card.credit_card_transactions
group by city, card_type)
select city, sum(gold_amount)/sum(total_amount) as gold_ratio
from cte1
group by city
having gold_ratio = 0;

#5 write a query to print 3 columns:  city, highest_expense_type , 
-- lowest_expense_type (example format : Delhi , bills, Fuel)
with cte1 as (select city,exp_type,sum(amount) as total_spend
from credit_card.credit_card_transactions
group by city,exp_type),
cte2 as (select *, rank() over (partition by city order by total_spend) rnk_asc, 
rank() over (partition by city order by total_spend desc) rnk_desc
from cte1)
select city, max(case when rnk_asc = 1 then exp_type end) as lowest_expense_type,
max(case when rnk_desc = 1 then exp_type end) as highest_expense_type
from cte2
group by city;

#6- write a query to find percentage contribution 
-- of spends by females for each expense type
select exp_type, 100* (sum(case when gender = 'f' then amount else 0 end) /sum(amount)) as f_perc_contribution
from credit_card.credit_card_transactions
group by exp_type
order by f_perc_contribution desc;
-- or
with cte1 as (select exp_type,gender,sum(amount) as amount
from credit_card.credit_card_transactions
where gender = 'f'
group by exp_type,gender),
cte2 as (select exp_type, sum(amount) as total_amount 
from credit_card.credit_card_transactions
group by exp_type)
select cte1.exp_type,gender,100*(amount/total_amount) as f_perc_contribution
from cte1 join cte2 on cte1.exp_type = cte2.exp_type
order by f_perc_contribution desc;

#7- which card and expense type combination saw 
-- highest month over month growth in Jan-2014
with cte1 as (select card_type,exp_type, month(transaction_date) as mnth,year(transaction_date) as yr, 
sum(amount) as amount from credit_card.credit_card_transactions
group by  card_type,exp_type,month(transaction_date),year(transaction_date)),
cte2 as (select *,lag(amount) over (partition by card_type,exp_type order by yr,mnth) prev_mn
from cte1)
select *, (amount-prev_mn)/prev_mn as yoy_growth from cte2 where mnth = 1 and yr = 2014
order by yoy_growth desc
limit 1;

#8- during weekends which city has highest total 
-- spend to total no of transcations ratio 
select city, sum(amount)/count(transaction_id) as ratio
from credit_card.credit_card_transactions
where dayname(transaction_date) in ('saturday','sunday')
-- or where weekday(transaction_date) in (5,6)
group by city
order by ratio desc;

#9- which city took least number of days to reach its 
-- 500th transaction after the first transaction in that city
with cte as (
select *, row_number () over (partition by city order by transaction_date) as rn
from credit_card.credit_card_transactions),
cte2 as (select city,min(transaction_date) as mindate,max(transaction_date) as maxdate from cte
where rn = 1 or rn = 500
group by city
having count(1)=2
order by city)
select *, datediff(maxdate,mindate) as daysbtw
 from cte2
 order by daysbtw;