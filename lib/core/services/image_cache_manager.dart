import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Manages image caching and memory for optimal performance
class ImageCacheManager {
  static final ImageCacheManager _instance = ImageCacheManager._internal();
  factory ImageCacheManager() => _instance;
  ImageCacheManager._internal();

  // Cache configuration
  static const int _maxCacheSize = 100 * 1024 * 1024; // 100 MB
  static const int _maxCacheCount = 200; // Max 200 images
  
  // Track loading images to avoid duplicates
  final Map<String, Future<void>> _loadingImages = {};
  
  // Track scroll state
  bool _isFastScrolling = false;
  DateTime? _lastScrollTime;
  
  /// Initialize cache settings
  void init() {
    // Configure image cache
    PaintingBinding.instance.imageCache.maximumSize = _maxCacheCount;
    PaintingBinding.instance.imageCache.maximumSizeBytes = _maxCacheSize;
    
    // Clear cache if it's too large
    _checkCacheSize();
  }
  
  /// Preload an image
  Future<void> preloadImage(String imageUrl, BuildContext context) async {
    if (imageUrl.isEmpty || _isFastScrolling) return;
    
    // Check if already loading
    if (_loadingImages.containsKey(imageUrl)) {
      return _loadingImages[imageUrl];
    }
    
    // Start loading
    final future = _doPreload(imageUrl, context);
    _loadingImages[imageUrl] = future;
    
    try {
      await future;
    } finally {
      _loadingImages.remove(imageUrl);
    }
  }
  
  Future<void> _doPreload(String imageUrl, BuildContext context) async {
    try {
      final image = NetworkImage(imageUrl);
      await precacheImage(image, context);
    } catch (e) {
      // Silently fail - image will load when needed
    }
  }
  
  /// Preload multiple images
  Future<void> preloadImages(List<String> imageUrls, BuildContext context) async {
    if (_isFastScrolling) return;
    
    // Limit concurrent preloads
    const int batchSize = 3;
    
    for (int i = 0; i < imageUrls.length; i += batchSize) {
      if (_isFastScrolling) break;
      
      final batch = imageUrls.skip(i).take(batchSize).toList();
      await Future.wait(
        batch.map((url) => preloadImage(url, context)),
        eagerError: false,
      );
    }
  }
  
  /// Update scroll state
  void updateScrollState(bool isFastScrolling) {
    _isFastScrolling = isFastScrolling;
    _lastScrollTime = DateTime.now();
    
    if (isFastScrolling) {
      // Cancel pending loads
      _loadingImages.clear();
    }
  }
  
  /// Clear specific image from cache
  void evictImage(String imageUrl) {
    if (imageUrl.isEmpty) return;
    
    final image = NetworkImage(imageUrl);
    image.evict();
  }
  
  /// Clear all cache
  void clearCache() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    _loadingImages.clear();
  }
  
  /// Check and manage cache size
  void _checkCacheSize() {
    final cache = PaintingBinding.instance.imageCache;
    
    // If cache is over 80% full, clear oldest entries
    if (cache.currentSizeBytes > _maxCacheSize * 0.8) {
      cache.clear();
    }
  }
  
  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    final cache = PaintingBinding.instance.imageCache;
    return {
      'currentSize': cache.currentSize,
      'currentSizeBytes': cache.currentSizeBytes,
      'liveImageCount': cache.liveImageCount,
      'pendingImageCount': _loadingImages.length,
    };
  }
}

/// Extension to detect scroll velocity
extension ScrollControllerVelocity on ScrollController {
  static final Map<ScrollController, _ScrollVelocityTracker> _trackers = {};
  
  double get velocity {
    final tracker = _trackers.putIfAbsent(
      this,
      () => _ScrollVelocityTracker(),
    );
    return tracker.velocity;
  }
  
  void updateVelocity() {
    final tracker = _trackers.putIfAbsent(
      this,
      () => _ScrollVelocityTracker(),
    );
    tracker.update(position.pixels);
  }
  
  bool get isFastScrolling {
    return velocity.abs() > 1000; // pixels per second
  }
}

class _ScrollVelocityTracker {
  double _lastPosition = 0;
  DateTime _lastTime = DateTime.now();
  double _velocity = 0;
  
  double get velocity => _velocity;
  
  void update(double position) {
    final now = DateTime.now();
    final timeDiff = now.difference(_lastTime).inMilliseconds;
    
    if (timeDiff > 0) {
      _velocity = (position - _lastPosition) / timeDiff * 1000;
    }
    
    _lastPosition = position;
    _lastTime = now;
  }
}