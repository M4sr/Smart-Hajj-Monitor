import 'package:flutter/material.dart';
import '../models/assessment_result.dart';
import '../models/assessment_history.dart';
import '../services/api_service.dart';

class AssessmentProvider with ChangeNotifier {
  bool _isLoading = false;
  AssessmentResult? _lastResult;
  Map<String, dynamic>? _lastInput;
  List<AssessmentHistory> _histories = [];

  bool get isLoading => _isLoading;
  AssessmentResult? get lastResult => _lastResult;
  Map<String, dynamic>? get lastInput => _lastInput;
  List<AssessmentHistory> get histories => _histories;

  Future<bool> submitAssessment(Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.dio.post('/assessments/klasifikasi', data: data);

      if (response.statusCode == 201) {
        _lastResult = AssessmentResult.fromJson(response.data);
        _lastInput = data;
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint("Submit Error: $e");
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> fetchAllAssessments() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.dio.get('/assessments/all');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        _histories = data.map((json) => AssessmentHistory.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint("Fetch Error: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<List<AssessmentHistory>> fetchJemaahAssessments(int idUser) async {
    try {
      final response = await ApiService.dio.get('/assessments/user/$idUser');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => AssessmentHistory.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint("Fetch User Assessments Error: $e");
    }
    return [];
  }

  Future<void> fetchMyAssessments() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.dio.get('/assessments/me');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        _histories = data.map((json) => AssessmentHistory.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint("Fetch My Assessments Error: $e");
    }

    _isLoading = false;
    notifyListeners();
  }
}
