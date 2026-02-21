import 'dart:async';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:safe_opensig/core/storage/accounts_box.dart';
import 'package:safe_opensig/shared/constants/event_bus.dart';
import 'package:safe_opensig/shared/constants/network_constants.dart';
import 'package:safe_opensig/shared/constants/safe_singletons.dart';
import 'package:safe_opensig/shared/models/network_model.dart';
import 'package:safe_opensig/shared/models/safe_account_model.dart';
import 'package:safe_opensig/shared/utils/abi_utils.dart';
import 'package:safe_opensig/shared/widgets/address_input_field.dart';
import 'package:safe_opensig/shared/widgets/network_logo.dart';
import 'package:uuid/uuid.dart';
import 'package:wallet/wallet.dart';
import 'package:web3dart/web3dart.dart';

enum _SafeValidationResult { confirmed, unverified }

class AccountAdditionFormScreen extends StatefulWidget {
  final SafeAccount? existingAccount;

  const AccountAdditionFormScreen({super.key, this.existingAccount});

  @override
  State<AccountAdditionFormScreen> createState() => _AccountAdditionFormScreenState();
}

class _AccountAdditionFormScreenState extends State<AccountAdditionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  late StreamSubscription _networkDetectionSubscription;

  final ValueNotifier<Network?> _selectedNetwork = ValueNotifier(null);
  String _safeAddress = "";
  String? _selectedVersion;
  String? _recommendedVersion;

  final List<String> _versions = [
    '1.5.0',
    '1.4.1',
    '1.3.0',
    '1.2.0',
    '1.1.1',
    '1.1.0',
    '1.0.0',
    '0.1.0',
  ];

  bool get isEditing => widget.existingAccount != null;

  Future<_SafeValidationResult> _validateSafeAccount(String address, Network network) async {
    // Step 1: On-chain check via eth_getStorageAt (slot 0 = singleton/masterCopy)
    try {
      final result = await network.provider.makeRPCCall(
        'eth_getStorageAt',
        [address, '0x0', 'latest'],
      );
      final storageValue = (result as String).replaceFirst('0x', '').toLowerCase();
      if (storageValue.isNotEmpty && storageValue != '0' * 64) {
        // Extract address from last 40 hex chars
        final singletonHex = '0x${storageValue.substring(storageValue.length - 40)}';
        if (trustedSingletons.contains(singletonHex)) {
          return _SafeValidationResult.confirmed;
        }
      }
    } catch (_) {
      // RPC failed, treat as unverified
    }

    return _SafeValidationResult.unverified;
  }

  void _saveAccount() {
    if (isEditing) {
      widget.existingAccount!.name = _nameController.text;
      widget.existingAccount!.address = EthereumAddress.fromHex(_addressController.text).eip55With0x;
      widget.existingAccount!.chainId = _selectedNetwork.value!.chainId;
      widget.existingAccount!.version = _selectedVersion!;
      AccountsBox.addAccount(widget.existingAccount!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account updated successfully!')),
      );
    } else {
      final account = SafeAccount(
        id: const Uuid().v4(),
        name: _nameController.text,
        address: _addressController.text,
        chainId: _selectedNetwork.value!.chainId,
        version: _selectedVersion!,
      );
      AccountsBox.addAccount(account);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account added successfully!')),
      );
    }
    GoRouter.of(context).pop();
  }

  /// Returns true if the version is fine (matches or not detected), false if user chose to go back.
  Future<bool> _checkVersionMismatch() async {
    if (_recommendedVersion != null && _selectedVersion != _recommendedVersion) {
      return _showVersionMismatchDialog(_recommendedVersion!, _selectedVersion!);
    }
    return true;
  }

  Future<bool> _showVersionMismatchDialog(String detectedVersion, String selectedVersion) async {
    final theme = Theme.of(context);
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        titlePadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        iconPadding: const EdgeInsets.only(top: 16),
        actionsPadding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        icon: const Icon(
          Icons.warning_amber_rounded,
          color: Colors.amber,
          size: 36,
        ),
        title: Text(
          'Version Mismatch',
          style: theme.textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'The on-chain contract version is $detectedVersion, '
              'but you selected $selectedVersion. Using a mismatched '
              'version will yield incorrect simulation and verification '
              'results.',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(false),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Go Back & Fix Version'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  side: BorderSide(color: theme.colorScheme.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ) ?? false;
  }

  Future<bool> _showUnverifiedSafeDialog() async {
    final theme = Theme.of(context);
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        titlePadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        iconPadding: const EdgeInsets.only(top: 16),
        actionsPadding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        icon: const Icon(
          Icons.warning_amber_rounded,
          color: Colors.amber,
          size: 36,
        ),
        title: Text(
          'Safe Not Verified',
          style: theme.textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Could not verify a recognized Safe contract at this address '
              'on the selected network. This may happen if the Safe is not '
              'yet deployed, uses a newer implementation, or the address '
              'is not a Safe.',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  side: BorderSide(color: theme.colorScheme.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Go Back'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () => Navigator.of(context).pop(true),
                icon: const Icon(Icons.save_outlined, size: 18),
                label: Text(
                  'Save Anyway',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ) ?? false;
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedNetwork.value == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a network')),
        );
        return;
      }
      if (_selectedVersion == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a contract version')),
        );
        return;
      }
      // Duplicate check
      if (isEditing) {
        if (
          EthereumAddress.fromHex(_addressController.text) != EthereumAddress.fromHex(widget.existingAccount!.address)
          || _selectedNetwork.value!.chainId != widget.existingAccount!.chainId
        ){
          if (AccountsBox.accountExists(_addressController.text, _selectedNetwork.value!.chainId)) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('An account with this address already exists on the selected network')),
            );
            return;
          }
        }
      } else {
        if (AccountsBox.accountExists(_addressController.text, _selectedNetwork.value!.chainId)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('An account with this address already exists on the selected network')),
          );
          return;
        }
      }

      // Skip on-chain validation in edit mode if address and network haven't changed
      if (isEditing
          && EthereumAddress.fromHex(_addressController.text) == EthereumAddress.fromHex(widget.existingAccount!.address)
          && _selectedNetwork.value!.chainId == widget.existingAccount!.chainId) {
        if (await _checkVersionMismatch() && mounted) {
          _saveAccount();
        }
        return;
      }

      // Validate Safe account
      final cancelLoad = BotToast.showLoading();
      try {
        final result = await _validateSafeAccount(
          _addressController.text,
          _selectedNetwork.value!,
        );
        cancelLoad();
        if (!mounted) return;

        switch (result) {
          case _SafeValidationResult.confirmed:
            if (await _checkVersionMismatch() && mounted) {
              _saveAccount();
            }
          case _SafeValidationResult.unverified:
            final shouldImport = await _showUnverifiedSafeDialog();
            if (shouldImport && mounted) {
              if (await _checkVersionMismatch() && mounted) {
                _saveAccount();
              }
            }
        }
      } catch (_) {
        cancelLoad();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to validate Safe account. Please try again.')),
        );
      }
    }
  }

  void updateRecommendedVersion() async {
    setState(() => _recommendedVersion = null);
    if (_selectedNetwork.value == null) return;
    if (!EthereumAddress.isEip55ValidEthereumAddress(_safeAddress)) return;
    var response = "";
    try {
      response = await _selectedNetwork.value!.provider.callRaw(
        contract: EthereumAddress.fromHex(_addressController.text),
        data: hexToBytes("0xffa1ad74")
      );
    } catch (e) {
      return;
    }
    if (response.replaceAll("0x", "").isEmpty) return;
    var version = decodeAbi(["string"], hexToBytes(response))[0];
    if (_versions.contains(version)){
      _selectedVersion ??= version;
      _recommendedVersion = version;
      setState(() {});
    }
  }

  @override
  void initState() {
    if (isEditing) {
      final account = widget.existingAccount!;
      _nameController.text = account.name;
      _addressController.text = account.address;
      _selectedVersion = account.version;
      _selectedNetwork.value = account.network;
      _safeAddress = account.address;
      updateRecommendedVersion();
    }
    _networkDetectionSubscription = eventBus.on<OnAddressNetworkDetected>().listen((event){
      setState(() {
        _selectedNetwork.value = event.network;
      });
    });
    _selectedNetwork.addListener((){
      updateRecommendedVersion();
    });
    _addressController.addListener((){
      var value = _addressController.text;
      if (_safeAddress == value) return;
      _safeAddress = value;
      if (EthereumAddress.isEip55ValidEthereumAddress(value)){
        updateRecommendedVersion();
        return;
      }else{
        if (value.contains(":")){
          var prefix = value.split(":")[0];
          var address = value.split(":")[1];
          if (EthereumAddress.isEip55ValidEthereumAddress(address)){
            for (var network in availableNetworks.values){
              if (network.chainPrefix == prefix){
                eventBus.fire(OnAddressNetworkDetected(network));
                break;
              }
            }
            _addressController.text = address;
            return;
          }
        }
      }
      setState(() => _recommendedVersion = null);
    });
    super.initState();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _networkDetectionSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Account' : 'Add Account'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Account Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an account name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AddressInputField(
                controller: _addressController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an account address';
                  }
                  if (!value.startsWith('0x') || value.length != 42) {
                    return 'Please enter a valid account address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Network>(
                value: _selectedNetwork.value,
                decoration: const InputDecoration(
                  labelText: 'Network',
                  border: OutlineInputBorder(),
                ),
                items: availableNetworks.values.map((Network network) {
                  return DropdownMenuItem<Network>(
                    value: network,
                    child: Row(
                      children: [
                        NetworkLogo(network: network),
                        const SizedBox(width: 12),
                        Text(network.name),
                      ],
                    ),
                  );
                }).toList(),
                selectedItemBuilder: (BuildContext context) {
                  return availableNetworks.values.map<Widget>((Network network) {
                    return Row(
                      children: [
                        NetworkLogo(network: network),
                        const SizedBox(width: 12),
                        Text(network.name),
                      ],
                    );
                  }).toList();
                },
                onChanged: (Network? newValue) {
                  setState(() {
                    _selectedNetwork.value = newValue;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a network';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedVersion,
                decoration: const InputDecoration(
                  labelText: 'Contract Version',
                  border: OutlineInputBorder(),
                ),
                items: _versions.map((String version) {
                  return DropdownMenuItem<String>(
                    value: version,
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: version),
                          if (_recommendedVersion == version)
                            TextSpan(
                              text: " (detected)",
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.5)
                              )
                            ),
                        ]
                      )
                    )
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedVersion = newValue;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a contract version';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Saved locally · never shared',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _submitForm,
                child: Text(isEditing ? 'Update' : 'Add'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
