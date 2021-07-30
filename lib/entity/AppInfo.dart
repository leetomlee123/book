class AppInfo {
  String id;
  String msg;
  String link;
  String version;
  String forceUpdate;
  String apkMD5;
  String apkSize;

  AppInfo(
      {this.id,
      this.msg,
      this.link,
      this.version,
      this.forceUpdate,
      this.apkMD5,
      this.apkSize});

  AppInfo.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    msg = json['msg'];
    link = json['link'];
    version = json['version'];
    forceUpdate = json['forceUpdate'];
    apkMD5 = json['apkMD5'];
    apkSize = json['apkSize'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['msg'] = this.msg;
    data['link'] = this.link;
    data['version'] = this.version;
    data['forceUpdate'] = this.forceUpdate;
    data['apkMD5'] = this.apkMD5;
    data['apkSize'] = this.apkSize;
    return data;
  }
}
