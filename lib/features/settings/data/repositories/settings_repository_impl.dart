import '../../domain/repositories/settings_repository.dart';
import '../local/settings_local_data_source.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsLocalDataSource localDataSource;

  SettingsRepositoryImpl({required this.localDataSource});

  @override
  Future<Map<String, String>> getUnitsAndLanguage() =>
      localDataSource.getUnitsAndLanguage();

  @override
  Future<void> updateUnits(String units) => localDataSource.updateUnits(units);

  @override
  Future<void> updateLanguage(String language) =>
      localDataSource.updateLanguage(language);

  @override
  Future<String> exportDataJson() => localDataSource.exportDataJson();

  @override
  Future<void> deleteAccountAndData() => localDataSource.deleteAccountAndData();

  @override
  Future<bool> isPremium() => localDataSource.isPremium();

  @override
  Future<bool> purchasePlan(String planId) =>
      localDataSource.purchasePlan(planId);

  @override
  Future<bool> restorePurchases() => localDataSource.restorePurchases();

  @override
  Future<void> syncWidgets() => localDataSource.syncWidgets();
}
