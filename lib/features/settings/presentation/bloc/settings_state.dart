part of 'settings_bloc.dart';

abstract class SettingsState extends Equatable {
  const SettingsState();

  @override
  List<Object?> get props => [];
}

class SettingsInitial extends SettingsState {
  const SettingsInitial();
}

class SettingsLoading extends SettingsState {
  const SettingsLoading();
}

class SettingsLoaded extends SettingsState {
  final String units;
  final String language;
  final bool isPremium;
  final bool isSyncing;
  final bool? syncSuccess;
  final String? exportJson;
  final String? message;

  const SettingsLoaded({
    this.units = 'metric',
    this.language = 'en',
    this.isPremium = false,
    this.isSyncing = false,
    this.syncSuccess,
    this.exportJson,
    this.message,
  });

  SettingsLoaded copyWith({
    String? units,
    String? language,
    bool? isPremium,
    bool? isSyncing,
    bool? syncSuccess,
    String? exportJson,
    String? message,
  }) {
    return SettingsLoaded(
      units: units ?? this.units,
      language: language ?? this.language,
      isPremium: isPremium ?? this.isPremium,
      isSyncing: isSyncing ?? this.isSyncing,
      syncSuccess: syncSuccess ?? this.syncSuccess,
      exportJson: exportJson ?? this.exportJson,
      message: message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [
    units,
    language,
    isPremium,
    isSyncing,
    syncSuccess,
    exportJson,
    message,
  ];
}

class SettingsError extends SettingsState {
  final String message;

  const SettingsError(this.message);

  @override
  List<Object?> get props => [message];
}
