import 'package:flutter/material.dart';
import '../utils/theme.dart';

class LoadingWidgets {
  
  /// Primary loading indicator with custom styling
  static Widget primaryLoader({
    double size = 40,
    Color? color,
    double strokeWidth = 3,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        color: color ?? AppTheme.primaryBlue,
        strokeWidth: strokeWidth,
      ),
    );
  }

  /// Full screen loading overlay
  static Widget fullScreenLoader({
    String message = 'Loading...',
    bool showMessage = true,
  }) {
    return Container(
      color: Colors.white.withOpacity(0.9),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                color: AppTheme.primaryBlue,
                strokeWidth: 4,
              ),
            ),
            if (showMessage) ...[
              SizedBox(height: 24),
              Text(
                message,
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.lightGray,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Shimmer loading effect for cards
  static Widget shimmerCard({
    double height = 120,
    EdgeInsets margin = const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
  }) {
    return Container(
      margin: margin,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          height: height,
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _shimmerLine(width: 0.7),
              SizedBox(height: 12),
              _shimmerLine(width: 0.9),
              SizedBox(height: 8),
              _shimmerLine(width: 0.6),
              Spacer(),
              Row(
                children: [
                  _shimmerBox(width: 60, height: 20),
                  Spacer(),
                  _shimmerBox(width: 40, height: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Shimmer loading for list items
  static Widget shimmerListItem({
    bool showAvatar = true,
    EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
  }) {
    return Container(
      padding: padding,
      child: Row(
        children: [
          if (showAvatar) ...[
            _shimmerBox(width: 50, height: 50, borderRadius: 25),
            SizedBox(width: 16),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _shimmerLine(width: 0.8),
                SizedBox(height: 8),
                _shimmerLine(width: 0.6),
                SizedBox(height: 4),
                _shimmerLine(width: 0.4),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Loading button state
  static Widget loadingButton({
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
    Color? backgroundColor,
    Color? textColor,
    double height = 50,
    double borderRadius = 8,
  }) {
    return Container(
      width: double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppTheme.primaryBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          elevation: isLoading ? 0 : 2,
        ),
        child: isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: textColor ?? Colors.white,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Loading...',
                    style: TextStyle(
                      color: textColor ?? Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : Text(
                text,
                style: TextStyle(
                  color: textColor ?? Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  /// Skeleton loader for dashboard cards
  static Widget dashboardCardSkeleton() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _shimmerBox(width: 40, height: 40, borderRadius: 8),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _shimmerLine(width: 0.7),
                      SizedBox(height: 8),
                      _shimmerLine(width: 0.5),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            _shimmerLine(width: 0.9),
            SizedBox(height: 8),
            _shimmerLine(width: 0.6),
          ],
        ),
      ),
    );
  }

  /// Loading state for forms
  static Widget formFieldSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _shimmerLine(width: 0.3, height: 14),
        SizedBox(height: 8),
        _shimmerBox(width: double.infinity, height: 50, borderRadius: 8),
      ],
    );
  }

  /// Animated loading dots
  static Widget loadingDots({
    Color? color,
    double size = 8,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 600),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Container(
              margin: EdgeInsets.symmetric(horizontal: 4),
              child: Transform.scale(
                scale: 0.5 + (0.5 * value),
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    color: (color ?? AppTheme.primaryBlue).withOpacity(value),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }

  /// Pull to refresh loading
  static Widget pullToRefreshLoader() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          primaryLoader(size: 30),
          SizedBox(height: 8),
          Text(
            'Refreshing...',
            style: TextStyle(
              color: AppTheme.lightGray,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods for shimmer effects
  static Widget _shimmerLine({
    required double width,
    double height = 16,
  }) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 1200),
      tween: Tween(begin: 0.3, end: 1.0),
      builder: (context, value, child) {
        return Container(
          width: MediaQuery.of(context).size.width * width,
          height: height,
          decoration: BoxDecoration(
            color: AppTheme.lightGray.withOpacity(0.2 + (0.1 * value)),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      },
    );
  }

  static Widget _shimmerBox({
    required double width,
    required double height,
    double borderRadius = 4,
  }) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 1200),
      tween: Tween(begin: 0.3, end: 1.0),
      builder: (context, value, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: AppTheme.lightGray.withOpacity(0.2 + (0.1 * value)),
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        );
      },
    );
  }
}

/// Animated loading overlay widget
class LoadingOverlay extends StatefulWidget {
  final Widget child;
  final bool isLoading;
  final String message;

  const LoadingOverlay({
    Key? key,
    required this.child,
    required this.isLoading,
    this.message = 'Loading...',
  }) : super(key: key);

  @override
  _LoadingOverlayState createState() => _LoadingOverlayState();
}

class _LoadingOverlayState extends State<LoadingOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(LoadingOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading != oldWidget.isLoading) {
      if (widget.isLoading) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.isLoading)
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Opacity(
                opacity: _animation.value,
                child: LoadingWidgets.fullScreenLoader(
                  message: widget.message,
                ),
              );
            },
          ),
      ],
    );
  }
}
