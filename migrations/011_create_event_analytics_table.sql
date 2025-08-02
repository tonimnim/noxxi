-- Create event_analytics table for daily event metrics
CREATE TABLE IF NOT EXISTS public.event_analytics (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    event_id UUID REFERENCES public.events(id) ON DELETE CASCADE NOT NULL,
    date DATE NOT NULL,
    ticket_sales INTEGER DEFAULT 0,
    revenue DECIMAL(10,2) DEFAULT 0,
    page_views INTEGER DEFAULT 0,
    conversion_rate DECIMAL(5,2),
    avg_order_value DECIMAL(10,2),
    peak_sale_hour INTEGER CHECK (peak_sale_hour >= 0 AND peak_sale_hour <= 23),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    -- Ensure one record per event per day
    UNIQUE(event_id, date)
);

-- Create indexes for performance
CREATE INDEX idx_event_analytics_event_id ON public.event_analytics(event_id);
CREATE INDEX idx_event_analytics_date ON public.event_analytics(date DESC);
CREATE INDEX idx_event_analytics_event_date ON public.event_analytics(event_id, date DESC);

-- Enable Row Level Security
ALTER TABLE public.event_analytics ENABLE ROW LEVEL SECURITY;

-- Create policies for event_analytics table
-- Organizers can view analytics for their events
CREATE POLICY "Organizers can view own event analytics" ON public.event_analytics
    FOR SELECT USING (
        event_id IN (
            SELECT e.id FROM public.events e
            JOIN public.organizers o ON o.id = e.organizer_id
            WHERE o.user_id = auth.uid()
        )
    );

-- Staff with analytics permission can view
CREATE POLICY "Staff can view event analytics" ON public.event_analytics
    FOR SELECT USING (
        event_id IN (
            SELECT event_id FROM public.event_staff
            WHERE user_id = auth.uid() 
            AND can_view_analytics = true 
            AND is_active = true
        )
    );

-- System can manage analytics
CREATE POLICY "System can manage analytics" ON public.event_analytics
    FOR ALL USING (true);

-- Function to update daily analytics
CREATE OR REPLACE FUNCTION public.update_event_analytics(
    p_event_id UUID,
    p_date DATE DEFAULT CURRENT_DATE
)
RETURNS VOID AS $$
DECLARE
    v_stats RECORD;
BEGIN
    -- Calculate daily stats
    WITH daily_sales AS (
        SELECT 
            COUNT(DISTINCT o.id) as order_count,
            SUM(o.ticket_count) as tickets_sold,
            SUM(o.total_amount) as revenue,
            AVG(o.total_amount) as avg_order_value
        FROM public.orders o
        WHERE o.event_id = p_event_id
        AND DATE(o.created_at) = p_date
        AND o.status = 'paid'
    ),
    hourly_sales AS (
        SELECT 
            EXTRACT(HOUR FROM created_at)::INTEGER as hour,
            COUNT(*) as sales_count
        FROM public.orders
        WHERE event_id = p_event_id
        AND DATE(created_at) = p_date
        AND status = 'paid'
        GROUP BY EXTRACT(HOUR FROM created_at)
        ORDER BY sales_count DESC
        LIMIT 1
    )
    SELECT 
        COALESCE(ds.tickets_sold, 0) as tickets_sold,
        COALESCE(ds.revenue, 0) as revenue,
        COALESCE(ds.avg_order_value, 0) as avg_order_value,
        COALESCE(hs.hour, 0) as peak_hour
    INTO v_stats
    FROM daily_sales ds
    LEFT JOIN hourly_sales hs ON true;
    
    -- Insert or update analytics record
    INSERT INTO public.event_analytics (
        event_id,
        date,
        ticket_sales,
        revenue,
        avg_order_value,
        peak_sale_hour
    ) VALUES (
        p_event_id,
        p_date,
        v_stats.tickets_sold,
        v_stats.revenue,
        v_stats.avg_order_value,
        v_stats.peak_hour
    )
    ON CONFLICT (event_id, date) 
    DO UPDATE SET
        ticket_sales = EXCLUDED.ticket_sales,
        revenue = EXCLUDED.revenue,
        avg_order_value = EXCLUDED.avg_order_value,
        peak_sale_hour = EXCLUDED.peak_sale_hour,
        updated_at = NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get event performance summary
CREATE OR REPLACE FUNCTION public.get_event_performance(
    p_event_id UUID,
    p_days INTEGER DEFAULT 30
)
RETURNS JSONB AS $$
DECLARE
    v_result JSONB;
BEGIN
    WITH performance AS (
        SELECT 
            SUM(ticket_sales) as total_tickets,
            SUM(revenue) as total_revenue,
            AVG(avg_order_value) as avg_order_value,
            MAX(ticket_sales) as best_day_sales,
            MAX(date) FILTER (WHERE ticket_sales = (SELECT MAX(ticket_sales) FROM public.event_analytics WHERE event_id = p_event_id)) as best_day,
            jsonb_agg(
                jsonb_build_object(
                    'date', date,
                    'sales', ticket_sales,
                    'revenue', revenue
                ) ORDER BY date DESC
            ) as daily_breakdown
        FROM public.event_analytics
        WHERE event_id = p_event_id
        AND date >= CURRENT_DATE - (p_days || ' days')::INTERVAL
    ),
    event_info AS (
        SELECT 
            title,
            event_date,
            total_capacity,
            tickets_sold,
            status
        FROM public.events
        WHERE id = p_event_id
    )
    SELECT jsonb_build_object(
        'event_title', event_info.title,
        'event_date', event_info.event_date,
        'total_capacity', event_info.total_capacity,
        'tickets_sold', event_info.tickets_sold,
        'status', event_info.status,
        'total_revenue', COALESCE(performance.total_revenue, 0),
        'avg_order_value', COALESCE(performance.avg_order_value, 0),
        'best_day', performance.best_day,
        'best_day_sales', COALESCE(performance.best_day_sales, 0),
        'sell_through_rate', CASE 
            WHEN event_info.total_capacity > 0 
            THEN ROUND((event_info.tickets_sold::DECIMAL / event_info.total_capacity) * 100, 2)
            ELSE 0 
        END,
        'daily_breakdown', COALESCE(performance.daily_breakdown, '[]'::jsonb)
    ) INTO v_result
    FROM event_info, performance;
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update analytics after order
CREATE OR REPLACE FUNCTION public.trigger_update_analytics()
RETURNS TRIGGER AS $$
BEGIN
    -- Update analytics for the event
    IF NEW.status = 'paid' AND (OLD IS NULL OR OLD.status != 'paid') THEN
        PERFORM public.update_event_analytics(NEW.event_id, DATE(NEW.created_at));
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger on orders table
CREATE TRIGGER update_analytics_on_order
    AFTER INSERT OR UPDATE ON public.orders
    FOR EACH ROW
    EXECUTE FUNCTION public.trigger_update_analytics();

-- Trigger to update updated_at
CREATE TRIGGER handle_event_analytics_updated_at
    BEFORE UPDATE ON public.event_analytics
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- Function to calculate conversion rate (called periodically)
CREATE OR REPLACE FUNCTION public.calculate_conversion_rates(
    p_date DATE DEFAULT CURRENT_DATE
)
RETURNS VOID AS $$
BEGIN
    -- Update conversion rates based on views vs sales
    UPDATE public.event_analytics ea
    SET conversion_rate = CASE 
        WHEN ea.page_views > 0 
        THEN ROUND((ea.ticket_sales::DECIMAL / ea.page_views) * 100, 2)
        ELSE 0 
    END
    WHERE ea.date = p_date
    AND ea.page_views > 0;
END;
$$ LANGUAGE plpgsql;