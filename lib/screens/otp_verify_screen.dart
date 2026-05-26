import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quiz_app_supabase/screens/home_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';

class OtpVerifyScreen extends StatefulWidget {
  final String email;

  const OtpVerifyScreen({super.key, required this.email});

  @override
  State<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends State<OtpVerifyScreen> {
  final _digits = List.generate(6, (_) => TextEditingController());
  final _focus = List.generate(6, (_) => FocusNode());
  final _keyFocus = List.generate(6, (_) => FocusNode());
  bool _loading = false;

  String get _otpCode => _digits.map((c) => c.text.trim()).join();

  @override
  void initState() {
    super.initState();
    // Auto focus first box
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focus[0].requestFocus();
      _keyFocus[0].requestFocus();
    });
  }

  @override
  void dispose() {
    for (final c in _digits) {
      c.dispose();
    }
    for (final f in _focus) {
      f.dispose();
    }
    for (final f in _keyFocus) {
      f.dispose();
    }
    super.dispose();
  }

  void _fillFromPaste(String raw) {
    final onlyDigits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (onlyDigits.isEmpty) return;

    for (var i = 0; i < 6; i++) {
      _digits[i].text = i < onlyDigits.length ? onlyDigits[i] : '';
    }

    // Move focus to next empty or last
    final next = onlyDigits.length >= 6 ? 5 : onlyDigits.length;
    _focus[next].requestFocus();

    // Optionally auto-verify when 6 digits present
    if (onlyDigits.length >= 6) {
      _verify();
    }
  }

  Future<void> _verify() async {
    final code = _otpCode;

    if (code.length != 6 || code.contains('')) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter the 6-digit code')));
      return;
    }

    setState(() => _loading = true);
    try {
      await Supabase.instance.client.auth.verifyOTP(
        email: widget.email,
        token: code,
        type: OtpType.email,
      );

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Verification failed: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    setState(() => _loading = true);
    try {
      await Supabase.instance.client.auth.signInWithOtp(email: widget.email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Code resent. Check your email.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to resend: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  InputDecoration _otpDecoration() => InputDecoration(
    counterText: '',
    filled: true,
    fillColor: Colors.grey[100],
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
    ),
  );

  Widget _otpBox(int i) {
    return RawKeyboardListener(
      focusNode: _keyFocus[i],
      onKey: (event) {
        if (event is! RawKeyDownEvent) return;

        final isBackspace = event.logicalKey == LogicalKeyboardKey.backspace;
        if (!isBackspace) return;

        final currentText = _digits[i].text;

        // If box has a digit, backspace clears it (stay here)
        if (currentText.isNotEmpty) {
          _digits[i].clear();
          return;
        }

        // If box is empty, backspace moves to previous and clears it
        if (i > 0) {
          _digits[i - 1].clear();
          _focus[i - 1].requestFocus();
          _keyFocus[i - 1].requestFocus();
        }
      },
      child: SizedBox(
        width: 48,
        child: TextField(
          controller: _digits[i],
          focusNode: _focus[i],
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 1,
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700),
          decoration: _otpDecoration(),
          onTap: () {
            // Keep keyboard listener in sync with TextField focus
            _keyFocus[i].requestFocus();
            _digits[i].selection = TextSelection(
              baseOffset: 0,
              extentOffset: _digits[i].text.length,
            );
          },
          onChanged: (value) {
            final v = value.trim();

            // If user pasted multiple digits
            if (v.length > 1) {
              _fillFromPaste(v);
              return;
            }

            // If user typed a digit, move forward
            if (v.isNotEmpty) {
              if (i < 5) {
                _focus[i + 1].requestFocus();
                _keyFocus[i + 1].requestFocus();
              } else {
                _focus[i].unfocus();
              }
            }
          },
          onSubmitted: (_) {
            if (i == 5) _verify();
          },
        ),
      ),
    );
  }

  Widget _otpBoxesRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, _otpBox),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Verify code',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Enter verification code',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'We sent a 6-digit code to:',
                      style: GoogleFonts.poppins(color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.email,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 16),

                    _otpBoxesRow(),
                    const SizedBox(height: 14),

                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _verify,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          _loading ? 'Verifying...' : 'Verify & Continue',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    TextButton(
                      onPressed: _loading ? null : _resend,
                      child: Text(
                        'Resend code',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
