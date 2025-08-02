2. organizers
  - id UUID PRIMARY KEY
  - user_id UUID REFERENCES profiles
  - business_name VARCHAR(255) NOT NULL
  - business_phone VARCHAR(20)
  - business_email VARCHAR(255)
  - mpesa_till_number VARCHAR(20)
  - mpesa_paybill VARCHAR(20)
  - bank_account_details JSONB (encrypted)
  - tax_pin VARCHAR(50)
  - business_registration_no VARCHAR(100)
  - verification_status ENUM('pending', 'verified', 'suspended')
  - verification_documents JSONB
  - commission_rate DECIMAL(5,2) DEFAULT 10.00
  - total_events INTEGER DEFAULT 0
  - total_tickets_sold INTEGER DEFAULT 0
  - total_revenue DECIMAL(15,2) DEFAULT 0
  - rating DECIMAL(3,2)
  - can_scan BOOLEAN DEFAULT true
  - api_key VARCHAR(255) UNIQUE (for integrations)
  - webhook_url TEXT
  - created_at TIMESTAMP
  - approved_at TIMESTAMP
  - approved_by UUID REFERENCES profiles(id)

  Event Management

  3. event_categories
  - id UUID PRIMARY KEY
  - name VARCHAR(100) NOT NULL
  - slug VARCHAR(100) UNIQUE
  - icon_url TEXT
  - parent_id UUID REFERENCES event_categories(id)
  - display_order INTEGER
  - is_active BOOLEAN DEFAULT true

  4. events
  - id UUID PRIMARY KEY
  - organizer_id UUID REFERENCES organizers
  - title VARCHAR(255) NOT NULL
  - slug VARCHAR(255) UNIQUE
  - description TEXT
  - category_id UUID REFERENCES event_categories
  - venue_name VARCHAR(255)
  - venue_address TEXT
  - venue_coordinates POINT
  - city VARCHAR(100)
  - event_date TIMESTAMP NOT NULL
  - end_date TIMESTAMP
  - ticket_types JSONB
  - total_capacity INTEGER NOT NULL
  - tickets_sold INTEGER DEFAULT 0
  - min_ticket_price DECIMAL(10,2)
  - max_ticket_price DECIMAL(10,2)
  - currency VARCHAR(3) DEFAULT 'KES'
  - images JSONB
  - cover_image_url TEXT
  - tags TEXT[]
  - status ENUM('draft', 'published', 'cancelled', 'postponed', 'completed')
  - featured BOOLEAN DEFAULT false
  - featured_until TIMESTAMP
  - requires_approval BOOLEAN DEFAULT false
  - age_restriction INTEGER
  - terms_conditions TEXT
  - refund_policy TEXT
  - offline_mode_data JSONB
  - seo_keywords TEXT[]
  - view_count INTEGER DEFAULT 0
  - share_count INTEGER DEFAULT 0
  - created_at TIMESTAMP
  - published_at TIMESTAMP
  - updated_at TIMESTAMP

  Ticketing

  5. orders
  - id UUID PRIMARY KEY
  - order_number VARCHAR(20) UNIQUE
  - user_id UUID REFERENCES profiles
  - event_id UUID REFERENCES events
  - ticket_count INTEGER NOT NULL
  - subtotal DECIMAL(10,2) NOT NULL
  - service_fee DECIMAL(10,2) NOT NULL
  - payment_fee DECIMAL(10,2)
  - discount_amount DECIMAL(10,2) DEFAULT 0
  - total_amount DECIMAL(10,2) NOT NULL
  - currency VARCHAR(3) DEFAULT 'KES'
  - status ENUM('pending', 'processing', 'paid', 'failed', 'refunded', 'cancelled')
  - payment_method ENUM('mpesa', 'card', 'bank_transfer', 'cash')
  - payment_reference VARCHAR(100)
  - mpesa_receipt_number VARCHAR(50)
  - promo_code VARCHAR(50)
  - buyer_info JSONB
  - ip_address INET
  - user_agent TEXT
  - expires_at TIMESTAMP
  - paid_at TIMESTAMP
  - created_at TIMESTAMP

  6. tickets (partitioned by event_date)
  - id UUID PRIMARY KEY
  - ticket_code VARCHAR(50) UNIQUE NOT NULL
  - ticket_hash VARCHAR(255) NOT NULL
  - order_id UUID REFERENCES orders
  - event_id UUID REFERENCES events
  - user_id UUID REFERENCES profiles
  - ticket_type VARCHAR(100)
  - price DECIMAL(10,2) NOT NULL
  - status ENUM('valid', 'used', 'cancelled', 'transferred')
  - qr_code_url TEXT
  - offline_mode_data JSONB
  - transferred_from UUID REFERENCES tickets(id)
  - transferred_to UUID REFERENCES profiles(id)
  - transferred_at TIMESTAMP
  - scanned_by UUID REFERENCES profiles(id)
  - scanned_at TIMESTAMP
  - device_fingerprint VARCHAR(255)
  - entry_gate VARCHAR(50)
  - seat_number VARCHAR(20)
  - special_requirements TEXT
  - created_at TIMESTAMP
  - valid_from TIMESTAMP
  - valid_until TIMESTAMP

  Scanning & Security

  7. scan_attempts
  - id UUID PRIMARY KEY
  - ticket_id UUID REFERENCES tickets
  - event_id UUID REFERENCES events
  - scanner_id UUID REFERENCES profiles
  - device_fingerprint VARCHAR(255)
  - scan_result ENUM('success', 'invalid_ticket', 'already_used', 'expired', 'wrong_event', 'unauthorized_scanner')
  - location POINT
  - ip_address INET
  - user_agent TEXT
  - created_at TIMESTAMP

  8. event_staff
  - id UUID PRIMARY KEY
  - event_id UUID REFERENCES events
  - user_id UUID REFERENCES profiles
  - added_by UUID REFERENCES organizers
  - role ENUM('scanner', 'manager', 'support')
  - can_scan BOOLEAN DEFAULT true
  - can_view_analytics BOOLEAN DEFAULT false
  - is_active BOOLEAN DEFAULT true
  - created_at TIMESTAMP

  Financial & Analytics

  9. transactions
  - id UUID PRIMARY KEY
  - type ENUM('ticket_sale', 'refund', 'payout', 'commission')
  - order_id UUID REFERENCES orders
  - organizer_id UUID REFERENCES organizers
  - amount DECIMAL(15,2) NOT NULL
  - currency VARCHAR(3) DEFAULT 'KES'
  - commission_amount DECIMAL(10,2)
  - net_amount DECIMAL(10,2)
  - payment_method VARCHAR(50)
  - payment_reference VARCHAR(100)
  - status ENUM('pending', 'completed', 'failed')
  - processed_at TIMESTAMP
  - created_at TIMESTAMP

  10. payouts
  - id UUID PRIMARY KEY
  - organizer_id UUID REFERENCES organizers
  - amount DECIMAL(15,2) NOT NULL
  - currency VARCHAR(3) DEFAULT 'KES'
  - method ENUM('mpesa', 'bank_transfer')
  - reference_number VARCHAR(100)
  - status ENUM('pending', 'processing', 'completed', 'failed')
  - failure_reason TEXT
  - initiated_by UUID REFERENCES profiles(id)
  - processed_at TIMESTAMP
  - created_at TIMESTAMP

  11. event_analytics
  - id UUID PRIMARY KEY
  - event_id UUID REFERENCES events
  - date DATE NOT NULL
  - ticket_sales INTEGER DEFAULT 0
  - revenue DECIMAL(10,2) DEFAULT 0
  - page_views INTEGER DEFAULT 0
  - conversion_rate DECIMAL(5,2)
  - avg_order_value DECIMAL(10,2)
  - peak_sale_hour INTEGER
  - top_referrer VARCHAR(255)
  - device_breakdown JSONB
  - geographic_breakdown JSONB
  - created_at TIMESTAMP

  Support & Communication

  12. event_waitlist
  - id UUID PRIMARY KEY
  - event_id UUID REFERENCES events
  - user_id UUID REFERENCES profiles
  - email VARCHAR(255)
  - phone_number VARCHAR(20)
  - ticket_type VARCHAR(100)
  - quantity INTEGER DEFAULT 1
  - notified BOOLEAN DEFAULT false
  - converted BOOLEAN DEFAULT false
  - created_at TIMESTAMP

  13. notifications
  - id UUID PRIMARY KEY
  - user_id UUID REFERENCES profiles
  - type ENUM('order_confirmation', 'event_reminder', 'ticket_transfer', 'event_update', 'marketing')
  - title VARCHAR(255)
  - message TEXT
  - data JSONB
  - channel ENUM('push', 'sms', 'email', 'in_app')
  - status ENUM('pending', 'sent', 'failed', 'read')
  - sent_at TIMESTAMP
  - read_at TIMESTAMP
  - created_at TIMESTAMP

  14. support_tickets
  - id UUID PRIMARY KEY
  - user_id UUID REFERENCES profiles
  - order_id UUID REFERENCES orders
  - category ENUM('payment', 'ticket', 'event', 'refund', 'other')
  - subject VARCHAR(255)
  - description TEXT
  - status ENUM('open', 'in_progress', 'resolved', 'closed')
  - priority ENUM('low', 'medium', 'high', 'urgent')
  - assigned_to UUID REFERENCES profiles(id)
  - resolved_at TIMESTAMP
  - created_at TIMESTAMP

  Platform Management (Laravel Admin)

  15. platform_settings
  - key VARCHAR(100) PRIMARY KEY
  - value JSONB
  - description TEXT
  - updated_by UUID REFERENCES profiles(id)
  - updated_at TIMESTAMP

  16. audit_logs
  - id UUID PRIMARY KEY
  - user_id UUID REFERENCES profiles
  - action VARCHAR(100)
  - entity_type VARCHAR(50)
  - entity_id UUID
  - old_values JSONB
  - new_values JSONB
  - ip_address INET
  - user_agent TEXT
  - created_at TIMESTAMP

  Views & Materialized Views

  17. popular_events (materialized view)
  - Aggregates events by ticket sales, views, and recency
  - Refreshed hourly

  18. organizer_dashboard (view)
  - Real-time stats for organizers
  - Upcoming events, recent sales, pending payouts

  Indexes:
  - tickets(ticket_code) - for fast QR scanning
  - tickets(event_id, status) - for availability checks
  - events(event_date, status) - for listing queries
  - profiles(phone_number) - for auth lookup
  - orders(user_id, created_at) - for order history