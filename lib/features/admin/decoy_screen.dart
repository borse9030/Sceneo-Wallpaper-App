import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:async';
import '../../core/theme/colors.dart';

class DecoyScreen extends StatefulWidget {
  const DecoyScreen({super.key});

  @override
  State<DecoyScreen> createState() => _DecoyScreenState();
}

class _DecoyScreenState extends State<DecoyScreen> {
  int _tapCount = 0;

  void _handleSecretTap() {
    _tapCount++;
    if (_tapCount == 5) {
      _tapCount = 0;
      _showPinDialog();
    }
  }

  void _showPinDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) {
        return const _PinDialog();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wallpaper, size: 80, color: Colors.white24)
                .animate()
                .fade(duration: 800.ms)
                .scale(),
            const SizedBox(height: 24),
            const Text(
              'Sceneo',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w300,
                letterSpacing: 2,
              ),
            ).animate().fade(delay: 200.ms),
            const SizedBox(height: 8),
            const Text(
              'Premium 4K Wallpapers',
              style: TextStyle(color: Colors.white54, fontSize: 16),
            ).animate().fade(delay: 400.ms),
            const SizedBox(height: 40),
            GestureDetector(
              onTap: _handleSecretTap,
              child: const Text(
                'Version 1.0.0',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ).animate().fade(delay: 600.ms),
          ],
        ),
      ),
    );
  }
}

class _PinDialog extends StatefulWidget {
  const _PinDialog();

  @override
  State<_PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<_PinDialog> {
  String enteredPin = '';
  int failedAttempts = 0;
  DateTime? lockoutEndTime;
  Timer? _timer;
  bool showIncorrectMessage = false;
  
  final String correctPin = '9307394255';
  final int maxAttempts = 5;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (lockoutEndTime != null) {
        if (DateTime.now().isAfter(lockoutEndTime!)) {
          setState(() {
            lockoutEndTime = null;
            failedAttempts = 0;
            showIncorrectMessage = false;
          });
          _timer?.cancel();
        } else {
          setState(() {}); // Update the countdown UI
        }
      }
    });
  }

  void _onNumberTap(int number) {
    if (lockoutEndTime != null) return; // Locked out
    if (enteredPin.length < 10) {
      setState(() {
        enteredPin += number.toString();
        showIncorrectMessage = false;
      });
      
      if (enteredPin.length == 10) {
        if (enteredPin == correctPin) {
          Navigator.pop(context);
          context.pushReplacement('/admin');
        } else {
          // Wrong PIN
          setState(() {
            failedAttempts++;
            enteredPin = '';
            showIncorrectMessage = true;
            if (failedAttempts >= maxAttempts) {
              lockoutEndTime = DateTime.now().add(const Duration(minutes: 1));
              _startTimer();
            }
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isLocked = lockoutEndTime != null;
    int secondsLeft = 0;
    if (isLocked) {
      secondsLeft = lockoutEndTime!.difference(DateTime.now()).inSeconds;
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isLocked 
                ? 'Locked for ${secondsLeft}s' 
                : (showIncorrectMessage ? 'Incorrect PIN' : 'Enter Admin PIN'),
            style: TextStyle(
              color: isLocked || showIncorrectMessage ? Colors.redAccent : Colors.white54, 
              fontSize: 16,
              fontWeight: isLocked || showIncorrectMessage ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 30),
          
          // Number Pad
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            runSpacing: 16,
            children: List.generate(10, (index) {
              final number = index == 9 ? 0 : index + 1;
              return GestureDetector(
                onTap: isLocked ? null : () => _onNumberTap(number),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: isLocked 
                        ? Colors.redAccent.withOpacity(0.05) 
                        : Colors.white.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      number.toString(),
                      style: TextStyle(
                        color: isLocked ? Colors.white24 : Colors.white, 
                        fontSize: 24,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          
          // Clear Button
          if (!isLocked) ...[
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () {
                setState(() {
                  enteredPin = '';
                });
              },
              child: const Text(
                'CLEAR',
                style: TextStyle(color: Colors.white38, letterSpacing: 2),
              ),
            ),
          ]
        ],
      ),
    );
  }
}
