import 'package:flutter/services.dart';

final class PhoneAuthorization {
  const PhoneAuthorization({required this.token, this.carrier});

  final String token;
  final String? carrier;
}

final class WechatAuthorization {
  const WechatAuthorization({required this.code, required this.state});

  final String code;
  final String state;
}

final class AuthPlatformException implements Exception {
  const AuthPlatformException(this.code);
  final String code;
}

abstract interface class AuthPlatformGateway {
  Future<PhoneAuthorization> authorizePhone();
  Future<bool> isWechatInstalled();
  Future<WechatAuthorization> authorizeWechat(String state);
}

final class MethodChannelAuthPlatformGateway implements AuthPlatformGateway {
  const MethodChannelAuthPlatformGateway();

  static const _channel = MethodChannel('com.wyg916.smartledger/auth');

  @override
  Future<PhoneAuthorization> authorizePhone() async {
    try {
      final result = (await _channel.invokeMapMethod<String, Object?>(
        'authorizePhone',
      ))!;
      return PhoneAuthorization(
        token: result['token']! as String,
        carrier: result['carrier'] as String?,
      );
    } on PlatformException catch (error) {
      throw AuthPlatformException(error.code);
    }
  }

  @override
  Future<bool> isWechatInstalled() async {
    try {
      return await _channel.invokeMethod<bool>('isWechatInstalled') ?? false;
    } on PlatformException catch (error) {
      throw AuthPlatformException(error.code);
    }
  }

  @override
  Future<WechatAuthorization> authorizeWechat(String state) async {
    try {
      final result = (await _channel.invokeMapMethod<String, Object?>(
        'authorizeWechat',
        {'state': state},
      ))!;
      return WechatAuthorization(
        code: result['code']! as String,
        state: result['state']! as String,
      );
    } on PlatformException catch (error) {
      throw AuthPlatformException(error.code);
    }
  }
}

final class FakeAuthPlatformGateway implements AuthPlatformGateway {
  const FakeAuthPlatformGateway({
    this.phoneFailure,
    this.wechatFailure,
    this.wechatInstalled = true,
  });

  final String? phoneFailure;
  final String? wechatFailure;
  final bool wechatInstalled;

  @override
  Future<PhoneAuthorization> authorizePhone() async {
    if (phoneFailure != null) throw AuthPlatformException(phoneFailure!);
    return const PhoneAuthorization(
      token: 'synthetic-phone-token',
      carrier: 'mobile',
    );
  }

  @override
  Future<bool> isWechatInstalled() async => wechatInstalled;

  @override
  Future<WechatAuthorization> authorizeWechat(String state) async {
    if (wechatFailure != null) throw AuthPlatformException(wechatFailure!);
    if (!wechatInstalled) {
      throw const AuthPlatformException('wechat_not_installed');
    }
    return WechatAuthorization(code: 'synthetic-wechat-code', state: state);
  }
}
