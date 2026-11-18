import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octet_pulse_app/presentation/attendance/views/facial_liveness_verification_sheet.dart';

void main() {
  Widget buildTestableWidget({Size size = const Size(400, 800)}) {
    return MaterialApp(
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  FacialLivenessVerificationSheet.show(
                    context,
                    employeeId: 'EMP-101',
                    employeeName: 'Safeer Hussain',
                  );
                },
                child: const Text('Open Verification Sheet'),
              );
            },
          ),
        ),
      ),
    );
  }

  group('FacialLivenessVerificationSheet Widget Tests', () {
    testWidgets('renders biometric verification UI elements properly', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.tap(find.text('Open Verification Sheet'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Biometric Liveness Verification'), findsOneWidget);
      expect(
        find.textContaining('Anti-Spoofing Clock-In Check'),
        findsOneWidget,
      );
      expect(find.textContaining('Ambient Sensor:'), findsOneWidget);
      expect(find.textContaining('STEP 1 / 2'), findsOneWidget);
      expect(find.byIcon(Icons.face), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets(
      'advances through challenge sequence and displays attestation',
      (tester) async {
        await tester.pumpWidget(buildTestableWidget());
        await tester.tap(find.text('Open Verification Sheet'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // Step 1
        final step1Button = find.byType(FilledButton);
        expect(step1Button, findsOneWidget);
        await tester.tap(step1Button);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Step 2
        final step2Button = find.byType(FilledButton);
        expect(step2Button, findsOneWidget);
        await tester.tap(step2Button);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Success attestation view
        expect(find.text('Liveness Attestation Generated'), findsOneWidget);
        expect(find.text('SHA-256 ATTESTATION HASH'), findsOneWidget);
        expect(find.text('Confirm Biometric Clock-In'), findsOneWidget);
        expect(find.byIcon(Icons.verified_user), findsOneWidget);
      },
    );

    testWidgets(
      'low light simulation triggers PIN fallback and authorizes with 1234',
      (tester) async {
        await tester.pumpWidget(buildTestableWidget());
        await tester.tap(find.text('Open Verification Sheet'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // Tap simulate low light
        await tester.tap(find.text('Sim Low-Light'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Supervisor PIN'), findsOneWidget);
        expect(find.text('Authorize & Generate Attestation'), findsOneWidget);

        // Enter invalid pin
        await tester.enterText(find.byType(TextField), '9999');
        await tester.tap(find.text('Authorize & Generate Attestation'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(
          find.text('Invalid Supervisor PIN. Default is 1234'),
          findsOneWidget,
        );

        // Enter valid pin
        await tester.enterText(find.byType(TextField), '1234');
        await tester.tap(find.text('Authorize & Generate Attestation'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Liveness Attestation Generated'), findsOneWidget);
        expect(
          find.textContaining('Supervisor Override Verified'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'safe rendering on 800x360 landscape viewport with zero overflow',
      (tester) async {
        tester.view.physicalSize = const Size(800, 360);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          buildTestableWidget(size: const Size(800, 360)),
        );
        await tester.tap(find.text('Open Verification Sheet'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text('Biometric Liveness Verification'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
