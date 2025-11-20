import 'dart:typed_data';

import 'package:evide_stop_announcer_app/core/app_imports.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';

class InstalledAppWidget extends StatefulWidget {
  const InstalledAppWidget({
    super.key,
    required this.app,
    required this.appIcon,
  });

  final AppInfo app;
  final Uint8List? appIcon;

  @override
  State<InstalledAppWidget> createState() => _InstalledAppWidgetState();
}

class _InstalledAppWidgetState extends State<InstalledAppWidget> {
  bool isFocused = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        print("Pacakage name: ${widget.app.packageName}");
        await InstalledApps.startApp(widget.app.packageName);
      },
      child: FocusableActionDetector(
        autofocus: false,
        onShowFocusHighlight: (focused) {
          setState(() {
            isFocused = focused;
          });
        },
        onFocusChange: (focused) {
          setState(() {
            isFocused = focused;
          });
        },
        actions: {
          ActivateIntent: CallbackAction<Intent>(
            onInvoke: (intent) async {
              return null;
            },
          )
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isFocused ? Colors.blue : Colors.transparent,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: widget.appIcon != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(
                        12,
                      ),
                      child: Image.memory(
                        widget.appIcon!, // first argument
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stackTrace) {
                              return const Icon(
                                Icons.broken_image,
                                size: 40,
                                color: Colors.white70,
                              );
                            },
                      ),
                    )
                  : const Icon(
                      Icons.apps,
                      color: Colors.white70,
                      size: 35,
                    ),
            ),
            const SizedBox(height: 5),
            Text(
              widget.app.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}