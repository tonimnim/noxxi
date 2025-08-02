-- Create event_staff table for managing event helpers
CREATE TABLE IF NOT EXISTS public.event_staff (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    event_id UUID REFERENCES public.events(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    added_by UUID NOT NULL,
    role TEXT CHECK (role IN ('manager')) DEFAULT 'manager',
    can_scan BOOLEAN DEFAULT true,
    can_view_analytics BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    -- Ensure unique staff per event
    UNIQUE(event_id, user_id)
);

-- Create indexes for performance
CREATE INDEX idx_event_staff_event_id ON public.event_staff(event_id);
CREATE INDEX idx_event_staff_user_id ON public.event_staff(user_id);
CREATE INDEX idx_event_staff_added_by ON public.event_staff(added_by);
CREATE INDEX idx_event_staff_active ON public.event_staff(event_id, user_id) WHERE is_active = true;

-- Enable Row Level Security
ALTER TABLE public.event_staff ENABLE ROW LEVEL SECURITY;

-- Create policies for event_staff table
-- Staff can view their own assignments
CREATE POLICY "Staff can view own assignments" ON public.event_staff
    FOR SELECT USING (user_id = auth.uid());

-- Organizers can view and manage staff for their events
CREATE POLICY "Organizers can manage event staff" ON public.event_staff
    FOR ALL USING (
        event_id IN (
            SELECT e.id FROM public.events e
            JOIN public.organizers o ON o.id = e.organizer_id
            WHERE o.user_id = auth.uid()
        )
    );

-- Enable realtime
ALTER PUBLICATION supabase_realtime ADD TABLE public.event_staff;

-- Function to validate staff assignment
CREATE OR REPLACE FUNCTION public.validate_event_staff()
RETURNS TRIGGER AS $$
DECLARE
    v_organizer_id UUID;
    v_is_organizer BOOLEAN;
BEGIN
    -- Get the organizer_id for this event
    SELECT e.organizer_id INTO v_organizer_id
    FROM public.events e
    WHERE e.id = NEW.event_id;
    
    -- Check if added_by is the organizer
    SELECT EXISTS (
        SELECT 1 FROM public.organizers o
        WHERE o.id = v_organizer_id AND o.user_id = NEW.added_by
    ) INTO v_is_organizer;
    
    IF NOT v_is_organizer THEN
        RAISE EXCEPTION 'Only event organizers can add staff';
    END IF;
    
    -- Set added_by to organizer_id (not user_id) for consistency
    NEW.added_by = v_organizer_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to send staff invitation (placeholder for notification)
CREATE OR REPLACE FUNCTION public.invite_event_staff(
    p_event_id UUID,
    p_email VARCHAR(255),
    p_phone_number VARCHAR(20),
    p_can_scan BOOLEAN DEFAULT true,
    p_can_view_analytics BOOLEAN DEFAULT false
)
RETURNS JSONB AS $$
DECLARE
    v_user_id UUID;
    v_staff_id UUID;
    v_event_title TEXT;
    v_organizer_name TEXT;
BEGIN
    -- Check if user exists by email or phone
    SELECT id INTO v_user_id
    FROM public.profiles
    WHERE email = p_email OR phone_number = p_phone_number
    LIMIT 1;
    
    IF v_user_id IS NULL THEN
        -- User doesn't exist yet
        RETURN jsonb_build_object(
            'success', false,
            'message', 'User not found. They need to register first.',
            'action', 'send_invite'
        );
    END IF;
    
    -- Get event details
    SELECT e.title, o.business_name 
    INTO v_event_title, v_organizer_name
    FROM public.events e
    JOIN public.organizers o ON o.id = e.organizer_id
    WHERE e.id = p_event_id;
    
    -- Add staff member
    INSERT INTO public.event_staff (
        event_id,
        user_id,
        added_by,
        can_scan,
        can_view_analytics
    ) VALUES (
        p_event_id,
        v_user_id,
        auth.uid(),
        p_can_scan,
        p_can_view_analytics
    ) RETURNING id INTO v_staff_id;
    
    -- TODO: Send notification to user about being added as staff
    
    RETURN jsonb_build_object(
        'success', true,
        'staff_id', v_staff_id,
        'message', 'Staff member added successfully'
    );
    
EXCEPTION WHEN unique_violation THEN
    RETURN jsonb_build_object(
        'success', false,
        'message', 'User is already a staff member for this event'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get staff permissions for an event
CREATE OR REPLACE FUNCTION public.get_user_event_permissions(
    p_user_id UUID,
    p_event_id UUID
)
RETURNS JSONB AS $$
DECLARE
    v_permissions JSONB;
    v_is_organizer BOOLEAN;
    v_is_staff BOOLEAN;
    v_staff_permissions RECORD;
BEGIN
    -- Check if user is the organizer
    SELECT EXISTS (
        SELECT 1 FROM public.events e
        JOIN public.organizers o ON o.id = e.organizer_id
        WHERE e.id = p_event_id AND o.user_id = p_user_id
    ) INTO v_is_organizer;
    
    IF v_is_organizer THEN
        -- Organizer has all permissions
        RETURN jsonb_build_object(
            'is_organizer', true,
            'can_scan', true,
            'can_view_analytics', true,
            'can_manage_staff', true,
            'can_edit_event', true
        );
    END IF;
    
    -- Check if user is staff
    SELECT can_scan, can_view_analytics, is_active
    INTO v_staff_permissions
    FROM public.event_staff
    WHERE event_id = p_event_id AND user_id = p_user_id AND is_active = true;
    
    IF FOUND THEN
        RETURN jsonb_build_object(
            'is_organizer', false,
            'is_staff', true,
            'can_scan', v_staff_permissions.can_scan,
            'can_view_analytics', v_staff_permissions.can_view_analytics,
            'can_manage_staff', false,
            'can_edit_event', false
        );
    END IF;
    
    -- Regular user
    RETURN jsonb_build_object(
        'is_organizer', false,
        'is_staff', false,
        'can_scan', false,
        'can_view_analytics', false,
        'can_manage_staff', false,
        'can_edit_event', false
    );
END;
$$ LANGUAGE plpgsql;

-- Triggers
CREATE TRIGGER validate_event_staff_trigger
    BEFORE INSERT ON public.event_staff
    FOR EACH ROW
    EXECUTE FUNCTION public.validate_event_staff();

CREATE TRIGGER handle_event_staff_updated_at
    BEFORE UPDATE ON public.event_staff
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();