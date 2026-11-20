import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/settings_usecases.dart';

part 'settings_event.dart';
part 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final GetUnitsAndLanguageUseCase getUnitsAndLanguageUseCase;
  final UpdateUnitsUseCase updateUnitsUseCase;
  final UpdateLanguageUseCase updateLanguageUseCase;
  final ExportDataUseCase exportDataUseCase;
  final DeleteAccountUseCase deleteAccountUseCase;
  final CheckPremiumUseCase checkPremiumUseCase;
  final PurchasePlanUseCase purchasePlanUseCase;
  final RestorePurchasesUseCase restorePurchasesUseCase;
  final SyncWidgetsUseCase syncWidgetsUseCase;

  SettingsBloc({
    required this.getUnitsAndLanguageUseCase,
    required this.updateUnitsUseCase,
    required this.updateLanguageUseCase,
    required this.exportDataUseCase,
    required this.deleteAccountUseCase,
    required this.checkPremiumUseCase,
    required this.purchasePlanUseCase,
    required this.restorePurchasesUseCase,
    required this.syncWidgetsUseCase,
  }) : super(const SettingsInitial()) {
    on<LoadSettingsEvent>(_onLoadSettings);
    on<UpdateUnitsEvent>(_onUpdateUnits);
    on<UpdateLanguageEvent>(_onUpdateLanguage);
    on<ExportDataEvent>(_onExportData);
    on<DeleteAccountEvent>(_onDeleteAccount);
    on<PurchasePremiumEvent>(_onPurchasePremium);
    on<RestorePurchasesEvent>(_onRestorePurchases);
    on<SyncWidgetsEvent>(_onSyncWidgets);
  }

  Future<void> _onLoadSettings(
    LoadSettingsEvent event,
    Emitter<SettingsState> emit,
  ) async {
    emit(const SettingsLoading());
    try {
      final unitsAndLang = await getUnitsAndLanguageUseCase();
      final isPrem = await checkPremiumUseCase();

      emit(
        SettingsLoaded(
          units: unitsAndLang['units'] ?? 'metric',
          language: unitsAndLang['language'] ?? 'en',
          isPremium: isPrem,
        ),
      );
    } catch (e) {
      emit(SettingsError(e.toString()));
    }
  }

  Future<void> _onUpdateUnits(
    UpdateUnitsEvent event,
    Emitter<SettingsState> emit,
  ) async {
    final current = state;
    if (current is SettingsLoaded) {
      try {
        await updateUnitsUseCase(event.units);
        emit(current.copyWith(units: event.units));
      } catch (e) {
        emit(SettingsError(e.toString()));
      }
    }
  }

  Future<void> _onUpdateLanguage(
    UpdateLanguageEvent event,
    Emitter<SettingsState> emit,
  ) async {
    final current = state;
    if (current is SettingsLoaded) {
      try {
        await updateLanguageUseCase(event.language);
        emit(current.copyWith(language: event.language));
      } catch (e) {
        emit(SettingsError(e.toString()));
      }
    }
  }

  Future<void> _onExportData(
    ExportDataEvent event,
    Emitter<SettingsState> emit,
  ) async {
    final current = state;
    if (current is SettingsLoaded) {
      try {
        final json = await exportDataUseCase();
        emit(
          current.copyWith(
            exportJson: json,
            message: 'Data exported successfully!',
          ),
        );
      } catch (e) {
        emit(SettingsError(e.toString()));
      }
    }
  }

  Future<void> _onDeleteAccount(
    DeleteAccountEvent event,
    Emitter<SettingsState> emit,
  ) async {
    emit(const SettingsLoading());
    try {
      await deleteAccountUseCase();
      emit(const SettingsLoaded());
    } catch (e) {
      emit(SettingsError(e.toString()));
    }
  }

  Future<void> _onPurchasePremium(
    PurchasePremiumEvent event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      final success = await purchasePlanUseCase(event.planId);
      final current = state;
      if (current is SettingsLoaded) {
        emit(current.copyWith(isPremium: success));
      } else {
        emit(SettingsLoaded(isPremium: success));
      }
    } catch (e) {
      emit(SettingsError(e.toString()));
    }
  }

  Future<void> _onRestorePurchases(
    RestorePurchasesEvent event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      final success = await restorePurchasesUseCase();
      final current = state;
      if (current is SettingsLoaded) {
        emit(current.copyWith(isPremium: success));
      } else {
        emit(SettingsLoaded(isPremium: success));
      }
    } catch (e) {
      emit(SettingsError(e.toString()));
    }
  }

  Future<void> _onSyncWidgets(
    SyncWidgetsEvent event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await syncWidgetsUseCase();
    } catch (e) {
      emit(SettingsError(e.toString()));
    }
  }
}
