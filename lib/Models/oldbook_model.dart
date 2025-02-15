class OldBookModel {
  bool? success;
  Data? data;

  OldBookModel({this.success, this.data});

  OldBookModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    data = json['data'] != null ? new Data.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class Data {
  String? oldBook;

  Data({this.oldBook});

  Data.fromJson(Map<String, dynamic> json) {
    oldBook = json['old_book'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['old_book'] = this.oldBook;
    return data;
  }
}
