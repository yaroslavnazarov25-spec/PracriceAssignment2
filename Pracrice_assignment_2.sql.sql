--Using explain analyze:
--Execution time: 205 ms (without indexes)
SELECT
    p.product_category as pc,

    (
        SELECT COUNT(*)
        FROM opt_orders o2
        JOIN opt_products p2
            ON o2.product_id = p2.product_id
        WHERE p2.product_category = p.product_category
        	AND o2.order_date >= '2025-12-01' 
    		AND o2.order_date <= '2025-12-07'
    ) AS tor,

    (
        SELECT COUNT(DISTINCT c2.id)
        FROM opt_clients c2
        JOIN opt_orders o3
            ON c2.id = o3.client_id
        JOIN opt_products p3
            ON o3.product_id = p3.product_id
        WHERE c2.status = 'active'
          AND p3.product_category = p.product_category
          AND o3.order_date >= '2025-12-01' 
    	  AND o3.order_date <= '2025-12-07'
    ) AS ac,

    (
        SELECT MAX(o4.order_date)
        FROM opt_orders o4
        JOIN opt_products p4
            ON o4.product_id = p4.product_id
        WHERE p4.product_category = p.product_category
        	AND o4.order_date >= '2025-12-01' 
    		AND o4.order_date <= '2025-12-07'
    ) AS lod
FROM opt_products p
GROUP BY p.product_category;



--Using explain analyze:
--Execution time: 40 ms (with indexes)
--With SET enable_bitmapscan = off and SET enable_indexscan = off:
--Execution time: 138 ms (does not use indexes)
WITH order_details AS (
    SELECT
        o.order_id,
        o.order_date,
        c.id,
        c.status,
        p.product_category
    FROM opt_orders o
    JOIN opt_clients c
        ON o.client_id = c.id
    JOIN opt_products p
        ON o.product_id = p.product_id
)
SELECT
    product_category,
    COUNT(order_id) AS total_orders,
    COUNT(DISTINCT id)
        FILTER (WHERE status = 'active') AS active_clients,
    MAX(order_date) AS last_order_date
FROM order_details as o_d
WHERE
    o_d.order_date >= '2025-12-01' 
    AND o_d.order_date <= '2025-12-07'
GROUP BY product_category;

--Optimized qwery:
--1) uses CTE to minimize the number of repetitions in the code and improve readability
--2) uses better alias names
--3) does not use unnecessary subqweries
--4) uses indexes:
--	idx_orders_date_client_product - opt_orders(order_date, client_id, product_id),
--	dx_products_category - opt_products(product_category),
--	idx_clients_status - opt_clients(status)