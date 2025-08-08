import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:splitzy/models/group_model.dart';
import 'package:splitzy/services/database_service.dart';
import 'package:splitzy/services/auth_service.dart';
import 'package:splitzy/utils/validators.dart';

class AddGroupScreen extends StatefulWidget {
  const AddGroupScreen({super.key});

  @override
  State<AddGroupScreen> createState() => _AddGroupScreenState();
}

class _AddGroupScreenState extends State<AddGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _newMemberController = TextEditingController();
  final List<String> _members = ['You'];
  final Map<String, String> _memberNames = {'you': 'You'};
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _newMemberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Group'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveGroup,
            child: _isLoading
                ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Text('SAVE'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Group Name
            TextFormField(
              controller: _nameController,
              enabled: !_isLoading,
              decoration: const InputDecoration(
                labelText: 'Group Name',
                hintText: 'Enter group name...',
                prefixIcon: Icon(Icons.group),
                border: OutlineInputBorder(),
              ),
              validator: (value) => Validators.validateName(value, minLength: 2, maxLength: 50, fieldName: 'Group Name'),
              textCapitalization: TextCapitalization.words,
              maxLength: 50,
            ),
            const SizedBox(height: 16),
            // Members
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Members',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ..._members.map((member) => ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(member),
                      trailing: member != 'You'
                          ? IconButton(
                        icon: const Icon(Icons.remove_circle, color: Colors.red),
                        onPressed: _isLoading
                            ? null
                            : () {
                          setState(() {
                            _members.remove(member);
                            _memberNames.removeWhere((key, value) => value == member);
                          });
                        },
                      )
                          : null,
                    )),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.person_add),
                      title: TextFormField(
                        controller: _newMemberController,
                        decoration: const InputDecoration(hintText: 'Enter member name'),
                        validator: (value) => Validators.validateName(value, minLength: 2, maxLength: 50, fieldName: 'Member Name'),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.add, color: Colors.green),
                        onPressed: _isLoading || _newMemberController.text.trim().isEmpty
                            ? null
                            : () {
                          final newMember = _newMemberController.text.trim();
                          if (Validators.validateName(newMember, minLength: 2, maxLength: 50, fieldName: 'Member Name') == null) {
                            setState(() {
                              _members.add(newMember);
                              _memberNames[newMember.toLowerCase()] = newMember;
                              _newMemberController.clear();
                            });
                          } else {
                            _showErrorSnackBar('Invalid member name');
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveGroup,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text('Adding...'),
                ],
              )
                  : const Text(
                'Create Group',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveGroup() async {
    if (!_formKey.currentState!.validate()) return;
    if (_members.isEmpty) {
      _showErrorSnackBar('Please add at least one member');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final name = _nameController.text.trim();
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUser;
      final userId = user?.uid ?? 'anonymous';
      final group = GroupModel.create(
        name: name,
        members: _members,
        memberNames: _memberNames,
        createdBy: userId,
      );
      final dbService = Provider.of<DatabaseService>(context, listen: false);
      final success = await dbService.createGroup(group);
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Group "$name" created successfully!')),
        );
        Navigator.pop(context, true);
      } else {
        _showErrorSnackBar('Failed to create group');
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('Failed to create group. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}