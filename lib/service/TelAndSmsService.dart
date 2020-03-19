import 'package:get_it/get_it.dart';
import 'package:url_launcher/url_launcher.dart';

class TelAndSmsService {

  void call(String number) => launch("tel:$number");
  void sendSms(String number) => launch("sms:$number");
  void sendEmail(String email) => launch("mailto:$email");
}


