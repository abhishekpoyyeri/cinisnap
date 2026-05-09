import 'package:flutter_test/flutter_test.dart';
import 'package:cinesnap/main.dart';

void main() {
  testWidgets('CineSnap app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const CineSnapApp());
  });
}
