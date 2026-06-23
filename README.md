# Customer & Product Analytics Reports | SQL

Analytical dashboards (gold layer) based on a star schema consisting of `fact_sales`, `dim_customers`, and `dim_products`.

## What's Inside

- **report_customers** — customer age, order count, average check value, recency / days since last purchase, customer lifetime duration, segmentation (VIP/Regular/New).
- **report_product** — revenue, order count, number of customers, average selling price, recency / days since last sale, segmentation by sales volume (High-Performer/Mid-Range/Low-Performer).
- Product segmentation based on cost ranges.

## SQL Techniques

- CTEs (Multi-step WITH chains)
- Date handling: TIMESTAMPDIFF, period aggregations
- CASE-based segmentation with division-by-zero protection
- Creating VIEWS for report reusability
- Conscious choice of reference point for metrics: customer age and recency are calculated from the latest date in the dataset (historical context), while product recency is calculated from the real current date to mimic a live system. Both logics are documented directly within the code in Russian and English.

## Data

The data schema was adapted from an educational SQL course (dimensional modeling: fact + dim tables).

## Files

`customer_product_reports_final.sql` — all queries with inline comments



===========================================================================================================================================
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

Схема данных адаптирована из учебного курса по SQL
(дименсиональное моделирование: fact + dim таблицы).

## Файлы

`customer_product_reports_final.sql` — все запросы с комментариями
