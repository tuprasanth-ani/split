import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:splitzy/models/group_model.dart';
import 'package:splitzy/services/database_service.dart';
import 'package:splitzy/services/auth_service.dart';
import 'package:splitzy/services/contacts_service.dart';
import 'package:splitzy/utils/validators.dart';
// Removed unused import: 'package:flutter_contacts/flutter_contacts.dart';

class AddGroupScreen extends StatefulWidget {
  const AddGroupScreen({super.key});

  @override
  State<AddGroupScreen> createState() => _AddGroupScreenState();
}

class _AddGroupScreenState extends State<AddGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _newMemberController = TextEditingController();
  final List<String> _members = [];
  final Map<String, String> _memberNames = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeCurrentUser();
  }

  void _initializeCurrentUser() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    if (user != null) {
      _members.add(user.uid);
      _memberNames[user.uid] = user.name.isNotEmpty ? user.name : 'You';
    } else {
      // Fallback if user is not authenticated
      _members.add('current_user');
      _memberNames['current_user'] = 'You';
    }
  }

  bool _isCurrentUser(String memberId) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    return (user != null && user.uid == memberId) || memberId == 'current_user';
  }

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
                    ..._members.map((memberId) => ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(_memberNames[memberId] ?? memberId),
                      trailing: _isCurrentUser(memberId)
                          ? null
                          : IconButton(
                        icon: const Icon(Icons.remove_circle, color: Colors.red),
                        onPressed: _isLoading
                            ? null
                            : () {
                          setState(() {
                            _members.remove(memberId);
                            _memberNames.remove(memberId);
                          });
                        },
                      ),
                    )),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.person_add),
                      title: TextFormField(
                        controller: _newMemberController,
                        decoration: const InputDecoration(hintText: 'Enter member name'),
                        validator: (value) => Validators.validateName(value, minLength: 2, maxLength: 50, fieldName: 'Member Name'),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.contacts, color: Colors.blue),
                            onPressed: _isLoading ? null : _showContactsDialog,
                            tooltip: 'Add from contacts',
                          ),
                          IconButton(
                            icon: const Icon(Icons.add, color: Colors.green),
                            onPressed: _isLoading || _newMemberController.text.trim().isEmpty
                                ? null
                                : () {
                              final newMemberName = _newMemberController.text.trim();
                              if (Validators.validateName(newMemberName, minLength: 2, maxLength: 50, fieldName: 'Member Name') == null) {
                                setState(() {
                                  // Generate a simple ID for the new member (name-based)
                                  final memberId = 'member_${newMemberName.toLowerCase().replaceAll(' ', '_')}';
                                  if (!_members.contains(memberId)) {
                                    _members.add(memberId);
                                    _memberNames[memberId] = newMemberName;
                                    _newMemberController.clear();
                                  }
                                });
                              } else {
                                _showErrorSnackBar('Invalid member name');
                              }
                            },
                          ),
                        ],
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

  void _showContactsDialog() {
    final contactsService = Provider.of<ContactsService>(context, listen: false);

    if (!contactsService.hasPermission) {
      _requestContactsPermission();
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select from Contacts'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: Consumer<ContactsService>(
            builder: (context, contactsService, child) {
              if (contactsService.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (contactsService.contacts.isEmpty) {
                return const Center(
                  child: Text('No contacts found'),
                );
              }

              return ListView.builder(
                itemCount: contactsService.contacts.length,
                itemBuilder: (context, index) {
                  final contact = contactsService.contacts[index];
                  return ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.person),
                    ),
                    title: Text(contact.displayName),
                    subtitle: contactsService.getContactPhone(contact) != null
                        ? Text(contactsService.getContactPhone(contact)!)
                        : contactsService.getContactEmail(contact) != null
                        ? Text(contactsService.getContactEmail(contact)!)
                        : null,
                    onTap: () {
                      final name = contact.displayName;
                      final memberId = 'member_${name.toLowerCase().replaceAll(' ', '_')}';
                      if (!_members.contains(memberId)) {
                        setState(() {
                          _members.add(memberId);
                          _memberNames[memberId] = name;
                        });
                      }
                      Navigator.of(context).pop();
                    },
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _requestContactsPermission() async {
    final contactsService = Provider.of<ContactsService>(context, listen: false);
    final granted = await contactsService.requestPermission();

    if (!mounted) return;

    if (granted) {
      _showContactsDialog();
    } else {
      _showErrorSnackBar('Contacts permission is required to add members from contacts');
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