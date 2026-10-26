import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  double _monthlySalary = 3000.0;
  double _monthlyHours = 160.0;
  bool _isLoading = true;

  bool _useRemainingBalanceMode = false;
  double _remainingBalance = 0.0;

  double get monthlySalary => _monthlySalary;
  double get monthlyHours => _monthlyHours;
  bool get isLoading => _isLoading;

  bool get useRemainingBalanceMode => _useRemainingBalanceMode;
  double get remainingBalance => _remainingBalance;

  double get hourlyWage => _monthlyHours > 0 ? _monthlySalary / _monthlyHours : 0.0;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _monthlySalary = prefs.getDouble('monthlySalary') ?? 3000.0;
      _monthlyHours = prefs.getDouble('monthlyHours') ?? 160.0;
      _useRemainingBalanceMode = prefs.getBool('useRemainingBalanceMode') ?? false;
      _remainingBalance = prefs.getDouble('remainingBalance') ?? 0.0;
    } catch (e) {
      debugPrint('Failed to load settings: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateSettings({required double salary, required double hours}) async {
    _monthlySalary = salary;
    _monthlyHours = hours;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('monthlySalary', salary);
      await prefs.setDouble('monthlyHours', hours);
    } catch (e) {
      debugPrint('Failed to save settings: $e');
    }
  }

  Future<void> setUseRemainingBalanceMode(bool value) async {
    _useRemainingBalanceMode = value;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('useRemainingBalanceMode', value);
    } catch (e) {
      debugPrint('Failed to save calc mode: $e');
    }
  }

  Future<void> setRemainingBalance(double value) async {
    _remainingBalance = value;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('remainingBalance', value);
    } catch (e) {
      debugPrint('Failed to save remaining balance: $e');
    }
  }

  Map<String, int> calculateTimeCost(double price) {
    if (hourlyWage <= 0 || price <= 0) {
      return {'hours': 0, 'minutes': 0};
    }

    final totalHours = price / hourlyWage;
    final totalMinutes = (totalHours * 60).round();
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    return {'hours': hours, 'minutes': minutes};
  }
}
