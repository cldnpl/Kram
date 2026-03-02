import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class CoinBadge extends StatelessWidget {
  const CoinBadge({super.key, this.coins = 0});

  final int coins;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? AppColors.secondaryDark : AppColors.secondaryLight;
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.monetization_on, color: color, size: 24),
          const SizedBox(width: 4),
          Text('$coins', style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
