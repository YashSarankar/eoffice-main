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
  String? letterContent;
  String? letterNo;
  String? dateOfGenerated;
  String? clerkSignature;
  String? hodSignature;
  String? ownerId;
  String? clerkOtp;
  String? hodOtp;
  String? hodOtpStatus;
  String? clerkOtpStatus;
  String? dateOfGeneratedClerk;
  String? frwdStaffId;
  String? frwdHodId;
  String? status;
  String? clerkVerifyStaff;
  String? hodVerifyStaff;
  String? rejectedBy;
  String? rejectDescription;
  String? clerkCreate;
  
  
  int? userId;

  Receipt({
    this.id,
    this.receiptNo,
    this.receiptChecklistId,
    this.subject,
    this.description,
    this.receiptStatus,
    this.receiptPdf,
    this.letterContent,
    this.letterNo,
    this.dateOfGenerated,
    this.clerkSignature,
    this.hodSignature,
    this.ownerId,
    this.clerkOtp,
    this.hodOtp,
    this.hodOtpStatus,
    this.clerkOtpStatus,
    this.dateOfGeneratedClerk,
    this.frwdStaffId,
    this.frwdHodId,
    this.status,
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
      letterContent: json['letter_content'],
      letterNo: json['letter_no'],
      dateOfGenerated: json['date_of_generated'],
      clerkSignature: json['clerk_signature'],
      hodSignature: json['hod_signature'],
      ownerId: json['owner_id'],
      clerkOtp: json['clerk_otp'],
      hodOtp: json['hod_otp'],
      hodOtpStatus: json['hod_otp_status'],
      clerkOtpStatus: json['clerk_otp_status'],
      dateOfGeneratedClerk: json['date_of_generated_clerk'],
      frwdStaffId: json['frwd_staff_id'],
      frwdHodId: json['frwd_hod_id'],
      status: json['status'],
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
    data['letter_content'] = this.letterContent;
    data['letter_no'] = this.letterNo;
    data['date_of_generated'] = this.dateOfGenerated;
    data['clerk_signature'] = this.clerkSignature;
    data['hod_signature'] = this.hodSignature;
    data['owner_id'] = this.ownerId;
    data['clerk_otp'] = this.clerkOtp;
    data['hod_otp'] = this.hodOtp;
    data['hod_otp_status'] = this.hodOtpStatus;
    data['clerk_otp_status'] = this.clerkOtpStatus;
    data['date_of_generated_clerk'] = this.dateOfGeneratedClerk;
    data['frwd_staff_id'] = this.frwdStaffId;
    data['frwd_hod_id'] = this.frwdHodId;
    data['status'] = this.status;
    
    return data;
  }
}
