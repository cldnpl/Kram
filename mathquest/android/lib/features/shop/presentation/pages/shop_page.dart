import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const _packages = [
  (coins: 25, price: 2.99),
  (coins: 60, price: 5.0),
  (coins: 200, price: 15.0),
  (coins: 500, price: 49.99),
];

class ShopPage extends StatelessWidget {
  const ShopPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Coin Shop'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Get more coins',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 24),
          ..._packages.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ShopCard(coins: p.coins, price: p.price),
              )),
        ],
      ),
    );
  }
}

class _ShopCard extends StatelessWidget {
  const _ShopCard({required this.coins, required this.price});

  final int coins;
  final double price;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Icon(Icons.monetization_on, color: Theme.of(context).colorScheme.primary, size: 40),
        title: Text(
          '$coins coins',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('€${price.toStringAsFixed(price == price.roundToDouble() ? 0 : 2)}'),
        trailing: FilledButton(
          onPressed: () {
            // TODO: integrate in-app purchase
          },
          child: const Text('Purchase'),
        ),
      ),
    );
  }
}
