import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:splitzy/services/database_service.dart';
import 'package:splitzy/services/auth_service.dart';
import 'package:splitzy/models/settlement_model.dart';

class SettleUpScreen extends StatefulWidget {
  const SettleUpScreen({super.key});

  @override
  State<SettleUpScreen> createState() => _SettleUpScreenState();
}

class _SettleUpScreenState extends State<SettleUpScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Sample data - in a real app, this would come from your database
  final List<SettlementItem> _youOwe = [
    SettlementItem(
      name: 'Rahul',
      amount: 150.0,
      groupName: 'Trip to Goa',
      avatarColor: Colors.blue,
      userId: 'user_rahul_123',
      groupId: 'group_goa_trip',
      phoneNumber: '+919876543210',
    ),
    SettlementItem(
      name: 'Priya',
      amount: 75.50,
      groupName: 'Office Lunch',
      avatarColor: Colors.purple,
      userId: 'user_priya_456',
      groupId: 'group_office_lunch',
      phoneNumber: '+919876543211',
    ),
    SettlementItem(
      name: 'Amit',
      amount: 200.0,
      groupName: 'Weekend Party',
      avatarColor: Colors.green,
      userId: 'user_amit_789',
      groupId: 'group_weekend_party',
      phoneNumber: '+919876543212',
    ),
  ];

  final List<SettlementItem> _owesYou = [
    SettlementItem(
      name: 'Aarav',
      amount: 220.0,
      groupName: 'Trip to Goa',
      avatarColor: Colors.orange,
      userId: 'user_aarav_101',
      groupId: 'group_goa_trip',
      phoneNumber: '+919876543213',
    ),
    SettlementItem(
      name: 'Sneha',
      amount: 120.75,
      groupName: 'Dinner',
      avatarColor: Colors.red,
      userId: 'user_sneha_202',
      groupId: 'group_dinner',
      phoneNumber: '+919876543214',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settle Up'),
        centerTitle: true,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'You Owe'),
            Tab(text: 'Owes You'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildYouOweTab(),
          _buildOwesYouTab(),
        ],
      ),
    );
  }

  Widget _buildYouOweTab() {
    if (_youOwe.isEmpty) {
      return _buildEmptyState(
        'No pending payments',
        'You\'re all settled up! 🎉',
        Icons.check_circle_outline,
      );
    }

    double totalOwed = _youOwe.fold(0, (sum, item) => sum + item.amount);

    return Column(
      children: [
        // Total Amount Card
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Row(
            children: [
              Icon(
                Icons.account_balance_wallet,
                color: Colors.red.shade600,
                size: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total you owe',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.red.shade700,
                      ),
                    ),
                    Text(
                      '₹${totalOwed.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Settlement List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _youOwe.length,
            itemBuilder: (context, index) {
              final item = _youOwe[index];
              return _buildSettlementCard(
                item: item,
                isOwed: false,
                onPay: () => _initiatePayment(item),
                onRemind: null,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOwesYouTab() {
    if (_owesYou.isEmpty) {
      return _buildEmptyState(
        'No pending receivables',
        'Nobody owes you money right now',
        Icons.money_off,
      );
    }

    double totalReceivable = _owesYou.fold(0, (sum, item) => sum + item.amount);

    return Column(
      children: [
        // Total Amount Card
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Row(
            children: [
              Icon(
                Icons.trending_up,
                color: Colors.green.shade600,
                size: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total owed to you',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.green.shade700,
                      ),
                    ),
                    Text(
                      '₹${totalReceivable.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Settlement List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _owesYou.length,
            itemBuilder: (context, index) {
              final item = _owesYou[index];
              return _buildSettlementCard(
                item: item,
                isOwed: true,
                onPay: null,
                onRemind: () => _sendReminder(item),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSettlementCard({
    required SettlementItem item,
    required bool isOwed,
    VoidCallback? onPay,
    VoidCallback? onRemind,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              backgroundColor: item.avatarColor.withValues(alpha: 0.2),
              child: Text(
                item.name[0].toUpperCase(),
                style: TextStyle(
                  color: item.avatarColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(width: 16),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isOwed ? '${item.name} owes you' : 'You owe ${item.name}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${item.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isOwed ? Colors.green.shade600 : Colors.red.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'From ${item.groupName}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // Action Button
            if (onPay != null)
              ElevatedButton(
                onPressed: onPay,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                ),
                child: const Text('Pay'),
              )
            else if (onRemind != null)
              OutlinedButton(
                onPressed: onRemind,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: const Text('Remind'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _initiatePayment(SettlementItem item) async {
    // Show payment options dialog
    if (mounted) {
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => _buildPaymentBottomSheet(item),
      );
    }
  }

  Widget _buildPaymentBottomSheet(SettlementItem item) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              CircleAvatar(
                backgroundColor: item.avatarColor.withValues(alpha: 0.2),
                child: Text(
                  item.name[0].toUpperCase(),
                  style: TextStyle(
                    color: item.avatarColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pay ${item.name}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '₹${item.amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.red.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Payment Options
          _buildPaymentOption(
            'UPI Payment',
            'Pay using any UPI app',
            Icons.phone_android,
                () => _payWithUPI(item),
          ),

          const SizedBox(height: 12),

          _buildPaymentOption(
            'Record Payment',
            'Mark as paid manually',
            Icons.check_circle_outline,
                () => _recordPayment(item),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(
      String title,
      String subtitle,
      IconData icon,
      VoidCallback onTap,
      ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _payWithUPI(SettlementItem item) async {
    Navigator.pop(context); // Close bottom sheet

    // Generate UPI payment URL
    final upiUrl = _generateUpiUrl(
      receiverUpiId: 'receiver@upi', // This should come from user data
      receiverName: item.name,
      amount: item.amount,
      note: 'Payment for ${item.groupName}',
    );

    try {
      final Uri uri = Uri.parse(upiUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);

        // Show confirmation dialog after UPI app opens
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          _showPaymentConfirmationDialog(item);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No UPI app found'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open UPI app: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _generateUpiUrl({
    required String receiverUpiId,
    required String receiverName,
    required double amount,
    required String note,
  }) {
    final encodedNote = Uri.encodeComponent(note);
    final encodedName = Uri.encodeComponent(receiverName);

    return 'upi://pay?pa=$receiverUpiId&pn=$encodedName&am=$amount&tn=$encodedNote&cu=INR';
  }

  void _showPaymentConfirmationDialog(SettlementItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment Confirmation'),
        content: Text('Did you successfully pay ₹${item.amount.toStringAsFixed(2)} to ${item.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _markAsSettled(item);
            },
            child: const Text('Yes, Paid'),
          ),
        ],
      ),
    );
  }

  void _recordPayment(SettlementItem item) {
    Navigator.pop(context); // Close bottom sheet

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Record Payment'),
        content: Text('Mark payment of ₹${item.amount.toStringAsFixed(2)} to ${item.name} as completed?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _markAsSettled(item);
            },
            child: const Text('Mark as Paid'),
          ),
        ],
      ),
    );
  }

  void _markAsSettled(SettlementItem item) async {
    try {
      // Get current user
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.currentUser;

      if (currentUser == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please sign in to settle payments'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Create settlement record
      final settlement = SettlementModel.create(
        fromUser: currentUser.uid,
        fromUserName: currentUser.displayName,
        toUser: item.userId ?? 'unknown',
        toUserName: item.name,
        amount: item.amount,
        groupId: item.groupId ?? 'unknown',
        groupName: item.groupName,
        paymentMethod: 'Manual',
        notes: 'Marked as settled via app',
      );

      // Update in database
      final databaseService = Provider.of<DatabaseService>(context, listen: false);
      final success = await databaseService.addSettlement(settlement);

      if (success && mounted) {
        setState(() {
          _youOwe.remove(item);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment to ${item.name} marked as completed'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(databaseService.errorMessage ?? 'Failed to update settlement'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating settlement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _sendReminder(SettlementItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Reminder'),
        content: Text('How would you like to send a payment reminder to ${item.name} for ₹${item.amount.toStringAsFixed(2)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _sendReminderViaWhatsApp(item);
            },
            child: const Text('WhatsApp'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _sendReminderViaSMS(item);
            },
            child: const Text('SMS'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _sendReminderMessage(item);
            },
            child: const Text('Copy Text'),
          ),
        ],
      ),
    );
  }

  void _sendReminderMessage(SettlementItem item) {
    final message = 'Hi ${item.name}! This is a friendly reminder that you owe ₹${item.amount.toStringAsFixed(2)} for ${item.groupName}. Please settle up when convenient. Thanks! - Splitzy';

    // Copy to clipboard
    Clipboard.setData(ClipboardData(text: message));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reminder message copied to clipboard'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  void _sendReminderViaWhatsApp(SettlementItem item) async {
    final message = 'Hi ${item.name}! This is a friendly reminder that you owe ₹${item.amount.toStringAsFixed(2)} for ${item.groupName}. Please settle up when convenient. Thanks! - Splitzy';
    final encodedMessage = Uri.encodeComponent(message);
    final phoneNumber = item.phoneNumber ?? '';

    final whatsappUrl = phoneNumber.isNotEmpty
        ? 'https://wa.me/$phoneNumber?text=$encodedMessage'
        : 'https://wa.me/?text=$encodedMessage';

    try {
      final uri = Uri.parse(whatsappUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _sendReminderMessage(item);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('WhatsApp not available. Message copied to clipboard instead.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      _sendReminderMessage(item);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open WhatsApp. Message copied to clipboard instead.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _sendReminderViaSMS(SettlementItem item) async {
    final message = 'Hi ${item.name}! This is a friendly reminder that you owe ₹${item.amount.toStringAsFixed(2)} for ${item.groupName}. Please settle up when convenient. Thanks! - Splitzy';
    final phoneNumber = item.phoneNumber ?? '';

    if (phoneNumber.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Phone number not available for this contact'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      _sendReminderMessage(item);
      return;
    }

    final smsUrl = 'sms:$phoneNumber?body=${Uri.encodeComponent(message)}';

    try {
      final uri = Uri.parse(smsUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        _sendReminderMessage(item);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('SMS not available. Message copied to clipboard instead.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      _sendReminderMessage(item);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open SMS. Message copied to clipboard instead.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }
}

class SettlementItem {
  final String name;
  final double amount;
  final String groupName;
  final Color avatarColor;
  final String? userId;
  final String? groupId;
  final String? phoneNumber;

  SettlementItem({
    required this.name,
    required this.amount,
    required this.groupName,
    required this.avatarColor,
    this.userId,
    this.groupId,
    this.phoneNumber,
  });
}