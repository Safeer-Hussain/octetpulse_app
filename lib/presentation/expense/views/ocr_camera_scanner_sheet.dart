import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/utils/app_feedback.dart';
import '../../../domain/entities/expense_receipt.dart';
import '../../../domain/services/currency_converter.dart';
import '../../../domain/services/ocr_receipt_parser.dart';
import '../bloc/expense_bloc.dart';
import '../bloc/expense_event.dart';

class OcrCameraScannerSheet extends StatefulWidget {
  final String employeeId;
  final String employeeName;

  const OcrCameraScannerSheet({
    super.key,
    this.employeeId = 'EMP-101',
    this.employeeName = 'Safeer Hussain',
  });

  @override
  State<OcrCameraScannerSheet> createState() => _OcrCameraScannerSheetState();
}

class _OcrCameraScannerSheetState extends State<OcrCameraScannerSheet>
    with SingleTickerProviderStateMixin {
  final _uuid = const Uuid();
  final _ocrTextController = TextEditingController();
  late AnimationController _laserController;

  ParsedOcrResult? _parsedResult;
  final bool _isScanningActive = true;

  final Map<String, String> _presets = {
    'Shell Fuel (PKR 8,500)': '''
SHELL PAKISTAN LIMITED
DHA Phase 5 Filling Station, Lahore
Date: 2026-11-17
Fuel: V-Power Petrol
Volume: 28.33 Litres
Subtotal: PKR 7,225.00
GST (17%): PKR 1,275.00
Grand Total: PKR 8,500.00
Payment Mode: Corporate Card
''',
    'PC Dining (PKR 14,250)': '''
PEARL CONTINENTAL HOTEL LAHORE
Marco Polo Restaurant - Client Lunch
Date: 2026-11-16
Executive Buffet x 4: PKR 10,800.00
Beverages: PKR 1,312.50
PRA Sales Tax (16%): PKR 1,938.00
Service Charge: PKR 199.50
Total Amount: PKR 14,250.00
Payment: Corporate Visa *8821
''',
    'Uber Transit (USD 48.50)': '''
UBER TECHNOLOGIES INC.
Trip Receipt - Airport Business Express
Date: 2026-11-15
Pickup: Terminal 2 Executive Gate
Dropoff: Innovation District
Trip Fare: \$36.50
Airport Surcharge: \$7.75
Transit Tax: \$4.25
Total Charged: \$48.50 USD
Payment: Corporate Mastercard *4419
''',
    'Dubai Mall Tech (AED 350)': '''
VIRGIN MEGASTORE - DUBAI MALL
Tax Invoice #: DXB-772109
Date: 2026-11-14
Item: USB-C Fast Charging Hub 100W
Subtotal: AED 333.33
VAT (5%): AED 16.67
Total Due: AED 350.00
Payment: Apple Pay Corporate
''',
  };

  @override
  void initState() {
    super.initState();
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Load initial preset
    _loadPreset('Shell Fuel (PKR 8,500)');
  }

  @override
  void dispose() {
    _laserController.dispose();
    _ocrTextController.dispose();
    super.dispose();
  }

  void _loadPreset(String title) {
    final text = _presets[title] ?? '';
    _ocrTextController.text = text;
    _parseText(text);
  }

  void _parseText(String text) {
    if (text.trim().isEmpty) {
      setState(() => _parsedResult = null);
      return;
    }
    final result = OcrReceiptParser.parse(text);
    setState(() => _parsedResult = result);
  }

  void _submitClaim() {
    if (_parsedResult == null || _parsedResult!.totalAmount <= 0) {
      AppFeedback.showError(
        context,
        'Cannot submit claim: No valid total amount detected in OCR payload.',
      );
      return;
    }

    final receipt = ExpenseReceipt(
      id: 'EXP-${_uuid.v4().substring(0, 6).toUpperCase()}',
      employeeId: widget.employeeId,
      employeeName: widget.employeeName,
      merchantName: _parsedResult!.merchantName,
      category: _parsedResult!.category,
      currency: _parsedResult!.currency,
      rawAmount: _parsedResult!.totalAmount,
      taxAmount: _parsedResult!.taxAmount,
      exchangeRateToUsd: CurrencyConverter.getRateToUsd(
        _parsedResult!.currency,
      ),
      usdEquivalent: _parsedResult!.usdEquivalent,
      receiptDate: _parsedResult!.receiptDate,
      rawOcrText: _ocrTextController.text.trim(),
      status: ExpenseStatus.submitted,
      createdAt: DateTime.now(),
    );

    context.read<ExpenseBloc>().add(SubmitExpenseClaimEvent(receipt));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dateFormat = DateFormat('EEE, MMM dd, yyyy');

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Row
            Row(
              children: [
                Icon(Icons.document_scanner, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Optical Expense Receipt Scanner',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Camera Viewfinder & Laser HUD
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.outlineVariant,
                  width: 1.5,
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.camera_alt_outlined,
                          size: 36,
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.6,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Optical Character Recognition Engine Active',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          'Align receipt within crosshairs for automated tokenization',
                          style: TextStyle(
                            fontSize: 10,
                            color: colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Animated Scanning Laser Bar
                  if (_isScanningActive)
                    AnimatedBuilder(
                      animation: _laserController,
                      builder: (context, _) {
                        return Positioned(
                          top: _laserController.value * 140,
                          left: 16,
                          right: 16,
                          child: Container(
                            height: 2,
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              boxShadow: [
                                BoxShadow(
                                  color: colorScheme.primary.withValues(
                                    alpha: 0.8,
                                  ),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  // Scanner corner brackets
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Icon(
                      Icons.crop_free,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Icon(
                      Icons.crop_free,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Icon(
                      Icons.crop_free,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Icon(
                      Icons.crop_free,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Quick Preset Selectors
            Text(
              'Sample Optical Receipt Presets:',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _presets.keys.map((key) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text(key, style: const TextStyle(fontSize: 11)),
                      onPressed: () => _loadPreset(key),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),

            // Editable Raw OCR text area
            TextField(
              controller: _ocrTextController,
              maxLines: 4,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
              decoration: const InputDecoration(
                labelText: 'Raw OCR Payload (Extracted Tokens)',
                hintText:
                    'Paste or type receipt text to test custom parsing...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(10),
              ),
              onChanged: _parseText,
            ),
            const SizedBox(height: 14),

            // Live Token Extraction HUD
            if (_parsedResult != null) ...[
              Card(
                color: colorScheme.surfaceContainerLow,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.insights,
                            size: 16,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Live Token Extraction Matrix',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${(_parsedResult!.confidenceScore * 100).toInt()}% Confidence',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      // Merchant & Category
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Merchant Detected',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                Text(
                                  _parsedResult!.merchantName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Chip(
                            avatar: Icon(
                              _parsedResult!.category.icon,
                              size: 14,
                            ),
                            label: Text(
                              _parsedResult!.category.displayName,
                              style: const TextStyle(fontSize: 10),
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Date & Original Amount
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Receipt Date',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                Text(
                                  dateFormat.format(_parsedResult!.receiptDate),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Tax Extracted',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                Text(
                                  CurrencyConverter.formatAmount(
                                    _parsedResult!.taxAmount,
                                    _parsedResult!.currency,
                                  ),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Total & USD Equivalent Highlight Banner
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.secondaryContainer.withValues(
                            alpha: 0.4,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: colorScheme.secondary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Original Total',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: colorScheme.onSecondaryContainer,
                                    ),
                                  ),
                                  Text(
                                    CurrencyConverter.formatAmount(
                                      _parsedResult!.totalAmount,
                                      _parsedResult!.currency,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSecondaryContainer,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: Icon(
                                Icons.arrow_forward,
                                size: 16,
                                color: colorScheme.secondary,
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'USD Base',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: colorScheme.secondary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '\$${_parsedResult!.usdEquivalent.toStringAsFixed(2)} USD',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.secondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Submit Button
            FilledButton.icon(
              onPressed: _submitClaim,
              icon: const Icon(Icons.send_rounded, size: 16),
              label: const Text('Submit for Reimbursement'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
