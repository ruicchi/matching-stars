import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:window_manager/window_manager.dart';
import 'package:match_2_card_game/database_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  sqfliteFfiInit(); // Initialize FFI support

  databaseFactory = databaseFactoryFfi;
  // Initialize the window manager
  await windowManager.ensureInitialized();

  // Set the initial window size
  await windowManager.setSize(Size(1280, 720));

  // Restrict resizing to prevent going below 1280x720
  await windowManager.setMinimumSize(Size(1280, 720));

  windowManager.setAspectRatio(16 / 9);

  runApp(Match2Game());
}

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

class Match2Game extends StatelessWidget {
  const Match2Game({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorObservers: [routeObserver],
      debugShowCheckedModeBanner: false,
      title: 'Group 4\'s Matching Stars',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[200],
      ),
      home: HomePage(),
    );
  }
}
class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  _LeaderboardPageState createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  List<Map<String, dynamic>> scores = [];

  @override
  void initState() {
    super.initState();
    _loadScores();
  }

  void _loadScores() async {
    final result = await DatabaseHelper.instance.getTopScores();
    setState(() {
      scores = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Leaderboards")),
      body: ListView.builder(
        itemCount: scores.length,
        itemBuilder: (context, index) {
          final item = scores[index];
          return ListTile(
            leading: Text('#${index + 1}'),
            title: Text(item['playerName']),
            subtitle: Text('Score: ${item['score']} | Difficulty: ${item['difficulty']}'),
          );
        },
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver, RouteAware {
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _playHomePageMusic();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);
  }

  @override
  void didPopNext() {
    _playHomePageMusic(); // Restart music when coming back to homepage
  }

  void _showDifficultyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Select Difficulty"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: ElevatedButton(
                  onPressed: () {
                    _stopHomePageMusic();
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GamePage(difficulty: "easy"),
                      ),
                    );
                  },
                  child: Text("Easy"),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: ElevatedButton(
                  onPressed: () {
                    _stopHomePageMusic();
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GamePage(difficulty: "medium"),
                      ),
                    );
                  },
                  child: Text("Medium"),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: ElevatedButton(
                  onPressed: () {
                    _stopHomePageMusic();
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GamePage(difficulty: "hard"),
                      ),
                    );
                  },
                  child: Text("Hard"),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  
  // Play homepage background music
  void _playHomePageMusic() async {
    await _audioPlayer.stop();
    await _audioPlayer.setSource(AssetSource('sounds/homepage_bg_music.mp3'));
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    await _audioPlayer.setVolume(0.4);
    await _audioPlayer.seek(Duration.zero);
    _audioPlayer.play(AssetSource('sounds/homepage_bg_music.mp3'));
  }

  // Stop homepage background music
  void _stopHomePageMusic() async {
    await _audioPlayer.stop();
  }

  @override
  void dispose() {
    _stopHomePageMusic();
    WidgetsBinding.instance.removeObserver(this);
    routeObserver.unsubscribe(this); // Unsubscribe when leaving
    super.dispose();
  }
  
  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text(
        "Matching Stars",
        style: TextStyle(
          fontFamily: 'Stepalange',
          fontSize: 24,
          color: Colors.white,
        ),
      ),
      backgroundColor: Colors.blueGrey,
    ),
    body: SingleChildScrollView(
      child: Column(
        children: [
          // Fixed 16:9 homepage banner
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/homepage_bg.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Group 4's",
                    style: TextStyle(
                      fontSize: 36,
                      fontFamily: 'Stepalange',
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  Text(
                    "Matching Stars",
                    style: TextStyle(
                      fontSize: 48,
                      fontFamily: 'Stepalange',
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    "A card-matching game",
                    style: TextStyle(
                      fontSize: 30,
                      fontFamily: 'Stepalange',
                      fontStyle: FontStyle.italic,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 40),
                  Image.asset(
                    'assets/images/Sun_Logo.png',
                    width: 150,
                    height: 150,
                  ),
                  SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Image.asset(
                        'assets/images/Twinkle.png',
                        width: 60,
                        height: 60,
                      ),
                      ElevatedButton(
                        onPressed: () {
                          _showDifficultyDialog(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.yellow[200],
                          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                          textStyle: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        child: Text("Start Game"),
                      ),
                      Image.asset(
                        'assets/images/Twinkle.png',
                        width: 60,
                        height: 60,
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => LeaderboardPage()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.yellow[200],
                      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                      textStyle: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: Text("Leaderboards"),
                  ),
                ],
              ),
            ),
          ),

          // 🔥 New Card Info Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Learn About the Cards',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Stepalange',
                  ),
                ),
                SizedBox(height: 12),
                _buildCardInfoSection(),
              ],
            ),
          ),
        ],
      ),
    ),
  );
  }
}

Widget _buildCardInfoSection() {
  final cards = [
    {
      'title': 'Asteroid',
      'description': 'A rocky object that orbits the Sun, mostly found between Mars and Jupiter.',
      'image': 'assets/images/Asteroid.png',
    },
    {
      'title': 'Astronaut',
      'description': 'A person trained to travel and work in space.',
      'image': 'assets/images/Astronaut.png',
    },
    {
      'title': 'Aurora',
      'description': 'Colorful lights in the sky caused by solar energy hitting Earth’s atmosphere.',
      'image': 'assets/images/Aurora.png',
    },
    {
      'title': 'Black Hole',
      'description': 'A space object with gravity so strong that it pulls anything near it and nothing can escape it.',
      'image': 'assets/images/Black_Hole.png',
    },
    {
      'title': 'Comet',
      'description': 'A ball of ice and dust that leaves a glowing tail when near the Sun.',
      'image': 'assets/images/Comet.png',
    },
    {
      'title': 'Constellation',
      'description': 'A group of stars forming a pattern in the sky.',
      'image': 'assets/images/Constellation.png',
    },
    {
      'title': 'Earth',
      'description': 'Third planet from the Sun. Known for being the only planet that harbors water and life.',
      'image': 'assets/images/Earth.png',
    },
    {
      'title': 'Eclipse',
      'description': 'When one space object blocks the light from another.',
      'image': 'assets/images/Eclipse.png',
    },
    {
      'title': 'Jetpack',
      'description': 'A wearable device that lets people fly for short distances.',
      'image': 'assets/images/Jetpack.png',
    },
    {
      'title': 'Jupiter',
      'description': 'The fifth planet from the Sun and known as the largest planet in our solar system with a big red storm.',
      'image': 'assets/images/Jupiter.png',
    },
    {
      'title': 'Mars',
      'description': 'Fourth planet from the Sun.Known for its signature rocky and red soil with a thin layer of atmosphere.',
      'image': 'assets/images/Mars.png',
    },
    {
      'title': 'Mercury',
      'description': 'The nearest planet from the Sun. It is also known as the smallest planet in the solar system.',
      'image': 'assets/images/Mercury.png',
    },
    {
      'title': 'Meteor Shower',
      'description': 'Many meteors appearing in the sky at once, often from a comet.',
      'image': 'assets/images/Meteor_Shower.png',
    },
    {
      'title': 'Meteor',
      'description': 'A space rock that burns brightly as it falls through Earth/s atmosphere.',
      'image': 'assets/images/Meteor.png',
    },
    {
      'title': 'Milky Way',
      'description': 'The galaxy where our solar system is located.',
      'image': 'assets/images/Milky_Way.png',
    },
    {
      'title': 'Moon',
      'description': 'An object that orbits a planet or something else that is not a star.',
      'image': 'assets/images/Moon.png',
    },
    {
      'title': 'Neptune',
      'description': 'The eighth planet from the Sun and known as a cold, blue planet, far from the Sun.',
      'image': 'assets/images/Neptune.png',
    },
    {
      'title': 'Pluto',
      'description': 'The ninth planet from the Sun and also known as a small, icy dwarf planet beyond Neptune.',
      'image': 'assets/images/Pluto.png',
    },
    {
     'title': 'Rocket',
      'description': 'Vehicles that launch into space using powerful engines.',
      'image': 'assets/images/Rocket.png',
    },
    {
      'title': 'Satellite',
      'description': 'An object that orbits a planet, either natural like the Moon or man-made',
      'image': 'assets/images/Satellite.png',
    },
    {
      'title': 'Saturn',
      'description': 'The sixth planet from the Sun and is also the second largest planet in the solar system. A gas giant known for its signature ring system.',
      'image': 'assets/images/Saturn.png',
    },
    {
      'title': 'Stars',
      'description': 'A giant ball of burning gas that gives off light and heat.',
      'image': 'assets/images/Stars.png',
    },
    {
      'title': 'Sun',
      'description': 'The central object of our solar system, a massive, hot ball of plasma primarily composed of hydrogen and helium, and the source of light and heat for Earth.',
      'image': 'assets/images/Sun.png',
    },
    {
      'title': 'Super Giant',
      'description': 'A massive star that is much larger and brighter than the Sun.',
      'image': 'assets/images/Super_Giant.png',
    },
    {
      'title': 'Supernova',
      'description': 'A powerful explosion of a dying star.',
      'image': 'assets/images/Supernova.png',
    },
    {
      'title': 'Telescope',
      'description': 'A tool that helps us see faraway objects in space.',
      'image': 'assets/images/Telescope.png',
    },
    {
      'title': 'UFO',
      'description': 'An unidentified flying object seen in the sky.',
      'image': 'assets/images/UFO.png',
    },
    {
      'title': 'Uranus',
      'description': 'The seventh planet from the Sun and also known as a cold, pale-blue planet that has faint rings.',
      'image': 'assets/images/Uranus.png',
    },
    {
      'title': 'Venus',
      'description': 'Second planet from the Sun. Known for being the hottest planet in the solar system.',
      'image': 'assets/images/Venus.png',
    },
    {
      'title': 'Wormhole',
      'description': 'A theoretical tunnel in space that could connect distant places.',
      'image': 'assets/images/Wormhole.png',
    },
  ];

  return SizedBox(
  height: 900,
  child: LayoutBuilder(
    builder: (context, constraints) {
      int cardsPerRow = 10;

      double cardWidth = constraints.maxWidth / cardsPerRow;
      cardWidth = cardWidth < 120 ? 120 : cardWidth;

      double cardAspectRatio = 750 / 1050;
      double cardHeight = cardWidth / cardAspectRatio;

      return GridView.builder(
        physics: const BouncingScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cardsPerRow,
          childAspectRatio: cardWidth / (cardHeight + 50),
          crossAxisSpacing: 12.0,
          mainAxisSpacing: 12.0,
        ),
        itemCount: cards.length,
        itemBuilder: (context, index) {
          final card = cards[index];

          return GestureDetector(
            onTap: () {
              showDialog(
  context: context,
  builder: (_) => Dialog(
    insetPadding: const EdgeInsets.all(16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: LayoutBuilder(
      builder: (context, constraints) {
        // Set a max width for the dialog content
        double dialogMaxWidth = 600;
        double dialogWidth = constraints.maxWidth < dialogMaxWidth
            ? constraints.maxWidth * 0.9
            : dialogMaxWidth;

        double imageAspectRatio = 750 / 1050;
        double imageWidth = dialogWidth;
        double imageHeight = imageWidth / imageAspectRatio;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: dialogMaxWidth),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.rotationY(3.14159),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        card['image']!,
                        width: imageWidth,
                        height: imageHeight,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    card['title']!,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    card['description']!,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Close'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  ),
);

            },
            child: Column(
              children: [
                Container(
                  width: cardWidth,
                  height: cardHeight,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.rotationY(3.14159),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                        image: DecorationImage(
                          image: AssetImage(card['image']!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Text(
                    card['title']!,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  ),
);

}


class RotationYTransition extends StatelessWidget {
  final Animation<double> turns;
  final Widget front;
  final Widget back;

  const RotationYTransition({super.key, 
    required this.turns,
    required this.front,
    required this.back,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: turns,
      builder: (context, child) {
        final angle = turns.value * pi;
        final isUnder = (angle > pi / 2);
        final transform = Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateY(angle);

        return Transform(
          alignment: Alignment.center,
          transform: transform,
          child: isUnder ? back : front,
        );
      },
    );
  }
}


class CardModel {
  final String imagePath;
  bool isFlipped;
  bool isMatched;

  CardModel({
    required this.imagePath,
    this.isFlipped = false,
    this.isMatched = false,
  });
}

class GamePage extends StatefulWidget {
  final String difficulty;

  const GamePage({super.key, required this.difficulty});

  @override
  _GamePageState createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> with TickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<CardModel> cards = [];
  bool wait = false;
  int score = 0;
  int combo = 1;
  late Timer _timer;
  late int remainingTime;
  late int columns;
  late int rows;

  late AnimationController _backgroundController;
  late final Animation<double> _backgroundAnimation;

  @override
  void initState() {
    super.initState();
    if (widget.difficulty == "easy") {
      remainingTime = 180; // 3 minutes
    } else if (widget.difficulty == "medium") {
      remainingTime = 300; // 5 minutes
    } else if (widget.difficulty == "hard") {
      remainingTime = 420; // 7 minutes
    }
    _playBackgroundMusic();
    cards = _generateShuffledCards();
    _startTimer();

    _backgroundController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 30),
    )..repeat(); // This loops the animation

    _backgroundAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_backgroundController);
}

  void _playBackgroundMusic() async {
    await _audioPlayer.setSource(AssetSource('sounds/bg_music.mp3')); // Load the background music
    await _audioPlayer.setReleaseMode(ReleaseMode.loop); // Loop the background music
    _audioPlayer.setVolume(0.25);
    _audioPlayer.play(AssetSource('sounds/bg_music.mp3')); // Play the music
  }


  List<CardModel> _generateShuffledCards() {
    List<String> imageNames;
    
    if (widget.difficulty == "easy") {
    imageNames = [
      'Asteroid',
      'Astronaut',
      'Aurora',
      'Black_Hole',
      'Comet',
      'Constellation',
      'Earth',
      'Eclipse',
      'Jetpack',
      'Jupiter',
      'Mars',
      'Mercury',
    ];
  } else if (widget.difficulty == "medium") {
    imageNames = [
      'Asteroid',
      'Astronaut',
      'Aurora',
      'Black_Hole',
      'Comet',
      'Constellation',
      'Earth',
      'Eclipse',
      'Jetpack',
      'Jupiter',
      'Mars',
      'Mercury',
      'Meteor_Shower',
      'Meteor',
      'Milky_Way',
      'Moon',
      'Neptune',
      'Pluto',
      'Rocket',
      'Satellite',
    ];
  } else {
    imageNames = [
      'Asteroid',
      'Astronaut',
      'Aurora',
      'Black_Hole',
      'Comet',
      'Constellation',
      'Earth',
      'Eclipse',
      'Jetpack',
      'Jupiter',
      'Mars',
      'Mercury',
      'Meteor_Shower',
      'Meteor',
      'Milky_Way',
      'Moon',
      'Neptune',
      'Pluto',
      'Rocket',
      'Satellite',
      'Saturn',
      'Stars',
      'Sun',
      'Super_Giant',
      'Supernova',
      'Telescope',
      'UFO',
      'Uranus',
      'Venus',
      'Wormhole',
    ];
  }

    List<String> cardPaths = imageNames.map((name) => 'assets/images/$name.png').toList();

    List<CardModel> cardList = cardPaths
        .expand((path) => [
              CardModel(imagePath: path),
              CardModel(imagePath: path),
            ])
        .toList();

    cardList.shuffle(Random());
    return cardList;
  }

  Widget _buildSlidingBackground() {
  return AnimatedBuilder(
    animation: _backgroundAnimation,
    builder: (context, child) {
      // Use MediaQuery to get screen width
      final screenWidth = MediaQuery.of(context).size.width;
      final offset = -_backgroundAnimation.value * screenWidth;

      return Stack(
        children: [
          Positioned(
            left: offset,
            top: 0,
            bottom: 0,
            child: Image.asset(
              'assets/images/Main_BG.png',
              width: screenWidth,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            left: offset + screenWidth,
            top: 0,
            bottom: 0,
            child: Image.asset(
              'assets/images/Main_BG.png',
              width: screenWidth,
              fit: BoxFit.cover,
            ),
          ),
        ],
      );
    },
  );
}

Widget _buildGameContent() {
  return LayoutBuilder(
    builder: (context, constraints) {
      // Set columns and rows dynamically based on the difficulty
      int columns = widget.difficulty == "easy" ? 6 : widget.difficulty == "medium" ? 10 : 15;
      int rows = 4;  // Keep rows fixed to 4, as in easy mode
      double spacing = 8;
      double infoHeight = 200;

      double availableWidth = constraints.maxWidth - (spacing * (columns - 1));
      double availableHeight = constraints.maxHeight - infoHeight - (spacing * (rows - 1));

      // Keep the height of each card fixed based on rows
      double cardHeight = availableHeight / rows;
      double maxCardWidth = availableWidth / columns;

      double cardAspectRatio = 5 / 7;
      double cardWidth = maxCardWidth; // Horizontal size of cards

      // If the card width is too wide, adjust it to maintain aspect ratio
      double cardHeightAdjusted = cardWidth / cardAspectRatio;

      // If the card height exceeds the available height, adjust the width accordingly
      if (cardHeightAdjusted > cardHeight) {
        cardHeightAdjusted = cardHeight;
        cardWidth = cardHeightAdjusted * cardAspectRatio;
      }

      return Column(
        children: [
          SizedBox(height: 20),
          Text("Time: ${remainingTime}s", style: TextStyle(
            fontFamily: 'Stepalange',
            fontSize: 28,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          )),
          Text("Score: $score", style: TextStyle(
            fontFamily: 'Stepalange',
            fontSize: 28,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          )),
          SizedBox(height: 20),
          Expanded(
            child: Center(
              child: SizedBox(
                width: (cardWidth * columns) + (spacing * (columns - 1)),
                height: (cardHeight * rows) + (spacing * (rows - 1)),
                child: GridView.builder(
                  physics: NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,  // Dynamically set based on difficulty
                    crossAxisSpacing: spacing,
                    mainAxisSpacing: spacing,
                    childAspectRatio: cardAspectRatio,
                  ),
                  itemCount: cards.length,
                  itemBuilder: (context, index) {
                    return _buildCard(index);
                  },
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}


  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        remainingTime--;
      });

      if (remainingTime == 0) {
        _timer.cancel();
        _showGameOver();
      }
    });
  }

  void _onCardTap(int index) async {
  if (wait || cards[index].isFlipped || cards[index].isMatched) return;

  // Use a separate instance for each flip sound
  final flipPlayer = AudioPlayer();
  await flipPlayer.play(AssetSource('sounds/card_flip.mp3'));
  flipPlayer.onPlayerComplete.listen((event) {
    flipPlayer.dispose();
  });

  setState(() {
    cards[index].isFlipped = true;
  });

  final flippedCards = cards.where((card) => card.isFlipped && !card.isMatched).toList();

  if (flippedCards.length == 2) {
  wait = true;

  Future.delayed(Duration(seconds: 1), () async {
    setState(() {
      if (flippedCards[0].imagePath == flippedCards[1].imagePath) {
        flippedCards[0].isMatched = true;
        flippedCards[1].isMatched = true;
        score += 10 * combo;
        combo++;
      } else {
        flippedCards[0].isFlipped = false;
        flippedCards[1].isFlipped = false;
        combo = 1;
      }
      wait = false;
      _checkForWin();
    });

    if (flippedCards[0].imagePath == flippedCards[1].imagePath) {
      final matchPlayer = AudioPlayer();
      await matchPlayer.play(AssetSource('sounds/match.mp3'));
      matchPlayer.onPlayerComplete.listen((event) {
        matchPlayer.dispose();
      });
    } else {
      final errorPlayer = AudioPlayer();
      await errorPlayer.play(AssetSource('sounds/mismatch.mp3'));
      errorPlayer.onPlayerComplete.listen((event) {
        errorPlayer.dispose();
      });
    }
  });
}
}
void _checkForWin() {
  bool allMatched = cards.every((card) => card.isMatched);
  
  if (allMatched) {
    _showWinDialog();
  }
}

final TextEditingController _nameController = TextEditingController();

void _showWinDialog() {
  int totalScore = score * remainingTime;
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('You Win!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Final Score: $totalScore'),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Enter your name'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              if (_nameController.text.isNotEmpty) {
                await DatabaseHelper.instance.insertScore(
                  _nameController.text,
                  totalScore,
                  widget.difficulty,
                );
              }
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text('Save and Exit'),
          ),
        ],
      );
    },
  );
}


  void _showGameOver() {
    int finalScore = score * remainingTime;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Game Over'),
          content: Text('Your Final Score: $finalScore'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: Text('Back to Home'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCard(int index) {
  final card = cards[index];
  final showFront = card.isFlipped || card.isMatched;

  return GestureDetector(
    onTap: () => _onCardTap(index),
    child: TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: showFront ? 1.0 : 0.0),
      duration: Duration(milliseconds: 300),
      builder: (context, value, child) {
        final isUnder = value > 0.5;
        final angle = value * pi;

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle),
          child: isUnder
          ? KeyedSubtree(key: ValueKey('front-$index'), child: _buildCardFace(card.imagePath))
          : KeyedSubtree(key: ValueKey('back-$index'), child: _buildCardFace('assets/images/Back_Card_Design.png')),

        );
      },
    ),
  );
}

Widget _buildCardFace(String imagePath) {
  return Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      image: DecorationImage(
        image: AssetImage(imagePath),
        fit: BoxFit.cover,
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
    appBar: AppBar(
    title: Text(
          "Matching Stars",
          style: TextStyle(
            fontFamily: 'Stepalange',
            fontSize: 24,
            color: const Color.fromARGB(255, 255, 255, 255), 
          ),
        ),
    backgroundColor: Colors.blueGrey,
  ),
  body: Stack(
    children: [
      _buildSlidingBackground(), // <- your background
      _buildGameContent(),       // <- your original game UI
    ],
  ),
);
}

  @override
  void dispose() {
    _timer.cancel();
    _backgroundController.dispose();
    _audioPlayer.stop();
    super.dispose();
  }
}