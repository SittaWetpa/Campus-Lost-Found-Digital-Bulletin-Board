class FeatureFlags {
  final bool secretQuestionEnabled;
  final bool sensitiveItemEnabled;
  final String securityOfficeContact;
  final List<String> sensitiveCategories;

  const FeatureFlags({
    required this.secretQuestionEnabled,
    required this.sensitiveItemEnabled,
    required this.securityOfficeContact,
    required this.sensitiveCategories,
  });

  // Applied when Remote Config has never been fetched or the network is
  // unavailable at cold-start.
  static const FeatureFlags defaults = FeatureFlags(
    secretQuestionEnabled: true,
    sensitiveItemEnabled: true,
    securityOfficeContact: '02-470-9999',
    sensitiveCategories: ['credit_card', 'id_card', 'passport', 'key', 'document'],
  );

  FeatureFlags copyWith({
    bool? secretQuestionEnabled,
    bool? sensitiveItemEnabled,
    String? securityOfficeContact,
    List<String>? sensitiveCategories,
  }) =>
      FeatureFlags(
        secretQuestionEnabled:
            secretQuestionEnabled ?? this.secretQuestionEnabled,
        sensitiveItemEnabled:
            sensitiveItemEnabled ?? this.sensitiveItemEnabled,
        securityOfficeContact:
            securityOfficeContact ?? this.securityOfficeContact,
        sensitiveCategories: sensitiveCategories ?? this.sensitiveCategories,
      );
}
