import 'package:flutter_test/flutter_test.dart';
import 'package:haru_app/data/local/settings_store.dart';
import 'package:haru_app/domain/services/daily_spend_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('updating a daily spend replaces its amount', () async {
    final preferences = await SharedPreferences.getInstance();
    final service = DailySpendService(SettingsStore(preferences));
    final date = DateTime(2026, 9, 12);

    await service.add(date, 12000);
    final spends = await service.update(date, 8500);

    expect(spends, hasLength(1));
    expect(spends.single.amount, 8500);
    expect(service.amountFor(date), 8500);
  });
}
