import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.dio.post('/auth/login/json', data: {
        'username': username,
        'password': password,
      });

      if (response.statusCode == 200) {
        _user = User.fromJson(response.data);
        
        // Save to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', _user!.accessToken);
        await prefs.setString('username', _user!.username);
        await prefs.setString('nama', _user!.nama);
        await prefs.setString('role', _user!.role);
        await prefs.setBool('is_temporary_password', _user!.isTemporaryPassword);
        if (_user!.fotoProfil != null) {
          await prefs.setString('foto_profil', _user!.fotoProfil!);
        }
        
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint("Login Error: $e");
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> register(Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.dio.post('/auth/register', data: data);

      if (response.statusCode == 201) {
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint("Register Error: $e");
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> loginWithGoogle() async {
    _isLoading = true;
    notifyListeners();

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: AppConstants.googleWebClientId,
      );

      // Force sign out first so the user can choose account if they have multiple
      await googleSignIn.signOut();
      
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        // User canceled the sign-in
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken != null) {
        final response = await ApiService.dio.post('/auth/google', data: {
          'id_token': idToken,
        });

        if (response.statusCode == 200) {
          _user = User.fromJson(response.data);
          
          // Save to SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('access_token', _user!.accessToken);
          await prefs.setString('username', _user!.username);
          await prefs.setString('nama', _user!.nama);
          await prefs.setString('role', _user!.role);
          await prefs.setBool('is_temporary_password', _user!.isTemporaryPassword);
          if (_user!.fotoProfil != null) {
            await prefs.setString('foto_profil', _user!.fotoProfil!);
          }
          
          _isLoading = false;
          notifyListeners();
          return true;
        }
      }
    } catch (e) {
      debugPrint("Google Login Error: $e");
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('access_token')) {
      return false;
    }

    final token = prefs.getString('access_token');
    final username = prefs.getString('username');
    final nama = prefs.getString('nama');
    final role = prefs.getString('role');
    final fotoProfil = prefs.getString('foto_profil');
    final isTemp = prefs.getBool('is_temporary_password') ?? false;

    if (token != null && username != null && nama != null && role != null) {
      _user = User(
        username: username,
        nama: nama,
        role: role,
        accessToken: token,
        isTemporaryPassword: isTemp,
        fotoProfil: fotoProfil,
      );
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('is_temporary_password');
    await prefs.remove('foto_profil');
    _user = null;
    notifyListeners();
  }

  Future<bool> changePassword(String oldPassword, String newPassword) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.dio.post('/users/change-password', data: {
        'old_password': oldPassword,
        'new_password': newPassword,
      });

      if (response.statusCode == 200) {
        if (_user != null) {
          _user = User(
            username: _user!.username,
            nama: _user!.nama,
            role: _user!.role,
            accessToken: _user!.accessToken,
            isTemporaryPassword: false,
            fotoProfil: _user!.fotoProfil,
          );
        }
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_temporary_password', false);
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint("Change Password Error: $e");
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> forgotPassword(String identifier) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.dio.post('/auth/forgot-password', data: {
        'identifier': identifier.trim(),
      });

      if (response.statusCode == 200) {
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint("Forgot Password Error: $e");
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> updateProfile(Map<String, dynamic> updateData) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.dio.put('/users/me', data: updateData);
      if (response.statusCode == 200) {
        // Jika update berhasil, update juga data `nama` di local memory (user model)
        if (updateData.containsKey('nama')) {
          _user = User(
            username: _user!.username,
            nama: updateData['nama'],
            role: _user!.role,
            accessToken: _user!.accessToken,
            fotoProfil: _user!.fotoProfil,
          );
        }
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint("Update Profile Error: $e");
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> updateFotoProfil(String newFotoUrl) async {
    if (_user != null) {
      _user = User(
        username: _user!.username,
        nama: _user!.nama,
        role: _user!.role,
        accessToken: _user!.accessToken,
        isTemporaryPassword: _user!.isTemporaryPassword,
        fotoProfil: newFotoUrl,
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('foto_profil', newFotoUrl);
      notifyListeners();
    }
  }

}
