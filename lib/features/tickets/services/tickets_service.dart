import 'package:flutter/foundation.dart';

class TicketsService {
  // Mock data for development
  
  /// Fetch active tickets for the current user
  Future<List<Ticket>> fetchActiveTickets() async {
    try {
      // Mock data - replace with your preferred backend service
      await Future.delayed(const Duration(seconds: 1));
      
      // Return empty list for now - implement with your backend
      return [];
    } catch (e) {
      debugPrint('Error fetching active tickets: $e');
      return [];
    }
  }
  
  /// Fetch used/expired tickets for the current user
  Future<List<Ticket>> fetchUsedTickets() async {
    try {
      // Mock data - replace with your preferred backend service
      await Future.delayed(const Duration(seconds: 1));
      return [];
    } catch (e) {
      debugPrint('Error fetching used tickets: $e');
      return [];
    }
  }
  
  /// Fetch transferred tickets (tickets transferred from or to the user)
  Future<List<Ticket>> fetchTransferredTickets() async {
    try {
      // Mock data - replace with your preferred backend service
      await Future.delayed(const Duration(seconds: 1));
      return [];
    } catch (e) {
      debugPrint('Error fetching transferred tickets: $e');
      return [];
    }
  }
  
  /// Get ticket details with QR code
  Future<Ticket?> getTicketDetails(String ticketId) async {
    try {
      // Mock data - replace with your preferred backend service
      await Future.delayed(const Duration(seconds: 1));
      return null;
    } catch (e) {
      debugPrint('Error fetching ticket details: $e');
      return null;
    }
  }
}

/// Ticket model
class Ticket {
  final String id;
  final String ticketCode;
  final String ticketHash;
  final String orderId;
  final String eventId;
  final String userId;
  final String ticketType;
  final double price;
  final String status;
  final String? qrCodeUrl;
  final DateTime? scannedAt;
  final String? seatNumber;
  final DateTime createdAt;
  final DateTime validFrom;
  final DateTime validUntil;
  final DateTime eventDate;
  
  // Related event data
  final String eventTitle;
  final String venueName;
  final String? city;
  final String? coverImageUrl;
  final DateTime eventDateTime;
  
  // Related order data
  final String orderNumber;
  final DateTime? paidAt;

  Ticket({
    required this.id,
    required this.ticketCode,
    required this.ticketHash,
    required this.orderId,
    required this.eventId,
    required this.userId,
    required this.ticketType,
    required this.price,
    required this.status,
    this.qrCodeUrl,
    this.scannedAt,
    this.seatNumber,
    required this.createdAt,
    required this.validFrom,
    required this.validUntil,
    required this.eventDate,
    required this.eventTitle,
    required this.venueName,
    this.city,
    this.coverImageUrl,
    required this.eventDateTime,
    required this.orderNumber,
    this.paidAt,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    final event = json['events'] as Map<String, dynamic>;
    final order = json['orders'] as Map<String, dynamic>;
    
    return Ticket(
      id: json['id'],
      ticketCode: json['ticket_code'],
      ticketHash: json['ticket_hash'],
      orderId: json['order_id'],
      eventId: json['event_id'],
      userId: json['user_id'],
      ticketType: json['ticket_type'],
      price: (json['price'] as num).toDouble(),
      status: json['status'],
      qrCodeUrl: json['qr_code_url'],
      scannedAt: json['scanned_at'] != null 
          ? DateTime.parse(json['scanned_at']) 
          : null,
      seatNumber: json['seat_number'],
      createdAt: DateTime.parse(json['created_at']),
      validFrom: DateTime.parse(json['valid_from']),
      validUntil: DateTime.parse(json['valid_until']),
      eventDate: DateTime.parse(json['event_date']),
      eventTitle: event['title'],
      venueName: event['venue_name'],
      city: event['city'],
      coverImageUrl: event['cover_image_url'],
      eventDateTime: DateTime.parse(event['event_date']),
      orderNumber: order['order_number'],
      paidAt: order['paid_at'] != null 
          ? DateTime.parse(order['paid_at']) 
          : null,
    );
  }
  
  bool get isActive => status == 'valid' && validUntil.isAfter(DateTime.now());
  bool get isUsed => status == 'used';
  bool get isExpired => validUntil.isBefore(DateTime.now());
  bool get isCancelled => status == 'cancelled';
}