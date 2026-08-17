import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/models/savings_goal_model.dart';

class SavingsGoalService extends ChangeNotifier {
  static final SavingsGoalService _instance = SavingsGoalService._internal();
  factory SavingsGoalService() => _instance;
  SavingsGoalService._internal();

  final List<SavingsGoalModel> _goals = [];

  List<SavingsGoalModel> get goals => List.unmodifiable(_goals);

  Future<void> initialize() async {
    await _loadGoals();
  }

  Future<void> _loadGoals() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? data = prefs.getString('user_gold_savings_goals');
      if (data != null) {
        final List<dynamic> list = jsonDecode(data);
        _goals.clear();
        _goals.addAll(list.map((e) => SavingsGoalModel.fromJson(e)));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading gold savings goals: $e');
    }
  }

  Future<void> _saveGoals() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String data = jsonEncode(_goals.map((e) => e.toJson()).toList());
      await prefs.setString('user_gold_savings_goals', data);
    } catch (e) {
      debugPrint('Error saving gold savings goals: $e');
    }
  }

  Future<void> addGoal(SavingsGoalModel goal) async {
    _goals.add(goal);
    await _saveGoals();
    notifyListeners();
  }

  Future<void> removeGoal(String id) async {
    _goals.removeWhere((g) => g.id == id);
    await _saveGoals();
    notifyListeners();
  }

  Future<void> addContribution(String id, double gramsToAdd) async {
    final index = _goals.indexWhere((g) => g.id == id);
    if (index != -1) {
      final updatedGrams = _goals[index].currentGrams + gramsToAdd;
      _goals[index] = _goals[index].copyWith(currentGrams: updatedGrams);
      await _saveGoals();
      notifyListeners();
    }
  }
}
