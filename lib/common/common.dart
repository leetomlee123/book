class Common {
//
//   static String domain = "http://192.168.0.109:8011/v1";
  static String domain = "http://134.175.83.19:8011/v1";

//  static String domain = "https://newbook.leetomlee.xyz/v1";
  static String video_domain = "http://134.175.83.19:8012";

  static String login = domain + "/login";
  static String gitHubLogin = domain + "/oauth/redirect";
  static String freshToken = domain + "/book/freshToken";
  static String info = domain + '/info';
  static String modifypassword = domain + "/password";
  static String register = domain + "/register";
  static String update = domain + "/update";
  static String hot = domain + '/hot';
  static String detail = domain + "/book/detail";
  static String shelf = domain + "/book/shelf";
  static String rank = domain + "/book/rank";
  static String config = domain + "/book/config";

//  static String search = video_domain + "/book/search";
  static String two = domain + "/book/two";

  static String search = domain + "/book/search";
  static String searchAi = domain + "/book/searchAi";
  static String bookInfo = domain + "/book/info/";
  static String chaptersUrl = domain + "/book/proto/chapters";
  static String bookContentUrl = domain + '/book/chapter';
  static String bookContentUpload = domain + '/book/chapter/content';
  static String reload = domain + '/book/chapter';
  static String bookAction = domain + '/book/action';
  static String process = domain + '/book/process';
  static String page_height_pre = "php";

  static String listbookname = "booklist";
  static String toplist = "toplist";
  static String downloadlist = "downloadlist";
  static String bgIdx = "bgIdx";
  static String turnPageAnima = "turnPageAnima";

//  static String video_domain = "http://192.168.3.56:8082";

  static String index = video_domain + '/index';
  static String voiceIndex = video_domain + '/voice/index';
  static String voiceDetail = video_domain + '/voice/detail';
  static String voiceMore = video_domain + '/voice/more';
  static String voiceSearch = video_domain + '/voice/search';
  static String voiceUrl = video_domain + '/voice';
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
  static String parse_html_config = "parse_html_config";
  static String fonts = "fonts";
  static String book_pic_width = "book_pic_width";
}
