// Standard flutter_driver bridge for the integration_test package.
// Usage (from repo root):
//   flutter drive \
//     --driver=test_driver/integration_test.dart \
//     --target=integration_test/wbs_3_2_web_smoke_test.dart \
//     -d chrome
import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver();
