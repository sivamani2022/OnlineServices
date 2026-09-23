import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/department.dart';
import '../models/service_item.dart';

/// ---------------------------------------------------------------------
/// SET THIS to your deployed Apps Script Web App URL, e.g.
/// https://script.google.com/macros/s/AKfycb.../exec
/// ---------------------------------------------------------------------
const String kApiBaseUrl =
    'https://script.google.com/macros/s/REPLACE_WITH_YOUR_DEPLOYMENT_ID/exec';

class LoginResult {
  final bool success;
  final String? deptId;
  final String? deptName;
  final String? message;
  LoginResult({required this.success, this.deptId, this.deptName, this.message});
}

class ActionResult {
  final bool success;
  final String? message;
  ActionResult({required this.success, this.message});
}

class ApiService {
  static Future<List<Department>> getDepartments() async {
    final uri = Uri.parse('$kApiBaseUrl?action=departments');
    final res = await http.get(uri).timeout(const Duration(seconds: 20));
    final body = jsonDecode(res.body);
    if (body['success'] == true) {
      return (body['data'] as List)
          .map((e) => Department.fromJson(e))
          .toList();
    }
    throw Exception(body['message'] ?? 'Failed to load departments');
  }

  static Future<List<ServiceItem>> getServices(String deptId) async {
    final uri = Uri.parse('$kApiBaseUrl?action=services&deptId=$deptId');
    final res = await http.get(uri).timeout(const Duration(seconds: 20));
    final body = jsonDecode(res.body);
    if (body['success'] == true) {
      return (body['data'] as List)
          .map((e) => ServiceItem.fromJson(e))
          .toList();
    }
    throw Exception(body['message'] ?? 'Failed to load services');
  }

  static Future<LoginResult> login(String username, String password) async {
    final res = await _post({
      'action': 'login',
      'username': username,
      'password': password,
    });
    if (res['success'] == true) {
      return LoginResult(
        success: true,
        deptId: res['deptId'],
        deptName: res['deptName'],
      );
    }
    return LoginResult(success: false, message: res['message']);
  }

  static Future<ActionResult> addService(
      String deptId, String name, String description, String url) async {
    final res = await _post({
      'action': 'addService',
      'deptId': deptId,
      'name': name,
      'description': description,
      'url': url,
    });
    return ActionResult(success: res['success'] == true, message: res['message']);
  }

  static Future<ActionResult> updateService(String deptId, String serviceId,
      String name, String description, String url) async {
    final res = await _post({
      'action': 'updateService',
      'deptId': deptId,
      'serviceId': serviceId,
      'name': name,
      'description': description,
      'url': url,
    });
    return ActionResult(success: res['success'] == true, message: res['message']);
  }

  static Future<ActionResult> deleteService(
      String deptId, String serviceId) async {
    final res = await _post({
      'action': 'deleteService',
      'deptId': deptId,
      'serviceId': serviceId,
    });
    return ActionResult(success: res['success'] == true, message: res['message']);
  }

  static Future<Map<String, dynamic>> _post(Map<String, dynamic> data) async {
    final res = await http
        .post(Uri.parse(kApiBaseUrl), body: jsonEncode(data))
        .timeout(const Duration(seconds: 20));
    return jsonDecode(res.body);
  }
}

/// Simple session persistence so a logged-in department stays logged in
/// between app launches.
class SessionStore {
  static const _kDeptId = 'session_dept_id';
  static const _kDeptName = 'session_dept_name';

  static Future<void> save(String deptId, String deptName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kDeptId, deptId);
    await prefs.setString(_kDeptName, deptName);
  }

  static Future<Map<String, String>?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_kDeptId);
    final name = prefs.getString(_kDeptName);
    if (id == null || name == null) return null;
    return {'deptId': id, 'deptName': name};
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kDeptId);
    await prefs.remove(_kDeptName);
  }
}
