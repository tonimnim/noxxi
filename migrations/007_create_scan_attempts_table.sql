-- Create scan_attempts table for comprehensive security logging
CREATE TABLE IF NOT EXISTS public.scan_attempts (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    ticket_id UUID, -- Nullable for invalid codes (no FK due to partitioning)
    ticket_code_attempted VARCHAR(100) NOT NULL, -- Always log what was scanned
    event_id UUID REFERENCES public.events(id), -- Nullable if ticket not found
    scanner_id UUID REFERENCES public.profiles(id) NOT NULL,
    device_fingerprint VARCHAR(255),
    scan_result TEXT CHECK (scan_result IN (
        'success', 
        'invalid_ticket', 
        'already_used', 
        'expired', 
        'wrong_event', 
        'unauthorized_scanner',
        'ticket_not_found',
        'event_cancelled',
        'invalid_hash'
    )) NOT NULL,
    scan_message TEXT, -- Detailed message for debugging
    location GEOGRAPHY(POINT, 4326),
    entry_gate VARCHAR(50),
    ip_address INET,
    user_agent TEXT,
    app_version VARCHAR(20),
    network_type VARCHAR(20), -- wifi, 4g, offline
    scan_duration_ms INTEGER, -- Time taken to validate
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX idx_scan_attempts_ticket_id ON public.scan_attempts(ticket_id) WHERE ticket_id IS NOT NULL;
CREATE INDEX idx_scan_attempts_event_id ON public.scan_attempts(event_id) WHERE event_id IS NOT NULL;
CREATE INDEX idx_scan_attempts_scanner_id ON public.scan_attempts(scanner_id);
CREATE INDEX idx_scan_attempts_created_at ON public.scan_attempts(created_at DESC);
CREATE INDEX idx_scan_attempts_device ON public.scan_attempts(device_fingerprint);
CREATE INDEX idx_scan_attempts_result ON public.scan_attempts(scan_result);
CREATE INDEX idx_scan_attempts_suspicious ON public.scan_attempts(scan_result, device_fingerprint, created_at) 
    WHERE scan_result != 'success';

-- Enable Row Level Security
ALTER TABLE public.scan_attempts ENABLE ROW LEVEL SECURITY;

-- Policies for scan_attempts
-- Scanners can view their own scan attempts
CREATE POLICY "Scanners can view own attempts" ON public.scan_attempts
    FOR SELECT USING (scanner_id = auth.uid());

-- Organizers can view scan attempts for their events
CREATE POLICY "Organizers can view event scan attempts" ON public.scan_attempts
    FOR SELECT USING (
        event_id IN (
            SELECT e.id FROM public.events e
            JOIN public.organizers o ON o.id = e.organizer_id
            WHERE o.user_id = auth.uid()
        )
    );

-- System can insert scan attempts
CREATE POLICY "System can insert scan attempts" ON public.scan_attempts
    FOR INSERT WITH CHECK (true);

-- Enable realtime for monitoring
ALTER PUBLICATION supabase_realtime ADD TABLE public.scan_attempts;

-- Function to log scan attempts (called from scan_ticket)
CREATE OR REPLACE FUNCTION public.log_scan_attempt(
    p_ticket_code TEXT,
    p_scanner_id UUID,
    p_result TEXT,
    p_message TEXT,
    p_ticket_id UUID DEFAULT NULL,
    p_event_id UUID DEFAULT NULL,
    p_device_fingerprint TEXT DEFAULT NULL,
    p_location GEOGRAPHY DEFAULT NULL,
    p_ip_address INET DEFAULT NULL,
    p_user_agent TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_attempt_id UUID;
BEGIN
    INSERT INTO public.scan_attempts (
        ticket_code_attempted,
        ticket_id,
        event_id,
        scanner_id,
        scan_result,
        scan_message,
        device_fingerprint,
        location,
        ip_address,
        user_agent
    ) VALUES (
        p_ticket_code,
        p_ticket_id,
        p_event_id,
        p_scanner_id,
        p_result,
        p_message,
        p_device_fingerprint,
        p_location,
        p_ip_address,
        p_user_agent
    ) RETURNING id INTO v_attempt_id;
    
    RETURN v_attempt_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update the scan_ticket function to log all attempts
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
        -- Log failed attempt
        PERFORM public.log_scan_attempt(
            p_ticket_code, p_scanner_id, 'ticket_not_found', 
            'No ticket found with this code',
            NULL, NULL, p_device_fingerprint, p_location, p_ip_address, p_user_agent
        );
        
        RETURN jsonb_build_object(
            'success', false,
            'message', 'Invalid ticket code',
            'scan_duration_ms', EXTRACT(MILLISECONDS FROM clock_timestamp() - v_scan_start)
        );
    END IF;
    
    -- Check if event is cancelled
    IF v_ticket.status = 'cancelled' THEN
        PERFORM public.log_scan_attempt(
            p_ticket_code, p_scanner_id, 'event_cancelled', 
            'Event has been cancelled',
            v_ticket.id, v_ticket.event_id, p_device_fingerprint, p_location, p_ip_address, p_user_agent
        );
        
        RETURN jsonb_build_object(
            'success', false,
            'message', 'Event has been cancelled',
            'scan_duration_ms', EXTRACT(MILLISECONDS FROM clock_timestamp() - v_scan_start)
        );
    END IF;
    
    -- Check if scanner is authorized
    SELECT TRUE INTO v_can_scan
    FROM public.events e
    JOIN public.organizers o ON o.id = e.organizer_id
    WHERE e.id = v_ticket.event_id AND (
        o.user_id = p_scanner_id OR
        EXISTS (
            SELECT 1 FROM public.event_staff es
            WHERE es.event_id = e.id 
            AND es.user_id = p_scanner_id 
            AND es.can_scan = true
            AND es.is_active = true
        )
    );
    
    IF NOT v_can_scan THEN
        PERFORM public.log_scan_attempt(
            p_ticket_code, p_scanner_id, 'unauthorized_scanner', 
            'Scanner not authorized for this event',
            v_ticket.id, v_ticket.event_id, p_device_fingerprint, p_location, p_ip_address, p_user_agent
        );
        
        RETURN jsonb_build_object(
            'success', false,
            'message', 'Unauthorized scanner',
            'scan_duration_ms', EXTRACT(MILLISECONDS FROM clock_timestamp() - v_scan_start)
        );
    END IF;
    
    -- Check ticket status
    IF v_ticket.status = 'used' THEN
        PERFORM public.log_scan_attempt(
            p_ticket_code, p_scanner_id, 'already_used', 
            'Ticket was used at ' || v_ticket.scanned_at::TEXT,
            v_ticket.id, v_ticket.event_id, p_device_fingerprint, p_location, p_ip_address, p_user_agent
        );
        
        RETURN jsonb_build_object(
            'success', false,
            'message', 'Ticket already used',
            'used_at', v_ticket.scanned_at,
            'scanned_by', (SELECT email FROM public.profiles WHERE id = v_ticket.scanned_by),
            'scan_duration_ms', EXTRACT(MILLISECONDS FROM clock_timestamp() - v_scan_start)
        );
    END IF;
    
    IF v_ticket.status = 'cancelled' THEN
        PERFORM public.log_scan_attempt(
            p_ticket_code, p_scanner_id, 'invalid_ticket', 
            'Ticket has been cancelled',
            v_ticket.id, v_ticket.event_id, p_device_fingerprint, p_location, p_ip_address, p_user_agent
        );
        
        RETURN jsonb_build_object(
            'success', false,
            'message', 'Ticket has been cancelled',
            'scan_duration_ms', EXTRACT(MILLISECONDS FROM clock_timestamp() - v_scan_start)
        );
    END IF;
    
    -- Check validity period
    IF NOW() < v_ticket.valid_from OR NOW() > v_ticket.valid_until THEN
        PERFORM public.log_scan_attempt(
            p_ticket_code, p_scanner_id, 'expired', 
            'Ticket not valid at this time',
            v_ticket.id, v_ticket.event_id, p_device_fingerprint, p_location, p_ip_address, p_user_agent
        );
        
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
    
    -- Log successful scan
    PERFORM public.log_scan_attempt(
        p_ticket_code, p_scanner_id, 'success', 
        'Ticket validated successfully',
        v_ticket.id, v_ticket.event_id, p_device_fingerprint, p_location, p_ip_address, p_user_agent
    );
    
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

-- Function to detect suspicious scanning patterns
CREATE OR REPLACE FUNCTION public.detect_suspicious_scanning(
    p_device_fingerprint TEXT,
    p_time_window INTERVAL DEFAULT '5 minutes'
)
RETURNS TABLE (
    failed_attempts INTEGER,
    different_events INTEGER,
    is_suspicious BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*)::INTEGER as failed_attempts,
        COUNT(DISTINCT event_id)::INTEGER as different_events,
        (COUNT(*) > 10 OR COUNT(DISTINCT event_id) > 3) as is_suspicious
    FROM public.scan_attempts
    WHERE 
        device_fingerprint = p_device_fingerprint
        AND scan_result != 'success'
        AND created_at > NOW() - p_time_window;
END;
$$ LANGUAGE plpgsql;

-- Function to get scan analytics for an event
CREATE OR REPLACE FUNCTION public.get_event_scan_analytics(
    p_event_id UUID
)
RETURNS JSONB AS $$
DECLARE
    v_analytics JSONB;
    v_scan_results JSONB;
    v_hourly_pattern JSONB;
BEGIN
    -- Get scan results breakdown
    SELECT jsonb_object_agg(scan_result, count)
    INTO v_scan_results
    FROM (
        SELECT scan_result, COUNT(*) as count
        FROM public.scan_attempts
        WHERE event_id = p_event_id
        GROUP BY scan_result
    ) s;
    
    -- Get hourly pattern
    SELECT jsonb_agg(hourly_data)
    INTO v_hourly_pattern
    FROM (
        SELECT 
            EXTRACT(HOUR FROM created_at) as hour,
            COUNT(*) as scans
        FROM public.scan_attempts
        WHERE event_id = p_event_id AND scan_result = 'success'
        GROUP BY EXTRACT(HOUR FROM created_at)
        ORDER BY hour
    ) hourly_data;
    
    -- Build final analytics
    SELECT jsonb_build_object(
        'total_scans', COUNT(*),
        'successful_scans', COUNT(*) FILTER (WHERE scan_result = 'success'),
        'failed_scans', COUNT(*) FILTER (WHERE scan_result != 'success'),
        'unique_scanners', COUNT(DISTINCT scanner_id),
        'scan_results', COALESCE(v_scan_results, '{}'::jsonb),
        'hourly_pattern', COALESCE(v_hourly_pattern, '[]'::jsonb),
        'peak_hour', (
            SELECT EXTRACT(HOUR FROM created_at)::INTEGER
            FROM public.scan_attempts
            WHERE event_id = p_event_id AND scan_result = 'success'
            GROUP BY EXTRACT(HOUR FROM created_at)
            ORDER BY COUNT(*) DESC
            LIMIT 1
        )
    ) INTO v_analytics
    FROM public.scan_attempts
    WHERE event_id = p_event_id;
    
    RETURN v_analytics;
END;
$$ LANGUAGE plpgsql;