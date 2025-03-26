import 'package:flutter/material.dart';

enum SnackbarType { success, error, info }

class animatedSnackbar extends StatefulWidget {
  final String message;
  final SnackbarType type;
  final int duration;
  final VoidCallback? onClose;

  const animatedSnackbar({
    Key? key,
    required this.message,
    this.type = SnackbarType.info,
    this.duration = 3000,
    this.onClose,
  }) : super(key: key);

  // Static method to show the snackbar
  static void show({
    required BuildContext context,
    required String message,
    SnackbarType type = SnackbarType.info,
    int duration = 1500,
    VoidCallback? onClose,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) {
        return animatedSnackbar(
          message: message,
          type: type,
          duration: duration,
          onClose: () {
            if (overlayEntry.mounted) {
              overlayEntry.remove();
            }
            onClose?.call();
          },
        );
      },
    );

    overlay.insert(overlayEntry);
  }

  @override
  State<animatedSnackbar> createState() => _AnimatedSnackbarState();
}

class _AnimatedSnackbarState extends State<animatedSnackbar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );

    // Small delay to ensure widget is built before animation
    Future.microtask(() {
      if (mounted) {
        setState(() {
          _isVisible = true;
        });
        _controller.forward();
      }
    });

    // Set timer for hiding the snackbar
    Future.delayed(Duration(milliseconds: widget.duration), () {
      if (mounted) {
        setState(() {
          _isVisible = false;
        });
        _controller.reverse().then((_) {
          widget.onClose?.call();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Get icon and color based on type
  Map<String, dynamic> _getTypeStyles() {
    switch (widget.type) {
      case SnackbarType.success:
        return {
          'icon': Icons.check_circle,
          'color': Colors.green.shade500,
        };
      case SnackbarType.error:
        return {
          'icon': Icons.error,
          'color': Colors.red.shade500,
        };
      case SnackbarType.info:
      default:
        return {
          'icon': Icons.info,
          'color': Colors.blue.shade500,
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final typeStyles = _getTypeStyles();
    final IconData icon = typeStyles['icon'];
    final Color color = typeStyles['color'];

    return Positioned(
      bottom: 20,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Center(
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Opacity(
                  opacity: _animation.value,
                  child: Transform.translate(
                    offset: Offset(0, (1 - _animation.value) * 50),
                    child: child,
                  ),
                );
              },
              child: Material(
                elevation: 6,
                borderRadius: BorderRadius.circular(8),
                color: color,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 420),
                  width: double.infinity,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12.0,
                      horizontal: 16.0,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          icon,
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.message,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 20,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            setState(() {
                              _isVisible = false;
                            });
                            _controller.reverse().then((_) {
                              widget.onClose?.call();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}