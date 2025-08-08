import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // for kDebugMode
import 'package:provider/provider.dart';
import 'package:splitzy/models/group_model.dart';
import 'package:splitzy/models/expense_model.dart';
import 'package:splitzy/services/database_service.dart';
import 'package:splitzy/services/auth_service.dart';
import 'package:splitzy/utils/validators.dart';

class AddExpenseScreen extends StatefulWidget {
  final GroupModel group;

  const AddExpenseScreen({
    super.key,
    required this.group,
  });

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  
  String _selectedPayer = '';
  List<String> _selectedMembers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedPayer = widget.group.members.first;
    _selectedMembers = [...widget.group.members];
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Expense'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveExpense,
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
            // Description
            TextFormField(
              controller: _descriptionController,
              enabled: !_isLoading,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'What was this expense for?',
                prefixIcon: Icon(Icons.description),
                border: OutlineInputBorder(),
              ),
              validator: Validators.validateExpenseDescription,
              textCapitalization: TextCapitalization.sentences,
              maxLength: 100,
            ),
            const SizedBox(height: 16),

            // Amount
            TextFormField(
              controller: _amountController,
              enabled: !_isLoading,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Amount',
                hintText: '0.00',
                prefixIcon: Icon(Icons.currency_rupee),
                border: OutlineInputBorder(),
                helperText: 'Enter amount in ₹',
              ),
              validator: (value) => Validators.validateAmount(
                value,
                minAmount: 0.01,
                maxAmount: 999999.99,
                fieldName: 'Amount',
              ),
            ),
            const SizedBox(height: 16),

            // Paid by
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Paid by',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ...widget.group.members.map((member) => RadioListTile<String>(
                      title: Text(member),
                      value: member,
                      groupValue: _selectedPayer,
                      onChanged: _isLoading ? null : (value) {
                        setState(() {
                          _selectedPayer = value!;
                        });
                      },
                    )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Split between
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Split between',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        TextButton(
                          onPressed: _isLoading ? null : () {
                            setState(() {
                              if (_selectedMembers.length == widget.group.members.length) {
                                _selectedMembers.clear();
                              } else {
                                _selectedMembers = [...widget.group.members];
                              }
                            });
                          },
                          child: Text(
                            _selectedMembers.length == widget.group.members.length
                                ? 'None'
                                : 'All',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...widget.group.members.map((member) => CheckboxListTile(
                      title: Text(member),
                      value: _selectedMembers.contains(member),
                      onChanged: _isLoading ? null : (checked) {
                        setState(() {
                          if (checked == true) {
                            _selectedMembers.add(member);
                          } else {
                            _selectedMembers.remove(member);
                          }
                        });
                      },
                    )),
                    if (_selectedMembers.isNotEmpty) ...[
                      const Divider(),
                      Text(
                        'Split: ₹${_calculateSplitAmount().toStringAsFixed(2)} per person',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Save button
            ElevatedButton(
              onPressed: _isLoading ? null : _saveExpense,
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
                      'Add Expense',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateSplitAmount() {
    if (_selectedMembers.isEmpty || _amountController.text.trim().isEmpty) {
      return 0.0;
    }
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    return amount / _selectedMembers.length;
  }

  Future<void> _saveExpense() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate member selection
    final selectionError = Validators.validateSelection(
      _selectedMembers,
      fieldName: 'person to split with',
    );
    
    if (selectionError != null) {
      _showErrorSnackBar(selectionError);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final description = _descriptionController.text.trim();
      final amountText = _amountController.text.trim();
      
      // Validate amount
      if (amountText.isEmpty) {
        throw Exception('Please enter an amount');
      }
      
      final amount = double.tryParse(amountText);
      if (amount == null) {
        throw Exception('Please enter a valid amount');
      }
      
      if (amount <= 0) {
        throw Exception('Amount must be greater than 0');
      }

      // Debug logging (only in debug mode)
      if (kDebugMode) {
        debugPrint('=== Adding Expense ===');
        debugPrint('Group: ${widget.group.name}');
        debugPrint('Description: $description');
        debugPrint('Amount: ₹$amount');
        debugPrint('Paid by: $_selectedPayer');
        debugPrint('Split between: $_selectedMembers');
        debugPrint('Split amount per person: ₹${(amount / _selectedMembers.length).toStringAsFixed(2)}');
      }

      // Get auth service to get current user info
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.currentUser;
      
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Validate selected members
      if (_selectedMembers.isEmpty) {
        throw Exception('At least one member must be selected for splitting');
      }

      // Calculate split amounts
      final splitAmount = amount / _selectedMembers.length;
      final splitMap = <String, double>{};
      for (final memberId in _selectedMembers) {
        splitMap[memberId] = splitAmount;
      }

      // Create expense model using the factory method
      final expense = ExpenseModel.create(
        groupId: widget.group.id,
        payer: _selectedPayer,
        payerName: widget.group.getMemberName(_selectedPayer),
        amount: amount,
        description: description,
        split: splitMap,
        date: DateTime.now(),
      );

      // Save to database using Provider
      final databaseService = Provider.of<DatabaseService>(context, listen: false);
      final success = await databaseService.addExpense(expense);
      
      if (!success) {
        throw Exception(databaseService.errorMessage ?? 'Failed to save expense');
      }

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Expense "$description" added successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Return to previous screen
      Navigator.pop(context, true); // Return true to indicate success
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error saving expense: $e');
      }
      
      if (!mounted) return;
      
      _showErrorSnackBar('Failed to add expense. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
