import 'package:harrier_central/imports.dart';

/// Hand-rolled replacement for the retired `intro_slider` package: a plain
/// PageView with our own indicator dots and bottom button row, all inside a
/// SafeArea we control — immune to Android 15/16 edge-to-edge by
/// construction. State lives in [OnboardingFlowController].
class OnboardingFlowPage extends StatelessWidget {
  const OnboardingFlowPage({super.key});

  @override
  Widget build(BuildContext context) {
    final OnboardingFlowController c = Get.find<OnboardingFlowController>();

    return Obx(
      () => Scaffold(
        backgroundColor: c.activeSlide.backgroundColor,
        body: SafeArea(
          child: Column(
            children: <Widget>[
              Expanded(
                child: PageView.builder(
                  controller: c.pageController,
                  physics: c.physics,
                  itemCount: c.slides.length,
                  onPageChanged: c.onPageChanged,
                  itemBuilder: (BuildContext context, int index) =>
                      _OnboardingSlideView(slide: c.slides[index]),
                ),
              ),
              _BottomBar(controller: c),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingSlideView extends StatelessWidget {
  const _OnboardingSlideView({required this.slide});

  final OnboardingSlide slide;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Image.asset(
            slide.imagePath,
            height: slide.imageHeight * deviceInfo.deviceMaxScaleFactor,
          ),
          const SizedBox(height: 36),
          Text(
            slide.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: TextStyle(
              color: Colors.black,
              fontSize: 32.0 * deviceInfo.deviceWidthScaleFactor,
              fontFamily: 'AvenirNextRegular',
            ),
          ),
          const SizedBox(height: 20),
          Text(
            slide.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black,
              fontSize: 24.0 * deviceInfo.deviceWidthScaleFactor,
              fontFamily: 'AvenirNextRegular',
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.controller});

  final OnboardingFlowController controller;

  TextStyle get _navStyle => TextStyle(
        // White on the theme's red buttons (see CLAUDE.md button rule).
        color: Colors.white,
        fontSize: 18.0 * deviceInfo.deviceWidthScaleFactor,
        fontFamily: 'AvenirNextDemiBold',
      );

  @override
  Widget build(BuildContext context) {
    final OnboardingFlowController c = controller;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: c.onSkipPressed,
                child: Text('Skip', style: _navStyle),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List<Widget>.generate(
                c.slides.length,
                (int i) => Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: i == c.currentPage.value
                        ? themeAppBarBackground
                        : themeAppBarBackground40,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: c.onPrimaryPressed,
                child: Text(
                  c.isLastPage
                      ? 'OK'
                      : (c.activeSlide.isPermissionPage ? 'Allow' : 'Next'),
                  style: _navStyle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
