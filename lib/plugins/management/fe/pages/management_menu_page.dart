import 'package:flutter/material.dart';
import 'package:sapiku/base_app/fe/widgets/plugin_card.dart';
import 'package:sapiku/core/fe/theme/app_colors.dart';
import 'package:sapiku/core/fe/utils/custom_icons.dart';
import 'package:sapiku/core/fe/widgets/app_background.dart';
import 'package:sapiku/core/fe/widgets/app_bottom_bar.dart';
import 'package:sapiku/core/fe/widgets/app_top_bar.dart';
import 'package:sapiku/plugins/management/be/be_app.dart';
import 'package:sapiku/utils/utils.dart';

class ManagementMenuPage extends StatefulWidget {
  const ManagementMenuPage({super.key});

  @override
  State<ManagementMenuPage> createState() => _ManagementMenuPageState();
}

class _ManagementMenuPageState extends State<ManagementMenuPage> {
  bool _syncing = false;
  bool _hasPendingSync = false;
  bool _passwordVerified = false;

  @override
  void initState() {
    super.initState();
    _checkPendingSync();
  }

  Future<void> _checkPendingSync() async {
    final pending = await SyncEngine.hasPendingChanges();
    if (mounted) {
      setState(() => _hasPendingSync = pending);
    }
  }

  Future<void> _showSyncPasswordDialog() async {
    final verified =
        _passwordVerified || await ManageUtils.isCloudSyncVerified();
    if (!mounted) return;

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => _SyncPasswordDialog(
        initiallyVerified: verified,
        onVerified: () {
          ManageUtils.markCloudSyncVerified();
          if (!mounted) return;
          setState(() => _passwordVerified = true);
          _checkPendingSync();
        },
        onStartSync: _startSync,
      ),
    );
  }

  Future<void> _startSync() async {
    if (_syncing) return;
    setState(() => _syncing = true);

    try {
      final syncSuccess = await SyncEngine.runSync();
      await _checkPendingSync();

      if (mounted) {
        if (syncSuccess && !_hasPendingSync) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data berhasil disinkronkan ke cloud')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sinkronisasi gagal atau sebagian data belum tersinkronisasi')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal sinkronkan: $e')),
        );
      }
    } finally {
      if (mounted) {
        await _checkPendingSync();
        if (mounted) {
          setState(() => _syncing = false);
        }
      }
    }
  }

  Widget _buildPendingSyncCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.brown, width: 1.5),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.brown,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.cloud_off_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Data Pencatatan Belum Tersinkronisasi ke Internet',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Lakukan sinkronisasi dengan menekan tombol sinkronisasi di pojok kanan bawah dan masukkan password',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const SapikuAppBar(title: 'Pencatatan'),
      body: AppBackground(
        child: ListView(
          padding: const EdgeInsets.only(left: 14, right: 14, top: 140),
          children: [
            if (_hasPendingSync) ...[
              _buildPendingSyncCard(),
              const SizedBox(height: 12),
            ],
            PluginCard(
              title: 'Pencatatan Produk',
              subtitle: 'Kelola pencatatan produk',
              route: '/management/pencatatan',
              icon: CustomIcons.fluent_notebook_32_filled,
              subIcon: CustomIcons.game_icons_notebook,
              onTap: (context, route) async {
                await Navigator.pushNamed(context, route);
                await _checkPendingSync();
              },
            ),
            const SizedBox(height: 8),
            PluginCard(
              title: 'Penjualan Produk',
              subtitle: 'Kelola transaksi penjualan produk',
              route: '/management/penjualan',
              icon: CustomIcons.fluent_building_retail_more_32_filled,
              subIcon: CustomIcons.fa7_solid_cash_register,
              onTap: (context, route) async {
                await Navigator.pushNamed(context, route);
                await _checkPendingSync();
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _syncing ? null : _showSyncPasswordDialog,
        backgroundColor: AppColors.darkCard,
        icon: _syncing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : const Icon(Icons.cloud_sync, color: Colors.white),
        label: const Text(
          'Sinkronisasi',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      bottomNavigationBar: const AppBottomBar(),
    );
  }
}

class _SyncPasswordDialog extends StatefulWidget {
  const _SyncPasswordDialog({
    required this.initiallyVerified,
    required this.onVerified,
    required this.onStartSync,
  });

  final bool initiallyVerified;
  final VoidCallback onVerified;
  final Future<void> Function() onStartSync;

  @override
  State<_SyncPasswordDialog> createState() => _SyncPasswordDialogState();
}

class _SyncPasswordDialogState extends State<_SyncPasswordDialog> {
  final TextEditingController _passwordCtrl = TextEditingController();
  bool _checking = false;
  bool _verified = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _verified = widget.initiallyVerified;
  }

  @override
  void dispose() {
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _verifyPassword() async {
    final password = _passwordCtrl.text;
    if (password.isEmpty) {
      setState(() => _error = 'Password tidak boleh kosong');
      return;
    }

    setState(() {
      _checking = true;
      _error = null;
    });

    final hasInternet = await checkInternetConnection();
    if (!mounted) return;
    if (!hasInternet) {
      setState(() {
        _checking = false;
        _error = 'Sinkronisasi gagal, anda tidak terhubung ke internet';
      });
      return;
    }

    await ManageUtils.setCloudSyncPw(password);
    final loginSuccess = await ManageUtils.login();
    if (!mounted) return;
    if (!loginSuccess) {
      setState(() {
        _checking = false;
        _error = 'Sinkronisasi gagal, password yang anda masukkan salah';
      });
      return;
    }

    setState(() {
      _checking = false;
      _verified = true;
      _error = null;
    });
    widget.onVerified();
  }

  void _startSync() {
    Navigator.pop(context);
    widget.onStartSync();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.greenBorder, width: 2),
        ),
        padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Password',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            if (!_verified) ...[
              const Text(
                'Masukkan password di bawah ini',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordCtrl,
                obscureText: true,
                enabled: !_checking,
                decoration: InputDecoration(
                  hintText: 'Password',
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: AppColors.greenBorder,
                      width: 1.4,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: AppColors.greenBorder,
                      width: 1.8,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: AppColors.greenBorder,
                      width: 1.4,
                    ),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.red,
                    height: 1.4,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              Center(
                child: ElevatedButton(
                  onPressed: _checking ? null : _verifyPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkCard,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: _checking
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Submit'),
                ),
              ),
            ] else ...[
              const Text(
                'Tekan tombol di bawah ini untuk memulai sinkronisasi.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              Center(
                child: ElevatedButton(
                  onPressed: _startSync,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkCard,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('Sinkronisasi sekarang'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
