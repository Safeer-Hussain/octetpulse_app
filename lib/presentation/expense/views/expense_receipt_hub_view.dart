import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/app_feedback.dart';
import '../../../domain/entities/expense_receipt.dart';
import '../../../domain/services/currency_converter.dart';
import '../bloc/expense_bloc.dart';
import '../bloc/expense_event.dart';
import '../bloc/expense_state.dart';
import 'ocr_camera_scanner_sheet.dart';

class ExpenseReceiptHubView extends StatelessWidget {
  final bool showHeader;

  const ExpenseReceiptHubView({super.key, this.showHeader = true});

  void _openScanner(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<ExpenseBloc>(),
        child: const OcrCameraScannerSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ExpenseBloc, ExpenseState>(
      listener: (context, state) {
        if (state.feedbackMessage != null) {
          AppFeedback.showSuccess(context, state.feedbackMessage!);
        }
        if (state.errorMessage != null) {
          AppFeedback.showError(context, state.errorMessage!);
        }
      },
      builder: (context, state) {
        final isLandscape =
            MediaQuery.of(context).orientation == Orientation.landscape;

        return Scaffold(
          floatingActionButton: FloatingActionButton.extended(
            heroTag: 'fab_expense_scan',
            onPressed: () => _openScanner(context),
            icon: const Icon(Icons.document_scanner),
            label: const Text('Scan Expense Receipt'),
          ),
          body: isLandscape
              ? _buildLandscapeLayout(context, state)
              : _buildPortraitLayout(context, state),
        );
      },
    );
  }

  Widget _buildPortraitLayout(BuildContext context, ExpenseState state) {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildMetricsOverview(context, state),
          const SizedBox(height: 12),
          _buildCategoryFiltersBar(context, state),
          const SizedBox(height: 8),
          _buildStatusFiltersBar(context, state),
          const SizedBox(height: 12),
          _buildReceiptsList(context, state),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildLandscapeLayout(BuildContext context, ExpenseState state) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Master Pane: Metrics, Filters, & Receipts List
        Expanded(
          flex: 5,
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildMetricsOverview(context, state),
                const SizedBox(height: 8),
                _buildCategoryFiltersBar(context, state),
                const SizedBox(height: 6),
                _buildStatusFiltersBar(context, state),
                const SizedBox(height: 10),
                _buildReceiptsList(context, state, isLandscape: true),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
        const VerticalDivider(width: 1),
        // Right Detail Pane: Selected Receipt OCR Token Inspection & Audit
        Expanded(
          flex: 5,
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildDetailedReceiptInspector(context, state),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsOverview(BuildContext context, ExpenseState state) {
    final colorScheme = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildMetricChip(
          context,
          icon: Icons.payments_outlined,
          label: 'Reimbursable',
          value: '\$${state.totalReimbursableUsd.toStringAsFixed(2)} USD',
          color: colorScheme.primary,
        ),
        _buildMetricChip(
          context,
          icon: Icons.pending_actions,
          label: 'Approvals',
          value: state.pendingCount.toString(),
          color: colorScheme.secondary,
        ),
        _buildMetricChip(
          context,
          icon: Icons.receipt_long,
          label: 'Receipts',
          value: state.expenses.length.toString(),
          color: colorScheme.tertiary,
        ),
      ],
    );
  }

  Widget _buildMetricChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            '$label: ',
            style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFiltersBar(BuildContext context, ExpenseState state) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: FilterChip(
              label: const Text(
                'All Categories',
                style: TextStyle(fontSize: 11),
              ),
              selected: state.selectedCategory == null,
              onSelected: (_) {
                context.read<ExpenseBloc>().add(
                  FilterExpensesEvent(
                    category: null,
                    status: state.selectedStatus,
                  ),
                );
              },
            ),
          ),
          ...ExpenseCategory.values.map((cat) {
            final isSelected = state.selectedCategory == cat;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: FilterChip(
                avatar: Icon(cat.icon, size: 14),
                label: Text(
                  cat.displayName,
                  style: const TextStyle(fontSize: 11),
                ),
                selected: isSelected,
                onSelected: (_) {
                  context.read<ExpenseBloc>().add(
                    FilterExpensesEvent(
                      category: isSelected ? null : cat,
                      status: state.selectedStatus,
                    ),
                  );
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStatusFiltersBar(BuildContext context, ExpenseState state) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: FilterChip(
              label: const Text('All Statuses', style: TextStyle(fontSize: 11)),
              selected: state.selectedStatus == null,
              onSelected: (_) {
                context.read<ExpenseBloc>().add(
                  FilterExpensesEvent(
                    category: state.selectedCategory,
                    status: null,
                  ),
                );
              },
            ),
          ),
          ...ExpenseStatus.values.map((st) {
            final isSelected = state.selectedStatus == st;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: FilterChip(
                label: Text(
                  st.displayName,
                  style: const TextStyle(fontSize: 11),
                ),
                selected: isSelected,
                onSelected: (_) {
                  context.read<ExpenseBloc>().add(
                    FilterExpensesEvent(
                      category: state.selectedCategory,
                      status: isSelected ? null : st,
                    ),
                  );
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildReceiptsList(
    BuildContext context,
    ExpenseState state, {
    bool isLandscape = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final receipts = state.filteredExpenses;

    if (receipts.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 40,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 12),
              Text(
                'No Expense Claims Found',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Scan a receipt or tap Quick Presets to submit your first expense claim.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: receipts.map((r) {
        final isSelected = state.selectedExpense?.id == r.id;
        return _buildReceiptCard(context, r, isSelected: isSelected);
      }).toList(),
    );
  }

  Widget _buildReceiptCard(
    BuildContext context,
    ExpenseReceipt r, {
    bool isSelected = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final dateFormat = DateFormat('MMM dd, yyyy');

    Color statusBg;
    Color statusFg;
    switch (r.status) {
      case ExpenseStatus.draft:
        statusBg = colorScheme.surfaceContainerHighest;
        statusFg = colorScheme.onSurfaceVariant;
        break;
      case ExpenseStatus.submitted:
        statusBg = colorScheme.primaryContainer;
        statusFg = colorScheme.onPrimaryContainer;
        break;
      case ExpenseStatus.approved:
        statusBg = colorScheme.secondaryContainer;
        statusFg = colorScheme.onSecondaryContainer;
        break;
      case ExpenseStatus.reimbursed:
        statusBg = colorScheme.tertiaryContainer;
        statusFg = colorScheme.onTertiaryContainer;
        break;
      case ExpenseStatus.rejected:
        statusBg = colorScheme.errorContainer;
        statusFg = colorScheme.onErrorContainer;
        break;
    }

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: isSelected
            ? BorderSide(color: colorScheme.primary, width: 1.5)
            : BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          context.read<ExpenseBloc>().add(SelectExpenseEvent(r));
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Row: Avatar, Merchant Name, Status Chip
              Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: colorScheme.primaryContainer,
                    child: Icon(
                      r.category.icon,
                      size: 14,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.merchantName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          '${r.category.displayName} • ${dateFormat.format(r.receiptDate)}',
                          style: TextStyle(
                            fontSize: 10,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      r.status.displayName,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: statusFg,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Currency Conversion Bar
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Original: ${CurrencyConverter.formatAmount(r.rawAmount, r.currency)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          if (r.taxAmount > 0)
                            Text(
                              'Tax: ${CurrencyConverter.formatAmount(r.taxAmount, r.currency)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'USD Base',
                          style: TextStyle(
                            fontSize: 9,
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '\$${r.usdEquivalent.toStringAsFixed(2)} USD',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Action Buttons Row
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  if (r.canApprove)
                    FilledButton.tonalIcon(
                      onPressed: () {
                        context.read<ExpenseBloc>().add(
                          UpdateExpenseStatusEvent(
                            receiptId: r.id,
                            status: ExpenseStatus.approved,
                          ),
                        );
                      },
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                      ),
                      icon: const Icon(Icons.check, size: 12),
                      label: const Text(
                        'Approve',
                        style: TextStyle(fontSize: 10),
                      ),
                    ),
                  if (r.canReimburse)
                    FilledButton.icon(
                      onPressed: () {
                        context.read<ExpenseBloc>().add(
                          UpdateExpenseStatusEvent(
                            receiptId: r.id,
                            status: ExpenseStatus.reimbursed,
                          ),
                        );
                      },
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                      ),
                      icon: const Icon(Icons.attach_money, size: 12),
                      label: const Text(
                        'Disburse to Payroll',
                        style: TextStyle(fontSize: 10),
                      ),
                    ),
                  if (r.canReject)
                    TextButton.icon(
                      onPressed: () {
                        context.read<ExpenseBloc>().add(
                          UpdateExpenseStatusEvent(
                            receiptId: r.id,
                            status: ExpenseStatus.rejected,
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: colorScheme.error,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                      ),
                      icon: const Icon(Icons.close, size: 12),
                      label: const Text(
                        'Decline',
                        style: TextStyle(fontSize: 10),
                      ),
                    ),
                  TextButton.icon(
                    onPressed: () {
                      context.read<ExpenseBloc>().add(DeleteExpenseEvent(r.id));
                    },
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      foregroundColor: colorScheme.onSurfaceVariant,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                    ),
                    icon: const Icon(Icons.delete_outline, size: 12),
                    label: const Text('Remove', style: TextStyle(fontSize: 10)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailedReceiptInspector(
    BuildContext context,
    ExpenseState state,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final r = state.selectedExpense;
    final dateFormat = DateFormat('EEE, MMM dd, yyyy - hh:mm a');

    if (r == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              'Select a receipt from the list to inspect OCR extracted tokens and reimbursement audit details.',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.document_scanner,
                  color: colorScheme.primary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'OCR Token Inspection & Audit',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            Text(
              'Claim ID: ${r.id}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Claimant: ${r.employeeName} (${r.employeeId})',
              style: TextStyle(fontSize: 11, color: colorScheme.onSurface),
            ),
            Text(
              'Submitted: ${dateFormat.format(r.createdAt)}',
              style: TextStyle(
                fontSize: 10,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Raw OCR Text Payload:',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: SelectableText(
                r.rawOcrText,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
