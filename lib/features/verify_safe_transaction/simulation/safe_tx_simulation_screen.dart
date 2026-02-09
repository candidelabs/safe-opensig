import 'dart:async';

import 'package:dotted_line/dotted_line.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:safe_opensig/shared/constants/constants.dart';
import 'package:safe_opensig/shared/models/safe_account_model.dart';
import 'package:safe_opensig/shared/models/safe_transaction_model.dart';
import 'package:safe_opensig/shared/models/simulation/nft_allowance.dart';
import 'package:safe_opensig/shared/models/simulation/nft_transfer.dart';
import 'package:safe_opensig/shared/models/simulation/safe_setting_change.dart';
import 'package:safe_opensig/shared/models/simulation/simulation_result.dart';
import 'package:safe_opensig/shared/models/simulation/token_allowance.dart';
import 'package:safe_opensig/shared/models/simulation/token_transfer.dart';
import 'package:safe_opensig/shared/models/simulation/warning_transaction.dart';
import 'package:safe_opensig/shared/utils/utilities.dart';
import 'package:safe_opensig/core/storage/network_config_box.dart';
import 'package:safe_opensig/shared/widgets/trust_minimized_note.dart';
import 'package:safe_opensig/shared/widgets/address_widget.dart';
import 'package:wallet/wallet.dart';

class SafeTxSimulationScreen extends StatefulWidget {
  final SafeAccount safeAccount;
  final SafeTransaction transaction;
  final SimulationResult simulationResult;

  const SafeTxSimulationScreen({
    super.key,
    required this.safeAccount,
    required this.transaction,
    required this.simulationResult,
  });

  @override
  State<SafeTxSimulationScreen> createState() => _SafeTxSimulationScreenState();
}

class _SafeTxSimulationScreenState extends State<SafeTxSimulationScreen> {
  @override
  Widget build(BuildContext context) {
    if (!widget.simulationResult.success) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Transaction Simulation'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error,
                color: Colors.red,
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text(
                'Simulation Failed',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'The transaction simulation failed, which may indicate that this transaction will revert when submitted on-chain.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              Card(
                // color: Colors.red[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Detected Revert Reason:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.simulationResult.revertReason,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  GoRouter.of(context).push(
                    "/verify-transaction/hashes",
                    extra: (widget.safeAccount, widget.transaction)
                  );
                },
                child: const Text('Verify Hashes anyway'),
              ),
              SizedBox(height: 8),
              OutlinedButton(
                onPressed: () {
                  GoRouter.of(context).go("/accounts",);
                },
                child: const Text('Abort'),
              ),
            ],
          ),
        ),
      );
    }
    final isDangerous = widget.simulationResult.dangerous.$1;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Simulation'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!NetworkConfigBox.hasCustomConfig(widget.safeAccount.chainId) ||
                (NetworkConfigBox.getConfig(widget.safeAccount.chainId)?.secondaryNodeUrls.isNotEmpty ?? false)) ...[
              TrustMinimizedNote(),
              const SizedBox(height: 16),
            ],
            if (widget.transaction.hasNonceMismatch) ...[
              Card(
                color: Colors.orange.shade600.withAlpha((255*0.1).floor()),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(text: 'Nonce Mismatch: '),
                              TextSpan(
                                text: 'Transaction nonce (${widget.transaction.nonce}) ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(text: 'differs from current on-chain nonce '),
                              TextSpan(
                                text: '(${widget.transaction.latestNonce})',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(text: '. Simulation uses the current nonce to bypass on-chain checks.'),
                            ],
                          ),
                          style: TextStyle(color: Colors.orange.shade900),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (isDangerous) ...[
              _buildDangerousTransactionCard(context),
              const SizedBox(height: 16),
            ],
            _buildBalanceChangesCard(context),
            const SizedBox(height: 16),
            _buildAllowancesCard(context),
            if (widget.simulationResult.nftTransfers.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildNFTTransfersCard(context),
            ],
            if (widget.simulationResult.nftAllowances.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildNFTAllowancesCard(context),
            ],
            const SizedBox(height: 16),
            _buildSafeSettingsChangesCard(context),
            const SizedBox(height: 16),
            _buildWarningsCard(context),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () {
                    GoRouter.of(context).go("/accounts",);
                  },
                  child: const Text('Abort'),
                ),
                SizedBox(width: 4),
                ElevatedButton(
                  onPressed: () {
                    GoRouter.of(context).push(
                      "/verify-transaction/hashes",
                      extra: (widget.safeAccount, widget.transaction)
                    );
                  },
                  child: const Text('Verify Hashes'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceChangesCard(BuildContext context) {
    final transfers = widget.simulationResult.transfers;
    if (transfers.isEmpty) {
      return _buildCard(
        context,
        title: 'Balance Changes',
        icon: Icons.account_balance_wallet,
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 16.0),
          child: Text(
            'No balance changes detected',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return _buildCard(
      context,
      title: 'Balance Changes',
      icon: Icons.account_balance_wallet,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: transfers.length,
        itemBuilder: (context, index) {
          final transfer = transfers[index];
          return _buildTransferItem(transfer, index == transfers.length-1 ? false : true);
        },
      ),
    );
  }

  Widget _buildTransferItem(TokenTransfer transfer, bool drawSeparatorLine) {
    var isReceived = false;
    if (transfer.recipient.with0x.toLowerCase() == widget.safeAccount.address.toLowerCase()){
      isReceived = true;
    }
    final amount = transfer.amount;
    final metadata = transfer.metadata!;
    final readableAmount = Utilities.formatCryptoAmount(amount, metadata.decimals);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 25,
                height: 25,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(70),
                  child: metadata.logoUri == "unknown" ? Container(
                    alignment: Alignment.center,
                    color: Colors.grey,
                    child: Text("?", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),),
                  ) : Image.network(metadata.logoUri),
                ),
              ),
              SizedBox(width: 5,),
              Text(
                metadata.symbol,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Spacer(),
              Text(
                "${isReceived ? "+" : "-"}$readableAmount",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isReceived ? Colors.green : Colors.red
                ),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isReceived ? 'From' : 'Recipient',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Spacer(),
              AddressWidget(
                address: isReceived ? transfer.sender.with0x : transfer.recipient.with0x,
                chainId: widget.safeAccount.network.chainId,
                truncateLength: 8,
                showBlockies: false,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          drawSeparatorLine ? Container(
            margin: EdgeInsets.only(top: 8),
            child: DottedLine(
              direction: Axis.horizontal,
              dashColor: Colors.white54,
              dashGapLength: 2.5,
            ),
          ) : SizedBox.shrink()
        ],
      ),
    );
  }

  Widget _buildAllowancesCard(BuildContext context) {
    final allowances = widget.simulationResult.allowances;
    if (allowances.isEmpty) {
      return _buildCard(
        context,
        title: 'Allowances',
        icon: Icons.shopping_bag,
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 16.0),
          child: Text(
            'No allowances detected',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return _buildCard(
      context,
      title: 'Allowances',
      icon: Icons.shopping_bag,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: allowances.length,
        itemBuilder: (context, index) {
          final allowance = allowances[index];
          return _buildAllowanceItem(allowance, index == allowances.length-1 ? false : true);
        },
      ),
    );
  }

  Widget _buildAllowanceItem(TokenAllowance allowance, bool drawSeparatorLine) {
    if (allowance.amount == BigInt.zero) return _buildRevokedAllowanceItem(allowance, drawSeparatorLine);
    final metadata = allowance.metadata!;
    var readableAmount = "";
    if (allowance.amount == maxUint256){
      readableAmount = "∞";
    }else{
      readableAmount = Utilities.formatCryptoAmount(allowance.amount, metadata.decimals);
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          RichText(
            text: TextSpan(
              style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.bold),
              children: [
                WidgetSpan(
                  child: Icon(Icons.warning_amber, size: 13, color: Colors.orange,)
                ),
                TextSpan(
                  text: "  You are giving ",
                ),
                WidgetSpan(
                  child: AddressWidget(
                    address: allowance.spender.with0x,
                    chainId: widget.safeAccount.network.chainId,
                    truncateLength: 8,
                    showBlockies: false,
                    style: TextStyle(fontSize: 12, color: Colors.grey[400], fontWeight: FontWeight.w800),
                  ),
                ),
                TextSpan(
                  text: " permission to spend ",
                ),
                WidgetSpan(
                  child: SizedBox(
                    width: 14,
                    height: 14,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(70),
                      child: metadata.logoUri == "unknown" ? Container(
                        alignment: Alignment.center,
                        color: Colors.grey,
                        child: Text("?", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),),
                      ) : Image.network(metadata.logoUri),
                    ),
                  ),
                ),
                TextSpan(
                  text: " $readableAmount",
                  style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.w800, fontSize: 14),
                ),
                TextSpan(
                  text: " ${metadata.symbol}",
                  style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.w800),
                ),
                TextSpan(
                  text: " from your account's ",
                ),
                WidgetSpan(
                  child: SizedBox(
                    width: 14,
                    height: 14,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(70),
                      child: metadata.logoUri == "unknown" ? Container(
                        alignment: Alignment.center,
                        color: Colors.grey,
                        child: Text("?", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),),
                      ) : Image.network(metadata.logoUri),
                    ),
                  ),
                ),
                TextSpan(
                  text: " ${metadata.name}",
                  style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.w800),
                ),
                TextSpan(
                  text: " balance",
                ),
              ]
            ),
          ),
          drawSeparatorLine ? Container(
            margin: EdgeInsets.only(top: 8),
            child: DottedLine(
              direction: Axis.horizontal,
              dashColor: Colors.white54,
              dashGapLength: 2.5,
            ),
          ) : SizedBox.shrink()
        ],
      ),
    );
  }

  Widget _buildRevokedAllowanceItem(TokenAllowance allowance, bool drawSeparatorLine) {
    final metadata = allowance.metadata!;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          RichText(
            text: TextSpan(
              style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.bold),
              children: [
                WidgetSpan(
                  child: Icon(Icons.check_circle_rounded, size: 13, color: Colors.green,)
                ),
                TextSpan(
                  text: "  You are revoking all previous allowances given to ",
                ),
                WidgetSpan(
                  child: AddressWidget(
                    address: allowance.spender.with0x,
                    chainId: widget.safeAccount.network.chainId,
                    truncateLength: 8,
                    showBlockies: false,
                    style: TextStyle(fontSize: 12, color: Colors.grey[400], fontWeight: FontWeight.w800),
                  ),
                ),
                TextSpan(
                  text: " of your account's ",
                ),
                WidgetSpan(
                  child: SizedBox(
                    width: 14,
                    height: 14,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(70),
                      child: metadata.logoUri == "unknown" ? Container(
                        alignment: Alignment.center,
                        color: Colors.grey,
                        child: Text("?", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),),
                      ) : Image.network(metadata.logoUri),
                    ),
                  ),
                ),
                TextSpan(
                  text: " ${metadata.name} (${metadata.symbol})",
                  style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.w800),
                ),
                TextSpan(
                  text: " balance",
                ),
              ]
            ),
          ),
          drawSeparatorLine ? Container(
            margin: EdgeInsets.only(top: 8),
            child: DottedLine(
              direction: Axis.horizontal,
              dashColor: Colors.white54,
              dashGapLength: 2.5,
            ),
          ) : SizedBox.shrink()
        ],
      ),
    );
  }

  Widget _buildNFTTransfersCard(BuildContext context) {
    final nftTransfers = widget.simulationResult.nftTransfers;
    return _buildCard(
      context,
      title: 'NFT Transfers',
      icon: Icons.image,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: nftTransfers.length,
        itemBuilder: (context, index) {
          final nftTransfer = nftTransfers[index];
          return _buildNFTTransferItem(nftTransfer, index == nftTransfers.length-1 ? false : true);
        },
      ),
    );
  }

  Widget _buildNFTTransferItem(NFTTransfer nftTransfer, bool drawSeparatorLine) {
    var isReceived = false;
    if (nftTransfer.recipient.with0x.toLowerCase() == widget.safeAccount.address.toLowerCase()){
      isReceived = true;
    }
    final metadata = nftTransfer.metadata!;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildNFTImage(metadata.imageURI, size: 40),
              SizedBox(width: 8,),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${metadata.collectionName} (${metadata.symbol})',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Token ID: ${nftTransfer.tokenId}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                isReceived ? Icons.arrow_downward : Icons.arrow_upward,
                color: isReceived ? Colors.green : Colors.red,
                size: 20,
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isReceived ? 'From' : 'To',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Spacer(),
              AddressWidget(
                address: isReceived ? nftTransfer.sender.with0x : nftTransfer.recipient.with0x,
                chainId: widget.safeAccount.network.chainId,
                truncateLength: 8,
                showBlockies: false,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          drawSeparatorLine ? Container(
            margin: EdgeInsets.only(top: 8),
            child: DottedLine(
              direction: Axis.horizontal,
              dashColor: Colors.white54,
              dashGapLength: 2.5,
            ),
          ) : SizedBox.shrink()
        ],
      ),
    );
  }

  Widget _buildNFTAllowancesCard(BuildContext context) {
    final nftAllowances = widget.simulationResult.nftAllowances;
    return _buildCard(
      context,
      title: 'NFT Allowances',
      icon: Icons.collections,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: nftAllowances.length,
        itemBuilder: (context, index) {
          final nftAllowance = nftAllowances[index];
          return _buildNFTAllowanceItem(nftAllowance, index == nftAllowances.length-1 ? false : true);
        },
      ),
    );
  }

  Widget _buildNFTAllowanceItem(NFTAllowance nftAllowance, bool drawSeparatorLine) {
    // Check if this is a revocation (spender is zero address)
    if (nftAllowance.spender.with0x.toLowerCase() == '0x0000000000000000000000000000000000000000') {
      return _buildRevokedNFTAllowanceItem(nftAllowance, drawSeparatorLine);
    }

    final metadata = nftAllowance.metadata!;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildNFTImage(metadata.imageURI, size: 50),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.bold),
                    children: [
                      WidgetSpan(
                        child: Icon(Icons.warning_amber, size: 13, color: Colors.orange,)
                      ),
                      TextSpan(
                        text: "  You are giving ",
                      ),
                      WidgetSpan(
                        child: AddressWidget(
                          address: nftAllowance.spender.with0x,
                          chainId: widget.safeAccount.network.chainId,
                          truncateLength: 8,
                          showBlockies: false,
                          style: TextStyle(fontSize: 12, color: Colors.grey[400], fontWeight: FontWeight.w800),
                        ),
                      ),
                      TextSpan(
                        text: " permission to transfer NFT ",
                      ),
                      TextSpan(
                        text: "${metadata.collectionName} (${metadata.symbol})",
                        style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.w800),
                      ),
                      TextSpan(
                        text: " with Token ID ",
                      ),
                      TextSpan(
                        text: "${nftAllowance.tokenId}",
                        style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.w800),
                      ),
                      TextSpan(
                        text: " from your account",
                      ),
                    ]
                  ),
                ),
              ),
            ],
          ),
          drawSeparatorLine ? Container(
            margin: EdgeInsets.only(top: 8),
            child: DottedLine(
              direction: Axis.horizontal,
              dashColor: Colors.white54,
              dashGapLength: 2.5,
            ),
          ) : SizedBox.shrink()
        ],
      ),
    );
  }

  Widget _buildRevokedNFTAllowanceItem(NFTAllowance nftAllowance, bool drawSeparatorLine) {
    final metadata = nftAllowance.metadata!;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildNFTImage(metadata.imageURI, size: 50),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.bold),
                    children: [
                      WidgetSpan(
                        child: Icon(Icons.check_circle_rounded, size: 13, color: Colors.green,)
                      ),
                      TextSpan(
                        text: "  You are revoking the approval for NFT ",
                      ),
                      TextSpan(
                        text: "${metadata.collectionName} (${metadata.symbol})",
                        style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.w800),
                      ),
                      TextSpan(
                        text: " with Token ID ",
                      ),
                      TextSpan(
                        text: "${nftAllowance.tokenId}",
                        style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.w800),
                      ),
                    ]
                  ),
                ),
              ),
            ],
          ),
          drawSeparatorLine ? Container(
            margin: EdgeInsets.only(top: 8),
            child: DottedLine(
              direction: Axis.horizontal,
              dashColor: Colors.white54,
              dashGapLength: 2.5,
            ),
          ) : SizedBox.shrink()
        ],
      ),
    );
  }

  Widget _buildSafeSettingsChangesCard(BuildContext context) {
    final changes = widget.simulationResult.safeSettingsChanges;
    if (changes.isEmpty) {
      return _buildCard(
        context,
        title: 'Safe Settings Changes',
        icon: Icons.settings,
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 16.0),
          child: Text(
            'No Safe settings changes detected\n(owners, and threshold changes)',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return _buildCard(
      context,
      title: 'Safe Settings Changes',
      icon: Icons.settings,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: changes.length,
        itemBuilder: (context, index) {
          final change = changes[index];
          return _buildSafeSettingChangeItem(change, index == changes.length-1 ? false : true);
        },
      ),
    );
  }

  Widget _buildSafeSettingChangeItem(SafeSettingChange change, bool drawSeparatorLine) {
    String title = '';
    String description = '';
    bool isDescriptionAddress = false;
    IconData icon = Icons.add;

    switch (change.type) {
      case SafeSettingChangeType.OWNER_ADDITION:
        final owner = change.data[0] as EthereumAddress;
        title = 'Added new owner';
        description = owner.with0x;
        isDescriptionAddress = true;
        icon = Icons.add;
        break;
      case SafeSettingChangeType.OWNER_REVOCATION:
        final owner = change.data[0] as EthereumAddress;
        title = 'Removed owner';
        description = owner.with0x;
        isDescriptionAddress = true;
        icon = Icons.remove;
        break;
      case SafeSettingChangeType.THRESHOLD_CHANGE:
        final threshold = change.data[0] as BigInt;
        title = 'Threshold changed';
        description = 'New threshold: $threshold';
        icon = Icons.numbers;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(3),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white30),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Icon(
                  icon,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  // color: Colors.orange,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          if (isDescriptionAddress)
            AddressWidget(
              address: description,
              chainId: widget.safeAccount.chainId,
              showBlockies: true,
              truncateLength: 50,
              // style: TextStyle(fontSize: 12),
            ),
          if (!isDescriptionAddress)
            Text(description),
          drawSeparatorLine ? Container(
            margin: EdgeInsets.only(top: 8),
            child: DottedLine(
              direction: Axis.horizontal,
              dashColor: Colors.white54,
              dashGapLength: 2.5,
            ),
          ) : SizedBox.shrink()
        ],
      ),
    );
  }

  Widget _buildWarningsCard(BuildContext context) {
    final warnings = widget.simulationResult.warningTransactions;
    if (warnings.isEmpty) {
      return _buildCard(
        context,
        title: 'Warnings',
        icon: Icons.warning,
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 16.0),
          child: Text(
            'No warnings detected\n(allowances, safe modules, and safe guards changes)',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return _buildCard(
      context,
      title: 'Warnings',
      icon: Icons.warning,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: warnings.length,
        itemBuilder: (context, index) {
          final warning = warnings[index];
          return _buildWarningItem(warning, index == warnings.length-1 ? false : true);
        },
      ),
    );
  }

  Widget _buildWarningItem(WarningTransaction warning, bool drawSeparatorLine) {
    String title = '';
    String preDescription = "";
    String description = '';
    final address = warning.data[0] as EthereumAddress;
    if (warning.type == WarningTransactionType.MODULE_ADDITION){
      title = "Module added to your wallet";
      preDescription = "This will grant this module\n";
      description = "\nfull permission to execute transactions on your behalf, only proceed with this transaction if you trust this module";
    }else if (warning.type == WarningTransactionType.MODULE_REVOCATION){
      title = "Module removed from your wallet";
      preDescription = "This will remove this module\n";
      description = "\nfrom your wallet entirely, which removes access for this module on your wallet";
    }else if (warning.type == WarningTransactionType.MODULE_GUARD_CHANGE){
      title = "Changed module guard of your wallet";
      preDescription = "This will place this contract\n";
      description = "\nas a module guard, that performs on-chain checks to approve any transaction initiated on your wallet by one of your enabled modules, only proceed with this transaction if you trust this module guard";
    }else if (warning.type == WarningTransactionType.GUARD_CHANGE){
      title = "Changed transaction guard of your wallet";
      preDescription = "This will place this contract\n";
      description = "\nas a transaction guard, that performs on-chain checks to approve any transaction initiated and signed by the owner(s), only proceed with this transaction if you trust this guard";
    }else if (warning.type == WarningTransactionType.DELEGATE_CALL){
      title = "Delegate call detected";
      preDescription = "A delegated call was detected to this contract\n";
      description = "\nwhich allows this contract to execute any operation on your behalf, only proceed if you trust and know what is the behavior of this contract";
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 8, top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.amber,
                size: 16,
              ),
              SizedBox(width: 5,),
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          RichText(
            text: TextSpan(
                text: preDescription,
                style: TextStyle(color: Colors.white54),
                children: [
                  WidgetSpan(
                    child: Container(
                      margin: EdgeInsets.symmetric(vertical: 3),
                      child: AddressWidget(
                        address: address.with0x,
                        chainId: widget.safeAccount.network.chainId,
                        truncateLength: 13,
                        showBlockies: false,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    )
                  ),
                  TextSpan(text: description),
                  WidgetSpan(
                    child: drawSeparatorLine ? Container(
                      margin: EdgeInsets.only(top: 8),
                      child: DottedLine(
                        direction: Axis.horizontal,
                        dashColor: Colors.white54,
                        dashGapLength: 2.5,
                      ),
                    ) : SizedBox.shrink()
                  )
                ]
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDangerousTransactionCard(BuildContext context) {
    final dangerousObject = widget.simulationResult.dangerous;
    String title = 'DANGEROUS TRANSACTION';
    String description = '';
    final dangerousType = dangerousObject.$2;
    final dangerousData = dangerousObject.$3 as (EthereumAddress, EthereumAddress);
    if (dangerousType == DangerousTransactionType.SINGLETON_CHANGE) {
      description = 'This transaction attempts to change the Safe singleton contract. This is extremely dangerous and should never be approved unless you explicitly opted in to upgrading your account’s contracts and are absolutely certain about the implications. The Safe contract is the core of your account security. If you are not completely sure about this action, abort the transaction immediately and consult the official Safe support channels before proceeding.';
    } else {
      description = 'This transaction has been identified as potentially dangerous. Please exercise extreme caution before proceeding. Do not approve unless you fully understand what this transaction does.';
    }
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(Icons.dangerous_rounded, color: Colors.red, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.error, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    description,
                    style: TextStyle(
                      color: Colors.red[800],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            if (dangerousType == DangerousTransactionType.SINGLETON_CHANGE)
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8,),
                  Text(
                    "New Singleton address",
                    style: TextStyle(
                      color: Colors.red[800],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4,),
                  AddressWidget(
                    address: dangerousData.$2.eip55With0x,
                    chainId: widget.safeAccount.network.chainId,
                    showBlockies: false,
                    truncateLength: 14,
                    style: TextStyle(
                      color: Colors.red[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[900]!.withAlpha((255*0.1).toInt()),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red, width: 2),
              ),
              child: Row(
                children: [
                  Icon(Icons.block, color: Colors.red[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'WARNING: This transaction could result in loss of funds. Only proceed if you are completely certain about what you are doing.',
                      style: TextStyle(
                        color: Colors.red[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget child,
    Widget? infoIcon,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                if (infoIcon != null) infoIcon,
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildNFTImage(String? imageURI, {double size = 40}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(8),
        ),
        child: imageURI != null && imageURI.isNotEmpty
          ? _NFTMediaPlayer(
              mediaUrl: imageURI,
              size: size,
            )
          : Icon(
              Icons.image_not_supported,
              size: size * 0.6,
              color: Colors.grey[600],
            ),
      ),
    );
  }

}

class _NFTMediaPlayer extends StatefulWidget {
  final String mediaUrl;
  final double size;

  const _NFTMediaPlayer({
    required this.mediaUrl,
    required this.size,
  });

  @override
  State<_NFTMediaPlayer> createState() => _NFTMediaPlayerState();
}

class _NFTMediaPlayerState extends State<_NFTMediaPlayer> {
  Player? _player;
  VideoController? _videoController;
  bool _isVideo = false;
  bool _videoInitialized = false;
  bool _checkingVideo = true;

  @override
  void initState() {
    super.initState();
    _attemptVideoInitialization();
  }

  Future<void> _attemptVideoInitialization() async {
    try {
      _player = Player();
      _videoController = VideoController(_player!);

      // Set a timeout for video initialization
      await _player!.open(Media(widget.mediaUrl)).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw TimeoutException('Video initialization timeout');
        },
      );

      // Wait a bit for the video to buffer and check if it's valid
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted && _player != null) {
        setState(() {
          _isVideo = true;
          _videoInitialized = true;
          _checkingVideo = false;
          // Configure video playback like a GIF
          _player!.setPlaylistMode(PlaylistMode.loop);
          _player!.setVolume(0.0); // Muted like GIFs
          _player!.play();
        });
      }
    } catch (e) {
      // If video initialization fails, fall back to image
      if (mounted) {
        setState(() {
          _isVideo = false;
          _checkingVideo = false;
        });
      }
      _player?.dispose();
      _player = null;
      _videoController = null;
    }
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // While checking if it's a video, show loading
    if (_checkingVideo) {
      return Center(
        child: SizedBox(
          width: widget.size * 0.5,
          height: widget.size * 0.5,
          child: CircularProgressIndicator(
            strokeWidth: 2,
          ),
        ),
      );
    }

    // If it's a video and initialized, show video player
    if (_isVideo && _videoInitialized && _videoController != null) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: Video(
          controller: _videoController!,
          fit: BoxFit.cover,
          controls: NoVideoControls,
        ),
      );
    }

    // Fall back to image
    return Image.network(
      widget.mediaUrl,
      width: widget.size,
      height: widget.size,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: SizedBox(
            width: widget.size * 0.5,
            height: widget.size * 0.5,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                : null,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Icon(
          Icons.broken_image,
          size: widget.size * 0.6,
          color: Colors.grey[600],
        );
      },
    );
  }
}

