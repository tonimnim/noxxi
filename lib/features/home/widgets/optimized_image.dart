import 'package:flutter/material.dart';
import 'package:noxxi/core/theme/app_colors.dart';

/// Optimized image widget with fade-in and caching
class OptimizedNetworkImage extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final Duration fadeInDuration;
  final Curve fadeInCurve;
  
  const OptimizedNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.fadeInDuration = const Duration(milliseconds: 300),
    this.fadeInCurve = Curves.easeIn,
  });

  @override
  State<OptimizedNetworkImage> createState() => _OptimizedNetworkImageState();
}

class _OptimizedNetworkImageState extends State<OptimizedNetworkImage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.fadeInDuration,
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: widget.fadeInCurve,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrl.isEmpty) {
      return _buildPlaceholder();
    }

    return Image.network(
      widget.imageUrl,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || _isLoaded) {
          return child;
        }
        
        if (frame != null && !_isLoaded) {
          _isLoaded = true;
          _controller.forward();
        }
        
        return Stack(
          children: [
            if (widget.placeholder != null) widget.placeholder!,
            if (frame != null)
              FadeTransition(
                opacity: _animation,
                child: child,
              ),
          ],
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }
        
        return widget.placeholder ?? _buildDefaultLoader(loadingProgress);
      },
      errorBuilder: (context, error, stackTrace) {
        return widget.errorWidget ?? _buildDefaultError();
      },
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

  Widget _buildDefaultLoader(ImageChunkEvent loadingProgress) {
    final progress = loadingProgress.expectedTotalBytes != null
        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
        : null;
    
    return Container(
      width: widget.width,
      height: widget.height,
      color: AppColors.cardBackground.withOpacity(0.3),
      child: Center(
        child: SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(
            value: progress,
            strokeWidth: 2,
            color: AppColors.primaryAccent,
          ),
        ),
      ),
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
            Icons.image_not_supported_outlined,
            size: 48,
            color: AppColors.darkText.withOpacity(0.3),
          ),
          const SizedBox(height: 8),
          Text(
            'Image not available',
            style: TextStyle(
              color: AppColors.darkText.withOpacity(0.5),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shimmer placeholder for images
class ImageShimmerPlaceholder extends StatefulWidget {
  final double? width;
  final double? height;
  
  const ImageShimmerPlaceholder({
    super.key,
    this.width,
    this.height,
  });

  @override
  State<ImageShimmerPlaceholder> createState() => _ImageShimmerPlaceholderState();
}

class _ImageShimmerPlaceholderState extends State<ImageShimmerPlaceholder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    
    _animation = Tween<double>(
      begin: -2.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-1.0 + _animation.value, 0),
              end: Alignment(-0.5 + _animation.value, 0),
              colors: [
                AppColors.cardBackground.withOpacity(0.8),
                AppColors.scaffoldBackground,
                AppColors.cardBackground.withOpacity(0.8),
              ],
            ),
          ),
        );
      },
    );
  }
}