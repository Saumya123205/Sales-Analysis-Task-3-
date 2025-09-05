
-- Customers Table
CREATE TABLE Customers (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    country VARCHAR(50),
    city VARCHAR(50),
    state VARCHAR(50)
);

-- Products Table
CREATE TABLE Products (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    product_name VARCHAR(200) NOT NULL,
    category VARCHAR(50),
    price DECIMAL(10,2)
);

-- Orders Table
CREATE TABLE Orders (
    order_id VARCHAR(20) PRIMARY KEY,
    order_date DATE NOT NULL,
    ship_date DATE,
    customer_id INT,
    FOREIGN KEY (customer_id) REFERENCES Customers(customer_id)
);

-- OrderDetails Table
CREATE TABLE OrderDetails (
    order_detail_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id VARCHAR(20),
    product_id INT,
    quantity INT,
    sales_amount DECIMAL(10,2),
    profit DECIMAL(10,2),
    FOREIGN KEY (order_id) REFERENCES Orders(order_id),
    FOREIGN KEY (product_id) REFERENCES Products(product_id)
);

-- Insert into Customers
INSERT INTO Customers (customer_name, country, city, state)
SELECT DISTINCT customer_name, country, city, state
FROM walmart.sales;

-- Insert into Products
INSERT INTO Products (product_name, category, price)
SELECT DISTINCT product_name, category, 
       (sales / NULLIF(quantity,0)) AS price
FROM walmart.sales;

-- Insert into Orders
INSERT INTO Orders (order_id, order_date, ship_date, customer_id)
SELECT DISTINCT s.order_id, 
       STR_TO_DATE(s.order_date, '%m/%d/%Y'),
       STR_TO_DATE(s.ship_date, '%m/%d/%Y'),
       c.customer_id
FROM walmart.sales s
JOIN Customers c ON s.customer_name = c.customer_name
                AND s.city = c.city
                AND s.state = c.state;

-- Insert into OrderDetails
INSERT INTO OrderDetails (order_id, product_id, quantity, sales_amount, profit)
SELECT s.order_id, 
       p.product_id,
       s.quantity,
       s.sales,
       s.profit
FROM walmart.sales s
JOIN Products p ON s.product_name = p.product_name
               AND s.category = p.category;

-- KPI for the Project
-- Total Revenue & Profit
SELECT 
    SUM(sales_amount) AS total_revenue,
    SUM(profit) AS total_profit
FROM OrderDetails;

-- Top 10 Customers by Spending
SELECT c.customer_name, SUM(od.sales_amount) AS total_spent
FROM Customers c
JOIN Orders o ON c.customer_id = o.customer_id
JOIN OrderDetails od ON o.order_id = od.order_id
GROUP BY c.customer_name
ORDER BY total_spent DESC
LIMIT 10;

-- Most Profitable Products
SELECT p.product_name, SUM(od.profit) AS total_profit
FROM Products p
JOIN OrderDetails od ON p.product_id = od.product_id
GROUP BY p.product_name
ORDER BY total_profit DESC
LIMIT 10;

-- Sales by Category
SELECT p.category, SUM(od.sales_amount) AS revenue, SUM(od.profit) AS profit
FROM Products p
JOIN OrderDetails od ON p.product_id = od.product_id
GROUP BY p.category
ORDER BY revenue DESC;

-- Monthly Sales Trend
SELECT YEAR(o.order_date) AS year, MONTH(o.order_date) AS month,
       SUM(od.sales_amount) AS total_sales
FROM Orders o
JOIN OrderDetails od ON o.order_id = od.order_id
GROUP BY year, month
ORDER BY year, month;

-- Revenue by State
SELECT c.state, SUM(od.sales_amount) AS revenue
FROM Customers c
JOIN Orders o ON c.customer_id = o.customer_id
JOIN OrderDetails od ON o.order_id = od.order_id
GROUP BY c.state
ORDER BY revenue DESC
LIMIT 10;

-- Most Ordered Products
SELECT p.product_name, SUM(od.quantity) AS total_quantity
FROM Products p
JOIN OrderDetails od ON p.product_id = od.product_id
GROUP BY p.product_name
ORDER BY total_quantity DESC
LIMIT 10;

-- Average Order Value (AOV)
SELECT 
    SUM(od.sales_amount) / COUNT(DISTINCT o.order_id) AS avg_order_value
FROM Orders o
JOIN OrderDetails od ON o.order_id = od.order_id;

-- Revenue per Customer
SELECT 
    c.customer_name,
    SUM(od.sales_amount) / COUNT(DISTINCT o.order_id) AS revenue_per_customer
FROM Customers c
JOIN Orders o ON c.customer_id = o.customer_id
JOIN OrderDetails od ON o.order_id = od.order_id
GROUP BY c.customer_name
ORDER BY revenue_per_customer DESC
LIMIT 10;

-- Profit Margin (%)
SELECT 
    (SUM(od.profit) / SUM(od.sales_amount)) * 100 AS profit_margin_percent
FROM OrderDetails od;

-- Repeat Customers (Customers with >1 Order)
SELECT COUNT(*) AS repeat_customers
FROM (
    SELECT c.customer_id
    FROM Customers c
    JOIN Orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id
    HAVING COUNT(DISTINCT o.order_id) > 1
) t;


-- Best-Selling Category (by Revenue)
SELECT p.category, SUM(od.sales_amount) AS revenue
FROM Products p
JOIN OrderDetails od ON p.product_id = od.product_id
GROUP BY p.category
ORDER BY revenue DESC
LIMIT 1;

-- Most Profitable Category (by Profit)
SELECT p.category, SUM(od.profit) AS total_profit
FROM Products p
JOIN OrderDetails od ON p.product_id = od.product_id
GROUP BY p.category
ORDER BY total_profit DESC
LIMIT 1;

-- Low Profit Margin Products
SELECT p.product_name,
       SUM(od.sales_amount) AS revenue,
       SUM(od.profit) AS profit,
       (SUM(od.profit)/SUM(od.sales_amount))*100 AS profit_margin_percent
FROM Products p
JOIN OrderDetails od ON p.product_id = od.product_id
GROUP BY p.product_name
HAVING profit_margin_percent < 5
ORDER BY profit_margin_percent ASC
LIMIT 10;

-- Average Delivery Time (Days between Order & Ship Date)
SELECT AVG(DATEDIFF(o.ship_date, o.order_date)) AS avg_delivery_days
FROM Orders o;

-- Year-over-Year Growth (%)
SELECT 
    YEAR(o.order_date) AS year,
    SUM(od.sales_amount) AS revenue,
    (SUM(od.sales_amount) - LAG(SUM(od.sales_amount)) 
        OVER (ORDER BY YEAR(o.order_date)))
    / LAG(SUM(od.sales_amount)) OVER (ORDER BY YEAR(o.order_date)) * 100 
    AS yoy_growth_percent
FROM Orders o
JOIN OrderDetails od ON o.order_id = od.order_id
GROUP BY YEAR(o.order_date)
ORDER BY year;

-- Top 5 States by Profitability
SELECT c.state, SUM(od.profit) AS total_profit
FROM Customers c
JOIN Orders o ON c.customer_id = o.customer_id
JOIN OrderDetails od ON o.order_id = od.order_id
GROUP BY c.state
ORDER BY total_profit DESC
LIMIT 5;
