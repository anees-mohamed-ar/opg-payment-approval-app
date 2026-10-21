import 'dart:async';

class RefreshEvent {}

class EventBus {
  final _eventController = StreamController<RefreshEvent>.broadcast();

  Stream<RefreshEvent> get events => _eventController.stream;

  void fire(RefreshEvent event) {
    _eventController.add(event);
  }

  void dispose() {
    _eventController.close();
  }
}

final eventBus = EventBus();
