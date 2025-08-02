#!/bin/bash

# Supabase Database Migration Script
# Make sure to set your environment variables first

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | xargs)
fi

# Check if required variables are set
if [ -z "$SUPABASE_DB_URL" ]; then
    echo "Error: SUPABASE_DB_URL not set"
    echo "Please create a .env file with:"
    echo "SUPABASE_DB_URL=postgresql://postgres:[PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres"
    exit 1
fi

echo "Starting database migrations..."

# Run each migration file in order
for file in migrations/*.sql; do
    if [[ -f "$file" && "$file" != *"run_all_migrations.sql" ]]; then
        echo "Running migration: $file"
        psql "$SUPABASE_DB_URL" -f "$file"
        
        if [ $? -eq 0 ]; then
            echo "✓ Successfully ran: $file"
        else
            echo "✗ Failed to run: $file"
            exit 1
        fi
    fi
done

echo "All migrations completed successfully!"

# Verify tables
echo "Verifying created tables..."
psql "$SUPABASE_DB_URL" -c "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' AND table_type = 'BASE TABLE' ORDER BY table_name;"