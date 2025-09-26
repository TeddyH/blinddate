import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class BadgeIcon extends StatelessWidget {
  final Widget icon;
  final int badgeCount;
  final Color? badgeColor;
  final Color? textColor;
  final double? badgeSize;

  const BadgeIcon({
    super.key,
    required this.icon,
    required this.badgeCount,
    this.badgeColor,
    this.textColor,
    this.badgeSize,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        icon,
        if (badgeCount > 0)
          Positioned(
            right: -6,
            top: -6,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: badgeColor ?? AppColors.error,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.white,
                  width: 1.5,
                ),
              ),
              constraints: BoxConstraints(
                minWidth: badgeSize ?? 18,
                minHeight: badgeSize ?? 18,
              ),
              child: Text(
                badgeCount > 99 ? '99+' : badgeCount.toString(),
                style: TextStyle(
                  color: textColor ?? Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}