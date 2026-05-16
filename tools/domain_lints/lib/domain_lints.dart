import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

PluginBase createPlugin() => _DomainLintsPlugin();

class _DomainLintsPlugin extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => [
        NoFirebaseInDomain(),
        NoFlutterInDomain(),
      ];
}

bool _isDomainFile(String path) =>
    path.replaceAll(r'\', '/').contains('/domain/');

const _firebasePrefixes = [
  'package:cloud_firestore',
  'package:firebase_auth',
  'package:firebase_storage',
  'package:firebase_core',
  'package:firebase_crashlytics',
  'package:firebase_messaging',
  'package:firebase_remote_config',
  'package:cloud_functions',
];

class NoFirebaseInDomain extends DartLintRule {
  NoFirebaseInDomain() : super(code: _code);

  static const _code = LintCode(
    name: 'no_firebase_in_domain',
    problemMessage: 'Domain layer must not import Firebase packages.',
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    if (!_isDomainFile(resolver.path)) return;
    context.registry.addImportDirective((node) {
      final uri = node.uri.stringValue ?? '';
      if (_firebasePrefixes.any(uri.startsWith)) {
        reporter.reportErrorForNode(_code, node);
      }
    });
  }
}

class NoFlutterInDomain extends DartLintRule {
  NoFlutterInDomain() : super(code: _code);

  static const _code = LintCode(
    name: 'no_flutter_in_domain',
    problemMessage: 'Domain layer must not import Flutter packages.',
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    if (!_isDomainFile(resolver.path)) return;
    context.registry.addImportDirective((node) {
      final uri = node.uri.stringValue ?? '';
      if (uri.startsWith('package:flutter/') || uri == 'flutter') {
        reporter.reportErrorForNode(_code, node);
      }
    });
  }
}
