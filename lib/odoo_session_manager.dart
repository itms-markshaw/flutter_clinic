import 'package:odoo_rpc/odoo_rpc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OdooSessionManager {
  final OdooClient _client = OdooClient('https://your-odoo-server.com');

  Future<OdooSession> login(String dbName, String username, String password) async {
    try {
      OdooSession session = await _client.authenticate(dbName, username, password);
      await _storeSession(session, dbName);
      return session;
    } on OdooException catch (e) {
      print('Login error: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _client.destroySession();
      await _clearSession();
    } on OdooException catch (e) {
      print('Logout error: $e');
    }
  }

  Future<bool> isLoggedIn() async {
    OdooSession? session = await _restoreSession();
    return session != null;
  }

  Future<void> _storeSession(OdooSession session, String dbName) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('session_id', session.id);
    await prefs.setInt('session_user_id', session.userId);
    await prefs.setInt('session_partner_id', session.partnerId);
    await prefs.setString('session_user_login', session.userLogin);
    await prefs.setString('session_user_name', session.userName);
    await prefs.setString('session_user_lang', session.userLang);
    await prefs.setString('session_user_tz', session.userTz);
    await prefs.setBool('session_is_system', session.isSystem);
    await prefs.setString('session_db_name', dbName);
    await prefs.setString('session_server_version', session.serverVersion);
  }

  Future<OdooSession?> _restoreSession() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sessionId = prefs.getString('session_id');
    int? userId = prefs.getInt('session_user_id');
    int? partnerId = prefs.getInt('session_partner_id');
    String? userLogin = prefs.getString('session_user_login');
    String? userName = prefs.getString('session_user_name');
    String? userLang = prefs.getString('session_user_lang');
    String? userTz = prefs.getString('session_user_tz');
    bool? isSystem = prefs.getBool('session_is_system');
    String? dbName = prefs.getString('session_db_name');
    String? serverVersion = prefs.getString('session_server_version');
    if (sessionId != null && userId != null && partnerId != null && userLogin != null && userName != null && userLang != null && userTz != null && isSystem != null && dbName != null && serverVersion != null) {
      return OdooSession(
        id: sessionId,
        userId: userId,
        partnerId: partnerId,
        userLogin: userLogin,
        userName: userName,
        userLang: userLang,
        userTz: userTz,
        isSystem: isSystem,
        dbName: dbName,
        serverVersion: serverVersion,
      );
    }
    return null;
  }

  Future<void> _clearSession() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('session_id');
    await prefs.remove('session_user_id');
    await prefs.remove('session_partner_id');
    await prefs.remove('session_user_login');
    await prefs.remove('session_user_name');
    await prefs.remove('session_user_lang');
    await prefs.remove('session_user_tz');
    await prefs.remove('session_is_system');
    await prefs.remove('session_db_name');
    await prefs.remove('session_server_version');
  }
}
