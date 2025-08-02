-- Create tickets table with partitioning by event date
CREATE TABLE IF NOT EXISTS public.tickets (
    id UUID DEFAULT gen_random_uuid(),
    ticket_code VARCHAR(50) NOT NULL, -- Removed UNIQUE constraint here
    ticket_hash VARCHAR(255) NOT NULL,
    order_id UUID REFERENCES public.orders(id) ON DELETE RESTRICT NOT NULL,
    event_id UUID REFERENCES public.events(id) ON DELETE RESTRICT NOT NULL,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    ticket_type VARCHAR(100) NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    status TEXT CHECK (status IN ('valid', 'used', 'cancelled', 'transferred')) DEFAULT 'valid',
    qr_code_url TEXT,
    offline_mode_data JSONB,
    transferred_from UUID,
    transferred_to UUID REFERENCES public.profiles(id),
    transferred_at TIMESTAMPTZ,
    scanned_by UUID REFERENCES public.profiles(id),
    scanned_at TIMESTAMPTZ,
    device_fingerprint VARCHAR(255),
    entry_gate VARCHAR(50),
    seat_number VARCHAR(20),
    special_requirements TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    valid_from TIMESTAMPTZ,
    valid_until TIMESTAMPTZ,
    event_date DATE NOT NULL, -- For partitioning
    PRIMARY KEY (id, event_date),
    UNIQUE (ticket_code, event_date) -- Unique constraint includes partition key
) PARTITION BY RANGE (event_date);

-- Create partitions for the next 12 months
DO $$
DECLARE
    start_date DATE := DATE_TRUNC('month', CURRENT_DATE);
    partition_date DATE;
    partition_name TEXT;
BEGIN
    FOR i IN 0..11 LOOP
        partition_date := start_date + (i || ' months')::INTERVAL;
        partition_name := 'tickets_' || TO_CHAR(partition_date, 'YYYY_MM');
        
        EXECUTE format(
            'CREATE TABLE IF NOT EXISTS public.%I PARTITION OF public.tickets
            FOR VALUES FROM (%L) TO (%L)',
            partition_name,
            partition_date,
            partition_date + INTERVAL '1 month'
        );
    END LOOP;
END $$;

-- Create a unique index on ticket_code across all partitions using a trigger
CREATE OR REPLACE FUNCTION public.check_ticket_code_unique()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM public.tickets 
        WHERE ticket_code = NEW.ticket_code 
        AND id != NEW.id
    ) THEN
        RAISE EXCEPTION 'Ticket code % already exists', NEW.ticket_code;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ensure_ticket_code_unique
    BEFORE INSERT OR UPDATE ON public.tickets
    FOR EACH ROW
    EXECUTE FUNCTION public.check_ticket_code_unique();

-- Create indexes on tickets table
CREATE INDEX idx_tickets_ticket_code ON public.tickets(ticket_code);
CREATE INDEX idx_tickets_order_id ON public.tickets(order_id);
CREATE INDEX idx_tickets_event_id ON public.tickets(event_id);
CREATE INDEX idx_tickets_user_id ON public.tickets(user_id);
CREATE INDEX idx_tickets_status ON public.tickets(status);
CREATE INDEX idx_tickets_event_date ON public.tickets(event_date);
CREATE INDEX idx_tickets_scanned_at ON public.tickets(scanned_at) WHERE scanned_at IS NOT NULL;

-- Enable Row Level Security
ALTER TABLE public.tickets ENABLE ROW LEVEL SECURITY;

-- Create policies for tickets table
-- Users can view their own tickets
CREATE POLICY "Users can view own tickets" ON public.tickets
    FOR SELECT USING (
        user_id = auth.uid() OR 
        transferred_to = auth.uid() OR
        EXISTS (
            SELECT 1 FROM public.organizers o
            JOIN public.events e ON e.organizer_id = o.id
            WHERE e.id = tickets.event_id AND o.user_id = auth.uid()
        )
    );

-- Scanners can update tickets they're authorized to scan
CREATE POLICY "Authorized scanners can update tickets" ON public.tickets
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.events e
            JOIN public.organizers o ON o.id = e.organizer_id
            WHERE e.id = tickets.event_id AND o.user_id = auth.uid()
        )
    );

-- Enable realtime for ticket updates
ALTER PUBLICATION supabase_realtime ADD TABLE public.tickets;

-- Function to generate unique ticket code
CREATE OR REPLACE FUNCTION public.generate_ticket_code()
RETURNS TEXT AS $$
DECLARE
    new_code TEXT;
    code_exists BOOLEAN;
BEGIN
    LOOP
        -- Generate ticket code: TKT + 12 alphanumeric characters
        new_code := 'TKT' || UPPER(
            SUBSTRING(
                REPLACE(
                    REPLACE(
                        encode(gen_random_bytes(9), 'base64'),
                        '/', ''
                    ),
                    '+', ''
                ),
                1, 12
            )
        );
        
        -- Check if exists
        SELECT EXISTS(SELECT 1 FROM public.tickets WHERE ticket_code = new_code) INTO code_exists;
        
        EXIT WHEN NOT code_exists;
    END LOOP;
    
    RETURN new_code;
END;
$$ LANGUAGE plpgsql;

-- Function to generate ticket hash for security
CREATE OR REPLACE FUNCTION public.generate_ticket_hash(
    p_ticket_code TEXT,
    p_event_id UUID,
    p_user_id UUID,
    p_created_at TIMESTAMPTZ
)
RETURNS TEXT AS $$
BEGIN
    -- Create hash using multiple fields for security
    RETURN encode(
        digest(
            p_ticket_code || p_event_id::TEXT || p_user_id::TEXT || p_created_at::TEXT || COALESCE(current_setting('app.secret_key', true), 'default_secret'),
            'sha256'
        ),
        'hex'
    );
END;
$$ LANGUAGE plpgsql;

-- Function to create tickets after order payment
CREATE OR REPLACE FUNCTION public.create_tickets_for_order(
    p_order_id UUID
)
RETURNS VOID AS $$
DECLARE
    v_order RECORD;
    v_event RECORD;
    v_ticket_types JSONB;
    v_ticket_type JSONB;
    v_ticket_count INTEGER;
    v_event_date DATE;
BEGIN
    -- Get order details
    SELECT * INTO v_order FROM public.orders WHERE id = p_order_id AND status = 'paid';
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Order not found or not paid';
    END IF;
    
    -- Get event details
    SELECT *, DATE(event_date) as event_day INTO v_event FROM public.events WHERE id = v_order.event_id;
    v_event_date := v_event.event_day;
    
    -- Get ticket types from buyer_info
    v_ticket_types := v_order.buyer_info->'ticket_types';
    
    -- Create tickets based on ticket types
    FOR v_ticket_type IN SELECT * FROM jsonb_array_elements(v_ticket_types)
    LOOP
        v_ticket_count := (v_ticket_type->>'quantity')::INTEGER;
        
        FOR i IN 1..v_ticket_count LOOP
            INSERT INTO public.tickets (
                ticket_code,
                ticket_hash,
                order_id,
                event_id,
                user_id,
                ticket_type,
                price,
                valid_from,
                valid_until,
                event_date,
                offline_mode_data
            ) VALUES (
                public.generate_ticket_code(),
                '', -- Will be set by trigger
                p_order_id,
                v_order.event_id,
                v_order.user_id,
                v_ticket_type->>'name',
                (v_ticket_type->>'price')::DECIMAL,
                v_event.event_date - INTERVAL '1 day',
                v_event.end_date,
                v_event_date,
                jsonb_build_object(
                    'event_title', v_event.title,
                    'event_date', v_event.event_date,
                    'venue_name', v_event.venue_name,
                    'organizer_name', (
                        SELECT business_name FROM public.organizers WHERE id = v_event.organizer_id
                    )
                )
            );
        END LOOP;
    END LOOP;
    
    -- Update event tickets sold count
    UPDATE public.events 
    SET tickets_sold = tickets_sold + v_order.ticket_count
    WHERE id = v_order.event_id;
    
    -- Update organizer stats
    UPDATE public.organizers o
    SET 
        total_tickets_sold = total_tickets_sold + v_order.ticket_count,
        total_revenue = total_revenue + (v_order.total_amount - v_order.service_fee)
    FROM public.events e
    WHERE e.organizer_id = o.id AND e.id = v_order.event_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to set ticket hash on insert
CREATE OR REPLACE FUNCTION public.handle_new_ticket()
RETURNS TRIGGER AS $$
BEGIN
    -- Generate ticket hash
    NEW.ticket_hash = public.generate_ticket_hash(
        NEW.ticket_code,
        NEW.event_id,
        NEW.user_id,
        NEW.created_at
    );
    
    -- Set valid_from and valid_until if not provided
    IF NEW.valid_from IS NULL THEN
        SELECT event_date - INTERVAL '1 day' INTO NEW.valid_from
        FROM public.events WHERE id = NEW.event_id;
    END IF;
    
    IF NEW.valid_until IS NULL THEN
        SELECT COALESCE(end_date, event_date + INTERVAL '1 day') INTO NEW.valid_until
        FROM public.events WHERE id = NEW.event_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to validate and scan ticket
CREATE OR REPLACE FUNCTION public.scan_ticket(
    p_ticket_code TEXT,
    p_scanner_id UUID,
    p_device_fingerprint TEXT DEFAULT NULL,
    p_location GEOGRAPHY DEFAULT NULL,
    p_ip_address INET DEFAULT NULL,
    p_user_agent TEXT DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
    v_ticket RECORD;
    v_event RECORD;
    v_can_scan BOOLEAN;
    v_result TEXT;
    v_message TEXT;
    v_scan_start TIMESTAMP;
BEGIN
    v_scan_start := clock_timestamp();
    
    -- Get ticket details
    SELECT t.*, e.* 
    INTO v_ticket
    FROM public.tickets t
    JOIN public.events e ON e.id = t.event_id
    WHERE t.ticket_code = p_ticket_code;
    
    IF NOT FOUND THEN
        -- Log failed attempt (assuming scan_attempts table exists)
        -- PERFORM public.log_scan_attempt(...);
        
        RETURN jsonb_build_object(
            'success', false,
            'message', 'Invalid ticket code',
            'scan_duration_ms', EXTRACT(MILLISECONDS FROM clock_timestamp() - v_scan_start)
        );
    END IF;
    
    -- Check if event is cancelled
    IF v_ticket.status = 'cancelled' THEN
        RETURN jsonb_build_object(
            'success', false,
            'message', 'Event has been cancelled',
            'scan_duration_ms', EXTRACT(MILLISECONDS FROM clock_timestamp() - v_scan_start)
        );
    END IF;
    
    -- Check if scanner is authorized (only organizers for now)
    SELECT TRUE INTO v_can_scan
    FROM public.events e
    JOIN public.organizers o ON o.id = e.organizer_id
    WHERE e.id = v_ticket.event_id AND o.user_id = p_scanner_id;
    
    IF NOT v_can_scan THEN
        RETURN jsonb_build_object(
            'success', false,
            'message', 'Unauthorized scanner',
            'scan_duration_ms', EXTRACT(MILLISECONDS FROM clock_timestamp() - v_scan_start)
        );
    END IF;
    
    -- Check ticket status
    IF v_ticket.status = 'used' THEN
        RETURN jsonb_build_object(
            'success', false,
            'message', 'Ticket already used',
            'used_at', v_ticket.scanned_at,
            'scanned_by', (SELECT email FROM public.profiles WHERE id = v_ticket.scanned_by),
            'scan_duration_ms', EXTRACT(MILLISECONDS FROM clock_timestamp() - v_scan_start)
        );
    END IF;
    
    IF v_ticket.status = 'cancelled' THEN
        RETURN jsonb_build_object(
            'success', false,
            'message', 'Ticket has been cancelled',
            'scan_duration_ms', EXTRACT(MILLISECONDS FROM clock_timestamp() - v_scan_start)
        );
    END IF;
    
    -- Check validity period
    IF NOW() < v_ticket.valid_from OR NOW() > v_ticket.valid_until THEN
        RETURN jsonb_build_object(
            'success', false,
            'message', 'Ticket not valid at this time',
            'valid_from', v_ticket.valid_from,
            'valid_until', v_ticket.valid_until,
            'scan_duration_ms', EXTRACT(MILLISECONDS FROM clock_timestamp() - v_scan_start)
        );
    END IF;
    
    -- SUCCESS - Mark ticket as used
    UPDATE public.tickets
    SET 
        status = 'used',
        scanned_by = p_scanner_id,
        scanned_at = NOW(),
        device_fingerprint = p_device_fingerprint
    WHERE id = v_ticket.id AND event_date = v_ticket.event_date;
    
    RETURN jsonb_build_object(
        'success', true,
        'message', 'Ticket validated successfully',
        'ticket_type', v_ticket.ticket_type,
        'event_title', v_ticket.title,
        'attendee_name', (SELECT email FROM public.profiles WHERE id = v_ticket.user_id),
        'scan_duration_ms', EXTRACT(MILLISECONDS FROM clock_timestamp() - v_scan_start)
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create triggers
CREATE TRIGGER handle_new_ticket_trigger
    BEFORE INSERT ON public.tickets
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_ticket();

-- Function to auto-create monthly partitions
CREATE OR REPLACE FUNCTION public.create_monthly_partition()
RETURNS void AS $$
DECLARE
    partition_date DATE;
    partition_name TEXT;
BEGIN
    -- Create partition for next month if it doesn't exist
    partition_date := DATE_TRUNC('month', CURRENT_DATE + INTERVAL '1 month');
    partition_name := 'tickets_' || TO_CHAR(partition_date, 'YYYY_MM');
    
    EXECUTE format(
        'CREATE TABLE IF NOT EXISTS public.%I PARTITION OF public.tickets
        FOR VALUES FROM (%L) TO (%L)',
        partition_name,
        partition_date,
        partition_date + INTERVAL '1 month'
    );
END;
$$ LANGUAGE plpgsql;