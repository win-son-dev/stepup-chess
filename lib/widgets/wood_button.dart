import 'package:flutter/material.dart';

/// A 3D-style button with press animation that matches the wood board aesthetic.
class WoodButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Color? color;
  final Color? shadowColor;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry padding;

  const WoodButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.color,
    this.shadowColor,
    this.height = 6,
    this.borderRadius = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
  });

  /// Green primary style (for main actions).
  factory WoodButton.primary({
    Key? key,
    required VoidCallback? onPressed,
    required Widget child,
    EdgeInsetsGeometry padding =
        const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
  }) {
    return WoodButton(
      key: key,
      onPressed: onPressed,
      color: const Color(0xFF558B2F),
      shadowColor: const Color(0xFF33691E),
      padding: padding,
      child: child,
    );
  }

  /// Wood/brown secondary style (for secondary actions).
  factory WoodButton.secondary({
    Key? key,
    required VoidCallback? onPressed,
    required Widget child,
    EdgeInsetsGeometry padding =
        const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
  }) {
    return WoodButton(
      key: key,
      onPressed: onPressed,
      color: const Color(0xFF8D6E63),
      shadowColor: const Color(0xFF5D4037),
      padding: padding,
      child: child,
    );
  }

  /// Outlined/ghost style on cream background.
  factory WoodButton.outlined({
    Key? key,
    required VoidCallback? onPressed,
    required Widget child,
    EdgeInsetsGeometry padding =
        const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
  }) {
    return WoodButton(
      key: key,
      onPressed: onPressed,
      color: const Color(0xFFFFF3E0),
      shadowColor: const Color(0xFFD7CCC8),
      height: 4,
      padding: padding,
      child: child,
    );
  }

  @override
  State<WoodButton> createState() => _WoodButtonState();
}

class _WoodButtonState extends State<WoodButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pressAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    );
    _pressAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (widget.onPressed != null) _controller.forward();
  }

  void _onTapUp(TapUpDetails _) {
    _controller.reverse();
    widget.onPressed?.call();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;
    final shadowColor = widget.shadowColor ??
        HSLColor.fromColor(color)
            .withLightness(
                (HSLColor.fromColor(color).lightness - 0.15).clamp(0, 1))
            .toColor();
    final disabled = widget.onPressed == null;
    final effectiveColor = disabled ? color.withValues(alpha: 0.5) : color;
    final effectiveShadow =
        disabled ? shadowColor.withValues(alpha: 0.3) : shadowColor;

    // Is this the outlined/light style?
    final isLight = HSLColor.fromColor(color).lightness > 0.8;
    final textColor = isLight
        ? const Color(0xFF5D4037)
        : Colors.white;

    return AnimatedBuilder(
      animation: _pressAnimation,
      builder: (context, child) {
        final press = _pressAnimation.value;
        final yOffset = widget.height * (1 - press);

        return GestureDetector(
          onTapDown: disabled ? null : _onTapDown,
          onTapUp: disabled ? null : _onTapUp,
          onTapCancel: disabled ? null : _onTapCancel,
          child: Transform.translate(
            offset: Offset(0, widget.height - yOffset),
            child: Container(
              padding: widget.padding,
              decoration: BoxDecoration(
                color: effectiveColor,
                borderRadius: BorderRadius.circular(widget.borderRadius),
                boxShadow: [
                  BoxShadow(
                    color: effectiveShadow,
                    offset: Offset(0, yOffset),
                    blurRadius: 0,
                  ),
                ],
                border: isLight
                    ? Border.all(
                        color: const Color(0xFF8D6E63).withValues(alpha: 0.3))
                    : null,
              ),
              child: DefaultTextStyle.merge(
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                child: IconTheme.merge(
                  data: IconThemeData(color: textColor, size: 22),
                  child: child!,
                ),
              ),
            ),
          ),
        );
      },
      child: Center(child: widget.child),
    );
  }
}
