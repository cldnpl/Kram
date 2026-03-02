abstract class Failure {
  final String message;
  const Failure(this.message);
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server error']);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Auth failed']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No connection']);
}
