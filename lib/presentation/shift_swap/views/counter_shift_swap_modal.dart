import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../domain/entities/shift_swap_proposal.dart';
import '../bloc/shift_swap_bloc.dart';
import '../bloc/shift_swap_event.dart';

class CounterShiftSwapModal extends StatefulWidget {
  final ShiftSwapProposal proposal;

  const CounterShiftSwapModal({super.key, required this.proposal});

  @override
  State<CounterShiftSwapModal> createState() => _CounterShiftSwapModalState();
}

class _CounterShiftSwapModalState extends State<CounterShiftSwapModal> {
  final _formKey = GlobalKey<FormState>();
  final _counterReasonController = TextEditingController();

  late DateTime _newTargetShiftDate;
  late ShiftType _newTargetShiftType;

  @override
  void initState() {
    super.initState();
    _newTargetShiftDate = widget.proposal.targetShiftDate.add(
      const Duration(days: 1),
    );
    _newTargetShiftType = widget.proposal.targetShiftType;
  }

  @override
  void dispose() {
    _counterReasonController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _newTargetShiftDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );
    if (picked != null) {
      setState(() => _newTargetShiftDate = picked);
    }
  }

  void _submitCounter() {
    if (!_formKey.currentState!.validate()) return;

    context.read<ShiftSwapBloc>().add(
      CounterShiftSwapEvent(
        proposalId: widget.proposal.id,
        newTargetShiftDate: _newTargetShiftDate,
        newTargetShiftType: _newTargetShiftType,
        counterReason: _counterReasonController.text.trim(),
      ),
    );
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
                      Icon(Icons.edit_calendar, color: colorScheme.secondary),
                      const SizedBox(width: 8),
                      Text(
                        'Counter Swap Offer',
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
              const SizedBox(height: 8),
              Text(
                'Proposing alternative shift date/rotation to ${widget.proposal.requesterName}.',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Card(
                color: colorScheme.surfaceContainerLow,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Proposed Replacement Shift',
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
                              onPressed: () => _pickDate(context),
                              icon: const Icon(Icons.calendar_today, size: 14),
                              label: Text(
                                dateFormat.format(_newTargetShiftDate),
                                style: const TextStyle(fontSize: 11),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<ShiftType>(
                              initialValue: _newTargetShiftType,
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
                                  setState(() => _newTargetShiftType = val);
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
              TextFormField(
                controller: _counterReasonController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Counter Offer Justification',
                  hintText: 'e.g. Can only cover evening rotation due to morning lab testing',
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a counter justification.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _submitCounter,
                icon: const Icon(Icons.reply, size: 16),
                label: const Text('Dispatch Counter Offer'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
