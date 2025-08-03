import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:couldai_user_app/components/user_avatar.dart';
import 'package:couldai_user_app/utils/constants.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute(
      builder: (context) => const ChatPage(),
    );
  }

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late final Stream<List<Map<String, dynamic>>> _messagesStream;
  final Map<String, String> _userNicknames = {};

  @override
  void initState() {
    super.initState();
    final userId = supabase.auth.currentUser!.id;
    _messagesStream = supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at')
        .map((maps) => maps.toList());
  }

  Future<void> _loadUserNickname(String userId) async {
    if (!_userNicknames.containsKey(userId)) {
      final response =
          await supabase.from('profiles').select('nickname').eq('id', userId).single();
      if (response != null && response['nickname'] != null) {
        setState(() {
          _userNicknames[userId] = response['nickname'];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        actions: [
          IconButton(
            onPressed: () async {
              await supabase.auth.signOut();
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _messagesStream,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final messages = snapshot.data!;
            return Column(
              children: [
                Expanded(
                  child: messages.isEmpty
                      ? const Center(
                          child: Text('Start your conversation now :)'),
                        )
                      : ListView.builder(
                          reverse: true,
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final message = messages[index];
                            final userId = message['user_id'];

                            _loadUserNickname(userId);

                            return _MessageBubble(
                              message: message,
                              isMe: userId == supabase.auth.currentUser!.id,
                              nickname: _userNicknames[userId],
                            );
                          },
                        ),
                ),
                const _MessageInput(),
              ],
            );
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading messages'));
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isMe,
    this.nickname,
  });

  final Map<String, dynamic> message;
  final bool isMe;
  final String? nickname;

  @override
  Widget build(BuildContext context) {
    final alignment = isMe ? Alignment.centerRight : Alignment.centerLeft;
    final color = isMe
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.secondary;
    final textColor = isMe
        ? Theme.of(context).colorScheme.onPrimary
        : Theme.of(context).colorScheme.onSecondary;

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isMe ? 'You' : (nickname ?? '...'),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: textColor.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message['content'] as String,
              style: TextStyle(color: textColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageInput extends StatefulWidget {
  const _MessageInput();

  @override
  State<_MessageInput> createState() => __MessageInputState();
}

class __MessageInputState extends State<_MessageInput> {
  final _textController = TextEditingController();

  Future<void> _submitMessage() async {
    final text = _textController.text;
    if (text.isEmpty) {
      return;
    }
    _textController.clear();
    try {
      final userId = supabase.auth.currentUser!.id;
      await supabase.from('messages').insert({
        'content': text,
        'user_id': userId,
      });
    } on PostgrestException catch (error) {
      context.showErrorSnackBar(message: error.message);
    } catch (error) {
      context.showErrorSnackBar(message: 'Unexpected error occurred');
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _textController,
              decoration: const InputDecoration(
                hintText: 'Send a message',
                border: InputBorder.none,
                filled: true,
              ),
              onFieldSubmitted: (_) => _submitMessage(),
            ),
          ),
          IconButton(
            onPressed: _submitMessage,
            icon: const Icon(Icons.send),
          ),
        ],
      ),
    );
  }
}
