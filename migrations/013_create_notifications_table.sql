-- Create notifications table for user communications
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    type TEXT CHECK (type IN (
        'order_confirmation', 
        'event_reminder', 
        'ticket_transfer', 
        'event_update', 
        'marketing',
        'waitlist_alert',
        'refund_processed',
        'scanner_added'
    )) NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    data JSONB DEFAULT '{}'::jsonb,
    channel TEXT CHECK (channel IN ('push', 'sms', 'email', 'in_app')) NOT NULL,
    status TEXT CHECK (status IN ('pending', 'sent', 'failed', 'read')) DEFAULT 'pending',
    sent_at TIMESTAMPTZ,
    read_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ,
    priority TEXT CHECK (priority IN ('low', 'normal', 'high')) DEFAULT 'normal'
);

-- Create indexes for performance
CREATE INDEX idx_notifications_user_id ON public.notifications(user_id);
CREATE INDEX idx_notifications_status ON public.notifications(status);
CREATE INDEX idx_notifications_type ON public.notifications(type);
CREATE INDEX idx_notifications_created_at ON public.notifications(created_at DESC);
CREATE INDEX idx_notifications_unread ON public.notifications(user_id, status) WHERE status != 'read';

-- Enable Row Level Security
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- Create policies for notifications table
-- Users can view their own notifications
CREATE POLICY "Users can view own notifications" ON public.notifications
    FOR SELECT USING (user_id = auth.uid());

-- Users can update their own notifications (mark as read)
CREATE POLICY "Users can update own notifications" ON public.notifications
    FOR UPDATE USING (user_id = auth.uid());

-- System can create notifications
CREATE POLICY "System can create notifications" ON public.notifications
    FOR INSERT WITH CHECK (true);

-- Enable realtime for in-app notifications
ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;

-- Function to create notification
CREATE OR REPLACE FUNCTION public.create_notification(
    p_user_id UUID,
    p_type TEXT,
    p_title VARCHAR(255),
    p_message TEXT,
    p_channel TEXT,
    p_data JSONB DEFAULT '{}'::jsonb,
    p_priority TEXT DEFAULT 'normal'
)
RETURNS UUID AS $$
DECLARE
    v_notification_id UUID;
    v_user_preferences JSONB;
BEGIN
    -- Get user notification preferences
    SELECT notification_preferences INTO v_user_preferences
    FROM public.profiles
    WHERE id = p_user_id;
    
    -- Check if user wants this type of notification
    IF v_user_preferences IS NOT NULL AND 
       v_user_preferences->p_channel = false THEN
        -- User has disabled this channel
        RETURN NULL;
    END IF;
    
    -- Create notification
    INSERT INTO public.notifications (
        user_id,
        type,
        title,
        message,
        channel,
        data,
        priority,
        expires_at
    ) VALUES (
        p_user_id,
        p_type,
        p_title,
        p_message,
        p_channel,
        p_data,
        p_priority,
        CASE 
            WHEN p_type = 'event_reminder' THEN NOW() + INTERVAL '7 days'
            WHEN p_type = 'marketing' THEN NOW() + INTERVAL '30 days'
            ELSE NOW() + INTERVAL '90 days'
        END
    ) RETURNING id INTO v_notification_id;
    
    -- Queue for sending (in real implementation, this would trigger a job)
    -- For now, we'll just mark it as ready to send
    
    RETURN v_notification_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to send order confirmation
CREATE OR REPLACE FUNCTION public.notify_order_confirmation(
    p_order_id UUID
)
RETURNS VOID AS $$
DECLARE
    v_order RECORD;
    v_event RECORD;
    v_tickets_count INTEGER;
BEGIN
    -- Get order and event details
    SELECT o.*, e.title as event_title, e.event_date, e.venue_name
    INTO v_order
    FROM public.orders o
    JOIN public.events e ON e.id = o.event_id
    WHERE o.id = p_order_id;
    
    -- Create notifications for different channels
    -- Email notification
    PERFORM public.create_notification(
        v_order.user_id,
        'order_confirmation',
        'Ticket Purchase Confirmed - ' || v_order.event_title,
        'Your order ' || v_order.order_number || ' for ' || v_order.ticket_count || 
        ' ticket(s) to ' || v_order.event_title || ' has been confirmed.',
        'email',
        jsonb_build_object(
            'order_id', p_order_id,
            'order_number', v_order.order_number,
            'event_date', v_order.event_date,
            'venue', v_order.venue_name,
            'amount', v_order.total_amount
        )
    );
    
    -- SMS notification
    PERFORM public.create_notification(
        v_order.user_id,
        'order_confirmation',
        'NOXXI Order Confirmed',
        'Order ' || v_order.order_number || ' confirmed. ' || v_order.ticket_count || 
        ' ticket(s) for ' || v_order.event_title || '. Check email for details.',
        'sms',
        jsonb_build_object('order_id', p_order_id)
    );
    
    -- In-app notification
    PERFORM public.create_notification(
        v_order.user_id,
        'order_confirmation',
        'Purchase Successful! 🎉',
        'Your tickets for ' || v_order.event_title || ' are ready',
        'in_app',
        jsonb_build_object('order_id', p_order_id)
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to send event reminders
CREATE OR REPLACE FUNCTION public.send_event_reminders(
    p_hours_before INTEGER DEFAULT 24
)
RETURNS INTEGER AS $$
DECLARE
    v_reminder_count INTEGER := 0;
    v_ticket RECORD;
BEGIN
    -- Find tickets for events happening soon
    FOR v_ticket IN 
        SELECT DISTINCT ON (t.user_id, t.event_id)
            t.user_id,
            t.event_id,
            e.title,
            e.event_date,
            e.venue_name,
            e.venue_address
        FROM public.tickets t
        JOIN public.events e ON e.id = t.event_id
        WHERE t.status = 'valid'
        AND e.event_date BETWEEN NOW() + (p_hours_before - 1 || ' hours')::INTERVAL 
                            AND NOW() + (p_hours_before + 1 || ' hours')::INTERVAL
        AND NOT EXISTS (
            -- Don't send if already sent a reminder
            SELECT 1 FROM public.notifications n
            WHERE n.user_id = t.user_id
            AND n.type = 'event_reminder'
            AND n.data->>'event_id' = t.event_id::TEXT
            AND n.created_at > NOW() - INTERVAL '48 hours'
        )
    LOOP
        -- Create reminder notification
        PERFORM public.create_notification(
            v_ticket.user_id,
            'event_reminder',
            'Event Tomorrow: ' || v_ticket.title,
            'Don''t forget! ' || v_ticket.title || ' is tomorrow at ' || 
            TO_CHAR(v_ticket.event_date, 'HH24:MI') || ' at ' || v_ticket.venue_name,
            'push',
            jsonb_build_object(
                'event_id', v_ticket.event_id,
                'event_date', v_ticket.event_date,
                'venue', v_ticket.venue_name
            ),
            'high'
        );
        
        v_reminder_count := v_reminder_count + 1;
    END LOOP;
    
    RETURN v_reminder_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to mark notification as read
CREATE OR REPLACE FUNCTION public.mark_notification_read(
    p_notification_id UUID
)
RETURNS VOID AS $$
BEGIN
    UPDATE public.notifications
    SET 
        status = 'read',
        read_at = NOW()
    WHERE id = p_notification_id
    AND user_id = auth.uid()
    AND status != 'read';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to mark all notifications as read
CREATE OR REPLACE FUNCTION public.mark_all_notifications_read()
RETURNS INTEGER AS $$
DECLARE
    v_updated_count INTEGER;
BEGIN
    UPDATE public.notifications
    SET 
        status = 'read',
        read_at = NOW()
    WHERE user_id = auth.uid()
    AND status = 'sent'
    AND channel = 'in_app';
    
    GET DIAGNOSTICS v_updated_count = ROW_COUNT;
    
    RETURN v_updated_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get unread notification count
CREATE OR REPLACE FUNCTION public.get_unread_notification_count()
RETURNS INTEGER AS $$
BEGIN
    RETURN (
        SELECT COUNT(*)::INTEGER
        FROM public.notifications
        WHERE user_id = auth.uid()
        AND status = 'sent'
        AND channel = 'in_app'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to clean up old notifications
CREATE OR REPLACE FUNCTION public.cleanup_old_notifications()
RETURNS INTEGER AS $$
DECLARE
    v_deleted_count INTEGER;
BEGIN
    DELETE FROM public.notifications
    WHERE (
        -- Delete expired notifications
        expires_at < NOW() OR
        -- Delete read notifications older than 30 days
        (status = 'read' AND read_at < NOW() - INTERVAL '30 days') OR
        -- Delete failed notifications older than 7 days
        (status = 'failed' AND created_at < NOW() - INTERVAL '7 days')
    );
    
    GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
    
    RETURN v_deleted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;