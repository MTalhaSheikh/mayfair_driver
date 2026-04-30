import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mayfair_driver/controllers/login_controller.dart';
import 'package:mayfair_driver/core/app_colors.dart';
import 'package:mayfair_driver/core/app_texts.dart';
import 'package:mayfair_driver/core/app_theme.dart';
import 'package:mayfair_driver/views/widgets/app_pill_text_field.dart';

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: const _DriverLoginScreen(),
          ),
        ),
      ),
    );
  }
}

/// Custom full-screen login widget that matches the provided design.
class _DriverLoginScreen extends StatefulWidget {
  const _DriverLoginScreen();

  @override
  State<_DriverLoginScreen> createState() => _DriverLoginScreenState();
}

class _DriverLoginScreenState extends State<_DriverLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  late final LoginController _controller;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<LoginController>();
    _emailController = TextEditingController(text: _controller.email.value);
    _passwordController = TextEditingController(text: _controller.password.value);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          // Top icon circle
          Container(
            width: 120,
            height: 120,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.portalOlive,
            ),
            child: const Icon(
              Icons.directions_car_filled_outlined,
              size: 60,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Text(AppTexts.limoGuy, style: AppTheme.loginTitle),
          const SizedBox(height: 4),
          Text(AppTexts.signInSubtitle, style: AppTheme.loginSubtitle),
          const SizedBox(height: 32),

          // Email field
          AppPillTextField(
            controller: _emailController,
            hintText: AppTexts.emailHint,
            prefixIcon: Icons.mail_outline,
            keyboardType: TextInputType.emailAddress,
            onChanged: (value) => _controller.email.value = value,
            validator: (value) {
              final v = (value ?? '').trim();
              if (v.isEmpty) return AppTexts.emailRequired;
              if (!GetUtils.isEmail(v)) return AppTexts.emailInvalid;
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Password field
          AppPillTextField(
            controller: _passwordController,
            hintText: AppTexts.passwordHint,
            prefixIcon: Icons.lock_outline,
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: Colors.grey,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            onChanged: (value) => _controller.password.value = value,
            validator: (value) {
              final v = (value ?? '').trim();
              if (v.isEmpty) return AppTexts.passwordRequired;
              if (v.length < 6) return AppTexts.passwordMinLength;
              return null;
            },
          ),

          const SizedBox(height: 8),
          Obx(
            () => _controller.errorMessage.isEmpty
                ? const SizedBox.shrink()
                : Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        _controller.errorMessage.value,
                        style: AppTheme.errorText,
                      ),
                    ),
                  ),
          ),

          const SizedBox(height: 32),

          // Login button (full-width pill)
          Obx(
            () => SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _controller.isLoading.value
                    ? null
                    : () {
                        FocusScope.of(context).unfocus();
                        _controller.errorMessage.value = '';
                        if (_formKey.currentState?.validate() ?? false) {
                          _controller.login();
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.portalOlive,
                  disabledBackgroundColor: AppColors.portalOlive.withOpacity(
                    0.6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32),
                  ),
                  elevation: 0,
                ),
                child: _controller.isLoading.value
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        AppTexts.login,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),

          const SizedBox(height: 40),
          const Divider(color: AppColors.divider),
          const SizedBox(height: 16),

          // Help footer
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(
                Icons.headset_mic_outlined,
                size: 18,
                color: AppColors.textSecondary,
              ),
              SizedBox(width: 8),
              Text(
                AppTexts.needHelp,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
