import 'package:flutter/material.dart';
import 'package:wpfactcheck/core/constants/app_constants.dart';
import 'package:wpfactcheck/core/utils/extensions.dart';
import 'package:wpfactcheck/data/models/fact_check_result.dart';

class FactCheckResultSheet extends StatelessWidget {
  final FactCheckResult? result;

  const FactCheckResultSheet({
    super.key,
    this.result,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppConstants.borderRadius * 2),
        ),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: AppConstants.gridSpacing),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Content
              Expanded(
                child: result != null 
                    ? _buildResultContent(context, scrollController)
                    : _buildMockContent(context, scrollController),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMockContent(BuildContext context, ScrollController scrollController) {
    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(AppConstants.gridSpacing * 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppConstants.gridSpacing),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                ),
                child: Icon(
                  Icons.warning_amber,
                  color: Colors.orange,
                  size: AppConstants.iconSize,
                ),
              ),
              const SizedBox(width: AppConstants.gridSpacing * 2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Partially True',
                      style: context.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Confidence: 78%',
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppConstants.gridSpacing * 3),
          
          // Explanation
          Text(
            'Analysis',
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.gridSpacing),
          Text(
            'This claim contains some accurate information but lacks important context. While the core facts are correct, the presentation may be misleading without additional details.',
            style: context.textTheme.bodyLarge,
          ),
          
          const SizedBox(height: AppConstants.gridSpacing * 3),
          
          // Key Points
          Text(
            'Key Points',
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.gridSpacing),
          ...[
            '✓ Core statistical data is accurate',
            '⚠ Missing important context about methodology',
            '✗ Timeline information is incomplete',
          ].map((point) => Padding(
            padding: const EdgeInsets.only(bottom: AppConstants.gridSpacing / 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  point.substring(0, 1),
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: point.startsWith('✓') 
                        ? Colors.green.withAlpha(102) 
                        : point.startsWith('⚠') 
                            ? Colors.orange 
                            : Colors.red,
                  ),
                ),
                const SizedBox(width: AppConstants.gridSpacing),
                Expanded(
                  child: Text(
                    point.substring(2),
                    style: context.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          )),
          
          const SizedBox(height: AppConstants.gridSpacing * 3),
          
          // Sources
          Text(
            'Sources',
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.gridSpacing),
          ...[
            'Reuters - Original report',
            'Associated Press - Verification',
            'Government database - Statistics',
          ].map((source) => Padding(
            padding: const EdgeInsets.only(bottom: AppConstants.gridSpacing / 2),
            child: Row(
              children: [
                Icon(
                  Icons.link,
                  size: 16,
                  color: context.colorScheme.primary,
                ),
                const SizedBox(width: AppConstants.gridSpacing),
                Expanded(
                  child: Text(
                    source,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.colorScheme.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          )),
          
          const SizedBox(height: AppConstants.gridSpacing * 3),
          
          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Implement share functionality
                  },
                  icon: const Icon(Icons.share),
                  label: const Text('Share'),
                ),
              ),
              const SizedBox(width: AppConstants.gridSpacing * 2),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    // TODO: Implement save functionality
                  },
                  icon: const Icon(Icons.bookmark),
                  label: const Text('Save'),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppConstants.gridSpacing * 2),
          
          // Footer
          Center(
            child: Text(
              'Analysis completed • ${DateTime.now().timeAgo}',
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultContent(BuildContext context, ScrollController scrollController) {
    // TODO: Implement actual result content when result is provided
    return _buildMockContent(context, scrollController);
  }
}
