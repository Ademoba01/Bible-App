// ---------------------------------------------------------------------------
// Study Quiz — question bank for Bible study quizzes.
// ---------------------------------------------------------------------------

/// A single study question with cross-references.
class StudyQuestion {
  final String question;
  final String answer;
  final String book;
  final int chapter;
  final List<String> relatedVerses;

  const StudyQuestion({
    required this.question,
    required this.answer,
    required this.book,
    required this.chapter,
    this.relatedVerses = const [],
  });
}

/// Returns questions relevant to a specific book and chapter.
List<StudyQuestion> getQuestionsForReading(String book, int chapter) {
  return kStudyQuestions
      .where((q) =>
          q.book.toLowerCase() == book.toLowerCase() && q.chapter == chapter)
      .toList();
}

/// Returns all questions for a given book.
List<StudyQuestion> getQuestionsForBook(String book) {
  return kStudyQuestions
      .where((q) => q.book.toLowerCase() == book.toLowerCase())
      .toList();
}

// ---------------------------------------------------------------------------
// Comprehensive question bank — 100+ questions across 14 books.
// ---------------------------------------------------------------------------

const kStudyQuestions = <StudyQuestion>[
  // ==========================================================================
  // GENESIS (10 questions)
  // ==========================================================================
  StudyQuestion(
    question: 'In Genesis 1, what did God create on the first day?',
    answer: 'Light -- "Let there be light" (Genesis 1:3)',
    book: 'Genesis',
    chapter: 1,
    relatedVerses: ['John 1:5', '2 Corinthians 4:6', 'Isaiah 45:7'],
  ),
  StudyQuestion(
    question: 'What did God create on the second day of creation?',
    answer: 'The expanse (sky/firmament) to separate the waters above from the waters below (Genesis 1:6-8)',
    book: 'Genesis',
    chapter: 1,
    relatedVerses: ['Psalm 19:1', 'Job 37:18'],
  ),
  StudyQuestion(
    question: 'How did God create mankind according to Genesis 1:27?',
    answer: 'In His own image, male and female He created them.',
    book: 'Genesis',
    chapter: 1,
    relatedVerses: ['Psalm 139:14', 'Colossians 3:10', 'James 3:9'],
  ),
  StudyQuestion(
    question: 'What was the tree in the Garden of Eden that Adam and Eve were forbidden to eat from?',
    answer: 'The tree of the knowledge of good and evil (Genesis 2:17)',
    book: 'Genesis',
    chapter: 2,
    relatedVerses: ['Proverbs 3:18', 'Revelation 22:2'],
  ),
  StudyQuestion(
    question: 'What was the first question God asked in the Bible?',
    answer: '"Where are you?" -- spoken to Adam after the Fall (Genesis 3:9)',
    book: 'Genesis',
    chapter: 3,
    relatedVerses: ['Luke 19:10', 'Isaiah 59:2'],
  ),
  StudyQuestion(
    question: 'What sign did God give Noah as a covenant promise never to flood the earth again?',
    answer: 'A rainbow in the clouds (Genesis 9:13)',
    book: 'Genesis',
    chapter: 9,
    relatedVerses: ['Isaiah 54:9', 'Ezekiel 1:28', 'Revelation 4:3'],
  ),
  StudyQuestion(
    question: 'What was Abram\'s original homeland before God called him?',
    answer: 'Ur of the Chaldeans, then Haran (Genesis 12:1)',
    book: 'Genesis',
    chapter: 12,
    relatedVerses: ['Hebrews 11:8', 'Acts 7:2-3'],
  ),
  StudyQuestion(
    question: 'Why did God test Abraham by asking him to sacrifice Isaac?',
    answer: 'To test his faith and obedience; God provided a ram as a substitute (Genesis 22:1-14)',
    book: 'Genesis',
    chapter: 22,
    relatedVerses: ['Hebrews 11:17-19', 'James 2:21-23', 'Romans 8:32'],
  ),
  StudyQuestion(
    question: 'How many sons did Jacob (Israel) have, forming the twelve tribes?',
    answer: 'Twelve sons: Reuben, Simeon, Levi, Judah, Dan, Naphtali, Gad, Asher, Issachar, Zebulun, Joseph, and Benjamin.',
    book: 'Genesis',
    chapter: 35,
    relatedVerses: ['Revelation 7:4-8', 'Exodus 1:1-5'],
  ),
  StudyQuestion(
    question: 'What did Joseph tell his brothers about their evil intentions in Genesis 50?',
    answer: '"You intended to harm me, but God intended it for good" (Genesis 50:20)',
    book: 'Genesis',
    chapter: 50,
    relatedVerses: ['Romans 8:28', 'Isaiah 55:8-9', 'Jeremiah 29:11'],
  ),

  // ==========================================================================
  // EXODUS (8 questions)
  // ==========================================================================
  StudyQuestion(
    question: 'How did God appear to Moses at the burning bush?',
    answer: 'As a flame of fire in a bush that burned but was not consumed (Exodus 3:2)',
    book: 'Exodus',
    chapter: 3,
    relatedVerses: ['Acts 7:30-34', 'Deuteronomy 33:16'],
  ),
  StudyQuestion(
    question: 'What name did God reveal to Moses at the burning bush?',
    answer: '"I AM WHO I AM" (Exodus 3:14)',
    book: 'Exodus',
    chapter: 3,
    relatedVerses: ['John 8:58', 'Revelation 1:8'],
  ),
  StudyQuestion(
    question: 'How many plagues did God send upon Egypt?',
    answer: 'Ten plagues, culminating in the death of the firstborn (Exodus 7-12)',
    book: 'Exodus',
    chapter: 7,
    relatedVerses: ['Psalm 78:43-51', 'Revelation 16:1-21'],
  ),
  StudyQuestion(
    question: 'What event does the Passover commemorate?',
    answer: 'When the Lord passed over Israelite houses marked with lamb\'s blood, sparing their firstborn (Exodus 12:13)',
    book: 'Exodus',
    chapter: 12,
    relatedVerses: ['1 Corinthians 5:7', 'John 1:29', '1 Peter 1:19'],
  ),
  StudyQuestion(
    question: 'How did God part the Red Sea for the Israelites?',
    answer: 'God drove the sea back with a strong east wind all night, making dry ground (Exodus 14:21)',
    book: 'Exodus',
    chapter: 14,
    relatedVerses: ['Isaiah 43:16', 'Psalm 77:19-20', 'Hebrews 11:29'],
  ),
  StudyQuestion(
    question: 'What is the first of the Ten Commandments?',
    answer: '"You shall have no other gods before me" (Exodus 20:3)',
    book: 'Exodus',
    chapter: 20,
    relatedVerses: ['Deuteronomy 6:4-5', 'Matthew 22:37-38', 'Mark 12:29-30'],
  ),
  StudyQuestion(
    question: 'What golden idol did the Israelites make while Moses was on Mount Sinai?',
    answer: 'A golden calf, fashioned from their gold earrings (Exodus 32:4)',
    book: 'Exodus',
    chapter: 32,
    relatedVerses: ['Acts 7:41', '1 Corinthians 10:7', 'Psalm 106:19-20'],
  ),
  StudyQuestion(
    question: 'What filled the tabernacle when it was completed?',
    answer: 'The glory of the Lord filled the tabernacle as a cloud (Exodus 40:34-35)',
    book: 'Exodus',
    chapter: 40,
    relatedVerses: ['1 Kings 8:10-11', '2 Chronicles 5:13-14', 'Revelation 15:8'],
  ),

  // ==========================================================================
  // PSALMS (8 questions)
  // ==========================================================================
  StudyQuestion(
    question: 'According to Psalm 1, what is the blessed person compared to?',
    answer: 'A tree planted by streams of water that yields fruit in season (Psalm 1:3)',
    book: 'Psalms',
    chapter: 1,
    relatedVerses: ['Jeremiah 17:7-8', 'John 15:5'],
  ),
  StudyQuestion(
    question: 'In Psalm 23, what does David say the Lord is to him?',
    answer: '"The Lord is my shepherd; I shall not want" (Psalm 23:1)',
    book: 'Psalms',
    chapter: 23,
    relatedVerses: ['John 10:11', 'Isaiah 40:11', '1 Peter 2:25'],
  ),
  StudyQuestion(
    question: 'What does Psalm 23:4 say about walking through the valley of the shadow of death?',
    answer: '"I will fear no evil, for you are with me; your rod and your staff, they comfort me."',
    book: 'Psalms',
    chapter: 23,
    relatedVerses: ['Isaiah 43:2', 'Romans 8:38-39'],
  ),
  StudyQuestion(
    question: 'What does Psalm 46:10 instruct us to do?',
    answer: '"Be still, and know that I am God."',
    book: 'Psalms',
    chapter: 46,
    relatedVerses: ['Isaiah 30:15', 'Exodus 14:14'],
  ),
  StudyQuestion(
    question: 'According to Psalm 51, what does David ask God to create in him?',
    answer: 'A clean heart and a renewed, steadfast spirit (Psalm 51:10)',
    book: 'Psalms',
    chapter: 51,
    relatedVerses: ['Ezekiel 36:26', '2 Corinthians 5:17'],
  ),
  StudyQuestion(
    question: 'What does Psalm 119:105 compare God\'s word to?',
    answer: '"A lamp to my feet and a light to my path."',
    book: 'Psalms',
    chapter: 119,
    relatedVerses: ['Proverbs 6:23', '2 Peter 1:19', 'John 8:12'],
  ),
  StudyQuestion(
    question: 'In Psalm 139, what does David say about God\'s knowledge of him?',
    answer: 'God knows when he sits and rises, perceives his thoughts from afar, and is familiar with all his ways (Psalm 139:1-4)',
    book: 'Psalms',
    chapter: 139,
    relatedVerses: ['Jeremiah 1:5', 'Matthew 10:30', 'Hebrews 4:13'],
  ),
  StudyQuestion(
    question: 'What is the final verse of the book of Psalms?',
    answer: '"Let everything that has breath praise the Lord. Praise the Lord!" (Psalm 150:6)',
    book: 'Psalms',
    chapter: 150,
    relatedVerses: ['Revelation 5:13', 'Romans 11:36'],
  ),

  // ==========================================================================
  // PROVERBS (5 questions)
  // ==========================================================================
  StudyQuestion(
    question: 'According to Proverbs 1:7, what is the beginning of knowledge?',
    answer: 'The fear of the Lord is the beginning of knowledge.',
    book: 'Proverbs',
    chapter: 1,
    relatedVerses: ['Proverbs 9:10', 'Psalm 111:10', 'Job 28:28'],
  ),
  StudyQuestion(
    question: 'What does Proverbs 3:5-6 instruct about trusting God?',
    answer: '"Trust in the Lord with all your heart and lean not on your own understanding; in all your ways acknowledge Him, and He will make your paths straight."',
    book: 'Proverbs',
    chapter: 3,
    relatedVerses: ['Psalm 37:5', 'Isaiah 26:3-4', 'Jeremiah 17:7'],
  ),
  StudyQuestion(
    question: 'According to Proverbs 16:9, who directs a person\'s steps?',
    answer: '"The heart of man plans his way, but the Lord establishes his steps."',
    book: 'Proverbs',
    chapter: 16,
    relatedVerses: ['Jeremiah 10:23', 'Psalm 37:23', 'James 4:13-15'],
  ),
  StudyQuestion(
    question: 'What does Proverbs 22:6 teach about raising children?',
    answer: '"Train up a child in the way he should go; even when he is old he will not depart from it."',
    book: 'Proverbs',
    chapter: 22,
    relatedVerses: ['Deuteronomy 6:6-7', 'Ephesians 6:4', '2 Timothy 3:15'],
  ),
  StudyQuestion(
    question: 'What does Proverbs 27:17 say about friendship?',
    answer: '"As iron sharpens iron, so one person sharpens another."',
    book: 'Proverbs',
    chapter: 27,
    relatedVerses: ['Ecclesiastes 4:9-10', 'Hebrews 10:24-25'],
  ),

  // ==========================================================================
  // ISAIAH (5 questions)
  // ==========================================================================
  StudyQuestion(
    question: 'In Isaiah 6, what did the seraphim cry out about God?',
    answer: '"Holy, holy, holy is the Lord Almighty; the whole earth is full of his glory." (Isaiah 6:3)',
    book: 'Isaiah',
    chapter: 6,
    relatedVerses: ['Revelation 4:8', 'Psalm 99:3'],
  ),
  StudyQuestion(
    question: 'What sign did Isaiah prophesy about the Messiah\'s birth?',
    answer: '"The virgin will conceive and give birth to a son, and will call him Immanuel." (Isaiah 7:14)',
    book: 'Isaiah',
    chapter: 7,
    relatedVerses: ['Matthew 1:22-23', 'Luke 1:31-35'],
  ),
  StudyQuestion(
    question: 'What does Isaiah 40:31 promise to those who hope in the Lord?',
    answer: 'They will renew their strength, soar on wings like eagles, run and not grow weary, walk and not be faint.',
    book: 'Isaiah',
    chapter: 40,
    relatedVerses: ['Psalm 103:5', '2 Corinthians 4:16', 'Galatians 6:9'],
  ),
  StudyQuestion(
    question: 'According to Isaiah 53, what did the suffering servant bear?',
    answer: 'He bore our griefs, carried our sorrows, was pierced for our transgressions, and by his wounds we are healed.',
    book: 'Isaiah',
    chapter: 53,
    relatedVerses: ['1 Peter 2:24', 'Matthew 8:17', 'Acts 8:32-35'],
  ),
  StudyQuestion(
    question: 'What promise does Isaiah 55:11 make about God\'s word?',
    answer: 'It will not return empty but will accomplish what God desires and achieve its purpose.',
    book: 'Isaiah',
    chapter: 55,
    relatedVerses: ['Hebrews 4:12', 'Jeremiah 23:29', '2 Timothy 3:16'],
  ),

  // ==========================================================================
  // MATTHEW (10 questions)
  // ==========================================================================
  StudyQuestion(
    question: 'In the Sermon on the Mount, what are the first words of the Beatitudes?',
    answer: '"Blessed are the poor in spirit, for theirs is the kingdom of heaven." (Matthew 5:3)',
    book: 'Matthew',
    chapter: 5,
    relatedVerses: ['Luke 6:20', 'Isaiah 57:15', 'James 4:6'],
  ),
  StudyQuestion(
    question: 'What does Jesus say about being salt and light in Matthew 5?',
    answer: 'Believers are the salt of the earth and the light of the world; they should let their light shine before others (Matthew 5:13-16)',
    book: 'Matthew',
    chapter: 5,
    relatedVerses: ['Mark 9:50', 'Philippians 2:15', 'John 8:12'],
  ),
  StudyQuestion(
    question: 'How does Jesus teach us to pray in Matthew 6?',
    answer: 'Through the Lord\'s Prayer: "Our Father in heaven, hallowed be your name..." (Matthew 6:9-13)',
    book: 'Matthew',
    chapter: 6,
    relatedVerses: ['Luke 11:1-4', 'John 17:1', 'Philippians 4:6'],
  ),
  StudyQuestion(
    question: 'What does Matthew 6:33 instruct believers to seek first?',
    answer: '"Seek first the kingdom of God and his righteousness, and all these things will be added to you."',
    book: 'Matthew',
    chapter: 6,
    relatedVerses: ['Luke 12:31', 'Psalm 37:4', 'Proverbs 3:9-10'],
  ),
  StudyQuestion(
    question: 'In the parable of the sower (Matthew 13), what does the good soil represent?',
    answer: 'Those who hear the word, understand it, and produce a fruitful crop (Matthew 13:23)',
    book: 'Matthew',
    chapter: 13,
    relatedVerses: ['Mark 4:20', 'Luke 8:15', 'Colossians 1:10'],
  ),
  StudyQuestion(
    question: 'What did Peter confess about Jesus at Caesarea Philippi?',
    answer: '"You are the Christ, the Son of the living God." (Matthew 16:16)',
    book: 'Matthew',
    chapter: 16,
    relatedVerses: ['Mark 8:29', 'John 6:69', 'John 11:27'],
  ),
  StudyQuestion(
    question: 'What is the greatest commandment according to Jesus in Matthew 22?',
    answer: '"Love the Lord your God with all your heart, soul, and mind." The second is to love your neighbor as yourself.',
    book: 'Matthew',
    chapter: 22,
    relatedVerses: ['Mark 12:29-31', 'Deuteronomy 6:5', 'Leviticus 19:18'],
  ),
  StudyQuestion(
    question: 'In the parable of the talents (Matthew 25), what did the master say to the faithful servants?',
    answer: '"Well done, good and faithful servant! You have been faithful with a few things; I will put you in charge of many things." (Matthew 25:21)',
    book: 'Matthew',
    chapter: 25,
    relatedVerses: ['Luke 19:17', 'Luke 16:10', '1 Corinthians 4:2'],
  ),
  StudyQuestion(
    question: 'What were Jesus\' final words to His disciples in Matthew 28?',
    answer: 'The Great Commission: "Go and make disciples of all nations, baptizing them... teaching them to obey everything I have commanded you." (Matthew 28:19-20)',
    book: 'Matthew',
    chapter: 28,
    relatedVerses: ['Mark 16:15', 'Acts 1:8', 'Luke 24:47'],
  ),
  StudyQuestion(
    question: 'What promise closes the Gospel of Matthew?',
    answer: '"And surely I am with you always, to the very end of the age." (Matthew 28:20)',
    book: 'Matthew',
    chapter: 28,
    relatedVerses: ['Hebrews 13:5', 'Joshua 1:9', 'Isaiah 41:10'],
  ),

  // ==========================================================================
  // MARK (5 questions)
  // ==========================================================================
  StudyQuestion(
    question: 'How does the Gospel of Mark begin?',
    answer: '"The beginning of the good news about Jesus the Messiah, the Son of God." (Mark 1:1)',
    book: 'Mark',
    chapter: 1,
    relatedVerses: ['Romans 1:1-4', 'Isaiah 40:3'],
  ),
  StudyQuestion(
    question: 'What happened when Jesus was baptized by John in Mark 1?',
    answer: 'The heavens were torn open, the Spirit descended like a dove, and a voice from heaven said, "You are my Son, whom I love." (Mark 1:10-11)',
    book: 'Mark',
    chapter: 1,
    relatedVerses: ['Matthew 3:16-17', 'Luke 3:21-22', 'John 1:32-34'],
  ),
  StudyQuestion(
    question: 'In Mark 4, what did Jesus calm with His words?',
    answer: 'A furious storm on the Sea of Galilee, saying "Quiet! Be still!" (Mark 4:39)',
    book: 'Mark',
    chapter: 4,
    relatedVerses: ['Psalm 107:29', 'Matthew 8:26', 'Luke 8:24'],
  ),
  StudyQuestion(
    question: 'What did Jesus teach about servanthood in Mark 10?',
    answer: '"Whoever wants to become great among you must be your servant, and whoever wants to be first must be slave of all." (Mark 10:43-44)',
    book: 'Mark',
    chapter: 10,
    relatedVerses: ['Matthew 20:26-28', 'John 13:14-15', 'Philippians 2:5-8'],
  ),
  StudyQuestion(
    question: 'What happened to the temple curtain when Jesus died according to Mark 15?',
    answer: 'The curtain of the temple was torn in two from top to bottom (Mark 15:38)',
    book: 'Mark',
    chapter: 15,
    relatedVerses: ['Matthew 27:51', 'Hebrews 10:19-20', 'Hebrews 6:19'],
  ),

  // ==========================================================================
  // LUKE (8 questions)
  // ==========================================================================
  StudyQuestion(
    question: 'What did the angel Gabriel announce to Mary in Luke 1?',
    answer: 'That she would conceive and give birth to a son named Jesus, who would be the Son of the Most High (Luke 1:31-33)',
    book: 'Luke',
    chapter: 1,
    relatedVerses: ['Isaiah 7:14', 'Matthew 1:20-23', 'Galatians 4:4'],
  ),
  StudyQuestion(
    question: 'Where was Jesus born according to Luke 2?',
    answer: 'In Bethlehem, and laid in a manger because there was no room in the inn (Luke 2:4-7)',
    book: 'Luke',
    chapter: 2,
    relatedVerses: ['Micah 5:2', 'Matthew 2:1', 'John 7:42'],
  ),
  StudyQuestion(
    question: 'In the parable of the Good Samaritan (Luke 10), who proved to be a neighbor?',
    answer: 'The Samaritan who showed mercy to the beaten traveler, unlike the priest and Levite who passed by.',
    book: 'Luke',
    chapter: 10,
    relatedVerses: ['Matthew 22:39', 'James 2:8', 'Galatians 5:14'],
  ),
  StudyQuestion(
    question: 'In the parable of the prodigal son (Luke 15), what did the father do when his lost son returned?',
    answer: 'He ran to him, embraced him, kissed him, and threw a great celebration (Luke 15:20-24)',
    book: 'Luke',
    chapter: 15,
    relatedVerses: ['Ephesians 2:4-5', 'Romans 5:8', 'Isaiah 55:7'],
  ),
  StudyQuestion(
    question: 'What did Jesus say to the thief on the cross in Luke 23?',
    answer: '"Truly I tell you, today you will be with me in paradise." (Luke 23:43)',
    book: 'Luke',
    chapter: 23,
    relatedVerses: ['2 Corinthians 5:8', 'Philippians 1:23', 'Revelation 2:7'],
  ),
  StudyQuestion(
    question: 'What did the two disciples on the road to Emmaus realize about Jesus?',
    answer: 'They recognized Him in the breaking of bread, and their hearts had been burning within them as He explained the Scriptures (Luke 24:31-32)',
    book: 'Luke',
    chapter: 24,
    relatedVerses: ['Acts 2:42', 'John 21:12'],
  ),
  StudyQuestion(
    question: 'In Luke 4, what Scripture did Jesus read in the synagogue at Nazareth?',
    answer: 'Isaiah 61:1-2 about the Spirit of the Lord anointing Him to proclaim good news to the poor (Luke 4:18-19)',
    book: 'Luke',
    chapter: 4,
    relatedVerses: ['Isaiah 61:1-2', 'Matthew 11:5'],
  ),
  StudyQuestion(
    question: 'What did Jesus teach about prayer in the parable of the persistent widow (Luke 18)?',
    answer: 'That we should always pray and not give up, for God will bring justice for His chosen ones (Luke 18:1-8)',
    book: 'Luke',
    chapter: 18,
    relatedVerses: ['1 Thessalonians 5:17', 'Colossians 4:2', 'Matthew 7:7-8'],
  ),

  // ==========================================================================
  // JOHN (10 questions)
  // ==========================================================================
  StudyQuestion(
    question: 'How does the Gospel of John describe Jesus in its opening verse?',
    answer: '"In the beginning was the Word, and the Word was with God, and the Word was God." (John 1:1)',
    book: 'John',
    chapter: 1,
    relatedVerses: ['Genesis 1:1', 'Colossians 1:15-17', 'Hebrews 1:1-3'],
  ),
  StudyQuestion(
    question: 'What was Jesus\' first miracle recorded in John?',
    answer: 'Turning water into wine at the wedding in Cana (John 2:1-11)',
    book: 'John',
    chapter: 2,
    relatedVerses: ['John 20:30-31', 'Matthew 26:29'],
  ),
  StudyQuestion(
    question: 'What did Jesus tell Nicodemus about entering the kingdom of God?',
    answer: '"No one can see the kingdom of God unless they are born again." (John 3:3)',
    book: 'John',
    chapter: 3,
    relatedVerses: ['1 Peter 1:23', 'Titus 3:5', '2 Corinthians 5:17'],
  ),
  StudyQuestion(
    question: 'What does John 3:16 teach about God\'s love?',
    answer: '"For God so loved the world that he gave his one and only Son, that whoever believes in him shall not perish but have eternal life."',
    book: 'John',
    chapter: 3,
    relatedVerses: ['Romans 5:8', '1 John 4:9-10', 'Romans 6:23'],
  ),
  StudyQuestion(
    question: 'What did Jesus declare in John 6:35?',
    answer: '"I am the bread of life. Whoever comes to me will never go hungry, and whoever believes in me will never be thirsty."',
    book: 'John',
    chapter: 6,
    relatedVerses: ['John 4:14', 'Isaiah 55:1', 'Matthew 5:6'],
  ),
  StudyQuestion(
    question: 'What did Jesus say about Himself in John 8:12?',
    answer: '"I am the light of the world. Whoever follows me will never walk in darkness, but will have the light of life."',
    book: 'John',
    chapter: 8,
    relatedVerses: ['John 1:4-5', 'Isaiah 9:2', 'Matthew 5:14'],
  ),
  StudyQuestion(
    question: 'What did Jesus say about abundant life in John 10?',
    answer: '"I have come that they may have life, and have it to the full." (John 10:10)',
    book: 'John',
    chapter: 10,
    relatedVerses: ['Romans 6:23', 'Colossians 2:10', '1 John 5:12'],
  ),
  StudyQuestion(
    question: 'What did Jesus do for Lazarus in John 11?',
    answer: 'He raised Lazarus from the dead after he had been in the tomb four days (John 11:43-44)',
    book: 'John',
    chapter: 11,
    relatedVerses: ['John 5:25', '1 Corinthians 15:55', 'Romans 6:9'],
  ),
  StudyQuestion(
    question: 'What is the "new commandment" Jesus gave in John 13?',
    answer: '"Love one another. As I have loved you, so you must love one another." (John 13:34)',
    book: 'John',
    chapter: 13,
    relatedVerses: ['1 John 3:16', '1 John 4:7-8', 'Romans 13:8'],
  ),
  StudyQuestion(
    question: 'What did Jesus say about being the way to the Father?',
    answer: '"I am the way and the truth and the life. No one comes to the Father except through me." (John 14:6)',
    book: 'John',
    chapter: 14,
    relatedVerses: ['Acts 4:12', '1 Timothy 2:5', 'Hebrews 10:19-20'],
  ),

  // ==========================================================================
  // ACTS (8 questions)
  // ==========================================================================
  StudyQuestion(
    question: 'What did Jesus promise the disciples before His ascension in Acts 1?',
    answer: '"You will receive power when the Holy Spirit comes on you; and you will be my witnesses." (Acts 1:8)',
    book: 'Acts',
    chapter: 1,
    relatedVerses: ['Luke 24:49', 'John 14:26', 'John 15:26-27'],
  ),
  StudyQuestion(
    question: 'What happened on the day of Pentecost in Acts 2?',
    answer: 'The Holy Spirit came upon the believers with tongues of fire, and they spoke in other languages (Acts 2:1-4)',
    book: 'Acts',
    chapter: 2,
    relatedVerses: ['Joel 2:28-29', 'John 14:16-17', 'Acts 1:5'],
  ),
  StudyQuestion(
    question: 'How many people were added to the church after Peter\'s sermon at Pentecost?',
    answer: 'About three thousand (Acts 2:41)',
    book: 'Acts',
    chapter: 2,
    relatedVerses: ['Acts 4:4', 'Acts 6:7'],
  ),
  StudyQuestion(
    question: 'What did Peter and John say to the lame beggar at the temple gate?',
    answer: '"Silver or gold I do not have, but what I do have I give you. In the name of Jesus Christ of Nazareth, walk." (Acts 3:6)',
    book: 'Acts',
    chapter: 3,
    relatedVerses: ['Mark 16:17-18', 'John 14:12'],
  ),
  StudyQuestion(
    question: 'What was Saul (Paul) doing when Jesus appeared to him on the road to Damascus?',
    answer: 'He was traveling to arrest Christians; a bright light blinded him and Jesus spoke to him (Acts 9:1-6)',
    book: 'Acts',
    chapter: 9,
    relatedVerses: ['1 Timothy 1:15-16', 'Galatians 1:13-16', '1 Corinthians 15:9-10'],
  ),
  StudyQuestion(
    question: 'What vision did Peter have in Acts 10 that changed his understanding?',
    answer: 'A sheet lowered from heaven with unclean animals, and God told him not to call impure what God has made clean (Acts 10:11-15)',
    book: 'Acts',
    chapter: 10,
    relatedVerses: ['Mark 7:19', 'Galatians 2:11-14', 'Ephesians 2:14'],
  ),
  StudyQuestion(
    question: 'What did the Philippian jailer ask Paul and Silas in Acts 16?',
    answer: '"Sirs, what must I do to be saved?" They replied, "Believe in the Lord Jesus, and you will be saved." (Acts 16:30-31)',
    book: 'Acts',
    chapter: 16,
    relatedVerses: ['Romans 10:9', 'Ephesians 2:8-9', 'John 3:16'],
  ),
  StudyQuestion(
    question: 'What was Paul\'s message to the Athenians at the Areopagus?',
    answer: 'He proclaimed the "unknown god" they worshiped was the one true God who made heaven and earth and raised Jesus from the dead (Acts 17:22-31)',
    book: 'Acts',
    chapter: 17,
    relatedVerses: ['Romans 1:19-20', 'Isaiah 42:5', 'Jeremiah 10:10'],
  ),

  // ==========================================================================
  // ROMANS (8 questions)
  // ==========================================================================
  StudyQuestion(
    question: 'What does Romans 1:16 say about the gospel?',
    answer: '"I am not ashamed of the gospel, because it is the power of God that brings salvation to everyone who believes."',
    book: 'Romans',
    chapter: 1,
    relatedVerses: ['1 Corinthians 1:18', '2 Timothy 1:8', 'Mark 8:38'],
  ),
  StudyQuestion(
    question: 'According to Romans 3:23, what is the universal condition of humanity?',
    answer: '"For all have sinned and fall short of the glory of God."',
    book: 'Romans',
    chapter: 3,
    relatedVerses: ['Ecclesiastes 7:20', '1 John 1:8', 'Psalm 14:3'],
  ),
  StudyQuestion(
    question: 'What does Romans 5:8 say about God\'s love?',
    answer: '"God demonstrates his own love for us in this: While we were still sinners, Christ died for us."',
    book: 'Romans',
    chapter: 5,
    relatedVerses: ['John 3:16', '1 John 4:10', 'Ephesians 2:4-5'],
  ),
  StudyQuestion(
    question: 'What does Romans 6:23 teach about sin and grace?',
    answer: '"The wages of sin is death, but the gift of God is eternal life in Christ Jesus our Lord."',
    book: 'Romans',
    chapter: 6,
    relatedVerses: ['James 1:15', 'John 3:16', 'Ephesians 2:8-9'],
  ),
  StudyQuestion(
    question: 'According to Romans 8:1, what is true for those in Christ Jesus?',
    answer: '"There is now no condemnation for those who are in Christ Jesus."',
    book: 'Romans',
    chapter: 8,
    relatedVerses: ['John 3:18', 'John 5:24', 'Galatians 5:1'],
  ),
  StudyQuestion(
    question: 'What does Romans 8:28 promise believers?',
    answer: '"In all things God works for the good of those who love him, who have been called according to his purpose."',
    book: 'Romans',
    chapter: 8,
    relatedVerses: ['Genesis 50:20', 'Jeremiah 29:11', 'Philippians 1:6'],
  ),
  StudyQuestion(
    question: 'What can separate us from the love of Christ according to Romans 8:38-39?',
    answer: 'Nothing -- neither death, life, angels, rulers, present, future, powers, height, depth, nor anything else in creation.',
    book: 'Romans',
    chapter: 8,
    relatedVerses: ['John 10:28-29', 'Psalm 23:4', 'Isaiah 43:1-2'],
  ),
  StudyQuestion(
    question: 'What does Romans 12:2 instruct about conformity to the world?',
    answer: '"Do not conform to the pattern of this world, but be transformed by the renewing of your mind."',
    book: 'Romans',
    chapter: 12,
    relatedVerses: ['Ephesians 4:23', 'Colossians 3:2', '1 John 2:15-16'],
  ),

  // ==========================================================================
  // 1 CORINTHIANS (5 questions)
  // ==========================================================================
  StudyQuestion(
    question: 'What is the message of the cross according to 1 Corinthians 1:18?',
    answer: 'It is foolishness to those who are perishing, but to those being saved it is the power of God.',
    book: '1 Corinthians',
    chapter: 1,
    relatedVerses: ['Romans 1:16', '2 Corinthians 4:3-4'],
  ),
  StudyQuestion(
    question: 'What does 1 Corinthians 6:19-20 say about our bodies?',
    answer: 'Our bodies are temples of the Holy Spirit; we are not our own but were bought at a price, so we should honor God with our bodies.',
    book: '1 Corinthians',
    chapter: 6,
    relatedVerses: ['2 Corinthians 6:16', 'Romans 12:1', '1 Peter 1:18-19'],
  ),
  StudyQuestion(
    question: 'How does 1 Corinthians 10:13 comfort those facing temptation?',
    answer: 'God is faithful and will not let you be tempted beyond what you can bear; He will provide a way out.',
    book: '1 Corinthians',
    chapter: 10,
    relatedVerses: ['James 1:13-14', '2 Peter 2:9', 'Hebrews 2:18'],
  ),
  StudyQuestion(
    question: 'How does 1 Corinthians 13 describe love?',
    answer: 'Love is patient, kind, does not envy or boast; it always protects, trusts, hopes, and perseveres (1 Corinthians 13:4-7)',
    book: '1 Corinthians',
    chapter: 13,
    relatedVerses: ['Colossians 3:14', 'John 13:34-35', '1 John 4:8'],
  ),
  StudyQuestion(
    question: 'What does 1 Corinthians 15:55-57 declare about death?',
    answer: '"Where, O death, is your victory? Where, O death, is your sting?" God gives us victory through our Lord Jesus Christ.',
    book: '1 Corinthians',
    chapter: 15,
    relatedVerses: ['Hosea 13:14', 'Romans 6:9', 'Revelation 21:4'],
  ),

  // ==========================================================================
  // EPHESIANS (5 questions)
  // ==========================================================================
  StudyQuestion(
    question: 'According to Ephesians 2:8-9, how are we saved?',
    answer: '"By grace you have been saved, through faith -- and this is not from yourselves, it is the gift of God -- not by works."',
    book: 'Ephesians',
    chapter: 2,
    relatedVerses: ['Romans 3:24', 'Titus 3:5', 'Romans 6:23'],
  ),
  StudyQuestion(
    question: 'What does Ephesians 2:10 call believers?',
    answer: '"God\'s handiwork, created in Christ Jesus to do good works, which God prepared in advance for us to do."',
    book: 'Ephesians',
    chapter: 2,
    relatedVerses: ['2 Corinthians 5:17', 'Titus 2:14', 'James 2:17'],
  ),
  StudyQuestion(
    question: 'What prayer does Paul offer in Ephesians 3:16-19?',
    answer: 'That believers would be strengthened through the Spirit, rooted in love, and able to grasp the breadth and depth of Christ\'s love.',
    book: 'Ephesians',
    chapter: 3,
    relatedVerses: ['Colossians 2:6-7', 'Romans 8:37-39'],
  ),
  StudyQuestion(
    question: 'What pieces of the armor of God are listed in Ephesians 6?',
    answer: 'Belt of truth, breastplate of righteousness, shoes of the gospel of peace, shield of faith, helmet of salvation, and sword of the Spirit (Ephesians 6:14-17)',
    book: 'Ephesians',
    chapter: 6,
    relatedVerses: ['Romans 13:12', '1 Thessalonians 5:8', '2 Corinthians 10:4'],
  ),
  StudyQuestion(
    question: 'What does Ephesians 4:2-3 urge about Christian unity?',
    answer: 'Be completely humble, gentle, patient, bearing with one another in love, making every effort to keep the unity of the Spirit through the bond of peace.',
    book: 'Ephesians',
    chapter: 4,
    relatedVerses: ['Colossians 3:12-14', 'Philippians 2:2-3', 'John 17:21'],
  ),

  // ==========================================================================
  // REVELATION (5 questions)
  // ==========================================================================
  StudyQuestion(
    question: 'To whom was the book of Revelation given?',
    answer: 'To John, while he was exiled on the island of Patmos, through a revelation from Jesus Christ (Revelation 1:1, 1:9)',
    book: 'Revelation',
    chapter: 1,
    relatedVerses: ['Daniel 7:13-14', 'Revelation 22:16'],
  ),
  StudyQuestion(
    question: 'What does Jesus say about Himself in Revelation 1:8?',
    answer: '"I am the Alpha and the Omega," says the Lord God, "who is, and who was, and who is to come, the Almighty."',
    book: 'Revelation',
    chapter: 1,
    relatedVerses: ['Isaiah 44:6', 'Revelation 22:13', 'Exodus 3:14'],
  ),
  StudyQuestion(
    question: 'What does the throne room scene in Revelation 4 describe?',
    answer: 'God seated on a glorious throne surrounded by 24 elders and four living creatures constantly declaring "Holy, holy, holy" (Revelation 4:2-8)',
    book: 'Revelation',
    chapter: 4,
    relatedVerses: ['Isaiah 6:1-3', 'Ezekiel 1:5-14', 'Psalm 47:8'],
  ),
  StudyQuestion(
    question: 'What is promised in Revelation 21:4 about the new heaven and new earth?',
    answer: '"He will wipe every tear from their eyes. There will be no more death or mourning or crying or pain."',
    book: 'Revelation',
    chapter: 21,
    relatedVerses: ['Isaiah 25:8', 'Isaiah 65:17-19', '2 Corinthians 5:17'],
  ),
  StudyQuestion(
    question: 'What invitation closes the book of Revelation?',
    answer: '"The Spirit and the bride say, \'Come!\' Let the one who is thirsty come; and let the one who wishes take the free gift of the water of life." (Revelation 22:17)',
    book: 'Revelation',
    chapter: 22,
    relatedVerses: ['Isaiah 55:1', 'John 7:37-38', 'Revelation 21:6'],
  ),
];
