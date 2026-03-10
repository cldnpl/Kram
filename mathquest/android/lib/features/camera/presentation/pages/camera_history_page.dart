import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/l10n/app_locale.dart';
import '../../data/camera_api.dart';
import '../../data/camera_models.dart';
import '../widgets/step_card.dart';

class CameraHistoryPage extends StatefulWidget {
  const CameraHistoryPage({
    super.key,
    required this.history,
  });

  final List<HistoryItem> history;

  @override
  State<CameraHistoryPage> createState() => _CameraHistoryPageState();
}

class _CameraHistoryPageState extends State<CameraHistoryPage> {
  final _dateFormat = DateFormat('MMM d, yyyy h:mm a', AppLocale.current);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocale.tr('history_title')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocale.tr('done')),
          ),
        ],
      ),
      body: widget.history.isEmpty ? _buildEmptyState() : _buildHistoryList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 60,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            AppLocale.tr('history_empty_title'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            AppLocale.tr('history_empty_subtitle'),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: widget.history.length,
      itemBuilder: (context, index) {
        final item = widget.history[index];
        return _HistoryItemTile(
          item: item,
          dateFormat: _dateFormat,
          onTap: () => _showDetail(item.id),
        );
      },
    );
  }

  Future<void> _showDetail(int id) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final api = CameraApi();
      final detail = await api.getHistoryDetail(id);

      if (mounted) {
        Navigator.pop(context); // Close loading
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => _HistoryDetailSheet(detail: detail),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocale.tr('error')}: $e')),
        );
      }
    }
  }
}

class _HistoryItemTile extends StatelessWidget {
  const _HistoryItemTile({
    required this.item,
    required this.dateFormat,
    required this.onTap,
  });

  final HistoryItem item;
  final DateFormat dateFormat;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      title: Text(
        item.problem,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '= ${item.solution}',
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              DifficultyBadge(level: item.difficultyLevel),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            dateFormat.format(item.createdAt),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}

class _HistoryDetailSheet extends StatefulWidget {
  const _HistoryDetailSheet({required this.detail});

  final HistoryDetailResponse detail;

  @override
  State<_HistoryDetailSheet> createState() => _HistoryDetailSheetState();
}

class _HistoryDetailSheetState extends State<_HistoryDetailSheet> {
  Set<int> _visibleSteps = {};

  @override
  void initState() {
    super.initState();
    _animateSteps();
  }

  Future<void> _animateSteps() async {
    for (int i = 0; i < widget.detail.steps.length; i++) {
      await Future.delayed(const Duration(milliseconds: 200));
      if (mounted) {
        setState(() => _visibleSteps = {..._visibleSteps, i});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      AppLocale.tr('solution'),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    // Problem
                    Text(
                      AppLocale.tr('problem'),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.detail.problem,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),

                    // Answer
                    AnswerCard(
                      answer: widget.detail.solution,
                      isVisible: true,
                    ),
                    const SizedBox(height: 8),

                    // Difficulty
                    Row(
                      children: [
                        Text(
                          AppLocale.tr('difficulty'),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        const Spacer(),
                        DifficultyBadge(level: widget.detail.difficultyLevel),
                      ],
                    ),
                    const Divider(height: 32),

                    // Steps
                    Text(
                      AppLocale.tr('solution_steps'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    ...widget.detail.steps.asMap().entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: StepCard(
                          stepNumber: entry.key + 1,
                          content: entry.value,
                          isVisible: _visibleSteps.contains(entry.key),
                        ),
                      );
                    }),

                    // LaTeX
                    if (widget.detail.rawLatex.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'LaTeX',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.detail.rawLatex,
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
