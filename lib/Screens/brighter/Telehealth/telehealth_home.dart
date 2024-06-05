import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:flutter_auth/graphql_service.dart';
import 'package:url_launcher/url_launcher.dart';

class TeleHealthHome extends StatelessWidget {
  const TeleHealthHome({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<GraphQLClient>(
      future: GraphQLService.initClient(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final client = snapshot.data;

        if (client == null) {
          return const Center(child: Text('Error initializing GraphQL client'));
        }

        return GraphQLProvider(
          client: ValueNotifier(client),
          child: Scaffold(
            appBar: AppBar(
              title: const Text('TeleHealth'),
            ),
            body: Query(
              options: QueryOptions(
                document: gql(r'''
                  query GetChannels {
                    Channels {
                      id
                      name
                    }
                  }
                '''),
              ),
              builder: (QueryResult result, { VoidCallback? refetch, FetchMore? fetchMore }) {
                if (result.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (result.hasException) {
                  return Center(child: Text('Error: ${result.exception.toString()}'));
                }

                final channels = result.data?['Channels'] ?? [];

                return ListView.builder(
                  itemCount: channels.length,
                  itemBuilder: (context, index) {
                    final channel = channels[index];
                    return ListTile(
                      title: Text(channel['name'] ?? 'Unnamed Channel'),
                      onTap: () {
                        final chatUrl = '${client.link.toString().replaceFirst('/graphql', '')}/web#action=mail.action_discuss&active_id=${channel['id']}';
                        launchUrl(Uri.parse(chatUrl));
                      },
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}
