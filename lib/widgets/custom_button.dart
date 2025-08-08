import 'package:flutter/material.dart';
import 'dart:ui';

enum CustomButtonType {
  primary,
  secondary,
  outline,
  text,
  danger,
}

enum CustomButtonSize {
  small,
  medium,
  large,
}

class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final CustomButtonType type;
  final CustomButtonSize size;
  final bool isLoading;
  final bool isFullWidth;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final Color? textColor;
  final double? borderRadius;

  const CustomButton({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.type = CustomButtonType.primary,
    this.size = CustomButtonSize.medium,
    this.isLoading = false,
    this.isFullWidth = false,
    this.padding,
    this.backgroundColor,
    this.textColor,
    this.borderRadius,
  });

  // Named constructors for different button types
  const CustomButton.primary({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.size = CustomButtonSize.medium,
    this.isLoading = false,
    this.isFullWidth = false,
    this.padding,
    this.backgroundColor,
    this.textColor,
    this.borderRadius,
  }) : type = CustomButtonType.primary;

  const CustomButton.secondary({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.size = CustomButtonSize.medium,
    this.isLoading = false,
    this.isFullWidth = false,
    this.padding,
    this.backgroundColor,
    this.textColor,
    this.borderRadius,
  }) : type = CustomButtonType.secondary;

  const CustomButton.outline({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.size = CustomButtonSize.medium,
    this.isLoading = false,
    this.isFullWidth = false,
    this.padding,
    this.backgroundColor,
    this.textColor,
    this.borderRadius,
  }) : type = CustomButtonType.outline;

  const CustomButton.text({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.size = CustomButtonSize.medium,
    this.isLoading = false,
    this.isFullWidth = false,
    this.padding,
    this.backgroundColor,
    this.textColor,
    this.borderRadius,
  }) : type = CustomButtonType.text;

  const CustomButton.danger({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.size = CustomButtonSize.medium,
    this.isLoading = false,
    this.isFullWidth = false,
    this.padding,
    this.backgroundColor,
    this.textColor,
    this.borderRadius,
  }) : type = CustomButtonType.danger;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sizeConfig = _getSizeConfig();
    final effectivePadding = padding ?? sizeConfig['padding'] as EdgeInsetsGeometry;
    final fontSize = sizeConfig['fontSize'] as double;
    final iconSize = sizeConfig['iconSize'] as double;

    Widget buttonContent = _buildButtonContent(fontSize, iconSize);
    if (isFullWidth) {
      buttonContent = SizedBox(width: double.infinity, child: buttonContent);
    }

    // Micro-interaction: scale on tap
    return GestureDetector(
      onTapDown: (_) => _buttonScale.value = 0.97,
      onTapUp: (_) => _buttonScale.value = 1.0,
      onTapCancel: () => _buttonScale.value = 1.0,
      child: ValueListenableBuilder<double>(
        valueListenable: _buttonScale,
        builder: (context, scale, child) {
          return AnimatedScale(
            scale: scale,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            child: _buildStyledButton(context, buttonContent, effectivePadding, colorScheme),
          );
        },
      ),
    );
  }

  final ValueNotifier<double> _buttonScale = ValueNotifier(1.0);

  Widget _buildStyledButton(BuildContext context, Widget child, EdgeInsetsGeometry padding, ColorScheme colorScheme) {
    final glassGradient = LinearGradient(
      colors: [
        colorScheme.primary.withOpacity(0.18),
        colorScheme.primary.withOpacity(0.08),
        Colors.white.withOpacity(0.12),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    final glassShadow = [
      BoxShadow(
        color: colorScheme.primary.withOpacity(0.13),
        blurRadius: 24,
        offset: const Offset(0, 8),
      ),
      BoxShadow(
        color: Colors.white.withOpacity(0.08),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ];
    final borderRadius = BorderRadius.circular(this.borderRadius ?? 32);

    Color? bgColor;
    Color? fgColor;
    switch (type) {
      case CustomButtonType.primary:
        bgColor = backgroundColor ?? colorScheme.primary.withOpacity(0.85);
        fgColor = textColor ?? colorScheme.onPrimary;
        break;
      case CustomButtonType.secondary:
        bgColor = backgroundColor ?? colorScheme.secondaryContainer.withOpacity(0.7);
        fgColor = textColor ?? colorScheme.onSecondaryContainer;
        break;
      case CustomButtonType.danger:
        bgColor = backgroundColor ?? colorScheme.error.withOpacity(0.85);
        fgColor = textColor ?? colorScheme.onError;
        break;
      default:
        bgColor = backgroundColor ?? Colors.transparent;
        fgColor = textColor ?? colorScheme.primary;
    }

    return ClipRRect(
      borderRadius: borderRadius,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glassmorphism background
          if (type == CustomButtonType.primary || type == CustomButtonType.secondary || type == CustomButtonType.danger)
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                decoration: BoxDecoration(
                  gradient: glassGradient,
                  color: bgColor,
                  borderRadius: borderRadius,
                  boxShadow: glassShadow,
                  border: Border.all(
                    color: colorScheme.primary.withOpacity(0.10),
                    width: 1.2,
                  ),
                ),
                padding: padding,
                child: Center(child: DefaultTextStyle.merge(style: TextStyle(color: fgColor), child: child)),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: borderRadius,
              ),
              padding: padding,
              child: Center(child: DefaultTextStyle.merge(style: TextStyle(color: fgColor), child: child)),
            ),
        ],
      ),
    );
  }

  Widget _buildButtonContent(double fontSize, double iconSize) {
    if (isLoading) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: iconSize,
            height: iconSize,
            child: const CircularProgressIndicator(
              strokeWidth: 2,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Loading...',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    return Text(
      label,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Map<String, dynamic> _getSizeConfig() {
    switch (size) {
      case CustomButtonSize.small:
        return {
          'padding': const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          'fontSize': 14.0,
          'iconSize': 18.0,
        };
      case CustomButtonSize.medium:
        return {
          'padding': const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          'fontSize': 16.0,
          'iconSize': 20.0,
        };
      case CustomButtonSize.large:
        return {
          'padding': const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
          'fontSize': 18.0,
          'iconSize': 22.0,
        };
    }
  }
}