import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

@immutable
class Money {
  const Money._();

  static final _fc = NumberFormat('#,###', 'vi_VN');
  static final _fcFull = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);

  static String get symbol => 'đ';

  static String format(num price, {bool symbol = false}) {
    return symbol ? _fcFull.format(price) : _fc.format(price);
  }

  static num unformat(String money) {
    if (money == '') {
      return 0;
    }
    // extract numbers, sign, commas & dots
    var s = money.replaceAll(RegExp(r'[^0-9,.-]'), '');
    s = s == '-' ? '0' : s;
    return _fc.parse(s);
  }
}
