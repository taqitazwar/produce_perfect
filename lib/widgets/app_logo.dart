import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final double iconSize;
  final bool showShadow;

  const AppLogo({
    super.key,
    this.size = 120,
    this.iconSize = 60,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppConstants.primaryGradient,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusXLarge),
        boxShadow: showShadow ? [
          BoxShadow(
            color: AppConstants.primaryColor.withOpacity(0.3),
            blurRadius: size * 0.17, // Proportional blur
            offset: Offset(0, size * 0.08), // Proportional offset
          ),
        ] : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusXLarge),
        child: Image.asset(
          'assets/images/app_logo.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Fallback to icon if image not found
            return Icon(
              Icons.agriculture,
              size: iconSize,
              color: Colors.white,
            );
          },
        ),
      ),
    );
  }
}

// Alternative logo design with text
class AppLogoWithText extends StatelessWidget {
  final double size;
  final double iconSize;
  final bool showShadow;
  final bool showAppName;

  const AppLogoWithText({
    super.key,
    this.size = 120,
    this.iconSize = 60,
    this.showShadow = true,
    this.showAppName = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppLogo(
          size: size,
          iconSize: iconSize,
          showShadow: showShadow,
        ),
        if (showAppName) ...[
          SizedBox(height: size * 0.15),
          Text(
            AppConstants.appName,
            style: TextStyle(
              fontSize: size * 0.27,
              fontWeight: FontWeight.bold,
              color: AppConstants.textPrimary,
              letterSpacing: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: size * 0.04),
          Text(
            AppConstants.appTagline,
            style: TextStyle(
              fontSize: size * 0.13,
              color: AppConstants.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
