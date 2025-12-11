import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/content_constrains.dart';

class AddMediaScreen extends StatefulWidget {
  final String? docId;
  final Map<String, dynamic>? existingData;

  const AddMediaScreen({super.key, this.docId, this.existingData});

  @override
  State<AddMediaScreen> createState() => _AddMediaScreenState();
}

class _AddMediaScreenState extends State<AddMediaScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _notesController;

  // Progress Controllers
  late TextEditingController _progressCurrentController;
  late TextEditingController _progressTotalController;

  String _selectedType = AppConstants.mediaTypes.first;
  String _selectedStatus = AppConstants.mediaStatuses.first;
  double _rating = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill existing data if editing
    final data = widget.existingData;

    _titleController = TextEditingController(text: data?['title'] ?? '');
    _notesController = TextEditingController(text: data?['notes'] ?? '');

    // Handle Progress Data
    _progressCurrentController = TextEditingController(text: (data?['progressCurrent'] ?? '').toString());
    _progressTotalController = TextEditingController(text: (data?['progressTotal'] ?? '').toString());

    if (data != null) {
      _selectedType = data['type'];
      _selectedStatus = data['status'];
      _rating = (data['rating'] ?? 0).toDouble();

      // Validate dropdown values match current constants
      if (!AppConstants.mediaTypes.contains(_selectedType)) _selectedType = AppConstants.mediaTypes.first;
      if (!AppConstants.mediaStatuses.contains(_selectedStatus)) _selectedStatus = AppConstants.mediaStatuses.first;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _progressCurrentController.dispose();
    _progressTotalController.dispose();
    super.dispose();
  }

  // Helper: Check if this type needs tracking
  bool get _isTrackable {
    return ['Series', 'Anime', 'Book'].contains(_selectedType);
  }

  // Helper: Get label (Episodes vs Pages)
  String get _unitLabel {
    return _selectedType == 'Book' ? 'Pages' : 'Episodes';
  }

  void _saveMedia() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      final collection = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('media');

      final dataMap = {
        'title': _titleController.text.trim(),
        'type': _selectedType,
        'status': _selectedStatus,
        'rating': _rating,
        'notes': _notesController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Only save progress if trackable
      if (_isTrackable) {
        dataMap['progressCurrent'] = int.tryParse(_progressCurrentController.text) ?? 0;
        dataMap['progressTotal'] = int.tryParse(_progressTotalController.text) ?? 0;
      } else {
        // Reset progress if switching to Movie/Game
        dataMap['progressCurrent'] = 0;
        dataMap['progressTotal'] = 0;
      }

      if (widget.docId != null) {
        await collection.doc(widget.docId).update(dataMap);
      } else {
        dataMap['createdAt'] = FieldValue.serverTimestamp();
        await collection.add(dataMap);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.docId != null ? "Updated!" : "Added!")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.docId != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? "Edit Item" : "Add New Item")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              TextFormField(
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Title', prefixIcon: Icon(Icons.title)),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 20),

              // Dropdowns
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedType,
                      decoration: const InputDecoration(labelText: 'Type'),
                      items: AppConstants.mediaTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                      onChanged: (val) => setState(() => _selectedType = val!),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedStatus,
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: AppConstants.mediaStatuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (val) => setState(() => _selectedStatus = val!),
                    ),
                  ),
                ],
              ),

              // Progress Section (Conditional)
              if (_isTrackable) ...[
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _progressCurrentController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Completed $_unitLabel',
                          hintText: '0',
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 15),
                      child: Text("/", style: TextStyle(fontSize: 20, color: Colors.grey)),
                    ),
                    Expanded(
                      child: TextFormField(
                        controller: _progressTotalController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Total $_unitLabel',
                          hintText: '?',
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 20),

              // Rating
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Rating"),
                  Text(_rating > 0 ? _rating.toStringAsFixed(1) : "Unrated", style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              Slider(
                value: _rating, min: 0, max: 10, divisions: 20, label: _rating.toString(),
                onChanged: (val) => setState(() => _rating = val),
              ),
              const SizedBox(height: 10),

              // Notes
              TextFormField(
                controller: _notesController, maxLines: 3,
                decoration: const InputDecoration(labelText: 'Notes', prefixIcon: Icon(Icons.notes)),
              ),
              const SizedBox(height: 30),

              // Save Button
              SizedBox(
                height: 50,
                child: FilledButton(
                  onPressed: _isLoading ? null : _saveMedia,
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white)
                      : Text(isEditing ? "Update Item" : "Save Item"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}