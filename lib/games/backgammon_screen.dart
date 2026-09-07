import 'dart:math';
import 'package:flutter/material.dart';

class BackgammonGameScreen extends StatefulWidget {
  const BackgammonGameScreen({Key? key}) : super(key: key);

  @override
  State<BackgammonGameScreen> createState() => _BackgammonGameScreenState();
}

class _BackgammonGameScreenState extends State<BackgammonGameScreen> {
  // وضعیت ۲۴ خانه تخته نرد (تعداد مهره و رنگ: مثبت برای سفید، منفی برای سیاه)
  // خانه‌ها از دید بازیکن سفید از ۱ تا ۲۴ شماره‌گذاری می‌شوند.
  final List<int> _board = List.filled(24, 0);

  // تاس‌ها
  int? _dice1;
  int? _dice2;
  bool _isWhiteTurn = true; // نوبت بازیکن سفید
  String _gameMessage = "برای شروع تاس بریزید";

  @override
  void initState() {
    super.initState();
    _initializeBoard();
  }

  // چیدمان اولیه استاندارد تخته نرد
  void _initializeBoard() {
    // سفید
    _board[0] = 2;   // خانه 1
    _board[11] = 5;  // خانه 12
    _board[16] = 3;  // خانه 17
    _board[18] = 5;  // خانه 19

    // سیاه (با مقادیر منفی)
    _board[23] = -2; // خانه 24
    _board[12] = -5; // خانه 13
    _board[7] = -3;  // خانه 8
    _board[5] = -5;  // خانه 6

    setState(() {
      _gameMessage = "بازی شروع شد. نوبت بازیکن سفید است.";
    });
  }

  // تابع پرتاب تاس
  void _rollDice() {
    final random = Random();
    setState(() {
      _dice1 = random.nextInt(6) + 1;
      _dice2 = random.nextInt(6) + 1;
      
      // اگر تاس‌ها جفت باشند، 4 حرکت داریم (در منطق کامل پیاده می‌شود)
      if (_dice1 == _dice2) {
        _gameMessage = "تاس جفت آمد! ($_dice1 - $_dice1). چهار حرکت دارید.";
      } else {
        _gameMessage = "تاس‌ها: $_dice1 و $_dice2. نوبت ${_isWhiteTurn ? 'سفید' : 'سیاه'}.";
      }
    });
  }

  // تعویض نوبت
  void _endTurn() {
    setState(() {
      _isWhiteTurn = !_isWhiteTurn;
      _dice1 = null;
      _dice2 = null;
      _gameMessage = "نوبت تغییر کرد. نوبت ${_isWhiteTurn ? 'سفید' : 'سیاه'} است.";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3E2723), // پس‌زمینه چوبی تیره
      appBar: AppBar(
        title: const Text('تخته نرد - نامیرا'),
        backgroundColor: const Color(0xFF5D4037),
      ),
      body: Column(
        children: [
          // بخش بالایی صفحه (اطلاعات بازی و تاس‌ها)
          Container(
            padding: const EdgeInsets.all(16.0),
            color: const Color(0xFF4E342E),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _gameMessage,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                Row(
                  children: [
                    if (_dice1 != null && _dice2 != null) ...[
                      Chip(label: Text('$_dice1')),
                      const SizedBox(width: 8),
                      Chip(label: Text('$_dice2')),
                    ],
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: (_dice1 == null) ? _rollDice : _endTurn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber[800],
                      ),
                      child: Text(_dice1 == null ? 'تاس بریز' : 'پایان نوبت'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // بدنه اصلی تخته (شمای گرافیکی دو بخش بالا و پایین)
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFD7CCC8),
                border: Border.all(color: const Color(0xFF271C19), width: 4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  // سمت چپ تخته (خانه‌های ۱۲ تا ۱۷ و ۱۸ تا ۲۳)
                  Expanded(
                    flex: 5,
                    child: Column(
                      children: [
                        _buildBoardHalf(11, 16, true), // بالای چپ
                        const Divider(height: 20, thickness: 8, color: Color(0xFF5D4037)),
                        _buildBoardHalf(17, 22, false), // پایین چپ
                      ],
                    ),
                  ),

                  // بار وسط تخته (Bar)
                  Container(
                    width: 30,
                    color: const Color(0xFF5D4037),
                    child: const Center(
                      child: RotatedBox(
                        quarterTurns: 3,
                        child: Text(
                          'NAMIRA BAR',
                          style: TextStyle(color: Colors.white70, fontSize: 10, letterSpacing: 2),
                        ),
                      ),
                    ),
                  ),

                  // سمت راست تخته (خانه‌های ۶ تا ۱۱ و ۰ تا ۵)
                  Expanded(
                    flex: 5,
                    child: Column(
                      children: [
                        _buildBoardHalf(5, 10, true), // بالای راست
                        const Divider(height: 20, thickness: 8, color: Color(0xFF5D4037)),
                        _buildBoardHalf(0, 4, false), // پایین راست
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ویجت کمکی برای ساختن نیمه‌ای از خانه‌های تخته
  Widget _buildBoardHalf(int startIndex, int endIndex, bool isTop) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate((endIndex - startIndex) + 1, (index) {
          int actualIndex = isTop ? (endIndex - index) : (startIndex + index);
          int checkersCount = _board[actualIndex];

          return Expanded(
            child: GestureDetector(
              onTap: () {
                // کلیک روی خانه برای انتخاب و حرکت مهره
                setState(() {
                  _gameMessage = "انتخاب خانه ${actualIndex + 1} (مهره‌ها: $checkersCount)";
                });
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: actualIndex % 2 == 0 ? const Color(0xFFBCAAA4) : const Color(0xFF8D6E63),
                ),
                child: Column(
                  mainAxisAlignment: isTop ? MainAxisAlignment.start : MainAxisAlignment.end,
                  children: [
                    Text(
                      '${actualIndex + 1}',
                      style: const TextStyle(fontSize: 10, color: Colors.black54),
                    ),
                    const SizedBox(height: 4),
                    // نمایش مهره‌ها به صورت دایره‌ای
                    if (checkersCount != 0)
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: checkersCount > 0 ? Colors.white : Colors.black87,
                          border: Border.all(color: Colors.grey, width: 1),
                        ),
                        child: Text(
                          '${checkersCount.abs()}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: checkersCount > 0 ? Colors.black : Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
