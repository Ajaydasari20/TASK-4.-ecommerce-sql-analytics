CREATE DATABASE ecommerce_db;
USE ecommerce_db;

CREATE TABLE IF NOT EXISTS customers (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(100),
    country VARCHAR(50)
);

CREATE TABLE IF NOT EXISTS orders (
    order_id INT PRIMARY KEY,
    customer_id INT,
    order_date DATE,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

CREATE TABLE IF NOT EXISTS products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(100),
    category_id INT
);

CREATE TABLE IF NOT EXISTS order_items (
    order_id INT,
    product_id INT,
    quantity INT,
    unit_price DECIMAL(10,2),
    PRIMARY KEY (order_id, product_id),
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

CREATE TABLE IF NOT EXISTS categories (
    category_id INT PRIMARY KEY,
    category_name VARCHAR(100)
);

CREATE TABLE IF NOT EXISTS payments (
    payment_id INT PRIMARY KEY,
    order_id INT,
    payment_method VARCHAR(50),
    amount DECIMAL(10,2),
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
);


SELECT *
FROM customers
WHERE country = 'India';

SELECT p.product_name, SUM(oi.quantity) AS total_quantity_sold
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
GROUP BY p.product_name
ORDER BY total_quantity_sold DESC
LIMIT 10;

SELECT DATE_FORMAT(o.order_date, '%Y-%m') AS month,
       SUM(oi.quantity * oi.unit_price) AS monthly_revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY month
ORDER BY month;

SELECT o.order_id, o.order_date, c.customer_name, p.payment_method, p.amount
FROM orders o
INNER JOIN customers c ON o.customer_id = c.customer_id
INNER JOIN payments p ON o.order_id = p.order_id;

SELECT p.product_name, oi.quantity
FROM products p
LEFT JOIN order_items oi ON p.product_id = oi.product_id;

SELECT o.order_id, c.customer_name, o.order_date
FROM customers c
RIGHT JOIN orders o ON c.customer_id = o.customer_id;

 SELECT customer_id, customer_name
FROM customers
WHERE customer_id IN (
    SELECT o.customer_id
    FROM orders o
    JOIN payments p ON o.order_id = p.order_id
    GROUP BY o.customer_id
    HAVING AVG(p.amount) > (
        SELECT AVG(amount) FROM payments
    )
);

SELECT 
    SUM(p.amount) AS total_revenue,
    AVG(p.amount) AS average_order_value
FROM payments p;

SELECT c.category_name, 
       SUM(oi.quantity) AS total_quantity,
       SUM(oi.quantity * oi.unit_price) AS total_revenue
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
JOIN categories c ON p.category_id = c.category_id
GROUP BY c.category_name;

CREATE VIEW customer_sales_summary AS
SELECT c.customer_id, c.customer_name,
       COUNT(o.order_id) AS total_orders,
       SUM(p.amount) AS total_spent
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN payments p ON o.order_id = p.order_id
GROUP BY c.customer_id, c.customer_name;

CREATE VIEW monthly_sales AS
SELECT DATE_FORMAT(o.order_date, '%Y-%m') AS month,
       SUM(oi.quantity * oi.unit_price) AS total_sales
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY month;

CREATE INDEX idx_customer_id ON orders(customer_id);
CREATE INDEX idx_product_id ON order_items(product_id);
CREATE INDEX idx_order_date ON orders(order_date);
CREATE INDEX idx_category_id ON products(category_id);
CREATE INDEX idx_order_id_payment ON payments(order_id);

SELECT * FROM customer_sales_summary;

-- H. STORED PROCEDURE FOR DYNAMIC FILTERING

DROP PROCEDURE IF EXISTS GetSalesByDateRange;

DELIMITER $$

CREATE PROCEDURE GetSalesByDateRange(IN start_date DATE, IN end_date DATE)
BEGIN
    SELECT o.order_id, c.customer_name, o.order_date, 
           SUM(oi.quantity * oi.unit_price) AS order_total
    FROM orders o
    INNER JOIN customers c ON o.customer_id = c.customer_id
    INNER JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_date BETWEEN start_date AND end_date
    GROUP BY o.order_id, c.customer_name, o.order_date
    ORDER BY o.order_date;
END $$

DELIMITER ;

CALL GetSalesByDateRange('2024-01-01', '2024-12-31');

SELECT o.order_id, c.customer_name, o.order_date, 
       SUM(oi.quantity * oi.unit_price) AS order_total
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_date BETWEEN '2024-01-01' AND '2024-12-31'
GROUP BY o.order_id, c.customer_name, o.order_date
ORDER BY o.order_date;

INSERT INTO customers (customer_id, customer_name, country) VALUES
(1, 'Alice', 'India'),
(2, 'Bob', 'USA'),
(3, 'Charlie', 'India'),
(4, 'David', 'UK'),
(5, 'Eva', 'Germany'),
(6, 'Frank', 'USA'),
(7, 'Grace', 'India'),
(8, 'Hannah', 'France'),
(9, 'Ivan', 'Canada'),
(10, 'Julia', 'India');

INSERT INTO orders (order_id, customer_id, order_date) VALUES
(101, 1, '2024-01-15'),
(102, 2, '2024-01-18'),
(103, 3, '2024-02-05'),
(104, 4, '2024-02-20'),
(105, 5, '2024-03-12'),
(106, 6, '2024-03-30'),
(107, 7, '2024-04-10'),
(108, 8, '2024-04-18'),
(109, 9, '2024-05-05'),
(110, 10, '2024-05-20');

INSERT INTO products (product_id, product_name, category_id) VALUES
(201, 'Phone Case', 301),
(202, 'Charger', 301),
(203, 'Headphones', 302),
(204, 'Smartwatch', 303),
(205, 'Bluetooth Speaker', 302);

INSERT INTO categories (category_id, category_name) VALUES
(301, 'Accessories'),
(302, 'Audio'),
(303, 'Wearables');

INSERT INTO order_items (order_id, product_id, quantity, unit_price) VALUES
(101, 201, 2, 100.00),
(101, 202, 1, 150.00),
(102, 203, 3, 200.00),
(103, 204, 1, 300.00),
(104, 201, 2, 100.00),
(105, 205, 1, 250.00),
(106, 203, 2, 200.00),
(107, 204, 1, 300.00),
(108, 202, 2, 150.00),
(109, 205, 2, 250.00),
(110, 201, 3, 100.00);

INSERT INTO payments (payment_id, order_id, payment_method, amount) VALUES
(1, 101, 'Card', 350.00),
(2, 102, 'PayPal', 600.00),
(3, 103, 'UPI', 300.00),
(4, 104, 'Card', 200.00),
(5, 105, 'Card', 250.00),
(6, 106, 'PayPal', 400.00),
(7, 107, 'UPI', 300.00),
(8, 108, 'Card', 300.00),
(9, 109, 'PayPal', 500.00),
(10, 110, 'Card', 300.00);

SELECT o.order_id, c.customer_name, o.order_date, 
       SUM(oi.quantity * oi.unit_price) AS order_total
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_date BETWEEN '2024-01-01' AND '2024-12-31'
GROUP BY o.order_id, c.customer_name, o.order_date
ORDER BY o.order_date;




