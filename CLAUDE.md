# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Noxxi - Event Ticketing Platform PRD

### Executive Summary
Noxxi is a simple, efficient event ticketing platform built for Kenya and the African market. It helps event organizers sell tickets online and manage event entry through QR codes, with seamless M-Pesa integration for payments.

### Problem Statement
Event organizers in Kenya face challenges with:
- Manual ticket sales and cash handling
- Ticket fraud and unauthorized entries
- Lack of basic analytics on sales
- Difficulty collecting payments from attendees
- No simple way to track who has entered the event

### Solution Overview
Noxxi provides a straightforward event ticketing solution:
- Create events and sell tickets online
- Accept M-Pesa payments via Daraja API
- Generate secure QR code tickets
- Scan tickets at entry with basic offline support
- View sales reports and attendee lists
- Automated M-Pesa settlements to organizers

### Target Users

#### Primary Users
1. **Event Organizers**
   - Concert promoters
   - Conference organizers
   - Sports event managers
   - Theater and entertainment venues
   - Churches and religious organizations

2. **Event Attendees**
   - Young professionals (18-35)
   - Entertainment seekers
   - Conference participants
   - Sports fans

#### Secondary Users
1. **Event Staff**
   - Ticket scanners at entry points
   - Event managers monitoring real-time data
   - Support staff handling customer issues

2. **Platform Administrators**
   - Noxxi operations team
   - Financial reconciliation team
   - Customer support team

### Core Features

#### 1. Event Management
- **Event Creation**: Rich event pages with images, descriptions, venue details
- **Ticket Types**: Multiple pricing tiers (Early Bird, VIP, Regular, Group)
- **Capacity Management**: Real-time availability tracking
- **Event Categories**: Music, Sports, Corporate, Religious, Theater, etc.
- **Venue Mapping**: GPS coordinates and detailed directions
- **Event Status**: Draft, Published, Cancelled, Postponed, Completed

#### 2. Ticketing System
- **In-App Tickets**: All tickets stored in user's app
- **QR Code Generation**: Unique, secure codes for each ticket
- **Ticket List**: View all purchased tickets in one place
- **Ticket Details**: Event info, date, time, venue
- **No Physical Tickets**: 100% digital, no SMS/email tickets
- **Group Bookings**: Buy multiple tickets at once

#### 3. Payment Processing
- **Daraja API Integration**: M-Pesa STK Push for instant payments
- **Payment Verification**: Real-time M-Pesa confirmation
- **Commission Handling**: Automatic 5-10% deduction
- **Settlement**: Daily M-Pesa transfers to organizers
- **Transaction History**: Clear payment records
- **Basic Refunds**: Manual refund process when needed

#### 4. Entry Management
- **QR Scanning**: Quick ticket validation using phone camera
- **Basic Offline Support**: Cache recent tickets for scanning
- **Entry Tracking**: Mark tickets as used after scanning
- **Scanner Access**: Add staff members who can scan tickets
- **Duplicate Prevention**: Block already-scanned tickets

#### 5. Analytics & Reporting
- **Sales Overview**: Total tickets sold and revenue
- **Daily Sales**: Track sales trends over time
- **Attendance Report**: How many people actually showed up
- **Basic Demographics**: Buyer phone numbers and names
- **Payment Summary**: M-Pesa transaction records

#### 6. Financial Management
- **Commission System**: Automatic 5-10% platform fee
- **Daily Payouts**: M-Pesa transfers to organizers
- **Transaction Records**: All payments tracked
- **Balance View**: See pending and paid amounts
- **Simple Receipts**: Basic payment confirmations

#### 7. Communication
- **In-App Notifications**: Payment confirmations
- **Push Notifications**: Event reminders (optional)
- **SMS Verification**: Only for account signup
- **No Ticket Emails/SMS**: All tickets stay in app
 
#### 8. Customer Support
- **Help Section**: Common questions and answers
- **Contact Form**: Submit issues via app
- **Phone Support**: Helpline for urgent issues

### Technical Architecture

#### Frontend
- **Mobile App**: Flutter (Android first, iOS later)
- **Web Dashboard**: Simple web interface for organizers (future)

#### Backend
- **Database**: PostgreSQL via Supabase
- **Authentication**: Phone number login via Supabase Auth
- **Storage**: Supabase Storage for event images
- **API**: Supabase client libraries

#### Key Integrations
- **Payment**: Daraja API for M-Pesa
- **SMS**: Africa's Talking for notifications
- **QR Codes**: Local generation in Flutter

### Security & Compliance
- **Secure QR Codes**: Unique, tamper-proof ticket codes
- **Phone Verification**: OTP for account creation
- **Data Protection**: Basic encryption for user data
- **Payment Security**: Daraja API handles M-Pesa security

### Business Model
- **Simple Commission**: 5-10% per ticket sold
- **No Setup Fees**: Free to create events
- **Volume Discounts**: Better rates for regular organizers

### Success Metrics
- **Monthly Ticket Sales**: Number and value of tickets
- **Active Organizers**: Regular event creators
- **Successful Events**: Events that sell tickets
- **Payment Success Rate**: M-Pesa transaction completion
- **Customer Satisfaction**: User feedback and ratings

### MVP Features (Phase 1)
1. **User Registration**: Phone number signup with OTP
2. **Event Creation**: Basic event details, images, ticket types
3. **M-Pesa Payment**: Buy tickets with Daraja API
4. **In-App Tickets**: View all tickets in "My Tickets" section
5. **QR Display**: Show QR code from app for scanning
6. **Ticket Scanning**: Scan QR codes from other users' apps
7. **Basic Dashboard**: View sales and scan status

### Future Phases
- **Phase 2**: SMS notifications, better analytics
- **Phase 3**: Web dashboard for organizers
- **Phase 4**: Expand to Tanzania, Uganda, Rwanda
- **Phase 5**: Add card payments and other features

### Competitive Advantages
- **Local Payment Methods**: Deep M-Pesa integration
- **Offline Functionality**: Critical for African venues
- **Low Transaction Fees**: Competitive pricing
- **Fast Settlement**: Daily payouts to organizers
- **Local Support**: Swahili and English support
- **Mobile-First**: Optimized for feature phones