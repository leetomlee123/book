class Common {
  static String imgPre =
      "https://appbdimg.cdn.bcebos.com/BookFiles/BookImages/";

//   static String domain = "http://120.27.244.128:8083/v1";
//  static String domain = "http://192.168.0.107:8081/v1";
//  static String domain = "http://192.168.0.107:8081/v1";
//  static String domain = "https://book.leetomlee.xyz/v1";
//
  static String domain = "http://23.91.100.230:8090/book/v1";
//  static String domain = "https://newbook.leetomlee.xyz/v1";
//  static String video_domain = "http://192.168.0.107:8082";
  static String video_domain = "http://23.91.100.230:8090/movie";
//  static String video_domain = "https://movie.leetomlee.xyz";

//static String domain = "https://book.leetomlee.xyz/v1";

//  static String domain = "http://192.168.3.56:8000/v1";
  static String login = domain + "/login";
  static String freshToken = domain + "/book/freshToken";
  static String info = domain + '/info';
  static String modifypassword = domain + "/password";
  static String register = domain + "/register";
  static String hot = domain + '/hot';
  static String detail = domain + "/book/detail";
  static String shelf = domain + "/book/shelf";
  static String rank = domain + "/book/rank";
//  static String search = video_domain + "/book/search";
  static String two = domain + "/book/two";

  static String search = domain + "/book/search";
  static String bookInfo = domain + "/book/info/";
  static String chaptersUrl = domain + "/book/chapters";
  static String bookContentUrl = domain + '/book/chapter';
  static String reload = domain + '/book/chapter';
  static String bookAction = domain + '/book/action';
  static String process = domain + '/book/process';
  static String page_height_pre = "php";

  static String listbookname = "booklist";
  static String toplist = "toplist";
  static String downloadlist = "downloadlist";

//  static String video_domain = "http://192.168.3.56:8082";

  static String index = video_domain + '/index';
  static String m_detail = video_domain + '/movies';
  static String look_m = video_domain + '/movies/tv/';
  static String cache_index = "movie_cache_index";
  static String tag_movies = video_domain + "/movies/category";
  static String movie_hot = video_domain + "/hot";
  static String movie_search = video_domain + "/movies";

  static String movies_record = "movies_record";
  static String book_search_history = "book_search_history";
  static String movie_search_history = "movie_search_history";
  static String notice_info = "notice_info";
  static String reading_style = "READINGSTYLE";
}
