import 'package:bloomi/core/database/app_database.dart';
import 'package:bloomi/features/onboarding/data/local/onboarding_local_data_source.dart';
import 'package:bloomi/features/onboarding/domain/entities/onboarding_profile_entity.dart';
import 'package:bloomi/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:bloomi/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:bloomi/features/onboarding/presentation/pages/body_metrics_page.dart';
import 'package:bloomi/features/onboarding/presentation/pages/plan_ready_page.dart';
import 'package:drift/native.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeOnboardingRepository implements OnboardingRepository {
  @override
  Future<OnboardingProfileEntity?> loadExistingProfile({
    String? userId,
  }) async => null;

  @override
  Future<void> saveProfileAndComplete({
    required OnboardingProfileEntity profile,
    String? userId,
  }) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('selected onboarding step target is used by the computed plan', () {
    const profile = OnboardingProfileEntity(stepTarget: 12500);

    expect(profile.computedPlan.steps, 12500);
  });

  test('selected onboarding step target is saved to app targets', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final source = OnboardingLocalDataSourceImpl(
      db,
      userIdProvider: () => 'test_user',
    );

    await source.saveProfileAndTargets(
      profile: const OnboardingProfileEntity(stepTarget: 12500),
      userId: 'test_user',
    );

    final target = await db.select(db.targets).getSingle();
    expect(target.steps, 12500);
  });

  testWidgets('target weight input scrolls above the open keyboard', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding();
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(() => tester.view.viewInsets = const FakeViewPadding());

    final bloc = OnboardingBloc(
      onboardingRepository: _FakeOnboardingRepository(),
    );
    addTearDown(bloc.close);

    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: const MaterialApp(
          home: Scaffold(
            resizeToAvoidBottomInset: false,
            body: BodyMetricsPage(),
          ),
        ),
      ),
    );

    final targetWeightField = find.byType(TextField).last;
    await tester.ensureVisible(targetWeightField);
    await tester.tap(targetWeightField);
    await tester.pump();

    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pump(const Duration(milliseconds: 300));

    final fieldBottom = tester.getRect(targetWeightField).bottom;
    final keyboardTop =
        tester.view.physicalSize.height / tester.view.devicePixelRatio -
        tester.view.viewInsets.bottom / tester.view.devicePixelRatio;
    expect(fieldBottom, lessThanOrEqualTo(keyboardTop));
    await tester.ensureVisible(find.text('Continue to Goals'));
    await tester.pump();
    expect(
      tester.getRect(find.text('Continue to Goals')).bottom,
      lessThanOrEqualTo(keyboardTop),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('plan-ready step card displays the selected target', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding();
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final bloc = OnboardingBloc(
      onboardingRepository: _FakeOnboardingRepository(),
    );
    addTearDown(bloc.close);

    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: const MaterialApp(home: PlanReadyPage()),
      ),
    );
    await tester.pump();

    expect(find.text('8,000'), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.pencil), findsOneWidget);
    bloc.add(const OnboardingStepTargetUpdated(12000));
    await tester.pump();

    expect(bloc.state.profile.stepTarget, 12000);
    expect(find.text('12,000'), findsOneWidget);
  });
}
