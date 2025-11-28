import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, String>> _messages = [];

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isNotEmpty) {
      setState(() {
        _messages.add({'role': 'user', 'content': message});
      });
      _messageController.clear();
      
      // Pass chat history to maintain context
      final chatHistory = _messages.map((msg) => {
        'role': msg['role']!,
        'content': msg['content']!
      }).toList();
      
      context.read<FoodAppState>().sendMessage(message, chatHistory: chatHistory).then((_) {
        final response = context.read<FoodAppState>().chatResponse;
        setState(() {
          _messages.add({'role': 'assistant', 'content': response});
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<FoodAppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Assistant'),
        actions: [
          // Model selection dropdown
          DropdownButton<String>(
            value: appState.selectedModel,
            onChanged: (newModel) {
              if (newModel != null) {
                appState.setSelectedModel(newModel);
              }
            },
            items: appState.availableModels.map((model) {
              final displayName = model.split('/').last;
              return DropdownMenuItem(
                value: model,
                child: Text(
                  displayName.length > 15 
                    ? '${displayName.substring(0, 15)}...' 
                    : displayName,
                  style: const TextStyle(fontSize: 12),
                ),
              );
            }).toList(),
          ),
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: () {
              setState(() {
                _messages.clear();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: _messages.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Ask me about recipes, cooking tips,\nor anything food-related!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isUser = message['role'] == 'user';
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          mainAxisAlignment: isUser 
                              ? MainAxisAlignment.end 
                              : MainAxisAlignment.start,
                          children: [
                            if (!isUser)
                              const CircleAvatar(
                                child: Icon(Icons.assistant),
                              ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isUser 
                                      ? Colors.green[100] 
                                      : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(message['content']!),
                              ),
                            ),
                            if (isUser)
                              const SizedBox(width: 8),
                            if (isUser)
                              const CircleAvatar(
                                child: Icon(Icons.person),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          
          // Loading indicator
          if (appState.isLoading)
            const LinearProgressIndicator(),
          
          // Message input
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Ask about recipes or cooking...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}