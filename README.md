# 🛒 E-Commerce Checkout Funnel & Conversion Rate Optimization (CRO) Analysis

## 📌 Executive Summary
This project evaluates customer transaction friction across a multi-stage digital storefront by engineering an end-to-end Python and SQL transformation pipeline auditing **12,719 user sessions**. The analysis identified that while top-of-funnel browsing holds strong (79.74% moving from Home to Product View), the most significant friction occurs between **Product View → Cart (40.11% conversion / ~60% drop-off)** and **Cart → Checkout**, with mobile completion lagging significantly behind desktop. Based on these findings, we outline targeted recommendations—including streamlining mobile checkout steps and automating cart recovery within 1 hour—projected to recover lost conversion opportunities.

---

## 🏢 Business Problem Statement
An e-commerce retailer experienced strong visitor acquisition but suffered from sluggish bottom-line revenue. Leadership lacked clear visibility into where prospects were stalling along the purchase journey and whether friction was driven by device disparities, acquisition channels, or checkout complexity.

**Key Objectives:**
1. **Stage-by-Stage Funnel Mapping:** Track visitor flow across five core stages:  
   `Home (5,000)` ➔ `Product Page (3,987)` ➔ `Cart (1,599)` ➔ `Checkout (1,123)` ➔ `Confirmation (1,010)`
2. **Behavioral & Segment Isolation:** Measure conversion velocity across device categories (Desktop vs. Mobile vs. Tablet), acquisition channels (Organic, Paid, Social), and cart depth.
3. **Actionable Commercial Strategy:** Translate friction metrics into concrete product and marketing initiatives.

---

## 🛠️ Tech Stack & Skills
* **SQL:** Common Table Expressions (CTEs), Conditional Aggregation (`SUM(CASE WHEN...)`), Window Functions, Safe Division.
* **Python Data Stack:** `Pandas` (Sessionization, Datetime extraction, Funnel logic), `NumPy`.
* **Data Visualization:** `Matplotlib`, `Seaborn` (Hourly trends, Country distributions, Funnel drop-offs).
* **Keywords:** E-Commerce Analytics, Conversion Rate Optimization (CRO), Dual-Stack ETL, A/B Testing Strategy.

---

## 🔬 Technical Methodology
1. **Data Hygiene & Chronological Validation:** Ingested 12,719 interaction logs, checked for nulls, parsed ISO timestamps, and verified that timestamps logically advanced from discovery to confirmation.
2. **Sessionization & Duration Metrics:** Computed total session durations (`SessionDuration_seconds`), revealing that purchasers spend an average of **388.24s** on-site compared to **114.00s** for non-purchasers.
3. **Dual-Stack Funnel Construction:** Modeled stage progression in Pandas and replicated the pipeline using an in-memory SQL database with modular CTEs to emulate production data warehouse (BigQuery/Snowflake) environments.
4. **Multivariate Segmentation:** Sliced conversion by Hour of Day, Day of Week, Referral Source, and Cart Items.

---

## 📊 Key Findings & Results

| Funnel Stage | Unique Sessions | Step-to-Step Conversion | Overall Conversion |
| :--- | :--- | :--- | :--- |
| **Home** | 5,000 | 79.74% | 100.00% |
| **Product Page** | 3,987 | **40.11% (Largest Drop)** | 79.74% |
| **Cart** | 1,599 | 70.23% | 31.98% |
| **Checkout** | 1,123 | 89.94% | 22.46% |
| **Confirmation** | 1,010 | — | **20.20%** |

* **The Mid-Funnel Leak:** The biggest absolute bottleneck occurs between viewing a product and adding to cart (only **40.11%** transition), followed by the Cart-to-Checkout transition.
* **Device Disparity:** Mobile users drop off at a notably higher rate during the final two steps than desktop users, signaling UI friction and long checkout forms.
* **Temporal Patterns:** Abandonment rates spike during late evening hours, and conversion peaks mid-week (Wednesday).
* **Cart Volume Correlation:** Sessions with 0-1 items in cart show the highest completion rate (~92% down to ~78%), with conversion leveling out at ~72-74% for 2+ items.

---

## 💡 Strategic Business Recommendations
* **Product / UX:**
  * **One-Click Mobile Checkout:** Introduce Apple Pay / Google Pay and single-page checkout to eliminate mobile input friction.
  * **Transparent Pricing on Product Pages:** Show shipping and tax estimates prior to the Cart step to address the 60% drop-off between product view and cart addition.
* **Growth & Marketing:**
  * **Automated Abandoned Cart Triggers:** Dispatch email/SMS reminders within 60 minutes of abandonment, capitalizing on high-intent shoppers.
  * **Channel Reallocation:** Shift marketing spend toward top-performing paid channels while re-evaluating underperforming social traffic.

---

## 🚀 Next Steps & Project Limitations
* **Limitations:** The dataset is synthetic and does not track order monetary value ($ AOV), individual item pricing tiers, or payment gateway error logs.
* **Future Experiments:** Implement a 30-day randomized A/B test on mobile traffic:
  * **Variant A:** Existing multi-step form.
  * **Variant B:** Simplified 2-step checkout with guest payment and autofill.

---

## 💻 Repository Structure & Quickstart
```text
├── data/
│   └── funnel-drop-data.csv
├── notebooks/
│   └── ecommerce_funnel_analysis.ipynb
├── README.md
