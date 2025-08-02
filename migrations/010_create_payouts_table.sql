-- Create payouts table for organizer payments
CREATE TABLE IF NOT EXISTS public.payouts (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    organizer_id UUID REFERENCES public.organizers(id) ON DELETE RESTRICT NOT NULL,
    amount DECIMAL(15,2) NOT NULL CHECK (amount > 0),
    currency VARCHAR(3) DEFAULT 'KES',
    method TEXT CHECK (method IN ('mpesa', 'bank_transfer')) NOT NULL,
    reference_number VARCHAR(100) UNIQUE,
    status TEXT CHECK (status IN ('pending', 'processing', 'completed', 'failed')) DEFAULT 'pending',
    failure_reason TEXT,
    initiated_by UUID REFERENCES public.profiles(id) NOT NULL,
    processed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    metadata JSONB DEFAULT '{}'::jsonb
);

-- Create indexes for performance
CREATE INDEX idx_payouts_organizer_id ON public.payouts(organizer_id);
CREATE INDEX idx_payouts_status ON public.payouts(status);
CREATE INDEX idx_payouts_created_at ON public.payouts(created_at DESC);
CREATE INDEX idx_payouts_reference_number ON public.payouts(reference_number) WHERE reference_number IS NOT NULL;

-- Enable Row Level Security
ALTER TABLE public.payouts ENABLE ROW LEVEL SECURITY;

-- Create policies for payouts table
-- Organizers can view their own payouts
CREATE POLICY "Organizers can view own payouts" ON public.payouts
    FOR SELECT USING (
        organizer_id IN (SELECT id FROM public.organizers WHERE user_id = auth.uid()) OR
        EXISTS (SELECT 1 FROM public.profiles WHERE user_id = auth.uid() AND role = 'admin')
    );

-- Only admins can create payouts
CREATE POLICY "Admins can create payouts" ON public.payouts
    FOR INSERT WITH CHECK (
        EXISTS (SELECT 1 FROM public.profiles WHERE user_id = auth.uid() AND role = 'admin')
    );

-- Only admins can update payouts
CREATE POLICY "Admins can update payouts" ON public.payouts
    FOR UPDATE USING (
        EXISTS (SELECT 1 FROM public.profiles WHERE user_id = auth.uid() AND role = 'admin')
    );

-- Enable realtime for payout updates
ALTER PUBLICATION supabase_realtime ADD TABLE public.payouts;

-- Function to generate payout reference
CREATE OR REPLACE FUNCTION public.generate_payout_reference()
RETURNS TEXT AS $$
DECLARE
    new_ref TEXT;
    ref_exists BOOLEAN;
BEGIN
    LOOP
        -- Generate reference: PO + YYMMDD + 6 random digits
        new_ref := 'PO' || TO_CHAR(NOW(), 'YYMMDD') || LPAD(FLOOR(RANDOM() * 1000000)::TEXT, 6, '0');
        
        -- Check if exists
        SELECT EXISTS(SELECT 1 FROM public.payouts WHERE reference_number = new_ref) INTO ref_exists;
        
        EXIT WHEN NOT ref_exists;
    END LOOP;
    
    RETURN new_ref;
END;
$$ LANGUAGE plpgsql;

-- Function to create payout
CREATE OR REPLACE FUNCTION public.create_payout(
    p_organizer_id UUID,
    p_amount DECIMAL(15,2),
    p_method TEXT,
    p_initiated_by UUID DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_payout_id UUID;
    v_balance RECORD;
    v_organizer RECORD;
    v_reference TEXT;
BEGIN
    -- Use current user if initiated_by not provided
    IF p_initiated_by IS NULL THEN
        p_initiated_by := auth.uid();
    END IF;
    
    -- Get organizer balance
    SELECT * FROM public.get_organizer_balance(p_organizer_id) INTO v_balance;
    
    -- Validate sufficient balance
    IF p_amount > v_balance.available_balance THEN
        RAISE EXCEPTION 'Insufficient balance. Available: %, Requested: %', 
            v_balance.available_balance, p_amount;
    END IF;
    
    -- Get organizer details
    SELECT * INTO v_organizer FROM public.organizers WHERE id = p_organizer_id;
    
    -- Validate payment method
    IF p_method = 'mpesa' AND (v_organizer.mpesa_till_number IS NULL AND v_organizer.mpesa_paybill IS NULL) THEN
        RAISE EXCEPTION 'M-Pesa details not configured for this organizer';
    END IF;
    
    IF p_method = 'bank_transfer' AND v_organizer.bank_account_details IS NULL THEN
        RAISE EXCEPTION 'Bank details not configured for this organizer';
    END IF;
    
    -- Generate reference
    v_reference := public.generate_payout_reference();
    
    -- Create payout record
    INSERT INTO public.payouts (
        organizer_id,
        amount,
        method,
        reference_number,
        initiated_by,
        metadata
    ) VALUES (
        p_organizer_id,
        p_amount,
        p_method,
        v_reference,
        p_initiated_by,
        jsonb_build_object(
            'available_balance_before', v_balance.available_balance,
            'payment_details', CASE 
                WHEN p_method = 'mpesa' THEN jsonb_build_object(
                    'till_number', v_organizer.mpesa_till_number,
                    'paybill', v_organizer.mpesa_paybill
                )
                ELSE v_organizer.bank_account_details
            END
        )
    ) RETURNING id INTO v_payout_id;
    
    -- Create transaction record
    INSERT INTO public.transactions (
        type,
        organizer_id,
        amount,
        payment_method,
        payment_reference,
        status,
        metadata
    ) VALUES (
        'payout',
        p_organizer_id,
        p_amount,
        p_method,
        v_reference,
        'pending',
        jsonb_build_object('payout_id', v_payout_id)
    );
    
    RETURN v_payout_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to process payout (called by payment processor)
CREATE OR REPLACE FUNCTION public.process_payout(
    p_payout_id UUID,
    p_success BOOLEAN,
    p_external_reference TEXT DEFAULT NULL,
    p_failure_reason TEXT DEFAULT NULL
)
RETURNS VOID AS $$
DECLARE
    v_payout RECORD;
BEGIN
    -- Get payout details
    SELECT * INTO v_payout FROM public.payouts WHERE id = p_payout_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Payout not found';
    END IF;
    
    IF v_payout.status != 'pending' AND v_payout.status != 'processing' THEN
        RAISE EXCEPTION 'Payout already processed';
    END IF;
    
    IF p_success THEN
        -- Update payout as completed
        UPDATE public.payouts
        SET 
            status = 'completed',
            processed_at = NOW(),
            reference_number = COALESCE(p_external_reference, reference_number),
            updated_at = NOW()
        WHERE id = p_payout_id;
        
        -- Update transaction
        UPDATE public.transactions
        SET 
            status = 'completed',
            processed_at = NOW()
        WHERE payment_reference = v_payout.reference_number;
    ELSE
        -- Update payout as failed
        UPDATE public.payouts
        SET 
            status = 'failed',
            failure_reason = p_failure_reason,
            processed_at = NOW(),
            updated_at = NOW()
        WHERE id = p_payout_id;
        
        -- Update transaction
        UPDATE public.transactions
        SET 
            status = 'failed',
            processed_at = NOW()
        WHERE payment_reference = v_payout.reference_number;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get payout summary
CREATE OR REPLACE FUNCTION public.get_payout_summary(
    p_start_date DATE DEFAULT CURRENT_DATE - INTERVAL '30 days',
    p_end_date DATE DEFAULT CURRENT_DATE
)
RETURNS TABLE (
    total_payouts DECIMAL,
    successful_payouts INTEGER,
    failed_payouts INTEGER,
    pending_payouts INTEGER,
    average_payout DECIMAL,
    by_method JSONB
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COALESCE(SUM(CASE WHEN status = 'completed' THEN amount ELSE 0 END), 0) as total_payouts,
        COUNT(CASE WHEN status = 'completed' THEN 1 END)::INTEGER as successful_payouts,
        COUNT(CASE WHEN status = 'failed' THEN 1 END)::INTEGER as failed_payouts,
        COUNT(CASE WHEN status IN ('pending', 'processing') THEN 1 END)::INTEGER as pending_payouts,
        COALESCE(AVG(CASE WHEN status = 'completed' THEN amount END), 0) as average_payout,
        jsonb_object_agg(method, method_count) as by_method
    FROM (
        SELECT 
            method,
            COUNT(*) as method_count
        FROM public.payouts
        WHERE DATE(created_at) BETWEEN p_start_date AND p_end_date
        AND status = 'completed'
        GROUP BY method
    ) method_stats,
    (SELECT * FROM public.payouts WHERE DATE(created_at) BETWEEN p_start_date AND p_end_date) p;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update updated_at
CREATE TRIGGER handle_payouts_updated_at
    BEFORE UPDATE ON public.payouts
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();