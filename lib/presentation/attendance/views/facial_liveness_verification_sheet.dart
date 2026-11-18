import 'package:flutter/material.dart';

import '../../../domain/entities/liveness_challenge.dart';
import '../../../domain/services/liveness_service.dart';

class FacialLivenessVerificationSheet extends StatefulWidget {
  final String employeeId;
  final String employeeName;

  const FacialLivenessVerificationSheet({
    super.key,
    this.employeeId = 'EMP-101',
    this.employeeName = 'Safeer Hussain',
  });

  static Future<LivenessAttestation?> show(
    BuildContext context, {
    String employeeId = 'EMP-101',
    String employeeName = 'Safeer Hussain',
  }) {
    return showModalBottomSheet<LivenessAttestation>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => FacialLivenessVerificationSheet(
        employeeId: employeeId,
        employeeName: employeeName,
      ),
    );
  }

  @override
  State<FacialLivenessVerificationSheet> createState() =>
      _FacialLivenessVerificationSheetState();
}

class _FacialLivenessVerificationSheetState
    extends State<FacialLivenessVerificationSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  late List<LivenessAction> _challenges;
  final List<LivenessAction> _completedActions = [];
  int _currentStepIndex = 0;
  double _luxLevel = 125.0;
  bool _isLowLightSimulated = false;
  bool _showPinFallback = false;
  final TextEditingController _pinController = TextEditingController();
  String? _pinError;
  LivenessAttestation? _attestation;

  @override
  void initState() {
    super.initState();
    _challenges = LivenessService.generateChallengeSequence(count: 2);
    _luxLevel = LivenessService.simulateAmbientLux();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _advanceChallenge() {
    if (_currentStepIndex < _challenges.length) {
      setState(() {
        _completedActions.add(_challenges[_currentStepIndex]);
        _currentStepIndex++;
        if (_currentStepIndex >= _challenges.length) {
          _attestation = LivenessService.createAttestation(
            employeeId: widget.employeeId,
            completedActions: _completedActions,
            luxLevel: _luxLevel,
            isFallbackUsed: false,
          );
        }
      });
    }
  }

  void _toggleLowLightSimulation() {
    setState(() {
      _isLowLightSimulated = !_isLowLightSimulated;
      _luxLevel = LivenessService.simulateAmbientLux(
        simulateLowLight: _isLowLightSimulated,
      );
      if (_luxLevel < LivenessService.lowLightThresholdLux) {
        _showPinFallback = true;
      }
    });
  }

  void _verifySupervisorPin() {
    final pin = _pinController.text.trim();
    if (pin == '1234') {
      setState(() {
        _pinError = null;
        _attestation = LivenessService.createAttestation(
          employeeId: widget.employeeId,
          completedActions: _completedActions,
          luxLevel: _luxLevel,
          isFallbackUsed: true,
        );
      });
    } else {
      setState(() {
        _pinError = 'Invalid Supervisor PIN. Default is 1234';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(context, colorScheme),
                const SizedBox(height: 12),
                _buildLuxMeterBanner(context, colorScheme),
                const SizedBox(height: 16),
                if (_attestation != null)
                  _buildAttestationSuccessView(context, colorScheme)
                else if (_showPinFallback)
                  _buildPinFallbackView(context, colorScheme)
                else
                  _buildVerificationFlow(context, colorScheme, isLandscape),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme colorScheme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.fingerprint,
            color: colorScheme.onPrimaryContainer,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Biometric Liveness Verification',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                'Anti-Spoofing Clock-In Check (${widget.employeeName})',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Cancel Verification',
        ),
      ],
    );
  }

  Widget _buildLuxMeterBanner(BuildContext context, ColorScheme colorScheme) {
    final isLowLight = _luxLevel < LivenessService.lowLightThresholdLux;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isLowLight
            ? colorScheme.errorContainer.withValues(alpha: 0.5)
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isLowLight ? colorScheme.error : colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isLowLight ? Icons.brightness_low : Icons.brightness_high,
            size: 18,
            color: isLowLight ? colorScheme.error : colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isLowLight
                  ? 'Low Light (${_luxLevel.toStringAsFixed(1)} lux < 20 lux): Optical sensor degraded'
                  : 'Ambient Sensor: ${_luxLevel.toStringAsFixed(1)} lux (Optimal illumination)',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isLowLight
                    ? colorScheme.onErrorContainer
                    : colorScheme.onSurface,
              ),
            ),
          ),
          TextButton(
            onPressed: _toggleLowLightSimulation,
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 6),
            ),
            child: Text(
              _isLowLightSimulated ? 'Reset Light' : 'Sim Low-Light',
              style: const TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationFlow(
    BuildContext context,
    ColorScheme colorScheme,
    bool isLandscape,
  ) {
    final currentAction = _challenges[_currentStepIndex];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: colorScheme.primary, width: 3),
                color: colorScheme.surfaceContainerLow,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.face,
                    size: 80,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  ),
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colorScheme.secondary.withValues(alpha: 0.6),
                        width: 1.5,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'STEP ${_currentStepIndex + 1} / ${_challenges.length}',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  currentAction.icon,
                  color: colorScheme.onPrimary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentAction.displayName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currentAction.instruction,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_challenges.length, (idx) {
            final isDone = idx < _currentStepIndex;
            final isCurrent = idx == _currentStepIndex;

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isDone
                    ? colorScheme.secondaryContainer
                    : (isCurrent
                          ? colorScheme.primaryContainer
                          : colorScheme.surfaceContainerHighest),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    isDone ? Icons.check_circle : Icons.circle_outlined,
                    size: 14,
                    color: isDone
                        ? colorScheme.onSecondaryContainer
                        : (isCurrent
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _challenges[idx].displayName,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isCurrent
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isDone
                          ? colorScheme.onSecondaryContainer
                          : (isCurrent
                                ? colorScheme.onPrimaryContainer
                                : colorScheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: _advanceChallenge,
          icon: const Icon(Icons.camera_alt),
          label: Text('Perform "${currentAction.displayName}" & Verify'),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () => setState(() => _showPinFallback = true),
          icon: const Icon(Icons.pin, size: 16),
          label: const Text('Use Supervisor PIN Fallback'),
        ),
      ],
    );
  }

  Widget _buildPinFallbackView(BuildContext context, ColorScheme colorScheme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.tertiaryContainer.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                Icons.shield_outlined,
                color: colorScheme.onTertiaryContainer,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Low-light or optical failure override: Enter Supervisor Authorization PIN (Default: 1234).',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onTertiaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _pinController,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 6,
          decoration: InputDecoration(
            labelText: 'Supervisor PIN',
            hintText: 'Enter 1234',
            prefixIcon: const Icon(Icons.lock_outline),
            errorText: _pinError,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _verifySupervisorPin,
          icon: const Icon(Icons.check),
          label: const Text('Authorize & Generate Attestation'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => setState(() => _showPinFallback = false),
          child: const Text('Return to Optical Facial Verification'),
        ),
      ],
    );
  }

  Widget _buildAttestationSuccessView(
    BuildContext context,
    ColorScheme colorScheme,
  ) {
    final att = _attestation!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.secondaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.secondary),
          ),
          child: Column(
            children: [
              Icon(Icons.verified_user, color: colorScheme.secondary, size: 40),
              const SizedBox(height: 8),
              Text(
                'Liveness Attestation Generated',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSecondaryContainer,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                att.isFallbackUsed
                    ? 'Supervisor Override Verified (Confidence: ${(att.confidenceScore * 100).toInt()}%)'
                    : 'Cryptographic Anti-Spoofing Passed (Confidence: ${(att.confidenceScore * 100).toInt()}%)',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSecondaryContainer,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SHA-256 ATTESTATION HASH',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      att.attestationHash,
                      style: TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        color: colorScheme.primary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: () => Navigator.of(context).pop(att),
          icon: const Icon(Icons.login),
          label: const Text('Confirm Biometric Clock-In'),
        ),
      ],
    );
  }
}
