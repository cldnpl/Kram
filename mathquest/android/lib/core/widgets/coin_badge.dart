import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class CoinBadge extends StatelessWidget {
  const CoinBadge({super.key, this.coins = 0, this.onTap, this.pillStyle = false});

  final int coins;
  final VoidCallback? onTap;
  /// Stile pill: sfondo a capsula, bordo, coin giallo, numero nero.
  final bool pillStyle;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? AppColors.secondaryDark : AppColors.secondaryLight;
    final iconColor = pillStyle ? AppColors.secondaryLight : color;
    final textColor = pillStyle ? Colors.black : color;

    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.monetization_on, color: iconColor, size: 24),
        const SizedBox(width: 6),
        Text('$coins', style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
      ],
    );

    if (pillStyle) {
      content = Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.black.withOpacity(0.15)),
        ),
        child: content,
      );
    } else {
      content = Padding(padding: const EdgeInsets.only(right: 16), child: content);
    }

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: content,
      );
    }
    return content;
  }
}
