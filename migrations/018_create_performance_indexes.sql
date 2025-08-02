-- Performance Indexes Summary and Additional Indexes
-- This file ensures all critical indexes are in place for optimal performance

-- ====================================
-- ENABLE REQUIRED EXTENSIONS FIRST
-- ====================================

-- Enable trigram extension for text search
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Enable btree_gin for composite indexes
CREATE EXTENSION IF NOT EXISTS btree_gin;

-- ====================================
-- EXISTING INDEXES (Already Created)
-- ====================================

-- tickets table (from migration 006)
-- idx_tickets_ticket_code - for fast QR scanning ✓
-- idx_tickets_event_id - for event queries ✓
-- idx_tickets_status - for filtering ✓

-- events table (from migration 004)
-- idx_events_event_date - for date queries ✓
-- idx_events_status - for filtering ✓

-- profiles table (from migration 001)
-- idx_profiles_phone_number - for auth lookup ✓

-- orders table (from migration 005)
-- idx_orders_user_id - for user queries ✓
-- idx_orders_created_at - for time queries ✓

-- ====================================
-- ADDITIONAL COMPOSITE INDEXES
-- ====================================

-- Composite index for ticket availability checks
CREATE INDEX IF NOT EXISTS idx_tickets_event_status_composite 
ON public.tickets(event_id, status) 
WHERE status = 'valid';

-- Composite index for event listings
CREATE INDEX IF NOT EXISTS idx_events_date_status_composite 
ON public.events(event_date, status) 
WHERE status = 'published';

-- Composite index for user order history
CREATE INDEX IF NOT EXISTS idx_orders_user_created_composite 
ON public.orders(user_id, created_at DESC) 
WHERE status = 'paid';

-- ====================================
-- ADDITIONAL PERFORMANCE INDEXES
-- ====================================

-- Fast event search by title
CREATE INDEX IF NOT EXISTS idx_events_title_trgm 
ON public.events USING gin(title gin_trgm_ops);

-- Fast venue search
CREATE INDEX IF NOT EXISTS idx_events_venue_trgm 
ON public.events USING gin(venue_name gin_trgm_ops);

-- Organizer events lookup
CREATE INDEX IF NOT EXISTS idx_events_organizer_status 
ON public.events(organizer_id, status, event_date DESC);

-- Ticket validation optimization
CREATE INDEX IF NOT EXISTS idx_tickets_code_status 
ON public.tickets(ticket_code, status) 
WHERE status IN ('valid', 'used');

-- Order payment optimization
CREATE INDEX IF NOT EXISTS idx_orders_payment_status 
ON public.orders(payment_method, status, created_at DESC) 
WHERE status IN ('paid', 'refunded');

-- Transaction financial reports
CREATE INDEX IF NOT EXISTS idx_transactions_date_type 
ON public.transactions(created_at DESC, type) 
WHERE status = 'completed';

-- Support ticket queue
CREATE INDEX IF NOT EXISTS idx_support_tickets_queue 
ON public.support_tickets(status, priority, created_at) 
WHERE status IN ('open', 'in_progress');

-- Notification delivery
CREATE INDEX IF NOT EXISTS idx_notifications_delivery 
ON public.notifications(user_id, status, created_at DESC) 
WHERE status = 'pending';

-- ====================================
-- PARTIAL INDEXES FOR COMMON QUERIES
-- ====================================

-- Active events in specific cities
CREATE INDEX IF NOT EXISTS idx_events_city_active 
ON public.events(city, event_date) 
WHERE status = 'published';

-- Paid orders by date
CREATE INDEX IF NOT EXISTS idx_orders_paid_date
ON public.orders(created_at) 
WHERE status = 'paid';

-- Unread notifications
CREATE INDEX IF NOT EXISTS idx_notifications_unread 
ON public.notifications(user_id, created_at DESC) 
WHERE status = 'sent' AND channel = 'in_app';


-- ====================================
-- ANALYZE TABLES FOR OPTIMIZER
-- ====================================

-- Update statistics for query planner
ANALYZE public.profiles;
ANALYZE public.events;
ANALYZE public.tickets;
ANALYZE public.orders;
ANALYZE public.transactions;

-- ====================================
-- MONITORING QUERIES
-- ====================================

-- Function to check index usage
CREATE OR REPLACE FUNCTION public.check_index_usage()
RETURNS TABLE (
    schemaname TEXT,
    tablename TEXT,
    indexname TEXT,
    index_size TEXT,
    idx_scan BIGINT,
    idx_tup_read BIGINT,
    idx_tup_fetch BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        s.schemaname::TEXT,
        s.tablename::TEXT,
        s.indexname::TEXT,
        pg_size_pretty(pg_relation_size(s.indexrelid))::TEXT as index_size,
        s.idx_scan,
        s.idx_tup_read,
        s.idx_tup_fetch
    FROM pg_stat_user_indexes s
    WHERE s.schemaname = 'public'
    ORDER BY s.idx_scan DESC;
END;
$$ LANGUAGE plpgsql;

-- Function to find missing indexes
CREATE OR REPLACE FUNCTION public.find_missing_indexes()
RETURNS TABLE (
    tablename TEXT,
    attname TEXT,
    n_distinct REAL,
    correlation REAL,
    recommendation TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        t.tablename::TEXT,
        a.attname::TEXT,
        s.n_distinct,
        s.correlation,
        CASE 
            WHEN s.n_distinct > 100 AND s.correlation < 0.1 
            THEN 'Consider adding index'
            ELSE 'Index may not be beneficial'
        END::TEXT as recommendation
    FROM pg_stats s
    JOIN pg_attribute a ON a.attname = s.attname
    JOIN pg_tables t ON t.tablename = s.tablename
    WHERE s.schemaname = 'public'
    AND a.attnum > 0
    AND NOT EXISTS (
        SELECT 1 FROM pg_index i
        WHERE i.indrelid = (t.schemaname||'.'||t.tablename)::regclass
        AND a.attnum = ANY(i.indkey)
    )
    ORDER BY s.n_distinct DESC;
END;
$$ LANGUAGE plpgsql;