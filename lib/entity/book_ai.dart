/// Id : "60d7702a10daf383fa5cb726"
/// Name : "大唐之神级太子"
/// Author : "剑诛仙"

class BookAi {
  String _id;
  String _name;
  String _author;

  String get id => _id;
  String get name => _name;
  String get author => _author;

  BookAi({
      String id, 
      String name, 
      String author}){
    _id = id;
    _name = name;
    _author = author;
}

  BookAi.fromJson(dynamic json) {
    _id = json["Id"];
    _name = json["Name"];
    _author = json["Author"];
  }

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    map["Id"] = _id;
    map["Name"] = _name;
    map["Author"] = _author;
    return map;
  }

}