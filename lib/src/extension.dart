import 'dart:async';

import 'package:flutter/material.dart';

extension DurationExtension on Duration {
  ///   final _delay = 3.seconds;
  ///   print('+ wait $_delay');
  ///   await _delay.delayed();
  ///   print('- finish wait $_delay');
  ///   print('+ callback in 700ms');
  Future<T> delayed<T>([FutureOr<T> Function()? callback]) =>
      Future<T>.delayed(this, callback);
}

extension ExtensionNum on num {
  Duration get milliseconds => Duration(microseconds: (this * 1000).round());

  Duration get seconds => Duration(milliseconds: (this * 1000).round());
}

void log(value) => debugPrint(value.toString());
