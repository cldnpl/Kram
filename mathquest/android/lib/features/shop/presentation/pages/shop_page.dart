import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';

const _appPurple = AppColors.appPurple;

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  int _selectedIndex = 1; // Default to Pro

  static const _plans = [
    _Plan(
      name: 'Free',
      price: null,
      priceLabel: 'Free',
      icon: Icons.eco,
      iconColor: Colors.green,
      badge: null,
      features: ['5 camera scans/day', '25% lesson rewards', 'Basic features'],
      summary: '5 camera scans/day and standard lesson rewards',
    ),
    _Plan(
      name: 'Pro',
      price: 3.99,
      priceLabel: '\$3.99',
      icon: Icons.bolt,
      iconColor: AppColors.appPurple,
      badge: null,
      features: ['10 camera scans/day', '60% lesson rewards', 'Priority support'],
      summary: '10 camera scans/day and boosted lesson rewards',
    ),
    _Plan(
      name: 'Max',
      price: 8.99,
      priceLabel: '\$8.99',
      icon: Icons.workspace_premium,
      iconColor: Colors.orange,
      badge: 'BEST',
      features: [
        'Unlimited camera scans',
        '100% lesson rewards',
        'Full lesson refunds',
        'All Pro features',
      ],
      summary: 'Unlimited camera scans and full lesson refunds',
    ),
  ];

  static const _comparisonFeatures = [
    _ComparisonRow(feature: 'Camera Scans', free: '5/day', pro: '10/day', max: 'Unlimited'),
    _ComparisonRow(feature: 'Lesson Rewards', free: '25%', pro: '60%', max: '100%'),
    _ComparisonRow(feature: 'Lesson Refunds', free: '-', pro: '-', max: 'Full'),
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
            // Hero header
            _buildHeader(),
            const SizedBox(height: 24),
            // Plan cards
            _buildPlanCards(),
            const SizedBox(height: 24),
            // Feature comparison
            _buildComparison(),
            const SizedBox(height: 24),
            // Subscribe button
            _buildSubscribeButton(),
            const SizedBox(height: 16),
            // Footer
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
        const Text(
          'Unlock Your Full Potential',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          'Choose the plan that fits your learning goals',
          style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPlanCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: List.generate(_plans.length, (i) {
          final plan = _plans[i];
          final isSelected = _selectedIndex == i;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _PlanCard(
              plan: plan,
              isSelected: isSelected,
              isCurrent: false, // TODO: check actual subscription
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
            "What's included",
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
                // Column headers
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      const Expanded(child: SizedBox()),
                      _comparisonHeader('Free', Colors.green),
                      _comparisonHeader('Pro', AppColors.appPurple),
                      _comparisonHeader('Max', Colors.orange, width: 70),
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
    final label = isFree ? 'Switch to Free' : 'Subscribe to ${plan.name}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: () {
            // TODO: integrate in-app purchase
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${plan.name} plan selected')),
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
            'Restore Purchases',
            style: TextStyle(fontSize: 14, color: _appPurple),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Subscriptions renew monthly. Cancel anytime in Settings.',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// MARK: - Data models

class _Plan {
  final String name;
  final double? price;
  final String priceLabel;
  final IconData icon;
  final Color iconColor;
  final String? badge;
  final List<String> features;
  final String summary;

  const _Plan({
    required this.name,
    required this.price,
    required this.priceLabel,
    required this.icon,
    required this.iconColor,
    required this.badge,
    required this.features,
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

// MARK: - Plan Card Widget

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
            // Icon
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
            // Info
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
                          child: const Text(
                            'CURRENT',
                            style: TextStyle(
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
            // Price
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
                    '/month',
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
