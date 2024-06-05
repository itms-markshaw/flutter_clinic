import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:flutter_auth/shared_pref.dart';

class GraphQLService {
  static Future<GraphQLClient> initClient() async {
    final prefs = SharedPref();
    final baseUrl = await prefs.readString('baseUrl') ?? '';
    final token = await prefs.readString('sessionToken') ?? ''; // Ensure you have this saved in shared preferences

    final HttpLink httpLink = HttpLink(
      '$baseUrl/graphql',
      defaultHeaders: {
        'Authorization': 'Bearer $token', // Adjust based on your auth method
      },
    );

    return GraphQLClient(
      link: httpLink,
      cache: GraphQLCache(store: InMemoryStore()),
    );
  }
}
