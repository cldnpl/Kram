import 'package:flutter/material.dart';

class StepCard extends StatelessWidget {
  const StepCard({
    super.key,
    required this.stepNumber,
    required this.content,
    required this.isVisible,
  });

  final int stepNumber;
  final String content;
  final bool isVisible;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: isVisible ? 1 : 0,
      duration: const Duration(milliseconds: 300),
      child: AnimatedSlide(
        offset: isVisible ? Offset.zero : const Offset(0, 0.2),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$stepNumber',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  content,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AnswerCard extends StatelessWidget {
  const AnswerCard({
    super.key,
    required this.answer,
    required this.isVisible,
  });

  final String answer;
  final bool isVisible;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: isVisible ? 1.0 : 0.8,
      duration: const Duration(milliseconds: 400),
      curve: Curves.elasticOut,
      child: AnimatedOpacity(
        opacity: isVisible ? 1 : 0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Text(
                'Answer',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                answer,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DifficultyBadge extends StatelessWidget {
  const DifficultyBadge({
    super.key,
    required this.level,
  });

  final String level;

  Color get _color {
    switch (level.toLowerCase()) {
      case 'elementary':
        return Colors.green;
      case 'middle_school':
        return Colors.blue;
      case 'high_school':
        return Colors.orange;
      case 'college':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String get _displayText {
    switch (level.toLowerCase()) {
      case 'elementary':
        return 'Elementary';
      case 'middle_school':
        return 'Middle School';
      case 'high_school':
        return 'High School';
      case 'college':
        return 'College';
      default:
        return level;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _displayText,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: _color,
        ),
      ),
    );
  }
}
