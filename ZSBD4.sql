-- Zadanie 1 
-- Stwórz ranking pracowników oparty na wysokości pensji. 
-- Jeśli dwie osoby mają tę samą pensję,
-- powinny otrzymać ten sam numer. 

SELECT e.FIRST_NAME, e.LAST_NAME, e.DEPARTMENT_ID, e.SALARY,
AVG(e.SALARY) as Srednia,
RANK() OVER(PARTITION BY e.DEPARTMENT_ID ORDER BY e.SALARY) AS RANKING
FROM EMPLOYEES e
GROUP BY e.FIRST_NAME, e.LAST_NAME, e.DEPARTMENT_ID, e.SALARY
ORDER BY e.DEPARTMENT_ID DESC;


-- Zadanie 2
-- Dodaj kolumnę, która pokazuje całkowitą sumę pensji 
-- wszystkich pracowników, ale bez grupowania ich.

SELECT e.FIRST_NAME, e.LAST_NAME, e.DEPARTMENT_ID, e.SALARY,
SUM(e.SALARY) OVER() AS SUMA
FROM EMPLOYEES e
ORDER BY e.DEPARTMENT_ID ASC;

-- Zadanie 3
-- Dla każdego pracownika wypisz: nazwisko, nazwę produktu, 
-- skumulowaną wartość sprzedaży dla pracownika,
-- ranking wartości sprzedaży względem wszystkich 
-- zamówień.

SELECT e.FIRST_NAME || ' ' || e.LAST_NAME as FULL_NAME,
p.PRODUCT_NAME,
s.QUANTITY * s.PRICE AS Full_Price,
SUM(s.QUANTITY * s.PRICE) OVER(PARTITION BY e.EMPLOYEE_ID) AS Skumulowana_Wartosc,
RANK() OVER(ORDER BY s.QUANTITY * s.PRICE DESC) AS RANKING
FROM EMPLOYEES e
JOIN SALES s ON e.EMPLOYEE_ID = s.EMPLOYEE_ID
JOIN PRODUCTS p ON p.PRODUCT_ID = s.PRODUCT_ID
ORDER BY e.EMPLOYEE_ID, RANKING ASC;

-- Zadanie 4 
-- Dla każdego wiersza z tabeli sales wypisać nazwisko pracownika,
-- nazwę produktu, cenę produktu, liczbę transakcji dla danego produktu tego dnia,
-- sumę zapłaconą danego dnia za produkt,
-- poprzednią cenę oraz kolejną cenę danego produktu.

SELECT 
	e.FIRST_NAME || ' ' || e.LAST_NAME AS FULL_NAME,
	p.PRODUCT_NAME,
	s.PRICE,
	COUNT(*) OVER (PARTITION BY s.PRODUCT_ID, TRUNC(s.SALE_DATE)) AS TRANSACTIONS_COUNT,
	SUM(s.QUANTITY * s.PRICE) OVER (PARTITION BY s.PRODUCT_ID, TRUNC(s.SALE_DATE)) AS DAILY_SUM,
	LAG(s.PRICE) OVER (PARTITION BY s.PRODUCT_ID ORDER BY TRUNC(s.SALE_DATE), s.SALE_ID) AS PREVIOUS_PRICE,
	LEAD(s.PRICE) OVER (PARTITION BY s.PRODUCT_ID ORDER BY TRUNC(s.SALE_DATE), s.SALE_ID) AS NEXT_PRICE,
	s.SALE_DATE
FROM SALES s
JOIN EMPLOYEES e ON s.EMPLOYEE_ID = e.EMPLOYEE_ID
JOIN PRODUCTS p ON s.PRODUCT_ID = p.PRODUCT_ID
ORDER BY s.SALE_DATE, e.LAST_NAME, p.PRODUCT_NAME;

-- Zadanie 5
-- Dla każdego wiersza wypisać nazwę produktu, cenę produktu, sumę całkowitą 
-- zapłaconą w danym miesiącu oraz sumę rosnącą zapłaconą w danym miesiącu za 
-- konkretny produkt
SELECT
	p.PRODUCT_NAME,
	s.PRICE,
	s.QUANTITY * s.PRICE AS FULL_PRICE,
	TRUNC(s.SALE_DATE,'MM') AS SALE_MONTH,
	SUM(s.QUANTITY * s.PRICE) OVER (PARTITION BY p.PRODUCT_ID, TRUNC(s.SALE_DATE,'MM')) AS TOTAL_PAID_IN_MONTH,
	SUM(s.QUANTITY * s.PRICE) OVER (
		PARTITION BY p.PRODUCT_ID, TRUNC(s.SALE_DATE,'MM')
		ORDER BY s.SALE_DATE, s.SALE_ID
		ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
	) AS RUNNING_SUM_IN_MONTH,
	s.SALE_DATE
FROM PRODUCTS p
JOIN SALES s ON s.PRODUCT_ID = p.PRODUCT_ID
ORDER BY p.PRODUCT_NAME, SALE_MONTH, s.SALE_DATE;