/* =============================================================================
   E-COMMERCE FUNNEL & USER BEHAVIOR ANALYSIS
   Target Table : november (event logs containing user_id, event_type, category_code, price)
   Dialect      : PostgreSQL / Standard SQL (Compatible with Snowflake, BigQuery, Redshift)
   ============================================================================= */

-- -----------------------------------------------------------------------------
-- 0. BASELINE METRIC: Total Unique Active Users
-- Business Context: Establish the top-of-funnel reach for the month.
-- -----------------------------------------------------------------------------
SELECT 
    COUNT(DISTINCT user_id) AS total_unique_users 
FROM november;


-- -----------------------------------------------------------------------------
-- 1. OVERALL FUNNEL INSIGHT (User-Level Conversion & Fallout)
-- Business Context: Measure step-to-step conversion from View -> Cart -> Purchase
--                   to identify where the largest drop-off occurs.
-- -----------------------------------------------------------------------------
WITH user_behavior AS (
    -- Step 1: Flag whether each individual user completed each funnel stage
    SELECT 
        user_id,
        MAX(CASE WHEN event_type = 'view' THEN 1 ELSE 0 END)     AS has_viewed,
        MAX(CASE WHEN event_type = 'cart' THEN 1 ELSE 0 END)     AS has_carted,
        MAX(CASE WHEN event_type = 'purchase' THEN 1 ELSE 0 END) AS has_purchased
    FROM november
    GROUP BY user_id
)
SELECT 
    COUNT(user_id)         AS total_users,
    SUM(has_viewed)        AS view_users,
    SUM(has_carted)        AS cart_users,
    SUM(has_purchased)     AS purchase_users,
    
    -- Step-to-step conversion rates with NULLIF to prevent division-by-zero errors
    ROUND(SUM(has_carted) * 100.0 / NULLIF(SUM(has_viewed), 0), 2)    AS view_to_cart_rate_pct,
    ROUND(SUM(has_purchased) * 100.0 / NULLIF(SUM(has_carted), 0), 2) AS cart_to_purchase_rate_pct,
    
    -- Overall end-to-end conversion rate (View to Purchase)
    ROUND(SUM(has_purchased) * 100.0 / NULLIF(SUM(has_viewed), 0), 2) AS overall_conversion_rate_pct
FROM user_behavior;


-- -----------------------------------------------------------------------------
-- 2. CATEGORY FUNNEL INSIGHT
-- Business Context: Extract top-level category from dot-delimited string (e.g. 'appliances.iron')
--                   and compare conversion efficiencies across different product departments.
-- -----------------------------------------------------------------------------
WITH parsed_categories AS (
    -- Step 1: Extract root category and clean NULL/blank categories
    SELECT 
        user_id,
        event_type,
        COALESCE(NULLIF(SPLIT_PART(category_code, '.', 1), ''), 'uncategorized') AS root_category
    FROM november
),
category_funnel AS (
    -- Step 2: Calculate unique users per funnel stage per root category
    SELECT 
        root_category,
        COUNT(DISTINCT CASE WHEN event_type = 'view' THEN user_id END)     AS view_users,
        COUNT(DISTINCT CASE WHEN event_type = 'cart' THEN user_id END)     AS cart_users,
        COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) AS purchase_users
    FROM parsed_categories
    GROUP BY root_category
)
SELECT 
    root_category,
    view_users,
    cart_users,
    purchase_users,
    -- Calculate step-to-step conversion percentages
    ROUND(cart_users * 100.0 / NULLIF(view_users, 0), 2)     AS view_to_cart_rate_pct,
    ROUND(purchase_users * 100.0 / NULLIF(cart_users, 0), 2) AS cart_to_purchase_rate_pct
FROM category_funnel
-- Filter out categories with negligible browsing traffic to prevent skewed conversion ratios
WHERE view_users >= 50
ORDER BY view_to_cart_rate_pct ASC;


-- -----------------------------------------------------------------------------
-- 3. PRICE ELASTICITY & CATEGORY BOTTLENECK ANALYSIS
-- Business Context: Find the 5 worst-performing categories by View-to-Cart conversion
--                   and drill down by price tier (Low / Medium / High) to diagnose
--                   if cart abandonment is driven by price friction.
-- -----------------------------------------------------------------------------
WITH parsed_events AS (
    -- Step 1: Standardize category and assign price buckets
    SELECT
        user_id,
        event_type,
        COALESCE(NULLIF(SPLIT_PART(category_code, '.', 1), ''), 'uncategorized') AS category,
        CASE
            WHEN price < 500              THEN '1. Low (< $500)'
            WHEN price BETWEEN 500 AND 1500 THEN '2. Medium ($500 - $1500)'
            ELSE                               '3. High (> $1500)'
        END AS price_bucket
    FROM november
),
price_metrics AS (
    -- Step 2: Unique users per category and price bucket
    SELECT
        category,
        price_bucket,
        COUNT(DISTINCT CASE WHEN event_type = 'view' THEN user_id END) AS view_users,
        COUNT(DISTINCT CASE WHEN event_type = 'cart' THEN user_id END) AS cart_users
    FROM parsed_events
    GROUP BY category, price_bucket
),
category_totals AS (
    -- Step 3: Aggregate overall category totals directly from price_metrics (no second full-table scan)
    SELECT
        category,
        SUM(view_users) AS total_views,
        SUM(cart_users) AS total_carts,
        ROUND(SUM(cart_users) * 100.0 / NULLIF(SUM(view_users), 0), 2) AS overall_view_to_cart_pct
    FROM price_metrics
    GROUP BY category
    HAVING SUM(view_users) >= 100 -- Focus on statistically significant traffic
),
bottom_5_categories AS (
    -- Step 4: Isolate the 5 categories with the lowest View -> Cart rate
    SELECT 
        category,
        overall_view_to_cart_pct
    FROM category_totals
    ORDER BY overall_view_to_cart_pct ASC
    LIMIT 5
)
-- Step 5: Final output detailing price tiers inside the bottom 5 categories
SELECT
    pm.category,
    b5.overall_view_to_cart_pct,
    pm.price_bucket,
    pm.view_users,
    pm.cart_users,
    ROUND(pm.cart_users * 100.0 / NULLIF(pm.view_users, 0), 2) AS tier_view_to_cart_pct
FROM price_metrics pm
INNER JOIN bottom_5_categories b5 
    ON pm.category = b5.category
ORDER BY
    b5.overall_view_to_cart_pct ASC,
    pm.category ASC,
    pm.price_bucket ASC;