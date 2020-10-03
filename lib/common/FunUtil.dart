import 'package:book/common/DbHelper.dart';
import 'package:book/entity/MRecords.dart';

class FunUtil {
  static saveMoviesRecord(
      var cover, var name, var cid, var cname, var list) async {
    var dbHelper = DbHelper();

    List<MRecords> mrds = await dbHelper.getMovies();

    MRecords mRecords = MRecords(cover, name, cid, cname, list);
    if (!mrds.contains(mRecords)) {
      dbHelper.addMovies([mRecords]);
    }
    await dbHelper.close();
  }
}
