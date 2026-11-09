import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

late AppSettings settings;

class AppSettings extends ChangeNotifier {
  SharedPreferences preferences;

  AppSettings(this.preferences);

  bool get isDark => preferences.getBool('darkMode') ?? false;
  bool get onboarded => preferences.getBool('onboarding') ?? false;
  String get language => preferences.getString('language') ?? 'en';

  Future<void> changeTheme(bool isDark) async {
    await preferences.setBool('darkMode', isDark);
    notifyListeners();
  }

  Future<void> changeLanguage(String language) async {
    await preferences.setString('language', language);
    notifyListeners();
  }

  Future<void> finishOnboarding() async {
    await preferences.setBool('onboarding', true);
    notifyListeners();
  }
}

String label(BuildContext context, String english, String arabic) {
  return Localizations.localeOf(context).languageCode == 'ar'
      ? arabic
      : english;
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  var pageController = PageController();
  int page = 0;

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var titles = [
      label(context, 'Find Events That Inspire You', 'اكتشف فعاليات تلهمك'),
      label(context, 'Effortless Event Planning', 'خطط لفعالياتك بسهولة'),
      label(
        context,
        'Connect with Friends & Share Moments',
        'تواصل مع أصدقائك وشارك اللحظات',
      ),
    ];
    var descriptions = [
      label(
        context,
        'Discover events that match your interests, from live music to workshops and more.',
        'اكتشف فعاليات تناسب اهتماماتك، من الموسيقى الحية إلى ورش العمل وغيرها.',
      ),
      label(
        context,
        'Keep track of dates and details so planning your next event is easy.',
        'تابع المواعيد والتفاصيل لتخطط لفعاليتك القادمة بسهولة.',
      ),
      label(
        context,
        'Invite your friends to events and share memorable experiences together.',
        'ادعُ أصدقاءك إلى الفعاليات وشاركهم تجارب لا تُنسى.',
      ),
    ];
    var pictures = [
      'assets/images/onboarding_discovery.png',
      'assets/images/onboarding_planning.png',
      'assets/images/onboarding_sharing.png',
    ];
    var blue = Theme.of(context).colorScheme.primary;
    var duration = const Duration(milliseconds: 300);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: page == 0
            ? null
            : IconButton(
                tooltip: label(context, 'Back', 'رجوع'),
                onPressed: () => pageController.previousPage(
                  duration: duration,
                  curve: Curves.easeInOut,
                ),
                icon: const BackButtonIcon(),
              ),
        title: Image.asset(
          'assets/images/evently_logo.png',
          width: 120,
          color: blue,
        ),
        actions: [
          if (page < titles.length - 1)
            TextButton(
              onPressed: settings.finishOnboarding,
              child: Text(label(context, 'Skip', 'تخطي')),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: pageController,
                itemCount: titles.length,
                onPageChanged: (index) => setState(() => page = index),
                itemBuilder: (context, index) => ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Image.asset(pictures[index], height: 250),
                    const SizedBox(height: 24),
                    Text(
                      titles[index],
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(descriptions[index]),
                  ],
                ),
              ),
            ),
            SmoothPageIndicator(
              controller: pageController,
              count: titles.length,
              effect: ExpandingDotsEffect(
                activeDotColor: blue,
                dotHeight: 7,
                dotWidth: 7,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    if (page == titles.length - 1) {
                      settings.finishOnboarding();
                    } else {
                      pageController.nextPage(
                        duration: duration,
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  child: Text(
                    page == titles.length - 1
                        ? label(context, 'Get started', 'ابدأ')
                        : label(context, 'Next', 'التالي'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
