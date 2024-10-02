import 'package:flutter/material.dart';
import 'package:diplomovka/assets/colorsStyles/testStyles.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

class Reusablecomponents {
  // Function to create a custom slide transition
  static Route createRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0); // Slide from the right
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  static ButtonStyle elevatedButtonStyle({
    Color backgroundColor = Colors.white,
    EdgeInsetsGeometry padding =
        const EdgeInsets.symmetric(vertical: 24, horizontal: 64),
    double borderRadius = 12.0,
    double width = 327.0,
    double height = 54.0,
  }) {
    return ElevatedButton.styleFrom(
      padding: padding,
      backgroundColor: backgroundColor,
      minimumSize: Size(width, height),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    ).copyWith(
      alignment: Alignment.center,
      visualDensity: VisualDensity.compact,
    );
  }

  static Widget nextButton({
    required String text,
    required VoidCallback? onPressed,
    required TextStyle textStyle,
    double borderRadius = 12.0,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(vertical: 14),
    bool enabled = true,
    required AnimationController controller,
    required Animation<double> scaleAnimation,
    Color? backgroundColor,
    Color? disabledColor =
        Colors.transparent, // Default disabled background color
    Color? disabledTextColor =
        Colors.transparent, // Default disabled text color
  }) {
    return ScaleTransition(
      scale: scaleAnimation,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: enabled
                ? (backgroundColor ??
                    AppStyles.onBackground()) // Use backgroundColor if enabled
                : AppStyles
                    .disabledButtonBackground(), // Ensure full transparency when disabled
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: ElevatedButton(
            onPressed: enabled
                ? () {
                    HapticFeedback.lightImpact();
                    controller.forward().then((_) => controller.reverse());
                    if (onPressed != null) {
                      onPressed();
                    }
                  }
                : null,
            style: ElevatedButton.styleFrom(
              padding: padding,
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(borderRadius),
              ),
              foregroundColor: enabled
                  ? textStyle.color
                  : disabledTextColor, // Set text color based on enabled state
              disabledBackgroundColor: Colors.transparent,
              disabledForegroundColor: Colors.transparent,
              splashFactory: NoSplash.splashFactory, // Disable splash effect
            ).copyWith(
              overlayColor: WidgetStateProperty.all(
                  Colors.transparent), // Disable the highlight effect on press
            ),
            child: Text(
              text,
              style: textStyle.copyWith(
                color:
                    enabled ? textStyle.color : AppStyles.disabledButtonText(),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  static Widget iconTextButton({
    required String iconPath,
    required String text,
    required VoidCallback onPressed,
    required AnimationController controller,
    required Animation<double> scaleAnimation,
  }) {
    return ScaleTransition(
      scale: scaleAnimation,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: ElevatedButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            onPressed();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(
                color: Color(0xFFEFEFEF),
                width: 0,
              ),
            ),
            elevation: 4, // Shadow elevation
            shadowColor: const Color(0xFF9D9D9D).withOpacity(0.1),
            splashFactory: NoSplash.splashFactory,
          ).copyWith(
            overlayColor: WidgetStateProperty.all(Colors.transparent),
          ),
          child: Row(
            children: [
              SvgPicture.asset(
                iconPath,
                width: 24,
                height: 24,
              ),
              const SizedBox(width: 12),
              Text(
                text,
                style: AppStyles.labelMedium(color: AppStyles.onBackground()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget gradientText({
    required String text,
  }) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [Color(0xFF00B4DB), Color(0xFF2A96E3)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(bounds),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16.0,
          fontWeight: FontWeight.w700,
          height: 1,
          color: Colors.white,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  static AppBar buildAppBarWithProgress(
      BuildContext context, double previousValue, double currentValue,
      {List<Widget>? actions}) {
    return AppBar(
      backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      elevation: 0.0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      title: AnimatedAppBarWithProgress(
        previousValue: previousValue,
        currentValue: currentValue,
      ),
      actions: actions,
    );
  }

  static Widget coachHint(
      {required String text, required BuildContext context}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Row(
          children: [
            SizedBox(width: MediaQuery.of(context).size.width * 0.04),
            Expanded(
              child: Container(
                padding: EdgeInsets.only(
                  left: MediaQuery.of(context).size.width * 0.025,
                  right: MediaQuery.of(context).size.width * 0.025,
                  top: MediaQuery.of(context).size.height * 0.03,
                  bottom: MediaQuery.of(context).size.height * 0.03,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFEFEF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    SizedBox(width: MediaQuery.of(context).size.width * 0.25),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            text,
                            style: AppStyles.coachHint(
                                color: AppStyles.onBackground()),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: MediaQuery.of(context).size.width * 0.04),
          ],
        ),
        Positioned(
          top: -MediaQuery.of(context).size.height * 0.02,
          left: MediaQuery.of(context).size.width * 0.04,
          child: Image.asset(
            'lib/assets/images_videos/coachAge.png',
            width: MediaQuery.of(context).size.width * 0.245,
            height: MediaQuery.of(context).size.height * 0.145,
          ),
        ),
      ],
    );
  }
}

class AnimatedAppBarWithProgress extends StatefulWidget {
  final double previousValue;
  final double currentValue;

  const AnimatedAppBarWithProgress({
    super.key,
    required this.previousValue,
    required this.currentValue,
  });

  @override
  _AnimatedAppBarWithProgressState createState() =>
      _AnimatedAppBarWithProgressState();
}

class _AnimatedAppBarWithProgressState extends State<AnimatedAppBarWithProgress>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _progressAnimation = Tween<double>(
      begin: widget.previousValue,
      end: widget.currentValue,
    ).animate(_animationController)
      ..addListener(() {
        setState(() {});
      });

    Future.delayed(const Duration(seconds: 1), () {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double textWidth = 60;
    double actionsWidth = 60;
    double availableWidth = screenWidth - textWidth - actionsWidth - 32;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              "${(_progressAnimation.value * 100).toInt()}%",
              style: AppStyles.labelSmall(color: AppStyles.onBackground()),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(50.0),
              child: Container(
                height: 7.0,
                width: availableWidth,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50.0),
                  color: Colors.grey.shade300,
                ),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(50.0),
              child: Container(
                height: 7.0,
                width: availableWidth * _progressAnimation.value,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF00B4DB),
                      Color(0xFF2A96E3),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(50.0),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
