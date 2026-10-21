class SupplierModel {
  final int id;
  final String supplier;
  final String address;
  final String? gstNo;
  final String pincode;
  final String state;
  final String telNo;
  final String faxNo;
  final String? contactPerson;
  final String emailId;
  final String? msmeType;
  final String? msmeNo;

  SupplierModel({
    required this.id,
    required this.supplier,
    required this.address,
    this.gstNo,
    required this.pincode,
    required this.state,
    required this.telNo,
    required this.faxNo,
    this.contactPerson,
    required this.emailId,
    this.msmeType,
    this.msmeNo,
  });

  factory SupplierModel.fromJson(Map<String, dynamic> json) {
    return SupplierModel(
      id: json['id'] ?? 0,
      supplier: json['supplier'] ?? '',
      address: json['address'] ?? '',
      gstNo: json['gst_no'],
      pincode: json['pincode'] ?? '',
      state: json['state'] ?? '',
      telNo: json['tel_no'] ?? '',
      faxNo: json['fax_no'] ?? '',
      contactPerson: json['contact_person'],
      emailId: json['email_id'] ?? '',
      msmeType: json['msme_type'],
      msmeNo: json['msme_no'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'supplier': supplier,
      'address': address,
      'gst_no': gstNo,
      'pincode': pincode,
      'state': state,
      'tel_no': telNo,
      'fax_no': faxNo,
      'contact_person': contactPerson,
      'email_id': emailId,
      'msme_type': msmeType,
      'msme_no': msmeNo,
    };
  }
}
