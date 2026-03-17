import 'package:hcportal/imports.dart';

class TabPageStandardLayout extends StatefulWidget {
  const TabPageStandardLayout({
    required this.child,
    required this.title,
    required this.tabLocked,
    required this.icon,
    required this.description,
    required this.formController,
    this.showCloseTabGroupButton = false,
    this.handlesOwnScrolling = false,
    this.contentPadding,
    this.dividerRightPadding = 20.0,
    super.key,
  });
  final Widget child;
  final Rx<TabLocked> tabLocked;
  final String title;
  final IconData icon;
  final String description;
  final TabUiController formController;
  final bool showCloseTabGroupButton;

  /// If true, the child widget handles its own scrolling and won't be wrapped
  /// in a SingleChildScrollView.
  final bool handlesOwnScrolling;

  /// Custom padding for the content area. If null, uses default EdgeInsets.all(16).
  final EdgeInsetsGeometry? contentPadding;

  /// Right padding between the sidebar divider and content. Defaults to 20.
  final double dividerRightPadding;

  @override
  TabPageStandardLayoutState createState() => TabPageStandardLayoutState();
}

class TabPageStandardLayoutState extends State<TabPageStandardLayout>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    //final scaffoldState = Scaffold.of(context); // Example of using context

    //printwidget.formController.screenSize);
    return Obx(
      () => Row(
        children: [
          if ((widget.formController.screenSize.value ==
              EScreenSize.isNormalScreen)) ...<Widget>[
            Container(
              width: SIDEBAR_WIDTH,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Expanded(
                    child: ClipRect(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        //crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Obx(
                            () => Icon(
                              widget.formController.sidebarIcon.value ??
                                  widget.icon,
                              size: 75,
                              color: Colors.blueAccent,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Obx(
                            () => Text(
                              widget.formController.sidebarTitle.value ??
                                  widget.title,
                              textAlign: TextAlign.center,
                              style: titleStyleBlack,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Obx(
                            () => Text(
                              widget.formController.sidebarDescription.value ??
                                  widget.description,
                              textAlign: TextAlign.center,
                              style: bodyStyleBlack,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                  Obx(
                    () => Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _ModernActionButton(
                          label: 'Save',
                          icon: Icons.save_rounded,
                          onPressed: (widget.formController.isFormDirty.value &&
                                  widget.formController.allFieldsAreValid.value)
                              ? () async {
                                  await widget.formController.save(true);
                                }
                              : null,
                          activeColor: Colors.green.shade600,
                        ),
                        const SizedBox(width: 12),
                        _ModernActionButton(
                          label: 'Undo',
                          icon: Icons.undo_rounded,
                          onPressed: (widget.formController.isFormDirty.value ||
                                  !widget
                                      .formController.allFieldsAreValid.value)
                              ? widget.formController.undoChanges
                              : null,
                          activeColor: Colors.red.shade600,
                        ),
                      ],
                    ),
                  ),
                  // if ((widget.showCloseTabGroupButton) &&
                  //     (widget.formController.close != null)) ...<Widget>[
                  //   const SizedBox(height: 15),
                  //   ElevatedButton(
                  //     style: defaultButtonStyle,
                  //     //onPressed: widget.formController.close,
                  //     onPressed: () {},
                  //     child: Text(
                  //       'Close Application',
                  //       style: buttonLabelStyleMedium,
                  //     ),
                  //   ),
                  // ],
                  const SizedBox(height: 15),
                  Text(
                    'Version: ${packageInfo.value?.version ?? '<unknown>'}',
                    style: footnoteSmall.copyWith(
                      color: Colors.black.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
          Padding(
            padding: EdgeInsets.only(
              top: 15,
              bottom: 15,
              right: widget.dividerRightPadding,
            ),
            child: const VerticalDivider(
              thickness: 2,
              width: 2,
            ),
          ),
          Expanded(
              child: pageFrame(
            screenSize: widget.formController.screenSize,
            child: widget.child,
            isFormDirty: widget.formController.isFormDirty,
            allFieldsAreValid: widget.formController.allFieldsAreValid,
            onBack: () => widget.formController.tabController.index--,
            onNext: () => widget.formController.tabController.index++,
            onSave: widget.formController.save,
            onUndo: widget.formController.undoChanges,
            handlesOwnScrolling: widget.handlesOwnScrolling,
            contentPadding: widget.contentPadding,
          )),
        ],
      ),
    );
  }

  Widget pageFrame({
    required Rx<EScreenSize> screenSize,
    required RxBool isFormDirty,
    required Widget child,
    RxBool? allFieldsAreValid,
    void Function()? onBack,
    void Function()? onNext,
    void Function(bool showDialog)? onSave,
    void Function()? onUndo,
    bool isFirstPage = false,
    bool isLastPage = false,
    bool handlesOwnScrolling = false,
    EdgeInsetsGeometry? contentPadding,
  }) {
    return Obx(() {
      final isNarrowOrMobile =
          (screenSize.value == EScreenSize.isNarrowScreen) ||
              (screenSize.value == EScreenSize.isMobileScreen);

      // Build the content area - either scrollable or as-is
      final contentWidget = handlesOwnScrolling
          ? Expanded(child: child)
          : Expanded(child: SingleChildScrollView(child: child));

      return Padding(
        padding: contentPadding ?? const EdgeInsets.all(16),
        child: Column(
          children: [
            contentWidget,
            // Spacing between content and buttons
            const SizedBox(height: 16),
            // Modern button bar
            _buildModernButtonBar(
              isNarrowOrMobile: isNarrowOrMobile,
              isFormDirty: isFormDirty.value,
              allFieldsAreValid: allFieldsAreValid?.value ?? true,
              onBack: onBack,
              onNext: onNext,
              onSave: onSave,
              onUndo: onUndo,
              isFirstPage: isFirstPage,
              isLastPage: isLastPage,
            ),
          ],
        ),
      );
    });
  }

  /// Builds a modern button bar with improved styling.
  Widget _buildModernButtonBar({
    required bool isNarrowOrMobile,
    required bool isFormDirty,
    bool allFieldsAreValid = true,
    void Function()? onBack,
    void Function()? onNext,
    void Function(bool showDialog)? onSave,
    void Function()? onUndo,
    bool isFirstPage = false,
    bool isLastPage = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          if (!isFirstPage)
            _ModernNavButton(
              label: 'Back',
              icon: Icons.arrow_back_rounded,
              onPressed: onBack,
              isBack: true,
            )
          else
            const SizedBox(width: 80),

          // Center buttons (Undo/Save) - only on narrow/mobile
          if (isNarrowOrMobile)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ModernActionButton(
                  label: 'Undo',
                  icon: Icons.undo_rounded,
                  onPressed:
                      (isFormDirty || !allFieldsAreValid) ? onUndo : null,
                  activeColor: Colors.red.shade600,
                ),
                const SizedBox(width: 12),
                _ModernActionButton(
                  label: 'Save',
                  icon: Icons.save_rounded,
                  onPressed: (isFormDirty && allFieldsAreValid)
                      ? () => onSave!(true)
                      : null,
                  activeColor: Colors.green.shade600,
                ),
              ],
            )
          else
            const Spacer(),

          // Next button
          if (!isLastPage)
            _ModernNavButton(
              label: 'Next',
              icon: Icons.arrow_forward_rounded,
              onPressed: onNext,
              isBack: false,
            )
          else
            const SizedBox(width: 80),
        ],
      ),
    );
  }
}

/// Modern navigation button (Back/Next).
class _ModernNavButton extends StatelessWidget {
  const _ModernNavButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.isBack,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isBack;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.blue.shade600,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isBack) ...[
                Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (!isBack) ...[
                const SizedBox(width: 8),
                Icon(icon, color: Colors.white, size: 18),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Modern action button (Undo/Save).
class _ModernActionButton extends StatelessWidget {
  const _ModernActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.activeColor,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? activeColor;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;
    final color = isEnabled
        ? (activeColor ?? Colors.grey.shade700)
        : Colors.grey.shade400;
    final borderColor = isEnabled
        ? (activeColor ?? Colors.grey.shade400)
        : Colors.grey.shade300;

    return Material(
      color: isEnabled ? color.withOpacity(0.1) : Colors.grey.shade100,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: borderColor,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
