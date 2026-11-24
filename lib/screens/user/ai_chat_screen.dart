
import 'package:flutter/material.dart';


class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _controller = TextEditingController();

  final List<Map<String, dynamic>> messages = [];

  final Color navy = const Color(0xFF2F4156);
  final Color cream = const Color(0xFFF8F4E8);
  final Color yellow = const Color(0xFFF4C95D);

  void sendMessage() {
    final text = _controller.text.trim();

    if (text.isEmpty) return;

    setState(() {
      messages.add({
        'text': text,
        'isUser': true,
      });

      _controller.clear();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Row(
          children: [
            CircleAvatar(
              backgroundColor: Color(0xFFF4C95D),
              child: Icon(
                Icons.auto_awesome,
                color: Color(0xFF2F4156),
              ),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Assistant',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Asisten pintar LokaBaca',
                  style: TextStyle(fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),

      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(25),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            size: 65,
                            color: navy,
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Halo, selamat datang!',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: navy,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Saya AI Assistant LokaBaca. '
                            'Saya siap membantu pertanyaanmu '
                            'seputar perpustakaan dan buku.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 22),
                          Text(
                            'Ada yang bisa saya bantu?',
                            style: TextStyle(
                              color: navy,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isUser = message['isUser'] as bool;

                      return Align(
                        alignment: isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(13),
                          constraints: BoxConstraints(
                            maxWidth:
                                MediaQuery.of(context).size.width * 0.75,
                          ),
                          decoration: BoxDecoration(
                            color: isUser ? navy : Colors.white,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            message['text'],
                            style: TextStyle(
                              color: isUser ? Colors.white : navy,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Tulis pertanyaan...',
                        filled: true,
                        fillColor: cream,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (_) => sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: yellow,
                    child: IconButton(
                      onPressed: sendMessage,
                      icon: Icon(
                        Icons.send_rounded,
                        color: navy,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
