-- Create platform_settings table for global configuration
CREATE TABLE IF NOT EXISTS public.platform_settings (
    key VARCHAR(100) PRIMARY KEY,
    value JSONB NOT NULL,
    description TEXT,
    updated_by UUID REFERENCES public.profiles(id),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    category VARCHAR(50),
    is_sensitive BOOLEAN DEFAULT false
);

-- Create indexes for performance
CREATE INDEX idx_platform_settings_category ON public.platform_settings(category);
CREATE INDEX idx_platform_settings_updated_at ON public.platform_settings(updated_at DESC);

-- Enable Row Level Security
ALTER TABLE public.platform_settings ENABLE ROW LEVEL SECURITY;

-- Create policies for platform_settings table
-- Only admins can view settings
CREATE POLICY "Admins can view settings" ON public.platform_settings
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM public.profiles WHERE user_id = auth.uid() AND role = 'admin')
    );

-- Only admins can manage settings
CREATE POLICY "Admins can manage settings" ON public.platform_settings
    FOR ALL USING (
        EXISTS (SELECT 1 FROM public.profiles WHERE user_id = auth.uid() AND role = 'admin')
    );

-- Function to get setting value
CREATE OR REPLACE FUNCTION public.get_setting(
    p_key VARCHAR(100),
    p_default JSONB DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
    v_value JSONB;
BEGIN
    SELECT value INTO v_value
    FROM public.platform_settings
    WHERE key = p_key;
    
    RETURN COALESCE(v_value, p_default);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update setting
CREATE OR REPLACE FUNCTION public.update_setting(
    p_key VARCHAR(100),
    p_value JSONB,
    p_description TEXT DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
    INSERT INTO public.platform_settings (key, value, description, updated_by, updated_at)
    VALUES (p_key, p_value, p_description, auth.uid(), NOW())
    ON CONFLICT (key) DO UPDATE
    SET 
        value = EXCLUDED.value,
        description = COALESCE(EXCLUDED.description, platform_settings.description),
        updated_by = EXCLUDED.updated_by,
        updated_at = NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Insert default settings
INSERT INTO public.platform_settings (key, value, category, description, is_sensitive) VALUES
    -- Commission Settings
    ('commission_rate', '10.0'::jsonb, 'financial', 'Platform commission percentage on ticket sales', false),
    ('minimum_payout_amount', '1000'::jsonb, 'financial', 'Minimum amount in KES for organizer payouts', false),
    ('payout_schedule', '"weekly"'::jsonb, 'financial', 'Default payout schedule for organizers', false),
    
    -- Payment Settings
    ('payment_methods', '["mpesa", "card"]'::jsonb, 'payment', 'Enabled payment methods', false),
    ('mpesa_config', '{"environment": "sandbox", "shortcode": "", "passkey": ""}'::jsonb, 'payment', 'M-Pesa API configuration', true),
    ('payment_timeout_minutes', '15'::jsonb, 'payment', 'Payment timeout in minutes', false),
    
    -- Ticket Settings
    ('max_tickets_per_order', '10'::jsonb, 'tickets', 'Maximum tickets per order', false),
    ('ticket_transfer_enabled', 'true'::jsonb, 'tickets', 'Allow users to transfer tickets', false),
    ('refund_policy_days', '7'::jsonb, 'tickets', 'Days before event for refund eligibility', false),
    
    -- Notification Settings
    ('email_provider', '"sendgrid"'::jsonb, 'notifications', 'Email service provider', false),
    ('sms_provider', '"africastalking"'::jsonb, 'notifications', 'SMS service provider', false),
    ('notification_sender_email', '"tickets@noxxi.co.ke"'::jsonb, 'notifications', 'From email address', false),
    ('notification_sender_name', '"NOXXI Tickets"'::jsonb, 'notifications', 'From name for notifications', false),
    
    -- Feature Flags
    ('features', '{"waitlist": true, "ticket_transfer": true, "group_bookings": true}'::jsonb, 'features', 'Feature toggles', false),
    ('maintenance_mode', 'false'::jsonb, 'features', 'Enable maintenance mode', false),
    
    -- Limits
    ('organizer_verification_required', 'true'::jsonb, 'limits', 'Require organizer verification before creating events', false),
    ('max_events_per_organizer', '50'::jsonb, 'limits', 'Maximum active events per organizer', false),
    ('max_image_size_mb', '5'::jsonb, 'limits', 'Maximum image upload size in MB', false),
    
    -- Support Settings
    ('support_email', '"support@noxxi.co.ke"'::jsonb, 'support', 'Support email address', false),
    ('support_phone', '"+254700000000"'::jsonb, 'support', 'Support phone number', false),
    ('support_hours', '"Monday-Friday 9AM-6PM EAT"'::jsonb, 'support', 'Support hours', false),
    
    -- Analytics
    ('analytics_retention_days', '365'::jsonb, 'analytics', 'Days to retain analytics data', false),
    ('popular_events_threshold', '100'::jsonb, 'analytics', 'Minimum views to be considered popular', false)
ON CONFLICT (key) DO NOTHING;

-- Function to get all settings by category
CREATE OR REPLACE FUNCTION public.get_settings_by_category(
    p_category VARCHAR(50) DEFAULT NULL
)
RETURNS TABLE (
    key VARCHAR(100),
    value JSONB,
    description TEXT,
    category VARCHAR(50),
    updated_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ps.key,
        CASE WHEN ps.is_sensitive THEN '"[HIDDEN]"'::jsonb ELSE ps.value END as value,
        ps.description,
        ps.category,
        ps.updated_at
    FROM public.platform_settings ps
    WHERE p_category IS NULL OR ps.category = p_category
    ORDER BY ps.category, ps.key;
END;
$$ LANGUAGE plpgsql;

-- Function to validate and update commission rate
CREATE OR REPLACE FUNCTION public.update_commission_rate(
    p_new_rate DECIMAL
)
RETURNS VOID AS $$
BEGIN
    IF p_new_rate < 0 OR p_new_rate > 50 THEN
        RAISE EXCEPTION 'Commission rate must be between 0 and 50 percent';
    END IF;
    
    PERFORM public.update_setting(
        'commission_rate',
        to_jsonb(p_new_rate),
        'Platform commission percentage on ticket sales'
    );
END;
$$ LANGUAGE plpgsql;

-- Trigger to track setting changes
CREATE OR REPLACE FUNCTION public.handle_setting_update()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    NEW.updated_by = auth.uid();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER handle_platform_settings_update
    BEFORE UPDATE ON public.platform_settings
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_setting_update();