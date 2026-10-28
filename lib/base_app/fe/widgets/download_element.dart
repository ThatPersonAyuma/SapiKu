import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:sapiku/core/fe/theme/app_colors.dart';
import 'package:sapiku/utils/db/local_handler.dart';
import 'package:sapiku/utils/utils.dart';

typedef PluginCallback = void Function(BuildContext, String);

class DownloadCard extends StatefulWidget {
  final String title;
  final String name;
  final String subtitle;
  final IconData icon;
  final Future<bool> Function(VoidCallback) downloadCallback;
  final Future<void> Function() removeCallback;
  Plugin? plugin;
  DownloadCard({
    super.key,
    required this.title,
    required this.name,
    required this.subtitle,
    required this.icon,
    required this.downloadCallback,
    required this.removeCallback,
    this.plugin,
  });

  @override
  State<DownloadCard> createState() => _DownloadCard();
}

class _DownloadCard extends State<DownloadCard> {
  bool get isSetup => widget.plugin != null && widget.plugin!.isSetup;
  bool _isDownloading = false;
  int maxProgress = 8;
  int currentProgress = 0;
  double percentProgress = 0.0;
  void downloadProgress() {
    if (currentProgress == 0) {
      setState(() {
        _isDownloading = true;
      });
    }
    setState(() {
      currentProgress += 1;
      percentProgress = currentProgress / maxProgress;
    });
  }

  Future<void> downloadPlugin() async {
    setState(() {
      currentProgress = 0;
    });
    final downloadSuccess = await widget.downloadCallback(downloadProgress);
    setState(() {
      currentProgress = maxProgress;
    });
    if (!downloadSuccess) {
      setState(() {
        _isDownloading = false;
      });
      return;
    }
    final res = await Plugin.getFromByName(widget.name);
    setState(() {
      widget.plugin = res;
      _isDownloading = false;
    });
    if (mounted) {
      await PopUpMessage.showDownloadSuccessMessage(widget.title, context);
    }
  }

  Future<void> delete() async {
    final decision = await PopUpMessage.showYesNoMessage(
      "Anda akan menghapus plugin Pencatatan beserta datanya. Apakah anda yakin ingin menghapus plugin ini?",
    );
    if (!decision) return;
    await widget.removeCallback();
    final plugData = await Plugin.getFromByName(widget.name);
    setState(() {
      widget.plugin = plugData;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
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
                          decoration: BoxDecoration(
                            color: AppColors.darkCard,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            widget.icon,
                            size: 26,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.subtitle,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 2),
                            isSetup
                                ? ElevatedButton(
                                    onPressed: () {},
                                    style: ElevatedButton.styleFrom(
                                      shape: StadiumBorder(),
                                      foregroundColor: Colors.black,
                                      backgroundColor: Colors.green,
                                    ),
                                    child: const Text("Terunduh"),
                                  )
                                : ElevatedButton(
                                    onPressed: _isDownloading
                                        ? () {}
                                        : downloadPlugin,
                                    style: ElevatedButton.styleFrom(
                                      shape: StadiumBorder(),
                                      foregroundColor: Colors.black,
                                    ),
                                    child: _isDownloading
                                        ? const Text("Mengunduh")
                                        : const Text("Unduh"),
                                  ),
                          ],
                        ),
                      ),
                      if (isSetup)
                        Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(Icons.check, color: Colors.green, size: 50),
                            IconButton(
                              onPressed: delete,
                              icon: Icon(
                                Icons.delete,
                                size: 50,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      if (_isDownloading) const SizedBox(width: 16),
                      if (_isDownloading)
                        CircularPercentIndicator(
                          radius: 60.0,
                          lineWidth: 10.0,
                          percent: percentProgress,
                          center: Icon(
                            Icons.download,
                            size: 35.0,
                            color: Colors.green,
                          ),
                          backgroundColor: Colors.lightGreenAccent,
                          progressColor: Colors.green,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
            ],
          ),
        ),
      ),
    );
  }
}
