import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:noxxi/core/services/image_cache_manager.dart';

/// Manages app memory and performs cleanup
class MemoryManager {
  static final MemoryManager _instance = MemoryManager._internal();
  factory MemoryManager() => _instance;
  MemoryManager._internal();
  
  Timer? _cleanupTimer;
  final _cacheManager = ImageCacheManager();
  
  // Memory thresholds
  static const double _criticalMemoryThreshold = 0.9; // 90% memory usage
  static const double _warningMemoryThreshold = 0.8;  // 80% memory usage
  
  /// Initialize memory management
  void init() {
    // Start periodic cleanup
    _cleanupTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _performCleanup(),
    );
    
    // Listen to app lifecycle
    WidgetsBinding.instance.addObserver(_MemoryLifecycleObserver(this));
  }
  
  /// Dispose resources
  void dispose() {
    _cleanupTimer?.cancel();
  }
  
  /// Perform memory cleanup
  void _performCleanup() {
    // Clear image cache if needed
    final stats = _cacheManager.getCacheStats();
    final currentSizeBytes = stats['currentSizeBytes'] as int;
    
    // If cache is too large, clear it
    if (currentSizeBytes > 80 * 1024 * 1024) { // 80MB
      _cacheManager.clearCache();
      debugPrint('Memory cleanup: Cleared image cache');
    }
    
    // Force garbage collection
    _forceGC();
  }
  
  /// Force garbage collection
  void _forceGC() {
    // Request garbage collection
    // Note: This is a hint, not guaranteed
    imageCache.clear();
    imageCache.clearLiveImages();
  }
  
  /// Handle low memory warning
  void handleLowMemory() {
    debugPrint('Low memory warning received');
    
    // Aggressive cleanup
    _cacheManager.clearCache();
    _forceGC();
    
    // Clear any other caches
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  }
  
  /// Get memory statistics
  Future<MemoryStats> getMemoryStats() async {
    final imageStats = _cacheManager.getCacheStats();
    
    return MemoryStats(
      imageCacheSize: imageStats['currentSize'] as int,
      imageCacheSizeBytes: imageStats['currentSizeBytes'] as int,
      liveImageCount: imageStats['liveImageCount'] as int,
    );
  }
}

/// Lifecycle observer for memory management
class _MemoryLifecycleObserver extends WidgetsBindingObserver {
  final MemoryManager memoryManager;
  
  _MemoryLifecycleObserver(this.memoryManager);
  
  @override
  void didHaveMemoryPressure() {
    super.didHaveMemoryPressure();
    memoryManager.handleLowMemory();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        // App is backgrounded - perform cleanup
        memoryManager._performCleanup();
        break;
      case AppLifecycleState.resumed:
        // App is foregrounded - ensure cache is ready
        ImageCacheManager().init();
        break;
      default:
        break;
    }
  }
}

/// Memory statistics
class MemoryStats {
  final int imageCacheSize;
  final int imageCacheSizeBytes;
  final int liveImageCount;
  
  MemoryStats({
    required this.imageCacheSize,
    required this.imageCacheSizeBytes,
    required this.liveImageCount,
  });
  
  String get formattedCacheSize {
    final mb = imageCacheSizeBytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }
}

/// Performance monitor widget (debug only)
class PerformanceMonitor extends StatefulWidget {
  final Widget child;
  
  const PerformanceMonitor({
    super.key,
    required this.child,
  });

  @override
  State<PerformanceMonitor> createState() => _PerformanceMonitorState();
}

class _PerformanceMonitorState extends State<PerformanceMonitor> {
  final _memoryManager = MemoryManager();
  MemoryStats? _stats;
  Timer? _updateTimer;
  
  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      _updateStats();
      _updateTimer = Timer.periodic(
        const Duration(seconds: 2),
        (_) => _updateStats(),
      );
    }
  }
  
  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }
  
  void _updateStats() async {
    final stats = await _memoryManager.getMemoryStats();
    if (mounted) {
      setState(() => _stats = stats);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (!kDebugMode || _stats == null) {
      return widget.child;
    }
    
    return Stack(
      children: [
        widget.child,
        Positioned(
          top: 50,
          right: 10,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8),
            ),
            child: DefaultTextStyle(
              style: const TextStyle(
                color: Colors.greenAccent,
                fontSize: 10,
                fontFamily: 'monospace',
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Images: ${_stats!.imageCacheSize}'),
                  Text('Memory: ${_stats!.formattedCacheSize}'),
                  Text('Live: ${_stats!.liveImageCount}'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}