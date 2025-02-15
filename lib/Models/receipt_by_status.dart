// models/receipt_model.dart

class ReceiptByStatus {
  final bool success;
  final List<ReceiptTable> pendingReceipts;
  final List<ReceiptTable> approvedReceipts;
  final List<ReceiptTable> rejectedReceipts;

  ReceiptByStatus({
    required this.success,
    required this.pendingReceipts,
    required this.approvedReceipts,
    required this.rejectedReceipts,
  });

  factory ReceiptByStatus.fromJson(Map<String, dynamic> json) {
    return ReceiptByStatus(
      success: json['success'],
      pendingReceipts: List<ReceiptTable>.from(
          json['Pending_receipts'].map((data) => ReceiptTable.fromJson(data))),
      approvedReceipts: List<ReceiptTable>.from(
          json['Approved_receipts'].map((data) => ReceiptTable.fromJson(data))),
      rejectedReceipts: List<ReceiptTable>.from(
          json['Rejected_receipts'].map((data) => ReceiptTable.fromJson(data))),
    );
  }
}

class ReceiptTable {
  final int id;
  final String? receiptNo;
  final String receiptChecklistId;
  final String subject;
  final String description;
  final String receiptStatus;
  final String receiptPdf;
  final String createdAt;
  final String updatedAt;
  final int userId;
  final String letterContent;
  final String letterNo;
  final String dateOfGenerated;
  final String clerkSignature;
  final String hodSignature;

  ReceiptTable({
    required this.id,
    required this.receiptNo,
    required this.receiptChecklistId,
    required this.subject,
    required this.description,
    required this.receiptStatus,
    required this.receiptPdf,
    required this.createdAt,
    required this.updatedAt,
    required this.userId,
    required this.letterContent,
    required this.letterNo,
    required this.dateOfGenerated,
    required this.clerkSignature,
    required this.hodSignature,
  });

  factory ReceiptTable.fromJson(Map<String, dynamic> json) {
    return ReceiptTable(
      id: json['id']??0,
      receiptNo: json['receipt_no']??'',
      receiptChecklistId: json['receipt_checklist_id']??'',
      subject: json['subject']??'',
      description: json['description']??'',
      receiptStatus: json['receipt_status']??'',
      receiptPdf: json['receipt_pdf']??'',
      createdAt: json['created_at']??'',
      updatedAt: json['updated_at']??'',
      userId: json['user_id']??0,
      letterContent: json['letter_content']??'',
      letterNo: json['letter_no']??'',
      dateOfGenerated: json['date_of_generated']??'',
      clerkSignature: json['clerk_signature']??'',
      hodSignature: json['hod_signature']??'',
    );
  }
}
