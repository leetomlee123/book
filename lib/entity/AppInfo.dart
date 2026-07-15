class AppInfo {
  String id;
  String msg;
  String link;
  String version;
  String forceUpdate;
  String apkMD5;
  String apkSize;

  AppInfo(
      {this.id = '',
      this.msg = '',
      this.link = '',
      this.version = '',
      this.forceUpdate = '',
      this.apkMD5 = '',
      this.apkSize = ''});

  AppInfo.fromJson(Map<String, dynamic> json)
      : id = json['id'] as String? ?? '',
        msg = json['msg'] as String? ?? '',
        link = json['link'] as String? ?? '',
        version = json['version'] as String? ?? '',
        forceUpdate = json['forceUpdate'] as String? ?? '',
        apkMD5 = json['apkMD5'] as String? ?? '',
        apkSize = json['apkSize'] as String? ?? '';

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['msg'] = msg;
    data['link'] = link;
    data['version'] = version;
    data['forceUpdate'] = forceUpdate;
    data['apkMD5'] = apkMD5;
    data['apkSize'] = apkSize;
    return data;
  }
}
