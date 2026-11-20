abstract class SettingsRepository {
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
