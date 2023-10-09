import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:buraq/AllScreens/registerationScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;

class StripeServices {
  StripeServices._();
  static final StripeServices _instance = StripeServices._();
  static StripeServices get instance => _instance;
  final isDebugMode = true;
  // final double _stripeLimit = 5000;
  final _publishableKeyTest =
      'pk_test_51NLn36IA8M1AbtHpGPgBAnExnOaRzPdX505bW5bnP0oWXKT6btE8D43AlhI1TAPSiJJoCCBLiKHX6NqCUQ5RgWHQ00SbajFyUZ';
  final _secreteKeyTest =
      'sk_test_51NLn36IA8M1AbtHpYX1q1unXh4h1uk0oMbWgOnCfxgNAW2AW64SHAVWhEIgLXkkZN5d6gMYX7F5v9OvE4fWVkk0G00Urd2PQop';
  Future<void> initialize() async {
    Stripe.publishableKey = _publishableKeyTest;
    // Stripe.merchantIdentifier = 'merchant.flutter.stripe.test';
    Stripe.urlScheme = 'flutterstripe';
    await Stripe.instance.applySettings();
    log('@initialize =====> Stripe is initialized');
  }

  String _calculate(double price) {
    double neee = price * 100;
    int ss = neee.ceil();
    return ss.toString();
  }

  Future<void> startPurchase(
      double amount, Future<void> Function(bool, String) purchaseHook,context) async {
    try {

      Map<String, dynamic>? paymentIntentData =
      await _getPaymentIntent(_calculate(amount), 'PKR');
      if (paymentIntentData == null) {
        displayToastMessage('Payment Intent Error!. Payment failed, please try again.', context);
        return;
      }
      await Stripe.instance
          .initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntentData['client_secret'],
          applePay: !Platform.isIOS
              ? null
              : const PaymentSheetApplePay(
            merchantCountryCode: 'IT',
          ),
          googlePay: PaymentSheetGooglePay(
            merchantCountryCode: 'IT',
            testEnv: isDebugMode,
          ),
          style: ThemeMode.light,
          merchantDisplayName: 'My Ticket',
        ),
      )
          .then((val) async {
        await _showPaymentIntentSheet(purchaseHook);
      });
    } catch (e, s) {
      log('@startPurchase onCatch=====> $e\n$s');

      purchaseHook.call(false, e.toString());
    }
  }

//this is used to show the bottom sheet where user can enter detials for that specific transaction and then payment is generated
  Future<void> _showPaymentIntentSheet(
      Future<void> Function(bool, String message) purchaseHook) async {
    try {
      await Stripe.instance.presentPaymentSheet().then((val) async {
        await purchaseHook.call(true, 'Payment Successfull!');
      });
    } on StripeException catch (e) {
      await purchaseHook.call(false, e.error.message.toString());
      log('@_showPaymentIntentSheet onStripeException=====> ${e.error}');
    } catch (e) {
      await purchaseHook.call(false, e.toString());
      log('@_showPaymentIntentSheet onCatch=====> $e');
    }
  }

// this is used by stripe to send request to generate payment intent related data. its done on the stage 1.
  Future<Map<String, dynamic>?> _getPaymentIntent(
      String amount, String currency) async {
    try {
      Map<String, dynamic> body = {
        'amount': amount,
        'currency': currency,
        'payment_method_types[]': 'card'
      };

      final response = await http.post(
          Uri.parse('https://api.stripe.com/v1/payment_intents'),
          body: body,
          headers: {
            'Authorization': 'Bearer $_secreteKeyTest',
            'Content-Type': 'application/x-www-form-urlencoded'
          });

      return jsonDecode(response.body);
    } catch (err) {
      log('@_getPaymentIntentError===>${err.toString()}');
      return null;
    }
  }
}
