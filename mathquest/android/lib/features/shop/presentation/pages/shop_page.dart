import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/l10n/app_locale.dart';
import '../../../../core/theme/app_colors.dart';

const _appPurple = AppColors.appPurple;

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  int _selectedIndex = 1; // Default to Pro

  List<_Plan> get _plans => [
    _Plan(
      name: AppLocale.tr('store_free'),
      price: null,
      priceLabel: AppLocale.tr('store_free'),
      icon: Icons.eco,
      iconColor: Colors.green,
      badge: null,
      summary: AppLocale.tr('store_summary_free'),
    ),
    _Plan(
      name: AppLocale.tr('store_pro'),
      price: 3.99,
      priceLabel: '\$3.99',
      icon: Icons.bolt,
      iconColor: AppColors.appPurple,
      badge: null,
      summary: AppLocale.tr('store_summary_pro'),
    ),
    _Plan(
      name: AppLocale.tr('store_max'),
      price: 8.99,
      priceLabel: '\$8.99',
      icon: Icons.workspace_premium,
      iconColor: Colors.orange,
      badge: AppLocale.tr('store_badge_best'),
      summary: AppLocale.tr('store_summary_max'),
    ),
  ];

  List<_ComparisonRow> get _comparisonFeatures => [
    _ComparisonRow(
      feature: AppLocale.tr('store_feature_camera_scans'),
      free: AppLocale.tr('store_value_5_day'),
      pro: AppLocale.tr('store_value_10_day'),
      max: AppLocale.tr('store_value_unlimited'),
    ),
    _ComparisonRow(feature: AppLocale.tr('store_feature_lesson_rewards'), free: '25%', pro: '60%', max: '100%'),
    _ComparisonRow(
      feature: AppLocale.tr('store_feature_lesson_refunds'),
      free: '-',
      pro: '-',
      max: AppLocale.tr('store_value_full'),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildPlanCards(),
            const SizedBox(height: 24),
            _buildComparison(),
            const SizedBox(height: 24),
            _buildSubscribeButton(),
            const SizedBox(height: 16),
            _buildFooter(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [AppColors.appPurple, Color(0xFF9966F0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Icon(Icons.workspace_premium, size: 36, color: Colors.white),
        ),
        const SizedBox(height: 12),
        Text(
          AppLocale.tr('store_unlock_title'),
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          AppLocale.tr('store_unlock_subtitle'),
          style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPlanCards() {
    final plans = _plans;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: List.generate(plans.length, (i) {
          final plan = plans[i];
          final isSelected = _selectedIndex == i;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _PlanCard(
              plan: plan,
              isSelected: isSelected,
              isCurrent: false,
              onTap: () => setState(() => _selectedIndex = i),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildComparison() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocale.tr('store_whats_included'),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      const Expanded(child: SizedBox()),
                      _comparisonHeader(AppLocale.tr('store_free'), Colors.green),
                      _comparisonHeader(AppLocale.tr('store_pro'), AppColors.appPurple),
                      _comparisonHeader(AppLocale.tr('store_max'), Colors.orange, width: 70),
                    ],
                  ),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ...List.generate(_comparisonFeatures.length, (i) {
                  return Column(
                    children: [
                      _buildComparisonRow(_comparisonFeatures[i]),
                      if (i < _comparisonFeatures.length - 1)
                        const Divider(height: 1, indent: 16, endIndent: 16),
                    ],
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _comparisonHeader(String label, Color color, {double width = 60}) {
    return SizedBox(
      width: width,
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildComparisonRow(_ComparisonRow row) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              row.feature,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          SizedBox(
            width: 60,
            child: Text(
              row.free,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: row.free == '-' ? Colors.grey.shade300 : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            width: 60,
            child: Text(
              row.pro,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: row.pro == '-' ? Colors.grey.shade300 : AppColors.appPurple,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            width: 70,
            child: Text(
              row.max,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: row.max == '-' ? Colors.grey.shade300 : Colors.orange,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscribeButton() {
    final plan = _plans[_selectedIndex];
    final isFree = plan.price == null;
    final label = isFree
        ? AppLocale.tr('store_switch_free')
        : AppLocale.trFormat('store_subscribe_format', [plan.name]);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(label)),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _appPurple,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
          child: Text(label),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        TextButton(
          onPressed: () {
            // TODO: restore purchases
          },
          child: Text(
            AppLocale.tr('store_restore'),
            style: TextStyle(fontSize: 14, color: _appPurple),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          AppLocale.tr('store_note'),
          style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _Plan {
  final String name;
  final double? price;
  final String priceLabel;
  final IconData icon;
  final Color iconColor;
  final String? badge;
  final String summary;

  const _Plan({
    required this.name,
    required this.price,
    required this.priceLabel,
    required this.icon,
    required this.iconColor,
    required this.badge,
    required this.summary,
  });
}

class _ComparisonRow {
  final String feature;
  final String free;
  final String pro;
  final String max;

  const _ComparisonRow({
    required this.feature,
    required this.free,
    required this.pro,
    required this.max,
  });
}

class _PlanCard extends StatelessWidget {
  final _Plan plan;
  final bool isSelected;
  final bool isCurrent;
  final VoidCallback onTap;

  const _PlanCard({
    required this.plan,
    required this.isSelected,
    required this.isCurrent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? _appPurple : Colors.grey.shade200,
            width: isSelected ? 2.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: plan.iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(plan.icon, size: 20, color: plan.iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        plan.name,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                      ),
                      if (isCurrent) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            AppLocale.tr('store_badge_current'),
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Colors.green,
                            ),
                          ),
                        ),
                      ],
                      if (plan.badge != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            plan.badge!,
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    plan.summary,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  plan.priceLabel,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: plan.price == null ? Colors.green : Colors.black,
                  ),
                ),
                if (plan.price != null)
                  Text(
                    AppLocale.tr('store_per_month'),
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
