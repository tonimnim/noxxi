-- Create popular_events materialized view
CREATE MATERIALIZED VIEW IF NOT EXISTS public.popular_events AS
WITH event_metrics AS (
    SELECT 
        e.id,
        e.title,
        e.slug,
        e.event_date,
        e.venue_name,
        e.city,
        e.cover_image_url,
        e.min_ticket_price,
        e.max_ticket_price,
        e.total_capacity,
        e.tickets_sold,
        e.view_count,
        e.category_id,
        ec.name as category_name,
        ec.slug as category_slug,
        o.business_name as organizer_name,
        -- Calculate popularity score
        (
            (e.tickets_sold::FLOAT / NULLIF(e.total_capacity, 0) * 100) * 0.4 + -- 40% weight on sell-through rate
            (LEAST(e.view_count, 10000)::FLOAT / 100) * 0.3 + -- 30% weight on views (capped at 10k)
            (CASE 
                WHEN e.event_date >= CURRENT_DATE THEN 30 -- 30% weight for upcoming events
                WHEN e.event_date >= CURRENT_DATE - INTERVAL '7 days' THEN 20 -- Recent past events
                ELSE 0 
            END)
        ) as popularity_score,
        -- Trends
        CASE 
            WHEN e.created_at > NOW() - INTERVAL '7 days' THEN 'new'
            WHEN e.tickets_sold > (e.total_capacity * 0.8) THEN 'selling_fast'
            WHEN e.event_date <= NOW() + INTERVAL '3 days' THEN 'happening_soon'
            ELSE 'normal'
        END as trend_tag
    FROM public.events e
    JOIN public.event_categories ec ON ec.id = e.category_id
    JOIN public.organizers o ON o.id = e.organizer_id
    WHERE e.status = 'published'
    AND e.event_date >= CURRENT_DATE - INTERVAL '1 day' -- Include events from yesterday
)
SELECT 
    id,
    title,
    slug,
    event_date,
    venue_name,
    city,
    cover_image_url,
    min_ticket_price,
    max_ticket_price,
    total_capacity,
    tickets_sold,
    view_count,
    category_id,
    category_name,
    category_slug,
    organizer_name,
    popularity_score,
    trend_tag,
    RANK() OVER (ORDER BY popularity_score DESC) as overall_rank,
    RANK() OVER (PARTITION BY category_id ORDER BY popularity_score DESC) as category_rank
FROM event_metrics
WHERE popularity_score > 0
ORDER BY popularity_score DESC
LIMIT 100;

-- Create indexes on materialized view
CREATE UNIQUE INDEX idx_popular_events_id ON public.popular_events(id);
CREATE INDEX idx_popular_events_category ON public.popular_events(category_id);
CREATE INDEX idx_popular_events_city ON public.popular_events(city);
CREATE INDEX idx_popular_events_event_date ON public.popular_events(event_date);
CREATE INDEX idx_popular_events_trend ON public.popular_events(trend_tag);

-- Create view for organizer dashboard
CREATE OR REPLACE VIEW public.organizer_dashboard AS
WITH upcoming_events AS (
    SELECT 
        o.id as organizer_id,
        COUNT(*) as upcoming_count,
        MIN(e.event_date) as next_event_date,
        SUM(e.total_capacity - e.tickets_sold) as available_tickets
    FROM public.organizers o
    JOIN public.events e ON e.organizer_id = o.id
    WHERE e.status = 'published'
    AND e.event_date >= CURRENT_DATE
    GROUP BY o.id
),
recent_sales AS (
    SELECT 
        o.id as organizer_id,
        COUNT(DISTINCT ord.id) as orders_today,
        SUM(ord.ticket_count) as tickets_sold_today,
        SUM(ord.total_amount) as revenue_today
    FROM public.organizers o
    JOIN public.events e ON e.organizer_id = o.id
    JOIN public.orders ord ON ord.event_id = e.id
    WHERE DATE(ord.created_at) = CURRENT_DATE
    AND ord.status = 'paid'
    GROUP BY o.id
),
pending_payouts AS (
    SELECT 
        organizer_id,
        SUM(amount) as pending_amount,
        COUNT(*) as pending_count
    FROM public.payouts
    WHERE status IN ('pending', 'processing')
    GROUP BY organizer_id
)
SELECT 
    o.id,
    o.user_id,
    o.business_name,
    o.verification_status,
    o.total_events,
    o.total_tickets_sold,
    o.total_revenue,
    o.rating,
    COALESCE(ue.upcoming_count, 0) as upcoming_events,
    ue.next_event_date,
    COALESCE(ue.available_tickets, 0) as total_available_tickets,
    COALESCE(rs.orders_today, 0) as orders_today,
    COALESCE(rs.tickets_sold_today, 0) as tickets_sold_today,
    COALESCE(rs.revenue_today, 0) as revenue_today,
    COALESCE(pp.pending_amount, 0) as pending_payout_amount,
    COALESCE(pp.pending_count, 0) as pending_payout_count
FROM public.organizers o
LEFT JOIN upcoming_events ue ON ue.organizer_id = o.id
LEFT JOIN recent_sales rs ON rs.organizer_id = o.id
LEFT JOIN pending_payouts pp ON pp.organizer_id = o.id;

-- Create view for user ticket summary
CREATE OR REPLACE VIEW public.user_ticket_summary AS
WITH upcoming_tickets AS (
    SELECT 
        t.user_id,
        COUNT(*) as upcoming_count,
        MIN(e.event_date) as next_event_date,
        jsonb_agg(jsonb_build_object(
            'ticket_id', t.id,
            'event_title', e.title,
            'event_date', e.event_date,
            'venue', e.venue_name
        ) ORDER BY e.event_date) as upcoming_events
    FROM public.tickets t
    JOIN public.events e ON e.id = t.event_id
    WHERE t.status = 'valid'
    AND e.event_date >= CURRENT_TIMESTAMP
    GROUP BY t.user_id
),
past_tickets AS (
    SELECT 
        t.user_id,
        COUNT(*) as past_count,
        COUNT(DISTINCT e.category_id) as categories_attended
    FROM public.tickets t
    JOIN public.events e ON e.id = t.event_id
    WHERE t.status = 'used'
    AND e.event_date < CURRENT_TIMESTAMP
    GROUP BY t.user_id
)
SELECT 
    p.id as user_id,
    p.email,
    p.phone_number,
    COALESCE(ut.upcoming_count, 0) as upcoming_tickets,
    ut.next_event_date,
    ut.upcoming_events,
    COALESCE(pt.past_count, 0) as past_tickets,
    COALESCE(pt.categories_attended, 0) as categories_attended,
    p.created_at as member_since
FROM public.profiles p
LEFT JOIN upcoming_tickets ut ON ut.user_id = p.id
LEFT JOIN past_tickets pt ON pt.user_id = p.id
WHERE p.role = 'user';

-- Create view for event availability
CREATE OR REPLACE VIEW public.event_availability AS
SELECT 
    e.id,
    e.title,
    e.slug,
    e.event_date,
    e.total_capacity,
    e.tickets_sold,
    (e.total_capacity - e.tickets_sold) as available_tickets,
    ROUND((e.tickets_sold::DECIMAL / NULLIF(e.total_capacity, 0)) * 100, 2) as sold_percentage,
    CASE 
        WHEN e.tickets_sold >= e.total_capacity THEN 'sold_out'
        WHEN e.tickets_sold >= (e.total_capacity * 0.9) THEN 'almost_sold_out'
        WHEN e.tickets_sold >= (e.total_capacity * 0.7) THEN 'selling_fast'
        ELSE 'available'
    END as availability_status,
    e.ticket_types,
    e.min_ticket_price,
    e.max_ticket_price,
    EXISTS (
        SELECT 1 FROM public.event_waitlist w 
        WHERE w.event_id = e.id AND w.converted = false
    ) as has_waitlist,
    (
        SELECT COUNT(*) FROM public.event_waitlist w 
        WHERE w.event_id = e.id AND w.converted = false
    ) as waitlist_count
FROM public.events e
WHERE e.status = 'published'
AND e.event_date >= CURRENT_DATE;

-- Create view for daily platform metrics
CREATE OR REPLACE VIEW public.platform_daily_metrics AS
WITH daily_orders AS (
    SELECT 
        DATE(created_at) as date,
        COUNT(*) as total_orders,
        SUM(ticket_count) as total_tickets,
        SUM(total_amount) as gross_revenue,
        SUM(service_fee) as total_fees,
        COUNT(DISTINCT user_id) as unique_buyers,
        COUNT(DISTINCT event_id) as events_sold
    FROM public.orders
    WHERE status = 'paid'
    AND created_at >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY DATE(created_at)
),
daily_events AS (
    SELECT 
        DATE(created_at) as date,
        COUNT(*) as events_created,
        COUNT(DISTINCT organizer_id) as active_organizers
    FROM public.events
    WHERE created_at >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY DATE(created_at)
),
daily_users AS (
    SELECT 
        DATE(created_at) as date,
        COUNT(*) as new_users,
        COUNT(*) FILTER (WHERE role = 'organizer') as new_organizers
    FROM public.profiles
    WHERE created_at >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY DATE(created_at)
)
SELECT 
    COALESCE(ord.date, evt.date, usr.date) as date,
    COALESCE(ord.total_orders, 0) as total_orders,
    COALESCE(ord.total_tickets, 0) as total_tickets,
    COALESCE(ord.gross_revenue, 0) as gross_revenue,
    COALESCE(ord.total_fees, 0) as platform_revenue,
    COALESCE(ord.unique_buyers, 0) as unique_buyers,
    COALESCE(ord.events_sold, 0) as events_with_sales,
    COALESCE(evt.events_created, 0) as events_created,
    COALESCE(evt.active_organizers, 0) as active_organizers,
    COALESCE(usr.new_users, 0) as new_users,
    COALESCE(usr.new_organizers, 0) as new_organizers
FROM daily_orders ord
FULL OUTER JOIN daily_events evt ON evt.date = ord.date
FULL OUTER JOIN daily_users usr ON usr.date = ord.date
ORDER BY date DESC;

-- Function to refresh popular events
CREATE OR REPLACE FUNCTION public.refresh_popular_events()
RETURNS void AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY public.popular_events;
END;
$$ LANGUAGE plpgsql;

-- Function to get personalized event recommendations
CREATE OR REPLACE FUNCTION public.get_event_recommendations(
    p_user_id UUID,
    p_limit INTEGER DEFAULT 10
)
RETURNS TABLE (
    event_id UUID,
    title VARCHAR(255),
    event_date TIMESTAMPTZ,
    venue_name VARCHAR(255),
    min_ticket_price DECIMAL,
    category_name VARCHAR(100),
    recommendation_reason TEXT,
    score FLOAT
) AS $$
BEGIN
    RETURN QUERY
    WITH user_preferences AS (
        -- Get user's preferred categories based on past purchases
        SELECT 
            ec.id as category_id,
            COUNT(*) as purchase_count
        FROM public.tickets t
        JOIN public.events e ON e.id = t.event_id
        JOIN public.event_categories ec ON ec.id = e.category_id
        WHERE t.user_id = p_user_id
        GROUP BY ec.id
    ),
    user_cities AS (
        -- Get cities where user has attended events
        SELECT DISTINCT e.city
        FROM public.tickets t
        JOIN public.events e ON e.id = t.event_id
        WHERE t.user_id = p_user_id
    )
    SELECT 
        e.id as event_id,
        e.title,
        e.event_date,
        e.venue_name,
        e.min_ticket_price,
        ec.name as category_name,
        CASE 
            WHEN up.category_id IS NOT NULL THEN 'Based on your past events'
            WHEN uc.city IS NOT NULL THEN 'In your preferred location'
            WHEN pe.trend_tag = 'selling_fast' THEN 'Selling fast - book soon!'
            ELSE 'Popular in your area'
        END as recommendation_reason,
        (
            COALESCE(up.purchase_count * 10, 0) + -- Category preference weight
            CASE WHEN uc.city IS NOT NULL THEN 5 ELSE 0 END + -- Location weight
            COALESCE(pe.popularity_score, 0) -- General popularity
        ) as score
    FROM public.events e
    JOIN public.event_categories ec ON ec.id = e.category_id
    LEFT JOIN user_preferences up ON up.category_id = e.category_id
    LEFT JOIN user_cities uc ON uc.city = e.city
    LEFT JOIN public.popular_events pe ON pe.id = e.id
    WHERE e.status = 'published'
    AND e.event_date >= CURRENT_TIMESTAMP
    AND e.tickets_sold < e.total_capacity
    AND NOT EXISTS (
        -- Exclude events user already has tickets for
        SELECT 1 FROM public.tickets t 
        WHERE t.event_id = e.id AND t.user_id = p_user_id
    )
    ORDER BY score DESC, e.event_date
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- Create cron job command for refreshing materialized views (to be set up in Supabase dashboard)
-- SELECT cron.schedule('refresh-popular-events', '0 * * * *', 'SELECT public.refresh_popular_events();');