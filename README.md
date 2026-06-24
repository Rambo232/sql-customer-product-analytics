# Customer & Product Analytics Reports | SQL

Analytical dashboards (gold layer) based on a star schema consisting of `fact_sales`, `dim_customers`, and `dim_products`.

## What's Inside

- **report_customers** — customer age, order count, average check value, recency / days since last purchase, customer lifetime duration, segmentation (VIP/Regular/New).
- **report_product** — revenue, order count, number of customers, average selling price, recency / days since last sale, segmentation by sales volume (High-Performer/Mid-Range/Low-Performer).
- Product segmentation based on cost ranges.

## SQL Techniques

- CTEs (multi-step WITH chains)
- Cumulative & period-based aggregation via TIMESTAMPDIFF
- CASE-based segmentation with division-by-zero protection
- Reusable analytical VIEWs
- Deliberate choice of time anchor per metric: customer age and
  recency are computed against the dataset's last order date
  (since the data is historical), while product recency is
  computed against the real current date — mirroring how that
  metric behaves in a live system. Both choices are documented
  inline, in Russian and English.

## Data Source

The data schema is based on a standard educational e-commerce model adapted for dimensional modeling analysis. 
It simulates real-world scenarios involving sales facts and customer/product dimensions to demonstrate complex SQL reporting techniques.


## Files

`customer_product_reports_final.sql` — all queries with inline comments



======================================================
# Русская версия

# Customer & Product Analytics Reports | SQL

Аналитические витрины (gold-слой) на основе звёздной схемы
fact_sales + dim_customers + dim_products.

## Что внутри

- **report_customers** — возраст, заказы, средний чек, давность
  последней покупки, срок жизни клиента, сегментация (VIP/Regular/New)
- **report_product** — выручка, заказы, клиенты, средняя цена продажи,
  давность последней продажи, сегментация по объёму продаж
  (High-Performer/Mid-Range/Low-Performer)
- Сегментация товаров по диапазону себестоимости

## SQL-техники

- CTE (многошаговые WITH-цепочки)
- Работа с датами: TIMESTAMPDIFF, агрегации по периодам
- CASE-сегментация с защитой от деления на ноль
- Создание VIEW для повторного использования отчётов
- Осознанный выбор точки отсчёта для разных метрик: возраст и
  recency клиента считаются от последней даты в данных (датасет
  исторический), а recency товара — от реальной текущей даты,
  как это работало бы в живой системе. Обе логики задокументированы
  прямо в коде на русском и английском.

## Данные

Схема данных основана на стандартной образовательной модели электронной коммерции, адаптированной для анализа многомерного моделирования. Она имитирует реальные сценарии, включающие данные о продажах и измерения клиентов/товаров, для демонстрации сложных методов создания отчетов с использованием SQL.

## Файлы

`customer_product_reports_final.sql` — все запросы с комментариями
