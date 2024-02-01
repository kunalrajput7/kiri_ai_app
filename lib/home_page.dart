import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:kiri_ai/feature_box.dart';
import 'package:kiri_ai/openai_service.dart';
import 'package:kiri_ai/pallete.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final speechToText = SpeechToText();
  String lastWords = '';
  final OpenAIService openAIService = OpenAIService();
  String? generatedContent;
  String? generatedImage;
  bool isFetching = false;
  bool darkMode = false;

  @override
  void initState() {
    super.initState();
    initSpeechtoText();
  }

  Future<void> initSpeechtoText() async {
    await speechToText.initialize();
    setState(() {});
  }

  Future<void> startListening() async {
    await speechToText.listen(onResult: onSpeechResult);
    setState(() {});
  }

  Future<void> stopListening() async {
    //print('Last words before stopping: $lastWords');
    await speechToText.stop();
    setState(() {});
  }

  void onSpeechResult(SpeechRecognitionResult result) {
    setState(() async {
      lastWords = result.recognizedWords;
      print('Recognized words: $lastWords');
      print(speechToText.isListening);

      if (speechToText.isListening == false) {
        setState(() {
          isFetching =
              true; // Here we set the fetching state to true when waiting for API response
        });

        final apiValue = await openAIService.isArtPromptAPI(lastWords);

        setState(() {
          isFetching =
              false; // And here we set loading state to false once API response is received

          if (apiValue.contains('https')) {
            generatedImage = apiValue;
            generatedContent = null;
            print("Image");
          } else {
            generatedImage = null;
            generatedContent = apiValue;
            print("No Image");
          }
        });
      }
    });
  }

  void resetApp() {
    setState(() {
      lastWords = '';
      generatedContent = null;
      generatedImage = null;
      isFetching = false;
    });
  }

  @override
  void dispose() {
    super.dispose();
    speechToText.stop();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: darkMode
          ? ThemeData.dark().copyWith(
              scaffoldBackgroundColor: Pallete.blackColor,
              appBarTheme:
                  const AppBarTheme(backgroundColor: Pallete.blackColor),
            )
          : ThemeData.light(useMaterial3: true).copyWith(
              scaffoldBackgroundColor: Pallete.whiteColor,
              appBarTheme:
                  const AppBarTheme(backgroundColor: Pallete.whiteColor),
            ),
      child: Scaffold(
        appBar: AppBar(
          title: BounceInDown(
            child: const Text(
              'Kiri',
              style: TextStyle(fontSize: 25),
            ),
          ),
          leading: Padding(
            padding: const EdgeInsets.only(left: 20),
            // using padding and transform to adjust the location of the icon according to the app screen
            child: Transform.scale(
              scale: 0.8,
              child: SlideInLeft(
                child: Switch(
                  value: darkMode,
                  onChanged: (value) {
                    setState(() {
                      darkMode = value;
                      print("Dark mode -> $darkMode");
                      // Add your logic here for handling the switch state change
                    });
                  },
                ),
              ),
            ),
          ),
          centerTitle: true,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 5),
              child: Transform.scale(
                scale: 1.15,
                child: SlideInRight(
                  child: IconButton(
                    onPressed: resetApp,
                    icon: const Icon(Icons.refresh),
                  ),
                ),
              ),
            )
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            //this column has a children list, that contains all the different compnents of the app screen
            children: [
              const SizedBox(
                height: 10,
              ),
              // 1. container for the Kiri's image on the app
              ZoomIn(
                child: Container(
                  height: 170,
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                          image: AssetImage('assets/images/kiri_image.png'))),
                ),
              ),
              // This is the loading logo that appears once the API is responding with an answer
              Visibility(
                visible: isFetching,
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              ),
              // 2. the chat bubble
              FadeInRight(
                child: Visibility(
                  visible: generatedImage == null && isFetching == false,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    margin: const EdgeInsets.symmetric(horizontal: 40)
                        .copyWith(top: 30),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Pallete.borderColor,
                      ),
                      borderRadius: BorderRadius.circular(20).copyWith(
                        topLeft: Radius.zero,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        generatedContent == null
                            ? 'Hello there, what task can I do for you?'
                            : generatedContent!,
                        style: TextStyle(
                          color:
                              darkMode ? Colors.white : Pallete.mainFontColor,
                          fontSize: generatedContent == null ? 25 : 18,
                          fontFamily: 'Cera Pro',
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // This is a conditional widget box, which will appear only if the an image is generated by the AI
              if (generatedImage != null)
                Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: ZoomIn(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(
                        generatedImage!,
                      ),
                    ),
                  ),
                ),
              // 3. A well alligned text box above the features
              SlideInLeft(
                child: Visibility(
                  visible: generatedContent == null && generatedImage == null,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    alignment: Alignment.centerLeft,
                    margin: const EdgeInsets.only(top: 10, left: 22),
                    child: Text(
                      'Here are a few features',
                      style: TextStyle(
                        fontFamily: 'Cera Pro',
                        fontSize: 20,
                        color: darkMode ? Colors.white : Pallete.mainFontColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              // 4. displaying the features list for chatbot and dall e and voice comman.
              Visibility(
                visible: generatedContent == null && generatedImage == null,
                child: Column(
                  // here we'll make a list of same functions called with different parameters
                  children: [
                    // 1st Feature box for Kiri
                    SlideInRight(
                      duration: const Duration(milliseconds: 300),
                      child: FeatureBox(
                        color: darkMode
                            ? const Color.fromARGB(255, 117, 108, 108)
                            : Pallete.firstSuggestionBoxColor,
                        headerText: 'Talk to Kiri',
                        descriptionText:
                            'Your smart virtual assistant for seamless conversations and instant answers.',
                      ),
                    ),
                    // 2nd Feature box for Dall E
                    SlideInRight(
                      duration: const Duration(milliseconds: 600),
                      child: FeatureBox(
                        color: darkMode
                            ? const Color.fromARGB(255, 92, 81, 81)
                            : Pallete.secondSuggestionBoxColor,
                        headerText: 'Dall-E',
                        descriptionText:
                            'Transform ideas into visual magic with our innovative image creation feature!',
                      ),
                    ),
                    // 3rd Feature Box for Voice Command
                    SlideInRight(
                      duration: const Duration(milliseconds: 900),
                      child: FeatureBox(
                        color: darkMode
                            ? const Color.fromARGB(255, 150, 139, 139)
                            : Pallete.thirdSuggestionBoxColor,
                        headerText: 'Kiri Speaks',
                        descriptionText:
                            'Get the best of both, by simply speaking with Kiri! >> Tap on 🎙.',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // this is the microphone button to record voices
        floatingActionButton: ZoomIn(
          delay: const Duration(milliseconds: 1200),
          child: Roulette(
            delay: const Duration(milliseconds: 1300),
            child: FloatingActionButton(
              onPressed: () async {
                if (await speechToText.hasPermission &&
                    speechToText.isNotListening) {
                  await startListening();
                } else if (speechToText.isListening) {
                  await stopListening();
                } else {
                  initSpeechtoText();
                }
              },
              child: Icon(
                speechToText.isListening ? Icons.stop : Icons.mic,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
