
class LeaveCountResponse {
  final bool success;
  final LeaveData data;

  LeaveCountResponse({required this.success, required this.data});

  factory LeaveCountResponse.fromJson(Map<String, dynamic> json) {
    return LeaveCountResponse(
      success: json['success'],
      data: LeaveData.fromJson(json['data']),
    );
  }
}

class LeaveData {
  final Map<String, LeaveStatus> leaveStatusMap;

  LeaveData({required this.leaveStatusMap});

  factory LeaveData.fromJson(Map<String, dynamic> json) {
    Map<String, LeaveStatus> leaveStatusMap = {};
    json.forEach((key, value) {
      leaveStatusMap[key] = LeaveStatus.fromJson(value);
    });
    return LeaveData(leaveStatusMap: leaveStatusMap);
  }
}

class LeaveStatus {
  final int approved;
  final int pending;
  final int rejected;

  LeaveStatus({required this.approved, required this.pending, required this.rejected});

  factory LeaveStatus.fromJson(Map<String, dynamic> json) {
    return LeaveStatus(
      approved: json['Approved'],
      pending: json['Pending'],
      rejected: json['Rejected'],
    );
  }
}
