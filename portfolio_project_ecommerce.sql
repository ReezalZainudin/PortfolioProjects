USE mavenfuzzyfactory;

-- Traffic analysis and optimization
-- 1 Finding top traffic sources

SELECT * FROM website_sessions;

SELECT
	utm_source,
	utm_campaign,
	http_referer,
    
	COUNT(DISTINCT website_session_id) AS total_number_of_sessions
    
FROM website_sessions
WHERE
	created_at <= '2012-04-12'
GROUP BY
	utm_source,
	utm_campaign,
	http_referer
ORDER BY
	total_number_of_sessions DESC;

-- 2 Traffic source conversion rates

SELECT * FROM website_sessions;
SELECT * FROM orders;

SELECT
	website_sessions.utm_source,
	website_sessions.utm_campaign,
    
	COUNT(DISTINCT orders.order_id) AS total_number_of_orders,
	COUNT(DISTINCT website_sessions.website_session_id) AS total_number_of_sessions,
   
	ROUND(COUNT(DISTINCT orders.order_id) /
		COUNT(DISTINCT website_sessions.website_session_id) * 100, 2) AS conversion_rate    
        
FROM website_sessions
	LEFT JOIN orders
		ON orders.website_session_id =  website_sessions.website_session_id
WHERE
	website_sessions.created_at < '2012-04-14'
	AND website_sessions.utm_source = 'gsearch'
	AND website_sessions.utm_campaign = 'nonbrand';
    
-- 3 Traffic source trending

SELECT * FROM website_sessions;

SELECT
	-- YEAR(created_at),
	-- WEEK(created_at),
	utm_source,
	utm_campaign,
    
	MIN(DATE(created_at)) AS week_started_at,
	COUNT(DISTINCT website_session_id) AS total_number_of_sessions
    
FROM website_sessions
WHERE
	created_at < '2012-05-10'
	AND utm_source = 'gsearch'
	AND utm_campaign = 'nonbrand'
GROUP BY
	YEAR(created_at),
	WEEK(created_at);

-- 4 Bid optimization for paid traffic

SELECT * FROM website_sessions;

SELECT
	website_sessions.utm_source,
	website_sessions.utm_campaign,
	website_sessions.device_type,
    
	COUNT(DISTINCT website_sessions.website_session_id) AS total_number_of_sessions,
	COUNT(DISTINCT orders.order_id) AS total_number_of_orders,
    
	ROUND(COUNT(DISTINCT orders.order_id) / 
		COUNT(DISTINCT website_sessions.website_session_id) * 100, 2) AS conversion_rate
        
FROM website_sessions
	LEFT JOIN orders
		ON orders.website_session_id = website_sessions.website_session_id
WHERE
	website_sessions.created_at < '2012-05-11'
	AND website_sessions.utm_source = 'gsearch'
	AND website_sessions.utm_campaign = 'nonbrand'
GROUP BY
	website_sessions.utm_source,
	website_sessions.utm_campaign,
	website_sessions.device_type
ORDER BY
	conversion_rate DESC;

-- 5 Trending with granular segments 

SELECT * FROM website_sessions;

SELECT
	-- YEAR(created_at),
	-- WEEK(created_at),
	utm_source,
	utm_campaign,
	MIN(DATE(created_at)) AS week_started_at,
    
	COUNT(DISTINCT CASE WHEN device_type = 'mobile' THEN website_session_id ELSE NULL END) AS total_number_of_mobile_sessions,
	COUNT(DISTINCT CASE WHEN device_type = 'desktop' THEN website_session_id ELSE NULL END) AS total_number_of_desktop_sessions,
    
	COUNT(DISTINCT website_session_id) AS total_number_of_sessions
    
FROM website_sessions
WHERE
	created_at < '2012-06-09'
	AND created_at >= '2012-04-15'
	AND utm_source = 'gsearch'
	AND utm_campaign = 'nonbrand'
GROUP BY
	YEAR(created_at),
	WEEK(created_at);

-- Website measurement and testing
-- 1 Finding top website pages

SELECT * FROM website_pageviews;

SELECT
	website_sessions.utm_source,
    website_sessions.utm_campaign,
	website_pageviews.pageview_url,
    
    COUNT(DISTINCT website_pageviews.website_pageview_id) AS total_number_of_pageviews
    
FROM website_pageviews
	LEFT JOIN website_sessions
		ON website_sessions.website_session_id = website_pageviews.website_session_id
WHERE
	website_pageviews.created_at < '2012-06-09'
    AND website_sessions.utm_source = 'gsearch'
    AND website_sessions.utm_campaign = 'nonbrand'
GROUP BY
	website_pageviews.pageview_url
ORDER BY
	total_number_of_pageviews DESC;

-- 2 Finding top entry pages or landing pages

SELECT * FROM website_pageviews;

CREATE TEMPORARY TABLE entry_page_per_session_table
SELECT
	website_sessions.utm_source,
    website_sessions.utm_campaign,
    website_pageviews.website_session_id,
    
	MIN(website_pageviews.website_pageview_id) AS entry_page_id,
    MIN(DATE(website_pageviews.created_at)) AS created_at
    
FROM website_pageviews
	LEFT JOIN website_sessions
		ON website_sessions.website_session_id = website_pageviews.website_session_id
WHERE
	website_pageviews.created_at < '2012-06-12'
	AND website_sessions.utm_source = 'gsearch'
    AND website_sessions.utm_campaign = 'nonbrand'
GROUP BY
	website_pageviews.website_session_id
ORDER BY
	website_pageviews.website_session_id;

SELECT * FROM entry_page_per_session_table;

SELECT
	entry_page_per_session_table.utm_source,
    entry_page_per_session_table.utm_campaign,
	website_pageviews.pageview_url AS entry_page_url,
    
    COUNT(DISTINCT entry_page_per_session_table.website_session_id) AS total_number_of_sessions
    
FROM entry_page_per_session_table
	LEFT JOIN website_pageviews
		ON website_pageviews.website_pageview_id = entry_page_per_session_table.entry_page_id
GROUP BY
	entry_page_url
ORDER BY
	 total_number_of_sessions;

DROP TEMPORARY TABLE entry_page_per_session_table;

-- 3 Calculating bounce rates

SELECT * FROM website_pageviews;
SELECT * FROM orders;

CREATE TEMPORARY TABLE entry_page_per_session_table
SELECT
	website_sessions.utm_source,
    website_sessions.utm_campaign,
	website_pageviews.website_session_id,
    
    MIN(website_pageviews.website_pageview_id) AS entry_page_id,
    MIN(DATE(website_pageviews.created_at)) AS created_at,
    COUNT(DISTINCT website_pageviews.website_pageview_id) AS total_number_of_pageviews
    
FROM website_pageviews
	LEFT JOIN website_sessions
		ON website_sessions.website_session_id = website_pageviews.website_session_id
WHERE
	website_pageviews.created_at < '2012-06-14'
	AND website_sessions.utm_source = 'gsearch'
    AND website_sessions.utm_campaign = 'nonbrand'
GROUP BY
	website_pageviews.website_session_id
ORDER BY
	website_pageviews.website_session_id;
    
SELECT * FROM entry_page_per_session_table;

SELECT
	entry_page_per_session_table.utm_source,
    entry_page_per_session_table.utm_campaign,
	website_pageviews.pageview_url AS entry_page_url,
    
    COUNT(CASE WHEN entry_page_per_session_table.total_number_of_pageviews > 1 THEN entry_page_per_session_table.website_session_id ELSE NULL END) AS total_number_of_non_bounce_sessions,
    COUNT(CASE WHEN entry_page_per_session_table.total_number_of_pageviews = 1 THEN entry_page_per_session_table.website_session_id ELSE NULL END) AS total_number_of_bounced_sessions,
    COUNT(DISTINCT entry_page_per_session_table.website_session_id) AS total_number_of_sessions,
    
    ROUND(COUNT(CASE WHEN entry_page_per_session_table.total_number_of_pageviews = 1 THEN entry_page_per_session_table.website_session_id ELSE NULL END) /
		COUNT(DISTINCT entry_page_per_session_table.website_session_id) * 100, 2) AS bounce_rates

FROM entry_page_per_session_table
	LEFT JOIN website_pageviews
		ON website_pageviews.website_pageview_id = entry_page_per_session_table.entry_page_id
GROUP BY
	website_pageviews.pageview_url
ORDER BY
	bounce_rates;

DROP TEMPORARY TABLE entry_page_per_session_table;

-- 4 Analyzing landing page tests

SELECT * FROM website_pageviews;

SELECT
	website_sessions.utm_source,
    website_sessions.utm_campaign,
	website_pageviews.pageview_url,
    
    MIN(website_pageviews.created_at) AS first_created_at,
    MIN(website_pageviews.website_pageview_id) AS first_website_pageview_id,
    MIN(website_pageviews.website_session_id) AS first_website_session_id
    
FROM website_pageviews
	LEFT JOIN website_sessions
		ON website_sessions.website_session_id = website_pageviews.website_session_id
WHERE 
	website_pageviews.pageview_url = '/lander-1'
    AND website_pageviews.created_at < '2012-07-28'
	AND website_sessions.utm_source = 'gsearch'
    AND website_sessions.utm_campaign = 'nonbrand'
GROUP BY
	website_pageviews.pageview_url;

CREATE TEMPORARY TABLE entry_page_per_session_table
SELECT
	website_sessions.utm_source,
    website_sessions.utm_campaign,
	website_pageviews.website_session_id,
    
    MIN(website_pageviews.website_pageview_id) AS entry_page_id,
    MIN(DATE(website_pageviews.created_at)) AS created_at,
    COUNT(DISTINCT website_pageviews.website_pageview_id) AS total_number_of_pageviews
    
FROM website_pageviews
	LEFT JOIN website_sessions
		ON website_sessions.website_session_id = website_pageviews.website_session_id
WHERE
	website_pageviews.website_session_id >= 11683
    AND website_pageviews.created_at < '2012-07-28'
    AND website_sessions.utm_source = 'gsearch'
    AND website_sessions.utm_campaign = 'nonbrand'
GROUP BY
	website_pageviews.website_session_id
ORDER BY
	website_pageviews.website_session_id;

SELECT * FROM entry_page_per_session_table;

SELECT
	entry_page_per_session_table.utm_source,
    entry_page_per_session_table.utm_campaign,
	website_pageviews.pageview_url AS entry_page,
    
    COUNT(DISTINCT CASE WHEN entry_page_per_session_table.total_number_of_pageviews = 1 THEN entry_page_per_session_table.website_session_id ELSE NULL END) AS total_number_of_bounced_sessions,
    COUNT(DISTINCT CASE WHEN entry_page_per_session_table.total_number_of_pageviews > 1 THEN entry_page_per_session_table.website_session_id ELSE NULL END) AS total_number_of_non_bounce_sessions,
    COUNT(DISTINCT entry_page_per_session_table.website_session_id) AS total_number_of_sessions,
    
    ROUND(COUNT(DISTINCT CASE WHEN entry_page_per_session_table.total_number_of_pageviews = 1 THEN entry_page_per_session_table.website_session_id ELSE NULL END) /
		COUNT(DISTINCT entry_page_per_session_table.website_session_id) * 100, 2) AS bounce_rates
    
FROM entry_page_per_session_table
	LEFT JOIN website_pageviews
		ON website_pageviews.website_pageview_id = entry_page_per_session_table.entry_page_id
GROUP BY
	entry_page
ORDER BY
	bounce_rates;

DROP TEMPORARY TABLE entry_page_per_session_table;

-- 5 Landing page trend analysis

SELECT * FROM website_pageviews;

CREATE TEMPORARY TABLE entry_page_per_session_table
SELECT
	website_sessions.utm_source,
    website_sessions.utm_campaign,
	website_pageviews.website_session_id,
    
    MIN(website_pageviews.website_pageview_id) AS entry_page_id,
    MIN(website_pageviews.created_at) AS created_at,
    COUNT(DISTINCT website_pageviews.website_pageview_id) AS total_number_of_pageviews
    
FROM website_pageviews
	LEFT JOIN website_sessions
		ON website_sessions.website_session_id =  website_pageviews.website_session_id
WHERE
	website_pageviews.created_at < '2012-08-31'
    AND website_pageviews.created_at > '2012-06-01'
    AND website_sessions.utm_source = 'gsearch'
    AND website_sessions.utm_campaign = 'nonbrand'
GROUP BY
	website_pageviews.website_session_id
ORDER BY
	website_pageviews.website_session_id;

SELECT * FROM entry_page_per_session_table;

CREATE TEMPORARY TABLE entry_page_url_table
SELECT
	entry_page_per_session_table.utm_source,
    entry_page_per_session_table.utm_campaign,
	entry_page_per_session_table.website_session_id,
    entry_page_per_session_table.entry_page_id,
    entry_page_per_session_table.created_at,
    website_pageviews.pageview_url,
    entry_page_per_session_table.total_number_of_pageviews
FROM entry_page_per_session_table
	LEFT JOIN website_pageviews
		ON website_pageviews.website_pageview_id = entry_page_per_session_table.entry_page_id;

SELECT * FROM entry_page_url_table;

SELECT
	utm_source,
	utm_campaign,
	MIN(DATE(created_at)) AS week_started_at,
    
	COUNT(DISTINCT CASE WHEN pageview_url = '/home' THEN website_session_id ELSE NULL END) AS total_number_of_home_sessions,
	COUNT(DISTINCT CASE WHEN pageview_url = '/lander-1' THEN website_session_id ELSE NULL END) AS total_number_of_lander_1_sessions,
    
	ROUND(COUNT(DISTINCT CASE WHEN total_number_of_pageviews = 1 THEN website_session_id ELSE NULL END) /
		COUNT(DISTINCT website_session_id) * 100, 2) AS overall_bounce_rate
    
FROM entry_page_url_table
GROUP BY
	YEAR(created_at),
	WEEK(created_at)
ORDER BY
	YEAR(created_at),
	WEEK(created_at);

DROP TEMPORARY TABLE entry_page_per_session_table;
DROP TEMPORARY TABLE entry_page_url_table;

-- 6 Building conversion funnel

SELECT * FROM website_pageviews;

SELECT DISTINCT
	website_sessions.utm_source,
    website_sessions.utm_campaign,
	website_pageviews.pageview_url, 
    COUNT(DISTINCT website_pageviews.website_pageview_id) AS total_number_of_pageviews
FROM website_pageviews
	LEFT JOIN website_sessions
		ON website_sessions.website_session_id = website_pageviews.website_session_id
WHERE
	website_pageviews.created_at > '2012-08-05'
    AND website_pageviews.created_at < '2012-09-05'
	AND website_sessions.utm_source = 'gsearch'
    AND website_sessions.utm_campaign = 'nonbrand'
GROUP BY
	website_pageviews.pageview_url
ORDER BY
	total_number_of_pageviews DESC;

CREATE TEMPORARY TABLE entry_page_per_session_table
SELECT
	website_sessions.utm_source,
    website_sessions.utm_campaign,
	website_pageviews.website_session_id,
    
    MIN(website_pageviews.website_pageview_id) AS entry_page_id,
    MIN(website_pageviews.created_at) AS created_at
    
FROM website_pageviews
	LEFT JOIN website_sessions
		ON website_sessions.website_session_id = website_pageviews.website_session_id
WHERE
	website_pageviews.created_at > '2012-08-05'
    AND website_pageviews.created_at < '2012-09-05'
    AND website_sessions.utm_source = 'gsearch'
    AND website_sessions.utm_campaign = 'nonbrand'
    AND website_pageviews.pageview_url = '/lander-1'
GROUP BY
	website_pageviews.website_session_id
ORDER BY
	website_pageviews.website_session_id;

SELECT * FROM entry_page_per_session_table;

CREATE TEMPORARY TABLE pages_per_session_table
SELECT
	entry_page_per_session_table.utm_source,
    entry_page_per_session_table.utm_campaign,
	entry_page_per_session_table.website_session_id,
    
    CASE WHEN website_pageviews.pageview_url = '/lander-1' THEN 1 ELSE 0 END AS lander_1_page,
    CASE WHEN website_pageviews.pageview_url = '/products' THEN 1 ELSE 0 END AS products_page,
    CASE WHEN website_pageviews.pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE 0 END AS mrfuzzy_page,
    CASE WHEN website_pageviews.pageview_url = '/cart' THEN 1 ELSE 0 END AS cart_page,
    CASE WHEN website_pageviews.pageview_url = '/shipping' THEN 1 ELSE 0 END AS shipping_page,
    CASE WHEN website_pageviews.pageview_url = '/billing' THEN 1 ELSE 0 END AS billing_page,
    CASE WHEN website_pageviews.pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS thankyou_page
    
FROM entry_page_per_session_table
	LEFT JOIN website_pageviews
		On website_pageviews.website_session_id = entry_page_per_session_table.website_session_id;

SELECT * FROM pages_per_session_table;

CREATE TEMPORARY TABLE max_page_per_session_table
SELECT
	utm_source,
    utm_campaign,
	website_session_id,
    
    MAX(lander_1_page) AS entry_page,
    MAX(products_page) AS products_made_it,
    MAX(mrfuzzy_page) AS mrfuzzy_made_it,
    MAX(cart_page) AS cart_made_it, 
    MAX(shipping_page) AS shipping_made_it,
    MAX(billing_page) AS billing_made_it,
    MAX(thankyou_page) AS thankyou_made_it
    
FROM pages_per_session_table
GROUP BY
	website_session_id;
    
SELECT * FROM max_page_per_session_table;

CREATE TEMPORARY TABLE sessions_conversion_funnel
SELECT 
	utm_source,
    utm_campaign,
	
	COUNT(DISTINCT CASE WHEN entry_page = 1 THEN website_session_id ELSE NULL END) AS total_number_of_sessions,
    COUNT(DISTINCT CASE WHEN products_made_it = 1 THEN website_session_id ELSE NULL END) AS total_number_of_to_products_sessions,
    COUNT(DISTINCT CASE WHEN mrfuzzy_made_it = 1 THEN website_session_id ELSE NULL END) AS total_number_of_to_mrfuzzy_sessions,
    COUNT(DISTINCT CASE WHEN cart_made_it = 1 THEN website_session_id ELSE NULL END) AS total_number_of_to_cart_sessions,
    COUNT(DISTINCT CASE WHEN shipping_made_it = 1 THEN website_session_id ELSE NULL END) AS total_number_of_to_shipping_sessions,
    COUNT(DISTINCT CASE WHEN billing_made_it = 1 THEN website_session_id ELSE NULL END) AS total_number_of_to_billing_sessions,
    COUNT(DISTINCT CASE WHEN thankyou_made_it = 1 THEN website_session_id ELSE NULL END) AS total_number_of_to_thankyou_sessions
    
FROM max_page_per_session_table;

SELECT * FROM sessions_conversion_funnel;

SELECT
	utm_source,
    utm_campaign,

	ROUND(total_number_of_to_products_sessions / total_number_of_sessions * 100, 2) AS lander_1_click_rt,
    ROUND(total_number_of_to_mrfuzzy_sessions / total_number_of_to_products_sessions * 100, 2) AS products_click_rt,
    ROUND(total_number_of_to_cart_sessions / total_number_of_to_mrfuzzy_sessions * 100, 2) AS mrfuzzy_click_rt,
    ROUND(total_number_of_to_shipping_sessions / total_number_of_to_cart_sessions * 100, 2) AS cart_click_rt,
    ROUND(total_number_of_to_billing_sessions / total_number_of_to_shipping_sessions * 100, 2) AS shipping_click_rt,
    ROUND(total_number_of_to_thankyou_sessions / total_number_of_to_billing_sessions  * 100, 2) AS billing_click_rt
    
FROM sessions_conversion_funnel;

DROP TEMPORARY TABLE entry_page_per_session_table;
DROP TEMPORARY TABLE pages_per_session_table;
DROP TEMPORARY TABLE max_page_per_session_table;
DROP TEMPORARY TABLE sessions_conversion_funnel;

-- 7 Analyzing conversion funnel tests

SELECT
	website_sessions.utm_source,
    website_sessions.utm_campaign,
	website_pageviews.pageview_url,
    
    MIN(website_pageviews.website_pageview_id) AS first_pageview,
    MIN(website_pageviews.created_at) AS first_created_at,
    MIN(website_pageviews.website_session_id) AS first_session
    
FROM website_pageviews
	LEFT JOIN website_sessions
		ON website_sessions.website_session_id = website_pageviews.website_session_id
WHERE
	website_pageviews.pageview_url = '/billing-2'
    AND website_sessions.utm_source = 'gsearch'
    AND website_sessions.utm_campaign = 'nonbrand';

CREATE TEMPORARY TABLE billing_page_per_session_table
SELECT
	website_sessions.utm_source,
    website_sessions.utm_campaign,
	website_pageviews.website_session_id,
    website_pageviews.pageview_url AS billing_page	 
FROM website_pageviews
	LEFT JOIN website_sessions
		ON website_sessions.website_session_id = website_pageviews.website_session_id
WHERE
	website_pageviews.created_at < '2012-11-10'
    AND website_pageviews.website_session_id >= 25325
    AND website_pageviews.pageview_url IN ('/billing','/billing-2')
    AND website_sessions.utm_source = 'gsearch'
    AND website_sessions.utm_campaign = 'nonbrand'
GROUP BY
	website_pageviews.website_session_id
ORDER BY
	website_pageviews.website_session_id;

SELECT * FROM billing_page_per_session_table;

SELECT
	billing_page_per_session_table.utm_source,
    billing_page_per_session_table.utm_campaign,
	billing_page_per_session_table.billing_page,
   
	COUNT(DISTINCT orders.order_id) AS total_number_of_orders,
	COUNT(DISTINCT billing_page_per_session_table.website_session_id) AS total_number_of_sessions,
    
    ROUND(COUNT(DISTINCT orders.order_id) /
		COUNT(DISTINCT billing_page_per_session_table.website_session_id) * 100, 2) AS billing_page_conversion_rate
        
FROM billing_page_per_session_table
	LEFT JOIN orders
		ON orders.website_session_id = billing_page_per_session_table.website_session_id
GROUP BY
	billing_page_per_session_table.billing_page
ORDER BY
	billing_page_conversion_rate DESC;
	
DROP TEMPORARY TABLE billing_page_per_session_table;

-- Channel analysis and optimization
-- 1 Analyzing channel portfolios

SELECT 
	utm_source,
	MIN(website_session_id) AS first_session,
    MIN(created_at) AS first_created_at
FROM website_sessions
WHERE 
	created_at < '2012-11-29'
    AND created_at > '2012-08-22'
    AND utm_source = 'bsearch'
    AND utm_campaign = 'nonbrand';

SELECT
	-- YEAR(created_at) AS yr,
	-- WEEK(created_at) AS mth,
	MIN(DATE(created_at)) AS week_started_at,
    
	COUNT(DISTINCT website_session_id) AS total_number_of_nonbrand_sessions,
	COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' THEN website_session_id ELSE NULL END) AS total_number_of_bsearch_nonbrand_sessions,
	COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' THEN website_session_id ELSE NULL END) AS total_number_of_gsearch_nonbrand_sessions,
	ROUND(COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' THEN website_session_id ELSE NULL END) /
		COUNT(DISTINCT website_session_id) * 100, 2) AS pct_of_bsearch_nonbrand
    
FROM website_sessions
WHERE
	created_at < '2012-11-29'
	AND website_session_id >= 21130
	AND utm_campaign = 'nonbrand'
GROUP BY
	YEAR(created_at),
	WEEK(created_at);

-- 2 Comparing channel characteristics

SELECT 
	utm_source,
    utm_campaign,
	
    COUNT(DISTINCT website_session_id) AS total_number_of_sessions,
    COUNT(DISTINCT CASE WHEN device_type = 'mobile' THEN website_session_id ELSE NULL END) AS total_number_of_mobile_sessions,
    
    ROUND(COUNT(DISTINCT CASE WHEN device_type = 'mobile' THEN website_session_id ELSE NULL END) /
		COUNT(DISTINCT website_session_id) * 100, 2) AS percentage_of_mobile_sessions
	
FROM website_sessions
WHERE
	created_at < '2012-11-30'
    AND created_at >= '2012-08-22'
    AND utm_campaign = 'nonbrand'
GROUP BY
	utm_source;

-- 3 Cross channel bid optimization

SELECT
	website_sessions.device_type,
    website_sessions.utm_source,
    website_sessions.utm_campaign,
	
    COUNT(DISTINCT website_sessions.website_session_id) AS total_number_of_sessions,
    COUNT(DISTINCT orders.order_id) AS total_number_of_orders,
	
    ROUND(COUNT(DISTINCT orders.order_id) /
		COUNT(DISTINCT website_sessions.website_session_id) * 100, 2) AS conversion_rt
        
FROM website_sessions
	LEFT JOIN orders
		ON orders.website_session_id = website_sessions.website_session_id
WHERE
	website_sessions.created_at <= '2012-09-18'
    AND website_sessions.created_at >= '2012-08-22'
    AND website_sessions.utm_campaign = 'nonbrand'
GROUP BY
	website_sessions.device_type,
    website_sessions.utm_source
ORDER BY
	website_sessions.device_type,
    website_sessions.utm_source;

-- 4 Analyzing channel portfolio trends

SELECT 
		-- YEAR(created_at),
    -- WEEK(created_at),
    MIN(DATE(created_at)) AS week_started_at,   
    
    COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' AND device_type = 'desktop' THEN website_session_id ELSE NULL END) AS total_num_of_bn_desk_sess,
    COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' AND device_type = 'desktop' THEN website_session_id ELSE NULL END) AS total_num_of_gn_desk_sess,
    
    ROUND(COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' AND device_type = 'desktop' THEN website_session_id ELSE NULL END) /
			COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' AND device_type = 'desktop' THEN website_session_id ELSE NULL END) * 100, 2) AS bn_pct_of_gn_desk,
    
    COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' AND device_type = 'mobile' THEN website_session_id ELSE NULL END) AS total_num_of_bn_mob_sess,
    COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' AND device_type = 'mobile' THEN website_session_id ELSE NULL END) AS total_num_of_bn_mob_sess,
    
    ROUND(COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' AND device_type = 'mobile' THEN website_session_id ELSE NULL END) /
			COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' AND device_type = 'mobile' THEN website_session_id ELSE NULL END) * 100, 2) AS bn_pct_of_gn_mob_sess

FROM website_sessions
WHERE
	created_at > '2012-11-04'
	AND created_at < '2012-12-22'
	AND utm_campaign = 'nonbrand'
GROUP BY
	YEAR(created_at),
	WEEK(created_at)
ORDER BY
	YEAR(created_at),
	WEEK(created_at);

-- 5 Analyzing direct traffic

SELECT DISTINCT utm_source, utm_campaign, http_referer FROM  website_sessions WHERE created_at < '2012-12-23';

SELECT 
	-- YEAR(created_at),
    -- MONTH(created_at),
    MIN(DATE(created_at)) AS month_started_at,
    
    COUNT(DISTINCT CASE WHEN utm_campaign = 'nonbrand' THEN website_session_id ELSE NULL END) AS total_number_of_nonbrand_sessions,
    
    COUNT(DISTINCT CASE WHEN utm_campaign = 'brand' THEN website_session_id ELSE NULL END) AS total_number_of_brand_sessions,
	ROUND(COUNT(DISTINCT CASE WHEN utm_campaign = 'brand' THEN website_session_id ELSE NULL END) /
		COUNT(DISTINCT CASE WHEN utm_campaign = 'nonbrand' THEN website_session_id ELSE NULL END) * 100, 2) AS brand_sessions_as_a_percentage_of_nonbrand_sessions,
    
    COUNT(DISTINCT CASE WHEN http_referer IS NULL THEN website_session_id ELSE NULL END) AS total_number_of_direct_sessions,
    ROUND(COUNT(DISTINCT CASE WHEN http_referer IS NULL THEN website_session_id ELSE NULL END) /
		COUNT(DISTINCT CASE WHEN utm_campaign = 'nonbrand' THEN website_session_id ELSE NULL END) * 100, 2) AS direct_sessions_as_a_percentage_of_nonbrand_sessions,
    
    COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NOT NULL THEN website_session_id ELSE NULL END) AS total_number_of_organic_sessions,
	ROUND(COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NOT NULL THEN website_session_id ELSE NULL END) /
		COUNT(DISTINCT CASE WHEN utm_campaign = 'nonbrand' THEN website_session_id ELSE NULL END) * 100, 2) AS organic_sessions_as_a_percentage_of_nonbrand_sessions
        
FROM website_sessions
WHERE
	created_at < '2012-12-23'
GROUP BY
	YEAR(created_at),
    MONTH(created_at);

-- Product-level analysis
-- 1 Product level sales analysis

SELECT * FROM orders;

SELECT 
	MIN(DATE(created_at)) AS mth,
    COUNT(DISTINCT order_id) AS total_number_of_orders,
    SUM(price_usd) AS total_revenue,
    SUM(price_usd - cogs_usd) AS total_profit_margin
FROM orders
WHERE
	created_at < '2013-01-01'
GROUP BY
	YEAR(created_at),
    MONTH(created_at);

-- 2 Analyzing product launches

SELECT
	YEAR(website_sessions.created_at) AS yr,
	MONTH(website_sessions.created_at) AS mth,
	
    COUNT(DISTINCT website_sessions.website_session_id) AS total_number_of_sessions,
	COUNT(DISTINCT CASE WHEN primary_product_id = 1 THEN order_id ELSE NULL END ) AS total_number_of_orders_for_product_1,
    COUNT(DISTINCT CASE WHEN primary_product_id = 2 THEN order_id ELSE NULL END ) AS total_number_of_orders_for_product_2,
    
    COUNT(DISTINCT orders.order_id) AS total_number_of_orders,
    ROUND(COUNT(DISTINCT orders.order_id) /
		COUNT(DISTINCT website_sessions.website_session_id) * 100, 2) AS conversion_rate,
	
    SUM(orders.price_usd) AS total_revenue,
    ROUND(SUM(orders.price_usd) / 
		COUNT(DISTINCT website_sessions.website_session_id), 2) AS revenue_per_session
	
FROM website_sessions
	LEFT JOIN orders
		ON orders.website_session_id = website_sessions.website_session_id
WHERE
	website_sessions.created_at < '2013-04-05'
    AND website_sessions.created_at > '2012-04-01'
GROUP BY
	yr,
    mth;

-- 3 Product level website pathing

SELECT * FROM products;

CREATE TEMPORARY TABLE products_page_per_session_table
SELECT DISTINCT
	website_session_id,
    created_at,
    CASE
		WHEN created_at < '2013-01-07' THEN 'pre_new_product_launch'
        ELSE 'new_product_launch' END
	AS launch_period,
    website_pageview_id AS products_page_id,
    pageview_url AS products_page
FROM website_pageviews
WHERE
	created_at >'2012-10-06'
    AND created_at < '2013-04-06'
    AND pageview_url = '/products';

SELECT * FROM products_page_per_session_table;

CREATE TEMPORARY TABLE next_page_per_session_table
SELECT
	products_page_per_session_table.website_session_id,
    products_page_per_session_table.created_at,
    products_page_per_session_table.launch_period,
    products_page_per_session_table.products_page_id,
    products_page_per_session_table.products_page,
    MIN(website_pageviews.website_pageview_id) AS next_page_id
FROM products_page_per_session_table
	LEFT JOIN website_pageviews
		ON website_pageviews.website_session_id = products_page_per_session_table.website_session_id
        AND website_pageviews.website_pageview_id > products_page_per_session_table.products_page_id
GROUP BY
	website_session_id;

SELECT * FROM next_page_per_session_table;

CREATE TEMPORARY TABLE next_page_url_per_session_table
SELECT
	next_page_per_session_table.website_session_id,
    next_page_per_session_table.created_at,
    next_page_per_session_table.launch_period,
    next_page_per_session_table.products_page_id,
    next_page_per_session_table.products_page,
    next_page_per_session_table.next_page_id,
    website_pageviews.pageview_url AS next_page_url
FROM next_page_per_session_table
	LEFT JOIN website_pageviews
		ON website_pageviews.website_pageview_id = next_page_per_session_table.next_page_id
ORDER BY
	website_session_id;

SELECT * FROM next_page_url_per_session_table;

SELECT
	launch_period,
    
	COUNT(DISTINCT website_session_id) AS total_num_of_prod_sess,
	
	ROUND(COUNT(DISTINCT CASE WHEN next_page_url IS NOT NULL THEN website_session_id ELSE NULL END) /
		COUNT(DISTINCT website_session_id) * 100, 2) AS pct_with_next_pg,
        
	COUNT(DISTINCT CASE WHEN next_page_url = '/the-original-mr-fuzzy' THEN website_session_id ELSE NULL END) AS total_num_of_to_mrfuzz_sess,
	    
	ROUND(COUNT(DISTINCT CASE WHEN next_page_url = '/the-original-mr-fuzzy' THEN website_session_id ELSE NULL END) /
		COUNT(DISTINCT website_session_id) * 100, 2) AS pct_to_mrfuzz,
    
	COUNT(DISTINCT CASE WHEN next_page_url = '/the-forever-love-bear' THEN website_session_id ELSE NULL END) AS total_num_of_to_love_sess,
    
	ROUND(COUNT(DISTINCT CASE WHEN next_page_url = '/the-forever-love-bear' THEN website_session_id ELSE NULL END) /
		COUNT(DISTINCT website_session_id) * 100, 2) AS pct_to_love
    
FROM next_page_url_per_session_table
GROUP BY
	launch_period;

DROP TEMPORARY TABLE products_page_per_session_table;
DROP TEMPORARY TABLE next_page_per_session_table;
DROP TEMPORARY TABLE next_page_url_per_session_table;

-- 4 Building product level conversion funnels

SELECT 
	pageview_url,
    COUNT(DISTINCT website_session_id) AS total_number_of_sessions
FROM website_pageviews
WHERE
	created_at >= '2013-01-07'
    AND created_at < '2013-04-10'
GROUP BY
	pageview_url
ORDER BY
	total_number_of_sessions DESC;

CREATE TEMPORARY TABLE product_per_session_table
SELECT
	website_session_id,
    created_at,
    website_pageview_id AS product_page_id,
    pageview_url AS product_url
FROM website_pageviews
WHERE
	created_at >= '2013-01-07'
    AND created_at < '2013-04-10'
	AND pageview_url IN ('/the-original-mr-fuzzy', '/the-forever-love-bear')
ORDER BY
	website_session_id;

SELECT * FROM product_per_session_table;

CREATE TEMPORARY TABLE pages_per_session_table
SELECT
	product_per_session_table.website_session_id,
	product_per_session_table.created_at,
    product_per_session_table.product_url,
    CASE WHEN website_pageviews.pageview_url = '/cart' THEN 1 ELSE 0 END AS cart_page,
    CASE WHEN website_pageviews.pageview_url = '/shipping' THEN 1 ELSE 0 END AS shipping_page,
    CASE WHEN website_pageviews.pageview_url = '/billing-2' THEN 1 ELSE 0 END AS billing_page,
    CASE WHEN website_pageviews.pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS thankyou_page
FROM product_per_session_table
	LEFT JOIN website_pageviews
		ON website_pageviews.website_session_id = product_per_session_table.website_session_id
        AND website_pageviews.website_pageview_id > product_per_session_table.product_page_id
ORDER BY
	website_session_id;

SELECT * FROM pages_per_session_table;

CREATE TEMPORARY TABLE max_page_per_session_table
SELECT
	website_session_id,
    created_at,
    product_url,
    MAX(cart_page) AS cart_made_it,
    MAX(shipping_page) AS shipping_made_it,
    MAX(billing_page) AS billing_made_it,
    MAX(thankyou_page) AS thankyou_made_it
FROM pages_per_session_table
GROUP BY
	website_session_id;
    
SELECT * FROM max_page_per_session_table;

CREATE TEMPORARY TABLE sessions_conversion_funnel
SELECT
	product_url,
	COUNT(DISTINCT website_session_id) AS total_number_of_to_product_sessions,
    COUNT(DISTINCT CASE WHEN cart_page = 1 THEN website_session_id ELSE NULL END) AS total_number_of_to_cart_sessions,
    COUNT(DISTINCT CASE WHEN shipping_page = 1 THEN website_session_id ELSE NULL END) AS total_number_of_to_shipping_sessions,
    COUNT(DISTINCT CASE WHEN billing_page = 1 THEN website_session_id ELSE NULL END) AS total_number_of_to_billing_sessions,
    COUNT(DISTINCT CASE WHEN thankyou_page = 1 THEN website_session_id ELSE NULL END) AS total_number_of_to_thankyou_sessions
FROM pages_per_session_table
GROUP BY
	product_url;

SELECT * FROM sessions_conversion_funnel;

SELECT
	product_url,
    
    ROUND(total_number_of_to_cart_sessions/
		total_number_of_to_product_sessions * 100, 2) AS product_click_rate,
        
	ROUND(total_number_of_to_shipping_sessions /
		total_number_of_to_cart_sessions * 100, 2) AS cart_click_rate,
	
    ROUND(total_number_of_to_billing_sessions /
		total_number_of_to_shipping_sessions * 100, 2) AS shipping_click_rate,
	
    ROUND(total_number_of_to_thankyou_sessions /
		total_number_of_to_billing_sessions * 100, 2) AS billing_click_rate
        
FROM sessions_conversion_funnel
GROUP BY
	product_url;

DROP TEMPORARY TABLE product_per_session_table;
DROP TEMPORARY TABLE pages_per_session_table;
DROP TEMPORARY TABLE max_page_per_session_table;
DROP TEMPORARY TABLE sessions_conversion_funnel;

-- 5 Cross sell analysis

SELECT *
FROM website_pageviews;

CREATE TEMPORARY TABLE cart_page_per_session_table
SELECT
	website_session_id,
    created_at,
    CASE 
		WHEN created_at >= '2013-09-25' THEN 'second_option_launch'  
		ELSE 'pre_second_option_launch' 
	END AS launch_period,
    website_pageview_id AS cart_page_id,
    pageview_url AS cart_page
FROM website_pageviews
WHERE
	created_at < '2013-10-25'
    AND created_at > '2013-08-25'
    AND pageview_url = '/cart'
ORDER BY
	website_session_id;
    
SELECT * FROM cart_page_per_session_table;

CREATE TEMPORARY TABLE next_page_per_session_table
SELECT
	cart_page_per_session_table.website_session_id,
    cart_page_per_session_table.created_at,
    cart_page_per_session_table.launch_period,
    cart_page_per_session_table.cart_page_id,
    cart_page_per_session_table.cart_page,
    MIN(website_pageviews.website_pageview_id) AS next_page_id
FROM cart_page_per_session_table
	LEFT JOIN website_pageviews
		ON website_pageviews.website_session_id = cart_page_per_session_table.website_session_id
		AND website_pageviews.website_pageview_id > cart_page_per_session_table.cart_page_id
GROUP BY
	cart_page_per_session_table.website_session_id;

SELECT * FROM next_page_per_session_table;

SELECT * FROM orders;
SELECT * FROM order_items;

SELECT
	next_page_per_session_table.launch_period,
    
    COUNT(DISTINCT next_page_per_session_table.website_session_id) AS total_number_of_cart_sessions,
    COUNT(DISTINCT next_page_per_session_table.next_page_id) AS total_number_of_next_page_sessions,
    
    ROUND(COUNT(DISTINCT next_page_per_session_table.next_page_id) /
		COUNT(DISTINCT next_page_per_session_table.website_session_id) * 100, 2) AS cart_click_rate,
	
	ROUND(SUM(orders.items_purchased) / 
		COUNT(DISTINCT orders.order_id), 3) AS avg_number_of_products_per_order,
    
    ROUND(SUM(orders.price_usd) / 
		COUNT(DISTINCT orders.order_id), 2) AS revenue_per_order,
    
	SUM(orders.price_usd) AS total_revenue,
    ROUND(SUM(orders.price_usd) /
		COUNT(DISTINCT next_page_per_session_table.website_session_id), 2) AS revenue_per_cart_page
    
FROM next_page_per_session_table
	LEFT JOIN website_sessions
		ON website_sessions.website_session_id = next_page_per_session_table.website_session_id
	LEFT JOIN orders
		ON orders.website_session_id = website_sessions.website_session_id
GROUP BY
	next_page_per_session_table.launch_period;
        
DROP TEMPORARY TABLE cart_page_per_session_table;
DROP TEMPORARY TABLE next_page_per_session_table;

-- 6 Product porfolio expansion

CREATE TEMPORARY TABLE launch_period_per_session_table
SELECT 
	website_session_id,
    created_at,
    CASE
		WHEN created_at < '2013-12-12' THEN 'pre_third_product_launch'
		ELSE 'third_product_launch'
	END AS launch_period
FROM website_sessions
WHERE
	created_at < '2014-01-12'
    AND created_at > '2013-11-12';

SELECT * FROM launch_period_per_session_table;

SELECT * FROM orders;

SELECT
	launch_period_per_session_table.launch_period,
    
    COUNT(DISTINCT launch_period_per_session_table.website_session_id) AS total_number_of_sessions,
    COUNT(DISTINCT orders.order_id) AS total_number_of_orders,
    
    ROUND(COUNT(DISTINCT orders.order_id) /
		COUNT(DISTINCT launch_period_per_session_table.website_session_id) * 100, 2) AS conversion_rate,
	
    ROUND(SUM(orders.price_usd) /
		COUNT(DISTINCT orders.order_id), 2) AS revenue_per_order,
    
    SUM(orders.items_purchased) /
		COUNT(DISTINCT orders.order_id) AS avg_number_of_products_per_order,
    
    ROUND(SUM(orders.price_usd) / 
		COUNT(DISTINCT launch_period_per_session_table.website_session_id), 2) AS revenue_per_session
        
FROM launch_period_per_session_table
	LEFT JOIN orders
		ON orders.website_session_id = launch_period_per_session_table.website_session_id
GROUP BY
	launch_period_per_session_table.launch_period;

DROP TEMPORARY TABLE launch_period_per_session_table;

-- 7 Analyzing product refund rates

SELECT * FROM products;

SELECT
	-- YEAR(order_items.created_at) AS yr,
	-- MONTH(order_items.created_at) AS mth,
	MIN(DATE(order_items.created_at)) AS mth_started_at,
    
	ROUND(COUNT(DISTINCT CASE WHEN order_items.product_id = 1 THEN order_item_refunds.order_item_refund_id ELSE NULL END) /
		COUNT(DISTINCT CASE WHEN order_items.product_id = 1 THEN order_items.order_item_id ELSE NULL END) * 100, 2) AS prod_1_refund_rt,
    
	ROUND(COUNT(DISTINCT CASE WHEN order_items.product_id = 2 THEN order_item_refunds.order_item_refund_id ELSE NULL END) /
		COUNT(DISTINCT CASE WHEN order_items.product_id = 2 THEN order_items.order_item_id ELSE NULL END) * 100, 2) AS prod_2_refund_rt,
        
    
	ROUND(COUNT(DISTINCT CASE WHEN order_items.product_id = 3 THEN order_item_refunds.order_item_refund_id ELSE NULL END) /
		COUNT(DISTINCT CASE WHEN order_items.product_id = 3 THEN order_items.order_item_id ELSE NULL END) * 100, 2) AS prod_3_refund_rt,
    
	ROUND(COUNT(DISTINCT CASE WHEN order_items.product_id = 4 THEN order_item_refunds.order_item_refund_id ELSE NULL END) /
		COUNT(DISTINCT CASE WHEN order_items.product_id = 4 THEN order_items.order_item_id ELSE NULL END) * 100, 2) AS prod_4_refund_rt
    
FROM order_items
	LEFT JOIN order_item_refunds 
		ON order_item_refunds.order_item_id = order_items.order_item_id
WHERE
	order_items.created_at < '2014-10-15'
GROUP BY
	YEAR(order_items.created_at),
	MONTH(order_items.created_at);

-- User-level analysis
-- 1 Identifying repeat visitors
  
SELECT * FROM website_sessions;

CREATE TEMPORARY TABLE first_visit_per_user_table
SELECT 
    user_id,
    website_session_id AS first_visit_id
FROM website_sessions
WHERE
	created_at < '2014-11-01'
    AND created_at >= '2014-01-01'
    AND is_repeat_session = 0;
    
SELECT * FROM first_visit_per_user_table;

CREATE TEMPORARY TABLE repeat_visits_per_user_table
SELECT
	first_visit_per_user_table.user_id,
    COUNT(website_sessions.user_id) AS total_number_of_repeat_visits
FROM first_visit_per_user_table
	LEFT JOIN website_sessions
		ON website_sessions.user_id = first_visit_per_user_table.user_id
        AND website_sessions.created_at < '2014-11-01'
        AND website_sessions.created_at >= '2014-01-01'
        AND website_sessions.website_session_id > first_visit_per_user_table.first_visit_id
        AND website_sessions.is_repeat_session = 1
GROUP BY
	first_visit_per_user_table.user_id
ORDER BY
	first_visit_per_user_table.user_id;

SELECT * FROM repeat_visits_per_user_table;

SELECT
	total_number_of_repeat_visits,
    COUNT(DISTINCT user_id) AS total_number_of_users
FROM repeat_visits_per_user_table
GROUP BY
	total_number_of_repeat_visits;

DROP TEMPORARY TABLE first_visit_per_user_table;
DROP TEMPORARY TABLE repeat_visits_per_user_table;

-- 2 Analyzing time to repeat

SELECT * FROM website_sessions;

CREATE TEMPORARY TABLE first_visit_per_user_table
SELECT
	user_id,
    created_at AS first_created_at,
    website_session_id AS first_visit_id
FROM website_sessions
WHERE
	created_at >= '2014-01-01'
    AND created_at < '2014-11-03'
    AND is_repeat_session = 0;

SELECT * FROM first_visit_per_user_table;

CREATE TEMPORARY TABLE first_repeat_per_user_table
SELECT
	first_visit_per_user_table.user_id,
    first_visit_per_user_table.first_created_at,
    first_visit_per_user_table.first_visit_id,
    MIN(website_sessions.created_at) AS first_repeat_created_at,
    MIN(website_sessions.website_session_id) AS first_repeat_id
FROM first_visit_per_user_table
	LEFT JOIN website_sessions
		ON website_sessions.user_id = first_visit_per_user_table.user_id
        AND website_sessions.created_at < '2014-11-03'
        AND website_sessions.created_at >= '2014-01-01'
        AND website_sessions.website_session_id > first_visit_per_user_table.first_visit_id
GROUP BY
	user_id;

SELECT * FROM first_repeat_per_user_table;

CREATE TEMPORARY TABLE days_first_visit_to_first_repeat_per_user_table
SELECT
	user_id,
    DATEDIFF(first_repeat_created_at, first_created_at) AS days_first_visit_to_first_repeat
FROM first_repeat_per_user_table;

SELECT * FROM days_first_visit_to_first_repeat_per_user_table;

SELECT 
	MIN(days_first_visit_to_first_repeat) AS minimum_time_first_visit_to_first_repeat,
    MAX(days_first_visit_to_first_repeat) AS maximum_time_first_visit_to_first_repeat,
    ROUND(AVG(days_first_visit_to_first_repeat), 2) AS average_time_first_visit_to_first_repeat
FROM days_first_visit_to_first_repeat_per_user_table;

DROP TEMPORARY TABLE first_visit_per_user_table;
DROP TEMPORARY TABLE first_repeat_per_user_table;
DROP TEMPORARY TABLE days_first_visit_to_first_repeat_per_user_table;

-- 3 Analyzing repeat channel behavior

SELECT DISTINCT utm_source, utm_campaign, http_referer FROM website_sessions
WHERE
	created_at < '2014-11-05'
    AND created_at >= '2014-01-01';

CREATE TEMPORARY TABLE first_visit_per_user_table
SELECT
    user_id,
    website_session_id AS first_visit_id
FROM website_sessions
WHERE
	created_at < '2014-11-05'
    AND created_at >= '2014-01-01'
    AND is_repeat_session = 0;

SELECT * FROM first_visit_per_user_table;

CREATE TEMPORARY TABLE traffic_per_user_table
SELECT
	website_sessions.user_id,
    website_sessions.is_repeat_session,
    website_sessions.utm_source,
    website_sessions.utm_campaign,
    website_sessions.http_referer
FROM first_visit_per_user_table
	LEFT JOIN website_sessions
		ON website_sessions.user_id = first_visit_per_user_table.user_id
        -- AND website_sessions.website_session_id > first_visit_per_user_table.first_visit_id
        AND website_sessions.created_at < '2014-11-05'
        AND website_sessions.created_at >= '2014-01-01'
ORDER BY
	website_sessions.user_id;

SELECT * FROM traffic_per_user_table;

SELECT
	CASE
		WHEN utm_source IS NULL AND http_referer IS NOT NULL THEN 'organic_search'
        WHEN utm_source IS NULL AND http_referer IS NULL THEN 'direct_type_in'
        WHEN utm_source = 'socialbook' THEN 'paid_socialbook'
        WHEN utm_campaign = 'brand' THEN 'paid_brand'
        WHEN utm_campaign = 'nonbrand' THEN 'paid_nonbrand'
		ELSE 'check_logic'
	END AS channel_group,
    COUNT(DISTINCT CASE WHEN is_repeat_session = 0 THEN user_id ELSE NULL END) AS total_number_of_first_visit_sessions,
    COUNT(DISTINCT CASE WHEN is_repeat_session = 1 THEN user_id ELSE NULL END) AS total_number_of_repeat_sessions
FROM traffic_per_user_table
GROUP BY
	channel_group;

DROP TEMPORARY TABLE first_visit_per_user_table;
DROP TEMPORARY TABLE traffic_per_user_table;

-- 4 Analyzing new and repeat conversion rate

SELECT * FROM website_sessions;

CREATE TEMPORARY TABLE first_visit_per_user_table
SELECT 
	user_id,
    created_at AS first_created_at,
    website_session_id AS first_visit_id
FROM website_sessions
WHERE
	created_at < '2014-11-08'
    AND created_at >= '2014-01-01'
    AND is_repeat_session = 0;

SELECT * FROM first_visit_per_user_table;

CREATE TEMPORARY TABLE first_and_repeat_session_per_user_table
SELECT
	website_sessions.user_id,
    website_sessions.website_session_id,
    website_sessions.created_at,
    website_sessions.is_repeat_session    
FROM first_visit_per_user_table
	LEFT JOIN website_sessions
		ON website_sessions.user_id = first_visit_per_user_table.user_id
        AND website_sessions.created_at < '2014-11-08'
        AND website_sessions.created_at >= '2014-01-01'
ORDER BY
	website_sessions.user_id;

SELECT * FROM first_and_repeat_session_per_user_table;

SELECT * FROM orders;

SELECT	
	is_repeat_session,
    COUNT(DISTINCT first_and_repeat_session_per_user_table.website_session_id) AS total_number_of_sessions,
    
    COUNT(DISTINCT orders.order_id) AS total_number_of_orders,
    ROUND(COUNT(DISTINCT orders.order_id) /
		COUNT(DISTINCT first_and_repeat_session_per_user_table.website_session_id) * 100, 2) AS conversion_rates,
	
    SUM(orders.price_usd) AS total_revenue,
    ROUND(SUM(orders.price_usd) /
		COUNT(DISTINCT first_and_repeat_session_per_user_table.website_session_id), 2) AS revenue_per_session
        
FROM first_and_repeat_session_per_user_table
	LEFT JOIN orders
		ON orders.website_session_id = first_and_repeat_session_per_user_table.website_session_id
GROUP BY 
	first_and_repeat_session_per_user_table.is_repeat_session;

DROP TEMPORARY TABLE first_visit_per_user_table;
DROP TEMPORARY TABLE first_and_repeat_session_per_user_table;