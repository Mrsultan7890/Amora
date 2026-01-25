import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/websocket_service.dart';
import '../../../../shared/models/user_model.dart';

// Events
abstract class AuthEvent extends Equatable {
  const AuthEvent();
  
  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class AuthSignUpRequested extends AuthEvent {
  final String email;
  final String password;
  final String name;
  final int age;
  final String gender;
  final List<String> interests;
  
  const AuthSignUpRequested({
    required this.email,
    required this.password,
    required this.name,
    required this.age,
    required this.gender,
    required this.interests,
  });
  
  @override
  List<Object?> get props => [email, password, name, age, gender, interests];
}

class AuthSignInRequested extends AuthEvent {
  final String email;
  final String password;
  
  const AuthSignInRequested({
    required this.email,
    required this.password,
  });
  
  @override
  List<Object?> get props => [email, password];
}

class AuthSignOutRequested extends AuthEvent {}

// States
abstract class AuthState extends Equatable {
  const AuthState();
  
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final UserModel user;
  
  const AuthAuthenticated(this.user);
  
  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  
  const AuthError(this.message);
  
  @override
  List<Object?> get props => [message];
}

// Bloc
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final ApiService _apiService = ApiService.instance;
  final WebSocketService _wsService = WebSocketService.instance;
  
  AuthBloc() : super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthSignUpRequested>(_onAuthSignUpRequested);
    on<AuthSignInRequested>(_onAuthSignInRequested);
    on<AuthSignOutRequested>(_onAuthSignOutRequested);
  }
  
  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    try {
      if (_apiService.isAuthenticated) {
        final user = await _apiService.getCurrentUser();
        try {
          await _wsService.connect(user.id);
        } catch (e) {
          print('WebSocket connection failed: $e');
        }
        emit(AuthAuthenticated(user));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      print('Auth check failed: $e');
      emit(AuthUnauthenticated());
    }
  }
  
  Future<void> _onAuthSignUpRequested(
    AuthSignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    try {
      final response = await _apiService.register(
        email: event.email,
        password: event.password,
        name: event.name,
        age: event.age,
        gender: event.gender,
        interests: event.interests,
      );
      
      final user = UserModel.fromJson(response['user']);
      await _wsService.connect(user.id);
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }
  
  Future<void> _onAuthSignInRequested(
    AuthSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    try {
      final response = await _apiService.login(
        email: event.email,
        password: event.password,
      );
      
      final user = UserModel.fromJson(response['user']);
      await _wsService.connect(user.id);
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }
  
  Future<void> _onAuthSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _apiService.logout();
      await _wsService.disconnect();
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }
}