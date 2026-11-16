import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/utils/app_feedback.dart';
import '../../../domain/entities/shift_swap_proposal.dart';
import '../bloc/shift_swap_bloc.dart';
import '../bloc/shift_swap_event.dart';

class ProposeShiftSwapModal extends StatefulWidget {
  final String department;
  final String requesterId;
  final String requesterName;
  final String requesterRole;

  const ProposeShiftSwapModal({
    super.key,
    this.department = 'Mobile Engineering',
    this.requesterId = 'EMP-101',
    this.requesterName = 'Safeer Hussain',
    this.requesterRole = 'Principal Architect',
  });

  @override
  State<ProposeShiftSwapModal> createState() => _ProposeShiftSwapModalState();
}

class _ProposeShiftSwapModalState extends State<ProposeShiftSwapModal> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final Uuid _uuid = const Uuid();

  late String _selectedDepartment;
  String? _selectedPeerId;
  String? _selectedPeerName;
  String? _selectedPeerRole;

  DateTime _requesterShiftDate = DateTime.now().add(const Duration(days: 1));
  ShiftType _requesterShiftType = ShiftType.morning;

  DateTime _targetShiftDate = DateTime.now().add(const Duration(days: 3));
  ShiftType _targetShiftType = ShiftType.evening;

  // Department peer roster lookup
  final Map<String, List<Map<String, String>>> _departmentPeers = {
    'Mobile Engineering': [
      {
        'id': 'EMP-102',
        'name': 'Zainab Tariq',
        'role': 'Lead Flutter Engineer',
      },
      {
        'id': 'EMP-103',
        'name': 'Hamza Malik',
        'role': 'Senior Mobile Engineer',
      },
    ],
    'Field Operations': [
      {
        'id': 'EMP-105',
        'name': 'Tariq Mahmood',
        'role': 'Field Operations Lead',
      },
      {
        'id': 'EMP-106',
        'name': 'Usman Khan',
        'role': 'Senior Field Specialist',
      },
    ],
    'Cloud Infrastructure': [
      {'id': 'EMP-104', 'name': 'Bilal Ahmed', 'role': 'Lead Cloud Architect'},
      {
        'id': 'EMP-107',
        'name': 'Ayesha Noor',
        'role': 'Site Reliability Engineer',
      },
    ],
  };

  @override
  void initState() {
    super.initState();
    _selectedDepartment = widget.department;
    _setInitialPeer();
  }

  void _setInitialPeer() {
    final peers = _departmentPeers[_selectedDepartment] ?? [];
    if (peers.isNotEmpty) {
      _selectedPeerId = peers.first['id'];
      _selectedPeerName = peers.first['name'];
      _selectedPeerRole = peers.first['role'];
    } else {
      _selectedPeerId = null;
      _selectedPeerName = null;
      _selectedPeerRole = null;
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickRequesterDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _requesterShiftDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );
    if (picked != null) {
      setState(() => _requesterShiftDate = picked);
    }
  }

  Future<void> _pickTargetDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetShiftDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );
    if (picked != null) {
      setState(() => _targetShiftDate = picked);
    }
  }

  void _submitProposal() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPeerId == null) {
      AppFeedback.showError(context, 'Please select a departmental peer.');
      return;
    }

    final proposal = ShiftSwapProposal(
      id: 'SWAP-${_uuid.v4().substring(0, 6).toUpperCase()}',
      requesterId: widget.requesterId,
      requesterName: widget.requesterName,
      requesterRole: widget.requesterRole,
      targetPeerId: _selectedPeerId!,
      targetPeerName: _selectedPeerName ?? 'Colleague',
      targetPeerRole: _selectedPeerRole ?? 'Engineer',
      department: _selectedDepartment,
      requesterShiftDate: _requesterShiftDate,
      requesterShiftType: _requesterShiftType,
      targetShiftDate: _targetShiftDate,
      targetShiftType: _targetShiftType,
      reason: _reasonController.text.trim(),
      status: ShiftSwapStatus.proposed,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    context.read<ShiftSwapBloc>().add(ProposeShiftSwapEvent(proposal));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dateFormat = DateFormat('EEE, MMM dd, yyyy');
    final availablePeers = _departmentPeers[_selectedDepartment] ?? [];

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.swap_horiz, color: colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Propose Peer Shift Swap',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Department Selector
              DropdownButtonFormField<String>(
                initialValue: _selectedDepartment,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Department Group',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                items: _departmentPeers.keys.map((dept) {
                  return DropdownMenuItem(
                    value: dept,
                    child: Text(dept, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedDepartment = val;
                      _setInitialPeer();
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              // Peer Selector
              DropdownButtonFormField<String>(
                initialValue: _selectedPeerId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Select Peer in Department',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                items: availablePeers.map((peer) {
                  return DropdownMenuItem(
                    value: peer['id'],
                    child: Text(
                      '${peer['name']} (${peer['role']})',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    final found = availablePeers.firstWhere(
                      (p) => p['id'] == val,
                    );
                    setState(() {
                      _selectedPeerId = found['id'];
                      _selectedPeerName = found['name'];
                      _selectedPeerRole = found['role'];
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              // Give-away Shift Card
              Card(
                color: colorScheme.surfaceContainerLow,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Current Shift (Giving Away)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _pickRequesterDate(context),
                              icon: const Icon(Icons.calendar_today, size: 14),
                              label: Text(
                                dateFormat.format(_requesterShiftDate),
                                style: const TextStyle(fontSize: 11),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<ShiftType>(
                              initialValue: _requesterShiftType,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                border: OutlineInputBorder(),
                              ),
                              items: ShiftType.values.map((s) {
                                return DropdownMenuItem(
                                  value: s,
                                  child: Text(
                                    s.shortName,
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _requesterShiftType = val);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Requested Shift Card
              Card(
                color: colorScheme.surfaceContainerLow,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Peer Shift Desired (In Exchange)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _pickTargetDate(context),
                              icon: const Icon(Icons.calendar_today, size: 14),
                              label: Text(
                                dateFormat.format(_targetShiftDate),
                                style: const TextStyle(fontSize: 11),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<ShiftType>(
                              initialValue: _targetShiftType,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                border: OutlineInputBorder(),
                              ),
                              items: ShiftType.values.map((s) {
                                return DropdownMenuItem(
                                  value: s,
                                  child: Text(
                                    s.shortName,
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _targetShiftType = val);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Reason
              TextFormField(
                controller: _reasonController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Justification / Reason for Swap',
                  hintText:
                      'e.g. Attending Architecture Sync / Family emergency',
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a valid swap reason.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _submitProposal,
                icon: const Icon(Icons.send, size: 16),
                label: const Text('Dispatch Shift Swap Proposal'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
