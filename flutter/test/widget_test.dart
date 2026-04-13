import 'package:flutter_test/flutter_test.dart';

import 'package:food_safe_flutter/main.dart';
import 'package:food_safe_flutter/app/app_controller.dart';

void main() {
  testWidgets('renders food-safe shell navigation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(FoodSafeApp(controller: AppController.preview()));

    expect(find.text('Gemma 4 Food-Safe'), findsWidgets);
    expect(find.text('Control Room'), findsOneWidget);
    expect(
      find.textContaining('Tum endpointleri tek panelden yonet'),
      findsOneWidget,
    );
  });
}
