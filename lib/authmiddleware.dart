import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:logging/logging.dart';

enum LoginTypes {
  otp,
  email,
  google,
  facebook,
  whatsapp,
  github,
}

enum AuthenticationType {
  login,
  transaction
}

class AuthMiddlewareService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final String baseUrl = 'https://api.amw.launchlense.tech/v1/client/';
  String? _accessKey;
  String? _token;
  final Logger _logger = Logger('AuthMiddlewareService');

  // Initialize the service with an access key and store it securely
  Future<void> initAuthMiddleWare(String accessKey) async {
    _accessKey = accessKey;
    await _secureStorage.write(key: 'accessKey', value: accessKey);
  }

  // Load the access key from secure storage if not already loaded
  Future<void> _loadConfig() async {
    _accessKey ??= await _secureStorage.read(key: 'accessKey');
  }

Future<void> _loadToken() async {
  _token ??= await _secureStorage.read(key:'bearer_token');
}
  // Helper method to make HTTP POST requests and handle responses
  Future<void> _postRequest(
    String endpoint,
    Map<String, dynamic> body,
    void Function(Map<String, dynamic>) onSuccess,
    void Function(String) onError, {
    String? token,
  }) async {
    await _loadConfig();
    await _loadToken();
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = {
      'Content-Type': 'application/json',
      if (_accessKey != null) 'Authorization': _accessKey!,
      if (token != null) 'Authorization': _token!,
    };

    try {
      final response = await http.post(url, headers: headers, body: jsonEncode(body));
      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
        onSuccess(responseBody);
      } else {
        final error = jsonDecode(response.body)['message'] as String;
        onError(error);
        Fluttertoast.showToast(
          msg: error,
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
        );
      }
    } catch (e) {
      onError('Failed to send request: $e');
      Fluttertoast.showToast(
        msg: 'Failed to send request: $e',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  // Get the client's IP address
  Future<String?> _getIpAddress() async {
    try {
      for (var interface in await NetworkInterface.list()) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4) {
            return addr.address;
          }
        }
      }
    } catch (e) {
      _logger.severe('Failed to get IP address', e);
    }
    return null;
  }

  Future<void> loginWithEmail(
    String email,
    String password,
    void Function(Map<String, dynamic>) onSuccess,
    void Function(String) onError,
  ) async {
    final ipAddress = await _getIpAddress() ?? '';
    await _postRequest(
      'login_with_email',
      {
        'email': email,
        'password': password,
        'ip': ipAddress,
      },
      onSuccess,
      onError,
    );
  }

  // Initialize login
  Future<void> initLogin(
    String contact,
    int otpLength,
    void Function(Map<String, dynamic>) onSuccess,
    void Function(String) onError, {
    bool isMfa = false,
    List<String> mfaTypes = const [],
    required AuthenticationType authType,
  }) async {
    final ipAddress = await _getIpAddress() ?? '';
    await _postRequest(
      'init_login',
      {
        'contact': contact,
        'otp_length': otpLength,
        'type': "otp",
        'ismfa': isMfa.toString(),
        'mfaTypes': mfaTypes,
        'ip': ipAddress,
      },
      onSuccess,
      onError,
    );
  }

  // Verify authentication
  Future<void> verifyAuth(
    String contact,
    String password,
    void Function(Map<String, dynamic>) onSuccess,
    void Function(String) onError, {
    bool isBiometric = false,
    Map<String, String> biometricsInput = const {},
  }) async {
    await _postRequest(
      'verify_auth',
      {
        'contact': contact,
        'password': password,
        'isbiometric': isBiometric.toString(),
        'biometrics_input': biometricsInput,
      },
      (response) async {
        if (response["Status"] == true) {
          String? token = response["data"];
          await _secureStorage.write(key: 'bearer_token', value: token);
          onSuccess(response);
        } else if (response["Status"] == false && response["message"] == "USER_BANNED") {
          Fluttertoast.showToast(
            msg: "You have been blocked from access",
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
          );
          onError("USER_BANNED");
        } else if (response["Status"] == false &&
            (response["message"] == "INVALID_USER" || response["message"] == "INVALID_CONTACT")) {
          Fluttertoast.showToast(
            msg: "Please enter correct contact number",
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
          );
          onError("INVALID_CONTACT");
        } else if (response["Status"] == false && response["message"] == "UNAUTHORIZED_USER") {
          Fluttertoast.showToast(
            msg: "Resources you are trying to find are not found",
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
          );
          onError("UNAUTHORIZED_USER");
        } else if (response["Status"] == false && response["message"] == "SERVER_ERROR") {
          Fluttertoast.showToast(
            msg: "Something went wrong...",
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
          );
          onError("SERVER_ERROR");
        } else {
          onError("Unknown error");
        }
      },
      onError,
    );
  }

  Future<void> authorizeUser(
   void Function(Map<String, dynamic>) onSuccess,
    void Function(String) onError
  ) async {
  
    await _loadToken();
    await _postRequest(
      'authorize_user',
      {},
      onSuccess,
      onError,
      token:_token
    );

      }
    

  }
