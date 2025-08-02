-- Create event_categories table for organizing event types
CREATE TABLE IF NOT EXISTS public.event_categories (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    icon_url TEXT,
    parent_id UUID REFERENCES public.event_categories(id) ON DELETE CASCADE,
    display_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX idx_event_categories_slug ON public.event_categories(slug);
CREATE INDEX idx_event_categories_parent_id ON public.event_categories(parent_id);
CREATE INDEX idx_event_categories_is_active ON public.event_categories(is_active);

-- Enable Row Level Security
ALTER TABLE public.event_categories ENABLE ROW LEVEL SECURITY;

-- Create policies for event_categories table
-- Everyone can view active categories
CREATE POLICY "Anyone can view active categories" ON public.event_categories
    FOR SELECT USING (is_active = true);

-- Only admins can manage categories
CREATE POLICY "Admins can manage categories" ON public.event_categories
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.user_id = auth.uid() AND profiles.role = 'admin'
        )
    );

-- Function to generate slug from name
CREATE OR REPLACE FUNCTION public.generate_slug(input_text TEXT)
RETURNS TEXT AS $$
BEGIN
    RETURN LOWER(
        REGEXP_REPLACE(
            REGEXP_REPLACE(
                TRIM(input_text),
                '[^a-zA-Z0-9\s-]', '', 'g'
            ),
            '\s+', '-', 'g'
        )
    );
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-generate slug if not provided
CREATE OR REPLACE FUNCTION public.handle_category_slug()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.slug IS NULL OR NEW.slug = '' THEN
        NEW.slug = public.generate_slug(NEW.name);
    END IF;
    
    -- Ensure slug is unique by appending number if needed
    DECLARE
        base_slug TEXT := NEW.slug;
        counter INTEGER := 1;
    BEGIN
        WHILE EXISTS (SELECT 1 FROM public.event_categories WHERE slug = NEW.slug AND id != COALESCE(NEW.id, gen_random_uuid())) LOOP
            NEW.slug = base_slug || '-' || counter;
            counter := counter + 1;
        END LOOP;
    END;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for slug generation
CREATE TRIGGER generate_category_slug
    BEFORE INSERT OR UPDATE ON public.event_categories
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_category_slug();

-- Trigger to update updated_at
CREATE TRIGGER handle_event_categories_updated_at
    BEFORE UPDATE ON public.event_categories
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- Insert default categories for Kenya market
INSERT INTO public.event_categories (name, slug, display_order) VALUES
    ('Events', 'events', 1),
    ('Cinema', 'cinema', 2),
    ('Travel', 'travel', 3),
    ('Experiences', 'experiences', 4);

-- Insert subcategories for Events
WITH events_parent AS (
    SELECT id FROM public.event_categories WHERE slug = 'events'
)
INSERT INTO public.event_categories (name, slug, parent_id, display_order)
SELECT name, slug, events_parent.id, display_order
FROM events_parent,
    (VALUES 
        ('Concerts', 'concerts', 1),
        ('Festivals', 'festivals', 2),
        ('Sports', 'sports', 3),
        ('Comedy Shows', 'comedy-shows', 4),
        ('Theatre & Arts', 'theatre-arts', 5),
        ('Conferences', 'conferences', 6),
        ('Workshops', 'workshops', 7),
        ('Nightlife', 'nightlife', 8)
    ) AS subcategories(name, slug, display_order);

-- Insert subcategories for Travel
WITH travel_parent AS (
    SELECT id FROM public.event_categories WHERE slug = 'travel'
)
INSERT INTO public.event_categories (name, slug, parent_id, display_order)
SELECT name, slug, travel_parent.id, display_order
FROM travel_parent,
    (VALUES 
        ('Bus', 'bus', 1),
        ('Train (SGR)', 'train-sgr', 2),
        ('Flights', 'flights', 3),
        ('Matatu', 'matatu', 4)
    ) AS subcategories(name, slug, display_order);

-- Insert subcategories for Experiences  
WITH experiences_parent AS (
    SELECT id FROM public.event_categories WHERE slug = 'experiences'
)
INSERT INTO public.event_categories (name, slug, parent_id, display_order)
SELECT name, slug, experiences_parent.id, display_order
FROM experiences_parent,
    (VALUES 
        ('Safari & Tours', 'safari-tours', 1),
        ('Adventure Activities', 'adventure-activities', 2),
        ('Food & Dining', 'food-dining', 3),
        ('Wellness & Spa', 'wellness-spa', 4),
        ('Classes & Learning', 'classes-learning', 5)
    ) AS subcategories(name, slug, display_order);