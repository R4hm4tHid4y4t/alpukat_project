import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';

class OtpVerificationPage extends StatefulWidget {
  final int userId;
  final String email;

  const OtpVerificationPage({super.key, required this.userId, required this.email});

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  Timer? _timer;
  int _secondsRemaining = 600; // 10 menit

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsRemaining = 600);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
      }
    });
  }

  String get _formattedTime {
    final minutes = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsRemaining % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String get _otpCode => _controllers.map((c) => c.text).join();

  void _onDigitChanged(int index, String value) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    // Auto-submit jika 6 digit sudah terisi
    if (_otpCode.length == 6) {
      _submit();
    }
  }

  void _submit() {
    if (_otpCode.length != 6) return;
    context.read<AuthBloc>().add(OtpVerifyRequested(
      userId: widget.userId,
      kodeOtp: _otpCode,
    ));
  }

  void _resendOtp() {
    // Catatan: panggil endpoint resend OTP jika tersedia
    _startTimer();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Kode OTP baru telah dikirim')),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(title: const Text('Verifikasi OTP')),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.errorColor),
            );
            // Reset input
            for (final c in _controllers) {
              c.clear();
            }
            _focusNodes[0].requestFocus();
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: AppColors.extraLightGreen,
                  shape: BoxShape.circle,
                ),
                child: const Center(child: Text('📧', style: TextStyle(fontSize: 36))),
              ),
              const SizedBox(height: 24),
              const Text(
                'Masukkan Kode OTP',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Kode OTP telah dikirim ke',
                style: const TextStyle(color: AppColors.textGrey),
                textAlign: TextAlign.center,
              ),
              Text(
                widget.email,
                style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primaryGreen),
              ),
              const SizedBox(height: 32),

              // 6 kotak OTP
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (i) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: SizedBox(
                        height: 56,
                        child: TextField(
                          controller: _controllers[i],
                          focusNode: _focusNodes[i],
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          maxLength: 1,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          decoration: const InputDecoration(counterText: ''),
                          onChanged: (v) => _onDigitChanged(i, v),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),

              // Timer
              Text(
                _secondsRemaining > 0
                    ? 'Kode berlaku selama $_formattedTime'
                    : 'Kode OTP sudah kedaluwarsa',
                style: TextStyle(
                  color: _secondsRemaining > 0 ? AppColors.textGrey : AppColors.errorColor,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),

              if (_secondsRemaining == 0)
                TextButton(
                  onPressed: _resendOtp,
                  child: const Text('Kirim Ulang OTP'),
                ),

              const SizedBox(height: 24),

              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  final isLoading = state is AuthLoading;
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (isLoading || _otpCode.length != 6) ? null : _submit,
                      child: isLoading
                          ? const SizedBox(
                              height: 20, width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('Verifikasi'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}