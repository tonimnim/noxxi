/// Event model for the home feed
/// Maps to the events table in the database
class EventFeedItem {
  final String id;
  final String title;
  final String? slug;
  final String? description;
  final String coverImageUrl;
  final List<String> images;
  final DateTime eventDate;
  final DateTime? endDate;
  final String venueName;
  final String? venueAddress;
  final String? city;
  final double minTicketPrice;
  final double? maxTicketPrice;
  final String currency;
  final int totalCapacity;
  final int ticketsSold;
  final String status;
  final bool featured;
  final List<TicketType> ticketTypes;
  final String categoryId;
  final String? categoryName;
  final int viewCount;
  final int shareCount;
  final bool isSaved; // Local state for UI
  final bool isInCart; // Local state for UI

  EventFeedItem({
    required this.id,
    required this.title,
    this.slug,
    this.description,
    required this.coverImageUrl,
    this.images = const [],
    required this.eventDate,
    this.endDate,
    required this.venueName,
    this.venueAddress,
    this.city,
    required this.minTicketPrice,
    this.maxTicketPrice,
    this.currency = 'KES',
    required this.totalCapacity,
    this.ticketsSold = 0,
    this.status = 'published',
    this.featured = false,
    this.ticketTypes = const [],
    required this.categoryId,
    this.categoryName,
    this.viewCount = 0,
    this.shareCount = 0,
    this.isSaved = false,
    this.isInCart = false,
  });

  /// Create from API JSON response
  factory EventFeedItem.fromJson(Map<String, dynamic> json) {
    // Parse ticket types from JSONB
    List<TicketType> tickets = [];
    if (json['ticket_types'] != null && json['ticket_types'] is List) {
      tickets = (json['ticket_types'] as List)
          .map((t) => TicketType.fromJson(t))
          .toList();
    }

    // Parse images array
    List<String> imagesList = [];
    if (json['images'] != null && json['images'] is List) {
      imagesList = List<String>.from(json['images']);
    }

    return EventFeedItem(
      id: json['id'],
      title: json['title'],
      slug: json['slug'],
      description: json['description'],
      coverImageUrl: json['cover_image_url'] ?? '',
      images: imagesList,
      eventDate: DateTime.parse(json['event_date']),
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      venueName: json['venue_name'] ?? '',
      venueAddress: json['venue_address'],
      city: json['city'],
      minTicketPrice: (json['min_ticket_price'] ?? 0).toDouble(),
      maxTicketPrice: json['max_ticket_price']?.toDouble(),
      currency: json['currency'] ?? 'KES',
      totalCapacity: json['total_capacity'] ?? 0,
      ticketsSold: json['tickets_sold'] ?? 0,
      status: json['status'] ?? 'published',
      featured: json['featured'] ?? false,
      ticketTypes: tickets,
      categoryId: json['category_id'],
      categoryName: json['category']?['name'], // If joined with category
      viewCount: json['view_count'] ?? 0,
      shareCount: json['share_count'] ?? 0,
      isSaved: false, // Will be set based on user's saved items
      isInCart: false, // Will be set based on user's cart
    );
  }

  /// Copy with updated values
  EventFeedItem copyWith({
    bool? isSaved,
    bool? isInCart,
    int? viewCount,
    int? shareCount,
  }) {
    return EventFeedItem(
      id: id,
      title: title,
      slug: slug,
      description: description,
      coverImageUrl: coverImageUrl,
      images: images,
      eventDate: eventDate,
      endDate: endDate,
      venueName: venueName,
      venueAddress: venueAddress,
      city: city,
      minTicketPrice: minTicketPrice,
      maxTicketPrice: maxTicketPrice,
      currency: currency,
      totalCapacity: totalCapacity,
      ticketsSold: ticketsSold,
      status: status,
      featured: featured,
      ticketTypes: ticketTypes,
      categoryId: categoryId,
      categoryName: categoryName,
      viewCount: viewCount ?? this.viewCount,
      shareCount: shareCount ?? this.shareCount,
      isSaved: isSaved ?? this.isSaved,
      isInCart: isInCart ?? this.isInCart,
    );
  }

  /// Check if event is sold out
  bool get isSoldOut => ticketsSold >= totalCapacity;

  /// Check if event is happening today
  bool get isToday {
    final now = DateTime.now();
    return eventDate.year == now.year &&
        eventDate.month == now.month &&
        eventDate.day == now.day;
  }

  /// Check if event is happening tomorrow
  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return eventDate.year == tomorrow.year &&
        eventDate.month == tomorrow.month &&
        eventDate.day == tomorrow.day;
  }

  /// Get formatted price range
  String get priceRange {
    if (maxTicketPrice != null && maxTicketPrice != minTicketPrice) {
      return '$currency ${minTicketPrice.toStringAsFixed(0)} - ${maxTicketPrice!.toStringAsFixed(0)}';
    }
    return 'From $currency ${minTicketPrice.toStringAsFixed(0)}';
  }

  /// Get availability percentage
  double get availabilityPercentage {
    if (totalCapacity == 0) return 0;
    return ((totalCapacity - ticketsSold) / totalCapacity) * 100;
  }

  /// Get availability status text
  String get availabilityStatus {
    final percentage = availabilityPercentage;
    if (percentage == 0) return 'Sold Out';
    if (percentage < 10) return 'Almost Sold Out';
    if (percentage < 25) return 'Few Tickets Left';
    return '${(totalCapacity - ticketsSold)} Tickets Available';
  }
}

/// Ticket type model
class TicketType {
  final String name;
  final double price;
  final int quantity;
  final int? quantitySold;
  final String? description;
  final bool? isEarlyBird;

  TicketType({
    required this.name,
    required this.price,
    required this.quantity,
    this.quantitySold,
    this.description,
    this.isEarlyBird,
  });

  factory TicketType.fromJson(Map<String, dynamic> json) {
    return TicketType(
      name: json['name'],
      price: (json['price'] ?? 0).toDouble(),
      quantity: json['quantity'] ?? 0,
      quantitySold: json['quantity_sold'],
      description: json['description'],
      isEarlyBird: json['is_early_bird'],
    );
  }

  bool get isSoldOut => quantitySold != null && quantitySold! >= quantity;
}