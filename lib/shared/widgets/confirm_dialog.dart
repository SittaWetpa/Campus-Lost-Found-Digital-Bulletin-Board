import 'package:flutter/material.dart';
import 'package:campus_lost_found/core/theme/app_tokens.dart';

enum ConfirmTone { primary, danger, success }

Future<bool> showConfirmDialog({
  required BuildContext context,
  required String title,
  String? body,
  Widget? bodyWidget,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  ConfirmTone tone = ConfirmTone.primary,
}) async {
  assert(
    body != null || bodyWidget != null,
    'Provide either `body` text or a `bodyWidget`.',
  );
  final result = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (ctx) => _ConfirmDialog(
      title: title,
      body: body,
      bodyWidget: bodyWidget,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      tone: tone,
    ),
  );
  return result == true;
}

class _ConfirmDialog extends StatelessWidget {
  const _ConfirmDialog({
    required this.title,
    required this.body,
    required this.bodyWidget,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.tone,
  });

  final String title;
  final String? body;
  final Widget? bodyWidget;
  final String confirmLabel;
  final String cancelLabel;
  final ConfirmTone tone;

  Color get _confirmBg => switch (tone) {
        ConfirmTone.primary => AppTokens.primary500,
        ConfirmTone.danger => AppTokens.seeker,
        ConfirmTone.success => AppTokens.success,
      };

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTokens.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 4,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.rMd),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTokens.ink900,
                      fontSize: 18,
                    ),
              ),
              const SizedBox(height: 10),
              if (bodyWidget != null)
                bodyWidget!
              else
                Text(
                  body!,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: AppTokens.ink700,
                  ),
                ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: AppTokens.ink700,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      shape: const StadiumBorder(),
                    ),
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(cancelLabel),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: _confirmBg,
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 11),
                        minimumSize: const Size(0, 40),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text(confirmLabel),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
