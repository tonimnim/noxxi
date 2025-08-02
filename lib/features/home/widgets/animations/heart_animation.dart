import 'package:flutter/material.dart';
import 'package:noxxi/core/theme/app_colors.dart';

/// Instagram-style heart animation overlay
class HeartAnimationOverlay extends StatefulWidget {
  final Widget child;
  final bool isLiked;
  final VoidCallback onDoubleTap;
  final Duration animationDuration;
  
  const HeartAnimationOverlay({
    super.key,
    required this.child,
    required this.isLiked,
    required this.onDoubleTap,
    this.animationDuration = const Duration(milliseconds: 800),
  });

  @override
  State<HeartAnimationOverlay> createState() => _HeartAnimationOverlayState();
}

class _HeartAnimationOverlayState extends State<HeartAnimationOverlay> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  bool _showHeart = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.15, curve: Curves.easeIn),
    ));

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _showHeart = false);
        _controller.reset();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    widget.onDoubleTap();
    if (!widget.isLiked) {
      setState(() => _showHeart = true);
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: _handleDoubleTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          widget.child,
          if (_showHeart)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: 1.0 - (_controller.value > 0.5 
                      ? (_controller.value - 0.5) * 2 
                      : 0.0),
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.favorite,
                        color: AppColors.primaryAccent,
                        size: 60,
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

/// Small heart animation for button taps
class HeartButtonAnimation extends StatefulWidget {
  final bool isLiked;
  final VoidCallback onTap;
  final double size;
  
  const HeartButtonAnimation({
    super.key,
    required this.isLiked,
    required this.onTap,
    this.size = 24,
  });

  @override
  State<HeartButtonAnimation> createState() => _HeartButtonAnimationState();
}

class _HeartButtonAnimationState extends State<HeartButtonAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.85,
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

  void _handleTap() {
    _controller.forward().then((_) {
      _controller.reverse();
    });
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                widget.isLiked ? Icons.favorite : Icons.favorite_border,
                key: ValueKey(widget.isLiked),
                color: widget.isLiked 
                    ? AppColors.primaryAccent 
                    : AppColors.darkText.withOpacity(0.7),
                size: widget.size,
              ),
            ),
          );
        },
      ),
    );
  }
}