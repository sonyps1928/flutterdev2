import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:speech_to_text/speech_to_text.dart';
import 'package:firebase_database/firebase_database.dart';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Firebase App',
      home: SpeechToTextScreen(),
    );
  }
}

class SpeechToTextScreen extends StatefulWidget {
  @override
  _SpeechToTextScreenState createState() => _SpeechToTextScreenState();
}

class _SpeechToTextScreenState extends State<SpeechToTextScreen> {
  SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _lastWords = '';
  
  final DatabaseReference _database = FirebaseDatabase.instance.ref('speech_to_text_data');

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  /// This has to happen only once or SpeechToText will fail.
  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  /// Starts the speech recognition session
  void _startListening() async {
    await _speechToText.listen(onResult: _onSpeechResult);
    setState(() {});
  }

  /// Stops the currently active speech recognition session
  /// Will not stop if simply paused
  void _stopListening() async {
    await _speechToText.stop();
    setState(() {});
  }

  /// This is the callback that the SpeechToText plugin calls when
  /// the platform returns recognized words.
  void _onSpeechResult(result) {
    setState(() {
      _lastWords = result.recognizedWords;
      _database.push().set({'text': _lastWords, 'timestamp': DateTime.now().toIso8601String()});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Speech to Text'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              padding: EdgeInsets.all(16),
              child: Text(
                'Recognized words:',
                style: TextStyle(fontSize: 20.0),
              ),
            ),
            Expanded(
              child: Container(
                padding: EdgeInsets.all(16),
                child: Text(
                  // If not listening, show the last words recognized
                  _speechToText.isNotListening
                      ? _lastWords
                      : _speechToText.status,
                  style: const TextStyle(
                    fontSize: 25.0,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
            ),
            Container(
              child: FloatingActionButton(
                onPressed:
                    // If not yet listening for speech start, otherwise stop
                    _speechToText.isNotListening ? _startListening : _stopListening,
                tooltip: 'Listen',
                child: Icon(_speechToText.isNotListening ? Icons.mic_off : Icons.mic),
              ),
            ),
          ],
        ),
      ),
    );
  }
}