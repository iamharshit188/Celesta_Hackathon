import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:wpfactcheck/core/constants/app_constants.dart';
import 'package:wpfactcheck/core/utils/extensions.dart';
import 'package:wpfactcheck/core/utils/validators.dart';
import 'package:wpfactcheck/presentation/shared_widgets/fact_check_result_sheet.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen>
    with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final SpeechToText _speechToText = SpeechToText();
  
  bool _isListening = false;
  bool _isAnalyzing = false;
  bool _speechEnabled = false;
  String _lastWords = '';
  
  late AnimationController _micAnimationController;
  late Animation<double> _micAnimation;
  
  @override
  void initState() {
    super.initState();
    _initSpeech();
    _setupAnimations();
  }

  void _setupAnimations() {
    _micAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _micAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _micAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  void _startListening() async {
    if (!_speechEnabled) return;
    
    await _speechToText.listen(
      onResult: _onSpeechResult,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      listenOptions: SpeechListenOptions(partialResults: true),
      localeId: 'en_US',
      onSoundLevelChange: (level) {
        // Animate mic based on sound level
        if (_isListening) {
          _micAnimationController.animateTo(level / 100);
        }
      },
    );
    
    setState(() {
      _isListening = true;
    });
    
    _micAnimationController.repeat(reverse: true);
    HapticFeedback.lightImpact();
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {
      _isListening = false;
    });
    _micAnimationController.stop();
    _micAnimationController.reset();
    HapticFeedback.lightImpact();
  }

  void _onSpeechResult(result) {
    setState(() {
      _lastWords = result.recognizedWords;
      _textController.text = _lastWords;
    });
  }

  void _analyzeText() async {
    final text = _textController.text.trim();
    
    if (text.isEmpty) {
      context.showErrorSnackBar('Please enter text or URL to analyze');
      return;
    }

    if (!Validators.isValidFactCheckText(text) && !Validators.isValidUrl(text)) {
      context.showErrorSnackBar('Text must be between 10-5000 characters or a valid URL');
      return;
    }

    setState(() {
      _isAnalyzing = true;
    });

    HapticFeedback.mediumImpact();

    try {
      // TODO: Implement actual fact-checking logic with providers
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call
      
      // Show result sheet
      if (mounted) {
        _showResultSheet();
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Analysis failed: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }

  void _showResultSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const FactCheckResultSheet(
        // TODO: Pass actual result data
      ),
    );
  }

  void _clearText() {
    _textController.clear();
    setState(() {
      _lastWords = '';
    });
    HapticFeedback.selectionClick();
  }

  @override
  void dispose() {
    _textController.dispose();
    _micAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WP FactCheck'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _clearText,
            icon: const Icon(Icons.clear_all),
            tooltip: 'Clear text',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.gridSpacing * 2),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Card(
                      elevation: AppConstants.cardElevation,
                      child: Padding(
                        padding: const EdgeInsets.all(AppConstants.gridSpacing * 3),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Enter text or URL to fact-check',
                              style: context.textTheme.titleLarge,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppConstants.gridSpacing * 3),
                            
                            // Text input field
                            TextField(
                              controller: _textController,
                              maxLines: 8,
                              maxLength: 5000,
                              decoration: InputDecoration(
                                hintText: 'Paste a news article, claim, or URL here...',
                                helperText: 'Supports text (10-5000 chars) or URLs',
                                suffixIcon: _textController.text.isNotEmpty
                                    ? IconButton(
                                        onPressed: _clearText,
                                        icon: const Icon(Icons.clear),
                                      )
                                    : null,
                              ),
                              onChanged: (value) => setState(() {}),
                            ),
                            
                            const SizedBox(height: AppConstants.gridSpacing * 2),
                            
                            // Voice input indicator
                            if (_isListening) ...[
                              Container(
                                padding: const EdgeInsets.all(AppConstants.gridSpacing),
                                decoration: BoxDecoration(
                                  color: context.colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.mic,
                                      color: context.colorScheme.primary,
                                    ),
                                    const SizedBox(width: AppConstants.gridSpacing),
                                    Expanded(
                                      child: Text(
                                        _lastWords.isEmpty 
                                            ? 'Listening...' 
                                            : _lastWords,
                                        style: context.textTheme.bodyMedium?.copyWith(
                                          color: context.colorScheme.onPrimaryContainer,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: AppConstants.gridSpacing * 2),
                            ],
                            
                            // Action buttons
                            Row(
                              children: [
                                // Voice input button
                                if (_speechEnabled)
                                  AnimatedBuilder(
                                    animation: _micAnimation,
                                    builder: (context, child) {
                                      return Transform.scale(
                                        scale: _micAnimation.value,
                                        child: FloatingActionButton(
                                          onPressed: _isListening ? _stopListening : _startListening,
                                          backgroundColor: _isListening 
                                              ? context.colorScheme.error
                                              : context.colorScheme.primary,
                                          child: Icon(
                                            _isListening ? Icons.mic_off : Icons.mic,
                                            color: _isListening 
                                                ? context.colorScheme.onError
                                                : context.colorScheme.onPrimary,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                
                                const SizedBox(width: AppConstants.gridSpacing * 2),
                                
                                // Analyze button
                                Expanded(
                                  child: FilledButton.icon(
                                    onPressed: _isAnalyzing ? null : _analyzeText,
                                    icon: _isAnalyzing
                                        ? SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(
                                                context.colorScheme.onPrimary,
                                              ),
                                            ),
                                          )
                                        : const Icon(Icons.fact_check),
                                    label: Text(_isAnalyzing ? 'Analyzing...' : 'Check Facts'),
                                    style: FilledButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppConstants.gridSpacing * 3,
                                        vertical: AppConstants.gridSpacing * 2,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              // Bottom info
              Padding(
                padding: const EdgeInsets.only(top: AppConstants.gridSpacing * 2),
                child: Text(
                  'Powered by AI • Made by ${AppConstants.teamName}',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
