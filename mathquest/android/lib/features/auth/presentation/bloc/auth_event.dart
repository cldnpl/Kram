abstract class AuthEvent {
  const AuthEvent();
}

class AuthSubscriptionRequested extends AuthEvent {
  const AuthSubscriptionRequested();
}

class AuthGoogleSignInRequested extends AuthEvent {
  const AuthGoogleSignInRequested();
}

class AuthAppleSignInRequested extends AuthEvent {
  const AuthAppleSignInRequested();
}

class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}
