import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tally_khata/main.dart';

void main() {
  testWidgets('ট্যালি খাতা লোড হচ্ছে', (WidgetTester tester) async {
    await tester.pumpWidget(const TallyKhataApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}