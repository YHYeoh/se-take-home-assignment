import 'package:take_home_assignment/bot.dart';

enum OrderType {
  normal,
  vip,
}

enum OrderStatus{
  pending,
  inProgress,
  completed,
}

class Order {
  final String name;
  final Bot? handler;
  final OrderType type;
  final OrderStatus status;
  // final int timeRemaining;


  //default time remaining is 10 seconds
  Order({
    required this.name,
    this.handler, required this.type, this.status = OrderStatus.pending});
}
