/*CHECK DATABASE EXISTANCE & CREATE DATABASE WITH ATTRIBUTED	*/
use master 
go

if DB_ID('RARS') is not null
drop database RARS
go

create database RARS
on
(
	name='rarsdb_data',
	filename='C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\rarsdb_log.mdf',
	size=25mb,
	maxsize=100mb,
	filegrowth=5%
)
log on
(
	name='rarsdb_log',
	filename='C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\rarsdb_log.ldf',
	size=10mb,
	maxsize=50mb,
	filegrowth=1%
)
go

use RARS
go

/*CREATE TRAIN TABLE WITH COLUMN DEFINITION */
create table train
(
	train_no int primary key not null, 
	train_name varchar(50) not null,
	departure_time time(0) not null,
	arrival_time time(0) not null,
	availability_of_seats char(50) not null,
	[date] date default getdate()
);
go
/*CREATE TRAIN_STATUS TABLE WITH COLUMN DEFINITION */
create table train_status
(
	train_no int references TRAIN(train_no),
	total_AC_seats int,
	total_GEN_seats int,
	total_Waiting_seats int,
	AC_seats_booked int,
	GEN_seats_booked int,
	AC_seats_available int,
	GEN_seats_available int,
	AC_seats_Price int,
	GEN_seats_Price int,
	check(total_Waiting_seats<3),
	check(AC_seats_booked<11),
	check(GEN_seats_booked<11)
);
go
/*CREATE PASSENGER TABLE WITH COLUMN DEFINITION */
create table passenger
(
	passenger_id int primary key,
	passenger_Name varchar(50),
	age int,
	gender varchar(10),
	reservation_status varchar(50),
	seat_number varchar(20)
);
go
/*CREATE TICKET TABLE WITH COLUMN DEFINITION */
create table ticket(
	ticket_id int primary key,
	passenger_id int references passenger(passenger_id),
	[status] varchar(50),
	No_of_passengers int,
	train_no int references train(train_no)
);
go
/*CREATE STATION TABLE WITH COLUMN DEFINITION */
create table station(
	Station_name varchar(50),
	train_no int references train(train_no),
);
go
/*CREATE BOOKS TABLE WITH COLUMN DEFINITION */
create table books(
	passenger_id int references passenger(passenger_id),
	ticket_id int references ticket(ticket_id)
);
go
/*CREATE CANCEL_Status TABLE WITH COLUMN DEFINITION */

create table cancel_status(
	passenger_id int references passenger(passenger_id),
	ticket_id int references ticket(ticket_id),
	CancelApprovalDateTime datetime,
	CancelStatus varchar(20)
);
go

/*CREATE CANCEL_Status_Audit TABLE WITH COLUMN DEFINITION */
create table cancel_status_audit
(
	passenger_id int references passenger(passenger_id),
	ticket_id int references ticket(ticket_id),
	CancelApprovalDateTime datetime,
	CancelStatus varchar(20),
	UpdatedBy nvarchar(255),
	UpdatedOn datetime
)
go
/*copy station table*/
select * into stationcopy from station
go
/*ADD column*/
alter table stationcopy 
add email varchar(50) 
go

/*Drop Column*/
alter table stationcopy 
drop column email 
go

/*CLUSTERED INDEX*/ 
create clustered index IX_Comments on stationcopy(train_no)
go

/*NONCLUSTERED INDEX*/ 
create unique nonclustered index IX_Commentsage on stationcopy(Station_name)
GO

-- DROP TABLE 
IF OBJECT_ID('stationcopy') is not null
drop table stationcopy
go

/*CREATE A VIEW*/
CREATE VIEW v_train_status
with encryption
AS
select p.passenger_id,passenger_Name,train_name 
from PASSENGER p join
TICKET te on p.passenger_id = te.passenger_id
join TRAIN tr on tr.train_no = te.train_no
where train_name ='Bandhonexp'
GO

/*Table Value Function*/
Create Function fn_passenger()
Returns Table
Return
(
select t.train_no,ts.AC_seats_available,t.train_name
from train_status ts,train t
where t.train_no=ts.train_no
)
go

/*Scalre Value Function*/
Create Function fn_count()
Returns int
Begin
Declare @c int;
Select @c = count(*) from Passenger;
Return @c;
End;
-----

/*Multi Statement Function*/
Create Function fn_Passenger_AddPrice()
	Returns @outTable table
	(train_no int,GEN_seats_Price int,price_extent_Gen 
	int,AC_seats_Price int,price_extent_AC int)
	begin
		insert into @outTable(train_no,GEN_seats_Price,price_extent_Gen,
		AC_seats_Price ,price_extent_AC) 
		select train_no,GEN_seats_Price,GEN_seats_Price=GEN_seats_Price+50,
		AC_seats_Price ,AC_seats_Price=AC_seats_Price+50
		from train_status;
		return;
	end;
go

/*Store Procedure select train table*/
create proc sp_train
as
select * from train
go
 execute sp_train
  
/*Store Procedure insert train table*/
create proc sp_Insert_train
	@train_no int, 
	@train_name varchar(50),
	@departure_time time(0) ,
	@arrival_time time(0) ,
	@availability_of_seats char(50),
	@date date 
as
insert into TRAIN(train_no, train_name, departure_time,arrival_time,availability_of_seats,date) 
values(
	@train_no,
	@train_name, 
	@departure_time,
	@arrival_time,
	@availability_of_seats,
	@date
)
go
 
/*Store Procedure Update train table*/
 create proc SP_Update_train
	@train_no int, 
	@train_name varchar(50)
as 
	update train set train_name = @train_name
	where train_no = @train_no
go

/*Store Procedure Delete train table*/
 create proc SP_Delete_train 
@train_no int
as 
delete from train where train_no = @train_no
go
 
--In parameter and one out parameter 
create proc usp_SquareValue(
    @input int,
    @result int output
) 
as
begin
    select @result = (@input * @input);
end;
declare @res int
exec usp_SquareValue @input = 5, @result=@res output;
select @res as 'Square Value';
go


/*insert of trigger*/
create trigger tr_booking_update on books
instead of update 
as
begin
	declare @passenger_id int,
			@ticket_id int
	select  @passenger_id = inserted.passenger_id,
		    @ticket_id = inserted.ticket_id
	from inserted
	if update(passenger_id)
	begin
		raiserror('Update cannot be passenger_id',16,1)
		rollback
	end
	else
	begin
		update books
		set passenger_id = @passenger_id where ticket_id = @ticket_id
	end

end
go

/*affter trigger*/
create trigger  tr_cancel_Status_Audit on cancel_status
after update, insert
as
begin
  insert into cancel_Status_Audit
  ( passenger_id, ticket_id,CancelApprovalDateTime,CancelStatus, UpdatedBy, UpdatedOn )
  select i.passenger_id, i.ticket_id,i.CancelApprovalDateTime, i.CancelStatus, SUSER_SNAME(), getdate() 
  from  cancel_Status c 
  inner join inserted i on c.passenger_id =i.passenger_id
end
go










