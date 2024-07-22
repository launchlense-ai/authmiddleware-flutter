# AuthMiddleware

AuthMiddleware is a Flutter package designed by Launchlense to handle authentication middleware operations. It provides utilities for initializing authentication, performing login actions, verifying authentication, and authorizing users with a decorator pattern.

## Installation

To use AuthMiddleware in your Flutter project, add the following to your `pubspec.yaml` file:

```yaml
dependencies:
  authmiddleware:1.0.0
```

## Usage

Import the package into your Dart file:

```dart
import 'package:authmiddleware/authmiddleware.dart';
```
### Get Access Keys

Head on to https://portal.amw.launchlense.tech
Create your account -> create a new project -> you will receive a access token (NEVER LOOSE THE TOKEN)


### Initialize AuthMiddleware

Initialize the AuthMiddleware service with an access key:



```dart
final authMiddleware = AuthMiddlewareService();
await authMiddleware.initAuthMiddleWare('your_access_key');
```

### Initialize Login

```dart
authMiddleware.initLogin(
  '9999999999',
  LoginTypes.otp,
  otpLength=4
  (response) {
    print('Login successful: $response');
  },
  (error) {
    print('Login error: $error');
  },
);
```

### Verify Authentication

```dart
authMiddleware.verifyAuth(
  '9999999999',
  '1234',
  (response) {
    print('Authentication successful: $response');
  },
  (error) {
    print('Authentication error: $error');
  },
);
```

### Authorize User (Using as a Decorator)

You can use `authorizeUser` method as a decorator to ensure user authorization before executing a function:

```dart
authMiddleware.authorizeUser(
  (authorize, onError) async {
    authorize(
      (response) {
        print('Authorization successful: $response');
      },
      (error) {
        print('Authorization error: $error');
      },
    );
    // Call any function that requires authorization here
  },
);
```

This ensures that the user is authorized before executing the function provided in the decorator.

## Support

For issues or questions, please open an issue on [GitHub](https://github.com/launchlense.ai/authmiddleware-flutter/issues).

## Notes

- Replace `'your_access_key'` with your actual access key during initialization (`initAuthMiddleWare`).

- Ensure to handle errors appropriately in your application.
