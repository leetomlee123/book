import 'package:book/common/DbHelper.dart';
import 'package:book/entity/MRecords.dart';

class FunUtil {
  static saveMoviesRecord(
      var cover, var name, var cid, var cname, var list) async {
    List<MRecords> mrds = await DbHelper.instance.getMovies();

    MRecords mRecords = MRecords(cover, name, cid, cname, list);
    if (!mrds.contains(mRecords)) {
      DbHelper.instance.addMovies([mRecords]);
    }
    // await dbHelper.closeMovie();
  }
}
