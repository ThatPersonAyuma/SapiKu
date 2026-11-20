import 'package:flutter/material.dart';
import 'package:sapiku/base_app/fe/widgets/plugin_card.dart';
import 'package:sapiku/core/fe/theme/app_colors.dart';
import 'package:sapiku/core/fe/utils/custom_icons.dart';
import 'package:sapiku/core/fe/widgets/app_background.dart';
import 'package:sapiku/core/fe/widgets/app_bottom_bar.dart';
import 'package:sapiku/core/fe/widgets/app_top_bar.dart';
import 'package:sapiku/plugins/management/be/be_app.dart';

class ManagementMenuPage extends StatefulWidget {
  const ManagementMenuPage({super.key});

  @override
  State<ManagementMenuPage> createState() => _ManagementMenuPageState();
}

class _ManagementMenuPageState extends State<ManagementMenuPage> {
  bool _syncing = false;
  bool _hasPendingSync = false;

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

  void _showSyncPasswordDialog() {
    final passwordCtrl = TextEditingController();

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
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
                  const Text(
                    'Masukkan password di bawah ini',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordCtrl,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'Password',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.greenBorder, width: 1.4),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.greenBorder, width: 1.8),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.greenBorder, width: 1.4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: ElevatedButton(
                      onPressed: () async {
                        final password = passwordCtrl.text;
                        if (password.isEmpty) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(content: Text('Password tidak boleh kosong')),
                          );
                          return;
                        }

                        Navigator.pop(ctx);
                        setState(() => _syncing = true);

                        try {
                          await ManageUtils.setCloudSyncPw(password);
                          final loginSuccess = await ManageUtils.login();
                          final syncSuccess = loginSuccess
                              ? await SyncEngine.runSync()
                              : false;
                          await _checkPendingSync();

                          if (mounted) {
                            if (!loginSuccess) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Password salah atau gagal sinkronkan')),
                              );
                            } else if (syncSuccess && !_hasPendingSync) {
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
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.darkCard,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      child: const Text('Submit'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
            : const Icon(Icons.lock_rounded, color: Colors.white),
        label: const Text(
          'Sinkronisasi',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      bottomNavigationBar: const AppBottomBar(),
    );
  }
}
