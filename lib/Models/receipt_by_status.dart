// models/receipt_model.dart

class ReceiptByStatus {
  final bool? success;
  final List<ReceiptTable> pendingReceipts;
  final List<ReceiptTable> approvedReceipts;
  final List<ReceiptTable> rejectedReceipts;

  ReceiptByStatus({
    this.success,
    List<ReceiptTable>? pendingReceipts,
    List<ReceiptTable>? approvedReceipts,
    List<ReceiptTable>? rejectedReceipts,
  })  : pendingReceipts = pendingReceipts ?? [],
        approvedReceipts = approvedReceipts ?? [],
        rejectedReceipts = rejectedReceipts ?? [];

  factory ReceiptByStatus.fromJson(Map<String, dynamic> json) {
    return ReceiptByStatus(
      success: json['success'],
      pendingReceipts: (json['Pending_receipts'] as List<dynamic>?)
          ?.map((data) => ReceiptTable.fromJson(data))
          .toList(),
      approvedReceipts: (json['Approved_receipts'] as List<dynamic>?)
          ?.map((data) => ReceiptTable.fromJson(data))
          .toList(),
      rejectedReceipts: (json['Rejected_receipts'] as List<dynamic>?)
          ?.map((data) => ReceiptTable.fromJson(data))
          .toList(),
    );
  }
}

class ReceiptTable {
  final int? id;
  final String? receiptNo;
  final String? receiptChecklistId;
  final String? subject;
  final String? description;
  final String? receiptStatus;
  final String? receiptPdf;
  final String? letterNo;
  final String? dateOfGenerated;
  final String? createdAt;
  final String? updatedAt;
  final int? userId;
  final String? status;


  ReceiptTable({
    this.id,
    this.receiptNo,
    this.receiptChecklistId,
    this.subject,
    this.description,
    this.letterNo,
    this.dateOfGenerated,
    this.receiptStatus,
    this.receiptPdf,
    this.createdAt,
    this.updatedAt,
    this.userId,
    this.status,
  });

  factory ReceiptTable.fromJson(Map<String, dynamic> json) {
    return ReceiptTable(
      id: json['id'],
      receiptNo: json['receipt_no'],
      receiptChecklistId: json['receipt_checklist_id'],
      subject: json['subject'],
      description: json['description'],
      receiptStatus: json['receipt_status'],
      receiptPdf: json['receipt_pdf'],
      letterNo: json['letter_no'],
      dateOfGenerated: json['date_of_generated'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      userId: json['user_id'],
      status: json['status'],
    );
  }
}
