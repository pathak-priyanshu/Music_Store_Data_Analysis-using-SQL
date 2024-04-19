/*
SQL PROJECT- MUSIC STORE DATA ANALYSIS
*/
create database Project_music
use Project_music

select*from playlist_track;
select * from track;
select * from album;
select * from playlist;
select * from media_type;
select * from invoice_line;
select * from invoice;
select * from genre;
select * from employee;
select * from customer;
select * from artist;
select * from track;


--Question Set 1 - Easy--------------------------------------------------------------------------------------------
-- Who is the senior most employee based on job title?
select employee_id,first_name +' '+ last_name as emp_name,
title,levels
from employee
where reports_to is null -- we use filter on reports_to, the senior most employee doesnt report to anybody,hence its null.
-------------------or-----------------------------------------
SELECT top 1 title, last_name, first_name 
FROM employee
ORDER BY levels DESC

---------------------------------------------------------------------------------------------------------------------------
--Which countries have the most Invoices?  select top 3* from(select billing_country,count(invoice_id) as tot_invoice
from invoice
group by billing_country
)                           --# we use subquerry here so that we can filter out top n countries by total invoice count
as invoice_Dem0
order by tot_invoice desc

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- What are top 3 values of total invoice?
SELECT top 3 total as Tot_invoice
FROM invoice
ORDER BY total DESC

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/* Which city has the best customers? We would like to throw a promotional Music 
Festival in the city we made the most money. Write a query that returns one city that 
has the highest sum of invoice totals. Return both the city name & sum of all invoice 
totals */select top 1 billing_city -- we use subquerry and 'top' to filter out city name where the total invoice is maximum.from (select billing_city,sum (total ) as city_totalfrom invoicegroup by billing_city) as city_total
order by city_total DESC

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/* Q5: Who is the best customer? The customer who has spent the most money will be declared the best customer. 
Write a query that returns the person who has spent the most money.*/
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


select c.customer_id,first_name,last_name,city,country,sum(total) as tot_spend
from customer as c
left join invoice as i on c.customer_id=i.customer_id
group by c.customer_id,first_name,last_name,city,country
order by tot_spend desc
------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*Question Set 2 – Moderate-----------------------------------------------------------------------------------------------------------------------------------------
1. Write query to return the email, first name, last name, & Genre of all Rock Music 
listeners. Return your list ordered alphabetically by email starting with A
*/

select distinct email as Email, first_name as First_NAME,last_name as LAST_NAME,g.name as Genre_NAME
from customer as c
join invoice as i on c.customer_id=i.customer_id
join invoice_line as il on i.invoice_id = il.invoice_id
join track as t on il.track_id = t.track_id
join genre as g on t.genre_id = g.genre_id
where g.name like 'ro%'
order by Email
-----------------------Method 2-----------------------------------------------------------------------------------

SELECT DISTINCT email,first_name, last_name
FROM customer
JOIN invoice ON customer.customer_id = invoice.customer_id
JOIN invoice_line ON invoice.invoice_id = invoice_line.invoice_id
WHERE track_id IN(
	SELECT track_id FROM track
	JOIN genre ON track.genre_id = genre.genre_id
	WHERE genre.name LIKE 'Rock'
)
ORDER BY email;
---------------------------------------------------------------------------------------------------------------------
/* Q2: Let's invite the artists who have written the most rock music in our dataset. 
Write a query that returns the Artist name and total track count of the top 10 rock bands. */

select top 10 ar.artist_id,ar.[name],count(ar.artist_id) as total_count
from track as t
join album as a on t.album_id=a.album_id
join artist as ar on a.artist_id = ar.artist_id
join genre as g on t.genre_id=g.genre_id
where g.[name] like 'ro%'
group by ar.[name],ar.artist_id
order by total_count desc

----------------------------------------------------------------------------------------------------------------------------
/* Q3: Return all the track names that have a song length longer than the average song length. 
Return the Name and Milliseconds for each track. Order by the song length with the longest songs listed first. */

select track_id,[name] as SNG_NAME,milliseconds as SNG_LEN
from track
where milliseconds > ( select avg(milliseconds) as AVG_SNG_LEN
                      from track)
order by SNG_LEN desc
-----------------------------------------------------------------------------------------------------------------------------------------

/* Q1: Find how much amount spent by each customer on artists? Write a query to return customer name, artist name and total spent */

/* Steps to Solve: First, find which artist has earned the most according to the InvoiceLines. Now use this artist to find 
which customer spent the most on this artist. For this query, you will need to use the Invoice, InvoiceLine, Track, Customer, 
Album, and Artist tables. Note, this one is tricky because the Total spent in the Invoice table might not be on a single product, 
so you need to use the InvoiceLine table to find out how many of each product was purchased, and then multiply this by the price
for each artist. */

WITH best_selling_artist AS (
	SELECT top 1 artist.artist_id AS artist_id, artist.[name] AS artist_name, SUM(invoice_line.unit_price*invoice_line.quantity) AS total_sales
	FROM invoice_line
	JOIN track ON track.track_id = invoice_line.track_id
	JOIN album ON album.album_id = track.album_id
	JOIN artist ON artist.artist_id = album.artist_id
	GROUP BY artist.artist_id,artist.[name]
	ORDER BY total_sales desc

)
SELECT c.customer_id, c.first_name, c.last_name, bsa.artist_name, SUM(il.unit_price*il.quantity) AS amount_spent
FROM invoice i
JOIN customer c ON c.customer_id = i.customer_id
JOIN invoice_line il ON il.invoice_id = i.invoice_id
JOIN track t ON t.track_id = il.track_id
JOIN album alb ON alb.album_id = t.album_id
JOIN best_selling_artist bsa ON bsa.artist_id = alb.artist_id
GROUP BY c.customer_id, c.first_name, c.last_name, bsa.artist_name
ORDER BY amount_spent DESC;
----------------------------------------------------------------------------------------------------------------------------------------
/* Q2: We want to find out the most popular music Genre for each country. We determine the most popular genre as the genre 
with the highest amount of purchases. Write a query that returns each country along with the top Genre. For countries where 
the maximum number of purchases is shared return all Genres. */

/* Steps to Solve:  There are two parts in question- first most popular music genre and second need data at country level. */
WITH popular_genre AS 

(
    SELECT COUNT(il.quantity) AS purchases, c.country, g.[name], g.genre_id, 
	ROW_NUMBER() OVER(PARTITION BY c.country ORDER BY COUNT(il.quantity) DESC) AS Row_No 
    FROM invoice_line il
	JOIN invoice i ON i.invoice_id = il.invoice_id
	JOIN customer c ON c.customer_id = i.customer_id
	JOIN track t ON t.track_id = il.track_id
	JOIN genre g ON g.genre_id = t.genre_id
	GROUP BY c.country, g.[name], g.genre_id
)
SELECT * FROM popular_genre 
WHERE Row_No <= 1
----------------------------------------------------------------------------------------------------------------------------------
/* Q3: Write a query that determines the customer that has spent the most on music for each country. 
Write a query that returns the country along with the top customer and how much they spent. 
For countries where the top amount spent is shared, provide all customers who spent this amount. */

/* Steps to Solve:  Similar to the above question. There are two parts in question- 
first find the most spent on music for each country and second filter the data for respective customers. */

WITH Customter_with_country AS
(
		SELECT c.customer_id,first_name,last_name,billing_country,SUM(total) AS total_spending,
	    ROW_NUMBER() OVER(PARTITION BY billing_country ORDER BY SUM(total) DESC) AS Row_No 
		FROM invoice i
		JOIN customer c ON c.customer_id = i.customer_id
		GROUP BY c.customer_id,first_name,last_name,billing_country
)
SELECT * FROM Customter_with_country
WHERE Row_No <= 1