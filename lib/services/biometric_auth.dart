import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

class BiometricAuth {
  final LocalAuthentication _localAuth = LocalAuthentication();

  Future<bool> canUseBiometrics() async {
    try {
      bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      bool isDeviceSupported = await _localAuth.isDeviceSupported();
      return canCheckBiometrics && isDeviceSupported;
    } catch (e) {
      print('Error checking biometrics: $e');
      return false;
    }
  }

  Future<void> checkBiometric(
    BuildContext context,
    Widget successScreen,
    Widget fallbackScreen,
    bool isLogin,
  ) async {
    try {
      bool canCheckBiometrics = await canUseBiometrics();
      if (canCheckBiometrics) {
        bool authenticated = await _localAuth.authenticate(
          localizedReason: 'Authenticate to log in',
          options: const AuthenticationOptions(biometricOnly: true),
        );
        if (authenticated) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => successScreen),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => fallbackScreen),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Biometric authentication not available')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Biometric error: $e')),
      );
    }
  }
}