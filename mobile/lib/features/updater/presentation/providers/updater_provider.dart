import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/updater_repository.dart';
import '../../domain/download_progress.dart';
import '../../domain/update_check_result.dart';
import '../../domain/updater_exceptions.dart';
import '../../domain/version_manifest.dart';

enum UpdaterStatus {
  idle,
  checking,
  updateAvailable,
  updateRequired,
  downloading,
  verifying,
  installing,
  permissionRequired,
  error,
}

/// State of the updater feature.
class UpdaterState {
  const UpdaterState({
    this.status = UpdaterStatus.idle,
    this.manifest,
    this.downloadProgress,
    this.downloadedFile,
    this.errorMessage,
    this.isCardDismissed = false,
  });

  final UpdaterStatus status;
  final VersionManifest? manifest;
  final DownloadProgress? downloadProgress;
  final File? downloadedFile;
  final String? errorMessage;
  final bool isCardDismissed;

  bool get hasUpdate =>
      status == UpdaterStatus.updateAvailable ||
      status == UpdaterStatus.updateRequired;

  bool get isMandatory => status == UpdaterStatus.updateRequired;

  UpdaterState copyWith({
    UpdaterStatus? status,
    VersionManifest? manifest,
    DownloadProgress? downloadProgress,
    File? downloadedFile,
    String? errorMessage,
    bool? isCardDismissed,
  }) {
    return UpdaterState(
      status: status ?? this.status,
      manifest: manifest ?? this.manifest,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      downloadedFile: downloadedFile ?? this.downloadedFile,
      errorMessage: errorMessage ?? this.errorMessage,
      isCardDismissed: isCardDismissed ?? this.isCardDismissed,
    );
  }
}

/// Controller for updater operations.
class UpdaterNotifier extends StateNotifier<UpdaterState> {
  UpdaterNotifier(this._repository) : super(const UpdaterState()) {
    // Schedule periodic 24-hour check
    _schedulePeriodicCheck();
  }

  final UpdaterRepository _repository;
  Timer? _periodicTimer;
  Completer<void>? _cancelSignal;

  void _schedulePeriodicCheck() {
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(const Duration(hours: 24), (_) {
      checkForUpdate();
    });
  }

  /// Checks for updates immediately. Set [force] to true to bypass 24h cache.
  Future<UpdateCheckResult> checkForUpdate({bool force = false}) async {
    state = state.copyWith(status: UpdaterStatus.checking, errorMessage: null);

    final result = await _repository.checkForUpdate(force: force);

    switch (result.status) {
      case UpdateCheckStatus.updateRequired:
        state = state.copyWith(
          status: UpdaterStatus.updateRequired,
          manifest: result.manifest,
          isCardDismissed: false,
        );
        break;
      case UpdateCheckStatus.updateAvailable:
        state = state.copyWith(
          status: UpdaterStatus.updateAvailable,
          manifest: result.manifest,
          isCardDismissed: false,
        );
        break;
      case UpdateCheckStatus.noUpdate:
      case UpdateCheckStatus.disabled:
        state = state.copyWith(
          status: UpdaterStatus.idle,
          errorMessage: null,
        );
        break;
      case UpdateCheckStatus.error:
        state = state.copyWith(
          status: UpdaterStatus.error,
          errorMessage: result.errorMessage,
        );
        break;
    }

    return result;
  }

  /// Downloads the available APK, verifies integrity, and launches system installer.
  Future<void> startDownloadAndInstall() async {
    final manifest = state.manifest;
    if (manifest == null) return;

    _cancelSignal = Completer<void>();

    state = state.copyWith(
      status: UpdaterStatus.downloading,
      downloadProgress: const DownloadProgress(receivedBytes: 0, totalBytes: 0),
      errorMessage: null,
    );

    try {
      final file = await _repository.downloadApk(
        manifest,
        cancelSignal: _cancelSignal,
        onProgress: (progress) {
          state = state.copyWith(downloadProgress: progress);
        },
      );

      state = state.copyWith(
        status: UpdaterStatus.verifying,
        downloadedFile: file,
      );

      await _repository.verifyAndInstall(file, manifest);

      state = state.copyWith(status: UpdaterStatus.installing);
    } on InstallerPermissionException {
      state = state.copyWith(
        status: UpdaterStatus.permissionRequired,
        errorMessage: 'Please grant permission to install updates in Android Settings.',
      );
    } on UpdaterException catch (e) {
      state = state.copyWith(
        status: UpdaterStatus.error,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        status: UpdaterStatus.error,
        errorMessage: 'An unexpected error occurred during update: $e',
      );
    }
  }

  /// Retries installation after user returns from permission settings.
  Future<void> retryInstall() async {
    final file = state.downloadedFile;
    final manifest = state.manifest;
    if (file == null || manifest == null) {
      await startDownloadAndInstall();
      return;
    }

    try {
      final canInstall = await _repository.canRequestPackageInstalls();
      if (!canInstall) {
        await _repository.requestInstallPermission();
        return;
      }

      state = state.copyWith(status: UpdaterStatus.installing, errorMessage: null);
      await _repository.verifyAndInstall(file, manifest);
    } catch (e) {
      state = state.copyWith(
        status: UpdaterStatus.error,
        errorMessage: 'Installation failed: $e',
      );
    }
  }

  /// Opens the system permission screen to allow unknown app installations.
  Future<void> openPermissionSettings() async {
    await _repository.requestInstallPermission();
  }

  /// Cancels in-progress download.
  void cancelDownload() {
    if (_cancelSignal != null && !_cancelSignal!.isCompleted) {
      _cancelSignal!.complete();
    }
    state = state.copyWith(
      status: state.manifest != null
          ? (state.isMandatory
              ? UpdaterStatus.updateRequired
              : UpdaterStatus.updateAvailable)
          : UpdaterStatus.idle,
      downloadProgress: null,
    );
  }

  /// Dismisses the optional update card for this session.
  void dismissCard() {
    state = state.copyWith(isCardDismissed: true);
  }

  @override
  void dispose() {
    _periodicTimer?.cancel();
    super.dispose();
  }
}

final updaterProvider =
    StateNotifierProvider<UpdaterNotifier, UpdaterState>((ref) {
  final repo = ref.watch(updaterRepositoryProvider);
  return UpdaterNotifier(repo);
});
