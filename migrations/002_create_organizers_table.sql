-- Create organizers table for event organizers
CREATE TABLE IF NOT EXISTS public.organizers (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL UNIQUE,
    business_name VARCHAR(255) NOT NULL,
    business_phone VARCHAR(20),
    business_email VARCHAR(255),
    mpesa_till_number VARCHAR(20),
    mpesa_paybill VARCHAR(20),
    bank_account_details JSONB,
    tax_pin VARCHAR(50),
    business_registration_no VARCHAR(100),
    verification_status TEXT CHECK (verification_status IN ('pending', 'verified', 'suspended')) DEFAULT 'pending' NOT NULL,
    verification_documents JSONB,
    total_events INTEGER DEFAULT 0,
    total_tickets_sold INTEGER DEFAULT 0,
    total_revenue DECIMAL(15,2) DEFAULT 0,
    rating DECIMAL(3,2),
    can_scan BOOLEAN DEFAULT true,
    api_key VARCHAR(255) UNIQUE,
    webhook_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    approved_at TIMESTAMPTZ,
    approved_by UUID REFERENCES public.profiles(id)
);

-- Create indexes for better performance
CREATE INDEX idx_organizers_user_id ON public.organizers(user_id);
CREATE INDEX idx_organizers_verification_status ON public.organizers(verification_status);
CREATE INDEX idx_organizers_api_key ON public.organizers(api_key);

-- Enable Row Level Security
ALTER TABLE public.organizers ENABLE ROW LEVEL SECURITY;

-- Create policies for organizers table
-- Organizers can view their own data
CREATE POLICY "Organizers can view own data" ON public.organizers
    FOR SELECT USING (
        auth.uid() = user_id OR
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.user_id = auth.uid() AND profiles.role = 'admin'
        )
    );

-- Organizers can update their own data (except verification status)
CREATE POLICY "Organizers can update own data" ON public.organizers
    FOR UPDATE USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Only admins can insert new organizers
CREATE POLICY "Admins can create organizers" ON public.organizers
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.user_id = auth.uid() AND profiles.role = 'admin'
        )
    );

-- Enable realtime
ALTER PUBLICATION supabase_realtime ADD TABLE public.organizers;

-- Function to generate unique API key
CREATE OR REPLACE FUNCTION public.generate_api_key()
RETURNS TEXT AS $$
DECLARE
    new_key TEXT;
    key_exists BOOLEAN;
BEGIN
    LOOP
        -- Generate a random API key with prefix
        new_key := 'noxxi_live_' || encode(gen_random_bytes(32), 'hex');
        
        -- Check if key already exists
        SELECT EXISTS(SELECT 1 FROM public.organizers WHERE api_key = new_key) INTO key_exists;
        
        -- Exit loop if unique key found
        EXIT WHEN NOT key_exists;
    END LOOP;
    
    RETURN new_key;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update organizer stats (called after ticket sales)
CREATE OR REPLACE FUNCTION public.update_organizer_stats()
RETURNS TRIGGER AS $$
BEGIN
    -- This function will be used later when we create the tickets table
    -- Placeholder for now
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update profile role when organizer is approved
CREATE OR REPLACE FUNCTION public.handle_organizer_approval()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.verification_status = 'verified' AND OLD.verification_status != 'verified' THEN
        -- Update the user's role to organizer
        UPDATE public.profiles
        SET role = 'organizer'
        WHERE id = NEW.user_id;
        
        -- Set approval timestamp
        NEW.approved_at = NOW();
        
        -- Generate API key if not exists
        IF NEW.api_key IS NULL THEN
            NEW.api_key = public.generate_api_key();
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for organizer approval
CREATE TRIGGER on_organizer_status_change
    BEFORE UPDATE ON public.organizers
    FOR EACH ROW
    WHEN (OLD.verification_status IS DISTINCT FROM NEW.verification_status)
    EXECUTE FUNCTION public.handle_organizer_approval();