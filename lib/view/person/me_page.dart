import 'package:book/common/read_setting.dart';
import 'package:book/common/app_colors.dart';
import 'package:book/common/local_account.dart';
import 'package:book/common/local_store.dart';
import 'package:book/main.dart';
import 'package:book/route/routes.dart';
import 'package:book/service/app_update_service.dart';
import 'package:book/service/tel_and_sms_service.dart';
import 'package:book/store/providers.dart';
import 'package:book/view/person/info_page.dart';
import 'package:book/view/person/skin_page.dart';
import 'package:book/view/person/yckceo_source_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:book/common/common.dart';

/// 「我的」页（微信读书风格）
class Me extends ConsumerWidget {
  /// Hosted inside MainShell bottom tab.
  final bool embedded;

  const Me({this.embedded = false, super.key});

  bool get _dark => SpUtil.getBool(PrefsKeys.dark);

  Color get _scaffold => _dark ? AppColors.scaffoldDark : AppColors.scaffold;
  Color get _surface => _dark ? AppColors.surfaceDark : AppColors.surface;
  Color get _primary => _dark ? AppColors.textOnDark : AppColors.textPrimary;
  Color get _secondary => AppColors.textSecondary;
  Color get _divider => _dark ? AppColors.dividerDark : AppColors.divider;
  Color get _iconBg =>
      _dark ? const Color(0xFF2A2A2A) : const Color(0xFFF3F3F3);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topPad = embedded
        ? MediaQuery.of(context).padding.top + 8
        : MediaQuery.of(context).padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _scaffold,
        body: Column(
          children: [
            SizedBox(height: topPad),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  _profileCard(context),
                  const SizedBox(height: 16),
                  _sectionCard([
                    _tile(
                      context: context,
                      icon: Icons.campaign_outlined,
                      title: '公告',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => InfoPage()),
                        );
                      },
                    ),
                    _tile(
                      context: context,
                      icon: Icons.gavel_outlined,
                      title: '免责声明',
                      onTap: () => _showLaw(context),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  _sectionCard([
                    _tile(
                      context: context,
                      icon: Icons.library_books_outlined,
                      title: '书源管理',
                      onTap: () =>
                          Routes.navigateTo(context, Routes.sources),
                    ),
                    _tile(
                      context: context,
                      icon: Icons.storefront_outlined,
                      title: '源仓库',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const YckceoSourcePage(),
                          ),
                        );
                      },
                    ),
                    _tile(
                      context: context,
                      icon: Icons.palette_outlined,
                      title: '主题',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => Skin()),
                        );
                      },
                    ),
                    _tile(
                      context: context,
                      icon: Icons.article_outlined,
                      title: '运行日志',
                      onTap: () => Routes.navigateTo(context, Routes.logs),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  _sectionCard([
                    _tile(
                      context: context,
                      icon: Icons.mail_outline,
                      title: '意见反馈',
                      onTap: () {
                        locator<TelAndSmsService>()
                            .sendEmail('leetomlee123@gmail.com');
                      },
                    ),
                    _tile(
                      context: context,
                      icon: Icons.code,
                      title: '开源地址',
                      onTap: () {
                        launchUrl(
                          Uri.parse('https://github.com/leetomlee123/book'),
                        );
                      },
                    ),
                    _tile(
                      context: context,
                      icon: Icons.system_update_alt,
                      title: '应用更新',
                      onTap: () {
                        AppUpdateService.instance.checkUpdate(context);
                      },
                    ),
                    _tile(
                      context: context,
                      icon: Icons.info_outline,
                      title: '关于',
                      onTap: () => _showAbout(context),
                      showDivider: false,
                    ),
                  ]),
                  if (LocalAccount.isLoggedIn) ...[
                    const SizedBox(height: 20),
                    _logoutButton(ref),
                  ],
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      '爱看书  ·  ${SpUtil.getString(PrefsKeys.version, defValue: "")}',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Profile
  // ---------------------------------------------------------------------------

  Widget _profileCard(BuildContext context) {
    final login = LocalAccount.isLoggedIn;
    return Material(
      color: _surface,
      borderRadius: BorderRadius.circular(AppDimens.cardRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDimens.cardRadius),
        onTap: login
            ? null
            : () => Routes.navigateTo(context, Routes.login),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: AppShadows.softBar,
                ),
                child: CircleAvatar(
                  radius: 28,
                  backgroundImage: const AssetImage('images/fu.png'),
                  backgroundColor: _iconBg,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: login
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            LocalAccount.username,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: _primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            LocalAccount.email.isEmpty
                                ? '本地账号'
                                : LocalAccount.email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: _secondary,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '登录 / 注册',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: _primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '本地账号 · 进度保存在本机',
                            style: TextStyle(
                              fontSize: 13,
                              color: _secondary,
                            ),
                          ),
                        ],
                      ),
              ),
              if (!login)
                Icon(Icons.chevron_right, color: _secondary, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Section / tile
  // ---------------------------------------------------------------------------

  Widget _sectionCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(AppDimens.cardRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }

  Widget _tile({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: _iconBg,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(
                      icon,
                      size: 18,
                      color: AppColors.accentOf(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: _primary,
                          ),
                        ),
                        if (subtitle != null && subtitle.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: _secondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 20, color: _secondary),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 60,
            color: _divider,
          ),
      ],
    );
  }

  Widget _logoutButton(WidgetRef ref) {
    return Material(
      color: _surface,
      borderRadius: BorderRadius.circular(AppDimens.cardRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDimens.cardRadius),
        onTap: () async {
          LocalAccount.logout();
          await ref.read(shelfModelProvider).dropAccountOut();
        },
        child: Container(
          height: 48,
          alignment: Alignment.center,
          child: const Text(
            '退出登录',
            style: TextStyle(
              color: AppColors.danger,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Dialogs
  // ---------------------------------------------------------------------------

  void _showLaw(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('免责声明'),
        content: SingleChildScrollView(
          child: Text(ReadSetting.lawWarn),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('爱看书 V${SpUtil.getString(PrefsKeys.version)}'),
        content: Text(
          ReadSetting.poet,
          style: const TextStyle(fontSize: 15, height: 2.1),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}
