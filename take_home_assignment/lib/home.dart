import 'dart:async';

import 'package:flutter/material.dart';
import 'package:take_home_assignment/order.dart';
import 'package:collection/collection.dart';

import 'bot.dart';

//free bot notification
class FreeBotNotification extends Notification {
  final String botName;
  final String completedOrderName;

  const FreeBotNotification(
      {required this.botName, required this.completedOrderName});
}

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final List<Order> _orders = [];
  final List<Order> _completedOrders = [];
  final List<Bot> _bots = [
    //initialize with one bot
    Bot(name: "Bot 1")
  ];

  void _addOrder(OrderType type) {
    final nextOrderID = _orders.length + 1 + _completedOrders.length;
    final nextFreeBot =
        _bots.firstWhereOrNull((bot) => bot.status == BotStatus.idle);

    final isNextBotReady = nextFreeBot != null;

    if (isNextBotReady) {
      //update bot status
      _bots[_bots.indexOf(nextFreeBot)] =
          Bot(name: nextFreeBot.name, status: BotStatus.busy);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("No free bots available, item added to queue"),
      ));
    }

    //find first index of pending order, insert vip order at the front, else add to the back
    // final firstPendingOrderIndex =
    //     _orders.indexWhere((order) => order.status == OrderStatus.pending);

    final bool isOrderContainsVip =
        _orders.any((order) => order.type == OrderType.vip);
    int firstPendingVipOrderIndex = isOrderContainsVip
        ? _orders.indexWhere((order) =>
            order.status == OrderStatus.pending && order.type == OrderType.vip)
        : _orders.indexWhere((order) => order.status == OrderStatus.pending);

    if (firstPendingVipOrderIndex != -1 && isOrderContainsVip) {
      //insert the new vip order after the last vip order
      firstPendingVipOrderIndex += 1;
    }

    setState(() {
      switch (type) {
        case OrderType.vip:
          _orders.insert(
              firstPendingVipOrderIndex == -1
                  ? _orders.length
                  : firstPendingVipOrderIndex,
              Order(
                  name: "Order $nextOrderID",
                  handler: nextFreeBot,
                  type: type,
                  status: isNextBotReady
                      ? OrderStatus.inProgress
                      : OrderStatus.pending));
          break;
        case OrderType.normal:
          _orders.add(Order(
              name: "Order $nextOrderID",
              handler: nextFreeBot,
              type: type,
              status: isNextBotReady
                  ? OrderStatus.inProgress
                  : OrderStatus.pending));
          break;
      }
    });
  }

  void _addBot() {
    int botIndex = _bots.length;
    setState(() {
      _bots.add(Bot(name: "Bot ${botIndex + 1}"));
    });
    _assignBotToNextPending(botIndex);
  }

  void _removeBot() {
    //remove the last bot
    setState(() {
      Bot latestBot = _bots.removeLast();

      //resets the status of the order handled by the bot
      Order? handledOrder = _orders.firstWhereOrNull(
          (element) => element.handler?.name == latestBot.name);

      if (handledOrder == null) return;

      _orders[_orders.indexOf(handledOrder)] = Order(
          name: handledOrder.name,
          handler: null,
          type: handledOrder.type,
          status: OrderStatus.pending);
    });
  }

  void _markOrderAsCompleted(String orderName) {
    final int index = _orders.indexWhere((order) => order.name == orderName);
    final Order currentOrder = _orders[index];
    final Order updatedOrder = Order(
        name: currentOrder.name,
        handler: currentOrder.handler,
        type: currentOrder.type,
        status: OrderStatus.completed);
    setState(() {
      _orders[index] = updatedOrder;
      _completedOrders.add(updatedOrder);
      _orders.removeAt(index);
    });
  }

  void _assignBotToNextPending(int botIndex) {
    final pendingOrders =
        _orders.where((order) => order.status == OrderStatus.pending).toList();

    if (pendingOrders.isEmpty) {
      return;
    }

    //update the first pending order to inProgress
    final firstPendingOrder = pendingOrders.first;
    final firstPendingOrderIndex = _orders.indexOf(firstPendingOrder);
    setState(() {
      _bots[botIndex] = Bot(name: _bots[botIndex].name, status: BotStatus.busy);
      _orders[firstPendingOrderIndex] = Order(
          name: firstPendingOrder.name,
          handler: _bots[botIndex],
          type: firstPendingOrder.type,
          status: OrderStatus.inProgress);
    });
  }

  void _refreshBotStatus(String botName) {
    final botIndex = _bots.indexWhere((bot) => bot.name == botName);
    if (botIndex == -1) {
      return;
    }

    //check if there are any pending orders
    final pendingOrders =
        _orders.where((order) => order.status == OrderStatus.pending).toList();

    if (pendingOrders.isEmpty) {
      setState(() {
        _bots[botIndex] = Bot(name: botName, status: BotStatus.idle);
      });
      return;
    }

    //update the first pending order to inProgress
    final firstPendingOrder = pendingOrders.first;
    final firstPendingOrderIndex = _orders.indexOf(firstPendingOrder);
    setState(() {
      _orders[firstPendingOrderIndex] = Order(
          name: firstPendingOrder.name,
          handler: _bots[botIndex],
          type: firstPendingOrder.type,
          status: OrderStatus.inProgress);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('McDonald Auto Order Bot'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.black),
      body: NotificationListener<FreeBotNotification>(
        onNotification: (notification) {
          _markOrderAsCompleted(notification.completedOrderName);
          _refreshBotStatus(notification.botName);

          return true;
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      "Bots",
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const Spacer(),
                    TextButton.icon(
                        //style the button red
                        style: _bots.isEmpty ? null: ButtonStyle(
                          foregroundColor:
                              MaterialStateProperty.all<Color>(Colors.red),
                        ),
                        onPressed: _bots.isEmpty
                            ? null
                            : () {
                                _removeBot();
                              },
                        icon: const Icon(Icons.remove_circle_rounded),
                        label: const Text("Remove Bot")),
                    const SizedBox(
                      width: 16,
                    ),
                    TextButton.icon(
                        onPressed: () {
                          _addBot();
                        },
                        icon: const Icon(Icons.add_circle_rounded),
                        label: const Text("Add Bot"))
                  ],
                ),
                const SizedBox(
                  height: 16,
                ),
                Bots(
                  bots: _bots,
                ),
                const SizedBox(
                  height: 32,
                ),
                Text(
                  "Orders",
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(
                  height: 16,
                ),
                Text("Pending / In Progress",
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(
                  height: 8,
                ),
                Expanded(
                  flex: 2,
                  child: Orders(
                    orders: _orders,
                  ),
                ),
                const SizedBox(
                  height: 16,
                ),
                Text("Completed",
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(
                  height: 8,
                ),
                Expanded(
                  flex: 2,
                  child: Orders(
                    orders: _completedOrders,
                  ),
                ),
                const SizedBox(
                  height: 32,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton.icon(
                        onPressed: () {
                          _addOrder(OrderType.vip);
                        },
                        icon: const Icon(Icons.add_moderator_rounded),
                        label: const Text("New VIP Order")),
                    ElevatedButton.icon(
                        onPressed: () {
                          //construct new Order
                          _addOrder(OrderType.normal);
                        },
                        icon: const Icon(Icons.add_rounded),
                        label: const Text("New Normal Order")),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class OrderItem extends StatefulWidget {
  final Order order;

  const OrderItem({super.key, required this.order});

  @override
  State<OrderItem> createState() => _OrderItemState();
}

class _OrderItemState extends State<OrderItem> {
  Timer? _timer;
  int _timeRemainingSecs = 10;
  late Order orderItem;

  @override
  void initState() {
    super.initState();
    orderItem = widget.order;
    debugPrint("initState ${orderItem.name}");
    if (widget.order.status == OrderStatus.completed) {
      _timeRemainingSecs = 0;
      return;
    }
    if (widget.order.handler != null) {
      startTimer();
    }
  }

  @override
  void didUpdateWidget(covariant OrderItem oldWidget) {
    debugPrint("didUpdateWidget ${orderItem.name}");
    super.didUpdateWidget(oldWidget);
    orderItem = widget.order;
    if (orderItem.handler != null &&
        orderItem.status != OrderStatus.completed &&
        _timer?.isActive != true &&
        _timeRemainingSecs > 0) {
      startTimer();
    }
    if (orderItem.handler == null) {
      _timer?.cancel();
      setState(() {
        _timeRemainingSecs = 10;
      });
    }
  }

  void startTimer() {
    const clockTimer = Duration(seconds: 1);
    _timer = Timer.periodic(clockTimer, (timer) {
      setState(() {
        _timeRemainingSecs--;
        if (_timeRemainingSecs == 0) {
          _timer?.cancel();

          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: Colors.green,
            duration: const Duration(milliseconds: 300),
            content: Text("${orderItem.name} Completed!"),
          ));

          context.dispatchNotification(FreeBotNotification(
              botName: orderItem.handler!.name,
              completedOrderName: widget.order.name));
          return;
        }
        orderItem = Order(
          name: orderItem.name,
          handler: orderItem.handler,
          type: orderItem.type,
          status: orderItem.status,
        );
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    if (_timer?.isActive != null && _timer != null && _timer!.isActive) {
      _timer?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    //enum to string
    String enumToString(enumItem) {
      return enumItem.toString().split('.').last;
    }

    //color code the order type if it is VIP, shows gold Color, else uses accentColor
    Color getOrderTypeColor(OrderType type) {
      return type == OrderType.vip
          ? Colors.amber
          : Theme.of(context).colorScheme.primary;
    }

    debugPrint(
        "rendering ${orderItem.name}, handler: ${orderItem.handler}, status: ${orderItem.status}");
    return ListTile(
      title: Text(orderItem.name),
      subtitle: Text(
        '${enumToString(orderItem.type).toUpperCase()} • ${orderItem.handler?.name ?? "Unknown Bot"} • ${enumToString(orderItem.status).toUpperCase()}',
        style: TextStyle(color: getOrderTypeColor(orderItem.type)),
      ),
      trailing: ProgressIndicator(
        //count up from 0 to 10
        progress: _timeRemainingSecs,
      ),
    );
  }
}

class Orders extends StatelessWidget {
  final List<Order> orders;

  const Orders({super.key, required this.orders});

  @override
  Widget build(BuildContext context) {
    return orders.isEmpty
        ? const Center(child: Text("No Orders :("))
        //not using list view builder as it is lazily loaded, the order of the list is not maintained, also the timer might not start if the order is not in view
        : ListView(
            children: orders
                .map((order) => OrderItem(
                    key: ValueKey(order.name + order.status.toString()),
                    order: order))
                .toList(),
          );
    // : ListView.builder(
    //     itemBuilder: (context, index) {
    //       return OrderItem(
    //           key: ValueKey(orders[index].name + orders[index].status.toString()),
    //           order: orders[index],
    //           );
    //     },
    //     itemCount: orders.length,
    //   );
  }
}

class Bots extends StatelessWidget {
  final List<Bot> bots;
  const Bots({super.key, required this.bots});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: bots.isEmpty
          ? const Center(child: Text("No Bots :("))
          : ListView.separated(
              itemCount: bots.length,
              scrollDirection: Axis.horizontal,
              separatorBuilder: (context, index) => const SizedBox(
                width: 16,
              ),
              itemBuilder: (context, index) {
                return BotItem(bot: bots[index]);
              },
            ),
    );
  }
}

class BotItem extends StatelessWidget {
  final Bot bot;

  const BotItem({super.key, required this.bot});

  @override
  Widget build(BuildContext context) {
    Color getStatusColor() {
      return bot.status == BotStatus.idle
          ? Colors.green
          : Theme.of(context).colorScheme.error;
    }

    return SizedBox(
      height: 32,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(bot.name),
          const SizedBox(
            height: 8,
          ),
          Text(
            bot.status.name.toUpperCase(),
            style: TextStyle(color: getStatusColor()),
          ),
        ],
      ),
    );
  }
}

class ProgressIndicator extends StatelessWidget {
  final int progress;

  const ProgressIndicator({super.key, this.progress = 0});

  @override
  Widget build(BuildContext context) {
    const totalDuration = 10;
    return progress == 0
        ? const Icon(
            Icons.check_rounded,
            color: Colors.green,
          )
        : Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  value: progress == totalDuration
                      ? null
                      : (totalDuration - progress) / 10,
                  strokeWidth: 4,
                ),
              ),
              Text(
                progress == totalDuration ? "-" : progress.toString(),
                style: const TextStyle(fontSize: 16),
              ),
            ],
          );
  }
}
