class Voucher {
  final int? id;
  final String? date;
  final String? voucherNumber;
  final String? ledgerName;
  final String? amount;
  final String? voucherId;
  final String? level1;
  final String? level2;
  final String? level3;
  final String? level4;
  final String? level5;
  final String? level6;
  final String? level7;
  final String? level2_1;
  final String? level2_2;
  final String? level2_3;

  Voucher({
    this.id,
    this.date,
    this.voucherNumber,
    this.ledgerName,
    this.amount,
    this.voucherId,
    this.level1,
    this.level2,
    this.level3,
    this.level4,
    this.level5,
    this.level6,
    this.level7,
    this.level2_1,
    this.level2_2,
    this.level2_3,
  });

  factory Voucher.fromJson(Map<String, dynamic> json) {
    return Voucher(
      id: json['id'] as int?,
      date: json['date']?.toString(),
      voucherNumber: json['voucherNumber']?.toString(),
      ledgerName: json['ledgerName']?.toString(),
      amount: json['amount']?.toString(),
      voucherId: json['voucherId']?.toString(),
      level1: json['level1']?.toString(),
      level2: json['level2']?.toString(),
      level3: json['level3']?.toString(),
      level4: json['level4']?.toString(),
      level5: json['level5']?.toString(),
      level6: json['level6']?.toString(),
      level7: json['level7']?.toString(),
      level2_1: json['level2_1']?.toString(),
      level2_2: json['level2_2']?.toString(),
      level2_3: json['level2_3']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date,
        'voucherNumber': voucherNumber,
        'ledgerName': ledgerName,
        'amount': amount,
        'voucherId': voucherId,
        'level1': level1,
        'level2': level2,
        'level3': level3,
        'level4': level4,
        'level5': level5,
        'level6': level6,
        'level7': level7,
        'level2_1': level2_1,
        'level2_2': level2_2,
        'level2_3': level2_3,
      };
}
