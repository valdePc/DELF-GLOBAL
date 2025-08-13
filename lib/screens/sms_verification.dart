import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'principal.dart';
import 'airtable_service.dart';

class SmsVerificationScreen extends StatefulWidget {
  final String fullName;
  final String phone;
  final DateTime? birthdate;
  final String password;
  final String fx;
  final String verificationId;

  const SmsVerificationScreen({
    Key? key,
    required this.fullName,
    required this.phone,
    required this.birthdate,
    required this.password,
    required this.fx,
    required this.verificationId,
  }) : super(key: key);

  @override
  SmsVerificationScreenState createState() => SmsVerificationScreenState();
}

class SmsVerificationScreenState extends State<SmsVerificationScreen> {
  final _codeController = TextEditingController();
  bool isVerifying = false;
  String errorMessage = '';
  int _secondsRemaining = 60;
  Timer? _timer;
  late String _currentVerificationId;

  @override
  void initState() {
    super.initState();
    _currentVerificationId = widget.verificationId;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  void startCountdown() {
    setState(() => _secondsRemaining = 60);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining == 0) {
        timer.cancel();
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  Future<void> resendCode() async {
    final l = AppLocalizations.of(context)!;
    _currentVerificationId = const Uuid().v4();
    startCountdown();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l.verifyCodeResent)),
    );
  }

  Future<void> verifyCode() async {
    final l = AppLocalizations.of(context)!;
    setState(() {
      isVerifying = true;
      errorMessage = '';
    });

    if (_codeController.text.trim() != '123456') {
      setState(() {
        errorMessage = l.verifyCodeInvalid;
        isVerifying = false;
      });
      return;
    }

    final birthdateStr = widget.birthdate != null
        ? "${widget.birthdate!.year}-${widget.birthdate!.month.toString().padLeft(2, '0')}-${widget.birthdate!.day.toString().padLeft(2, '0')}"
        : '';

    final created = await AirtableService.createUser(
      widget.fullName,
      widget.phone,
      birthdateStr,
      widget.password,
      widget.fx,
    );

    setState(() => isVerifying = false);

    if (created) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PrincipalScreen()),
      );
    } else {
      setState(() => errorMessage = l.verifyUserCreationError);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.verifySmsTitle),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(l.verifySmsInstruction(widget.phone), style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l.verifyCodeLabel,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            if (errorMessage.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(errorMessage, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ],
            const SizedBox(height: 16),
            isVerifying
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: verifyCode,
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15)),
                    child: Text(l.verifyCodeButton),
                  ),
            const SizedBox(height: 16),
            _secondsRemaining > 0
                ? Text(l.verifyCodeRetryIn(_secondsRemaining), style: const TextStyle(fontSize: 16))
                : TextButton(onPressed: resendCode, child: Text(l.verifyCodeResend)),
          ],
        ),
      ),
    );
  }
}
