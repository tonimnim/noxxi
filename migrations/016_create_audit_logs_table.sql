-- Create audit_logs table for tracking system changes
CREATE TABLE IF NOT EXISTS public.audit_logs (
    id UUID DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id),
    action VARCHAR(100) NOT NULL,
    entity_type VARCHAR(50) NOT NULL,
    entity_id UUID,
    old_values JSONB,
    new_values JSONB,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    metadata JSONB DEFAULT '{}'::jsonb,
    session_id VARCHAR(100),
    request_id VARCHAR(100),
    PRIMARY KEY (id, created_at)
) PARTITION BY RANGE (created_at);

-- Create partitions for the next 12 months
DO $$
DECLARE
    start_date DATE := DATE_TRUNC('month', CURRENT_DATE);
    partition_date DATE;
    partition_name TEXT;
BEGIN
    FOR i IN 0..11 LOOP
        partition_date := start_date + (i || ' months')::INTERVAL;
        partition_name := 'audit_logs_' || TO_CHAR(partition_date, 'YYYY_MM');
        
        EXECUTE format(
            'CREATE TABLE IF NOT EXISTS public.%I PARTITION OF public.audit_logs
            FOR VALUES FROM (%L) TO (%L)',
            partition_name,
            partition_date,
            partition_date + INTERVAL '1 month'
        );
    END LOOP;
END $$;

-- Create indexes for performance
CREATE INDEX idx_audit_logs_user_id ON public.audit_logs(user_id);
CREATE INDEX idx_audit_logs_entity ON public.audit_logs(entity_type, entity_id);
CREATE INDEX idx_audit_logs_action ON public.audit_logs(action);
CREATE INDEX idx_audit_logs_created_at ON public.audit_logs(created_at DESC);

-- Enable Row Level Security
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

-- Create policies for audit_logs table
-- Only admins can view audit logs
CREATE POLICY "Admins can view audit logs" ON public.audit_logs
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM public.profiles WHERE user_id = auth.uid() AND role = 'admin')
    );

-- Users can view their own audit logs
CREATE POLICY "Users can view own audit logs" ON public.audit_logs
    FOR SELECT USING (user_id = auth.uid());

-- System can insert audit logs
CREATE POLICY "System can insert audit logs" ON public.audit_logs
    FOR INSERT WITH CHECK (true);

-- Function to log audit entry
CREATE OR REPLACE FUNCTION public.log_audit(
    p_action VARCHAR(100),
    p_entity_type VARCHAR(50),
    p_entity_id UUID DEFAULT NULL,
    p_old_values JSONB DEFAULT NULL,
    p_new_values JSONB DEFAULT NULL,
    p_metadata JSONB DEFAULT '{}'::jsonb
)
RETURNS UUID AS $$
DECLARE
    v_audit_id UUID;
    v_ip_address INET;
    v_user_agent TEXT;
BEGIN
    -- Get request context if available
    v_ip_address := NULLIF(current_setting('request.headers', true)::jsonb->>'x-forwarded-for', '')::INET;
    v_user_agent := current_setting('request.headers', true)::jsonb->>'user-agent';
    
    INSERT INTO public.audit_logs (
        user_id,
        action,
        entity_type,
        entity_id,
        old_values,
        new_values,
        ip_address,
        user_agent,
        metadata
    ) VALUES (
        auth.uid(),
        p_action,
        p_entity_type,
        p_entity_id,
        p_old_values,
        p_new_values,
        v_ip_address,
        v_user_agent,
        p_metadata
    ) RETURNING id INTO v_audit_id;
    
    RETURN v_audit_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Generic audit trigger function
CREATE OR REPLACE FUNCTION public.audit_trigger_function()
RETURNS TRIGGER AS $$
DECLARE
    v_old_values JSONB;
    v_new_values JSONB;
    v_action VARCHAR(100);
    v_entity_id UUID;
BEGIN
    -- Determine action
    CASE TG_OP
        WHEN 'INSERT' THEN
            v_action := TG_TABLE_NAME || '.created';
            v_new_values := to_jsonb(NEW);
            v_entity_id := NEW.id;
        WHEN 'UPDATE' THEN
            v_action := TG_TABLE_NAME || '.updated';
            v_old_values := to_jsonb(OLD);
            v_new_values := to_jsonb(NEW);
            v_entity_id := NEW.id;
        WHEN 'DELETE' THEN
            v_action := TG_TABLE_NAME || '.deleted';
            v_old_values := to_jsonb(OLD);
            v_entity_id := OLD.id;
    END CASE;
    
    -- Log audit entry
    PERFORM public.log_audit(
        v_action,
        TG_TABLE_NAME,
        v_entity_id,
        v_old_values,
        v_new_values,
        jsonb_build_object(
            'trigger_op', TG_OP,
            'trigger_name', TG_NAME
        )
    );
    
    RETURN CASE WHEN TG_OP = 'DELETE' THEN OLD ELSE NEW END;
END;
$$ LANGUAGE plpgsql;

-- Create audit triggers for important tables
CREATE TRIGGER audit_organizers
    AFTER INSERT OR UPDATE OR DELETE ON public.organizers
    FOR EACH ROW EXECUTE FUNCTION public.audit_trigger_function();

CREATE TRIGGER audit_events
    AFTER INSERT OR UPDATE OR DELETE ON public.events
    FOR EACH ROW EXECUTE FUNCTION public.audit_trigger_function();

CREATE TRIGGER audit_orders
    AFTER INSERT OR UPDATE ON public.orders
    FOR EACH ROW EXECUTE FUNCTION public.audit_trigger_function();

CREATE TRIGGER audit_transactions
    AFTER INSERT OR UPDATE ON public.transactions
    FOR EACH ROW EXECUTE FUNCTION public.audit_trigger_function();

CREATE TRIGGER audit_payouts
    AFTER INSERT OR UPDATE ON public.payouts
    FOR EACH ROW EXECUTE FUNCTION public.audit_trigger_function();

CREATE TRIGGER audit_platform_settings
    AFTER UPDATE OR DELETE ON public.platform_settings
    FOR EACH ROW EXECUTE FUNCTION public.audit_trigger_function();

-- Specific audit functions for critical actions

-- Function to audit login attempts
CREATE OR REPLACE FUNCTION public.audit_login_attempt(
    p_email VARCHAR(255),
    p_success BOOLEAN,
    p_failure_reason TEXT DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
    PERFORM public.log_audit(
        CASE WHEN p_success THEN 'auth.login.success' ELSE 'auth.login.failed' END,
        'auth',
        auth.uid(),
        NULL,
        NULL,
        jsonb_build_object(
            'email', p_email,
            'success', p_success,
            'failure_reason', p_failure_reason,
            'timestamp', NOW()
        )
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to audit ticket scanning
CREATE OR REPLACE FUNCTION public.audit_ticket_scan(
    p_ticket_id UUID,
    p_scan_result TEXT,
    p_scanner_id UUID
)
RETURNS VOID AS $$
BEGIN
    PERFORM public.log_audit(
        'ticket.scanned',
        'tickets',
        p_ticket_id,
        NULL,
        NULL,
        jsonb_build_object(
            'scan_result', p_scan_result,
            'scanner_id', p_scanner_id,
            'timestamp', NOW()
        )
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get audit history for an entity
CREATE OR REPLACE FUNCTION public.get_entity_audit_history(
    p_entity_type VARCHAR(50),
    p_entity_id UUID,
    p_limit INTEGER DEFAULT 50
)
RETURNS TABLE (
    id UUID,
    action VARCHAR(100),
    user_email VARCHAR(255),
    changes JSONB,
    created_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        al.id,
        al.action,
        p.email as user_email,
        CASE 
            WHEN al.old_values IS NOT NULL AND al.new_values IS NOT NULL THEN
                jsonb_build_object(
                    'old', al.old_values,
                    'new', al.new_values,
                    'diff', (
                        SELECT jsonb_object_agg(key, value)
                        FROM jsonb_each(al.new_values)
                        WHERE al.old_values->key IS DISTINCT FROM value
                    )
                )
            WHEN al.new_values IS NOT NULL THEN
                jsonb_build_object('created', al.new_values)
            WHEN al.old_values IS NOT NULL THEN
                jsonb_build_object('deleted', al.old_values)
            ELSE NULL
        END as changes,
        al.created_at
    FROM public.audit_logs al
    LEFT JOIN public.profiles p ON p.user_id = al.user_id
    WHERE al.entity_type = p_entity_type
    AND al.entity_id = p_entity_id
    ORDER BY al.created_at DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- Function to search audit logs
CREATE OR REPLACE FUNCTION public.search_audit_logs(
    p_user_id UUID DEFAULT NULL,
    p_action VARCHAR(100) DEFAULT NULL,
    p_entity_type VARCHAR(50) DEFAULT NULL,
    p_start_date TIMESTAMPTZ DEFAULT NOW() - INTERVAL '30 days',
    p_end_date TIMESTAMPTZ DEFAULT NOW(),
    p_limit INTEGER DEFAULT 100
)
RETURNS TABLE (
    id UUID,
    user_email VARCHAR(255),
    action VARCHAR(100),
    entity_type VARCHAR(50),
    entity_id UUID,
    metadata JSONB,
    created_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        al.id,
        p.email as user_email,
        al.action,
        al.entity_type,
        al.entity_id,
        al.metadata,
        al.created_at
    FROM public.audit_logs al
    LEFT JOIN public.profiles p ON p.user_id = al.user_id
    WHERE (p_user_id IS NULL OR al.user_id = p_user_id)
    AND (p_action IS NULL OR al.action ILIKE '%' || p_action || '%')
    AND (p_entity_type IS NULL OR al.entity_type = p_entity_type)
    AND al.created_at BETWEEN p_start_date AND p_end_date
    ORDER BY al.created_at DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- Function to clean up old audit logs
CREATE OR REPLACE FUNCTION public.cleanup_old_audit_logs(
    p_retention_days INTEGER DEFAULT 365
)
RETURNS INTEGER AS $$
DECLARE
    v_deleted_count INTEGER;
BEGIN
    DELETE FROM public.audit_logs
    WHERE created_at < NOW() - (p_retention_days || ' days')::INTERVAL;
    
    GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
    
    -- Log the cleanup action
    PERFORM public.log_audit(
        'audit.cleanup',
        'system',
        NULL,
        NULL,
        NULL,
        jsonb_build_object(
            'deleted_count', v_deleted_count,
            'retention_days', p_retention_days
        )
    );
    
    RETURN v_deleted_count;
END;
$$ LANGUAGE plpgsql;