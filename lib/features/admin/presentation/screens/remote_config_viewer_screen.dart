import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:campus_lost_found/core/services/feature_flag_service.dart';

const _kAmber  = Color(0xFFD98A0E);
const _kBg     = Color(0xFFFBF7EC);
const _kBorder = Color(0xFFE6DDC4);
const _kInk400 = Color(0xFFA39580);
const _kInk500 = Color(0xFF7A6F5B);
const _kInk700 = Color(0xFF40372A);
const _kInk900 = Color(0xFF1B1610);
const _kSurface = Colors.white;

const _kFirebaseConsoleUrl =
    'https://console.firebase.google.com/project/_/config';

class RemoteConfigViewerScreen extends ConsumerStatefulWidget {
  const RemoteConfigViewerScreen({super.key});

  @override
  ConsumerState<RemoteConfigViewerScreen> createState() =>
      _RemoteConfigViewerScreenState();
}

class _RemoteConfigViewerScreenState
    extends ConsumerState<RemoteConfigViewerScreen> {
  bool _fetching = false;

  Future<void> _fetchAndActivate() async {
    if (_fetching) return;
    setState(() => _fetching = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(featureFlagsProvider).fetchAndActivate();
      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(
        content: Text('Remote Config fetched & activated'),
      ));
    } finally {
      if (mounted) setState(() => _fetching = false);
    }
  }

  Future<void> _copyConsoleUrl() async {
    await Clipboard.setData(const ClipboardData(text: _kFirebaseConsoleUrl));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Firebase Console URL copied to clipboard'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(featureFlagsProvider);
    final flags = service.currentFlags;
    final lastFetch = service.lastFetchTime;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5EDE0),
        elevation: 0,
        leading: const BackButton(),
        title: const Text(
          'Remote Config',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _kInk900),
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: _fetching ? null : _fetchAndActivate,
              child: Text(
                _fetching ? 'Fetching…' : 'Fetch & activate',
                style: const TextStyle(
                  color: _kAmber,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _LastFetchedBanner(lastFetch: lastFetch),
          const SizedBox(height: 18),

          const _SectionHeading(label: 'FEATURE FLAGS'),
          _FlagCard(
            keyName: 'secret_question_enabled',
            type: 'Boolean',
            description:
                'Gates WBS 2.10 Secret Question — disabling hides all secret-question UI and skips visitorAnswer on claim submission.',
            valueLabel: flags.secretQuestionEnabled ? 'TRUE' : 'FALSE',
            valueOn: flags.secretQuestionEnabled,
          ),
          _FlagCard(
            keyName: 'sensitive_item_enabled',
            type: 'Boolean',
            description:
                'Gates the Sensitive Item selector on the Post Form (WBS 2.14).',
            valueLabel: flags.sensitiveItemEnabled ? 'TRUE' : 'FALSE',
            valueOn: flags.sensitiveItemEnabled,
          ),

          const SizedBox(height: 18),
          const _SectionHeading(label: 'CONFIGURATION VALUES'),
          _FlagCard(
            keyName: 'security_office_contact',
            type: 'String',
            description:
                'Phone number shown on sensitive-item posts and the Security Office contact button (WBS 2.14).',
            valueLabel: '"${flags.securityOfficeContact}"',
            valueOn: null,
          ),
          _FlagCard(
            keyName: 'sensitive_categories',
            type: 'String[]',
            description:
                'Item categories that trigger the sensitive-item flow (WBS 2.14). Managed remotely so categories can be added without a release.',
            valueLabel: null,
            valueOn: null,
            children: [
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: flags.sensitiveCategories
                    .map((c) => _CategoryChip(label: c))
                    .toList(),
              ),
            ],
          ),

          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _copyConsoleUrl,
            icon: const Icon(Icons.content_copy, size: 16),
            label: const Text('Copy Firebase Console URL'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _kInk700,
              side: const BorderSide(color: _kBorder),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'This screen is read-only. To change a value, paste the URL into '
              'your browser, sign in to the Firebase Console, and edit Remote '
              'Config there.',
              style: TextStyle(fontSize: 12, color: _kInk500, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sub-components ─────────────────────────────────────────────────────────

class _LastFetchedBanner extends StatelessWidget {
  final DateTime lastFetch;
  const _LastFetchedBanner({required this.lastFetch});

  @override
  Widget build(BuildContext context) {
    final everFetched = lastFetch.millisecondsSinceEpoch > 0;
    final label = everFetched
        ? 'Config active · last fetched ${_relativeTime(lastFetch)}'
        : 'Config not yet fetched · using in-app defaults';
    final dotColor = everFetched ? const Color(0xFF2F7D3E) : _kInk400;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _kSurface,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 12.5, color: _kInk500),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final String label;
  const _SectionHeading({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
          color: _kInk500,
        ),
      ),
    );
  }
}

class _FlagCard extends StatelessWidget {
  final String keyName;
  final String type;
  final String description;
  final String? valueLabel;
  final bool? valueOn;
  final List<Widget> children;

  const _FlagCard({
    required this.keyName,
    required this.type,
    required this.description,
    required this.valueLabel,
    required this.valueOn,
    this.children = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _kSurface,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Text(
                      keyName,
                      style: GoogleFonts.robotoMono(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: _kInk900,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFE7D2),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        type,
                        style: const TextStyle(
                          fontSize: 11,
                          color: _kInk500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (valueLabel != null) _ValueBadge(label: valueLabel!, on: valueOn),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.45,
              color: _kInk500,
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _ValueBadge extends StatelessWidget {
  final String label;
  final bool? on;
  const _ValueBadge({required this.label, required this.on});

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    if (on == true) {
      bg = const Color(0xFFE5F4E9);
      fg = const Color(0xFF1F5C2E);
    } else if (on == false) {
      bg = const Color(0xFFF6E5E2);
      fg = const Color(0xFF8C2A1B);
    } else {
      bg = const Color(0xFFEFE7D2);
      fg = _kInk700;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.robotoMono(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  const _CategoryChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4DC),
        border: Border.all(color: const Color(0xFFE0AA40)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11.5,
          color: Color(0xFF7A4E00),
        ),
      ),
    );
  }
}

String _relativeTime(DateTime t) {
  final diff = DateTime.now().difference(t);
  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} h ago';
  return '${diff.inDays} d ago';
}
