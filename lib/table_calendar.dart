import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'category_service.dart';
import 'category_settings_page.dart';

class CalendarPage extends StatefulWidget {
  final Map<DateTime, Map<String, List<Map<String, dynamic>>>> entries;
  final Function(Map<DateTime, Map<String, List<Map<String, dynamic>>>>) onUpdateEntries;

  const CalendarPage({
    super.key,
    required this.entries,
    required this.onUpdateEntries,
  });

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> with TickerProviderStateMixin {
  DateTime _focusedDay = DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  DateTime _currentDay = DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day);

  final formatter = NumberFormat("#,###");
  final CategoryService _categoryService = CategoryService();
  List<String> _incomeCategories = [];
  List<String> _expenseCategories = [];

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _loadCategories();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final incomeCategories = await _categoryService.getIncomeCategories();
      final expenseCategories = await _categoryService.getExpenseCategories();

      if (mounted) {
        setState(() {
          _incomeCategories = incomeCategories;
          _expenseCategories = expenseCategories;
        });
      }
    } catch (e) {
      print('Error loading categories: $e');
    }
  }

  Future<void> _navigateToSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CategorySettingsPage()),
    );

    await _loadCategories();

    if (mounted) {
      setState(() {});
    }
  }

  // 特定の日の支出総額を取得
  int _getDayExpenseTotal(DateTime day) {
    final date = DateTime.utc(day.year, day.month, day.day);
    final expenses = widget.entries[date]?['支出'] ?? [];
    return expenses.fold(0, (sum, e) => sum + (e['amount'] as int));
  }

  // 月の最大支出額を取得（グラデーションの基準値として使用）
  int _getMaxMonthlyExpense() {
    int maxExpense = 1000; // 最小基準値

    widget.entries.forEach((date, types) {
      if (date.year == _focusedDay.year && date.month == _focusedDay.month) {
        final expenses = types['支出'] ?? [];
        final dayExpense = expenses.fold(0, (sum, e) => sum + (e['amount'] as int));
        if (dayExpense > maxExpense) {
          maxExpense = dayExpense;
        }
      }
    });

    return maxExpense;
  }

  // 支出額に応じた色を取得
  Color _getExpenseColor(DateTime day) {
    final dayExpense = _getDayExpenseTotal(day);
    if (dayExpense == 0) {
      return Colors.transparent; // 支出がない場合は透明
    }

    final maxExpense = _getMaxMonthlyExpense();
    final ratio = (dayExpense / maxExpense).clamp(0.0, 1.0);

    // グラデーション色を計算（薄いピンクから濃い赤へ）
    return Color.lerp(
      const Color(0xFFFFE4E1), // 薄いピンク
      const Color(0xFFDC143C), // 濃い赤
      ratio,
    ) ?? Colors.transparent;
  }

// このメソッドをまるごと置き換えてください
  @override
  Widget build(BuildContext context) {
    final summary = _getMonthlySummary();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFD2B48C),
        title: const Text(
          'お小遣い帳',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: TextButton.icon(
              onPressed: _navigateToSettings,
              icon: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.category_outlined, color: Colors.white, size: 18),
              ),
              label: const Text(
                'カテゴリ設定',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
      // 【変更点】body全体をSingleChildScrollViewでラップ
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView( // <--- 1. ここを追加
            child: Column(             // <--- 2. Expandedが不要になり、すべてがこのColumnの子になる
              children: [
                // カレンダーコンテナ
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: TableCalendar(
                      // ... (TableCalendarのプロパティは変更なし)
                      locale: 'ja_JP',
                      firstDay: DateTime.utc(2010, 1, 1),
                      lastDay: DateTime.utc(2030, 12, 31),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (day) => isSameDay(_currentDay, day),
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _currentDay = selectedDay;
                          _focusedDay = focusedDay;
                        });
                      },
                      headerStyle: HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                        titleTextStyle: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8B4513),
                        ),
                        leftChevronIcon: Icon(
                          Icons.chevron_left,
                          color: const Color(0xFF8B4513),
                        ),
                        rightChevronIcon: Icon(
                          Icons.chevron_right,
                          color: const Color(0xFF8B4513),
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5DC).withOpacity(0.3),
                        ),
                        headerPadding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      calendarStyle: CalendarStyle(
                        outsideDaysVisible: true,
                        weekendTextStyle: const TextStyle(color: Color(0xFF8B4513)),
                        holidayTextStyle: const TextStyle(color: Colors.red),
                        defaultTextStyle: const TextStyle(
                          color: Color(0xFF2C2C2C),
                          fontWeight: FontWeight.w500,
                        ),
                        todayDecoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.green.shade300, Colors.green.shade600],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                        selectedDecoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.orange.shade300, Colors.orange.shade600],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                        markerDecoration: const BoxDecoration(
                          color: Colors.blueAccent,
                          shape: BoxShape.circle,
                        ),
                        cellMargin: const EdgeInsets.all(4),
                      ),
                      calendarBuilders: CalendarBuilders(
                        defaultBuilder: (context, day, focusedDay) {
                          return _buildCalendarCell(day, false, false);
                        },
                        todayBuilder: (context, day, focusedDay) {
                          return _buildCalendarCell(day, true, false);
                        },
                        selectedBuilder: (context, day, focusedDay) {
                          return _buildCalendarCell(day, false, true);
                        },
                        outsideBuilder: (context, day, focusedDay) {
                          return _buildCalendarCell(day, false, false, isOutside: true);
                        },
                      ),
                      onPageChanged: (focusedDay) {
                        setState(() {
                          _focusedDay = focusedDay;
                        });
                      },
                    ),
                  ),
                ),

                // 凡例
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: _buildLegend(),
                ),

                // 月次サマリーカード
                _buildMonthlySummaryCard(summary),

                const SizedBox(height: 16),

                // 【変更点】Expandedを削除し、ListViewをColumnに変更
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20), // 全体を丸くする
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 5), // 影を調整
                      ),
                    ],
                  ),
                  // ListViewの代わりにPaddingとColumnを使用
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column( // <--- 3. ListViewをColumnに変更
                      children: [
                        _buildEntryList('収入'),
                        const SizedBox(height: 16),
                        _buildEntryList('支出'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16), // スクロールした際の下部の余白
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        // ... (bottomNavigationBarは変更なし)
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade400, Colors.blue.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () => _showEntryDialog(type: '収入'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    '収入を追加',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red.shade400, Colors.red.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () => _showEntryDialog(type: '支出'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.remove, color: Colors.white),
                  label: const Text(
                    '支出を追加',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  //【新規ウィジェット】コンパクトな月次サマリーカード
  Widget _buildMonthlySummaryCard(Map<String, int> summary) {
    final balance = summary['balance'] ?? 0;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFD2B48C),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildCompactSummaryItem('収入', summary['income'] ?? 0, Colors.blue.shade600),
          _buildCompactSummaryItem('支出', summary['expense'] ?? 0, Colors.red.shade600),
          _buildCompactSummaryItem('残高', balance, balance >= 0 ? Colors.green.shade600 : Colors.red.shade600),
        ],
      ),
    );
  }
  //【新規ウィジェット】コンパクトなサマリーの各項目
  Widget _buildCompactSummaryItem(String label, int amount, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${formatter.format(amount)}円',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }


  // カスタムカレンダーセルビルダー
  Widget _buildCalendarCell(DateTime day, bool isToday, bool isSelected, {bool isOutside = false}) {
    final expenseColor = _getExpenseColor(day);
    final hasExpense = _getDayExpenseTotal(day) > 0;

    Color textColor = isOutside ? Colors.grey.shade400 : const Color(0xFF2C2C2C);

    Widget child = Container(
      margin: const EdgeInsets.all(2.0),
      decoration: BoxDecoration(
        color: isSelected
            ? null
            : isToday
            ? null
            : hasExpense
            ? expenseColor
            : Colors.transparent,
        gradient: isSelected
            ? LinearGradient(
          colors: [Colors.orange.shade300, Colors.orange.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
            : isToday
            ? LinearGradient(
          colors: [Colors.green.shade300, Colors.green.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
            : null,
        shape: BoxShape.circle,
        boxShadow: (isSelected || isToday) ? [
          BoxShadow(
            color: (isSelected ? Colors.orange : Colors.green).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ] : null,
      ),
      child: Center(
        child: Text(
          '${day.day}',
          style: TextStyle(
            color: (isSelected || isToday) ? Colors.white : textColor,
            fontWeight: (isSelected || isToday) ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: child,
    );
  }

  // 凡例ウィジェット
  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          '支出額 (少)',
          style: TextStyle(fontSize: 12, color: Color(0xFF8B4513)),
        ),
        const SizedBox(width: 8),
        Container(
          width: 100,
          height: 10,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFE4E1), Color(0xFFDC143C)],
            ),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          '(多)',
          style: TextStyle(fontSize: 12, color: Color(0xFF8B4513)),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _getEntriesForDay(DateTime day, String type) {
    final date = DateTime.utc(day.year, day.month, day.day);
    return widget.entries[date]?[type] ?? [];
  }

  //【変更点】日次リストのUIを改善
  Widget _buildEntryList(String type) {
    final entries = _getEntriesForDay(_currentDay, type);
    final total = entries.fold(0, (sum, e) => sum + (e['amount'] as int));
    final isIncome = type == '収入';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isIncome ? Colors.blue.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isIncome ? Colors.blue : Colors.red).shade100,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isIncome ? Icons.arrow_circle_up_outlined : Icons.arrow_circle_down_outlined,
                    color: isIncome ? Colors.blue.shade600 : Colors.red.shade600,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '$type一覧',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isIncome ? Colors.blue.shade800 : Colors.red.shade800,
                    ),
                  ),
                ],
              ),
              Text(
                '合計: ${formatter.format(total)}円',
                style: TextStyle(
                  color: isIncome ? Colors.blue.shade700 : Colors.red.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          Divider(
            height: 24,
            thickness: 1,
            color: (isIncome ? Colors.blue : Colors.red).shade100,
          ),
          if (entries.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              alignment: Alignment.center,
              child: Text(
                '${type}データがありません',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            )
          else
            ...entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getCategoryIcon(entry['category']),
                      size: 22,
                      color: isIncome ? Colors.blue.shade600 : Colors.red.shade600,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      entry['category'],
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ),
                  Text(
                    '${formatter.format(entry['amount'])}円',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isIncome ? Colors.blue.shade800 : Colors.red.shade800,
                    ),
                  ),
                ],
              ),
            )),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case '食費':
        return Icons.restaurant;
      case '外食費':
        return Icons.local_dining;
      case '交通費':
        return Icons.directions_bus;
      case '日用品':
        return Icons.shopping_cart;
      case '医療費':
        return Icons.local_hospital;
      case '娯楽費':
        return Icons.videogame_asset;
      case '趣味':
        return Icons.palette;
      case '美容費':
        return Icons.spa;
      case 'その他':
        return Icons.category;
      case '給料':
        return Icons.work;
      case 'お小遣い':
        return Icons.monetization_on;
      case '副業':
        return Icons.laptop;
      default:
        return Icons.category;
    }
  }

  Map<String, int> _getMonthlySummary() {
    int income = 0;
    int expense = 0;

    widget.entries.forEach((date, types) {
      if (date.year == _focusedDay.year && date.month == _focusedDay.month) {
        final incomeList = types['収入'] ?? [];
        final expenseList = types['支出'] ?? [];
        income += incomeList.fold(0, (sum, e) => sum + (e['amount'] as int));
        expense += expenseList.fold(0, (sum, e) => sum + (e['amount'] as int));
      }
    });
    return {
      'income': income,
      'expense': expense,
      'balance': income - expense,
    };
  }

  Future<void> _showEntryDialog({required String type}) async {
    final controller = TextEditingController();
    final categories = type == '支出' ? _expenseCategories : _incomeCategories;
    if (categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${type}カテゴリが登録されていません。設定画面から追加してください。'),
          backgroundColor: Colors.orange.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }
    String selectedCategory = categories.first;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text('${type}の追加'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  items: categories
                      .map((category) => DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedCategory = value;
                      });
                    }
                  },
                  decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16)
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: '金額',
                    prefixIcon: Icon(Icons.currency_yen, color: Colors.grey.shade600),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('キャンセル'),
              ),
              ElevatedButton(
                onPressed: () {
                  final amount = int.tryParse(controller.text.replaceAll(',', ''));
                  if (amount != null && amount > 0) {
                    Navigator.pop(context, {
                      'category': selectedCategory,
                      'amount': amount,
                    });
                  } else {
                    // 金額が不正な場合のエラー表示
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('有効な金額を入力してください。'), backgroundColor: Colors.red),
                    );
                  }
                },
                child: const Text('追加'),
              ),
            ],
          ),
        );
      },
    );

    if (result != null) {
      final newEntries = Map<DateTime, Map<String, List<Map<String, dynamic>>>>.from(widget.entries);
      final date = DateTime.utc(_currentDay.year, _currentDay.month, _currentDay.day);
      newEntries[date] ??= {'収入': [], '支出': []};
      newEntries[date]![type]!.add(result);
      widget.onUpdateEntries(newEntries);
    }
  }
}