import 'package:flutter/material.dart';
import '../../data/camera_models.dart';
import 'step_card.dart';

class SolutionPanel extends StatelessWidget {
  const SolutionPanel({
    super.key,
    required this.response,
    required this.visibleSteps,
    required this.onClose,
  });

  final SolveResponse response;
  final Set<int> visibleSteps;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
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

              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Header
                    Row(
                      children: [
                        Text(
                          'Solution',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const Spacer(),
                        DifficultyBadge(level: response.difficultyLevel),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: onClose,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Problem
                    Text(
                      'Problem',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      response.problem,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 16),

                    // Answer Card
                    AnswerCard(
                      answer: response.solution,
                      isVisible: visibleSteps.isNotEmpty,
                    ),
                    const SizedBox(height: 24),

                    // Steps
                    ...response.steps.asMap().entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: StepCard(
                          stepNumber: entry.key + 1,
                          content: entry.value,
                          isVisible: visibleSteps.contains(entry.key),
                        ),
                      );
                    }),
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
