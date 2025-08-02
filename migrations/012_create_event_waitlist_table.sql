-- Create event_waitlist table for sold-out events
CREATE TABLE IF NOT EXISTS public.event_waitlist (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    event_id UUID REFERENCES public.events(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    email VARCHAR(255) NOT NULL,
    phone_number VARCHAR(20) NOT NULL,
    ticket_type VARCHAR(100),
    quantity INTEGER DEFAULT 1 CHECK (quantity > 0 AND quantity <= 10),
    notified BOOLEAN DEFAULT false,
    converted BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    notified_at TIMESTAMPTZ,
    converted_at TIMESTAMPTZ,
    -- Prevent duplicate waitlist entries
    UNIQUE(event_id, user_id, ticket_type)
);

-- Create indexes for performance
CREATE INDEX idx_event_waitlist_event_id ON public.event_waitlist(event_id);
CREATE INDEX idx_event_waitlist_user_id ON public.event_waitlist(user_id);
CREATE INDEX idx_event_waitlist_created_at ON public.event_waitlist(created_at);
CREATE INDEX idx_event_waitlist_not_notified ON public.event_waitlist(event_id, notified) WHERE notified = false;

-- Enable Row Level Security
ALTER TABLE public.event_waitlist ENABLE ROW LEVEL SECURITY;

-- Create policies for event_waitlist table
-- Users can view their own waitlist entries
CREATE POLICY "Users can view own waitlist entries" ON public.event_waitlist
    FOR SELECT USING (user_id = auth.uid());

-- Users can create waitlist entries
CREATE POLICY "Users can join waitlist" ON public.event_waitlist
    FOR INSERT WITH CHECK (user_id = auth.uid());

-- Users can update their own entries (change quantity)
CREATE POLICY "Users can update own waitlist" ON public.event_waitlist
    FOR UPDATE USING (user_id = auth.uid() AND converted = false);

-- Users can delete their own entries
CREATE POLICY "Users can leave waitlist" ON public.event_waitlist
    FOR DELETE USING (user_id = auth.uid() AND converted = false);

-- Organizers can view waitlists for their events
CREATE POLICY "Organizers can view event waitlists" ON public.event_waitlist
    FOR SELECT USING (
        event_id IN (
            SELECT e.id FROM public.events e
            JOIN public.organizers o ON o.id = e.organizer_id
            WHERE o.user_id = auth.uid()
        )
    );

-- Enable realtime
ALTER PUBLICATION supabase_realtime ADD TABLE public.event_waitlist;

-- Function to join waitlist
CREATE OR REPLACE FUNCTION public.join_waitlist(
    p_event_id UUID,
    p_ticket_type VARCHAR(100) DEFAULT NULL,
    p_quantity INTEGER DEFAULT 1
)
RETURNS JSONB AS $$
DECLARE
    v_event RECORD;
    v_user RECORD;
    v_waitlist_id UUID;
    v_position INTEGER;
BEGIN
    -- Get event details
    SELECT * INTO v_event FROM public.events WHERE id = p_event_id;
    
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'message', 'Event not found');
    END IF;
    
    -- Check if event is actually sold out
    IF v_event.tickets_sold < v_event.total_capacity THEN
        RETURN jsonb_build_object(
            'success', false, 
            'message', 'Tickets are still available',
            'available_tickets', v_event.total_capacity - v_event.tickets_sold
        );
    END IF;
    
    -- Get user details
    SELECT * INTO v_user FROM public.profiles WHERE user_id = auth.uid();
    
    -- Join waitlist
    INSERT INTO public.event_waitlist (
        event_id,
        user_id,
        email,
        phone_number,
        ticket_type,
        quantity
    ) VALUES (
        p_event_id,
        auth.uid(),
        v_user.email,
        v_user.phone_number,
        p_ticket_type,
        p_quantity
    ) 
    ON CONFLICT (event_id, user_id, ticket_type) 
    DO UPDATE SET
        quantity = EXCLUDED.quantity,
        created_at = CASE 
            WHEN event_waitlist.converted = true THEN NOW()
            ELSE event_waitlist.created_at
        END,
        converted = false,
        notified = false
    RETURNING id INTO v_waitlist_id;
    
    -- Get position in waitlist
    SELECT COUNT(*) + 1 INTO v_position
    FROM public.event_waitlist
    WHERE event_id = p_event_id
    AND created_at < (SELECT created_at FROM public.event_waitlist WHERE id = v_waitlist_id)
    AND converted = false;
    
    RETURN jsonb_build_object(
        'success', true,
        'waitlist_id', v_waitlist_id,
        'position', v_position,
        'message', 'Successfully joined waitlist'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to notify waitlist when tickets become available
CREATE OR REPLACE FUNCTION public.notify_waitlist(
    p_event_id UUID,
    p_available_tickets INTEGER,
    p_ticket_type VARCHAR(100) DEFAULT NULL
)
RETURNS INTEGER AS $$
DECLARE
    v_notified_count INTEGER := 0;
    v_waitlist_entry RECORD;
    v_tickets_allocated INTEGER := 0;
BEGIN
    -- Get waitlist entries in order
    FOR v_waitlist_entry IN 
        SELECT * FROM public.event_waitlist
        WHERE event_id = p_event_id
        AND (ticket_type = p_ticket_type OR p_ticket_type IS NULL)
        AND notified = false
        AND converted = false
        ORDER BY created_at
    LOOP
        -- Check if we can fulfill this request
        IF v_tickets_allocated + v_waitlist_entry.quantity <= p_available_tickets THEN
            -- Mark as notified
            UPDATE public.event_waitlist
            SET 
                notified = true,
                notified_at = NOW()
            WHERE id = v_waitlist_entry.id;
            
            -- TODO: Send notification (SMS/Email)
            -- This would integrate with your notification service
            
            v_notified_count := v_notified_count + 1;
            v_tickets_allocated := v_tickets_allocated + v_waitlist_entry.quantity;
        ELSE
            -- Can't fulfill more requests
            EXIT;
        END IF;
    END LOOP;
    
    RETURN v_notified_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to convert waitlist to order
CREATE OR REPLACE FUNCTION public.convert_waitlist_to_order(
    p_waitlist_id UUID
)
RETURNS UUID AS $$
DECLARE
    v_waitlist RECORD;
    v_order_id UUID;
BEGIN
    -- Get waitlist entry
    SELECT * INTO v_waitlist 
    FROM public.event_waitlist 
    WHERE id = p_waitlist_id AND user_id = auth.uid();
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Waitlist entry not found';
    END IF;
    
    IF v_waitlist.converted THEN
        RAISE EXCEPTION 'Waitlist entry already converted';
    END IF;
    
    -- Mark as converted
    UPDATE public.event_waitlist
    SET 
        converted = true,
        converted_at = NOW()
    WHERE id = p_waitlist_id;
    
    -- Return null for now - actual order creation would happen through normal flow
    -- This just marks the waitlist entry as converted
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get waitlist stats
CREATE OR REPLACE FUNCTION public.get_waitlist_stats(
    p_event_id UUID
)
RETURNS JSONB AS $$
DECLARE
    v_stats JSONB;
    v_by_ticket_type JSONB;
BEGIN
    -- Get ticket type breakdown
    SELECT jsonb_object_agg(ticket_type, type_count)
    INTO v_by_ticket_type
    FROM (
        SELECT 
            COALESCE(ticket_type, 'Any') as ticket_type,
            COUNT(*) as type_count
        FROM public.event_waitlist
        WHERE event_id = p_event_id
        GROUP BY ticket_type
    ) t;
    
    -- Get overall stats
    SELECT jsonb_build_object(
        'total_waitlisted', COUNT(*),
        'total_quantity', SUM(quantity),
        'notified_count', COUNT(*) FILTER (WHERE notified = true),
        'converted_count', COUNT(*) FILTER (WHERE converted = true),
        'conversion_rate', CASE 
            WHEN COUNT(*) FILTER (WHERE notified = true) > 0
            THEN ROUND((COUNT(*) FILTER (WHERE converted = true)::DECIMAL / 
                       COUNT(*) FILTER (WHERE notified = true)) * 100, 2)
            ELSE 0
        END,
        'by_ticket_type', COALESCE(v_by_ticket_type, '{}'::jsonb)
    ) INTO v_stats
    FROM public.event_waitlist
    WHERE event_id = p_event_id;
    
    RETURN v_stats;
END;
$$ LANGUAGE plpgsql;

-- Trigger to check if tickets become available (e.g., after refund)
CREATE OR REPLACE FUNCTION public.check_waitlist_on_refund()
RETURNS TRIGGER AS $$
DECLARE
    v_available_tickets INTEGER;
BEGIN
    -- When tickets are refunded, check if we should notify waitlist
    IF NEW.status = 'refunded' AND OLD.status = 'paid' THEN
        -- Get available tickets
        SELECT total_capacity - tickets_sold INTO v_available_tickets
        FROM public.events
        WHERE id = NEW.event_id;
        
        IF v_available_tickets > 0 THEN
            -- Notify waitlist
            PERFORM public.notify_waitlist(NEW.event_id, v_available_tickets);
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger on orders table
CREATE TRIGGER check_waitlist_on_order_change
    AFTER UPDATE ON public.orders
    FOR EACH ROW
    EXECUTE FUNCTION public.check_waitlist_on_refund();