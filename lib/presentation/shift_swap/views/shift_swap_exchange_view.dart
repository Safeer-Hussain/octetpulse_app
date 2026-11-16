import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/app_feedback.dart';
import '../../../domain/entities/shift_swap_proposal.dart';
import '../bloc/shift_swap_bloc.dart';
import '../bloc/shift_swap_event.dart';
import '../bloc/shift_swap_state.dart';
import 'counter_shift_swap_modal.dart';
import 'propose_shift_swap_modal.dart';

class ShiftSwapExchangeView extends StatelessWidget {
  const ShiftSwapExchangeView({super.key});

  void _openProposeModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const ProposeShiftSwapModal(),
    );
  }

  void _openCounterModal(BuildContext context, ShiftSwapProposal proposal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => CounterShiftSwapModal(proposal: proposal),
    );
  }

  void _showRejectDialog(BuildContext context, ShiftSwapProposal proposal) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) {
        final colorScheme = Theme.of(dialogCtx).colorScheme;
        return AlertDialog(
          title: Text(
            'Decline Shift Swap',
            style: TextStyle(color: colorScheme.onSurface),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Decline shift swap proposal from ${proposal.requesterName}?',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonCtrl,
                decoration: const InputDecoration(
                  labelText: 'Reason for Declining',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Back'),
            ),
            FilledButton(
              onPressed: () {
                final reason = reasonCtrl.text.trim();
                context.read<ShiftSwapBloc>().add(
                  RejectShiftSwapEvent(
                    proposalId: proposal.id,
                    rejectionReason: reason.isNotEmpty
                        ? reason
                        : 'Schedule conflict',
                  ),
                );
                Navigator.of(dialogCtx).pop();
              },
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.error,
                foregroundColor: colorScheme.onError,
              ),
              child: const Text('Decline Proposal'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ShiftSwapBloc, ShiftSwapState>(
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
            heroTag: 'fab_shift_swap_propose',
            onPressed: () => _openProposeModal(context),
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Propose Shift Swap'),
          ),
          body: isLandscape
              ? _buildLandscapeLayout(context, state)
              : _buildPortraitLayout(context, state),
        );
      },
    );
  }

  Widget _buildPortraitLayout(BuildContext context, ShiftSwapState state) {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (state.latestNotification != null &&
              !state.latestNotification!.isRead)
            _buildPushNotificationBanner(context, state),
          _buildMetricsOverview(context, state),
          const SizedBox(height: 12),
          _buildFiltersBar(context, state),
          const SizedBox(height: 12),
          _buildProposalsList(context, state),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildLandscapeLayout(BuildContext context, ShiftSwapState state) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (state.latestNotification != null &&
                    !state.latestNotification!.isRead)
                  _buildPushNotificationBanner(context, state),
                _buildMetricsOverview(context, state),
                const SizedBox(height: 10),
                _buildFiltersBar(context, state),
                const SizedBox(height: 10),
                _buildProposalsList(context, state, isLandscape: true),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          flex: 5,
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildDetailedProposalView(context, state),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPushNotificationBanner(
    BuildContext context,
    ShiftSwapState state,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final notif = state.latestNotification!;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.notifications_active,
            size: 18,
            color: colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notif.title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                Text(
                  notif.message,
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onPrimaryContainer.withValues(
                      alpha: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: () {
              context.read<ShiftSwapBloc>().add(
                DismissNotificationEvent(notif.id),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsOverview(BuildContext context, ShiftSwapState state) {
    final colorScheme = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildMetricChip(
          context,
          icon: Icons.pending_actions,
          label: 'Active Negotiations',
          value: state.pendingCount.toString(),
          color: colorScheme.primary,
        ),
        _buildMetricChip(
          context,
          icon: Icons.verified_outlined,
          label: 'Lead Approved',
          value: state.approvedCount.toString(),
          color: colorScheme.secondary,
        ),
        _buildMetricChip(
          context,
          icon: Icons.swap_calls,
          label: 'Total Proposals',
          value: state.proposals.length.toString(),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersBar(BuildContext context, ShiftSwapState state) {
    final departments = [
      'All',
      'Mobile Engineering',
      'Field Operations',
      'Cloud Infrastructure',
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: departments.map((dept) {
          final isSelected = state.selectedDepartment == dept;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: FilterChip(
              label: Text(dept, style: const TextStyle(fontSize: 11)),
              selected: isSelected,
              onSelected: (_) {
                context.read<ShiftSwapBloc>().add(
                  FilterShiftSwapsEvent(
                    selectedDepartment: dept,
                    selectedStatus: state.selectedStatus,
                  ),
                );
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildProposalsList(
    BuildContext context,
    ShiftSwapState state, {
    bool isLandscape = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final proposals = state.filteredProposals;

    if (proposals.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.swap_horiz_outlined,
                size: 40,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 12),
              Text(
                'No Shift Swap Proposals Found',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tap "Propose Shift Swap" below to initiate a peer trade within your department.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: proposals.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, idx) {
        final p = proposals[idx];
        return _buildProposalCard(context, p);
      },
    );
  }

  Widget _buildProposalCard(BuildContext context, ShiftSwapProposal p) {
    final colorScheme = Theme.of(context).colorScheme;
    final dateFormat = DateFormat('MMM dd, yyyy');

    Color statusBg;
    Color statusFg;
    switch (p.status) {
      case ShiftSwapStatus.proposed:
        statusBg = colorScheme.primaryContainer;
        statusFg = colorScheme.onPrimaryContainer;
        break;
      case ShiftSwapStatus.countered:
        statusBg = colorScheme.tertiaryContainer;
        statusFg = colorScheme.onTertiaryContainer;
        break;
      case ShiftSwapStatus.accepted:
        statusBg = colorScheme.secondaryContainer;
        statusFg = colorScheme.onSecondaryContainer;
        break;
      case ShiftSwapStatus.leadApproved:
        statusBg = colorScheme.surfaceContainerHighest;
        statusFg = colorScheme.primary;
        break;
      case ShiftSwapStatus.rejected:
        statusBg = colorScheme.errorContainer;
        statusFg = colorScheme.onErrorContainer;
        break;
      case ShiftSwapStatus.cancelled:
        statusBg = colorScheme.surfaceContainerLow;
        statusFg = colorScheme.onSurfaceVariant;
        break;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: colorScheme.primaryContainer,
                  child: Text(
                    p.requesterName.isNotEmpty
                        ? p.requesterName.substring(0, 1)
                        : 'S',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${p.requesterName} -> ${p.targetPeerName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
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
                    p.statusLabel,
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
            // Shift Trade Indicator
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Giving Away',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                        Text(
                          dateFormat.format(p.requesterShiftDate),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          p.requesterShiftType.displayName,
                          style: TextStyle(
                            fontSize: 10,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.swap_horiz,
                    size: 22,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'In Exchange',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.secondary,
                          ),
                        ),
                        Text(
                          dateFormat.format(p.targetShiftDate),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          p.targetShiftType.displayName,
                          style: TextStyle(
                            fontSize: 10,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Reason: ${p.reason}',
              style: TextStyle(fontSize: 11, color: colorScheme.onSurface),
            ),
            if (p.counterReason != null) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.tertiaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Counter Offer: ${p.counterReason}',
                  style: TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: colorScheme.onTertiaryContainer,
                  ),
                ),
              ),
            ],
            if (p.approvedByLeadName != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.verified, size: 14, color: colorScheme.primary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Signed off by: ${p.approvedByLeadName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            // Actions Row
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (p.canAccept)
                  FilledButton.tonalIcon(
                    onPressed: () {
                      context.read<ShiftSwapBloc>().add(
                        AcceptShiftSwapEvent(p.id),
                      );
                    },
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                    ),
                    icon: const Icon(Icons.check, size: 14),
                    label: const Text(
                      'Accept Swap',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                if (p.canCounter)
                  OutlinedButton.icon(
                    onPressed: () => _openCounterModal(context, p),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                    ),
                    icon: const Icon(Icons.reply, size: 14),
                    label: const Text(
                      'Counter Offer',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                if (p.canApproveByLead)
                  FilledButton.icon(
                    onPressed: () {
                      context.read<ShiftSwapBloc>().add(
                        LeadApproveShiftSwapEvent(
                          proposalId: p.id,
                          leadName: 'Safeer Hussain (Principal Architect)',
                        ),
                      );
                    },
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                    ),
                    icon: const Icon(Icons.verified_user, size: 14),
                    label: const Text(
                      'Lead Sign-Off',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                if (p.canReject)
                  TextButton.icon(
                    onPressed: () => _showRejectDialog(context, p),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      foregroundColor: colorScheme.error,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                    ),
                    icon: const Icon(Icons.close, size: 14),
                    label: const Text(
                      'Decline',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                if (p.canCancel)
                  TextButton.icon(
                    onPressed: () {
                      context.read<ShiftSwapBloc>().add(
                        CancelShiftSwapEvent(p.id),
                      );
                    },
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                    ),
                    icon: const Icon(Icons.cancel_outlined, size: 14),
                    label: const Text('Cancel', style: TextStyle(fontSize: 11)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedProposalView(
    BuildContext context,
    ShiftSwapState state,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final proposal = state.selectedProposal;

    if (proposal == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              'Select a shift swap negotiation to inspect full audit timeline.',
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.timeline, color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Negotiation Audit Trail',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTimelineStep(
              context,
              title: 'Proposal Dispatched',
              subtitle:
                  '${proposal.requesterName} created proposal for ${proposal.targetPeerName}',
              time: DateFormat('MMM dd, hh:mm a').format(proposal.createdAt),
              isCompleted: true,
            ),
            if (proposal.counterReason != null)
              _buildTimelineStep(
                context,
                title: 'Counter Offer Submitted',
                subtitle: proposal.counterReason!,
                time: DateFormat('MMM dd, hh:mm a').format(proposal.updatedAt),
                isCompleted: true,
              ),
            _buildTimelineStep(
              context,
              title: 'Peer Acceptance',
              subtitle:
                  proposal.status == ShiftSwapStatus.accepted ||
                      proposal.status == ShiftSwapStatus.leadApproved
                  ? '${proposal.targetPeerName} accepted the trade terms'
                  : 'Pending peer confirmation',
              time: '',
              isCompleted:
                  proposal.status == ShiftSwapStatus.accepted ||
                  proposal.status == ShiftSwapStatus.leadApproved,
            ),
            _buildTimelineStep(
              context,
              title: 'Statutory Lead Sign-off',
              subtitle:
                  proposal.approvedByLeadName ??
                  'Pending management authorization',
              time: '',
              isCompleted: proposal.status == ShiftSwapStatus.leadApproved,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineStep(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String time,
    required bool isCompleted,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: isCompleted
                ? colorScheme.primary
                : colorScheme.outlineVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    if (time.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: 10,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
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
