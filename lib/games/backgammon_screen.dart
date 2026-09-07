import 'package:flutter/material.dart';
import 'backgammon_logic.dart';

class BackgammonScreen extends StatefulWidget {
  const BackgammonScreen({Key? key}) : super(key: key);

  @override
  State<BackgammonScreen> createState() => _BackgammonScreenState();
}

class _BackgammonScreenState extends State<BackgammonScreen> {
  final BackgammonGameLogic _gameLogic = BackgammonGameLogic();
  int? selectedPointIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('بازی تخته نرد - نامیرا'),
        backgroundColor: Colors.brown[800],
      ),
      backgroundColor: Colors.brown[900],
      body: Column(
        children: [
          // بخش اطلاعات نوبت و تاس‌ها
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.brown[800],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'نوبت: ${_gameLogic.currentTurn == CheckeredColor.white ? "سفید" : "سیاه"}',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    Text(
                      'تاس‌ها: ${_gameLogic.currentDice.join(" - ")}',
                      style: const TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.amber[800]),
                      onPressed: _gameLogic.isDiceRolled
                          ? null
                          : () {
                              setState(() {
                                _gameLogic.rollDice();
                              });
                            },
                      child: const Text('ریختن تاس'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // بدنه اصلی تخته بازی
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.brown[300],
                border: Border.all(color: Colors.brown.shade900, width: 4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // نیمه بالایی تخته
                  Expanded(
                    child: Row(
                      children: List.generate(12, (index) {
                        int pointNum = 12 - index; // چیدمان استاندارد بالا
                        var point = _gameLogic.points[pointNum - 1];
                        bool isSelected = selectedPointIndex == (pointNum - 1);

                        return Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                if (selectedPointIndex == null) {
                                  if (point.count > 0 && point.color == _gameLogic.currentTurn) {
                                    selectedPointIndex = pointNum - 1;
                                  }
                                } else {
                                  _gameLogic.movePiece(selectedPointIndex!, pointNum - 1);
                                  selectedPointIndex = null;
                                }
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.all(1),
                              decoration: BoxDecoration(
                                color: isSelected 
                                    ? Colors.blue.withOpacity(0.5) 
                                    : (index % 2 == 0 ? Colors.brown[600] : Colors.brown[200]),
                                border: Border.all(color: Colors.black26),
                              ),
                              child: Column(
                                mainAxisAlignment: index % 2 == 0 ? MainAxisAlignment.start : MainAxisAlignment.end,
                                children: [
                                  Text('$pointNum', style: const TextStyle(fontSize: 10, color: Colors.white70)),
                                  if (point.count > 0)
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: point.color == CheckeredColor.white ? Colors.white : Colors.black,
                                        border: Border.all(color: Colors.grey),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${point.count}',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: point.color == CheckeredColor.white ? Colors.black : Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
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
                  ),

                  // نوار وسط تخته (Bar)
                  Container(
                    height: 30,
                    color: Colors.brown[700],
                    child: Center(
                      child: Text(
                        'بیرون‌مانده - سفید: ${_gameLogic.whiteBar} | سیاه: ${_gameLogic.blackBar}',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),

                  // نیمه پایینی تخته
                  Expanded(
                    child: Row(
                      children: List.generate(12, (index) {
                        int pointNum = 13 + index; // چیدمان استاندارد پایین
                        var point = _gameLogic.points[pointNum - 1];
                        bool isSelected = selectedPointIndex == (pointNum - 1);

                        return Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                if (selectedPointIndex == null) {
                                  if (point.count > 0 && point.color == _gameLogic.currentTurn) {
                                    selectedPointIndex = pointNum - 1;
                                  }
                                } else {
                                  _gameLogic.movePiece(selectedPointIndex!, pointNum - 1);
                                  selectedPointIndex = null;
                                }
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.all(1),
                              decoration: BoxDecoration(
                                color: isSelected 
                                    ? Colors.blue.withOpacity(0.5) 
                                    : (index % 2 == 0 ? Colors.brown[200] : Colors.brown[600]),
                                border: Border.all(color: Colors.black26),
                              ),
                              child: Column(
                                mainAxisAlignment: index % 2 == 0 ? MainAxisAlignment.end : MainAxisAlignment.start,
                                children: [
                                  if (point.count > 0)
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: point.color == CheckeredColor.white ? Colors.white : Colors.black,
                                        border: Border.all(color: Colors.grey),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${point.count}',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: point.color == CheckeredColor.white ? Colors.black : Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  Text('$pointNum', style: const TextStyle(fontSize: 10, color: Colors.white70)),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // دکمه ریست بازی
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
              onPressed: () {
                setState(() {
                  _gameLogic.initBoard();
                  selectedPointIndex = null;
                });
              },
              child: const Text('شروع مجدد بازی'),
            ),
          ),
        ],
      ),
    );
  }
}
