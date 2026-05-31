// Golden-test configuration — applies only to tests under test/golden/.
//
// The reference PNGs are generated on a developer machine (Windows) while CI
// renders on Linux. Font anti-aliasing differs between platforms, producing
// sub-1% pixel diffs (observed 0.03%–0.73%) that fail exact-match comparison
// even though the widgets are visually identical. This installs a comparator
// that tolerates that platform noise while still catching real visual
// regressions, which are far larger than the threshold.
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

// Max allowed pixel difference. Cross-platform AA noise sits under 1%; a real
// regression (changed colour, layout, text) blows well past this.
const double _kGoldenDiffTolerance = 0.02; // 2%

class _TolerantGoldenComparator extends LocalFileComparator {
  _TolerantGoldenComparator(super.testFile);

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final ComparisonResult result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );

    if (result.passed || result.diffPercent <= _kGoldenDiffTolerance) {
      return true;
    }

    final String error = await generateFailureOutput(result, golden, basedir);
    throw FlutterError(error);
  }
}

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  final LocalFileComparator defaultComparator =
      goldenFileComparator as LocalFileComparator;
  // Preserve the default comparator's basedir (the test directory) so relative
  // golden paths still resolve correctly.
  goldenFileComparator = _TolerantGoldenComparator(
    Uri.parse('${defaultComparator.basedir}test.dart'),
  );
  await testMain();
}
