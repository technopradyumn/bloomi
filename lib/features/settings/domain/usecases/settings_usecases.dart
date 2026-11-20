import '../repositories/settings_repository.dart';

class GetUnitsAndLanguageUseCase {
  final SettingsRepository repository;
  GetUnitsAndLanguageUseCase(this.repository);

  Future<Map<String, String>> call() => repository.getUnitsAndLanguage();
}

class UpdateUnitsUseCase {
  final SettingsRepository repository;
  UpdateUnitsUseCase(this.repository);

  Future<void> call(String units) => repository.updateUnits(units);
}

class UpdateLanguageUseCase {
  final SettingsRepository repository;
  UpdateLanguageUseCase(this.repository);

  Future<void> call(String language) => repository.updateLanguage(language);
}

class ExportDataUseCase {
  final SettingsRepository repository;
  ExportDataUseCase(this.repository);

  Future<String> call() => repository.exportDataJson();
}

class DeleteAccountUseCase {
  final SettingsRepository repository;
  DeleteAccountUseCase(this.repository);

  Future<void> call() => repository.deleteAccountAndData();
}

class CheckPremiumUseCase {
  final SettingsRepository repository;
  CheckPremiumUseCase(this.repository);

  Future<bool> call() => repository.isPremium();
}

class PurchasePlanUseCase {
  final SettingsRepository repository;
  PurchasePlanUseCase(this.repository);

  Future<bool> call(String planId) => repository.purchasePlan(planId);
}

class RestorePurchasesUseCase {
  final SettingsRepository repository;
  RestorePurchasesUseCase(this.repository);

  Future<bool> call() => repository.restorePurchases();
}

class SyncWidgetsUseCase {
  final SettingsRepository repository;
  SyncWidgetsUseCase(this.repository);

  Future<void> call() => repository.syncWidgets();
}
