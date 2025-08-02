import 'package:flutter/material.dart';
import 'package:noxxi/core/theme/app_colors.dart';
import 'package:noxxi/core/services/image_cache_manager.dart';

/// High-performance image widget with scroll-aware loading
class PerformanceImage extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final ScrollController? scrollController;
  final bool enableFadeIn;
  
  const PerformanceImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.scrollController,
    this.enableFadeIn = true,
  });

  @override
  State<PerformanceImage> createState() => _PerformanceImageState();
}

class _PerformanceImageState extends State<PerformanceImage>
    with AutomaticKeepAliveClientMixin {
  final _cacheManager = ImageCacheManager();
  bool _isVisible = true;
  bool _hasLoaded = false;
  ImageStream? _imageStream;
  ImageStreamListener? _imageStreamListener;
  
  @override
  bool get wantKeepAlive => _hasLoaded;

  @override
  void initState() {
    super.initState();
    if (widget.scrollController != null) {
      widget.scrollController!.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    widget.scrollController?.removeListener(_onScroll);
    _removeImageStreamListener();
    super.dispose();
  }

  void _onScroll() {
    if (!mounted) return;
    
    final controller = widget.scrollController!;
    controller.updateVelocity();
    
    final isFastScrolling = controller.isFastScrolling;
    _cacheManager.updateScrollState(isFastScrolling);
    
    // Cancel image loading if scrolling too fast
    if (isFastScrolling && !_hasLoaded) {
      setState(() => _isVisible = false);
      _removeImageStreamListener();
    } else if (!isFastScrolling && !_isVisible) {
      setState(() => _isVisible = true);
    }
  }
  
  void _removeImageStreamListener() {
    _imageStream?.removeListener(_imageStreamListener!);
    _imageStream = null;
    _imageStreamListener = null;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    if (widget.imageUrl.isEmpty) {
      return _buildPlaceholder();
    }
    
    if (!_isVisible) {
      return widget.placeholder ?? _buildDefaultPlaceholder();
    }
    
    return Image(
      image: NetworkImage(widget.imageUrl),
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      frameBuilder: widget.enableFadeIn ? _buildFrameWithFade : (context, child, frame, wasSynchronouslyLoaded) => child,
      loadingBuilder: _buildLoadingWidget,
      errorBuilder: (context, error, stackTrace) {
        return widget.errorWidget ?? _buildDefaultError();
      },
    );
  }
  
  Widget _buildFrameWithFade(
    BuildContext context,
    Widget child,
    int? frame,
    bool wasSynchronouslyLoaded,
  ) {
    if (wasSynchronouslyLoaded || _hasLoaded) {
      return child;
    }
    
    if (frame != null) {
      _hasLoaded = true;
    }
    
    return AnimatedOpacity(
      opacity: frame == null ? 0 : 1,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      child: child,
    );
  }
  
  Widget _buildLoadingWidget(
    BuildContext context,
    Widget child,
    ImageChunkEvent? loadingProgress,
  ) {
    if (loadingProgress == null) {
      return child;
    }
    
    return Stack(
      children: [
        if (widget.placeholder != null) 
          widget.placeholder!
        else
          _buildDefaultPlaceholder(),
        if (loadingProgress.expectedTotalBytes != null)
          Positioned.fill(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: LinearProgressIndicator(
                value: loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.primaryAccent.withOpacity(0.3),
                ),
                minHeight: 2,
              ),
            ),
          ),
      ],
    );
  }
  
  Widget _buildPlaceholder() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: AppColors.cardBackground,
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          size: 48,
          color: AppColors.secondaryText,
        ),
      ),
    );
  }
  
  Widget _buildDefaultPlaceholder() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: AppColors.cardBackground.withOpacity(0.3),
    );
  }
  
  Widget _buildDefaultError() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: AppColors.cardBackground,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image_outlined,
            size: 36,
            color: AppColors.darkText.withOpacity(0.3),
          ),
        ],
      ),
    );
  }
}