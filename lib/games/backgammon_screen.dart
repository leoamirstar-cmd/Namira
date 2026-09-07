import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class BackgammonGameScreen extends StatefulWidget {
  const BackgammonGameScreen({Key? key}) : super(key: key);

  @override
  State<BackgammonGameScreen> createState() => _BackgammonGameScreenState();
}

class _BackgammonGameScreenState extends State<BackgammonGameScreen> {
  // وضعیت ۲۴ خانه تخته نرد (مثبت برای سفید، منفی برای سیاه)
  final List<int> _board = List.filled(24, 0);

  int? _dice1;
  int? _dice2;
  List<int> _availableDice = [];
  
  bool _isWhiteTurn = true; // true مخفف سفید (کاربر)، false مخفف سیاه (ربات)
  bool _isVsBot = true; // حالت بازی با ربات فعال است
  int? _selectedSourceIndex;
  String _gameMessage = "برای شروع تاس بریزید";
  bool _isBotThinking = false;

  @override
  void initState() {
    super.initState();
    _initializeBoard();
  }

  // چیدمان اولیه استاندارد تخته نرد
  void _initializeBoard() {
    _board.fillRange(0, 24, 0);

    // سفید (با اعداد مثبت)
    _board[0] = 2;   
    _board[11] = 5;  
    _board[16] = 3;  
    _board[18] = 5;  

    // سیاه (با مقادیر منفی)
    _board[23] = -2; 
    _board[12] = -5; 
    _board[7] = -3;  
    _board[5] = -5;  

    setState(() {
      _isWhiteTurn = true;
      _dice1 = null;
      _dice2 = null;
      _availableDice.clear();
      _selectedSourceIndex = null;
      _isBotThinking = false;
      _gameMessage = "بازی شروع شد. نوبت شماست (مهره سفید). تاس بریزید.";
    });
  }

  // تابع پرتاب تاس
  void _rollDice() {
    if (_isBotThinking) return;

    final random = Random();
    setState(() {
      _dice1 = random.nextInt(6) + 1;
      _dice2 = random.nextInt(6) + 1;
      
      _availableDice = [_dice1!, _dice2!];
      if (_dice1 == _dice2) {
        _availableDice.add(_dice1!);
        _availableDice.add(_dice1!);
        _gameMessage = "تاس جفت آمد! ($_dice1 - $_dice1). ۴ حرکت دارید.";
      } else {
        _gameMessage = "تاس‌ها: $_dice1 و $_dice2. مهره‌ای را برای حرکت انتخاب کنید.";
      }
      _selectedSourceIndex = null;
    });

    // اگر نوبت ربات باشد، پس از ریختن تاس، هوش مصنوعی وارد عمل می‌شود
    if (!_isWhiteTurn && _isVsBot) {
      _triggerBotTurn();
    }
  }

  // مدیریت کلیک روی خانه‌ها توسط کاربر
  void _onBoardSquareTap(int actualIndex) {
    if (!_isWhiteTurn && _isVsBot) return; // کاربر در نوبت ربات نمی‌تواند بازی کند
    if (_availableDice.isEmpty) {
      setState(() {
        _gameMessage = "ابتدا باید تاس بریزید!";
      });
      return;
    }

    setState(() {
      if (_selectedSourceIndex == null) {
        int checker = _board[actualIndex];
        // بازیکن سفید فقط باید روی مهره‌های مثبت خودش کلیک کند
        if (checker > 0) {
          _selectedSourceIndex = actualIndex;
          _gameMessage = "خانه ${actualIndex + 1} انتخاب شد. حالا مقصد را انتخاب کنید.";
        } else {
          _gameMessage = "این مهره متعلق به شما نیست!";
        }
      } else {
        int source = _selectedSourceIndex!;
        if (source == actualIndex) {
          _selectedSourceIndex = null;
          _gameMessage = "انتخاب لغو شد.";
          return;
        }

        // جهت حرکت سفید از 0 به سمت 23 است
        int distance = actualIndex - source;

        if (distance <= 0) {
          _gameMessage = "جهت حرکت نامعتبر است! مهره سفید به سمت جلو حرکت می‌کند.";
          _selectedSourceIndex = null;
          return;
        }

        if (_availableDice.contains(distance)) {
          int destinationVal = _board[actualIndex];
          // سفید می‌تواند روی خانه‌های خالی، خانه‌های خودش، یا خانه تکِ حریف بنشیند
          bool canLand = (destinationVal >= -1);

          if (canLand) {
            _board[source] -= 1;
            if (destinationVal == -1) {
              _board[actualIndex] = 1; // زدن مهره سیاه
            } else {
              _board[actualIndex] += 1;
            }

            _availableDice.remove(distance);
            _selectedSourceIndex = null;

            if (_availableDice.isEmpty) {
              _endTurn();
            } else {
              _gameMessage = "حرکت انجام شد. تاس‌های باقیمانده: $_availableDice";
            }
          } else {
            _gameMessage = "این خانه بسته است!";
            _selectedSourceIndex = null;
          }
        } else {
          _gameMessage = "فاصله با تاس‌های باقیمانده ($_availableDice) همخوانی ندارد!";
          _selectedSourceIndex = null;
        }
      }
    });
  }

  // منطق هوش مصنوعی (ربات سیاه)
  void _triggerBotTurn() {
    setState(() {
      _isBotThinking = true;
      _gameMessage = "ربات نامیرا در حال فکر کردن است...";
    });

    // ایجاد تاخیر مصنوعی برای واقعی‌تر شدن بازی
    Timer(const Duration(seconds: 1500 ~/ 1000), () {
      if (!mounted) return;

      // ربات تا زمانی که تاس دارد تلاش می‌کند حرکت کند
      while (_availableDice.isNotEmpty) {
        bool moved = _makeOneBotMove();
        if (!moved) {
          break; // اگر هیچ حرکت قانونی‌ای باقی نمانده بود، از حلقه خارج شو
        }
      }

      // پایان نوبت ربات
      setState(() {
        _isBotThinking = false;
        _endTurn();
      });
    });
  }

  // انجام یک حرکت توسط ربات
  bool _makeOneBotMove() {
    // مهره‌های سیاه منفی هستند و از خانه 23 به سمت 0 حرکت می‌کنند
    for (int dice in List.from(_availableDice)) {
      for (int i = 23; i >= 0; i--) {
        if (_board[i] < 0) { // اگر مهره سیاه اینجا هست
          int targetIndex = i - dice;
          if (targetIndex >= 0) {
            int targetVal = _board[targetIndex];
            // ربات می‌تواند روی خانه‌های خالی، منفی، یا تک مهره سفید (1) بنشیند
            if (targetVal <= 1) {
              _board[i] += 1; // کم شدن از مبدأ سیاه
              if (targetVal == 1) {
                _board[targetIndex] = -1; // زدن مهره سفید
              } else {
                _board[targetIndex] -= 1;
              }
              _availableDice.remove(dice);
              return true; // حرکت با موفقیت انجام شد
            }
          }
        }
      }
    }
    return false; // هیچ حرکتی مقدور نبود
  }

  // تعویض نوبت
  void _endTurn() {
    setState(() {
      _isWhiteTurn = !_isWhiteTurn;
      _dice1 = null;
      _dice2 = null;
      _availableDice.clear();
      _selectedSourceIndex = null;
      
      if (_isWhiteTurn) {
        _gameMessage = "نوبت شماست (سفید). تاس بریزید.";
      } else {
        _gameMessage = "نوبت ربات (سیاه). در حال پرتاب تاس...";
        if (_isVsBot) {
          // به طور خودکار تاس ربات ریخته می‌شود
          Timer(const Duration(milliseconds: 800), _rollDice);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3E2723),
      appBar: AppBar(
        title: Text(_isVsBot ? 'تخته نرد - نامیرا (بازی با ربات)' : 'تخته نرد - نامیرا (دو نفره)'),
        backgroundColor: const Color(0xFF5D4037),
        actions: [
          // دکمه تغییر حالت بازی با ربات یا دونفره
          IconButton(
            icon: Icon(_isVsBot ? Icons.person : Icons.smart_toy),
            tooltip: _isVsBot ? 'تغییر به بازی دونفره' : 'تغییر به بازی با ربات',
            onPressed: () {
              setState(() {
                _isVsBot = !_isVsBot;
                _initializeBoard();
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _initializeBoard,
            tooltip: 'شروع مجدد',
          )
        ],
      ),
      body: Column(
        children: [
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
                      onPressed: (_availableDice.isEmpty && !_isBotThinking && (_isWhiteTurn || !_isVsBot)) 
                          ? _rollDice 
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber[800],
                        foregroundColor: Colors.white,
                      ),
                      child: Text(_availableDice.isEmpty ? 'تاس بریز' : 'صبر کنید'),
                    ),
                  ],
                ),
              ],
            ),
          ),

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
                  Expanded(
                    flex: 5,
                    child: Column(
                      children: [
                        _buildBoardHalf(11, 16, true),
                        const Divider(height: 20, thickness: 8, color: Color(0xFF5D4037)),
                        _buildBoardHalf(17, 22, false),
                      ],
                    ),
                  ),
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
                  Expanded(
                    flex: 5,
                    child: Column(
                      children: [
                        _buildBoardHalf(5, 10, true),
                        _buildBoardHalf(0, 4, false),
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
                      ? Colors.amber.withOpacity(0.6) 
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
