import '../../data/local/settings_store.dart';
import '../models/daily_spend.dart';

class DailySpendService {
  DailySpendService(this._store);

  final SettingsStore _store;

  List<DailySpend> load() => _store.loadDailySpends();

  int amountFor(DateTime date) {
    for (final spend in load()) {
      if (_sameDay(spend.date, date)) return spend.amount;
    }
    return 0;
  }

  Future<List<DailySpend>> add(DateTime date, int amount) {
    if (amount <= 0) throw ArgumentError.value(amount, 'amount');
    return update(date, amountFor(date) + amount);
  }

  Future<List<DailySpend>> update(DateTime date, int amount) async {
    if (amount < 0) throw ArgumentError.value(amount, 'amount');
    final values = [...load()];
    final index = values.indexWhere((item) => _sameDay(item.date, date));
    if (amount == 0) {
      if (index >= 0) values.removeAt(index);
    } else {
      final updated = DailySpend(
        date: DateTime(date.year, date.month, date.day),
        amount: amount,
        updatedAt: DateTime.now(),
      );
      if (index < 0) {
        values.add(updated);
      } else {
        values[index] = updated;
      }
    }
    await _store.saveDailySpends(values);
    return values;
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
