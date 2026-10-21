class PODetailsModel {
  final int id;
  final int requisitionId;
  final String product;
  final String reqDate;
  final String poRes;
  final double reviewerValue;
  final double approverValue;
  final double poValue;
  final double value;
  final double rate;
  final double gstAmount;
  final double gst;
  final String cost;
  final String prNo;
  final String hsn;
  final String gl;
  final String typeOfExpenses;
  final String prType;
  final String closingQuantity;
  final String description;
  final double discount;
  final double? discountAmount;
  final int quantity;
  final String depApprovedHead;
  final String depApprovedHeadDate;
  final String depApprovedManager;
  final String depApprovedManagerDate;
  final String? poApprovedDate;
  final String? poApproved;
  final int deptQuantity;
  final String deptQuantity2;
  final int newPoQuantity;
  final int? finalQty;
  final int? remainingQty;
  final double poRate;
  final int poQuantity;
  final double maxQuantity;
  final int? splitQuantity;
  final String unitMeasure;
  final String? rejectReason;
  final String? rejectReasonManager;
  final String? rejectReasonPo;
  final String requisitionActionSupervisor;
  final String requisitionActionManager;
  final String requisitionActionPo;
  final String vendors;
  final String? poRised;
  final List<String> productImage;
  final String poGen;

  PODetailsModel({
    required this.id,
    required this.requisitionId,
    required this.product,
    required this.reqDate,
    required this.poRes,
    required this.reviewerValue,
    required this.approverValue,
    required this.poValue,
    required this.value,
    required this.rate,
    required this.gstAmount,
    required this.gst,
    required this.cost,
    required this.prNo,
    required this.hsn,
    required this.gl,
    required this.typeOfExpenses,
    required this.prType,
    required this.closingQuantity,
    required this.description,
    required this.discount,
    this.discountAmount,
    required this.quantity,
    required this.depApprovedHead,
    required this.depApprovedHeadDate,
    required this.depApprovedManager,
    required this.depApprovedManagerDate,
    this.poApprovedDate,
    this.poApproved,
    required this.deptQuantity,
    required this.deptQuantity2,
    required this.newPoQuantity,
    this.finalQty,
    this.remainingQty,
    required this.poRate,
    required this.poQuantity,
    required this.maxQuantity,
    this.splitQuantity,
    required this.unitMeasure,
    this.rejectReason,
    this.rejectReasonManager,
    this.rejectReasonPo,
    required this.requisitionActionSupervisor,
    required this.requisitionActionManager,
    required this.requisitionActionPo,
    required this.vendors,
    this.poRised,
    required this.productImage,
    required this.poGen,
  });

  factory PODetailsModel.fromJson(Map<String, dynamic> json) {
    return PODetailsModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      requisitionId: int.tryParse(json['requisition_id'].toString()) ?? 0,
      product: json['product'] ?? '',
      reqDate: json['req_date'] ?? '',
      poRes: json['po_res'] ?? '',
      reviewerValue: double.tryParse(json['reviewer_value'].toString()) ?? 0.0,
      approverValue: double.tryParse(json['approver_value'].toString()) ?? 0.0,
      poValue: double.tryParse(json['po_value'].toString()) ?? 0.0,
      value: double.tryParse(json['value'].toString()) ?? 0.0,
      rate: double.tryParse(json['rate'].toString()) ?? 0.0,
      gstAmount: double.tryParse(json['gst_amount'].toString()) ?? 0.0,
      gst: double.tryParse(json['gst'].toString()) ?? 0.0,
      cost: json['cost'] ?? '',
      prNo: json['pr_no'] ?? '',
      hsn: json['hsn'] ?? '',
      gl: json['gl'] ?? '',
      typeOfExpenses: json['type_of_expenses'] ?? '',
      prType: json['pr_type'] ?? '',
      closingQuantity: json['closing_quantity'] ?? '',
      description: json['description'] ?? '',
      discount: double.tryParse(json['discount'].toString()) ?? 0.0,
      discountAmount: json['discount_amount'] != null
          ? double.tryParse(json['discount_amount'].toString())
          : null,
      quantity: int.tryParse(json['quantity'].toString()) ?? 0,
      depApprovedHead: json['dep_approved_head'] ?? '',
      depApprovedHeadDate: json['dep_approved_head_date'] ?? '',
      depApprovedManager: json['dep_approved_manager'] ?? '',
      depApprovedManagerDate: json['dep_approved_manager_date'] ?? '',
      poApprovedDate: json['po_approved_date'],
      poApproved: json['po_approved'],
      deptQuantity: int.tryParse(json['dept_quantity'].toString()) ?? 0,
      deptQuantity2: json['dept_quantity2'] ?? '',
      newPoQuantity: int.tryParse(json['new_po_quantity'].toString()) ?? 0,
      finalQty: json['final_qty'] != null
          ? int.tryParse(json['final_qty'].toString())
          : null,
      remainingQty: json['remaining_qty'] != null
          ? int.tryParse(json['remaining_qty'].toString())
          : null,
      poRate: double.tryParse(json['po_rate'].toString()) ?? 0.0,
      poQuantity: int.tryParse(json['po_quantity'].toString()) ?? 0,
      maxQuantity: double.tryParse(json['max_quantity'].toString()) ?? 0.0,
      splitQuantity: json['split_quantity'] != null
          ? int.tryParse(json['split_quantity'].toString())
          : null,
      unitMeasure: json['unit_measure'] ?? '',
      rejectReason: json['reject_reason'],
      rejectReasonManager: json['reject_reason_manager'],
      rejectReasonPo: json['reject_reason_po'],
      requisitionActionSupervisor: json['requisition_action_supervisor'] ?? '',
      requisitionActionManager: json['requisition_action_manager'] ?? '',
      requisitionActionPo: json['requisition_action_po'] ?? '',
      vendors: json['vendors'] ?? '',
      poRised: json['po_rised'],

      // FIX: Handle both List<String> and single String case for productImage
      productImage: json['product_image'] is List
          ? List<String>.from(json['product_image'])
          : (json['product_image'] is String ? [json['product_image']] : []),

      poGen: json['po_gen'] ?? '',
    );
  }
}
