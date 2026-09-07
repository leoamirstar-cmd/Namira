import 'dart:math';

enum CheckeredColor { white, black }

class BackgammonPoint {
  final int index;
  int count;
  CheckeredColor? color;

  BackgammonPoint(this.index, this.count, this.color);
}

class BackgammonGameLogic {
  List<BackgammonPoint> points = [];
  CheckeredColor currentTurn = CheckeredColor.white;
  List<int> dice = [];
  List<int> currentDice = [];
  bool isDiceRolled = false;
  
  int whiteBar = 0;
  int blackBar = 0;
  int whiteHome = 0;
  int blackHome = 0;

  BackgammonGameLogic() {
    initBoard();
  }

  void initBoard() {
    points = List.generate(24, (index) => BackgammonPoint(index + 1, 0, null));

    // تنظیمات اولیه مهره‌های تخته نرد استاندارد
    // نقاط بر اساس شماره‌گذاری استاندارد 1 تا 24
    setPoint(1, 2, CheckeredColor.white);
    setPoint(12, 5, CheckeredColor.white);
    setPoint(17, 3, CheckeredColor.white);
    setPoint(19, 5, CheckeredColor.white);

    setPoint(24, 2, CheckeredColor.black);
    setPoint(13, 5, CheckeredColor.black);
    setPoint(8, 3, CheckeredColor.black);
    setPoint(6, 5, CheckeredColor.black);

    whiteBar = 0;
    blackBar = 0;
    whiteHome = 0;
    blackHome = 0;
    currentTurn = CheckeredColor.white;
    isDiceRolled = false;
  }

  void setPoint(int index, int count, CheckeredColor color) {
    points[index - 1].count = count;
    points[index - 1].color = color;
  }

  void rollDice() {
    if (isDiceRolled) return;
    Random rnd = Random();
    int d1 = rnd.nextInt(6) + 1;
    int d2 = rnd.nextInt(6) + 1;

    if (d1 == d2) {
      dice = [d1, d1, d1, d1];
    } else {
      dice = [d1, d2];
    }
    currentDice = List.from(dice);
    isDiceRolled = true;
  }

  bool movePiece(int fromIndex, int toIndex) {
    // منطق ساده‌شده و ایمن برای جابجایی مهره در صورت صحت نوبت و تاس
    if (!isDiceRolled || currentDice.isEmpty) return false;
    
    // بررسی صحت حرکت بر اساس تاس‌های موجود
    int distance = (toIndex - fromIndex).abs();
    if (!currentDice.contains(distance)) {
      // بررسی تاس ترکیبی یا تقریبی در صورت نیاز
      bool found = false;
      for (int d in currentDice) {
        if (distance % d == 0) {
          found = true;
          break;
        }
      }
      if (!found) return false;
    }

    // اعمال جابجایی
    var fromPoint = points[fromIndex];
    var toPoint = points[toIndex];

    if (fromPoint.count <= 0 || fromPoint.color != currentTurn) return false;

    // اگر خانه مقصد خالی یا هم‌رنگ باشد یا تک‌مهره حریف باشد (بردن روی زن)
    if (toPoint.count == 0 || toPoint.color == currentTurn) {
      fromPoint.count--;
      if (fromPoint.count == 0) fromPoint.color = null;

      toPoint.count++;
      toPoint.color = currentTurn;
      
      // مصرف تاس
      currentDice.remove(distance);
    } else if (toPoint.count == 1 && toPoint.color != currentTurn) {
      // زدن مهره حریف
      fromPoint.count--;
      if (fromPoint.count == 0) fromPoint.color = null;

      if (toPoint.color == CheckeredColor.white) {
        whiteBar++;
      } else {
        blackBar++;
      }

      toPoint.count = 1;
      toPoint.color = currentTurn;
      
      currentDice.remove(distance);
    } else {
      return false;
    }

    // اگر تاس‌ها تمام شدند، نوبت عوض شود
    if (currentDice.isEmpty) {
      endTurn();
    }

    return true;
  }

  void endTurn() {
    currentTurn = (currentTurn == CheckeredColor.white) ? CheckeredColor.black : CheckeredColor.white;
    isDiceRolled = false;
    dice.clear();
    currentDice.clear();
  }
}
