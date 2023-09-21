enum BotStatus {
  idle,
  busy,
}

class Bot {
  final String name;
  final BotStatus status;

  Bot({required this.name, this.status = BotStatus.idle});
}
