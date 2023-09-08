import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter/services.dart';
import 'package:csv/csv.dart';

class SoundAiApp extends StatefulWidget {
  @override
  _MergedAppState createState() => _MergedAppState();
}

class _MergedAppState extends State<SoundAiApp> {
  final SpeechToText speech = SpeechToText();
  final _controller = TextEditingController();
  bool _hasSpeech = false;
  String lastWords = '';
  List<List<dynamic>> _results = [];
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();
    initSpeechState();
    Future.delayed(Duration(seconds: 4), () {
      setState(() {
        _opacity = 1.0;
      });
    });
  }

  Future<void> initSpeechState() async {
    try {
      var hasSpeech = await speech.initialize();
      if (!mounted) return;

      setState(() {
        _hasSpeech = hasSpeech;
      });
    } catch (e) {
      _hasSpeech = false;
    }
  }

  void startListening() {
    speech.listen(
      onResult: (result) {
        setState(() {
          lastWords = result.recognizedWords;
          _controller.text = lastWords;
          _search(lastWords);
        });
      },
      localeId: 'en_US',
    );
  }

  Future<List<List<dynamic>>> _loadCsvData() async {
    final data = await rootBundle.loadString('assets/drug.csv');
    return CsvToListConverter().convert(data);
  }

  void _search(String searchTerm) async {
    List<List<dynamic>> csvData = await _loadCsvData();

    Set<String> uniqueDrugs = {};

    setState(() {
      _results = csvData
          .where((row) => row[2]
              .toString()
              .toLowerCase()
              .contains(searchTerm.toLowerCase()))
          .where((row) {
        final uniqueKey = '${row[0]}${row[1]}${row[10]}';
        final isNew = !uniqueDrugs.contains(uniqueKey);
        if (isNew) uniqueDrugs.add(uniqueKey);
        return isNew;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        colorScheme: ColorScheme.light().copyWith(
          primary: Colors.teal[700],
        ),
      ),
      home: SafeArea(
        child: Scaffold(
          appBar: AppBar(
            toolbarHeight: 70.0,
            title: Container(
              margin: EdgeInsets.symmetric(vertical: 8),
              child: TextField(
                controller: _controller,
                readOnly: true,
                decoration: InputDecoration(
                  fillColor: Colors.white,
                  filled: true,
                  hintText: 'Speak and search for a drug...',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.mic, color: Colors.tealAccent),
                    onPressed: _hasSpeech ? startListening : null,
                  ),
                ),
              ),
            ),
          ),
          body: Stack(
            children: [
              AnimatedOpacity(
                opacity: _opacity,
                duration: Duration(seconds: 1),
                child: ListView.builder(
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    return AnimatedContainer(
                      duration: Duration(seconds: 1),
                      margin: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.teal.withOpacity(0.1),
                              spreadRadius: 3,
                              blurRadius: 5)
                        ],
                      ),
                      child: ListTile(
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                        title: Text("Drug: ${_results[index][0]}",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                            "Dosage: ${_results[index][1]}\nSideeffects: ${_results[index][10]}"),
                      ),
                    );
                  },
                ),
              ),
              Center(
                child: AnimatedOpacity(
                  opacity: 1.0 - _opacity,
                  duration: Duration(seconds: 1),
                  child: Text(
                    "Hackathon Sound Ai",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: _opacity == 0.0 ? Colors.teal[100] : Colors.white,
        ),
      ),
    );
  }
}
