class NominationModel {
  bool? success;
  String? message;
  Data? data;

  NominationModel({this.success, this.message, this.data});

  NominationModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    data = json['data'] != null ? new Data.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    data['message'] = this.message;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class Data {
  String? state;
  String? district;
  String? taluka;
  int? userId;
  String? position;
  String? birthDate;
  String? joinDate;
  String? nominationType;
  String? updatedAt;
  String? createdAt;
  int? id;

  Data(
      {this.state,
        this.district,
        this.taluka,
        this.userId,
        this.position,
        this.birthDate,
        this.joinDate,
        this.nominationType,
        this.updatedAt,
        this.createdAt,
        this.id});

  Data.fromJson(Map<String, dynamic> json) {
    state = json['state'];
    district = json['district'];
    taluka = json['taluka'];
    userId = json['user_id'];
    position = json['position'];
    birthDate = json['birth_date'];
    joinDate = json['join_date'];
    nominationType = json['nomination_type'];
    updatedAt = json['updated_at'];
    createdAt = json['created_at'];
    id = json['id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['state'] = this.state;
    data['district'] = this.district;
    data['taluka'] = this.taluka;
    data['user_id'] = this.userId;
    data['position'] = this.position;
    data['birth_date'] = this.birthDate;
    data['join_date'] = this.joinDate;
    data['nomination_type'] = this.nominationType;
    data['updated_at'] = this.updatedAt;
    data['created_at'] = this.createdAt;
    data['id'] = this.id;
    return data;
  }
}
