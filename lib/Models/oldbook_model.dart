class OldBookModel {
  final bool success;
  final String? oldBook;

  OldBookModel({required this.success, this.oldBook});

  factory OldBookModel.fromJson(Map<String, dynamic> json) {
    return OldBookModel(
      success: json['success'],
      oldBook: json['data']['old_book'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    if (this.oldBook != null) {
      data['old_book'] = this.oldBook;
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
