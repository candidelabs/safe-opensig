import 'package:dotted_line/dotted_line.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
import 'package:safe_opensig/shared/widgets/simulation_scope_content.dart';
import 'package:safe_opensig/shared/widgets/trust_minimized_note.dart';
import 'package:safe_opensig/shared/widgets/address_detail_sheet.dart';
import 'package:safe_opensig/shared/widgets/address_widget.dart';
import 'package:safe_opensig/shared/widgets/hold_to_confirm_button.dart';
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
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline),
              tooltip: 'Simulation scope',
              onPressed: () => SimulationScopeContent.showAsSheet(context),
            ),
          ],
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
                'The transaction simulation failed, which may indicate that this transaction will revert when submitted onchain.',
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
              HoldToConfirmButton(
                label: 'Proceed Anyway',
                duration: const Duration(seconds: 3),
                onConfirmed: () {
                  GoRouter.of(context).push(
                    "/verify-transaction/hashes",
                    extra: (widget.safeAccount, widget.transaction),
                  );
                },
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
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Simulation scope',
            onPressed: () => SimulationScopeContent.showAsSheet(context),
          ),
        ],
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
                              TextSpan(text: 'differs from current onchain nonce '),
                              TextSpan(
                                text: '(${widget.transaction.latestNonce})',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(text: '. Simulation uses the current nonce to bypass onchain checks.'),
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
            HoldToConfirmButton(
              label: 'Confirm',
              onConfirmed: () {
                GoRouter.of(context).push(
                  "/verify-transaction/hashes",
                  extra: (widget.safeAccount, widget.transaction),
                );
              },
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () {
                  GoRouter.of(context).go("/accounts",);
                },
                child: const Text('Abort'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceChangesCard(BuildContext context) {
    final transfers = widget.simulationResult.transfers;
    if (transfers.isEmpty) {
      return _buildVerifiedRow(
        context,
        icon: Icons.account_balance_wallet,
        title: 'Balance changes',
        message: 'no token transfers',
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

  void _showTokenDetail(BuildContext context, String tokenAddress) {
    showModalBottomSheet(
      context: context,
      builder: (context) => AddressDetailSheet(
        address: tokenAddress,
        chainId: widget.safeAccount.network.chainId,
        blockiesSize: 64,
      ),
    );
  }

  Widget _tokenLogo(String logoUri, double size) {
    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(70),
        child: logoUri == "unknown"
            ? Container(
                alignment: Alignment.center,
                color: Colors.grey,
                child: const Text("?", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              )
            : Image.network(logoUri),
      ),
    );
  }

  WidgetSpan _inlineTokenSpan({
    required BuildContext context,
    required String tokenAddress,
    required String logoUri,
    required String label,
    TextStyle? labelStyle,
  }) {
    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: GestureDetector(
        onTap: () => _showTokenDetail(context, tokenAddress),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _tokenLogo(logoUri, 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: (labelStyle ?? const TextStyle()).copyWith(
                decoration: TextDecoration.underline,
                decorationStyle: TextDecorationStyle.dotted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  WidgetSpan _inlineTappableLabelSpan({
    required BuildContext context,
    required String tokenAddress,
    required String label,
    TextStyle? labelStyle,
  }) {
    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: GestureDetector(
        onTap: () => _showTokenDetail(context, tokenAddress),
        child: Text(
          label,
          style: (labelStyle ?? const TextStyle()).copyWith(
            decoration: TextDecoration.underline,
            decorationStyle: TextDecorationStyle.dotted,
          ),
        ),
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
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _showTokenDetail(context, transfer.token.with0x),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _tokenLogo(metadata.logoUri, 25),
                    const SizedBox(width: 5),
                    Text(
                      metadata.symbol,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                        decorationStyle: TextDecorationStyle.dotted,
                      ),
                    ),
                  ],
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
      return _buildVerifiedRow(
        context,
        icon: Icons.shopping_bag,
        title: 'Token allowances',
        message: 'no new grants or revocations',
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
              style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.bold),
              children: [
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Icon(Icons.warning_amber, size: 16, color: Colors.orange,)
                ),
                TextSpan(
                  text: "  You are giving ",
                ),
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: AddressWidget(
                    address: allowance.spender.with0x,
                    chainId: widget.safeAccount.network.chainId,
                    truncateLength: 8,
                    showBlockies: false,
                    style: TextStyle(fontSize: 14, color: Colors.grey[400], fontWeight: FontWeight.w800),
                  ),
                ),
                TextSpan(
                  text: " permission to spend $readableAmount ",
                  style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.w800),
                ),
                _inlineTokenSpan(
                  context: context,
                  tokenAddress: allowance.token.with0x,
                  logoUri: metadata.logoUri,
                  label: metadata.symbol,
                  labelStyle: TextStyle(fontSize: 14, color: Colors.grey[400], fontWeight: FontWeight.w800),
                ),
                TextSpan(
                  text: " from your account.",
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
              style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.bold),
              children: [
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Icon(Icons.check_circle_rounded, size: 16, color: Colors.green,)
                ),
                TextSpan(
                  text: "  You are revoking all previous ",
                ),
                _inlineTokenSpan(
                  context: context,
                  tokenAddress: allowance.token.with0x,
                  logoUri: metadata.logoUri,
                  label: "${metadata.name} (${metadata.symbol})",
                  labelStyle: TextStyle(fontSize: 14, color: Colors.grey[400], fontWeight: FontWeight.w800),
                ),
                TextSpan(
                  text: " allowances given to ",
                ),
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: AddressWidget(
                    address: allowance.spender.with0x,
                    chainId: widget.safeAccount.network.chainId,
                    truncateLength: 8,
                    showBlockies: false,
                    style: TextStyle(fontSize: 14, color: Colors.grey[400], fontWeight: FontWeight.w800),
                  ),
                ),
                TextSpan(
                  text: ".",
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
    final account = widget.safeAccount.address.toLowerCase();
    final isReceived = nftTransfer.recipient.with0x.toLowerCase() == account;
    final isMint = nftTransfer.sender.with0x.toLowerCase() == '0x0000000000000000000000000000000000000000';
    final isBurn = nftTransfer.recipient.with0x.toLowerCase() == '0x0000000000000000000000000000000000000000';
    final metadata = nftTransfer.metadata!;
    final amountColor = isBurn ? Colors.red : isReceived || isMint ? Colors.green : Colors.red;
    final amountPrefix = isBurn ? "-" : isReceived || isMint ? "+" : "-";

    // Format amount for ERC-1155
    String? formattedAmount;
    if (nftTransfer.amount != null) {
      formattedAmount = nftTransfer.decimals != null
          ? Utilities.formatCryptoAmount(nftTransfer.amount!, nftTransfer.decimals!, symbol: metadata.symbol)
          : '${nftTransfer.amount} ${metadata.symbol}';
    }

    // Determine the counterparty label and address
    String counterpartyLabel;
    String counterpartyAddress;
    if (isMint) {
      counterpartyLabel = 'Minted to your account';
      counterpartyAddress = nftTransfer.recipient.with0x;
    } else if (isBurn) {
      counterpartyLabel = 'Burned from your account';
      counterpartyAddress = nftTransfer.sender.with0x;
    } else if (isReceived) {
      counterpartyLabel = 'From';
      counterpartyAddress = nftTransfer.sender.with0x;
    } else {
      counterpartyLabel = 'To';
      counterpartyAddress = nftTransfer.recipient.with0x;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Image + Collection name + direction icon
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _showTokenDetail(context, nftTransfer.collection.with0x),
                child: _buildNFTImage(metadata.imageURI, size: 40),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _showTokenDetail(context, nftTransfer.collection.with0x),
                      child: Text(
                        '${metadata.collectionName} (${metadata.symbol})',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                          decorationStyle: TextDecorationStyle.dotted,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      'ID: ${Utilities.truncate(nftTransfer.tokenId.toString(), leadingDigits: 8, trailingDigits: 4)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                isReceived || isMint ? Icons.arrow_downward : Icons.arrow_upward,
                color: amountColor,
                size: 20,
              ),
            ],
          ),
          // Row 2: Amount (on its own line so it doesn't squeeze the name)
          if (formattedAmount != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Text(
                    'Amount',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  Spacer(),
                  Flexible(
                    child: Text(
                      '$amountPrefix$formattedAmount',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: amountColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          // Row 3: Counterparty
          if (!isMint && !isBurn)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  counterpartyLabel,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Spacer(),
                AddressWidget(
                  address: counterpartyAddress,
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
          if (isMint || isBurn)
            Row(
              children: [
                Icon(
                  isMint ? Icons.add_circle_outline : Icons.remove_circle_outline,
                  size: 14,
                  color: isMint ? Colors.green[400] : Colors.red[400],
                ),
                SizedBox(width: 4),
                Text(
                  counterpartyLabel,
                  style: TextStyle(
                    fontSize: 12,
                    color: isMint ? Colors.green[400] : Colors.red[400],
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
    // Check if this is a revocation (spender is zero address or ApprovalForAll with approved=false)
    if (nftAllowance.spender.with0x.toLowerCase() == '0x0000000000000000000000000000000000000000'
        || (nftAllowance.isApprovalForAll && !nftAllowance.approved)) {
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
                        child: Icon(Icons.warning_amber, size: 13, color: nftAllowance.isApprovalForAll ? Colors.red : Colors.orange,)
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
                      if (nftAllowance.isApprovalForAll) ...[
                        TextSpan(
                          text: " permission to transfer ALL tokens in ",
                        ),
                        _inlineTappableLabelSpan(
                          context: context,
                          tokenAddress: nftAllowance.collection.with0x,
                          label: "${metadata.collectionName} (${metadata.symbol})",
                          labelStyle: TextStyle(fontSize: 12, color: Colors.grey[400], fontWeight: FontWeight.w800),
                        ),
                        TextSpan(
                          text: " from your account",
                        ),
                      ] else ...[
                        TextSpan(
                          text: " permission to transfer NFT ",
                        ),
                        _inlineTappableLabelSpan(
                          context: context,
                          tokenAddress: nftAllowance.collection.with0x,
                          label: "${metadata.collectionName} (${metadata.symbol})",
                          labelStyle: TextStyle(fontSize: 12, color: Colors.grey[400], fontWeight: FontWeight.w800),
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
                      ],
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
                      if (nftAllowance.isApprovalForAll) ...[
                        TextSpan(
                          text: "  You are revoking operator approval for ALL tokens in ",
                        ),
                        _inlineTappableLabelSpan(
                          context: context,
                          tokenAddress: nftAllowance.collection.with0x,
                          label: "${metadata.collectionName} (${metadata.symbol})",
                          labelStyle: TextStyle(fontSize: 12, color: Colors.grey[400], fontWeight: FontWeight.w800),
                        ),
                      ] else ...[
                        TextSpan(
                          text: "  You are revoking the approval for NFT ",
                        ),
                        _inlineTappableLabelSpan(
                          context: context,
                          tokenAddress: nftAllowance.collection.with0x,
                          label: "${metadata.collectionName} (${metadata.symbol})",
                          labelStyle: TextStyle(fontSize: 12, color: Colors.grey[400], fontWeight: FontWeight.w800),
                        ),
                        TextSpan(
                          text: " with Token ID ",
                        ),
                        TextSpan(
                          text: "${nftAllowance.tokenId}",
                          style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.w800),
                        ),
                      ],
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
      return _buildVerifiedRow(
        context,
        icon: Icons.settings,
        title: 'Safe settings',
        message: 'owners and threshold unchanged',
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
      return _buildVerifiedRow(
        context,
        icon: Icons.shield_outlined,
        title: 'Permission checks',
        message: 'no module, guard, or delegate-call changes',
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
      description = "\nas a module guard, that performs onchain checks to approve any transaction initiated on your wallet by one of your enabled modules, only proceed with this transaction if you trust this module guard";
    }else if (warning.type == WarningTransactionType.GUARD_CHANGE){
      title = "Changed transaction guard of your wallet";
      preDescription = "This will place this contract\n";
      description = "\nas a transaction guard, that performs onchain checks to approve any transaction initiated and signed by the owner(s), only proceed with this transaction if you trust this guard";
    }else if (warning.type == WarningTransactionType.DELEGATE_CALL){
      title = "Delegate call detected";
      preDescription = "A delegate call was detected to this contract\n";
      description = "\nwhich means this contract will run code with your Safe's full permissions. Only proceed if you trust this contract and understand what its code does.";
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
      description = 'This transaction attempts to change the Safe singleton, the core contract that runs your account. This is extremely dangerous and should never be approved unless you explicitly opted in to upgrading your account\'s contracts and are absolutely certain about the implications. The Safe contract is the core of your account security. If you are not completely sure about this action, abort the transaction immediately and consult the official Safe support channels before proceeding.';
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

  /// Compact "checked and clean" row for sections with no findings.
  /// Signals that the app actively verified the dimension, not that it
  /// was skipped. Keeps the full-card visual language (primary-color
  /// icon, full-contrast title) in a smaller footprint.
  Widget _buildVerifiedRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String message,
  }) {
    final theme = Theme.of(context);
    final mutedColor =
        theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7);
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: theme.primaryColor),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: mutedColor,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.check_circle_outline,
              size: 18,
              color: Colors.green[400],
            ),
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
        child: _buildNFTImageContent(imageURI, size),
      ),
    );
  }

  Widget _buildNFTImageContent(String? imageURI, double size) {
    if (imageURI == null || imageURI.isEmpty) {
      return Icon(
        Icons.image_not_supported,
        size: size * 0.6,
        color: Colors.grey[600],
      );
    }

    if (_isVideoUrl(imageURI)) {
      return Icon(
        Icons.movie_outlined,
        size: size * 0.6,
        color: Colors.grey[600],
      );
    }

    return Image.network(
      imageURI,
      width: size,
      height: size,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: SizedBox(
            width: size * 0.5,
            height: size * 0.5,
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
          size: size * 0.6,
          color: Colors.grey[600],
        );
      },
    );
  }

  bool _isVideoUrl(String url) {
    final path = url.split('?').first.split('#').first.toLowerCase();
    return path.endsWith('.mp4') ||
        path.endsWith('.webm') ||
        path.endsWith('.mov') ||
        path.endsWith('.m4v');
  }

}

