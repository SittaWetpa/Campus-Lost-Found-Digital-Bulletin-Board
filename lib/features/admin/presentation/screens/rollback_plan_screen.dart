import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:campus_lost_found/core/services/feature_flag_service.dart';

const _kAmber  = Color(0xFFD98A0E);
const _kBg     = Color(0xFFFBF7EC);
const _kBorder = Color(0xFFE6DDC4);
const _kInk500 = Color(0xFF7A6F5B);
const _kInk600 = Color(0xFF5A4F3D);
const _kInk700 = Color(0xFF40372A);
const _kInk900 = Color(0xFF1B1610);
const _kSurface = Colors.white;

class RollbackPlanScreen extends ConsumerStatefulWidget {
  const RollbackPlanScreen({super.key});

  @override
  ConsumerState<RollbackPlanScreen> createState() => _RollbackPlanScreenState();
}

class _RollbackPlanScreenState extends ConsumerState<RollbackPlanScreen> {
  final Set<String> _checked = {};

  static const _whenToInvoke = [
    'Unexpected bugs in the claim-request flow traced to secret-question logic',
    'Evidence of fraudulent abuse patterns exploiting the question field',
    'Legal or privacy escalation requiring immediate feature removal',
    'Critical performance regression caused by additional Firestore reads',
  ];

  static const _steps = [
    _RollbackStep(
      n: 1,
      title: 'Open Firebase Console',
      body: 'Navigate to console.firebase.google.com → select the project → Remote Config.',
    ),
    _RollbackStep(
      n: 2,
      title: 'Locate the parameter',
      body: 'Find secret_question_enabled in the parameter list. Click the pencil (Edit) icon.',
    ),
    _RollbackStep(
      n: 3,
      title: 'Set value to false',
      body: 'Change the default value from true → false. Leave any condition overrides unchanged.',
    ),
    _RollbackStep(
      n: 4,
      title: 'Publish',
      body: 'Click Save then Publish changes. Confirm in the dialog.',
    ),
    _RollbackStep(
      n: 5,
      title: 'Force-fetch on a test device',
      body: 'In a debug build set minFetchInterval = 0, cold-restart, and verify the flag reads false.',
    ),
  ];

  static const _checklist = [
    _ChecklistItem(
      key: 'cold_restart',
      label: 'Cold-restart the app — launches without crash; Remote Config fetched',
    ),
    _ChecklistItem(
      key: 'sq_section_hidden',
      label: 'Post Form → Founder Post: SECRET QUESTION section is not visible',
    ),
    _ChecklistItem(
      key: 'no_answer_field',
      label: 'Claim Request form on a Founder Post: no secret-answer field appears',
    ),
    _ChecklistItem(
      key: 'no_verification',
      label: 'Request Detail (Poster view): no Verification section shown',
    ),
    _ChecklistItem(
      key: 'crashlytics_clean',
      label: 'Crashlytics shows no new fatal errors for 15 min post-rollback',
    ),
  ];

  static const _contacts = [
    _Contact(
      role: 'Tech Lead',
      handle: '@team-lead',
      note: 'Primary point of contact',
    ),
    _Contact(
      role: 'Firebase Console',
      handle: 'console.firebase.google.com',
      note: 'Remote Config UI',
    ),
    _Contact(
      role: 'Crashlytics',
      handle: 'console.firebase.google.com → Crashlytics',
      note: 'Error monitoring',
    ),
  ];

  void _toggle(String key) {
    setState(() {
      if (_checked.contains(key)) {
        _checked.remove(key);
      } else {
        _checked.add(key);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final flagOn = ref.watch(featureFlagsProvider).secretQuestionEnabled;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5EDE0),
        elevation: 0,
        leading: const BackButton(),
        title: const Text(
          'Rollback Plan',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _kInk900),
        ),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _StatusBanner(flagOn: flagOn),
          const SizedBox(height: 18),

          const _SectionHeading(label: 'WHEN TO INVOKE THIS PLAN'),
          _Card(
            child: Column(
              children: [
                for (var i = 0; i < _whenToInvoke.length; i++) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 1, right: 8),
                          child: Text(
                            '!',
                            style: TextStyle(
                              color: _kAmber,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            _whenToInvoke[i],
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.5,
                              color: _kInk700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (i < _whenToInvoke.length - 1)
                    const Divider(height: 1, color: _kBorder),
                ],
              ],
            ),
          ),

          const SizedBox(height: 18),
          const _SectionHeading(label: 'ROLLBACK PROCEDURE'),
          ..._steps.map((s) => _StepCard(step: s)),

          const SizedBox(height: 18),
          const _SectionHeading(label: 'PROPAGATION TIME'),
          _Card(
            child: Column(
              children: const [
                _PropagationRow(
                  label: 'Production',
                  value: '≤ 1 hour',
                  note: 'Default min fetch interval',
                ),
                Divider(height: 1, color: _kBorder),
                _PropagationRow(
                  label: 'Debug build',
                  value: '~0 seconds',
                  note: 'minFetchInterval = 0; cold-restart required',
                ),
                Divider(height: 1, color: _kBorder),
                _PropagationRow(
                  label: 'Force-fetch (prod)',
                  value: '~0 seconds',
                  note: 'Call fetchAndActivate() programmatically from debug menu',
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),
          const _SectionHeading(label: 'POST-ROLLBACK VERIFICATION'),
          _Card(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              children: [
                for (var i = 0; i < _checklist.length; i++) ...[
                  _ChecklistRow(
                    item: _checklist[i],
                    checked: _checked.contains(_checklist[i].key),
                    onToggle: () => _toggle(_checklist[i].key),
                  ),
                  if (i < _checklist.length - 1)
                    const Divider(height: 1, color: _kBorder),
                ],
              ],
            ),
          ),

          const SizedBox(height: 18),
          const _SectionHeading(label: 'ON-CALL CONTACTS'),
          _Card(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < _contacts.length; i++) ...[
                  _ContactRow(contact: _contacts[i]),
                  if (i < _contacts.length - 1)
                    const Divider(height: 1, color: _kBorder),
                ],
              ],
            ),
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ── Models ─────────────────────────────────────────────────────────────────

class _RollbackStep {
  final int n;
  final String title;
  final String body;
  const _RollbackStep({required this.n, required this.title, required this.body});
}

class _ChecklistItem {
  final String key;
  final String label;
  const _ChecklistItem({required this.key, required this.label});
}

class _Contact {
  final String role;
  final String handle;
  final String note;
  const _Contact({required this.role, required this.handle, required this.note});
}

// ── Sub-components ─────────────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  final bool flagOn;
  const _StatusBanner({required this.flagOn});

  @override
  Widget build(BuildContext context) {
    final bg = flagOn ? const Color(0xFFEDF8F0) : const Color(0xFFFFF4DC);
    final border = flagOn ? const Color(0xFFA3D9B1) : const Color(0xFFE0AA40);
    final dot = flagOn ? const Color(0xFF2F7D3E) : const Color(0xFFC07A00);
    final headlineColor = flagOn ? const Color(0xFF1F5C2E) : const Color(0xFF7A4E00);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  flagOn
                      ? 'Feature currently ENABLED'
                      : 'Feature currently DISABLED — rollback applied',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: headlineColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text.rich(TextSpan(
                  children: [
                    const TextSpan(
                      text: 'secret_question_enabled = ',
                      style: TextStyle(fontSize: 12, color: _kInk600),
                    ),
                    TextSpan(
                      text: flagOn ? 'true' : 'false',
                      style: GoogleFonts.robotoMono(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _kInk900,
                      ),
                    ),
                  ],
                )),
              ],
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

class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  const _Card({required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kSurface,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}

class _StepCard extends StatelessWidget {
  final _RollbackStep step;
  const _StepCard({required this.step});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _kSurface,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: const BoxDecoration(
              color: _kAmber,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '${step.n}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                    color: _kInk900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  step.body,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: _kInk600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PropagationRow extends StatelessWidget {
  final String label;
  final String value;
  final String note;
  const _PropagationRow({required this.label, required this.value, required this.note});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: _kInk900,
                  ),
                ),
                Text(
                  note,
                  style: const TextStyle(fontSize: 11.5, color: _kInk500),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: _kAmber,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  final _ChecklistItem item;
  final bool checked;
  final VoidCallback onToggle;
  const _ChecklistRow({
    required this.item,
    required this.checked,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: checked ? _kAmber : Colors.transparent,
                border: Border.all(
                  color: checked ? _kAmber : _kBorder,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: checked
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.label,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: checked ? _kInk500 : _kInk900,
                  decoration: checked
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final _Contact contact;
  const _ContactRow({required this.contact});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.role,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: _kInk900,
                  ),
                ),
                Text(
                  contact.note,
                  style: const TextStyle(fontSize: 11.5, color: _kInk500),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: Text(
              contact.handle,
              textAlign: TextAlign.right,
              style: GoogleFonts.robotoMono(
                fontSize: 12,
                color: _kInk700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
