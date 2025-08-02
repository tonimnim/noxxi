-- Create orders table
CREATE TABLE IF NOT EXISTS public.orders (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    order_number VARCHAR(20) UNIQUE NOT NULL,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    event_id UUID REFERENCES public.events(id) ON DELETE RESTRICT NOT NULL,
    ticket_count INTEGER NOT NULL CHECK (ticket_count > 0),
    subtotal DECIMAL(10,2) NOT NULL,
    service_fee DECIMAL(10,2) NOT NULL,
    payment_fee DECIMAL(10,2) DEFAULT 0,
    discount_amount DECIMAL(10,2) DEFAULT 0,
    total_amount DECIMAL(10,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'KES',
    status TEXT CHECK (status IN ('pending', 'processing', 'paid', 'failed', 'refunded', 'cancelled')) DEFAULT 'pending',
    payment_method TEXT CHECK (payment_method IN ('mpesa', 'card', 'bank_transfer', 'cash')),
    payment_reference VARCHAR(100),
    mpesa_receipt_number VARCHAR(50),
    promo_code VARCHAR(50),
    buyer_info JSONB DEFAULT '{}'::jsonb,
    ip_address INET,
    user_agent TEXT,
    expires_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '15 minutes'),
    paid_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX idx_orders_order_number ON public.orders(order_number);
CREATE INDEX idx_orders_user_id ON public.orders(user_id);
CREATE INDEX idx_orders_event_id ON public.orders(event_id);
CREATE INDEX idx_orders_status ON public.orders(status);
CREATE INDEX idx_orders_created_at ON public.orders(created_at DESC);
CREATE INDEX idx_orders_mpesa_receipt ON public.orders(mpesa_receipt_number) WHERE mpesa_receipt_number IS NOT NULL;

-- Enable Row Level Security
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;

-- Create policies for orders table
-- Users can view their own orders
CREATE POLICY "Users can view own orders" ON public.orders
    FOR SELECT USING (user_id = auth.uid() OR EXISTS (
        SELECT 1 FROM public.organizers o
        JOIN public.events e ON e.organizer_id = o.id
        WHERE e.id = orders.event_id AND o.user_id = auth.uid()
    ));

-- Users can create orders
CREATE POLICY "Users can create orders" ON public.orders
    FOR INSERT WITH CHECK (user_id = auth.uid());

-- System can update orders (for payment processing)
CREATE POLICY "System can update orders" ON public.orders
    FOR UPDATE USING (true);

-- Enable realtime for order status updates
ALTER PUBLICATION supabase_realtime ADD TABLE public.orders;

-- Function to generate unique order number
CREATE OR REPLACE FUNCTION public.generate_order_number()
RETURNS TEXT AS $$
DECLARE
    new_number TEXT;
    number_exists BOOLEAN;
BEGIN
    LOOP
        -- Generate order number: NX + YYMMDD + 6 random digits
        new_number := 'NX' || TO_CHAR(NOW(), 'YYMMDD') || LPAD(FLOOR(RANDOM() * 1000000)::TEXT, 6, '0');
        
        -- Check if exists
        SELECT EXISTS(SELECT 1 FROM public.orders WHERE order_number = new_number) INTO number_exists;
        
        EXIT WHEN NOT number_exists;
    END LOOP;
    
    RETURN new_number;
END;
$$ LANGUAGE plpgsql;

-- Trigger to generate order number
CREATE OR REPLACE FUNCTION public.handle_new_order()
RETURNS TRIGGER AS $$
BEGIN
    -- Generate order number if not provided
    IF NEW.order_number IS NULL THEN
        NEW.order_number = public.generate_order_number();
    END IF;
    
    -- Calculate total amount
    NEW.total_amount = NEW.subtotal + NEW.service_fee + COALESCE(NEW.payment_fee, 0) - COALESCE(NEW.discount_amount, 0);
    
    -- Ensure total is not negative
    IF NEW.total_amount < 0 THEN
        NEW.total_amount = 0;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to handle order expiry
CREATE OR REPLACE FUNCTION public.expire_pending_orders()
RETURNS void AS $$
BEGIN
    UPDATE public.orders
    SET 
        status = 'cancelled',
        updated_at = NOW()
    WHERE 
        status = 'pending' 
        AND expires_at < NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to calculate fees (10% service fee)
CREATE OR REPLACE FUNCTION public.calculate_order_fees(
    p_subtotal DECIMAL,
    p_payment_method TEXT
) RETURNS TABLE (
    service_fee DECIMAL,
    payment_fee DECIMAL
) AS $$
BEGIN
    -- 10% service fee
    service_fee := ROUND(p_subtotal * 0.10, 2);
    
    -- Payment method fees
    CASE p_payment_method
        WHEN 'mpesa' THEN payment_fee := GREATEST(ROUND(p_subtotal * 0.015, 2), 10); -- 1.5% min 10 KES
        WHEN 'card' THEN payment_fee := ROUND(p_subtotal * 0.029, 2); -- 2.9%
        ELSE payment_fee := 0;
    END CASE;
    
    RETURN QUERY SELECT service_fee, payment_fee;
END;
$$ LANGUAGE plpgsql;

-- Create triggers
CREATE TRIGGER handle_new_order_trigger
    BEFORE INSERT ON public.orders
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_order();

CREATE TRIGGER handle_orders_updated_at
    BEFORE UPDATE ON public.orders
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- Create a scheduled function to expire old pending orders (call this from a cron job)
-- In Supabase, you'd set this up in the dashboard under SQL Functions