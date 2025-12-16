import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:task_paven/ui/pages/home_page.dart';
import 'package:task_paven/ui/theme.dart';
import 'package:flutter_svg/flutter_svg.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  final _settingsBox = GetStorage();

  int _currentPage = 0;

  final List<_OnboardingStep> _steps = const [
    _OnboardingStep(
      titleKey: 'onboarding_plan_title',
      descriptionKey: 'onboarding_plan_desc',
      assetPath: 'images/list.png',
    ),
    _OnboardingStep(
      titleKey: 'onboarding_focus_title',
      descriptionKey: 'onboarding_focus_desc',
      assetPath: 'images/chatbot.png',
    ),
    _OnboardingStep(
      titleKey: 'onboarding_progress_title',
      descriptionKey: 'onboarding_progress_desc',
      assetPath: 'images/process.png',
    ),
  ];

  bool get _isLastPage => _currentPage == _steps.length - 1;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.colorScheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _completeOnboarding,
                      child: Text(
                        'onboarding_skip'.tr,
                        style: TextStyle(
                          color: Get.isDarkMode ? Colors.white70 : darkGreyClr,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _steps.length,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        final step = _steps[index];
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: 260,
                          child: _OnboardingAsset(
                                assetPath: step.assetPath,
                                semanticsLabel: step.titleKey.tr,
                              ),
                            ),
                            const SizedBox(height: 36),
                            Text(
                              step.titleKey.tr,
                              textAlign: TextAlign.center,
                              style: headingStyle,
                            ),
                            const SizedBox(height: 14),
                            Text(
                              step.descriptionKey.tr,
                              textAlign: TextAlign.center,
                              style: bodyStyle.copyWith(
                                color: Get.isDarkMode
                                    ? Colors.white70
                                    : Colors.grey.shade700,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _steps.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 10,
                        width: _currentPage == index ? 26 : 12,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? primaryClr
                              : (Get.isDarkMode
                                  ? Colors.white24
                                  : Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryClr,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _isLastPage ? _completeOnboarding : _goToNextPage,
                      child: Text(
                        _isLastPage
                            ? 'onboarding_get_started'.tr
                            : 'onboarding_next'.tr,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _goToNextPage() async {
    await _pageController.nextPage(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _completeOnboarding() async {
    await _settingsBox.write('onboarding_completed', true);
    Get.offAll(() => const HomePage());
  }
}

class _OnboardingStep {
  final String titleKey;
  final String descriptionKey;
  final String assetPath;

  const _OnboardingStep({
    required this.titleKey,
    required this.descriptionKey,
    required this.assetPath,
  });
}

class _OnboardingAsset extends StatelessWidget {
  final String assetPath;
  final String semanticsLabel;

  const _OnboardingAsset({
    required this.assetPath,
    required this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    if (assetPath.toLowerCase().endsWith('.svg')) {
      return SvgPicture.asset(
        assetPath,
        semanticsLabel: semanticsLabel,
      );
    }

    return Image.asset(
      assetPath,
      fit: BoxFit.contain,
      semanticLabel: semanticsLabel,
    );
  }
}
