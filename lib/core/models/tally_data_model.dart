// lib/core/models/tally_data_model.dart
class TallyData {
  final String date;
  final String paymentNo;
  final String accountLedger;
  final String party;
  final String billType;
  final String billName;
  final String billAmount;
  final String narration;

  const TallyData({
    required this.date,
    required this.paymentNo,
    required this.accountLedger,
    required this.party,
    required this.billType,
    required this.billName,
    required this.billAmount,
    required this.narration,
  });
}

class TallyDataManager {
  static final TallyDataManager _instance = TallyDataManager._internal();
  TallyData? _currentTallyData;

  factory TallyDataManager() => _instance;

  TallyDataManager._internal();

  TallyData? get currentTallyData => _currentTallyData;

  void updateTallyData(TallyData newData) {
    _currentTallyData = newData;
  }
}
