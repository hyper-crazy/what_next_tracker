import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/content_constrains.dart';
import '../../widgets/media_card.dart';
import '../media/add_media_screen.dart';
import '../auth/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final user = FirebaseAuth.instance.currentUser;

  String _searchQuery = "";
  String _sortOption = 'Date';
  bool _isDescending = true;
  String _selectedStatus = 'All';
  String _selectedTypeFilter = 'All';

  List<QueryDocumentSnapshot> _processList(List<QueryDocumentSnapshot> docs) {
    List<QueryDocumentSnapshot> filteredList = docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final title = (data['title'] ?? '').toString().toLowerCase();
      final status = data['status'] ?? '';
      final type = data['type'] ?? '';

      if (_searchQuery.isNotEmpty && !title.contains(_searchQuery.toLowerCase())) return false;
      if (_selectedStatus != 'All' && status != _selectedStatus) return false;

      if (_selectedTypeFilter != 'All') {
        if (!type.startsWith(_selectedTypeFilter.substring(0, 4))) return false;
      }

      return true;
    }).toList();

    filteredList.sort((a, b) {
      final dataA = a.data() as Map<String, dynamic>;
      final dataB = b.data() as Map<String, dynamic>;
      int comparison = 0;

      switch (_sortOption) {
        case 'Title':
          comparison = (dataA['title'] ?? '').compareTo(dataB['title'] ?? '');
          break;
        case 'Rating':
          final rA = (dataA['rating'] ?? 0).toDouble();
          final rB = (dataB['rating'] ?? 0).toDouble();
          comparison = rA.compareTo(rB);
          break;
        case 'Date':
        default:
          final dA = (dataA['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
          final dB = (dataB['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
          comparison = dA.compareTo(dB);
          break;
      }
      return _isDescending ? -comparison : comparison;
    });

    return filteredList;
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
  }

  void _deleteMedia(String docId) async {
    await FirebaseFirestore.instance.collection('users').doc(user!.uid).collection('media').doc(docId).delete();
  }

  Widget _buildStatusFilterRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: AppConstants.statusFilters.map((label) {
          final isSelected = _selectedStatus == label;
          final theme = Theme.of(context);
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilterChip(
              label: Text(label),
              selected: isSelected,
              showCheckmark: false,
              onSelected: (bool selected) {
                setState(() {
                  if (selected) _selectedStatus = label;
                  else _selectedStatus = 'All';
                });
              },
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              backgroundColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
              selectedColor: theme.colorScheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSortRow() {
    final theme = Theme.of(context);
    final options = ['Date', 'Rating', 'Title'];

    return Row(
      children: options.map((opt) {
        final isSelected = _sortOption == opt;
        return Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: ActionChip(
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(opt),
                if (isSelected) ...[
                  const SizedBox(width: 4),
                  Icon(
                    _isDescending ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                    size: 14,
                    color: theme.colorScheme.onPrimaryContainer,
                  )
                ]
              ],
            ),
            backgroundColor: isSelected ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
            onPressed: () {
              setState(() {
                if (_sortOption == opt) {
                  _isDescending = !_isDescending;
                } else {
                  _sortOption = opt;
                  _isDescending = true;
                }
              });
            },
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
          ),
        );
      }).toList(),
    );
  }

  void _showTypeFilterMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Filter by Type", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 15),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: AppConstants.typeFilters.map((type) {
                  final isSelected = _selectedTypeFilter == type;
                  return ChoiceChip(
                    label: Text(type),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _selectedTypeFilter = type);
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final username = user?.displayName ?? "Friend";

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("What Next?", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            Text("Hello, $username", style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: _selectedTypeFilter != 'All',
              label: const Text("!"),
              child: Icon(_selectedTypeFilter == 'All' ? Icons.filter_list_rounded : Icons.filter_list_off_rounded),
            ),
            onPressed: _showTypeFilterMenu,
          ),
          IconButton(icon: const Icon(Icons.logout_rounded), onPressed: _logout),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: "Search your list...", prefixIcon: const Icon(Icons.search),
                filled: true, fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 15),

            Text("Status", style: theme.textTheme.labelMedium?.copyWith(color: Colors.grey)),
            const SizedBox(height: 5),
            _buildStatusFilterRow(),

            const SizedBox(height: 15),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Sort By", style: theme.textTheme.labelMedium?.copyWith(color: Colors.grey)),
                if (_selectedTypeFilter != 'All')
                  Text("Showing: $_selectedTypeFilter", style: TextStyle(fontSize: 10, color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 5),
            _buildSortRow(),

            const SizedBox(height: 15),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('users').doc(user!.uid).collection('media').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("Nothing to watch yet!"));

                  final displayedList = _processList(snapshot.data!.docs);

                  if (displayedList.isEmpty) return const Center(child: Text("No items match filters"));

                  return ListView.builder(
                    itemCount: displayedList.length,
                    itemBuilder: (context, index) {
                      final doc = displayedList[index];
                      return MediaCard(
                        data: doc.data() as Map<String, dynamic>,
                        documentId: doc.id,
                        onDelete: () => _deleteMedia(doc.id),
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => AddMediaScreen(docId: doc.id, existingData: doc.data() as Map<String, dynamic>)));
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddMediaScreen())),
        child: const Icon(Icons.add),
      ),
    );
  }
}