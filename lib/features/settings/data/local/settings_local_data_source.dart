import 'dart:convert';
import 'package:bloomi/core/database/app_database.dart';
import 'package:bloomi/core/localization/app_languages.dart';
import 'package:bloomi/core/localization/app_localizations.dart';
import 'package:bloomi/features/auth/domain/repositories/auth_repository.dart';
import 'package:bloomi/services/billing/billing_service.dart';
import 'package:bloomi/services/widgets/widget_bridge_service.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class SettingsLocalDataSource {
  Future<Map<String, String>> getUnitsAndLanguage();
  Future<void> updateUnits(String units);
  Future<void> updateLanguage(String language);
  Future<String> exportDataJson();
  Future<void> deleteAccountAndData();
  Future<bool> isPremium();
  Future<bool> purchasePlan(String planId);
  Future<bool> restorePurchases();
  Future<void> syncWidgets();
}

class SettingsLocalDataSourceImpl implements SettingsLocalDataSource {
  final AppDatabase _db;
  final WidgetBridgeService _widgetBridgeService;
  final BillingService? _billingService;
  final AuthRepository? _authRepository;
  final String Function()? _userIdProvider;
  final SharedPreferences? _prefs;

  SettingsLocalDataSourceImpl({
    required AppDatabase db,
    required WidgetBridgeService widgetBridgeService,
    BillingService? billingService,
    AuthRepository? authRepository,
    String Function()? userIdProvider,
    SharedPreferences? prefs,
  }) : _db = db,
       _widgetBridgeService = widgetBridgeService,
       _billingService = billingService,
       _authRepository = authRepository,
       _userIdProvider = userIdProvider,
       _prefs = prefs;

  String get _currentUserId =>
      _userIdProvider?.call() ??
      _authRepository?.currentUserId ??
      'default_user';

  @override
  Future<Map<String, String>> getUnitsAndLanguage() async {
    final savedLang = _prefs?.getString('selected_language_code');
    final savedUnits = _prefs?.getString('selected_units');

    final profiles =
        await (_db.select(_db.userProfiles)
              ..where(
                (t) =>
                    t.userId.equals(_currentUserId) & t.deleted.equals(false),
              )
              ..limit(1))
            .get();

    final String units =
        savedUnits ?? (profiles.isNotEmpty ? profiles.first.units : 'metric');
    String language;

    if (savedLang != null && savedLang.isNotEmpty) {
      language = savedLang;
    } else if (profiles.isNotEmpty && profiles.first.language.isNotEmpty) {
      language = profiles.first.language;
    } else {
      // Default to device language if supported, otherwise English
      final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;
      final devCode = deviceLocale.languageCode.toLowerCase();
      final hasMatch = AppLanguage.supportedLanguages.any(
        (l) => l.code.toLowerCase() == devCode,
      );
      language = hasMatch ? devCode : 'en';
    }

    try {
      BloomiLocalizations.applySafeIntlLocale(language);
    } catch (_) {}

    return {'units': units, 'language': language};
  }

  @override
  Future<void> updateUnits(String units) async {
    await _prefs?.setString('selected_units', units);
    final profiles =
        await (_db.select(_db.userProfiles)
              ..where(
                (t) =>
                    t.userId.equals(_currentUserId) & t.deleted.equals(false),
              )
              ..limit(1))
            .get();
    if (profiles.isNotEmpty) {
      await (_db.update(
        _db.userProfiles,
      )..where((p) => p.id.equals(profiles.first.id))).write(
        UserProfilesCompanion(
          units: drift.Value(units),
          isDirty: const drift.Value(true),
          updatedAt: drift.Value(DateTime.now()),
        ),
      );
    }
  }

  @override
  Future<void> updateLanguage(String language) async {
    await _prefs?.setString('selected_language_code', language);
    try {
      BloomiLocalizations.applySafeIntlLocale(language);
    } catch (_) {}

    final profiles =
        await (_db.select(_db.userProfiles)
              ..where(
                (t) =>
                    t.userId.equals(_currentUserId) & t.deleted.equals(false),
              )
              ..limit(1))
            .get();
    if (profiles.isNotEmpty) {
      await (_db.update(
        _db.userProfiles,
      )..where((p) => p.id.equals(profiles.first.id))).write(
        UserProfilesCompanion(
          language: drift.Value(language),
          isDirty: const drift.Value(true),
          updatedAt: drift.Value(DateTime.now()),
        ),
      );
    }
  }

  @override
  Future<String> exportDataJson() async {
    final profile =
        await (_db.select(_db.userProfiles)..where(
              (t) => t.userId.equals(_currentUserId) & t.deleted.equals(false),
            ))
            .get();
    final targets =
        await (_db.select(_db.targets)..where(
              (t) => t.userId.equals(_currentUserId) & t.deleted.equals(false),
            ))
            .get();
    final meals =
        await (_db.select(_db.mealLogs)..where(
              (t) => t.userId.equals(_currentUserId) & t.deleted.equals(false),
            ))
            .get();
    final water =
        await (_db.select(_db.waterLogs)..where(
              (t) => t.userId.equals(_currentUserId) & t.deleted.equals(false),
            ))
            .get();
    final body =
        await (_db.select(_db.bodyEntries)..where(
              (t) => t.userId.equals(_currentUserId) & t.deleted.equals(false),
            ))
            .get();
    final workouts =
        await (_db.select(_db.workoutLogs)..where(
              (t) => t.userId.equals(_currentUserId) & t.deleted.equals(false),
            ))
            .get();

    return jsonEncode({
      'exportDate': DateTime.now().toIso8601String(),
      'profile': profile.map((p) => p.name).toList(),
      'targetsCount': targets.length,
      'mealLogsCount': meals.length,
      'waterLogsCount': water.length,
      'bodyEntriesCount': body.length,
      'workoutLogsCount': workouts.length,
    });
  }

  @override
  Future<void> deleteAccountAndData() async {
    // 1. Clear current user's local database records
    await _db.clearUserScopedDataForUser(_currentUserId);

    // 2. Clear SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('bloomi_cached_user_session');
    await prefs.remove('bloomi_has_completed_onboarding');
    await prefs.remove('bloomi_last_logged_in_user_id');
  }

  @override
  Future<bool> isPremium() async {
    if (_billingService != null) {
      return await _billingService.isPremium();
    }
    final prefs = await SharedPreferences.getInstance();
    final isExplicitlyUnlocked =
        prefs.getBool('is_bloomi_premium_unlocked') ?? false;
    if (isExplicitlyUnlocked) return true;

    int? firstInstallMs = prefs.getInt('bloomi_first_install_timestamp');
    if (firstInstallMs == null) {
      firstInstallMs = DateTime.now().millisecondsSinceEpoch;
      await prefs.setInt('bloomi_first_install_timestamp', firstInstallMs);
    }
    final firstInstallDate = DateTime.fromMillisecondsSinceEpoch(
      firstInstallMs,
    );
    return DateTime.now().difference(firstInstallDate).inDays < 7;
  }

  @override
  Future<bool> purchasePlan(String planId) async {
    if (_billingService != null) {
      return await _billingService.buyPlanById(planId);
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_bloomi_premium_unlocked', true);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> restorePurchases() async {
    if (_billingService != null) {
      return await _billingService.restorePurchases();
    }
    return true;
  }

  @override
  Future<void> syncWidgets() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final targetRow =
        await (_db.select(_db.targets)
              ..where((t) => t.deleted.equals(false))
              ..orderBy([(t) => drift.OrderingTerm.desc(t.updatedAt)])
              ..limit(1))
            .getSingleOrNull();

    final targetCalories = targetRow?.calories ?? 2000.0;
    final targetWater = targetRow?.waterMl.toInt() ?? 2200;
    final targetSteps = targetRow?.steps ?? 10000;

    final todayMeals =
        await (_db.select(_db.mealLogs)..where(
              (t) =>
                  t.date.isBiggerOrEqualValue(startOfDay) &
                  t.date.isSmallerOrEqualValue(endOfDay) &
                  t.deleted.equals(false),
            ))
            .get();

    double consumedCalories = 0.0;
    for (final m in todayMeals) {
      try {
        final decoded =
            jsonDecode(m.computedNutrientsSnapshot) as Map<String, dynamic>;
        consumedCalories += (decoded['calories'] as num?)?.toDouble() ?? 0.0;
      } catch (_) {}
    }

    final remainingCalories = (targetCalories - consumedCalories).clamp(
      0.0,
      targetCalories,
    );

    final todayWaterLogs =
        await (_db.select(_db.waterLogs)..where(
              (t) =>
                  t.date.isBiggerOrEqualValue(startOfDay) &
                  t.date.isSmallerOrEqualValue(endOfDay) &
                  t.deleted.equals(false),
            ))
            .get();
    final waterLogged = todayWaterLogs.fold<int>(0, (sum, w) => sum + w.ml);

    final payload = WidgetSyncPayload(
      remainingCalories: remainingCalories,
      targetCalories: targetCalories,
      waterLoggedMl: waterLogged,
      targetWaterMl: targetWater,
      steps: 0,
      targetSteps: targetSteps,
      streakCount: 0,
      lastUpdated: now,
    );
    await _widgetBridgeService.updateWidgets(payload);
  }
}
