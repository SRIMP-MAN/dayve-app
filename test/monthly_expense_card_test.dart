import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haru_app/presentation/monthly_expense_card.dart';

void main() {
  testWidgets('monthly expense card shows usage without daily allowance',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MonthlyExpenseCard(
            monthlyBudget: 1000000,
            monthlySpent: 435200,
            monthlyRemaining: 564800,
            usageRatio: .4352,
            remainingDays: 15,
            onSpendTap: () {},
            onDetailsTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('이번 달 소비 현황'), findsOneWidget);
    expect(find.text('이번 달 44% 사용 중'), findsOneWidget);
    expect(find.text('435,200원'), findsOneWidget);
    final amount = tester.widget<Text>(find.text('435,200원'));
    expect(amount.style?.fontSize, 34);
    expect(amount.style?.fontWeight, FontWeight.w700);
    expect(find.text('오늘 써도 되는 돈'), findsNothing);
    expect(find.byKey(const Key('monthly_expense_progress')), findsOneWidget);
    expect(find.byKey(const Key('dayve_pixel_cat')), findsNothing);
    expect(find.byKey(const Key('open_spend_sheet')), findsOneWidget);
  });
}
