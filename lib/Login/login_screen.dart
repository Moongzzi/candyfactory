import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../Common/session_store.dart';
import '../Home/widgets/logo_button.dart';
import '../constants/app_routes.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import 'auth_service.dart';
import 'widgets/input_field.dart';
import 'widgets/login_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final LoginService _loginService = LoginService();
  bool _isLoading = false;

  @override
  void dispose() {
    _nicknameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onLoginPressed() async {
    if (_isLoading) {
      return;
    }

    final nickname = _nicknameController.text.trim();
    final password = _passwordController.text;

    if (nickname.isEmpty || password.isEmpty) {
      await _showMessageDialog('닉네임과 비밀번호를 입력해주세요.');
      return;
    }

    if (!_isValidNickname(nickname)) {
      await _showMessageDialog(
        '닉네임 형식이 올바르지 않습니다.\n1~10자, 한글/영문/숫자만 사용할 수 있습니다.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _loginService.loginOrSignup(
        nickname: nickname,
        password: password,
      );

      if (!mounted) {
        return;
      }

      switch (result.outcome) {
        case LoginOutcome.signedUp:
          SessionStore.login(result.nickname);
          await _showMessageDialog('새 계정으로 접속 완료 했습니다.');
          _moveToHome();
          break;
        case LoginOutcome.wrongPassword:
          await _showMessageDialog('비밀번호가 잘못되었습니다.');
          break;
        case LoginOutcome.loggedIn:
          SessionStore.login(result.nickname);
          _moveToHome();
          break;
      }
    } on LoginSchemaException catch (error) {
      await _showMessageDialog(error.message);
    } catch (error) {
      await _showMessageDialog('로그인 처리 중 오류가 발생했습니다.\n$error');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _moveToHome() {
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
  }

  Future<void> _showMessageDialog(String message) {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }

  bool _isValidNickname(String nickname) {
    final lengthValid = nickname.length >= 1 && nickname.length <= 10;
    final formatValid = RegExp(r'^[A-Za-z0-9가-힣]+$').hasMatch(nickname);
    return lengthValid && formatValid;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: AppColors.webGradientColors,
            stops: AppColors.webGradientStops,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth;
              final maxHeight = constraints.maxHeight;
              final scale = math.min(
                maxWidth / AppSizes.designWidth,
                maxHeight / AppSizes.designHeight,
              );
              final panelWidth = AppSizes.loginPanelWidth * scale;
              final panelHeight = AppSizes.loginPanelHeight * scale;
              final logoWidth = AppSizes.loginLogoWidth * scale;
              final logoSpacing = AppSizes.loginLogoSpacing * scale;
              final inputSpacing = AppSizes.loginInputSpacing * scale;
              final buttonSpacing = AppSizes.loginButtonSpacing * scale;

              return Center(
                child: Container(
                  width: panelWidth,
                  height: panelHeight,
                  decoration: BoxDecoration(
                    color: AppColors.loginPanelBackground,
                    border: Border.all(
                      color: AppColors.loginPanelOutline,
                      width: AppSizes.loginPanelBorderWidth * scale,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      LogoButton(width: logoWidth),
                      SizedBox(height: logoSpacing),
                      LoginInputField(
                        placeholder: '닉네임',
                        scale: scale,
                        controller: _nicknameController,
                        onSubmitted: (_) => _onLoginPressed(),
                      ),
                      SizedBox(height: inputSpacing),
                      LoginInputField(
                        placeholder: '비밀번호',
                        scale: scale,
                        controller: _passwordController,
                        obscureText: true,
                        onSubmitted: (_) => _onLoginPressed(),
                      ),
                      SizedBox(height: buttonSpacing),
                      LoginActionButton(
                        scale: scale,
                        isLoading: _isLoading,
                        onPressed: _onLoginPressed,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
