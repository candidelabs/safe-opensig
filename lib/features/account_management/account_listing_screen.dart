import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:safe_opensig/core/storage/accounts_box.dart';
import 'package:safe_opensig/core/theme/theme_config.dart';
import 'package:safe_opensig/shared/constants/event_bus.dart';
import 'package:safe_opensig/shared/models/safe_account_model.dart';
import 'package:safe_opensig/shared/widgets/network_logo.dart';
import 'package:safe_opensig/shared/widgets/address_widget.dart';

class AccountListingScreen extends StatefulWidget {
  const AccountListingScreen({super.key});

  @override
  State<AccountListingScreen> createState() => _AccountListingScreenState();
}

class _AccountListingScreenState extends State<AccountListingScreen> {
  late List<SafeAccount> _accounts;
  late StreamSubscription _accountChangesSubscription;

  @override
  void initState() {
    _loadAccounts();
    _accountChangesSubscription = eventBus.on<OnAccountStorageChange>().listen((event) {
      if (!mounted) return;
      _loadAccounts();
    });
    super.initState();
  }

  @override
  void dispose() {
    _accountChangesSubscription.cancel();
    super.dispose();
  }

  void _loadAccounts() {
    setState(() {
      _accounts = AccountsBox.getAccounts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final accounts = _accounts;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Safe Accounts'),
        actions: [
          if (accounts.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                GoRouter.of(context).go('/accounts/add-account');
              },
            ),
        ],
      ),
      body: accounts.isEmpty
          ? _EmptyStateWidget()
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(ThemeConfig.spacingMedium),
                    itemCount: accounts.length,
                    itemBuilder: (context, index) {
                      final account = accounts[index];
                      return _AccountCard(
                        account: account,
                        onTap: () {
                          GoRouter.of(context).push("/verify-transaction", extra: account);
                        },
                        onEdit: () {
                          GoRouter.of(context).go('/accounts/edit-account', extra: account);
                        },
                        onDelete: () {
                          AccountsBox.removeAccount(account.id);
                          _loadAccounts();
                        },
                      );
                    },
                  ),
                ),
                // Hint text
                Padding(
                  padding: const EdgeInsets.only(bottom: ThemeConfig.spacingMedium),
                  child: Text(
                    'Swipe or hold cards for options',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  final SafeAccount account;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AccountCard({
    required this.account,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ThemeConfig.spacingMedium),
      child: Dismissible(
        key: ValueKey(account.id),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            // Swipe RIGHT → Edit
            onEdit();
            return false; // Don't actually dismiss, just trigger edit
          } else if (direction == DismissDirection.endToStart) {
            // Swipe LEFT → Delete (with confirmation)
            return await _showDeleteConfirmation(context);
          }
          return false;
        },
        onDismissed: (direction) {
          if (direction == DismissDirection.endToStart) {
            onDelete();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Account deleted')),
            );
          }
        },
        background: Container(
          // Swipe RIGHT background (Edit)
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 20),
          decoration: BoxDecoration(
            color: ThemeConfig.primaryVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.edit, color: Colors.white),
        ),
        secondaryBackground: Container(
          // Swipe LEFT background (Delete)
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.error,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        child: Card(
          margin: EdgeInsets.zero,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Theme.of(context).dividerColor, width: 1),
          ),
          child: InkWell(
            onTap: onTap,
            onLongPress: () => _showContextMenu(context),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  // Network logo
                  NetworkLogo(network: account.network),
                  const SizedBox(width: 14),

                  // Account info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Account name
                        Text(
                          account.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // Address
                        AddressWidget(
                          address: account.address,
                          chainId: account.network.chainId,
                          truncateLength: 6,
                          showBlockies: false,
                          interactive: false,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),

                  // Arrow indicator
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Theme.of(context).primaryColor,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.edit, color: ThemeConfig.primaryVariant),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(context);
                  onEdit();
                },
              ),
              ListTile(
                leading: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
                title: const Text('Delete'),
                onTap: () async {
                  Navigator.pop(context);
                  final confirmed = await _showDeleteConfirmation(context);
                  if (confirmed) {
                    onDelete();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Account deleted')),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<bool> _showDeleteConfirmation(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Account'),
          content: Text('Are you sure you want to delete "${account.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    ) ?? false;
  }

}

class _EmptyStateWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 24),
          const Text(
            'No accounts yet',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add your first account to get started',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              GoRouter.of(context).go('/accounts/add-account');
            },
            child: const Text('Add Account'),
          ),
        ],
      ),
    );
  }
}
