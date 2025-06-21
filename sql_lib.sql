select * from books;
select * from branch;
select * from employees;
select * from issued_status;
select * from return_status;
select * from members;

-- Project Task

--Task 1. Create a New Book Record -- "978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.')
insert into books (isbn, book_title, category, rental_price, status, author, publisher)
values
('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.0,'yes', 'Harper Lee', 'J.B. Lippincott & Co');

-- Task 2: Update an Existing Member's Address

update members
set member_address = '125 Main St'
where member_id = 'C101'
select * from members

-- Task 3: Delete a Record from the Issued Status Table 
-- Objective: Delete the record with issued_id = 'IS121' from the issued_status table.
select * from issued_status
where issued_id = 'IS121';
delete from issued_status
where issued_id = 'IS121'


-- Task 4: Retrieve All Books Issued by a Specific Employee -- Objective: Select all books issued by the employee with emp_id = '101'.

select * from issued_status
where issued_emp_id = '101';

-- Task 5: List Members Who Have Issued More Than One Book -- Objective: Use GROUP BY to find members who have issued more than one book.


select ist.issued_emp_id,
    e.emp_name,
    count(*) as total_issued_books
from issued_status as ist
join employees as e on e.emp_id = ist.issued_emp_id
group by ist.issued_emp_id, e.emp_name
having count(ist.issued_id) > 1;

-- CTAS
-- Task 6: Create Summary Tables: Used CTAS to generate new tables based on query results - each book and total book_issued_cnt**
select b.isbn,b.book_title,
count(ist.issued_id) as no_issued
into book_cnts
from books as b
join issued_status as ist
on ist.issued_book_isbn = b.isbn
group by b.isbn, b.book_title;

SELECT * FROM book_cnts;



-- Task 7. Retrieve All Books in a Specific Category:

select * from books
where category = 'Classic'

-- Task 8: Member’s total issued, returned, and current books
SELECT 
    m.member_id, m.member_name,
    COUNT(DISTINCT i.issued_id) AS total_issued,
    COUNT(DISTINCT r.return_id) AS total_returned,
    COUNT(DISTINCT i.issued_id) - COUNT(DISTINCT r.return_id) AS current_books
FROM 
    members m
LEFT JOIN 
    issued_status i ON m.member_id = i.issued_member_id
LEFT JOIN 
    return_status r ON i.issued_id = r.issued_id
GROUP BY 
    m.member_id, m.member_name;

--TASK 9 List Members Who Have Not Issued Any Books in the Last 180 Days
SELECT m.member_id, m.member_name, m.member_address, m.reg_date
FROM members m
WHERE NOT EXISTS (
    SELECT 1 
    FROM issued_status i 
    WHERE i.issued_member_id = m.member_id 
    AND i.issued_date >= DATEADD(DAY, -180, GETDATE())
);

-- task 10 List Employees with Their Branch Manager's Name and their branch details:

SELECT 
    e1.*,
    b.manager_id,
    e2.emp_name as manager
FROM employees as e1
JOIN  
branch as b
ON b.branch_id = e1.branch_id
JOIN
employees as e2
ON b.manager_id = e2.emp_id


-- Task 11. Top publisher by issued count
SELECT 
    b.publisher, COUNT(*) AS issue_count
FROM 
    books b
JOIN 
    issued_status i ON b.isbn = i.issued_book_isbn
GROUP BY 
    b.publisher
ORDER BY 
    issue_count DESC


-- Task 12: Retrieve the List of Books Not Yet Returned

SELECT 
    DISTINCT ist.issued_book_name
FROM issued_status as ist
LEFT JOIN
return_status as rs
ON ist.issued_id = rs.issued_id
WHERE rs.return_id IS NULL

    
SELECT * FROM return_status

--Task 13: 
--Identify Members with Overdue Books
--Write a query to identify members who have overdue books (assume a 30-day return period). 
--Display the member's_id, member's name, book title, issue date, and days overdue.


-- issued_status == members == books == return_status
-- filter books which is return
-- overdue > 30 

select ist.issued_member_id,m.member_name, bk.book_title,ist.issued_date,
    datediff(day, ist.issued_date, getdate()) as over_dues_days
from issued_status as ist
join members as m
    on m.member_id = ist.issued_member_id
join books as bk
    on bk.isbn = ist.issued_book_isbn
left join return_status as rs
    on rs.issued_id = ist.issued_id
where 
    rs.return_date IS NULL
    and datediff(day, ist.issued_date, getdate()) > 30
order by ist.issued_member_id;



-- Task 14:Calculate the average number of days taken to return a book by each member
SELECT 
    m.member_id,
    m.member_name,
    AVG(DATEDIFF(DAY, i.issued_date, r.return_date)) AS avg_days_to_return
FROM 
    members m
JOIN 
    issued_status i ON m.member_id = i.issued_member_id
JOIN 
    return_status r ON i.issued_id = r.issued_id
GROUP BY 
    m.member_id, m.member_name;



/*
Task 15: Branch Performance Report
Create a query that generates a performance report for each branch, showing the number of books issued, the number of books returned, and the total revenue generated from book rentals.
*/

SELECT 
    b.branch_id,
    b.manager_id,
    COUNT(DISTINCT ist.issued_id) AS number_book_issued,
    COUNT(DISTINCT rs.return_id) AS number_of_book_return,
    SUM(DATEPART(HOUR, bk.rental_price)) AS total_revenue
INTO 
    branch_reports
FROM 
    issued_status AS ist
JOIN 
    employees AS e ON e.emp_id = ist.issued_emp_id
JOIN 
    branch AS b ON e.branch_id = b.branch_id
LEFT JOIN 
    return_status AS rs ON rs.issued_id = ist.issued_id
JOIN 
    books AS bk ON bk.isbn = ist.issued_book_isbn
GROUP BY 
    b.branch_id, b.manager_id;

-- View the result
SELECT * FROM branch_reports;



-- Task 16: CTAS — Create a Table of High-Value Books
-- Drop the table if it already exists (optional safety step)
-- Create the new active_members table

-- Drop the table if it already exists (optional safety step)

IF OBJECT_ID('late_returns', 'U') IS NOT NULL
    DROP TABLE late_returns;
-- Create the new active_members table
SELECT r.*
INTO late_returns
FROM return_status r
JOIN issued_status i ON r.issued_id = i.issued_id
WHERE DATEDIFF(DAY, TRY_CAST(i.issued_date AS DATE), TRY_CAST(r.return_date AS DATE)) > 30;

SELECT * FROM late_returns;

-- 
-- Task 17: Find Employees with the Most Book Issues Processed
-- Write a query to find the top 3 employees who have processed the most book issues. Display the employee name, number of books processed, and their branch.
SELECT TOP 3
    e.emp_name,
    b.branch_id,
    b.branch_address AS branch_name,
    COUNT(ist.issued_id) AS no_book_issued
FROM 
    issued_status AS ist
JOIN 
    employees AS e ON e.emp_id = ist.issued_emp_id
JOIN 
    branch AS b ON e.branch_id = b.branch_id
GROUP BY
    e.emp_name,
    b.branch_id,
    b.branch_address
ORDER BY
    no_book_issued DESC;



--Task 18: Stored Procedure Objective: 

-- Optional: Drop procedure if it already exists (for re-running/testing)
IF OBJECT_ID('Get_OverdueBooks', 'P') IS NOT NULL
    DROP PROCEDURE Get_OverdueBooks;
GO

-- Create the stored procedure
CREATE PROCEDURE Get_OverdueBooks
AS
BEGIN
    SELECT 
        i.issued_id,
        i.issued_book_name,
        i.issued_date,
        m.member_name,
        DATEDIFF(DAY, i.issued_date, GETDATE()) AS days_held
    FROM 
        issued_status i
    JOIN 
        members m ON i.issued_member_id = m.member_id
    LEFT JOIN 
        return_status r ON i.issued_id = r.issued_id
    WHERE 
        r.return_id IS NULL 
        AND DATEDIFF(DAY, i.issued_date, GETDATE()) > 15;
END;
GO

-- Run the procedure
EXEC Get_OverdueBooks;





