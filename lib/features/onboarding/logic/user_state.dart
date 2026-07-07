// lib/features/onboarding/logic/user_state.dart
import 'package:flutter/material.dart';

abstract class UserState {}

class UserInitial extends UserState {}

class UserLoading extends UserState {}

class UserSuccess extends UserState {
  final String message;
  UserSuccess({this.message = 'Success'});
}

class UserError extends UserState {
  final String message;
  UserError({required this.message});
}
