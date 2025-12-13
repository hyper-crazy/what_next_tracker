import 'package:flutter/material.dart';

class MediaCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String documentId;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const MediaCard({
    super.key,
    required this.data,
    required this.documentId,
    required this.onDelete,
    required this.onTap,
  });

  Color _getStatusColor(String status) {
    switch (status) {
      case 'NEXT': return Colors.purpleAccent;
      case 'In Progress': return Colors.blue;
      case 'Completed': return Colors.green;
      case 'On-Hold': return Colors.grey;
      default: return Colors.blue;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'Game': return Colors.redAccent;
      case 'Book': return Colors.brown;
      case 'Anime': return Colors.pinkAccent;
      case 'Series': return Colors.orange;
      case 'Movie': return Colors.teal;
      default: return Colors.blueGrey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'Book': return Icons.menu_book_rounded;
      case 'Game': return Icons.gamepad_rounded;
      case 'Anime': return Icons.tv_rounded;
      case 'Series': return Icons.tv_rounded;
      case 'Movie':
      default: return Icons.movie_creation_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String title = data['title'] ?? 'Untitled';
    final String type = data['type'] ?? 'Movie';
    final String status = data['status'] ?? 'NEXT';
    final double rating = (data['rating'] ?? 0).toDouble();

    // Get Progress Data
    final int current = data['progressCurrent'] ?? 0;
    final int total = data['progressTotal'] ?? 0;
    final bool hasProgress = total > 0 || current > 0;
    final String unit = type == 'Book' ? 'pgs' : 'eps';

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainer,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Icon Box
              Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  color: _getTypeColor(type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_getTypeIcon(type), color: _getTypeColor(type)),
              ),
              const SizedBox(width: 16),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        // Type Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceDim,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.grey.withOpacity(0.3)),
                          ),
                          child: Text(
                            type.toUpperCase(),
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ),
                        // Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getStatusColor(status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: _getStatusColor(status).withOpacity(0.5), width: 0.5),
                          ),
                          child: Text(
                            status.toUpperCase(),
                            style: TextStyle(fontSize: 9, color: _getStatusColor(status), fontWeight: FontWeight.bold),
                          ),
                        ),
                        // Progress Badge (Only shows if there is progress)
                        if (hasProgress)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondaryContainer.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              "$current/$total $unit",
                              style: TextStyle(fontSize: 9, color: theme.colorScheme.onSecondaryContainer, fontWeight: FontWeight.bold),
                            ),
                          ),

                        // Rating
                        if (rating > 0) ...[
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star_rounded, size: 14, color: Colors.amber.shade700),
                              const SizedBox(width: 2),
                              Text(rating.toStringAsFixed(1), style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
                            ],
                          )
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.grey),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}