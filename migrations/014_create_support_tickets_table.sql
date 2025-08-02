-- Create support_tickets table for customer support
CREATE TABLE IF NOT EXISTS public.support_tickets (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    order_id UUID REFERENCES public.orders(id),
    category TEXT CHECK (category IN ('payment', 'ticket', 'event', 'refund', 'other')) NOT NULL,
    subject VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    status TEXT CHECK (status IN ('open', 'in_progress', 'resolved', 'closed')) DEFAULT 'open',
    priority TEXT CHECK (priority IN ('low', 'medium', 'high', 'urgent')) DEFAULT 'medium',
    assigned_to UUID REFERENCES public.profiles(id),
    resolved_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    ticket_number VARCHAR(20) UNIQUE NOT NULL,
    resolution_notes TEXT,
    satisfaction_rating INTEGER CHECK (satisfaction_rating >= 1 AND satisfaction_rating <= 5),
    metadata JSONB DEFAULT '{}'::jsonb
);

-- Create indexes for performance
CREATE INDEX idx_support_tickets_user_id ON public.support_tickets(user_id);
CREATE INDEX idx_support_tickets_order_id ON public.support_tickets(order_id) WHERE order_id IS NOT NULL;
CREATE INDEX idx_support_tickets_status ON public.support_tickets(status);
CREATE INDEX idx_support_tickets_priority ON public.support_tickets(priority);
CREATE INDEX idx_support_tickets_assigned_to ON public.support_tickets(assigned_to) WHERE assigned_to IS NOT NULL;
CREATE INDEX idx_support_tickets_created_at ON public.support_tickets(created_at DESC);
CREATE INDEX idx_support_tickets_open ON public.support_tickets(status, priority) WHERE status IN ('open', 'in_progress');

-- Enable Row Level Security
ALTER TABLE public.support_tickets ENABLE ROW LEVEL SECURITY;

-- Create policies for support_tickets table
-- Users can view their own tickets
CREATE POLICY "Users can view own tickets" ON public.support_tickets
    FOR SELECT USING (user_id = auth.uid());

-- Users can create tickets
CREATE POLICY "Users can create tickets" ON public.support_tickets
    FOR INSERT WITH CHECK (user_id = auth.uid());

-- Users can update their own open tickets
CREATE POLICY "Users can update own open tickets" ON public.support_tickets
    FOR UPDATE USING (
        user_id = auth.uid() AND 
        status IN ('open', 'in_progress')
    );

-- Support agents (admins) can view all tickets
CREATE POLICY "Support agents can view all tickets" ON public.support_tickets
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM public.profiles WHERE user_id = auth.uid() AND role = 'admin')
    );

-- Support agents can update tickets
CREATE POLICY "Support agents can update tickets" ON public.support_tickets
    FOR UPDATE USING (
        EXISTS (SELECT 1 FROM public.profiles WHERE user_id = auth.uid() AND role = 'admin')
    );

-- Enable realtime for ticket updates
ALTER PUBLICATION supabase_realtime ADD TABLE public.support_tickets;

-- Function to generate ticket number
CREATE OR REPLACE FUNCTION public.generate_ticket_number()
RETURNS TEXT AS $$
DECLARE
    new_number TEXT;
    number_exists BOOLEAN;
BEGIN
    LOOP
        -- Generate ticket number: SUP + YYMMDD + 4 random digits
        new_number := 'SUP' || TO_CHAR(NOW(), 'YYMMDD') || LPAD(FLOOR(RANDOM() * 10000)::TEXT, 4, '0');
        
        -- Check if exists
        SELECT EXISTS(SELECT 1 FROM public.support_tickets WHERE ticket_number = new_number) INTO number_exists;
        
        EXIT WHEN NOT number_exists;
    END LOOP;
    
    RETURN new_number;
END;
$$ LANGUAGE plpgsql;

-- Function to create support ticket
CREATE OR REPLACE FUNCTION public.create_support_ticket(
    p_category TEXT,
    p_subject VARCHAR(255),
    p_description TEXT,
    p_order_id UUID DEFAULT NULL,
    p_priority TEXT DEFAULT 'medium'
)
RETURNS UUID AS $$
DECLARE
    v_ticket_id UUID;
    v_ticket_number TEXT;
    v_auto_priority TEXT;
BEGIN
    -- Auto-adjust priority based on keywords
    v_auto_priority := p_priority;
    
    -- Check for urgent keywords
    IF p_description ILIKE '%urgent%' OR 
       p_description ILIKE '%emergency%' OR 
       p_description ILIKE '%immediately%' OR
       p_description ILIKE '%cannot access%' OR
       p_category = 'payment' THEN
        v_auto_priority := 'high';
    END IF;
    
    -- Payment issues with orders are always high priority
    IF p_category = 'payment' AND p_order_id IS NOT NULL THEN
        v_auto_priority := 'high';
    END IF;
    
    -- Generate ticket number
    v_ticket_number := public.generate_ticket_number();
    
    -- Create ticket
    INSERT INTO public.support_tickets (
        user_id,
        order_id,
        category,
        subject,
        description,
        priority,
        ticket_number,
        metadata
    ) VALUES (
        auth.uid(),
        p_order_id,
        p_category,
        p_subject,
        p_description,
        v_auto_priority,
        v_ticket_number,
        jsonb_build_object(
            'user_agent', current_setting('request.headers', true)::jsonb->>'user-agent',
            'created_from', 'mobile_app'
        )
    ) RETURNING id INTO v_ticket_id;
    
    -- Create notification for user
    PERFORM public.create_notification(
        auth.uid(),
        'support_ticket',
        'Support Ticket Created',
        'Your ticket #' || v_ticket_number || ' has been created. We''ll respond within 24 hours.',
        'in_app',
        jsonb_build_object(
            'ticket_id', v_ticket_id,
            'ticket_number', v_ticket_number
        )
    );
    
    RETURN v_ticket_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to assign ticket to support agent
CREATE OR REPLACE FUNCTION public.assign_support_ticket(
    p_ticket_id UUID,
    p_agent_id UUID DEFAULT NULL
)
RETURNS VOID AS $$
DECLARE
    v_ticket RECORD;
BEGIN
    -- If no agent specified, use current user
    IF p_agent_id IS NULL THEN
        p_agent_id := auth.uid();
    END IF;
    
    -- Get ticket details
    SELECT * INTO v_ticket FROM public.support_tickets WHERE id = p_ticket_id;
    
    -- Update ticket
    UPDATE public.support_tickets
    SET 
        assigned_to = p_agent_id,
        status = CASE WHEN status = 'open' THEN 'in_progress' ELSE status END,
        updated_at = NOW()
    WHERE id = p_ticket_id;
    
    -- Notify user that ticket is being handled
    PERFORM public.create_notification(
        v_ticket.user_id,
        'support_update',
        'Your support ticket is being handled',
        'An agent is now working on your ticket #' || v_ticket.ticket_number,
        'in_app',
        jsonb_build_object(
            'ticket_id', p_ticket_id,
            'ticket_number', v_ticket.ticket_number
        )
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to resolve ticket
CREATE OR REPLACE FUNCTION public.resolve_support_ticket(
    p_ticket_id UUID,
    p_resolution_notes TEXT
)
RETURNS VOID AS $$
DECLARE
    v_ticket RECORD;
BEGIN
    -- Get ticket details
    SELECT * INTO v_ticket FROM public.support_tickets WHERE id = p_ticket_id;
    
    -- Update ticket
    UPDATE public.support_tickets
    SET 
        status = 'resolved',
        resolution_notes = p_resolution_notes,
        resolved_at = NOW(),
        updated_at = NOW()
    WHERE id = p_ticket_id;
    
    -- Notify user
    PERFORM public.create_notification(
        v_ticket.user_id,
        'support_resolved',
        'Your support ticket has been resolved',
        'Ticket #' || v_ticket.ticket_number || ' has been resolved. Please rate your experience.',
        'in_app',
        jsonb_build_object(
            'ticket_id', p_ticket_id,
            'ticket_number', v_ticket.ticket_number
        )
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get ticket stats for dashboard
CREATE OR REPLACE FUNCTION public.get_support_stats(
    p_days INTEGER DEFAULT 30
)
RETURNS JSONB AS $$
DECLARE
    v_stats JSONB;
    v_by_category JSONB;
    v_by_priority JSONB;
BEGIN
    -- Get category breakdown
    SELECT jsonb_object_agg(category, cat_count)
    INTO v_by_category
    FROM (
        SELECT category, COUNT(*) as cat_count
        FROM public.support_tickets
        WHERE created_at >= NOW() - (p_days || ' days')::INTERVAL
        GROUP BY category
    ) c;
    
    -- Get priority breakdown
    SELECT jsonb_object_agg(priority, pri_count)
    INTO v_by_priority
    FROM (
        SELECT priority, COUNT(*) as pri_count
        FROM public.support_tickets
        WHERE created_at >= NOW() - (p_days || ' days')::INTERVAL
        GROUP BY priority
    ) p;
    
    -- Build final stats
    SELECT jsonb_build_object(
        'total_tickets', COUNT(*),
        'open_tickets', COUNT(*) FILTER (WHERE status = 'open'),
        'in_progress_tickets', COUNT(*) FILTER (WHERE status = 'in_progress'),
        'resolved_tickets', COUNT(*) FILTER (WHERE status = 'resolved'),
        'avg_resolution_time', AVG(
            EXTRACT(EPOCH FROM (resolved_at - created_at)) / 3600
        ) FILTER (WHERE resolved_at IS NOT NULL),
        'satisfaction_avg', AVG(satisfaction_rating) FILTER (WHERE satisfaction_rating IS NOT NULL),
        'by_category', COALESCE(v_by_category, '{}'::jsonb),
        'by_priority', COALESCE(v_by_priority, '{}'::jsonb)
    ) INTO v_stats
    FROM public.support_tickets
    WHERE created_at >= NOW() - (p_days || ' days')::INTERVAL;
    
    RETURN v_stats;
END;
$$ LANGUAGE plpgsql;

-- Function to handle new ticket trigger
CREATE OR REPLACE FUNCTION public.handle_new_support_ticket()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.ticket_number IS NULL THEN
        NEW.ticket_number := public.generate_ticket_number();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers
CREATE TRIGGER handle_new_ticket
    BEFORE INSERT ON public.support_tickets
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_support_ticket();

CREATE TRIGGER handle_support_tickets_updated_at
    BEFORE UPDATE ON public.support_tickets
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- Create support ticket categories table for better organization
CREATE TABLE IF NOT EXISTS public.support_ticket_responses (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    ticket_id UUID REFERENCES public.support_tickets(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES public.profiles(id) NOT NULL,
    message TEXT NOT NULL,
    is_internal BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for responses
CREATE INDEX idx_support_ticket_responses_ticket_id ON public.support_ticket_responses(ticket_id);

-- RLS for responses
ALTER TABLE public.support_ticket_responses ENABLE ROW LEVEL SECURITY;

-- Users can view responses for their tickets
CREATE POLICY "Users can view own ticket responses" ON public.support_ticket_responses
    FOR SELECT USING (
        ticket_id IN (SELECT id FROM public.support_tickets WHERE user_id = auth.uid()) OR
        EXISTS (SELECT 1 FROM public.profiles WHERE user_id = auth.uid() AND role = 'admin')
    );

-- Users and agents can create responses
CREATE POLICY "Users and agents can create responses" ON public.support_ticket_responses
    FOR INSERT WITH CHECK (
        user_id = auth.uid() AND (
            ticket_id IN (SELECT id FROM public.support_tickets WHERE user_id = auth.uid()) OR
            EXISTS (SELECT 1 FROM public.profiles WHERE user_id = auth.uid() AND role = 'admin')
        )
    );