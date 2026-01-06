import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Needed for data deletion
import '../../core/constants/validators.dart';
import '../../widgets/password_checklist.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final user = FirebaseAuth.instance.currentUser;
  final _formKey = GlobalKey<FormState>();

  // Profile Controllers
  late TextEditingController _nameController;
  late TextEditingController _emailController;

  // Password Change Controllers
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();

  // Delete Account Controller
  final _deletePasswordController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: user?.displayName ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _deletePasswordController.dispose();
    super.dispose();
  }

  // --- ACTIONS ---

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final String newName = _nameController.text.trim();

      // 1. Update Auth Profile (The one used for Login/Auth)
      await user?.updateDisplayName(newName);
      await user?.reload(); // Refresh local user data

      // 2. Update Firestore Database (The one stored in your 'users' collection)
      // We use 'username' because that matches your Signup screen logic
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({'username': newName});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _changePassword() async {
    // ... (Same password change logic as before) ...
    final currentPass = _currentPasswordController.text.trim();
    final newPass = _newPasswordController.text.trim();

    if (currentPass.isEmpty || newPass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in both fields'), backgroundColor: Colors.orange));
      return;
    }

    final String? validationError = Validators.validatePassword(newPass);
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(validationError), backgroundColor: Colors.red));
      return;
    }

    try {
      final email = user?.email;
      if (email == null) return;
      AuthCredential credential = EmailAuthProvider.credential(email: email, password: currentPass);
      await user?.reauthenticateWithCredential(credential);
      await user?.updatePassword(newPass);

      if (mounted) {
        Navigator.pop(context);
        _currentPasswordController.clear();
        _newPasswordController.clear();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password changed successfully!')));
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? "Error"), backgroundColor: Colors.red));
    }
  }

  // --- NEW: DELETE ACCOUNT FUNCTION ---
  Future<void> _deleteAccount() async {
    final password = _deletePasswordController.text.trim();
    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password required to delete account")));
      return;
    }

    // Close Dialog and Show Loading
    Navigator.pop(context);
    setState(() => _isLoading = true);

    try {
      final uid = user!.uid;
      final email = user!.email!;

      // 1. Re-authenticate (Security Requirement)
      AuthCredential credential = EmailAuthProvider.credential(email: email, password: password);
      await user!.reauthenticateWithCredential(credential);

      // 2. Delete User Content (Firestore Media Collection)
      // Note: On Free plan, we must delete subcollections manually loop-by-loop.
      final mediaSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('media')
          .get();

      // Use Batch for faster deletion (Atomic operation)
      WriteBatch batch = FirebaseFirestore.instance.batch();
      for (var doc in mediaSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // 3. Delete User Profile Doc
      await FirebaseFirestore.instance.collection('users').doc(uid).delete();

      // 4. Delete Authentication Record
      await user!.delete();

      if (mounted) {
        // Redirect to Login
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
        );
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Account deleted successfully")));
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? "Delete failed"), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("An error occurred"), backgroundColor: Colors.red));
      }
    }
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
      );
    }
  }

  // --- WIDGETS ---

  // Dialog: Confirm Delete
  void _showDeleteConfirmDialog() {
    _deletePasswordController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Account?", style: TextStyle(color: Colors.red)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("This action cannot be undone. All your data will be permanently lost."),
            const SizedBox(height: 20),
            TextField(
              controller: _deletePasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Confirm Password",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outline, color: Colors.red),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: _deleteAccount,
            child: const Text("DELETE"),
          ),
        ],
      ),
    );
  }

  // Dialog: Change Password (Keeping your existing logic)
  void _showChangePasswordDialog() {
    _currentPasswordController.clear();
    _newPasswordController.clear();
    bool isObscured = true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Change Password"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Verify your current password to set a new one.", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _currentPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: "Current Password", prefixIcon: Icon(Icons.lock_open), border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _newPasswordController,
                      obscureText: isObscured,
                      onChanged: (val) => setStateDialog(() {}),
                      decoration: InputDecoration(
                        labelText: "New Password",
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(icon: Icon(isObscured ? Icons.visibility_off : Icons.visibility), onPressed: () => setStateDialog(() => isObscured = !isObscured)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    PasswordChecklist(password: _newPasswordController.text),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                FilledButton(onPressed: _changePassword, child: const Text("Update")),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Profile")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 10),
              CircleAvatar(
                radius: 50,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text(user?.displayName != null && user!.displayName!.isNotEmpty ? user!.displayName![0].toUpperCase() : "U", style: TextStyle(fontSize: 40, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 40),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Username", prefixIcon: Icon(Icons.person_outline), border: OutlineInputBorder()),
                validator: (val) => val!.isEmpty ? "Name cannot be empty" : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _emailController,
                readOnly: true,
                style: const TextStyle(color: Colors.grey),
                decoration: const InputDecoration(labelText: "Email Address", prefixIcon: Icon(Icons.email_outlined), border: OutlineInputBorder(), filled: true),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: _isLoading ? null : _updateProfile,
                  child: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text("Save Profile Changes"),
                ),
              ),
              const SizedBox(height: 30),
              const Divider(),
              const SizedBox(height: 10),
              ListTile(
                leading: const Icon(Icons.lock_reset_rounded),
                title: const Text("Change Password"),
                trailing: const Icon(Icons.chevron_right),
                onTap: _showChangePasswordDialog,
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.grey),
                title: const Text("Log Out"),
                onTap: _logout,
              ),

              // --- NEW DELETE ACCOUNT BUTTON ---
              ListTile(
                leading: const Icon(Icons.delete_forever_rounded, color: Colors.red),
                title: const Text("Delete Account", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                onTap: _showDeleteConfirmDialog,
              ),
            ],
          ),
        ),
      ),
    );
  }
}