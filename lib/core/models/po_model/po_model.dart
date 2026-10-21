class POModel {
  final String id;
  final String poNumber;
  final String vendor;
  final String date;
  final String amount;
  final String expenses;
  final String productValue;
  final String totalRate;
  final String totalQty;
  final String discount;
  final String poQty;
  final String purchaseLedger;
  final String deliveryAddress;
  final String billToAddress;
  final String termsOfPayment;
  final String incoTerms;
  final String inspection;
  final String deliveryService;
  final String yourReference;
  final String purchaseRequisition;
  final String projectTimeGCTPolicy;
  final String insurance;
  final String rejectedReason;
  final String validityStartEnd;
  final String deliveryDate;
  final String paymentTerms;
  final String specialInstructions;
  final String warranty;
  final String level1;
  final String level2;
  final String level3;
  final String level4;
  final String level5;
  final String level1Approver;
  final String level2Approver;
  final String level3Approver;
  final String level4Approver;
  final String level5Approver;
  final String sentToTally;
  final String sentToTallyDate;
  final String reject;
  final String rejectionReason;
  final String rejectedPerson;
  final String rejectReason;
  final String prType;
  final String document;

  POModel({
    required this.id,
    required this.poNumber,
    required this.vendor,
    required this.date,
    required this.amount,
    required this.expenses,
    required this.productValue,
    required this.totalRate,
    required this.totalQty,
    required this.discount,
    required this.poQty,
    required this.purchaseLedger,
    required this.deliveryAddress,
    required this.billToAddress,
    required this.termsOfPayment,
    required this.incoTerms,
    required this.inspection,
    required this.deliveryService,
    required this.yourReference,
    required this.purchaseRequisition,
    required this.projectTimeGCTPolicy,
    required this.insurance,
    required this.rejectedReason,
    required this.validityStartEnd,
    required this.deliveryDate,
    required this.paymentTerms,
    required this.specialInstructions,
    required this.warranty,
    required this.level1,
    required this.level2,
    required this.level3,
    required this.level4,
    required this.level5,
    required this.level1Approver,
    required this.level2Approver,
    required this.level3Approver,
    required this.level4Approver,
    required this.level5Approver,
    required this.sentToTally,
    required this.sentToTallyDate,
    required this.reject,
    required this.rejectionReason,
    required this.rejectedPerson,
    required this.rejectReason,
    required this.prType,
    required this.document,
  });

  /// **Factory constructor to create POModel from JSON**
  factory POModel.fromJson(Map<String, dynamic> json) {
    return POModel(
      id: json['id']?.toString() ?? '',
      poNumber: json['unqiue_no']?.toString() ?? '',
      vendor: json['vendors']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      amount: json['totalvalue']?.toString() ?? '',
      expenses: json['expenses']?.toString() ?? '',
      productValue: json['product_value']?.toString() ?? '',
      totalRate: json['totalrate']?.toString() ?? '',
      totalQty: json['totalqty']?.toString() ?? '',
      discount: json['discount']?.toString() ?? '',
      poQty: json['po_qty']?.toString() ?? '',
      purchaseLedger: json['purchase_ledger']?.toString() ?? '',
      deliveryAddress: json['delivery_address']?.toString() ?? '',
      billToAddress: json['billto_address']?.toString() ?? '',
      termsOfPayment: json['terms_of_payment']?.toString() ?? '',
      incoTerms: json['inco_terms']?.toString() ?? '',
      inspection: json['inspection']?.toString() ?? '',
      deliveryService: json['delivery_service']?.toString() ?? '',
      yourReference: json['your_reference']?.toString() ?? '',
      purchaseRequisition: json['purchase_requestion']?.toString() ?? '',
      projectTimeGCTPolicy: json['project_time_gct_policy']?.toString() ?? '',
      insurance: json['insurance']?.toString() ?? '',
      rejectedReason: json['rejected_reason']?.toString() ?? '',
      validityStartEnd: json['validity_start_end']?.toString() ?? '',
      deliveryDate: json['delivery_date']?.toString() ?? '',
      paymentTerms: json['payment_terms']?.toString() ?? '',
      specialInstructions: json['special_instructions']?.toString() ?? '',
      warranty: json['warranty']?.toString() ?? '',
      level1: json['level1']?.toString() ?? '',
      level2: json['level2']?.toString() ?? '',
      level3: json['level3']?.toString() ?? '',
      level4: json['level4']?.toString() ?? '',
      level5: json['level5']?.toString() ?? '',
      level1Approver: json['level1approver']?.toString() ?? '',
      level2Approver: json['level2approver']?.toString() ?? '',
      level3Approver: json['level3approver']?.toString() ?? '',
      level4Approver: json['level4approver']?.toString() ?? '',
      level5Approver: json['level5approver']?.toString() ?? '',
      sentToTally: json['sent_to_tally']?.toString() ?? '',
      sentToTallyDate: json['sent_to_tallydate']?.toString() ?? '',
      reject: json['reject']?.toString() ?? '',
      rejectionReason: json['rejection_reason']?.toString() ?? '',
      rejectedPerson: json['rejected_person']?.toString() ?? '',
      rejectReason: json['reject_reason']?.toString() ?? '',
      prType: json['pr_type']?.toString() ?? '',
      document: json['document']?.toString() ?? '',
    );
  }

  /// **Method to convert POModel to Map (for API requests if needed)**
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'po_number': poNumber,
      'vendor': vendor,
      'date': date,
      'amount': amount,
      'expenses': expenses,
      'product_value': productValue,
      'totalrate': totalRate,
      'totalqty': totalQty,
      'discount': discount,
      'po_qty': poQty,
      'purchase_ledger': purchaseLedger,
      'delivery_address': deliveryAddress,
      'billto_address': billToAddress,
      'terms_of_payment': termsOfPayment,
      'inco_terms': incoTerms,
      'inspection': inspection,
      'delivery_service': deliveryService,
      'your_reference': yourReference,
      'purchase_requestion': purchaseRequisition,
      'project_time_gct_policy': projectTimeGCTPolicy,
      'insurance': insurance,
      'rejected_reason': rejectedReason,
      'validity_start_end': validityStartEnd,
      'delivery_date': deliveryDate,
      'payment_terms': paymentTerms,
      'special_instructions': specialInstructions,
      'warranty': warranty,
      'level1': level1,
      'level2': level2,
      'level3': level3,
      'level4': level4,
      'level5': level5,
      'level1approver': level1Approver,
      'level2approver': level2Approver,
      'level3approver': level3Approver,
      'level4approver': level4Approver,
      'level5approver': level5Approver,
      'sent_to_tally': sentToTally,
      'sent_to_tallydate': sentToTallyDate,
      'reject': reject,
      'rejection_reason': rejectionReason,
      'rejected_person': rejectedPerson,
      'reject_reason': rejectReason,
      'pr_type': prType,
      'document': document,
    };
  }
}
