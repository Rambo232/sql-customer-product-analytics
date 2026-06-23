-- ================================================================
-- RU: ФИНАЛЬНЫЕ ОТЧЁТЫ — КЛИЕНТЫ И ТОВАРЫ
-- EN: FINAL REPORTS — CUSTOMERS & PRODUCTS
-- ================================================================
-- RU: Слой gold. Консолидированные витрины для дальнейшего анализа
--     и визуализации. Каждая секция документирована на двух языках.
-- EN: Gold layer. Consolidated views for downstream analysis and
--     visualization. Each section is documented in two languages.
-- ================================================================


-- ================================================================
-- RU: 1. СЕГМЕНТАЦИЯ ТОВАРОВ ПО ДИАПАЗОНУ СЕБЕСТОИМОСТИ
-- EN: 1. PRODUCT SEGMENTATION BY COST RANGE
-- ================================================================
-- RU: Исправлено: третий диапазон дублировал метку второго
--     ('100-500' вместо '500-1000'), из-за чего два разных
--     ценовых сегмента сливались при агрегации. Границы заданы
--     через >= / < без BETWEEN, чтобы исключить любую
--     неоднозначность на стыке диапазонов.
-- EN: Fixed: the third range duplicated the second range's label
--     ('100-500' instead of '500-1000'), causing two distinct
--     price segments to merge during aggregation. Boundaries use
--     >= / < instead of BETWEEN to remove any ambiguity at the
--     edges of each range.
-- ================================================================

WITH product_segments AS (
    SELECT
        product_key,
        product_name,
        cost,
        CASE
            WHEN cost < 100 THEN 'Below 100'
            WHEN cost >= 100 AND cost < 500 THEN '100-500'
            WHEN cost >= 500 AND cost < 1000 THEN '500-1000'
            ELSE 'Above 1000'
        END AS cost_range
    FROM dim_products
)
SELECT
    cost_range,
    COUNT(product_key) AS total_products
FROM product_segments
GROUP BY cost_range
ORDER BY total_products DESC;


-- ================================================================
-- RU: 2. ОТЧЁТ ПО КЛИЕНТАМ (gold.report_customers)
-- EN: 2. CUSTOMER REPORT (gold.report_customers)
-- ================================================================
-- RU: Назначение: свести ключевые метрики по каждому клиенту в
--     одну витрину — возраст, заказы, средний чек, давность
--     последней покупки, срок жизни и сегмент.
-- EN: Purpose: consolidate key per-customer metrics into a single
--     view — age, orders, average order value, recency of last
--     purchase, lifespan, and segment.
-- ================================================================

DROP VIEW IF EXISTS gold.report_customers;

CREATE VIEW gold.report_customers AS
WITH max_date_cte AS (
    -- RU: Последняя дата заказа во всём датасете — используется
    --     как точка отсчёта для возраста, потому что данные
    --     исторические и не обновляются. Считать возраст от
    --     сегодняшней реальной даты дало бы нереалистичные
    --     значения (датасет старый — клиенты выглядели бы старше
    --     своего реального возраста на момент покупок).
    -- EN: Latest order date across the whole dataset — used as the
    --     reference point for age, because the data is historical
    --     and not live. Computing age against the real
    --     CURRENT_DATE() would produce unrealistic values (an old
    --     dataset would make customers look older than they
    --     actually were at the time of purchase).
    SELECT
        MAX(order_date) AS global_last_date
    FROM fact_sales
    WHERE order_date != 0
),
base_query AS (
    SELECT
        s.order_number,
        s.product_key,
        s.order_date,
        s.sales_amount,
        s.quantity,
        c.customer_key,
        c.customer_number,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        TIMESTAMPDIFF(YEAR, c.birthdate, m.global_last_date) AS age,
        m.global_last_date
    FROM fact_sales AS s
    JOIN dim_customers AS c ON s.customer_key = c.customer_key
    CROSS JOIN max_date_cte AS m
    WHERE s.order_date != 0
),
customer_aggregation AS (
    SELECT
        customer_key,
        customer_number,
        customer_name,
        age,
        COUNT(DISTINCT order_number) AS total_orders,
        SUM(sales_amount) AS total_sales,
        SUM(quantity) AS total_quantity,
        COUNT(DISTINCT product_key) AS total_products,
        MAX(order_date) AS last_order,
        MAX(global_last_date) AS global_last_date,
        TIMESTAMPDIFF(MONTH, MIN(order_date), MAX(order_date)) AS lifespan
    FROM base_query
    GROUP BY customer_key, customer_number, customer_name, age
)
SELECT
    customer_key,
    customer_number,
    customer_name,
    age,
    total_orders,
    -- RU: Средний чек на заказ
    -- EN: Average order value
    CASE
        WHEN total_orders = 0 THEN 0
        ELSE ROUND(total_sales / total_orders, 2)
    END AS avg_order_value,
    total_sales,
    total_quantity,
    total_products,
    last_order,
    -- RU: Давность последней покупки считаем от global_last_date,
    --     а НЕ от сегодняшней даты — чтобы давность отражала
    --     реальное поведение клиента внутри периода данных, а не
    --     просто "сколько лет прошло с момента выгрузки датасета".
    --     Сравните с recency_in_months в report_product ниже —
    --     там точка отсчёта другая, и это сделано намеренно.
    -- EN: Recency is anchored to global_last_date, not real
    --     CURRENT_DATE() — so it reflects the customer's actual
    --     behaviour within the dataset's timeframe, not simply
    --     "how many years have passed since the data was pulled".
    --     Compare with recency_in_months in report_product below —
    --     the anchor point differs there on purpose.
    TIMESTAMPDIFF(DAY, last_order, global_last_date) AS recency,
    lifespan,
    -- RU: Средние расходы в месяц
    -- EN: Average monthly spend
    CASE
        WHEN lifespan = 0 THEN total_sales
        ELSE ROUND(total_sales / lifespan, 2)
    END AS avg_monthly_spend,
    CASE
        WHEN age < 20 THEN 'Under 20'
        WHEN age BETWEEN 20 AND 29 THEN '20-29'
        WHEN age BETWEEN 30 AND 39 THEN '30-39'
        WHEN age BETWEEN 40 AND 49 THEN '40-49'
        ELSE '50 and Above'
    END AS age_group,
    -- RU: Сегмент клиента — VIP при долгом сроке жизни и высоких
    --     тратах, Regular — долгий срок жизни, но низкие траты,
    --     остальные — New customer.
    -- EN: Customer segment — VIP for long lifespan with high
    --     spend, Regular for long lifespan with low spend,
    --     everyone else — New customer.
    CASE
        WHEN lifespan >= 12 AND total_sales > 5000 THEN 'VIP'
        WHEN lifespan >= 12 AND total_sales <= 5000 THEN 'Regular'
        ELSE 'New customer'
    END AS customer_segment
FROM customer_aggregation
ORDER BY total_sales DESC;


-- ================================================================
-- RU: 3. ОТЧЁТ ПО ТОВАРАМ (gold.report_product)
-- EN: 3. PRODUCT REPORT (gold.report_product)
-- ================================================================
-- RU: Назначение: свести ключевые метрики по каждому товару —
--     выручку, заказы, клиентов, средний чек, давность последней
--     продажи и сегмент по объёму продаж.
-- EN: Purpose: consolidate key per-product metrics — revenue,
--     orders, customers, average order revenue, recency of the
--     last sale, and a sales-volume-based segment.
-- ================================================================

DROP VIEW IF EXISTS gold.report_product;

CREATE VIEW gold.report_product AS
WITH base_query AS (
    -- RU: 1) Базовый запрос — соединяем продажи и товары
    -- EN: 1) Base query — join sales facts with the product dimension
    SELECT
        fact.order_number,
        fact.order_date,
        fact.customer_key,
        fact.sales_amount,
        fact.quantity,
        prod.product_key,
        prod.product_name,
        prod.category,
        prod.subcategory,
        prod.cost
    FROM fact_sales AS fact
    JOIN dim_products AS prod ON prod.product_key = fact.product_key
    WHERE order_date != 0
),
product_aggregations AS (
    -- RU: 2) Агрегации на уровне товара
    -- EN: 2) Product-level aggregations
    SELECT
        product_key,
        product_name,
        category,
        subcategory,
        cost,
        TIMESTAMPDIFF(MONTH, MIN(order_date), MAX(order_date)) AS lifespan,
        MAX(order_date) AS last_sale_date,
        COUNT(DISTINCT order_number) AS total_orders,
        COUNT(DISTINCT customer_key) AS total_customers,
        SUM(sales_amount) AS total_sales,
        SUM(quantity) AS total_quantity,
        ROUND(AVG(sales_amount / quantity), 2) AS avg_selling_price
    FROM base_query
    GROUP BY product_key, product_name, category, subcategory, cost
)
-- RU: 3) Финальный запрос — собирает итоговый отчёт по товарам
-- EN: 3) Final query — assembles the finished product report
SELECT
    product_key,
    product_name,
    category,
    subcategory,
    cost,
    last_sale_date,
    -- RU: В отличие от report_customers, давность продаж здесь
    --     НАМЕРЕННО считается от РЕАЛЬНОЙ текущей даты — именно
    --     так эта метрика работает в живой production-системе:
    --     "сколько времени прошло с последней продажи прямо
    --     сейчас". На исторических/статичных данных абсолютные
    --     числа будут выглядеть большими, но относительное
    --     сравнение между товарами остаётся корректным: разница
    --     в recency между двумя товарами не зависит от выбора
    --     точки отсчёта, потому что обе даты сдвигаются на одну и
    --     ту же константу. Если эта метрика когда-либо пойдёт в
    --     пороговую фильтрацию (например "товары без продаж за
    --     последние 6 месяцев"), точку отсчёта нужно будет
    --     пересмотреть — иначе все товары попадут в одну группу.
    -- EN: Unlike report_customers, recency here is INTENTIONALLY
    --     anchored to the REAL CURRENT_DATE() — mirroring how this
    --     metric behaves in a live production system: "how long
    --     ago was the last sale, right now". On historical/static
    --     data the absolute numbers will look large, but relative
    --     comparisons between products stay valid, since both
    --     dates shift by the same constant offset. If this metric
    --     is ever used for threshold-based filtering (e.g. "products
    --     with no sales in the last 6 months"), the anchor should be
    --     reconsidered — otherwise every product would fall into the
    --     same bucket.
    TIMESTAMPDIFF(MONTH, last_sale_date, CURRENT_DATE()) AS recency_in_months,
    -- RU: Сегмент товара по суммарной выручке
    -- EN: Product segment by total revenue
    CASE
        WHEN total_sales > 50000 THEN 'High-Performer'
        WHEN total_sales >= 10000 THEN 'Mid-Range'
        ELSE 'Low-Performer'
    END AS product_segment,
    lifespan,
    total_orders,
    total_sales,
    total_quantity,
    total_customers,
    avg_selling_price,
    -- RU: Средняя выручка с одного заказа
    -- EN: Average order revenue
    CASE
        WHEN total_orders = 0 THEN 0
        ELSE ROUND(total_sales / total_orders, 2)
    END AS avg_order_revenue,
    -- RU: Средняя выручка в месяц
    -- EN: Average monthly revenue
    CASE
        WHEN lifespan = 0 THEN total_sales
        ELSE ROUND(total_sales / lifespan, 2)
    END AS avg_monthly_revenue
FROM product_aggregations
ORDER BY total_sales DESC;
