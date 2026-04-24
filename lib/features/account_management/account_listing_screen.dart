import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:safe_opensig/core/storage/accounts_box.dart';
import 'package:safe_opensig/core/storage/misc_box.dart';
import 'package:safe_opensig/core/theme/theme_config.dart';
import 'package:safe_opensig/shared/constants/event_bus.dart';
import 'package:safe_opensig/shared/models/safe_account_model.dart';
import 'package:safe_opensig/shared/services/analytics_service.dart';
import 'package:safe_opensig/shared/widgets/analytics_info_sheet.dart';
import 'package:safe_opensig/shared/widgets/network_logo.dart';
import 'package:safe_opensig/shared/widgets/address_widget.dart';
import 'package:safe_opensig/shared/widgets/popular_safes_section.dart';

class AccountListingScreen extends StatefulWidget {
  const AccountListingScreen({super.key});

  @override
  State<AccountListingScreen> createState() => _AccountListingScreenState();
}

class _AccountListingScreenState extends State<AccountListingScreen> {
  late List<SafeAccount> _accounts;
  late StreamSubscription _accountChangesSubscription;
  late StreamSubscription _firstVerificationSubscription;
  bool _showAnalyticsNudge = false;

  @override
  void initState() {
    _loadAccounts();
    _recomputeAnalyticsNudge();
    _accountChangesSubscription = eventBus.on<OnAccountStorageChange>().listen((event) {
      if (!mounted) return;
      _loadAccounts();
    });
    _firstVerificationSubscription = eventBus.on<OnFirstVerificationCompleted>().listen((event) {
      if (!mounted) return;
      _recomputeAnalyticsNudge();
    });
    super.initState();
  }

  void _recomputeAnalyticsNudge() {
    final shouldShow = Analytics.isConfigured &&
        !MiscBox.isAnalyticsNudgeShown() &&
        !MiscBox.isAnalyticsOptedIn() &&
        MiscBox.hasCompletedFirstVerification();
    if (shouldShow == _showAnalyticsNudge) return;
    setState(() => _showAnalyticsNudge = shouldShow);
  }

  Future<void> _enableAnalyticsFromNudge() async {
    await MiscBox.setAnalyticsOptedIn(true);
    Analytics.setEnabled(true);
    await MiscBox.markAnalyticsNudgeShown();
    if (mounted) setState(() => _showAnalyticsNudge = false);
  }

  Future<void> _dismissAnalyticsNudge() async {
    await MiscBox.markAnalyticsNudgeShown();
    if (mounted) setState(() => _showAnalyticsNudge = false);
  }

  void _openAnalyticsDocs() {
    AnalyticsInfoSheet.show(context);
  }

  @override
  void dispose() {
    _accountChangesSubscription.cancel();
    _firstVerificationSubscription.cancel();
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
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              GoRouter.of(context).go('/settings');
            },
          ),
          if (accounts.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                GoRouter.of(context).go('/accounts/add-account');
              },
            ),
        ],
      ),
      body: Column(
        children: [
          if (_showAnalyticsNudge)
            _AnalyticsNudgeCard(
              onEnable: _enableAnalyticsFromNudge,
              onDismiss: _dismissAnalyticsNudge,
              onLearnMore: _openAnalyticsDocs,
            ),
          Expanded(
            child: accounts.isEmpty
                ? _EmptyStateWidget()
                : Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(
                            ThemeConfig.spacingMedium,
                          ),
                          itemCount: accounts.length,
                          itemBuilder: (context, index) {
                            final account = accounts[index];
                            return _AccountCard(
                              account: account,
                              onTap: () {
                                GoRouter.of(
                                  context,
                                ).push("/verify-transaction", extra: account);
                              },
                              onEdit: () {
                                GoRouter.of(
                                  context,
                                ).go('/accounts/edit-account', extra: account);
                              },
                              onDelete: () {
                                final countAfter = AccountsBox.getAccounts().length - 1;
                                AccountsBox.removeAccount(account.id);
                                Analytics.trackAccountRemoved(
                                  account.network.chainPrefix,
                                  countAfter,
                                );
                                _loadAccounts();
                              },
                            );
                          },
                        ),
                      ),
                      // Hint text
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: ThemeConfig.spacingMedium,
                        ),
                        child: Text(
                          'Swipe or long-press an account for options',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.5)),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsNudgeCard extends StatefulWidget {
  final VoidCallback onEnable;
  final VoidCallback onDismiss;
  final VoidCallback onLearnMore;

  const _AnalyticsNudgeCard({
    required this.onEnable,
    required this.onDismiss,
    required this.onLearnMore,
  });

  @override
  State<_AnalyticsNudgeCard> createState() => _AnalyticsNudgeCardState();
}

class _AnalyticsNudgeCardState extends State<_AnalyticsNudgeCard> {
  late final TapGestureRecognizer _learnMoreRecognizer;

  @override
  void initState() {
    super.initState();
    _learnMoreRecognizer = TapGestureRecognizer()..onTap = widget.onLearnMore;
  }

  @override
  void dispose() {
    _learnMoreRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ThemeConfig.spacingMedium,
        ThemeConfig.spacingMedium,
        ThemeConfig.spacingMedium,
        0,
      ),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: theme.dividerColor, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.insights_outlined,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Help improve Safe OpenSig?',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      size: 18,
                      color: theme.textTheme.bodySmall?.color?.withValues(
                        alpha: 0.6,
                      ),
                    ),
                    tooltip: 'Dismiss',
                    onPressed: widget.onDismiss,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text.rich(
                  TextSpan(
                    style: theme.textTheme.bodySmall,
                    children: [
                      const TextSpan(
                        text:
                            'Send anonymous app-usage events. No wallet data, no addresses. Change anytime in Settings. ',
                      ),
                      TextSpan(
                        text: 'See what\'s collected',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: _learnMoreRecognizer,
                      ),
                      const TextSpan(text: '.'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.onDismiss,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        visualDensity: VisualDensity.compact,
                      ),
                      child: const Text('No thanks'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.tonal(
                      onPressed: widget.onEnable,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        visualDensity: VisualDensity.compact,
                      ),
                      child: const Text('Enable'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            AddressWidget(
                              address: account.address,
                              chainId: account.network.chainId,
                              truncateLength: 6,
                              showBlockies: false,
                              interactive: false,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'v${account.version}',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).textTheme.labelSmall?.color?.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
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
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: ThemeConfig.spacingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 40),

          // Hero section
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 72,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 20),
          Text(
            'No accounts yet',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Add your Safe account to start\nverifying transactions',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              GoRouter.of(context).go('/accounts/add-account');
            },
            child: const Text('Add Account'),
          ),

          const SizedBox(height: 48),

          // Divider
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'or explore',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color
                        ?.withValues(alpha: 0.5),
                  ),
                ),
              ),
              const Expanded(child: Divider()),
            ],
          ),

          const SizedBox(height: 24),

          const PopularSafesSection(),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
