
-- Inserting data into the train table
insert into train values (1271,'Mitaliexp','06:40:00','01:30:00','A',getdate()), 
						(1272,'Bandhonexp','12:00:00','9:30:00','A',getdate()),
						(1273,'Modhomoteexp','09:00:00','05:30:00','A',getdate()),
						(1274,'Subornoexp','13:00:00','10:30:00','A',getdate()),
						(1275,'Parabatexp','10:00:00','06:30:00','NA',getdate()) 
go
-- Inserting data into the TRAIN_STATUS table
insert into train_status values(1271,10,10,2,0,0,10,10,1500,500),
								(1272,10,10,2,0,0,10,10,1500,500),
								(1273,10,10,2,0,0,10,10,1200,400),
								(1274,10,10,2,0,0,10,10,2000,800),
								(1275,10,10,2,0,0,10,10,1500,500);
go
-- Inserting data into the passenger table
insert into passenger values(101,'Aziz Hossen',22,'Male','available','B6-45'),
							(102,'Rakib Hossen',22,'Male','available','B6-47'),
							(103,'Abir Das',27,'Male','available','B7-5'),
							(104,'Uttam kumer',29,'Male','available','B7-72'),
							(105,'Anowaer Hossen',33,'Male','available','B6-38'),
							(106,'Akib Jabed',21,'Male','Wating','B7-71'),
							(107,'Musa Kalimullah',47,'Male','wating','B6-60')
go
-- Inserting data into the TICKET table
insert into ticket values (4001,101,'confirmed',1,1271),
						(4002,102,'confirmed',1,1272),
						(4003,103,'Wait',1,1273),
						(4004,104,'Wait',1,1274),
						(4005,105,'confirmed',1,1275);
go
-- Inserting data into the STATION table
insert into station values ('Dhaka',1271),
							('Dhaka',1272),
							('Dhaka',1273),
							('Dhaka',1274),
							('Dhaka',1275),
							('sylet',1271),
							('Rajshahi',1272),
							('Khulna',1273),
							('Chittagong',1274),
							('Barishal',1275)
go
-- Inserting data into the BOOKS table
insert into books values(101,4001),(102,4002)
go

/*insert store procedure*/
execute sp_Insert_train'1276','Jamuna_Exp','06:30:00','01:10:00','NA','2018-01-18';
go

/*Delete store procedure*/
execute sp_Delete_train  '1276';
go

/*Update store procedure*/
execute st_Update_train '1276','Mettor_Exp';
go

/*instead of update */
update books set passenger_id = 109 where ticket_id = 4001;
go

/*print passenger id and name of all those user who 
booked ticket for Bandhon express using join*/
select distinct p.passenger_id,passenger_Name,train_name
from  passenger p join TICKET te 
on p.passenger_id = te.passenger_id join train tr 
on tr.train_no = te.train_no
where train_name ='Bandhonexp'
go

/*using left join*/
select distinct p.passenger_id,passenger_Name,train_name
from passenger p left join TICKET te 
on p.passenger_id = te.passenger_id left join train tr 
on tr.train_no = te.train_no
go

/*right left join*/
select distinct p.passenger_id,passenger_Name,train_name
from passenger p right join ticket te 
on p.passenger_id = te.passenger_id right join train tr 
on tr.train_no = te.train_no
go


/*print detail of passengers travelling under ticket no 4001*/
select p.passenger_id,passenger_Name,ticket_id
from passenger p join ticket te 
on p.passenger_id = te.passenger_id
where ticket_id like 4001;
go

/*diplay the train no with increasing order of the AC_seats_available*/
select t.train_no,ts.AC_seats_available,t.train_name
from train_status ts,train t
where t.train_no=ts.train_no
order by AC_seats_available;
go

/*display immediate train from Dhaka to sylet using subquery*/
select t.train_no,t.train_name, dha.Station_name as
start_joury, sy.Station_name as end_joury 
from train t join
(select * from station where Station_name ='Dhaka')
as dha on t.train_no = dha.train_no join
(select * from station where Station_name ='sylet')
as sy on t.train_no = sy.train_no
go

/*display details of all those passengers whose status is confirmed for trainno*/
select * from ticket t where t.status like 'confirmed' and t.train_no=1271;
go

/*display ticket whose status is match show comment using case*/
 select te.passenger_id, tr.train_no, tr.train_Name,te.[status],
 CASE
 when [status]='confirmed' THEN 'Successfully completed'
 when [status]='wait' THEN 'Wating for you'
 else 'try this agin'
 end as Comment 
 from ticket te join train tr 
 on tr.train_no = te.train_no;
 go

/*display ticket whose status is match show comment using case */
select train_name, arrival_time, departure_time
from train where arrival_time BETWEEN '01:30:00'AND '09:30:00'
go

/*display ticket whose status is match show comment using case */
SELECT train_name, arrival_time, departure_time FROM train WHERE train_name LIKE 'M%'
go

/*OFFSET 0 ROWS FETCH FIRST 2 ROWS ONLY FROM PASSENGER table */
SELECT * FROM PASSENGER ORDER BY passenger_Name
OFFSET 0 ROWS FETCH FIRST 2 ROWS ONLY
go

/*using in opearator */
SELECT * FROM TRAIN  WHERE train_name IN ('Bandhonexp')
go

/*using over clause */
SELECT  train_no,AC_seats_Price,
SUM ( AC_seats_Price) OVER (ORDER BY  train_no) AS sumTotal 
FROM TRAIN_STATUS
go
--
/* passenger_Name group using grouping set Operator and*/
select passenger_Name,COUNT(passenger_id) AS totalPassener
from passenger
where passenger_Name IN ('Aziz Hossen')
group by grouping sets(passenger_Name) 
order by passenger_Name desc
go

/*using Any keyword */
select tr.train_no,tr.train_name,ts.total_AC_seats
from TRAIN tr JOIN TRAIN_STATUS ts ON tr.train_no = ts.train_no
where total_AC_seats > ANY
(select total_AC_seats
from TRAIN_STATUS
where train_no = 1275);
go
--
/*using exists operator*/
SELECT train_no,train_name
FROM TRAIN
WHERE EXISTS 
(SELECT * FROM TRAIN_STATUS WHERE TRAIN.train_no = TRAIN_STATUS.train_no)
go

/*using All keyword */
select tr.train_no,tr.train_name,ts.total_AC_seats
from train tr join train_status ts ON tr.train_no = ts.train_no
where total_AC_seats < all
(select total_AC_seats
from train_status
where train_no = 1275);  
go

/*common table expesstion(CTE)*/
WITH Summary (passenger_Name,age,No_of_passengers,status)AS 
( SELECT  passenger_Name,age,t.No_of_passengers,t.status
FROM PASSENGER p
JOIN TICKET t ON p.passenger_id = t.passenger_id
)
select * from Summary 

/*using SOME keyword */
SELECT tr.train_no,tr.train_name,ts.total_AC_seats
FROM TRAIN tr JOIN TRAIN_STATUS ts ON tr.train_no = ts.train_no
WHERE total_AC_seats < some
(SELECT total_AC_seats
FROM TRAIN_STATUS
WHERE train_no = 1275);  
go


/* instead trigger insert*/
insert into cancel_Status values (102,4002,'01/01/2019','Pending')
go

/* instead trigger Update*/
update cancel_status 
set CancelStatus='Approved', 
CancelApprovalDateTime=getdate()  
where passenger_id=102
go

/*train table select*/
select * from train
select * from passenger
select * from train_status
select * from ticket
select * from station
select * from books

--table function select
Select * From dbo.fn_passenger();

--Scalare function select
select dbo.fn_count()

--Multistatement function select
select * from dbo.fn_Passenger_AddPrice()

--Affter trigger select
select * from cancel_status
select * from cancel_status_audit
