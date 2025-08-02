-- Enable PostGIS extension for location features
CREATE EXTENSION IF NOT EXISTS postgis;

-- Create events table
CREATE TABLE IF NOT EXISTS public.events (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    organizer_id UUID REFERENCES public.organizers(id) ON DELETE CASCADE NOT NULL,
    title VARCHAR(255) NOT NULL,
    slug VARCHAR(255) UNIQUE,
    description TEXT,
    category_id UUID REFERENCES public.event_categories(id) NOT NULL,
    venue_name VARCHAR(255),
    venue_address TEXT,
    venue_coordinates GEOGRAPHY(POINT, 4326),
    city VARCHAR(100),
    event_date TIMESTAMPTZ NOT NULL,
    end_date TIMESTAMPTZ,
    ticket_types JSONB DEFAULT '[]'::jsonb,
    total_capacity INTEGER NOT NULL,
    tickets_sold INTEGER DEFAULT 0,
    min_ticket_price DECIMAL(10,2),
    max_ticket_price DECIMAL(10,2),
    currency VARCHAR(3) DEFAULT 'KES',
    images JSONB DEFAULT '[]'::jsonb,
    cover_image_url TEXT,
    tags TEXT[] DEFAULT '{}',
    status TEXT CHECK (status IN ('draft', 'published', 'cancelled', 'postponed', 'completed')) DEFAULT 'draft',
    featured BOOLEAN DEFAULT false,
    featured_until TIMESTAMPTZ,
    requires_approval BOOLEAN DEFAULT false,
    age_restriction INTEGER,
    terms_conditions TEXT,
    refund_policy TEXT,
    offline_mode_data JSONB,
    seo_keywords TEXT[] DEFAULT '{}',
    view_count INTEGER DEFAULT 0,
    share_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    published_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX idx_events_organizer_id ON public.events(organizer_id);
CREATE INDEX idx_events_category_id ON public.events(category_id);
CREATE INDEX idx_events_slug ON public.events(slug);
CREATE INDEX idx_events_status ON public.events(status);
CREATE INDEX idx_events_event_date ON public.events(event_date);
CREATE INDEX idx_events_city ON public.events(city);
CREATE INDEX idx_events_featured ON public.events(featured) WHERE featured = true;
CREATE INDEX idx_events_venue_coordinates ON public.events USING GIST (venue_coordinates);
CREATE INDEX idx_events_tags ON public.events USING GIN (tags);
CREATE INDEX idx_events_search ON public.events USING GIN (to_tsvector('english', title || ' ' || COALESCE(description, '')));

-- Enable Row Level Security
ALTER TABLE public.events ENABLE ROW LEVEL SECURITY;

-- Create policies for events table
-- Anyone can view published events
CREATE POLICY "Anyone can view published events" ON public.events
    FOR SELECT USING (status = 'published' OR organizer_id IN (
        SELECT id FROM public.organizers WHERE user_id = auth.uid()
    ));

-- Organizers can create events
CREATE POLICY "Organizers can create events" ON public.events
    FOR INSERT WITH CHECK (
        organizer_id IN (
            SELECT id FROM public.organizers 
            WHERE user_id = auth.uid() AND verification_status = 'verified'
        )
    );

-- Organizers can update their own events
CREATE POLICY "Organizers can update own events" ON public.events
    FOR UPDATE USING (
        organizer_id IN (
            SELECT id FROM public.organizers WHERE user_id = auth.uid()
        )
    );

-- Organizers can delete their own draft events only
CREATE POLICY "Organizers can delete own draft events" ON public.events
    FOR DELETE USING (
        status = 'draft' AND organizer_id IN (
            SELECT id FROM public.organizers WHERE user_id = auth.uid()
        )
    );

-- Enable realtime
ALTER PUBLICATION supabase_realtime ADD TABLE public.events;

-- Function to generate event slug
CREATE OR REPLACE FUNCTION public.handle_event_slug()
RETURNS TRIGGER AS $$
DECLARE
    base_slug TEXT;
    new_slug TEXT;
    counter INTEGER := 1;
BEGIN
    IF NEW.slug IS NULL OR NEW.slug = '' THEN
        -- Generate base slug from title and date
        base_slug = public.generate_slug(NEW.title || '-' || TO_CHAR(NEW.event_date, 'DD-Mon'));
        new_slug = base_slug;
        
        -- Ensure uniqueness
        WHILE EXISTS (SELECT 1 FROM public.events WHERE slug = new_slug AND id != COALESCE(NEW.id, gen_random_uuid())) LOOP
            new_slug = base_slug || '-' || counter;
            counter := counter + 1;
        END LOOP;
        
        NEW.slug = new_slug;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to validate ticket types JSONB
CREATE OR REPLACE FUNCTION public.validate_ticket_types()
RETURNS TRIGGER AS $$
BEGIN
    -- Ensure ticket_types is an array
    IF jsonb_typeof(NEW.ticket_types) != 'array' THEN
        RAISE EXCEPTION 'ticket_types must be an array';
    END IF;
    
    -- Validate each ticket type has required fields
    IF NEW.ticket_types IS NOT NULL AND NEW.ticket_types != '[]'::jsonb THEN
        FOR i IN 0..jsonb_array_length(NEW.ticket_types) - 1 LOOP
            IF NOT (NEW.ticket_types->i ? 'name' AND 
                    NEW.ticket_types->i ? 'price' AND 
                    NEW.ticket_types->i ? 'quantity') THEN
                RAISE EXCEPTION 'Each ticket type must have name, price, and quantity';
            END IF;
        END LOOP;
    END IF;
    
    -- Calculate min and max prices
    IF NEW.ticket_types IS NOT NULL AND jsonb_array_length(NEW.ticket_types) > 0 THEN
        NEW.min_ticket_price = (
            SELECT MIN((ticket->>'price')::DECIMAL)
            FROM jsonb_array_elements(NEW.ticket_types) AS ticket
        );
        NEW.max_ticket_price = (
            SELECT MAX((ticket->>'price')::DECIMAL)
            FROM jsonb_array_elements(NEW.ticket_types) AS ticket
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to update event status based on date
CREATE OR REPLACE FUNCTION public.update_event_status()
RETURNS TRIGGER AS $$
BEGIN
    -- Auto-complete events that have ended
    IF NEW.end_date IS NOT NULL AND NEW.end_date < NOW() AND NEW.status = 'published' THEN
        NEW.status = 'completed';
    END IF;
    
    -- Set published_at when status changes to published
    IF NEW.status = 'published' AND OLD.status != 'published' THEN
        NEW.published_at = NOW();
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers
CREATE TRIGGER generate_event_slug
    BEFORE INSERT OR UPDATE ON public.events
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_event_slug();

CREATE TRIGGER validate_event_ticket_types
    BEFORE INSERT OR UPDATE ON public.events
    FOR EACH ROW
    EXECUTE FUNCTION public.validate_ticket_types();

CREATE TRIGGER update_event_status_trigger
    BEFORE UPDATE ON public.events
    FOR EACH ROW
    EXECUTE FUNCTION public.update_event_status();

CREATE TRIGGER handle_events_updated_at
    BEFORE UPDATE ON public.events
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- Function to increment view count
CREATE OR REPLACE FUNCTION public.increment_event_view(event_id UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE public.events
    SET view_count = view_count + 1
    WHERE id = event_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;