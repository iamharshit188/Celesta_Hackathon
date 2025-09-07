import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wpfactcheck/core/constants/app_constants.dart';
import 'package:wpfactcheck/core/utils/extensions.dart';
import 'package:wpfactcheck/data/models/fact_check_result.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final FactCheckResult factCheckResult;

  const ChatScreen({
    super.key,
    required this.factCheckResult,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
  }

  void _addWelcomeMessage() {
    final welcomeMessage = ChatMessage(
      content: "Hi! I can help you understand the fact-check results for: \"${widget.factCheckResult.inputText}\"\n\nFeel free to ask me about the sources, methodology, or any other questions you have!",
      isUser: false,
      timestamp: DateTime.now(),
    );
    
    setState(() {
      _messages.add(welcomeMessage);
    });
  }

  void _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isLoading) return;

    // Add user message
    final userMessage = ChatMessage(
      content: message,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      // TODO: Implement actual chat API call
      await Future.delayed(const Duration(seconds: 1));
      
      // Mock response for now
      final response = _getMockResponse(message);
      
      final assistantMessage = ChatMessage(
        content: response,
        isUser: false,
        timestamp: DateTime.now(),
      );

      setState(() {
        _messages.add(assistantMessage);
        _isLoading = false;
      });

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        context.showErrorSnackBar('Failed to send message: ${e.toString()}');
      }
    }
  }

  String _getMockResponse(String userMessage) {
    final message = userMessage.toLowerCase();
    
    if (message.contains('source') || message.contains('sources')) {
      return "The fact-check used ${widget.factCheckResult.sources.length} sources including: ${widget.factCheckResult.sources.take(2).join(', ')}. These sources were selected based on their credibility and relevance to the claim.";
    } else if (message.contains('confidence') || message.contains('sure')) {
      return "The confidence score of ${(widget.factCheckResult.confidenceScore * 100).toInt()}% reflects the strength of available evidence. This score considers source quality, consistency across sources, and completeness of information.";
    } else if (message.contains('how') || message.contains('method')) {
      return "The analysis used ${widget.factCheckResult.modelVersion} to evaluate the claim. The process involved analyzing key assertions, cross-referencing with credible sources, and determining the overall verdict based on available evidence.";
    } else {
      return "Based on the fact-check results, the claim was marked as ${widget.factCheckResult.verdict.name.toUpperCase()}. ${widget.factCheckResult.explanation.substring(0, 100)}... Would you like me to explain any specific aspect in more detail?";
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat about Fact-Check'),
        backgroundColor: context.colorScheme.surface,
        elevation: 1,
      ),
      body: Column(
        children: [
          // Fact-check summary card
          Container(
            margin: const EdgeInsets.all(AppConstants.gridSpacing),
            padding: const EdgeInsets.all(AppConstants.gridSpacing * 2),
            decoration: BoxDecoration(
              color: context.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            ),
            child: Row(
              children: [
                Icon(
                  _getVerdictIcon(widget.factCheckResult.verdict),
                  color: _getVerdictColor(widget.factCheckResult.verdict),
                ),
                const SizedBox(width: AppConstants.gridSpacing),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.factCheckResult.verdict.name.toUpperCase(),
                        style: context.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _getVerdictColor(widget.factCheckResult.verdict),
                        ),
                      ),
                      Text(
                        widget.factCheckResult.inputText,
                        style: context.textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(AppConstants.gridSpacing),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),
          
          // Loading indicator
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(AppConstants.gridSpacing),
              child: Row(
                children: [
                  const SizedBox(width: AppConstants.gridSpacing * 6),
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: AppConstants.gridSpacing),
                  Text(
                    'Thinking...',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          
          // Message input
          Container(
            padding: const EdgeInsets.all(AppConstants.gridSpacing),
            decoration: BoxDecoration(
              color: context.colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: context.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Ask about the fact-check...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.gridSpacing * 2,
                          vertical: AppConstants.gridSpacing,
                        ),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: AppConstants.gridSpacing),
                  FloatingActionButton.small(
                    onPressed: _isLoading ? null : _sendMessage,
                    child: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.gridSpacing),
      child: Row(
        mainAxisAlignment: message.isUser 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: context.colorScheme.primary,
              child: Icon(
                Icons.smart_toy,
                size: 16,
                color: context.colorScheme.onPrimary,
              ),
            ),
            const SizedBox(width: AppConstants.gridSpacing),
          ],
          
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(AppConstants.gridSpacing * 1.5),
              decoration: BoxDecoration(
                color: message.isUser 
                    ? context.colorScheme.primary
                    : context.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppConstants.borderRadius * 1.5),
              ),
              child: Text(
                message.content,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: message.isUser 
                      ? context.colorScheme.onPrimary
                      : context.colorScheme.onSurface,
                ),
              ),
            ),
          ),
          
          if (message.isUser) ...[
            const SizedBox(width: AppConstants.gridSpacing),
            CircleAvatar(
              radius: 16,
              backgroundColor: context.colorScheme.secondary,
              child: Icon(
                Icons.person,
                size: 16,
                color: context.colorScheme.onSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getVerdictColor(FactCheckVerdict verdict) {
    switch (verdict) {
      case FactCheckVerdict.true_:
        return Colors.green;
      case FactCheckVerdict.false_:
        return Colors.red;
      case FactCheckVerdict.partiallyTrue:
        return Colors.orange;
      case FactCheckVerdict.misleading:
        return Colors.deepOrange;
      case FactCheckVerdict.satire:
        return Colors.purple;
      case FactCheckVerdict.unverified:
        return Colors.grey;
    }
  }

  IconData _getVerdictIcon(FactCheckVerdict verdict) {
    switch (verdict) {
      case FactCheckVerdict.true_:
        return Icons.check_circle;
      case FactCheckVerdict.false_:
        return Icons.cancel;
      case FactCheckVerdict.partiallyTrue:
        return Icons.warning_amber;
      case FactCheckVerdict.misleading:
        return Icons.error;
      case FactCheckVerdict.satire:
        return Icons.theater_comedy;
      case FactCheckVerdict.unverified:
        return Icons.help;
    }
  }
}

class ChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.content,
    required this.isUser,
    required this.timestamp,
  });
}
