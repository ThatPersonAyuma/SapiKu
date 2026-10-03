import 'package:flutter/material.dart';
import 'package:sapiku/core/fe/theme/app_colors.dart';

class PluginCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String route;
  final IconData icon;
  final IconData subIcon;
  final VoidCallback? onTap;
  const PluginCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.route,
    required this.icon,
    required this.subIcon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    void handleTap() => onTap != null ? onTap!() : Navigator.pushNamed(context, route);
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: handleTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.only(left: 10, bottom: 10),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: AppColors.darkCard, borderRadius: BorderRadius.circular(10)),
                            child: Icon(icon, size: 26, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                              const SizedBox(height: 2),
                              Text(subtitle, style: const TextStyle(fontSize: 14, color: Colors.black54)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.greyAction,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: const [BoxShadow(color: AppColors.shadowGrey, offset: Offset(0, 10), blurRadius: 0)],
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                    child: Icon(subIcon, size: 38, color: AppColors.darkCard),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
