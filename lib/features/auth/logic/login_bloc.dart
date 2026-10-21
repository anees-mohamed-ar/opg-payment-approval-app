import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart'; // SharedPreferences import

import '../apiService/api_service.dart';

part 'login_event.dart';
part 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final ApiService apiService;

  LoginBloc({required this.apiService}) : super(LoginState.initial()) {
    on<LoginSubmitted>(_onLoginSubmitted);
    on<TogglePasswordVisibility>(_onTogglePasswordVisibility);
  }
  void _onLoginSubmitted(LoginSubmitted event, Emitter<LoginState> emit) async {
    emit(state.update(isSubmitting: true));
    print("Login attempt for username: ${event.username}");

    try {
      final users = await apiService.fetchUsers();
      print("Fetched users: $users");

      final user = users.firstWhere(
        (user) => user.userId.toLowerCase() == event.username.toLowerCase(),
        orElse: () => throw Exception('User not found'),
      );

      print("User found: ${user.name}");

      if (user.password == event.password) {
        // Save userId, name, and role in SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        try {
          await prefs.setString('userId', user.userId);
          await prefs.setString('userName', user.name);
          await prefs.setString('userRole', user.role); // Save user role
          await prefs.setString(
              'userDepartment', user.department); // Save user department

          emit(LoginSuccess());
          print("""
  _  ___      _   _     _       _      _ 
 | |/ (_)    | | (_)   (_)     (_)    (_)
 | ' / _  ___| |_ _ ___ _ ___   _  ___ _ 
 |  < | |/ _ \\ __| / __| / __| | |/ _ \\ |
 | . \\| |  __/ |_| \\__ \\ \\__ \\ | |  __/ |
 |_|\\_\\_|\\___|\\__|_|___/_|___/ |_|\\___|_|
                                         
🎯 Flutter Login ✅ Successful for User: ${user.name}
""");

          Fluttertoast.showToast(
            msg: "Login Successful",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.green,
            textColor: Colors.white,
            fontSize: 16.0,
          );

          // Navigate based on role
          if (user.role == 'approver') {
            Get.offAllNamed('/approver');
          } else {
            Get.offAllNamed('/home');
          }
        } catch (e) {
          print("Error saving to SharedPreferences: $e");
          emit(LoginFailure("Failed to save user data."));
          Fluttertoast.showToast(
            msg: "Failed to save user data.",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0,
          );
        }
      } else {
        emit(LoginFailure("Invalid username or password."));
        print("Invalid credentials for username: ${event.username}");
        Fluttertoast.showToast(
          msg: "Invalid username or password.",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
    } catch (e) {
      String errorMessage = e.toString();
      print("Error during login: $errorMessage");
      if (errorMessage == 'null') {
        errorMessage = 'An unknown error occurred. Please try again.';
      }
      emit(LoginFailure(errorMessage));
      Fluttertoast.showToast(
        msg: errorMessage,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  void _onTogglePasswordVisibility(
      TogglePasswordVisibility event, Emitter<LoginState> emit) {
    emit(state.update(isPasswordVisible: !state.isPasswordVisible));
  }
}
