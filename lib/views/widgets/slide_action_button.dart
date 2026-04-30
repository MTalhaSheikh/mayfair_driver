import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:mayfair_driver/controllers/home_controller.dart';

import '../../core/app_colors.dart';
import '../../core/app_theme.dart';

class SlideActionButton extends StatefulWidget {
  final String label;
  final IconData leadingIcon;
  final VoidCallback onCompleted;
  final bool isLoading;

  const SlideActionButton({
    super.key,
    required this.label,
    required this.leadingIcon,
    required this.onCompleted,
    this.isLoading = false,
  });

  @override
  State<SlideActionButton> createState() => _SlideActionButtonState();
}

class _SlideActionButtonState extends State<SlideActionButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _anim;
  final HomeController homeController = Get.find<HomeController>();

  double _dragX = 0;
  double _maxDrag = 1;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _anim = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    )..addListener(() {
        setState(() {
          _dragX = _anim.value;
        });
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _animateTo(double value) {
    _controller.stop();
    _anim = Tween<double>(begin: _dragX, end: value).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller
      ..reset()
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const height = 64.0;
        const knobSize = 52.0;
        // _maxDrag = (constraints.maxWidth - knobSize).clamp(0, double.infinity);
        _maxDrag = (constraints.maxWidth - knobSize - 16).clamp(0.0, double.infinity);

        return Container(
          height: height,
          decoration: BoxDecoration(
            color: AppColors.portalOlive,
            borderRadius: BorderRadius.circular(36),
            boxShadow: const [
              BoxShadow(
                color: AppColors.softCardShadow,
                blurRadius: 24,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Center content: either loading indicator or label + chevrons
              if (widget.isLoading)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(width: 8),
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Updating status...',
                      style: AppTheme.buttonText.copyWith(fontSize: 16),
                    ),
                    const SizedBox(width: 8),
                  ],
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(width: 12),
                    const Icon(Icons.chevron_right, color: Colors.white70),
                    const Icon(Icons.chevron_right, color: Colors.white54),
                    const SizedBox(width: 10),
                    Text(widget.label, style: AppTheme.buttonText.copyWith(fontSize: 18)),
                    const SizedBox(width: 10),
                    const Icon(Icons.chevron_right, color: Colors.white54),
                    const Icon(Icons.chevron_right, color: Colors.white70),
                    const SizedBox(width: 12),
                  ],
                ),

              // draggable knob
              Positioned(
                left: _dragX,
                child: IgnorePointer(
                  ignoring: widget.isLoading,
                  child: GestureDetector(
                    onHorizontalDragUpdate: (details) {
                      setState(() {
                        _dragX = (_dragX + details.delta.dx).clamp(0, _maxDrag);
                      });
                    },
                    onHorizontalDragEnd: (_) async {
                      final reached = _dragX >= _maxDrag * 0.82;
                      if (reached) {
                        widget.onCompleted();
                        homeController.refreshTrips();
                        _animateTo(0);
                      } else {
                        _animateTo(0);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Container(
                        width: knobSize,
                        height: knobSize,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(widget.leadingIcon, color: AppColors.portalOlive),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

