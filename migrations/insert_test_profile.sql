-- Insert profile for test user
-- User ID: 546c1d48-d2ec-4693-8452-084a7af2409f
-- Email: test@noxxi.com
-- Phone: 0705708643

INSERT INTO public.profiles (
    user_id,
    email,
    phone_number,
    role,
    country_code,
    is_active,
    created_at,
    updated_at
) VALUES (
    '546c1d48-d2ec-4693-8452-084a7af2409f'::uuid,
    'test@noxxi.com',
    '0705708643',
    'user',
    'KE',
    true,
    NOW(),
    NOW()
)
ON CONFLICT (user_id) DO UPDATE SET
    email = EXCLUDED.email,
    phone_number = EXCLUDED.phone_number,
    updated_at = NOW();