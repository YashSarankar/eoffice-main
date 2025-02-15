class GetReceiptResponse {
  bool? success;
  List<Receipt>? receipt;
  int? pendingReceipts;
  int? approvedReceipts;
  int? rejectedReceipts;

  GetReceiptResponse(
      {this.success,
      this.receipt,
      this.pendingReceipts,
      this.approvedReceipts,
      this.rejectedReceipts});

  GetReceiptResponse.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    if (json['data'] != null) {
      receipt = <Receipt>[];
      json['data'].forEach((v) {
        receipt!.add(new Receipt.fromJson(v));
      });
    }
    pendingReceipts = json['Pending_receipts']??0;
    approvedReceipts = json['Approved_receipts']??0;
    rejectedReceipts = json['Rejected_receipts']??0;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    if (this.receipt != null) {
      data['data'] = this.receipt!.map((v) => v.toJson()).toList();
    }
    data['Pending_receipts'] = this.pendingReceipts;
    data['Approved_receipts'] = this.approvedReceipts;
    data['Rejected_receipts'] = this.rejectedReceipts;
    return data;
  }
}

class Receipt {
  int? id;
  String? receiptNo;
  String? receiptChecklistId;
  String? subject;
  String? description;
  String? receiptStatus;
  String? receiptPdf;
  String? createdAt;
  String? updatedAt;
  int? userId;

  Receipt({
    this.id,
    this.receiptNo,
    this.receiptChecklistId,
    this.subject,
    this.description,
    this.receiptStatus,
    this.receiptPdf,
    this.createdAt,
    this.updatedAt,
    this.userId,
  });

  factory Receipt.fromJson(Map<String, dynamic> json) {
    return Receipt(
      id: json['id'],
      receiptNo: json['receipt_no'],
      receiptChecklistId: json['receipt_checklist_id'],
      subject: json['subject'],
      description: json['description'],
      receiptStatus: json['receipt_status'],
      receiptPdf: json['receipt_pdf'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      userId: json['user_id'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['receipt_no'] = this.receiptNo;
    data['receipt_checklist_id'] = this.receiptChecklistId;
    data['subject'] = this.subject;
    data['description'] = this.description;
    data['receipt_status'] = this.receiptStatus;
    data['receipt_pdf'] = this.receiptPdf;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    data['user_id'] = this.userId;
    return data;
  }
}
