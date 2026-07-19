/// Id : "60d7702a10daf383fa5cb726"
/// Name : "大唐之神级太子"
/// Author : "剑诛仙"
library;

class BookAi {
  final String _id;
  final String _name;
  final String _author;

  String get id => _id;
  String get name => _name;
  String get author => _author;

  BookAi({
    this._id = '',
    this._name = '',
    this._author = '',
  });

  BookAi.fromJson(dynamic json)
      : _id = json["Id"] as String? ?? '',
        _name = json["Name"] as String? ?? '',
        _author = json["Author"] as String? ?? '';

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    map["Id"] = _id;
    map["Name"] = _name;
    map["Author"] = _author;
    return map;
  }
}
