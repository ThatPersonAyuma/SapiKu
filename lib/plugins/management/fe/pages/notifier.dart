import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sapiku/main.dart';

enum SyncNotifierStatus { syncing, success, error }

class TopSyncState {
  final String title;
  final String? message;
  final SyncNotifierStatus status;
  final int sequence;

  const TopSyncState({
    required this.title,
    this.message,
    required this.status,
    required this.sequence,
  });

  TopSyncState copyWith({
    String? title,
    String? message,
    SyncNotifierStatus? status,
    int? sequence,
  }) {
    return TopSyncState(
      title: title ?? this.title,
      message: message ?? this.message,
      status: status ?? this.status,
      sequence: sequence ?? this.sequence,
    );
  }
}

class TopSyncNotifier {
  static OverlayEntry? _currentEntry;
  static ValueNotifier<TopSyncState>? _stateNotifier;
  static Timer? _dismissTimer;
  static int _latestSequence = 0;

  /// Tampilkan atau perbarui notifier yang sedang aktif.
  /// Jika [autoDismiss] == null, banner tidak otomatis hilang (cocok untuk status `syncing`).
  static void showOrUpdate({
    required String title,
    String? message,
    required SyncNotifierStatus status,
    Duration? autoDismiss = const Duration(seconds: 4),
    VoidCallback? onTap,
    int? eventSequence,
  }) {
    final seq = eventSequence ?? (++_latestSequence);

    // Abaikan event lama jika sudah ada update yang lebih baru
    if (seq < _latestSequence) return;
    _latestSequence = seq;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _dismissTimer?.cancel();
      _dismissTimer = null;

      final nextState = TopSyncState(
        title: title,
        message: message,
        status: status,
        sequence: seq,
      );

      // Jika OverlayEntry sudah ada, cukup perbarui valuenya tanpa insert ulang
      if (_currentEntry != null && _stateNotifier != null) {
        _stateNotifier!.value = nextState;
      } else {
        final overlay = navigatorKey.currentState?.overlay;
        if (overlay == null) return;

        final notifier = ValueNotifier<TopSyncState>(nextState);
        _stateNotifier = notifier;

        final entry = OverlayEntry(
          builder: (context) {
            final topPadding = MediaQuery.of(context).padding.top;

            return Positioned(
              top: topPadding + 12,
              left: 16,
              right: 16,
              child: ValueListenableBuilder<TopSyncState>(
                valueListenable: notifier,
                builder: (context, state, _) {
                  return _SyncBannerCard(
                    state: state,
                    onTap: () {
                      dismiss();
                      onTap?.call();
                    },
                    onClose: dismiss,
                  );
                },
              ),
            );
          },
        );

        _currentEntry = entry;
        overlay.insert(entry);
      }

      // Set timer baru jika autoDismiss diaktifkan (misalnya saat sukses/gagal)
      if (autoDismiss != null) {
        _dismissTimer = Timer(autoDismiss, dismiss);
      }
    });
  }

  /// Helper khusus saat sinkronisasi mulai berjalan
  static int showSyncing({
    String title = 'Menyinkronkan data...',
    String? message = 'Sedang mengirim perubahan ke server',
    VoidCallback? onTap,
  }) {
    final seq = ++_latestSequence;
    showOrUpdate(
      title: title,
      message: message,
      status: SyncNotifierStatus.syncing,
      autoDismiss: null, // Tahan selama proses berlangsung
      onTap: onTap,
      eventSequence: seq,
    );
    return seq;
  }

  /// Helper saat sinkronisasi selesai (sukses atau gagal) sebelum durasi habis
  static void completeSync({
    required bool isSuccess,
    required String title,
    String? message,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onTap,
    int? syncSequence,
  }) {
    // Jika syncSequence diberikan dan sudah ada proses baru setelahnya, abaikan
    if (syncSequence != null && syncSequence < _latestSequence) return;

    showOrUpdate(
      title: title,
      message: message,
      status: isSuccess ? SyncNotifierStatus.success : SyncNotifierStatus.error,
      autoDismiss: duration, // Timer di-reset ke durasi hasil akhir
      onTap: onTap,
      eventSequence: syncSequence ?? _latestSequence,
    );
  }

  static void dismiss() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    _currentEntry?.remove();
    _currentEntry = null;
    _stateNotifier?.dispose();
    _stateNotifier = null;
  }
}

class _SyncBannerCard extends StatelessWidget {
  final TopSyncState state;
  final VoidCallback onTap;
  final VoidCallback onClose;

  const _SyncBannerCard({
    required this.state,
    required this.onTap,
    required this.onClose,
  });

  Color get _backgroundColor {
    switch (state.status) {
      case SyncNotifierStatus.syncing:
        return const Color(0xFF1E293B);
      case SyncNotifierStatus.success:
        return const Color(0xFF15803D);
      case SyncNotifierStatus.error:
        return const Color(0xFFB91C1C);
    }
  }

  Widget _buildLeadingIcon() {
    switch (state.status) {
      case SyncNotifierStatus.syncing:
        return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2.2,
            color: Colors.white,
          ),
        );
      case SyncNotifierStatus.success:
        return const Icon(Icons.check_circle, color: Colors.white, size: 22);
      case SyncNotifierStatus.error:
        return const Icon(Icons.sync_problem, color: Colors.white, size: 22);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(12),
      color: _backgroundColor,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              _buildLeadingIcon(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    if (state.message != null && state.message!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        state.message!,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onClose,
                child: const Icon(
                  Icons.close,
                  color: Colors.white70,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}