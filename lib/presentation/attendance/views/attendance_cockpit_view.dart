import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/app_feedback.dart';
import '../../../core/utils/app_formatters.dart';
import '../bloc/attendance_bloc.dart';
import '../bloc/attendance_event.dart';
import '../bloc/attendance_state.dart';
import '../../shift_swap/bloc/shift_swap_bloc.dart';
import '../../shift_swap/bloc/shift_swap_state.dart';
import '../../shift_swap/views/shift_swap_exchange_view.dart';
import 'leave_request_modal.dart';
import 'facial_liveness_verification_sheet.dart';

class AttendanceCockpitView extends StatefulWidget {
  const AttendanceCockpitView({super.key});

  @override
  State<AttendanceCockpitView> createState() => _AttendanceCockpitViewState();
}

class _AttendanceCockpitViewState extends State<AttendanceCockpitView> {
  Timer? _ticker;
  int _elapsedSeconds = 0;
  int _viewMode = 0; // 0 = Clock-In & Roster, 1 = Shift Swap Exchange

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _elapsedSeconds++;
        });
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _openLeaveModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const LeaveRequestModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AttendanceBloc, AttendanceState>(
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

        if (_viewMode == 1) {
          return Column(
            children: [
              _buildModeSwitcher(context, isLandscape),
              const Expanded(child: ShiftSwapExchangeView()),
            ],
          );
        }

        return Scaffold(
          floatingActionButton: FloatingActionButton.extended(
            heroTag: 'fab_attendance_clockin',
            onPressed: () async {
              if (state.isClockedIn) {
                context.read<AttendanceBloc>().add(const ClockOutEvent());
              } else {
                final attestation = await FacialLivenessVerificationSheet.show(
                  context,
                  employeeId: 'EMP-101',
                  employeeName: 'Safeer Hussain',
                );
                if (attestation != null && context.mounted) {
                  context.read<AttendanceBloc>().add(
                    ClockInEvent(
                      employeeId: 'EMP-101',
                      employeeName: 'Safeer Hussain',
                      latitude: state.currentLatitude,
                      longitude: state.currentLongitude,
                      isWithinGeofence: state.isWithinGeofence,
                      geofenceDistanceMeters: state.geofenceDistanceMeters,
                      livenessAttestationHash: attestation.attestationHash,
                      isBiometricallyVerified: true,
                      livenessLuxLevel: attestation.luxLevel,
                    ),
                  );
                }
              }
            },
            icon: Icon(state.isClockedIn ? Icons.logout : Icons.login),
            label: Text(
              state.isClockedIn ? 'Clock Out Shift' : 'Clock In Shift',
            ),
          ),
          body: Column(
            children: [
              _buildModeSwitcher(context, isLandscape),
              Expanded(
                child: isLandscape
                    ? _buildLandscapeLayout(context, state)
                    : _buildPortraitLayout(context, state),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModeSwitcher(BuildContext context, bool isLandscape) {
    return BlocBuilder<ShiftSwapBloc, ShiftSwapState>(
      builder: (context, swapState) {
        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isLandscape ? 12 : 16,
            vertical: isLandscape ? 4 : 8,
          ),
          child: SegmentedButton<int>(
            segments: [
              const ButtonSegment<int>(
                value: 0,
                icon: Icon(Icons.timer_outlined, size: 16),
                label: Text(
                  'Attendance & Roster',
                  style: TextStyle(fontSize: 12),
                ),
              ),
              ButtonSegment<int>(
                value: 1,
                icon: Badge(
                  isLabelVisible: swapState.pendingCount > 0,
                  label: Text(swapState.pendingCount.toString()),
                  child: const Icon(Icons.swap_horiz, size: 16),
                ),
                label: const Text(
                  'Shift Swap Exchange',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
            selected: {_viewMode},
            onSelectionChanged: (val) {
              setState(() => _viewMode = val.first);
            },
          ),
        );
      },
    );
  }

  Widget _buildPortraitLayout(BuildContext context, AttendanceState state) {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCockpitCard(context, state),
          const SizedBox(height: 12),
          _buildQuickSwapBanner(context),
          const SizedBox(height: 16),
          _buildWeeklyTrendChart(context),
          const SizedBox(height: 16),
          _buildApprovalQueue(context, state),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildQuickSwapBanner(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.swap_horiz,
                size: 18,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Peer-to-Peer Shift Swap Engine',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    'Need to trade shifts? Negotiate with colleagues in your department.',
                    style: TextStyle(
                      fontSize: 10,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.tonal(
              onPressed: () => setState(() => _viewMode = 1),
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
              ),
              child: const Text('Exchange', style: TextStyle(fontSize: 11)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLandscapeLayout(BuildContext context, AttendanceState state) {
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
                _buildCockpitCard(context, state),
                const SizedBox(height: 12),
                _buildWeeklyTrendChart(context),
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
                _buildApprovalQueue(context, state),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCockpitCard(BuildContext context, AttendanceState state) {
    final colorScheme = Theme.of(context).colorScheme;
    final isClockedIn = state.isClockedIn;
    final isOnBreak = state.isOnBreak;

    final duration = state.currentRecord != null
        ? Duration(
            seconds:
                state.currentRecord!.durationSeconds +
                (isClockedIn ? _elapsedSeconds : 0),
          )
        : Duration.zero;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.timer_outlined,
                    color: colorScheme.onPrimaryContainer,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Shift Operations Cockpit',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'Safeer Hussain (Principal Architect)',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isClockedIn
                        ? colorScheme.secondaryContainer
                        : (isOnBreak
                              ? colorScheme.tertiaryContainer
                              : colorScheme.surfaceContainerHighest),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isClockedIn
                        ? 'CLOCKED IN'
                        : (isOnBreak ? 'ON BREAK' : 'CLOCKED OUT'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isClockedIn
                          ? colorScheme.onSecondaryContainer
                          : (isOnBreak
                                ? colorScheme.onTertiaryContainer
                                : colorScheme.onSurfaceVariant),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Row(
                children: [
                  Icon(
                    state.isWithinGeofence
                        ? Icons.check_circle
                        : Icons.warning_amber,
                    color: state.isWithinGeofence
                        ? colorScheme.secondary
                        : colorScheme.error,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.isWithinGeofence
                          ? (state.activeGeofenceZone != null
                                ? 'Verified: Within ${state.activeGeofenceZone!.name} Polygon Boundary'
                                : 'Verified: Within ${AppConstants.hqGeofenceRadiusMeters.toInt()}m ${AppConstants.hqLocationName} Geofence (${state.geofenceDistanceMeters.toStringAsFixed(1)}m from center)')
                          : 'Warning: Outside Campus Geofence (${state.geofenceDistanceMeters.toStringAsFixed(1)}m from boundary)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (isClockedIn &&
                state.currentRecord?.isBiometricallyVerified == true) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colorScheme.secondary.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.verified_user,
                      color: colorScheme.secondary,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Biometric Anti-Spoofing Verified: Liveness hash attested (${state.currentRecord?.livenessLuxLevel?.toStringAsFixed(1) ?? '120.0'} lux)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: 10,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ACTIVE SHIFT DURATION',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppFormatters.formatDurationHoursMins(duration),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (isClockedIn || isOnBreak)
                      OutlinedButton.icon(
                        onPressed: () {
                          context.read<AttendanceBloc>().add(
                            const ToggleBreakEvent(),
                          );
                        },
                        icon: Icon(
                          isOnBreak ? Icons.play_arrow : Icons.pause,
                          size: 16,
                        ),
                        label: Text(isOnBreak ? 'Resume' : 'Break'),
                      ),
                    FilledButton.tonalIcon(
                      onPressed: () => _openLeaveModal(context),
                      icon: const Icon(Icons.add_task, size: 16),
                      label: const Text('Leave/OT'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyTrendChart(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.insights, color: colorScheme.primary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Workforce Attendance & Efficiency Trend',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                Text(
                  'Past 7 Days',
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 130,
              width: double.infinity,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        reservedSize: 0,
                        showTitles: false,
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        reservedSize: 0,
                        showTitles: false,
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        reservedSize: 0,
                        showTitles: false,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        getTitlesWidget: (val, meta) {
                          const days = [
                            'Mon',
                            'Tue',
                            'Wed',
                            'Thu',
                            'Fri',
                            'Sat',
                            'Sun',
                          ];
                          final idx = val.toInt();
                          if (idx >= 0 && idx < days.length) {
                            return Text(
                              days[idx],
                              style: TextStyle(
                                fontSize: 10,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: 6,
                  minY: 80,
                  maxY: 100,
                  lineBarsData: [
                    LineChartBarData(
                      spots: const [
                        FlSpot(0, 94.2),
                        FlSpot(1, 96.0),
                        FlSpot(2, 91.5),
                        FlSpot(3, 98.4),
                        FlSpot(4, 95.8),
                        FlSpot(5, 89.0),
                        FlSpot(6, 97.2),
                      ],
                      isCurved: true,
                      color: colorScheme.secondary,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: colorScheme.secondary.withValues(alpha: 0.15),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApprovalQueue(BuildContext context, AttendanceState state) {
    final colorScheme = Theme.of(context).colorScheme;
    final pending = state.pendingLeaveRequests;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.approval, color: colorScheme.primary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Team Lead Clearance Queue (${pending.length})',
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
            if (pending.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'No pending approval requests in queue.',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: pending.length,
                separatorBuilder: (_, _) =>
                    Divider(color: colorScheme.outlineVariant, height: 16),
                itemBuilder: (context, idx) {
                  final req = pending[idx];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${req.employeeName} • ${req.requestType}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${req.hours.toStringAsFixed(1)} hrs',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        req.reason,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              context.read<AttendanceBloc>().add(
                                ApproveLeaveRequestEvent(
                                  requestId: req.id,
                                  status: 'Rejected',
                                  comment: 'Deferred by Lead Architect',
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: colorScheme.error,
                              visualDensity: VisualDensity.compact,
                            ),
                            child: const Text('Reject'),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.tonal(
                            onPressed: () {
                              context.read<AttendanceBloc>().add(
                                ApproveLeaveRequestEvent(
                                  requestId: req.id,
                                  status: 'Approved',
                                  comment: 'Cleared by Lead Architect',
                                ),
                              );
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: colorScheme.secondaryContainer,
                              foregroundColor: colorScheme.onSecondaryContainer,
                              visualDensity: VisualDensity.compact,
                            ),
                            child: const Text('Approve'),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
