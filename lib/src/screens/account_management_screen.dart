import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../models/account.dart';
import '../services/account_database.dart';
import '../providers/auth_provider.dart';
import '../widgets/scrollable_appbar.dart';
import '../widgets/settings_section.dart';
import 'login_screen.dart';

class AccountManagementScreen extends ConsumerStatefulWidget {
  const AccountManagementScreen({super.key});

  @override
  ConsumerState<AccountManagementScreen> createState() =>
      _AccountManagementScreenState();
}

class _AccountManagementScreenState
    extends ConsumerState<AccountManagementScreen> {
  List<Account> _accounts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    setState(() => _isLoading = true);
    final accounts = await AccountDatabase.instance.getAllAccounts();
    if (!mounted) return;
    setState(() {
      _accounts = accounts;
      _isLoading = false;
    });
  }

  Future<void> _switchAccount(Account account) async {
    if (account.isActive) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.of(context).switchAccountTitle),
        content: Text(S.of(context).switchAccountConfirm(account.username)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(S.of(context).cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(S.of(context).confirm),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // Switch account in database
      await AccountDatabase.instance.setActiveAccount(account.id!);

      // Login with the account
      final success = await ref.read(authProvider.notifier).login(
          account.username,
          account.password,
          account.host,
          account.serverCookie);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(S.of(context).switchedToAccount(account.username))),
        );
        await _loadAccounts();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).switchFailed)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).switchFailedWithError('$e'))),
        );
      }
    }
  }

  Future<void> _addAccount() async {
    // Navigate to login screen in "add account" mode
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(isAddingAccount: true),
      ),
    );

    // Reload accounts if successfully added
    if (result == true) {
      await _loadAccounts();
    }
  }

  Future<void> _deleteAccount(Account account) async {
    if (account.isActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).cannotDeleteActiveAccount)),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.of(context).deleteAccount),
        content: Text(S.of(context).deleteAccountConfirm(account.username)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(S.of(context).cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(S.of(context).delete),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await AccountDatabase.instance.deleteAccount(account.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).accountDeleted)),
        );
      }
      await _loadAccounts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).deletionFailedWithError('$e'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ScrollableAppBar(
        title: Text(S.of(context).accountManagement,
            style: const TextStyle(fontSize: 18)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _accounts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.account_circle_outlined,
                        size: 64,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        S.of(context).noAccounts,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        S.of(context).tapToAddAccount,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _accounts.length,
                  itemBuilder: (context, index) {
                    final account = _accounts[index];
                    return SettingsSectionCard(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: account.isActive
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                          child: Icon(
                            account.isActive
                                ? Icons.check_circle
                                : Icons.account_circle,
                            color: account.isActive
                                ? Theme.of(context).colorScheme.onPrimary
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                          ),
                        ),
                        title: Text(
                          account.username,
                          style: TextStyle(
                            fontWeight: account.isActive
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(account.host),
                            if (account.isActive)
                              Text(
                                S.of(context).currentAccount,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            if (!account.isActive)
                              PopupMenuItem(
                                value: 'switch',
                                child: Row(
                                  children: [
                                    const Icon(Icons.swap_horiz),
                                    const SizedBox(width: 8),
                                    Text(S.of(context).switchAction),
                                  ],
                                ),
                              ),
                            if (!account.isActive)
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    const Icon(Icons.delete, color: Colors.red),
                                    const SizedBox(width: 8),
                                    Text(S.of(context).delete,
                                        style:
                                            const TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                          ],
                          onSelected: (value) {
                            switch (value) {
                              case 'switch':
                                _switchAccount(account);
                                break;
                              case 'delete':
                                _deleteAccount(account);
                                break;
                            }
                          },
                        ),
                        onTap: () {
                          if (!account.isActive) {
                            _switchAccount(account);
                          }
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addAccount,
        child: const Icon(Icons.add),
      ),
    );
  }
}
