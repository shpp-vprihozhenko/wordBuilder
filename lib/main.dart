import 'dart:async';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'wordsLst.dart';

enum TtsState { playing, stopped, paused, continued }
double letterPlaceSize = 60.0;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Строим слоги и слова',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Строим слоги и слова'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List <String> centralLetters = [];

  String targetWord = '';
  int numCentralLetters = 3;
  int numHotLetters = 5, numColdLetters = 5, counter = 0;
  List <String> listHotLetters, listColdLetters;
  final allHotLetters = 'АЕОУИЫЭЮЯЁ';
  final allColdLetters = 'НТСРВЛКМДПГЗБЧХЖШЦЩФЬЪЙ';
  final specialLetters = '-';
  String targetText = '';
  List<String> wordsList;
  List<String> filteredWordsList;

  List<Widget> listColdLetterWidgets = [];
  List<Widget> listHotLetterWidgets = [];

  bool speakMode = false;
  bool aboutMode = false;

  FlutterTts flutterTts;
  dynamic languages;
  String language;
  double volume = 1;
  double pitch = 1.2;
  double rate = 1;

  @override
  void initState() {
    super.initState();
    initTts();
    wordsList =  WordsList.getList();
    startLoop();
  }

  void startLoop() {
    filteredWordsList = wordsList.where((el) => el.length == numCentralLetters).toList();
    formTargetWord();
    formHotColdLettersLists();
    targetText = "Собери ${targetWord.length == 2? 'слог':'слово'} $targetWord";
    _speak(targetText, true);
  }
  
  void formTargetWord() {
    var rng = new Random();
    targetWord = filteredWordsList[rng.nextInt(filteredWordsList.length)].toUpperCase();
    print('ts $targetWord');
  }

  List shuffle(List items) {
    var random = new Random();
    for (var i = items.length - 1; i > 0; i--) {
      var n = random.nextInt(i + 1);
      var temp = items[i];
      items[i] = items[n];
      items[n] = temp;
    }
    return items;
  }

  String anyLetter(var rng, String allLetters, List<String> listUsedLetters) {
    String letter = '';
    do {
      int pos = rng.nextInt(allLetters.length);
      letter = allLetters.substring(pos, pos+1);
      if (listUsedLetters.indexOf(letter) > -1) {
        letter = '';
      }
    } while (letter == '');
    return letter;
  }

  void formHotColdLettersLists() {
    listHotLetters = []; listColdLetters = [];
    listHotLetterWidgets = []; listColdLetterWidgets = [];

    var rng = new Random();

    for (int i = 0; i < numHotLetters; i++) {
      String selectedLetter = '';
      if (i < targetWord.length) {
        String ch = targetWord.substring(i, i+1);
        if (allHotLetters.indexOf(ch) > -1) {
          selectedLetter = ch;
        }
      }
      if (selectedLetter == '') {
        selectedLetter = anyLetter(rng, allHotLetters, listHotLetters); //allHotLetters[rng.nextInt(hTotal)];
      }
      listHotLetters.add(selectedLetter);
    }

    shuffle(listHotLetters);
    formWidgetsList(listHotLetters, listHotLetterWidgets);

    for (int i = 0; i < numColdLetters; i++) {
      String selectedLetter = '';
      if (i < targetWord.length) {
        String ch = targetWord.substring(i, i+1);
        if (allColdLetters.indexOf(ch) > -1) {
          selectedLetter = ch;
        }
      }
      if (selectedLetter == '') {
        selectedLetter = anyLetter(rng, allColdLetters, listColdLetters); //allHotLetters[rng.nextInt(hTotal)];
      }
      listColdLetters.add(selectedLetter);
    }

    shuffle(listColdLetters);
    formWidgetsList(listColdLetters, listColdLetterWidgets);
  }

  void formWidgetsList(List<String> lettersList, List<Widget> lw) {
    for(int i=0; i<lettersList.length; i++) {
      lw.add(ContWithDLetter(letter: lettersList[i]));
    }
  }

  initTts() {
    flutterTts = FlutterTts();
    _setSpeakParameters();
  }

  Future _setSpeakParameters() async {
    await flutterTts.setVolume(volume);
    await flutterTts.setSpeechRate(rate);
    await flutterTts.setPitch(pitch);
    // ru-RU uk-UA en-US
    await flutterTts.setLanguage('ru-RU');
  }

  Future<void> _speak(String _text, bool asyncMode) async {
    if (_text != null) {
      if (_text.isNotEmpty) {
        if (asyncMode) {
          flutterTts.speak(_text);
        } else {
          await flutterTts.speak(_text);
        }
      }
    }
  }

  Future<void> _speakSync(String _text) {
    final c = new Completer();
    flutterTts.setCompletionHandler(() {
      c.complete("ok");
    });
    _speak(_text, false);
    return c.future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: buildBodyContainer(),
      bottomNavigationBar:
        Container(
          color: Colors.blue[100],
          child: buildBottomRow(),
        )
    );
  }

  Widget buildBottomRow() {
    if (aboutMode) {
      return SizedBox(height: 50,);
    }
    return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            FloatingActionButton(
                onPressed: (){
                  setState(() {
                    aboutMode = true;
                  });
                },
                tooltip: 'О программе',
                child: Icon(Icons.sentiment_satisfied, size: 40, color: Colors.redAccent,)
            ),
            FloatingActionButton(
                onPressed: difDown,
                tooltip: 'короче слово',
                child: Icon(Icons.arrow_back_ios, size: 40, color: Colors.redAccent,)
            ),
            FloatingActionButton(
                onPressed: difUp,
                tooltip: 'длинее слово',
                child: Icon(Icons.arrow_forward_ios, size: 40, color: Colors.redAccent,)
            ),
            FloatingActionButton(
                onPressed: _repeatCurSyl,
                tooltip: 'Повторить задание',
                child: Icon(Icons.volume_up, size: 40, color: Colors.redAccent,)
            ),
          ],
        );
  }

  Container buildBodyContainer() {
    if (aboutMode) {
      return buildAboutContainer();
    } else {
      return buildMainContainer();
    }
  }

  Container buildAboutContainer() {
    return Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.grey[300],
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: ListView(
            children: [
              SizedBox(height: 20,),
              Text('Предложите ребёнку поиграть - собрать услышанное слово из буковок на экране, перетаскивая их в центральные окошки.',
                textAlign: TextAlign.center, textScaleFactor: 1.5,),
              SizedBox(height: 20,),
              Text('Автор идеи и разработчик - Прихоженко Владимир',
                textAlign: TextAlign.center, textScaleFactor: 1.5, style: TextStyle(color: Colors.blueAccent),
              ),
              SizedBox(height: 20,),
              Text('Все вопросы и пожелания прошу слать на е-мейл vprihogenko@gmail.com',
                textAlign: TextAlign.center, textScaleFactor: 1.5, style: TextStyle(color: Colors.blueAccent),
              ),
              SizedBox(height: 20,),
              FloatingActionButton(
                  onPressed: ()=>{
                    setState(() {
                      aboutMode = false;
                    })
                  },
                  child: Text('ok', textScaleFactor: 2,),
              ),
              SizedBox(height: 20,),
            ],
          ),
        ),
    );
  }

  Container buildMainContainer() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child:
        Column(
          children: <Widget>[
            Expanded(
              flex: 2,
              child: hotLettersBlock(),
            ),
            Container(
              padding: EdgeInsets.all(10),
              color: CupertinoColors.activeOrange,
              //width: double.infinity,
              //height: 80,
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                runAlignment: WrapAlignment.center,
                children: listOfDrags(),
              ),
            ),
            Expanded(
              flex: 2,
              child: coldLettersBlock(),
            ),
          ],
        ),
    );
  }

  Widget coldLettersBlock() {
    if (numColdLetters < 6) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            runAlignment: WrapAlignment.center,
            children: listColdLetterWidgets,
          ),
        ],
      );
    }
    return SingleChildScrollView(
              padding: EdgeInsets.all(10),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                runAlignment: WrapAlignment.center,
                children: listColdLetterWidgets,
              ),
            );
  }

  Widget hotLettersBlock() {
    if (numHotLetters < 6 ){
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            runAlignment: WrapAlignment.center,
            children: listHotLetterWidgets,
          ),
        ],
      );
    }
    return SingleChildScrollView(
              padding: EdgeInsets.all(10),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                runAlignment: WrapAlignment.center,
                children: listHotLetterWidgets,
              ),
            );
  }

  List<Widget> listOfDrags() {
    List<Widget> lw = [];
    for (var i=0; i<numCentralLetters; i++) {
      if (centralLetters.length <= i){
        centralLetters.add('');
      }
      lw.add(DragTarget(
        builder: (context, candidateData, rejectedData) =>
            Container(width: letterPlaceSize, height: letterPlaceSize,
              decoration: new BoxDecoration(color: Colors.yellow[200], shape: BoxShape.circle,),
              child: Center(child: Text(centralLetters[i], textScaleFactor: 3, style: TextStyle(color: Colors.blue), textAlign: TextAlign.center,)),
            ),
        onAccept: (String data){
          setState(() {
            centralLetters[i] = data;
          });
          Future.delayed(Duration.zero, () => speakCentralLettersAndStartNewLoop(context));
        },
      ));
    }
    return lw;

  }

  void _repeatCurSyl() {
    print(targetText);
    _speak(targetText, true);
  }

  speakCentralLettersAndStartNewLoop(BuildContext context) async {
    if (speakMode) {
      return;
    }
    speakMode = true;
    String res = '';
    bool allLettersCompleted = true;
    for (int i=0; i<numCentralLetters; i++) {
      if (centralLetters[i]=='') {
        allLettersCompleted = false;
        break;
      }
      res += centralLetters[i];
    }
    if (allLettersCompleted) {
      if (res == targetWord) {
        await _speakSync('Правильно! Получилось $res !');
        nextLoop();
      } else {
        await _speakSync('Неправильно. Получилось $res, а надо $targetWord !');
        await _speakSync('Попробуй ещё раз.');
      }
      Future.delayed(const Duration(milliseconds: 1000), () {
        setState(() {
          clearCentralLetters();
        });
      });
    }
    speakMode = false;
  }

  void clearCentralLetters() {
    for (int i=0; i<numCentralLetters; i++) {
      centralLetters[i]='';
    }
  }

  void nextLoop() {
    counter++;
    if (counter%20 == 0) {
      if (numColdLetters < 6) {
        numCentralLetters++;
      }
    }
    if (counter%10 == 0) {
      if (numHotLetters < allHotLetters.length) {
        numHotLetters++;
      }
      if (numColdLetters < allColdLetters.length) {
        numColdLetters++;
      }
    }
    startLoop();
  }

  void restart() {
    setState(() {
      numCentralLetters = 3; numHotLetters = 5; numColdLetters = 5; counter = 0;
      startLoop();
    });
  }

  void difUp() {
    setState(() {
      if (numCentralLetters < 7) {
        numCentralLetters++;
        if (numCentralLetters>4) {
          numColdLetters++;
          numHotLetters++;
        }
      } else {
        if (numHotLetters < allHotLetters.length) {
          numHotLetters++;
        }
        if (numColdLetters < allColdLetters.length) {
          numColdLetters++;
        }
      }
    });
    startLoop();
  }

  void difDown() {
    setState(() {
      if (numCentralLetters > 2) {
        numCentralLetters--;
      } else {
        numHotLetters = 5;
        numColdLetters = 5;
      }
    });
    startLoop();
  }
}

class CircleButton extends StatelessWidget {
  final GestureTapCallback onTap;
  final String letter;

  const CircleButton({Key key, this.onTap, this.letter}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return new InkResponse(
      onTap: onTap,
      child: ContWithDLetter(letter: letter),
    );
  }
}

class ContWithDLetter extends StatelessWidget {
  const ContWithDLetter({
    Key key,
    @required this.letter,
  }) : super(key: key);

  final String letter;

  @override
  Widget build(BuildContext context) {
    Color fColor = 'АЕЁОУИЫЭЮЯ'.indexOf(this.letter)==-1 ? Colors.green:Colors.red;
    return new Container(
      width: letterPlaceSize,
      height: letterPlaceSize,
      //decoration: new BoxDecoration(
        //color: Colors.white,
        //shape: BoxShape.circle,
      //),
      child: Draggable(
        child: Container(
            width: letterPlaceSize, height: letterPlaceSize, color: Colors.lightGreen[100],
            child: Center(child: Text(this.letter, textAlign: TextAlign.center, textScaleFactor: 3, style: TextStyle(color: fColor),))
        ),
        feedback: Text(this.letter, textAlign: TextAlign.center, textScaleFactor: 1, style: TextStyle(color: Colors.blueAccent),),
        data: this.letter,
      )
    );
  }
}

