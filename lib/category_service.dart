// lib/category_service.dart

import 'package:shared_preferences/shared_preferences.dart';

class CategoryService {
  static const _incomeKey = 'income_categories';
  static const _expenseKey = 'expense_categories';

  // 初回起動時やデータがない場合のデフォルトカテゴリ
  static const List<String> defaultIncomeCategories = ['給料', 'お小遣い', '副業', 'その他'];
  static const List<String> defaultExpenseCategories = [
    '食費', '外食費', '交通費', '日用品', '医療費', '娯楽費', '趣味', '美容費', 'その他'
  ];

  // SharedPreferencesのインスタンスを取得
  Future<SharedPreferences> _getPrefs() async {
    return SharedPreferences.getInstance();
  }

  // 収入カテゴリの取得（修正版）
  Future<List<String>> getIncomeCategories() async {
    final prefs = await _getPrefs();
    // データがなければデフォルト値のコピーを返す
    final storedCategories = prefs.getStringList(_incomeKey);
    if (storedCategories == null) {
      // デフォルトカテゴリの変更可能なコピーを作成
      return List<String>.from(defaultIncomeCategories);
    }
    // 既存データも変更可能なコピーとして返す
    return List<String>.from(storedCategories);
  }

  // 支出カテゴリの取得（修正版）
  Future<List<String>> getExpenseCategories() async {
    final prefs = await _getPrefs();
    final storedCategories = prefs.getStringList(_expenseKey);
    if (storedCategories == null) {
      // デフォルトカテゴリの変更可能なコピーを作成
      return List<String>.from(defaultExpenseCategories);
    }
    // 既存データも変更可能なコピーとして返す
    return List<String>.from(storedCategories);
  }

  // 収入カテゴリの保存
  Future<void> saveIncomeCategories(List<String> categories) async {
    final prefs = await _getPrefs();
    await prefs.setStringList(_incomeKey, categories);
  }

  // 支出カテゴリの保存
  Future<void> saveExpenseCategories(List<String> categories) async {
    final prefs = await _getPrefs();
    await prefs.setStringList(_expenseKey, categories);
  }

  // デバッグ用メソッド（必要に応じて使用）
  Future<void> debugPrintCategories() async {
    final prefs = await _getPrefs();
    print('Income categories in SharedPreferences: ${prefs.getStringList(_incomeKey)}');
    print('Expense categories in SharedPreferences: ${prefs.getStringList(_expenseKey)}');
  }
}