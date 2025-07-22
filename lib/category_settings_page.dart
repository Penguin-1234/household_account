//カテゴリを追加、編集、削除できる設定画面の作成
// lib/category_settings_page.dart

import 'package:flutter/material.dart';
import 'category_service.dart';

class CategorySettingsPage extends StatefulWidget {
  const CategorySettingsPage({super.key});

  @override
  State<CategorySettingsPage> createState() => _CategorySettingsPageState();
}

class _CategorySettingsPageState extends State<CategorySettingsPage> {
  final CategoryService _categoryService = CategoryService();
  List<String> _incomeCategories = [];
  List<String> _expenseCategories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() { _isLoading = true; });
    _incomeCategories = await _categoryService.getIncomeCategories();
    _expenseCategories = await _categoryService.getExpenseCategories();
    setState(() { _isLoading = false; });
  }

  // カテゴリ追加・編集ダイアログ
// CategorySettingsPageの修正されたメソッド

// カテゴリ追加・編集ダイアログ（修正版）
  Future<void> _showCategoryDialog({
    required bool isExpense,
    String? oldCategory,
  }) async {
    final controller = TextEditingController(text: oldCategory);
    final newCategory = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(oldCategory == null ? 'カテゴリの追加' : 'カテゴリの編集'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'カテゴリ名'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                Navigator.pop(context, controller.text);
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );

    if (newCategory != null) {
      try {
        // まずローカルリストを更新
        setState(() {
          final targetList = isExpense ? _expenseCategories : _incomeCategories;
          if (oldCategory != null) {
            // 編集の場合
            final index = targetList.indexOf(oldCategory);
            if (index != -1) targetList[index] = newCategory;
          } else {
            // 追加の場合
            if (!targetList.contains(newCategory)) targetList.add(newCategory);
          }
        });

        // SharedPreferencesに保存
        await (isExpense
            ? _categoryService.saveExpenseCategories(_expenseCategories)
            : _categoryService.saveIncomeCategories(_incomeCategories));

        // 保存後にデータを再読み込みして確実に同期
        await _loadCategories();

        // 成功メッセージを表示
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(oldCategory == null
                  ? '「$newCategory」を追加しました。'
                  : '「$newCategory」に更新しました。'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        // エラーハンドリング
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('エラーが発生しました: $e')),
          );
        }
      }
    }
  }

// カテゴリ削除（修正版）
  Future<void> _deleteCategory({required bool isExpense, required String category}) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('カテゴリの削除'),
        content: Text('「$category」を削除しますか？\nこの操作は元に戻せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('削除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // ローカルリストから削除
        setState(() {
          if (isExpense) {
            _expenseCategories.remove(category);
          } else {
            _incomeCategories.remove(category);
          }
        });

        // SharedPreferencesに保存
        await (isExpense
            ? _categoryService.saveExpenseCategories(_expenseCategories)
            : _categoryService.saveIncomeCategories(_incomeCategories));

        // 保存後にデータを再読み込みして確実に同期
        await _loadCategories();

        // 削除完了メッセージ
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('「$category」を削除しました。'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        // エラーハンドリング
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('エラーが発生しました: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('カテゴリ設定'),
          bottom: const TabBar(
            tabs: [Tab(text: '支出'), Tab(text: '収入')],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
          children: [
            _buildCategoryList(isExpense: true),
            _buildCategoryList(isExpense: false),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryList({required bool isExpense}) {
    final categories = isExpense ? _expenseCategories : _incomeCategories;
    return ListView.separated(
      itemCount: categories.length + 1, // 追加ボタン分+1
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        if (index == categories.length) { // 末尾に追加ボタン
          return ListTile(
            leading: const Icon(Icons.add),
            title: const Text('新規カテゴリを追加'),
            onTap: () => _showCategoryDialog(isExpense: isExpense),
          );
        }
        final category = categories[index];
        return ListTile(
          title: Text(category),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () => _showCategoryDialog(isExpense: isExpense, oldCategory: category),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deleteCategory(isExpense: isExpense, category: category),
              ),
            ],
          ),
        );
      },
    );
  }
}