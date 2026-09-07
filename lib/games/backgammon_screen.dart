import 'dart:math';
import 'package:flutter/material.dart';

class BackgammonGameScreen extends StatefulWidget {
  const BackgammonGameScreen({Key? key}) : super(key: key);

  @override
  State<BackgammonGameScreen> createState() => _BackgammonGameScreenState();
}

class _BackgammonGameScreenState extends State<BackgammonGameScreen> {
  // وضعیت ۲۴ خانه تخته نرد (تعداد مهره و رنگ: مثبت برای سفید، منفی برای سیاه)
  // خانه‌ها از دید بازیکن سفید از 0 تا 23 (نمایش ۱ تا ۲۴) شماره‌گذاری می‌شوند.
  final List<int> _board = List.filled(24, 0);

  // تاس‌ها و باقی‌مانده‌ی تاس‌های قابل استفاده در این نوبت
  int? _dice1;
  int? _dice2;
  List<int> _availableDice = [];
  
  bool _isWhiteTurn = true; // نوبت بازیکن سفید (true مخفف سفید، false مخفف سیاه)
  int? _selectedSourceIndex; // خانه‌ای که بازیکن برای حرکت مهره انتخاب کرده است
  String _gameMessage = "برای شروع تاس بریزید";

  @override
  void initState() {
    super.initState();
    _initializeBoard();
  }

  // چیدمان اولیه استاندارد تخته نرد
  void _initializeBoard() {
    // پاکسازی کامل تخته
    _board.fillRange(0, 24, 0);

    // سفید (با اعداد مثبت)
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
      _isWhiteTurn = true;
      _dice1 = null;
      _dice2 = null;
      _availableDice.clear();
      _selectedSourceIndex = null;
      _gameMessage = "بازی شروع شد. نوبت بازیکن سفید است. تاس بریزید.";
    });
  }

  // تابع پرتاب تاس
  void _rollDice() {
    final random = Random();
    setState(() {
      _dice1 = random.nextInt(6) + 1;
      _dice2 = random.nextInt(6) + 1;
      
      _availableDice = [_dice1!, _dice2!];
      // اگر تاس‌ها جفت باشند، 4 حرکت مشابه داریم
      if (_dice1 == _dice2) {
        _availableDice.add(_dice1!);
        _availableDice.add(_dice1!);
        _gameMessage = "تاس جفت آمد! ($_dice1 - $_dice1). ۴ حرکت دارید. مهره‌ای را انتخاب کنید.";
      } else {
        _gameMessage = "تاس‌ها: $_dice1 و $_dice2. نوبت ${_isWhiteTurn ? 'سفید' : 'سیاه'}. مهره‌ای را انتخاب کنید.";
      }
      _selectedSourceIndex = null;
    });
  }

  // مدیریت کلیک روی خانه‌های تخته برای حرکت مهره‌ها
  void _onBoardSquareTap(int actualIndex) {
    // اگر هنوز تاس نریخته‌اند، اجازه حرکت نیست
    if (_availableDice.isEmpty) {
      setState(() {
        _gameMessage = "ابتدا باید تاس بریزید!";
      });
      return;
    }

    setState(() {
      // حالت اول: هنوز مهره‌ای برای حرکت انتخاب نکرده‌ایم
      if (_selectedSourceIndex == null) {
        int checker = _board[actualIndex];
        // بررسی اینکه آیا بازیکن روی مهره‌ی خودش کلیک کرده است یا خیر
        bool isValidSelection = _isWhiteTurn ? (checker > 0) : (checker < 0);

        if (isValidSelection) {
          _selectedSourceIndex = actualIndex;
          _gameMessage = "خانه ${actualIndex + 1} انتخاب شد. حالا خانه مقصد را انتخاب کنید.";
        } else {
          _gameMessage = "این مهره متعلق به شما نیست یا این خانه خالی است!";
        }
      } 
      // حالت دوم: مهره انتخاب شده است و حالا داریم مقصد را انتخاب می‌کنیم
      else {
        int source = _selectedSourceIndex!;
        
        // اگر روی همان خانه قبلی دوباره کلیک کند، انتخاب لغو می‌شود
        if (source == actualIndex) {
          _selectedSourceIndex = null;
          _gameMessage = "انتخاب لغو شد.";
          return;
        }

        // محاسبه فاصله (تعداد خانه‌های جابجایی) بر اساس جهت حرکت بازیکن
        // سفید از خانه 0 به سمت 23 حرکت می‌کند، سیاه برعکس از 23 به سمت 0
        int distance = _isWhiteTurn ? (actualIndex - source) : (source - actualIndex);

        if (distance <= 0) {
          _gameMessage = "جهت حرکت نامعتبر است!";
          _selectedSourceIndex = null;
          return;
        }

        // بررسی اینکه آیا تاس متناسب با این فاصله در دست داریم یا خیر
        if (_availableDice.contains(distance)) {
          // بررسی قوانین ساده مقصد (مانع نشدن مهره حریف - اگر تعداد مهره حریف بیشتر از 1 باشد نمی‌توان نشست)
          int destinationVal = _board[actualIndex];
          bool canLand = _isWhiteTurn ? (destinationVal >= -1) : (destinationVal <= 1);

          if (canLand) {
            // اعمال حرکت روی آرایه تخته
            if (_isWhiteTurn) {
              _board[source] -= 1;
              if (destinationVal == -1) {
                // زدن مهره سیاه و فرستادن به بیرون (حالت ساده)
                _board[actualIndex] = 1;
              } else {
                _board[actualIndex] += 1;
              }
            } else {
              _board[source] += 1;
              if (destinationVal == 1) {
                // زدن مهره سفید
                _board[actualIndex] = -1;
              } else {
                _board[actualIndex] -= 1;
              }
            }

            // مصرف کردن تاس استفاده شده
            _availableDice.remove(distance);
            _selectedSourceIndex = null;

            // بررسی اتمام تاس‌های این نوبت
            if (_availableDice.isEmpty) {
              _endTurn();
            } else {
              _gameMessage = "حرکت با موفقیت انجام شد. تاس‌های باقیمانده: $_availableDice. مهره بعدی را انتخاب کنید.";
            }
          } else {
            _gameMessage = "این خانه بسته است (مهره حریف زیاد است)! مقصد دیگری انتخاب کنید.";
            _selectedSourceIndex = null;
          }
        } else {
          _gameMessage = "فاصله انتخابی با مقدار تاس‌های باقیمانده ($_availableDice) همخوانی ندارد!";
          _selectedSourceIndex = null;
        }
      }
    });
  }

  // تعویض نوبت
  void _endTurn() {
    setState(() {
      _isWhiteTurn = !_isWhiteTurn;
      _dice1 = null;
      _dice2 = null;
      _availableDice.clear();
      _selectedSourceIndex = null;
      _gameMessage = "نوبت تغییر کرد. نوبت ${_isWhiteTurn ? 'سفید (پایین/راست)' : 'سیاه (بالا)'} است. تاس بریزید.";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3E2723), // پس‌زمینه چوبی تیره
      appBar: AppBar(
        title: const Text('تخته نرد - نامیرا'),
        backgroundColor: const Color(0xFF5D4037),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _initializeBoard,
            tooltip: 'شروع مجدد بازی',
          )
        ],
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
                Expanded(
                  child: Text(
                    _gameMessage,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  children: [
                    if (_dice1 != null && _dice2 != null) ...[
                      Chip(label: Text('$_dice1', style: const TextStyle(fontWeight: FontWeight.bold))),
                      const SizedBox(width: 4),
                      Chip(label: Text('$_dice2', style: const TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: (_availableDice.isEmpty) ? _rollDice : _endTurn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber[800],
                        foregroundColor: Colors.white,
                      ),
                      child: Text(_availableDice.isEmpty ? 'تاس بریز' : 'پایان نوبت'),
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

  // ویجت کمکی برای ساختن نیمه‌ای از خانه‌های تخته با قابلیت تشخیص انتخاب‌شده‌ها
  Widget _buildBoardHalf(int startIndex, int endIndex, bool isTop) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate((endIndex - startIndex) + 1, (index) {
          int actualIndex = isTop ? (endIndex - index) : (startIndex + index);
          int checkersCount = _board[actualIndex];
          bool isSelected = _selectedSourceIndex == actualIndex;

          return Expanded(
            child: GestureDetector(
              onTap: () => _onBoardSquareTap(actualIndex),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? Colors.amber.withOpacity(0.6) // اگر این خانه انتخاب شده باشد رنگش فرق می‌کند
                      : (actualIndex % 2 == 0 ? const Color(0xFFBCAAA4) : const Color(0xFF8D6E63)),
                  border: isSelected ? Border.all(color: Colors.amber, width: 2) : null,
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
                          border: Border.all(
                            color: isSelected ? Colors.amberAccent : Colors.grey, 
                            width: isSelected ? 2 : 1,
                          ),
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
