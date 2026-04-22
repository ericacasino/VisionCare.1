import 'package:flutter/material.dart';

// Shimmer gradient for the loading effect
const _shimmerGradient = LinearGradient(
  colors: [
    Color.fromARGB(255, 57, 163, 22),
    Color.fromARGB(255, 46, 216, 8),
    Color.fromARGB(255, 2, 255, 2),
  ],
  stops: [0.1, 0.3, 0.4],
  begin: Alignment(-1.0, -0.3),
  end: Alignment(1.0, 0.3),
  tileMode: TileMode.clamp,
);

// Shimmer widget that controls the animation
class Shimmer extends StatefulWidget {
  const Shimmer({
    super.key,
    required this.linearGradient,
    required this.child,
  });

  final LinearGradient linearGradient;
  final Widget child;

  @override
  State<Shimmer> createState() => _ShimmerState();

  static _ShimmerState? of(BuildContext context) {
    return context.findAncestorStateOfType<_ShimmerState>();
  }
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController.unbounded(vsync: this)
      ..repeat(min: -0.5, max: 1.5, period: const Duration(milliseconds: 1000));
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  Listenable get shimmerChanges => _shimmerController;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return widget.linearGradient.createShader(
              Rect.fromLTWH(
                -bounds.width * _shimmerController.value,
                0,
                bounds.width * 3,
                bounds.height,
              ),
            );
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

// ShimmerLoading widget that applies the shimmer effect to its child
class ShimmerLoading extends StatefulWidget {
  const ShimmerLoading({
    super.key,
    required this.isLoading,
    required this.child,
  });

  final bool isLoading;
  final Widget child;

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading> {
  Listenable? _shimmerChanges;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_shimmerChanges != null) {
      _shimmerChanges!.removeListener(_onShimmerChange);
    }
    _shimmerChanges = Shimmer.of(context)?.shimmerChanges;
    if (_shimmerChanges != null) {
      _shimmerChanges!.addListener(_onShimmerChange);
    }
  }

  @override
  void dispose() {
    _shimmerChanges?.removeListener(_onShimmerChange);
    super.dispose();
  }

  void _onShimmerChange() {
    if (widget.isLoading) {
      setState(() {
        // Update the shimmer painting.
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) {
      return widget.child;
    }

    // If no ancestor Shimmer widget is found, create one
    if (Shimmer.of(context) == null) {
      return Shimmer(
        linearGradient: _shimmerGradient,
        child: ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return _shimmerGradient.createShader(bounds);
          },
          child: widget.child,
        ),
      );
    }

    // If an ancestor Shimmer widget exists, use ShaderMask directly
    return ShaderMask(
      blendMode: BlendMode.srcATop,
      shaderCallback: (bounds) {
        return _shimmerGradient.createShader(bounds);
      },
      child: widget.child,
    );
  }
}

// Full-screen loading overlay with shimmer effect
class ShimmerLoadingOverlay extends StatelessWidget {
  const ShimmerLoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
  });

  final bool isLoading;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: Shimmer(
                  linearGradient: _shimmerGradient,
                  child: Container(
                    width: 200,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Text(
                        'Loading...',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}