import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';

/// The OTP box row. Figma specifies 5 boxes, but Supabase's phone OTP is a
/// fixed 6-digit code — see AppConfig.otpLength for the flagged deviation.
/// Box size/spacing/colors/radius otherwise match the Figma spec exactly;
/// width is computed responsively so it still fits narrow screens.
///
/// Supports typing one digit per box (auto-advance / backspace-to-previous)
/// and pasting a full code into any box.
class FMOTPInput extends StatefulWidget {
  const FMOTPInput({
    super.key,
    required this.onChanged,
    this.length = AppConfig.otpLength,
    this.resetToken,
    this.enabled = true,
  });

  final ValueChanged<String> onChanged;
  final int length;
  final Object? resetToken;
  final bool enabled;

  @override
  State<FMOTPInput> createState() => _FMOTPInputState();
}

class _FMOTPInputState extends State<FMOTPInput> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _initControllers();
    HardwareKeyboard.instance.addHandler(_handleHardwareKey);
  }

  void _initControllers() {
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _focusNodes = List.generate(widget.length, (_) => FocusNode());
  }

  @override
  void didUpdateWidget(covariant FMOTPInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.resetToken != oldWidget.resetToken) {
      setState(() {
        for (final controller in _controllers) {
          controller.clear();
        }
      });
      // didUpdateWidget always runs mid-rebuild of the parent, so calling
      // widget.onChanged() here synchronously runs the parent's callback
      // (which calls setState on the parent) while Flutter is still
      // building that same parent tree — "setState()/markNeedsBuild()
      // called during build", and in practice corrupted the tree badly
      // enough to also throw "Duplicate GlobalKey". Deferring to a
      // post-frame callback lets the current build finish first.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onChanged('');
      });
    }
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleHardwareKey);
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String get _code => _controllers.map((c) => c.text).join();

  void _handleChanged(int index, String value) {
    if (value.length > 1) {
      // Pasted content — spread across boxes starting at `index`.
      final digits = value.replaceAll(RegExp(r'\D'), '');
      setState(() {
        for (var i = 0; i < digits.length && index + i < widget.length; i++) {
          _controllers[index + i].text = digits[i];
        }
      });
      final nextEmpty = _controllers.indexWhere((c) => c.text.isEmpty);
      final focusIndex = nextEmpty == -1 ? widget.length - 1 : nextEmpty;
      _focusNodes[focusIndex].requestFocus();
      widget.onChanged(_code);
      return;
    }

    setState(() {});
    if (value.isNotEmpty && index < widget.length - 1) {
      _focusNodes[index + 1].requestFocus();
    }
    widget.onChanged(_code);
  }

  /// Backspace on an already-empty box moves focus back and clears the
  /// previous box. TextField has no key-event callback, so this listens at
  /// the hardware-keyboard level and checks which box currently has focus.
  bool _handleHardwareKey(KeyEvent event) {
    if (event is! KeyDownEvent || event.logicalKey != LogicalKeyboardKey.backspace) {
      return false;
    }
    final focusedIndex = _focusNodes.indexWhere((node) => node.hasFocus);
    if (focusedIndex > 0 && _controllers[focusedIndex].text.isEmpty) {
      setState(() {
        _focusNodes[focusedIndex - 1].requestFocus();
        _controllers[focusedIndex - 1].clear();
      });
      widget.onChanged(_code);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = (constraints.maxWidth / widget.length) - 8;
        final resolvedWidth = boxWidth.clamp(32.0, 40.0);
        final resolvedHeight = resolvedWidth * (39 / 40);

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(widget.length, (index) {
            return SizedBox(
              width: resolvedWidth,
              height: resolvedHeight,
              child: Semantics(
                label: 'OTP digit ${index + 1} of ${widget.length}',
                textField: true,
                child: TextField(
                  controller: _controllers[index],
                  focusNode: _focusNodes[index],
                  enabled: widget.enabled,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (value) => _handleChanged(index, value),
                  onTap: () {
                    _controllers[index].selection = TextSelection(
                      baseOffset: 0,
                      extentOffset: _controllers[index].text.length,
                    );
                  },
                  style: const TextStyle(
                    color: AppColors.primaryText,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    filled: true,
                    fillColor: _controllers[index].text.isNotEmpty
                        ? AppColors.otpFilled
                        : AppColors.otpEmpty,
                    contentPadding: EdgeInsets.zero,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppDimens.otpRadius),
                      borderSide: const BorderSide(color: AppColors.fieldBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppDimens.otpRadius),
                      borderSide: const BorderSide(color: AppColors.fieldBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppDimens.otpRadius),
                      borderSide: const BorderSide(color: AppColors.fieldBorder, width: 1.5),
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
