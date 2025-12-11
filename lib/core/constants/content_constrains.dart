class AppConstants {
  // Content Types
  static const List<String> mediaTypes = [
    'Movie',
    'Series',
    'Anime',
    'Game',
    'Book'
  ];

  // Statuses (Unified)
  static const List<String> mediaStatuses = [
    'NEXT',
    'In Progress', // Watching, Reading, Playing
    'Completed',
    'On-Hold'
  ];

  // Filter Options
  static const List<String> statusFilters = ['All', ...mediaStatuses];
  static const List<String> typeFilters = ['All', 'Movies', 'Series', 'Anime', 'Games', 'Books'];
}