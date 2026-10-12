import 'package:flutter/material.dart';
import 'package:sapiku/core/fe/theme/app_colors.dart';

class PenjualanFabMenu extends StatefulWidget {
  final VoidCallback? onTambah;
  final VoidCallback? onLaporan;
  const PenjualanFabMenu({super.key, this.onTambah, this.onLaporan});

  @override
  State<PenjualanFabMenu> createState() => _PenjualanFabMenuState();
}

class _PenjualanFabMenuState extends State<PenjualanFabMenu> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _expand;
  late final Animation<double> _fade;
  late final Animation<double> _rotate;
  bool _open = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 260));
    _expand = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut, reverseCurve: Curves.easeIn);
    _rotate = Tween<double>(begin: 0, end: 0.25).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _open = !_open);
    if (_open) {
      _ctrl.forward();
    } else {
      _ctrl.reverse();
    }
  }

  void _close() {
    if (!_open) return;
    setState(() => _open = false);
    _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (_open)
          Positioned.fill(
            child: GestureDetector(
              onTap: _close,
              behavior: HitTestBehavior.translucent,
              child: const SizedBox.expand(),
            ),
          ),
        Positioned(
          right: 16,
          bottom: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildAction(
                label: 'Tambah Penjualan',
                icon: Icons.add_rounded,
                index: 1,
                onTap: () {
                  _close();
                  widget.onTambah?.call();
                },
              ),
              const SizedBox(height: 10),
              _buildAction(
                label: 'Laporan Penjualan',
                icon: Icons.receipt_long_rounded,
                index: 0,
                onTap: () {
                  _close();
                  widget.onLaporan?.call();
                },
              ),
              const SizedBox(height: 12),
              _buildMainFab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAction({required String label, required IconData icon, required int index, required VoidCallback onTap}) {
    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.85, end: 1).animate(_expand),
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(_expand),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.darkCard,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 3))],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 24, color: Colors.white),
                    const SizedBox(width: 10),
                    Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainFab() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _toggle,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            color: AppColors.darkCard,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: RotationTransition(
            turns: _rotate,
            child: Icon(_open ? Icons.close_rounded : Icons.menu_rounded, color: Colors.white, size: 34),
          ),
        ),
      ),
    );
  }
}
