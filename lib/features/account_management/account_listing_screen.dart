import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:safe_verify/core/storage/accounts_box.dart';
import 'package:safe_verify/core/storage/misc_box.dart';
import 'package:safe_verify/core/theme/theme_config.dart';
import 'package:safe_verify/shared/constants/event_bus.dart';
import 'package:safe_verify/shared/models/safe_account_model.dart';
import 'package:safe_verify/shared/widgets/network_logo.dart';

class AccountListingScreen extends StatefulWidget {
  const AccountListingScreen({super.key});

  @override
  State<AccountListingScreen> createState() => _AccountListingScreenState();
}

class _AccountListingScreenState extends State<AccountListingScreen> {
  late List<SafeAccount> _accounts;
  late String? _selectedAccountId;
  late StreamSubscription _accountChangesSubscription;

  @override
  void initState() {
    _loadAccounts();
    _accountChangesSubscription = eventBus.on<OnAccountStorageChange>().listen((event){
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
      _selectedAccountId = MiscBox.getSelectedAccountId();
    });
  }

  void _selectAccount(String accountId) {
    MiscBox.setSelectedAccountId(accountId);
    setState(() {
      _selectedAccountId = accountId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final accounts = _accounts;
    final selectedAccountId = _selectedAccountId;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Safe Accounts'),
        actions: [
          accounts.isNotEmpty ? IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              GoRouter.of(context).go('/accounts/add-account');
            },
          ) : const SizedBox.shrink(),
        ],
      ),
      body: accounts.isEmpty ? _EmptyStateWidget() : ListView.builder(
        padding: const EdgeInsets.all(ThemeConfig.spacingMedium),
        itemCount: accounts.length,
        itemBuilder: (context, index) {
          final account = accounts[index];
          return _AccountCard(
            account: account,
            isActive: account.id == selectedAccountId,
            onTap: () => _selectAccount(account.id),
            onDelete: () {
              AccountsBox.removeAccount(account.id);
              if (selectedAccountId == account.id) {
                MiscBox.setSelectedAccountId(null);
              }
              _loadAccounts();
            },
          );
        },
      ),
      floatingActionButton: accounts.isNotEmpty ? FloatingActionButton.extended(
        onPressed: () {
          GoRouter.of(context).push("/verify-transaction", extra: AccountsBox.getAccount(selectedAccountId!)!);
        },
        label: const Text('Verify Safe Transaction'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ) : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class _AccountCard extends StatelessWidget {
  final SafeAccount account;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _AccountCard({
    required this.account,
    required this.isActive,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    var borderColor = isActive ? Theme.of(context).colorScheme.primary : Colors.white.withValues(alpha: 0.5);
    return AnimatedContainer(
      duration: Duration(milliseconds: 100),
      margin: const EdgeInsets.only(bottom: ThemeConfig.spacingMedium),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: ThemeConfig.borderRadiusLarge,
        boxShadow: ThemeConfig.shadowMedium,
        border: Border(
          left: BorderSide(
            color: borderColor,
            width: isActive ? 4.0 : 1,
          ),
          right: BorderSide(color: borderColor, width: 1),
          top: BorderSide(color: borderColor, width: 1),
          bottom: BorderSide(color: borderColor, width: 1)
        ),
      ),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: ThemeConfig.borderRadiusLarge,
        elevation: isActive ? 10 : 3,
        child: InkWell(
          onTap: onTap,
          borderRadius: ThemeConfig.borderRadiusLarge,
          child: Padding(
            padding: const EdgeInsets.all(ThemeConfig.spacingMedium),
            child: Row(
              children: [
                NetworkLogo(network: account.network),
                const SizedBox(width: ThemeConfig.spacingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: ThemeConfig.spacingXSmall),
                      Text(
                        _trimAddress(account.address),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: ThemeConfig.borderRadiusLarge,
                  ),
                  onSelected: (String result) {
                    if (result == 'edit') {
                      _editAccount(context, account);
                    } else if (result == 'delete') {
                      _deleteAccount(context, account);
                    }
                  },
                  menuPadding: EdgeInsets.zero,
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(
                            Icons.edit,
                            size: ThemeConfig.iconSizeMedium,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          const SizedBox(width: ThemeConfig.spacingSmall),
                          const Text('Edit'),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete,
                            size: ThemeConfig.iconSizeMedium,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(width: ThemeConfig.spacingSmall),
                          const Text('Delete'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _editAccount(BuildContext context, SafeAccount account) {
    GoRouter.of(context).go('/accounts/edit-account', extra: account);
  }

  void _deleteAccount(BuildContext context, SafeAccount account) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Account'),
          content: Text('Are you sure you want to delete the account "${account.name}"?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                onDelete();
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Account deleted successfully!')),
                );
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  String _trimAddress(String address) {
    if (address.length <= 10) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
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