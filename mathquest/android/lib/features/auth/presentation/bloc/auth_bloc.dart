import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/auth_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._authService) : super(const AuthState()) {
    on<AuthSubscriptionRequested>(_onSubscriptionRequested);
    on<AuthGoogleSignInRequested>(_onGoogleSignInRequested);
    on<AuthAppleSignInRequested>(_onAppleSignInRequested);
    on<AuthSignOutRequested>(_onSignOutRequested);
    on<_AuthUserChanged>(_onUserChanged);
    add(const AuthSubscriptionRequested());
  }

  final AuthService _authService;
  StreamSubscription<User?>? _authSubscription;

  Future<void> _onSubscriptionRequested(
    AuthSubscriptionRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _authSubscription?.cancel();
    _authSubscription = _authService.authStateChanges().listen(
          (user) => add(_AuthUserChanged(user)),
          onError: (error, _) =>
              add(_AuthUserChanged(null, error: error.toString())),
        );
  }

  void _onUserChanged(_AuthUserChanged event, Emitter<AuthState> emit) {
    if (event.error != null) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorMessage: event.error,
        ),
      );
      return;
    }

    emit(
      AuthState(
        status: event.user == null
            ? AuthStatus.unauthenticated
            : AuthStatus.authenticated,
        user: event.user,
      ),
    );
  }

  Future<void> _onGoogleSignInRequested(
    AuthGoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(
      state.copyWith(
        status: AuthStatus.loading,
        clearError: true,
      ),
    );

    try {
      await _authService.signInWithGoogle();
    } on FirebaseAuthException catch (error) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorMessage: error.message ?? error.code,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _onAppleSignInRequested(
    AuthAppleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(
      state.copyWith(
        status: AuthStatus.loading,
        clearError: true,
      ),
    );

    try {
      await _authService.signInWithApple();
    } on FirebaseAuthException catch (error) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorMessage: error.message ?? error.code,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _onSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(
      state.copyWith(
        status: AuthStatus.loading,
        clearError: true,
      ),
    );

    try {
      await _authService.signOut();
    } catch (error) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  @override
  Future<void> close() async {
    await _authSubscription?.cancel();
    return super.close();
  }
}

class _AuthUserChanged extends AuthEvent {
  const _AuthUserChanged(this.user, {this.error});

  final User? user;
  final String? error;
}
