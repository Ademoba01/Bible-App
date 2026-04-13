import 'package:latlong2/latlong.dart';

/// Biblical time periods for filtering locations.
enum BiblicalEra {
  patriarchs('Patriarchs', '🏕️', 0xFF8D6E63),
  exodus('Exodus', '🌊', 0xFF1976D2),
  conquest('Conquest', '⚔️', 0xFFE65100),
  kingdom('Kingdom', '👑', 0xFFFFA000),
  exile('Exile', '⛓️', 0xFF5D4037),
  prophets('Prophets', '📜', 0xFF7B1FA2),
  jesus('Jesus', '✝️', 0xFFAB47BC),
  earlyChurch('Early Church', '⛪', 0xFF2E7D32),
  revelation('Revelation', '🔥', 0xFFC62828);

  final String label;
  final String emoji;
  final int color;
  const BiblicalEra(this.label, this.emoji, this.color);
}

/// A biblical location with coordinates and metadata.
class BiblicalPlace {
  final String name;
  final String modernName;
  final LatLng position;
  final String description;
  final List<String> relatedVerses; // e.g. "Genesis 12:1"
  final String emoji;
  final List<BiblicalEra> eras;

  const BiblicalPlace({
    required this.name,
    required this.modernName,
    required this.position,
    required this.description,
    this.relatedVerses = const [],
    this.emoji = '📍',
    this.eras = const [],
  });
}

/// A biblical journey with waypoints.
class BiblicalJourney {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final int color; // ARGB
  final List<LatLng> route;
  final List<BiblicalPlace> stops;
  final List<String> relatedBooks;

  const BiblicalJourney({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.color,
    required this.route,
    required this.stops,
    this.relatedBooks = const [],
  });
}

// ─── Key Biblical Places ────────────────────────────────────────

final kBiblicalPlaces = <BiblicalPlace>[
  BiblicalPlace(
    name: 'Jerusalem',
    modernName: 'Jerusalem, Israel',
    position: LatLng(31.7683, 35.2137),
    description: 'The Holy City — center of Jewish worship, site of the Temple, and where Jesus was crucified and rose again.',
    relatedVerses: ['Psalm 122:1', 'Luke 19:41', 'Acts 2:1'],
    emoji: '🏛️',
    eras: [BiblicalEra.patriarchs, BiblicalEra.kingdom, BiblicalEra.jesus, BiblicalEra.earlyChurch],
  ),
  BiblicalPlace(
    name: 'Bethlehem',
    modernName: 'Bethlehem, Palestine',
    position: LatLng(31.7054, 35.2024),
    description: 'Birthplace of Jesus and King David. "But you, Bethlehem, though you are small..."',
    relatedVerses: ['Micah 5:2', 'Luke 2:4', 'Matthew 2:1'],
    emoji: '⭐',
    eras: [BiblicalEra.kingdom, BiblicalEra.jesus],
  ),
  BiblicalPlace(
    name: 'Nazareth',
    modernName: 'Nazareth, Israel',
    position: LatLng(32.6996, 35.3035),
    description: 'Hometown of Jesus, where He grew up and was announced by the angel Gabriel.',
    relatedVerses: ['Luke 1:26', 'Matthew 2:23', 'Luke 4:16'],
    emoji: '🏠',
    eras: [BiblicalEra.jesus],
  ),
  BiblicalPlace(
    name: 'Capernaum',
    modernName: 'Tel Hum, Israel',
    position: LatLng(32.8803, 35.5753),
    description: 'Jesus\'s base of ministry by the Sea of Galilee. Many miracles happened here.',
    relatedVerses: ['Matthew 4:13', 'Mark 2:1', 'John 6:59'],
    emoji: '🐟',
    eras: [BiblicalEra.jesus],
  ),
  BiblicalPlace(
    name: 'Sea of Galilee',
    modernName: 'Lake Kinneret, Israel',
    position: LatLng(32.8231, 35.5831),
    description: 'Where Jesus walked on water, calmed the storm, and called His first disciples.',
    relatedVerses: ['Matthew 14:25', 'Mark 4:39', 'Luke 5:1'],
    emoji: '🌊',
    eras: [BiblicalEra.jesus],
  ),
  BiblicalPlace(
    name: 'Mount Sinai',
    modernName: 'Jebel Musa, Egypt',
    position: LatLng(28.5392, 33.9750),
    description: 'Where God gave Moses the Ten Commandments amid thunder and lightning.',
    relatedVerses: ['Exodus 19:20', 'Exodus 20:1', 'Deuteronomy 5:2'],
    emoji: '⛰️',
    eras: [BiblicalEra.exodus],
  ),
  BiblicalPlace(
    name: 'Babylon',
    modernName: 'Hillah, Iraq',
    position: LatLng(32.5421, 44.4210),
    description: 'The great empire that conquered Judah. Where Daniel served kings and the Jews were exiled.',
    relatedVerses: ['Daniel 1:1', 'Psalm 137:1', 'Jeremiah 29:10'],
    emoji: '🏰',
    eras: [BiblicalEra.exile, BiblicalEra.prophets],
  ),
  BiblicalPlace(
    name: 'Ur of the Chaldees',
    modernName: 'Tell el-Muqayyar, Iraq',
    position: LatLng(30.9627, 46.1031),
    description: 'Abraham\'s birthplace. God called him to leave and journey to a promised land.',
    relatedVerses: ['Genesis 11:31', 'Genesis 12:1', 'Acts 7:2'],
    emoji: '🌙',
    eras: [BiblicalEra.patriarchs],
  ),
  BiblicalPlace(
    name: 'Egypt (Goshen)',
    modernName: 'Nile Delta, Egypt',
    position: LatLng(30.8569, 31.8518),
    description: 'Where Israel lived as slaves before the Exodus. Joseph brought his family here.',
    relatedVerses: ['Genesis 47:6', 'Exodus 1:11', 'Exodus 12:31'],
    emoji: '🏺',
    eras: [BiblicalEra.patriarchs, BiblicalEra.exodus],
  ),
  BiblicalPlace(
    name: 'Jericho',
    modernName: 'Jericho, Palestine',
    position: LatLng(31.8611, 35.4600),
    description: 'The first city conquered after crossing the Jordan. Its walls fell at the sound of trumpets.',
    relatedVerses: ['Joshua 6:20', 'Luke 19:1', '2 Kings 2:4'],
    emoji: '🎺',
    eras: [BiblicalEra.conquest, BiblicalEra.jesus],
  ),
  BiblicalPlace(
    name: 'Damascus',
    modernName: 'Damascus, Syria',
    position: LatLng(33.5138, 36.2765),
    description: 'Where Saul was blinded by light and became Paul the Apostle.',
    relatedVerses: ['Acts 9:3', 'Acts 22:6', '2 Corinthians 11:32'],
    emoji: '⚡',
    eras: [BiblicalEra.earlyChurch],
  ),
  BiblicalPlace(
    name: 'Antioch',
    modernName: 'Antakya, Turkey',
    position: LatLng(36.2025, 36.1604),
    description: 'Where believers were first called "Christians." Launch point for Paul\'s missionary journeys.',
    relatedVerses: ['Acts 11:26', 'Acts 13:1', 'Galatians 2:11'],
    emoji: '⛪',
    eras: [BiblicalEra.earlyChurch],
  ),
  BiblicalPlace(
    name: 'Ephesus',
    modernName: 'Selçuk, Turkey',
    position: LatLng(37.9411, 27.3417),
    description: 'Major church city. Paul preached here for two years. Home of the temple of Artemis.',
    relatedVerses: ['Acts 19:1', 'Ephesians 1:1', 'Revelation 2:1'],
    emoji: '🏛️',
    eras: [BiblicalEra.earlyChurch, BiblicalEra.revelation],
  ),
  BiblicalPlace(
    name: 'Corinth',
    modernName: 'Corinth, Greece',
    position: LatLng(37.9063, 22.8788),
    description: 'A wealthy trade city where Paul founded a church and wrote two famous letters.',
    relatedVerses: ['Acts 18:1', '1 Corinthians 1:2', '2 Corinthians 1:1'],
    emoji: '🏛️',
    eras: [BiblicalEra.earlyChurch],
  ),
  BiblicalPlace(
    name: 'Athens',
    modernName: 'Athens, Greece',
    position: LatLng(37.9838, 23.7275),
    description: 'Where Paul preached to philosophers on Mars Hill about "the unknown God."',
    relatedVerses: ['Acts 17:16', 'Acts 17:22'],
    emoji: '🏛️',
    eras: [BiblicalEra.earlyChurch],
  ),
  BiblicalPlace(
    name: 'Rome',
    modernName: 'Rome, Italy',
    position: LatLng(41.9028, 12.4964),
    description: 'Capital of the Roman Empire. Paul was imprisoned here and wrote several letters.',
    relatedVerses: ['Acts 28:14', 'Romans 1:7', 'Philippians 1:13'],
    emoji: '🏟️',
    eras: [BiblicalEra.earlyChurch],
  ),
  BiblicalPlace(
    name: 'Patmos',
    modernName: 'Patmos, Greece',
    position: LatLng(37.3227, 26.5453),
    description: 'The island where John received the vision of Revelation.',
    relatedVerses: ['Revelation 1:9'],
    emoji: '🏝️',
    eras: [BiblicalEra.revelation],
  ),
  BiblicalPlace(
    name: 'Jordan River',
    modernName: 'Jordan River',
    position: LatLng(31.7596, 35.5472),
    description: 'Where Jesus was baptized by John. Israel crossed it to enter the Promised Land.',
    relatedVerses: ['Matthew 3:13', 'Joshua 3:17', '2 Kings 5:14'],
    emoji: '💧',
    eras: [BiblicalEra.conquest, BiblicalEra.jesus],
  ),
  BiblicalPlace(
    name: 'Nineveh',
    modernName: 'Mosul, Iraq',
    position: LatLng(36.3566, 43.1592),
    description: 'The great Assyrian city where Jonah preached and the people repented.',
    relatedVerses: ['Jonah 1:2', 'Jonah 3:5', 'Nahum 1:1'],
    emoji: '🐋',
    eras: [BiblicalEra.prophets],
  ),
  BiblicalPlace(
    name: 'Bethany',
    modernName: 'Al-Eizariya, Palestine',
    position: LatLng(31.7700, 35.2569),
    description: 'Home of Mary, Martha, and Lazarus. Where Jesus raised Lazarus from the dead.',
    relatedVerses: ['John 11:1', 'Luke 10:38', 'Mark 14:3'],
    emoji: '🏠',
    eras: [BiblicalEra.jesus],
  ),
  BiblicalPlace(
    name: 'Philippi',
    modernName: 'Filippoi, Greece',
    position: LatLng(41.0117, 24.2867),
    description: 'First European city to hear the Gospel. Paul and Silas were imprisoned here.',
    relatedVerses: ['Acts 16:12', 'Philippians 1:1'],
    emoji: '⛪',
    eras: [BiblicalEra.earlyChurch],
  ),
  BiblicalPlace(
    name: 'Thessalonica',
    modernName: 'Thessaloniki, Greece',
    position: LatLng(40.6301, 22.9444),
    description: 'Paul founded a church here on his second missionary journey.',
    relatedVerses: ['Acts 17:1', '1 Thessalonians 1:1'],
    emoji: '📬',
    eras: [BiblicalEra.earlyChurch],
  ),
  BiblicalPlace(
    name: 'Crete',
    modernName: 'Crete, Greece',
    position: LatLng(35.2401, 24.8963),
    description: 'Where Titus was left to appoint elders and set things in order.',
    relatedVerses: ['Titus 1:5', 'Acts 27:7'],
    emoji: '🏝️',
    eras: [BiblicalEra.earlyChurch],
  ),
  BiblicalPlace(
    name: 'Tarsus',
    modernName: 'Tarsus, Turkey',
    position: LatLng(36.9190, 34.8938),
    description: 'Paul\'s birthplace in the Roman province of Cilicia.',
    relatedVerses: ['Acts 21:39', 'Acts 22:3'],
    emoji: '🏠',
    eras: [BiblicalEra.earlyChurch],
  ),
  BiblicalPlace(
    name: 'Caesarea',
    modernName: 'Caesarea, Israel',
    position: LatLng(32.4996, 34.8903),
    description: 'Roman administrative capital of Judea where Paul was imprisoned before sailing to Rome.',
    relatedVerses: ['Acts 10:1', 'Acts 23:23', 'Acts 25:1'],
    emoji: '🏰',
    eras: [BiblicalEra.earlyChurch],
  ),
  BiblicalPlace(
    name: 'Bethsaida',
    modernName: 'Et-Tell, Israel',
    position: LatLng(32.9070, 35.6300),
    description: 'Hometown of Peter, Andrew, and Philip. Jesus fed the 5,000 near here.',
    relatedVerses: ['John 1:44', 'Luke 9:10', 'Mark 8:22'],
    emoji: '🍞',
    eras: [BiblicalEra.jesus],
  ),

  // ─── New Places ────────────────────────────────────────────────

  // Seven Churches of Revelation
  BiblicalPlace(
    name: 'Smyrna',
    modernName: 'Izmir, Turkey',
    position: LatLng(38.4192, 27.1287),
    description: 'Church that suffered persecution but was rich in faith. "Be faithful unto death."',
    relatedVerses: ['Revelation 2:8'],
    emoji: '💎',
    eras: [BiblicalEra.revelation],
  ),
  BiblicalPlace(
    name: 'Pergamum',
    modernName: 'Bergama, Turkey',
    position: LatLng(39.1216, 27.1833),
    description: 'Church where "Satan\'s throne" was. Faithful witness Antipas was martyred here.',
    relatedVerses: ['Revelation 2:12'],
    emoji: '🪨',
    eras: [BiblicalEra.revelation],
  ),
  BiblicalPlace(
    name: 'Thyatira',
    modernName: 'Akhisar, Turkey',
    position: LatLng(38.9175, 27.8386),
    description: 'Known for its trade guilds. Church rebuked for tolerating false teaching.',
    relatedVerses: ['Revelation 2:18', 'Acts 16:14'],
    emoji: '🎨',
    eras: [BiblicalEra.revelation],
  ),
  BiblicalPlace(
    name: 'Sardis',
    modernName: 'Sart, Turkey',
    position: LatLng(38.4875, 28.0406),
    description: '"You have a reputation of being alive, but you are dead." Called to wake up.',
    relatedVerses: ['Revelation 3:1'],
    emoji: '💀',
    eras: [BiblicalEra.revelation],
  ),
  BiblicalPlace(
    name: 'Philadelphia',
    modernName: 'Alaşehir, Turkey',
    position: LatLng(38.3500, 28.5167),
    description: 'Faithful church given an "open door" that no one can shut.',
    relatedVerses: ['Revelation 3:7'],
    emoji: '🚪',
    eras: [BiblicalEra.revelation],
  ),
  BiblicalPlace(
    name: 'Laodicea',
    modernName: 'near Denizli, Turkey',
    position: LatLng(37.8358, 29.1083),
    description: 'The "lukewarm" church — neither hot nor cold. Known for its wealth.',
    relatedVerses: ['Revelation 3:14', 'Colossians 4:16'],
    emoji: '🌡️',
    eras: [BiblicalEra.revelation],
  ),

  // Old Testament sites
  BiblicalPlace(
    name: 'Hebron',
    modernName: 'Hebron, Palestine',
    position: LatLng(31.5326, 35.0998),
    description: 'Where Abraham, Isaac, and Jacob were buried. David\'s first capital.',
    relatedVerses: ['Genesis 23:19', '2 Samuel 2:11', 'Genesis 13:18'],
    emoji: '🌳',
    eras: [BiblicalEra.patriarchs, BiblicalEra.kingdom],
  ),
  BiblicalPlace(
    name: 'Beersheba',
    modernName: 'Be\'er Sheva, Israel',
    position: LatLng(31.2518, 34.7913),
    description: 'Southern boundary of Israel. Abraham and Isaac dug wells here.',
    relatedVerses: ['Genesis 21:31', 'Genesis 26:33', '1 Kings 19:3'],
    emoji: '💧',
    eras: [BiblicalEra.patriarchs],
  ),
  BiblicalPlace(
    name: 'Shechem',
    modernName: 'Nablus area, Palestine',
    position: LatLng(32.2141, 35.2681),
    description: 'Where God first promised the land to Abraham. Joshua renewed the covenant here.',
    relatedVerses: ['Genesis 12:6', 'Joshua 24:1', 'John 4:5'],
    emoji: '⛺',
    eras: [BiblicalEra.patriarchs, BiblicalEra.conquest],
  ),
  BiblicalPlace(
    name: 'Bethel',
    modernName: 'Beitin, Palestine',
    position: LatLng(31.9349, 35.2274),
    description: 'Where Jacob saw the ladder to heaven. "This is the gate of heaven."',
    relatedVerses: ['Genesis 28:19', 'Genesis 35:1', '1 Kings 12:29'],
    emoji: '🪜',
    eras: [BiblicalEra.patriarchs],
  ),
  BiblicalPlace(
    name: 'Samaria',
    modernName: 'Sebastia, Palestine',
    position: LatLng(32.2753, 35.1903),
    description: 'Capital of the northern kingdom of Israel. Fell to Assyria in 722 BC.',
    relatedVerses: ['1 Kings 16:24', '2 Kings 17:6', 'Acts 8:5'],
    emoji: '👑',
    eras: [BiblicalEra.kingdom, BiblicalEra.exile],
  ),
  BiblicalPlace(
    name: 'Shiloh',
    modernName: 'Khirbet Seilun, Palestine',
    position: LatLng(32.0569, 35.2903),
    description: 'Where the Tabernacle rested for centuries. Young Samuel heard God here.',
    relatedVerses: ['Joshua 18:1', '1 Samuel 3:21', 'Jeremiah 7:12'],
    emoji: '⛺',
    eras: [BiblicalEra.conquest, BiblicalEra.kingdom],
  ),
  BiblicalPlace(
    name: 'Megiddo',
    modernName: 'Tel Megiddo, Israel',
    position: LatLng(32.5847, 35.1847),
    description: 'Strategic fortress city. "Armageddon" derives from Har Megiddo (Mount Megiddo).',
    relatedVerses: ['Judges 5:19', '2 Kings 23:29', 'Revelation 16:16'],
    emoji: '⚔️',
    eras: [BiblicalEra.conquest, BiblicalEra.kingdom, BiblicalEra.revelation],
  ),
  BiblicalPlace(
    name: 'Mount Carmel',
    modernName: 'Haifa, Israel',
    position: LatLng(32.7352, 34.9916),
    description: 'Where Elijah challenged the prophets of Baal and fire fell from heaven.',
    relatedVerses: ['1 Kings 18:19', '1 Kings 18:38'],
    emoji: '🔥',
    eras: [BiblicalEra.prophets],
  ),
  BiblicalPlace(
    name: 'Dan',
    modernName: 'Tel Dan, Israel',
    position: LatLng(33.2486, 35.6519),
    description: 'Northernmost city of Israel. "From Dan to Beersheba" described the whole nation.',
    relatedVerses: ['Judges 18:29', '1 Kings 12:29'],
    emoji: '🗿',
    eras: [BiblicalEra.conquest, BiblicalEra.kingdom],
  ),
  BiblicalPlace(
    name: 'Hazor',
    modernName: 'Tel Hazor, Israel',
    position: LatLng(33.0175, 35.5678),
    description: 'Largest Canaanite city. Joshua defeated its king Jabin; later rebuilt by Solomon.',
    relatedVerses: ['Joshua 11:10', 'Judges 4:2', '1 Kings 9:15'],
    emoji: '🏰',
    eras: [BiblicalEra.conquest, BiblicalEra.kingdom],
  ),
  BiblicalPlace(
    name: 'Lachish',
    modernName: 'Tel Lachish, Israel',
    position: LatLng(31.5647, 34.8489),
    description: 'Second most important city of Judah. Sennacherib\'s siege depicted on palace reliefs.',
    relatedVerses: ['Joshua 10:31', '2 Kings 18:14', '2 Chronicles 11:9'],
    emoji: '🏰',
    eras: [BiblicalEra.conquest, BiblicalEra.kingdom],
  ),
  BiblicalPlace(
    name: 'Dothan',
    modernName: 'Tell Dothan, Palestine',
    position: LatLng(32.4050, 35.2250),
    description: 'Where Joseph was sold by his brothers. Elisha saw heavenly chariots of fire.',
    relatedVerses: ['Genesis 37:17', '2 Kings 6:13'],
    emoji: '🔥',
    eras: [BiblicalEra.patriarchs, BiblicalEra.prophets],
  ),
  BiblicalPlace(
    name: 'Haran',
    modernName: 'Harran, Turkey',
    position: LatLng(36.8637, 39.0290),
    description: 'Where Abraham stayed before continuing to Canaan. Where Jacob fled from Esau.',
    relatedVerses: ['Genesis 11:31', 'Genesis 27:43', 'Genesis 29:4'],
    emoji: '🏕️',
    eras: [BiblicalEra.patriarchs],
  ),
  BiblicalPlace(
    name: 'Mount Nebo',
    modernName: 'Mount Nebo, Jordan',
    position: LatLng(31.7672, 35.7253),
    description: 'Where Moses viewed the Promised Land before he died.',
    relatedVerses: ['Deuteronomy 34:1', 'Deuteronomy 32:49'],
    emoji: '⛰️',
    eras: [BiblicalEra.exodus],
  ),
  BiblicalPlace(
    name: 'Ai',
    modernName: 'Et-Tell, Palestine',
    position: LatLng(31.9153, 35.2564),
    description: 'Israel was first defeated here due to Achan\'s sin, then conquered it on the second attempt.',
    relatedVerses: ['Joshua 7:5', 'Joshua 8:28'],
    emoji: '⚔️',
    eras: [BiblicalEra.conquest],
  ),
  BiblicalPlace(
    name: 'Gibeon',
    modernName: 'El-Jib, Palestine',
    position: LatLng(31.8481, 35.1856),
    description: 'Where the sun stood still for Joshua. Solomon received wisdom from God here.',
    relatedVerses: ['Joshua 10:12', '1 Kings 3:5', '2 Samuel 2:13'],
    emoji: '☀️',
    eras: [BiblicalEra.conquest, BiblicalEra.kingdom],
  ),
  BiblicalPlace(
    name: 'Gaza',
    modernName: 'Gaza City',
    position: LatLng(31.5000, 34.4667),
    description: 'Philistine city where Samson was imprisoned and brought down the temple of Dagon.',
    relatedVerses: ['Judges 16:21', 'Judges 16:30', 'Acts 8:26'],
    emoji: '🏛️',
    eras: [BiblicalEra.conquest, BiblicalEra.kingdom],
  ),
  BiblicalPlace(
    name: 'Susa',
    modernName: 'Shush, Iran',
    position: LatLng(32.1878, 48.2570),
    description: 'Persian capital where Queen Esther saved her people. Nehemiah served King Artaxerxes.',
    relatedVerses: ['Esther 1:2', 'Nehemiah 1:1', 'Daniel 8:2'],
    emoji: '👸',
    eras: [BiblicalEra.exile],
  ),
  BiblicalPlace(
    name: 'Joppa',
    modernName: 'Jaffa (Tel Aviv), Israel',
    position: LatLng(32.0539, 34.7518),
    description: 'Where Jonah fled from God. Peter received a vision of clean and unclean animals.',
    relatedVerses: ['Jonah 1:3', 'Acts 9:36', 'Acts 10:5'],
    emoji: '⛵',
    eras: [BiblicalEra.prophets, BiblicalEra.earlyChurch],
  ),
  BiblicalPlace(
    name: 'Cana',
    modernName: 'Kafr Kanna, Israel',
    position: LatLng(32.7469, 35.3392),
    description: 'Where Jesus performed His first miracle, turning water into wine at a wedding.',
    relatedVerses: ['John 2:1', 'John 4:46'],
    emoji: '🍷',
    eras: [BiblicalEra.jesus],
  ),
  BiblicalPlace(
    name: 'Nain',
    modernName: 'Nein, Israel',
    position: LatLng(32.6350, 35.3500),
    description: 'Where Jesus raised the widow\'s son from the dead.',
    relatedVerses: ['Luke 7:11'],
    emoji: '💫',
    eras: [BiblicalEra.jesus],
  ),
  BiblicalPlace(
    name: 'Caesarea Philippi',
    modernName: 'Banias, Israel',
    position: LatLng(33.2474, 35.6942),
    description: 'Where Peter confessed Jesus as the Christ. "On this rock I will build my church."',
    relatedVerses: ['Matthew 16:13', 'Mark 8:27'],
    emoji: '🪨',
    eras: [BiblicalEra.jesus],
  ),
  BiblicalPlace(
    name: 'Mount of Olives',
    modernName: 'Mount of Olives, Jerusalem',
    position: LatLng(31.7780, 35.2452),
    description: 'Where Jesus prayed before His arrest and ascended to heaven.',
    relatedVerses: ['Luke 22:39', 'Acts 1:12', 'Zechariah 14:4'],
    emoji: '🫒',
    eras: [BiblicalEra.jesus],
  ),
  BiblicalPlace(
    name: 'Golgotha',
    modernName: 'Church of the Holy Sepulchre, Jerusalem',
    position: LatLng(31.7785, 35.2296),
    description: 'The "Place of the Skull" where Jesus was crucified for the sins of the world.',
    relatedVerses: ['Matthew 27:33', 'John 19:17', 'Mark 15:22'],
    emoji: '✝️',
    eras: [BiblicalEra.jesus],
  ),
  BiblicalPlace(
    name: 'Emmaus',
    modernName: 'Near Jerusalem',
    position: LatLng(31.8392, 34.9892),
    description: 'Where the risen Jesus walked with two disciples who did not recognize Him until He broke bread.',
    relatedVerses: ['Luke 24:13'],
    emoji: '🍞',
    eras: [BiblicalEra.jesus],
  ),
  BiblicalPlace(
    name: 'Sychar',
    modernName: "Jacob's Well, Palestine",
    position: LatLng(32.2094, 35.2847),
    description: 'Where Jesus spoke with the Samaritan woman at Jacob\'s well about living water.',
    relatedVerses: ['John 4:5', 'John 4:14'],
    emoji: '💧',
    eras: [BiblicalEra.jesus],
  ),
  BiblicalPlace(
    name: 'Troas',
    modernName: 'Near Çanakkale, Turkey',
    position: LatLng(39.7567, 26.1700),
    description: 'Paul received the Macedonian call here: "Come over and help us."',
    relatedVerses: ['Acts 16:8', 'Acts 20:5', '2 Corinthians 2:12'],
    emoji: '📣',
    eras: [BiblicalEra.earlyChurch],
  ),
  BiblicalPlace(
    name: 'Miletus',
    modernName: 'Near Söke, Turkey',
    position: LatLng(37.5311, 27.2783),
    description: 'Where Paul gave his farewell address to the Ephesian elders.',
    relatedVerses: ['Acts 20:17', '2 Timothy 4:20'],
    emoji: '👋',
    eras: [BiblicalEra.earlyChurch],
  ),
  BiblicalPlace(
    name: 'Derbe',
    modernName: 'Kerti Höyük, Turkey',
    position: LatLng(37.3588, 33.4150),
    description: 'Easternmost point of Paul\'s first journey. Many disciples were made here.',
    relatedVerses: ['Acts 14:20', 'Acts 16:1'],
    emoji: '🌱',
    eras: [BiblicalEra.earlyChurch],
  ),
  BiblicalPlace(
    name: 'Lystra',
    modernName: 'Near Konya, Turkey',
    position: LatLng(37.5958, 32.3480),
    description: 'Timothy\'s hometown. Paul was stoned here but survived. Locals tried to worship Paul as Hermes.',
    relatedVerses: ['Acts 14:8', 'Acts 16:1', '2 Timothy 3:11'],
    emoji: '💪',
    eras: [BiblicalEra.earlyChurch],
  ),
];

// ─── Biblical Journeys ──────────────────────────────────────────

final kBiblicalJourneys = <BiblicalJourney>[
  BiblicalJourney(
    id: 'abraham',
    name: "Abraham's Journey",
    description: 'From Ur to Canaan — God called Abram to leave everything and follow His promise.',
    emoji: '🌟',
    color: 0xFFFFA726,
    relatedBooks: ['Genesis'],
    stops: [
      kBiblicalPlaces.firstWhere((p) => p.name == 'Ur of the Chaldees'),
      BiblicalPlace(name: 'Haran', modernName: 'Harran, Turkey', position: LatLng(36.8637, 39.0290), description: 'Where Abraham stayed before continuing to Canaan.', emoji: '🏕️'),
      BiblicalPlace(name: 'Shechem', modernName: 'Nablus area', position: LatLng(32.2141, 35.2681), description: 'First stop in Canaan where God appeared to Abraham.', emoji: '⛺'),
      kBiblicalPlaces.firstWhere((p) => p.name == 'Egypt (Goshen)'),
      BiblicalPlace(name: 'Hebron', modernName: 'Hebron, Palestine', position: LatLng(31.5326, 35.0998), description: 'Where Abraham settled and was buried.', emoji: '🌳'),
    ],
    route: [
      LatLng(30.9627, 46.1031), // Ur
      LatLng(36.8637, 39.0290), // Haran
      LatLng(32.2141, 35.2681), // Shechem
      LatLng(30.8569, 31.8518), // Egypt
      LatLng(31.5326, 35.0998), // Hebron
    ],
  ),
  BiblicalJourney(
    id: 'exodus',
    name: 'The Exodus',
    description: 'From slavery in Egypt through the Red Sea, to Mount Sinai, and into the Promised Land.',
    emoji: '🌊',
    color: 0xFF1976D2,
    relatedBooks: ['Exodus', 'Numbers', 'Deuteronomy', 'Joshua'],
    stops: [
      kBiblicalPlaces.firstWhere((p) => p.name == 'Egypt (Goshen)'),
      BiblicalPlace(name: 'Red Sea Crossing', modernName: 'Gulf of Suez area', position: LatLng(29.9000, 32.5500), description: 'God parted the waters for Israel to cross.', emoji: '🌊'),
      kBiblicalPlaces.firstWhere((p) => p.name == 'Mount Sinai'),
      BiblicalPlace(name: 'Kadesh Barnea', modernName: 'Ein el-Qudeirat', position: LatLng(30.6174, 34.3980), description: '40 years of wandering began when Israel refused to enter.', emoji: '🏜️'),
      kBiblicalPlaces.firstWhere((p) => p.name == 'Jordan River'),
      kBiblicalPlaces.firstWhere((p) => p.name == 'Jericho'),
    ],
    route: [
      LatLng(30.8569, 31.8518), // Goshen
      LatLng(29.9000, 32.5500), // Red Sea
      LatLng(28.5392, 33.9750), // Sinai
      LatLng(30.6174, 34.3980), // Kadesh
      LatLng(31.7596, 35.5472), // Jordan
      LatLng(31.8611, 35.4600), // Jericho
    ],
  ),
  BiblicalJourney(
    id: 'jesus_ministry',
    name: "Jesus's Ministry",
    description: 'From baptism at the Jordan to His resurrection in Jerusalem — the greatest story ever told.',
    emoji: '✝️',
    color: 0xFFAB47BC,
    relatedBooks: ['Matthew', 'Mark', 'Luke', 'John'],
    stops: [
      kBiblicalPlaces.firstWhere((p) => p.name == 'Bethlehem'),
      kBiblicalPlaces.firstWhere((p) => p.name == 'Nazareth'),
      kBiblicalPlaces.firstWhere((p) => p.name == 'Jordan River'),
      kBiblicalPlaces.firstWhere((p) => p.name == 'Capernaum'),
      kBiblicalPlaces.firstWhere((p) => p.name == 'Sea of Galilee'),
      kBiblicalPlaces.firstWhere((p) => p.name == 'Jericho'),
      kBiblicalPlaces.firstWhere((p) => p.name == 'Bethany'),
      kBiblicalPlaces.firstWhere((p) => p.name == 'Jerusalem'),
    ],
    route: [
      LatLng(31.7054, 35.2024), // Bethlehem
      LatLng(32.6996, 35.3035), // Nazareth
      LatLng(31.7596, 35.5472), // Jordan
      LatLng(32.8803, 35.5753), // Capernaum
      LatLng(32.8231, 35.5831), // Sea of Galilee
      LatLng(31.8611, 35.4600), // Jericho
      LatLng(31.7700, 35.2569), // Bethany
      LatLng(31.7683, 35.2137), // Jerusalem
    ],
  ),
  BiblicalJourney(
    id: 'paul_first',
    name: "Paul's First Missionary Journey",
    description: 'Paul and Barnabas set out from Antioch to bring the Gospel to Cyprus and Asia Minor.',
    emoji: '⛵',
    color: 0xFF2E7D32,
    relatedBooks: ['Acts'],
    stops: [
      kBiblicalPlaces.firstWhere((p) => p.name == 'Antioch'),
      BiblicalPlace(name: 'Salamis, Cyprus', modernName: 'Famagusta, Cyprus', position: LatLng(35.1856, 33.9030), description: 'First stop — preaching in the synagogues of Cyprus.', emoji: '🏝️'),
      BiblicalPlace(name: 'Paphos', modernName: 'Paphos, Cyprus', position: LatLng(34.7554, 32.4009), description: 'Where Paul confronted the sorcerer Bar-Jesus.', emoji: '🔮'),
      BiblicalPlace(name: 'Perga', modernName: 'Antalya, Turkey', position: LatLng(36.9616, 30.8539), description: 'Where John Mark left them to return to Jerusalem.', emoji: '🚶'),
      BiblicalPlace(name: 'Antioch of Pisidia', modernName: 'Yalvaç, Turkey', position: LatLng(38.2944, 31.1831), description: 'Paul preached a powerful sermon in the synagogue.', emoji: '📣'),
      BiblicalPlace(name: 'Iconium', modernName: 'Konya, Turkey', position: LatLng(37.8714, 32.4846), description: 'Many believed but the city was divided.', emoji: '⚔️'),
      BiblicalPlace(name: 'Lystra', modernName: 'near Konya, Turkey', position: LatLng(37.5958, 32.3480), description: 'Paul was stoned and left for dead, but got up and kept going.', emoji: '💪'),
      BiblicalPlace(name: 'Derbe', modernName: 'Kerti Höyük, Turkey', position: LatLng(37.3588, 33.4150), description: 'Many disciples were won here.', emoji: '🌱'),
    ],
    route: [
      LatLng(36.2025, 36.1604), // Antioch
      LatLng(35.1856, 33.9030), // Salamis
      LatLng(34.7554, 32.4009), // Paphos
      LatLng(36.9616, 30.8539), // Perga
      LatLng(38.2944, 31.1831), // Antioch Pisidia
      LatLng(37.8714, 32.4846), // Iconium
      LatLng(37.5958, 32.3480), // Lystra
      LatLng(37.3588, 33.4150), // Derbe
      LatLng(37.5958, 32.3480), // back through Lystra
      LatLng(36.9616, 30.8539), // back to Perga
      LatLng(36.2025, 36.1604), // back to Antioch
    ],
  ),
  BiblicalJourney(
    id: 'paul_rome',
    name: "Paul's Voyage to Rome",
    description: 'A dramatic sea voyage — storms, shipwreck on Malta, and finally arrival in Rome as a prisoner.',
    emoji: '⚓',
    color: 0xFF37474F,
    relatedBooks: ['Acts'],
    stops: [
      BiblicalPlace(name: 'Caesarea', modernName: 'Caesarea, Israel', position: LatLng(32.4996, 34.8903), description: 'Paul was imprisoned here for two years before sailing to Rome.', emoji: '⛓️'),
      BiblicalPlace(name: 'Myra', modernName: 'Demre, Turkey', position: LatLng(36.2445, 29.9837), description: 'Where they changed to an Alexandrian ship.', emoji: '🚢'),
      BiblicalPlace(name: 'Crete', modernName: 'Crete, Greece', position: LatLng(35.2401, 24.4709), description: 'Fair Havens — Paul warned them not to sail further.', emoji: '🏝️'),
      BiblicalPlace(name: 'Malta', modernName: 'Malta', position: LatLng(35.9375, 14.3754), description: 'Shipwrecked! But all 276 people survived. Paul was bitten by a viper and healed the sick.', emoji: '🐍'),
      kBiblicalPlaces.firstWhere((p) => p.name == 'Rome'),
    ],
    route: [
      LatLng(32.4996, 34.8903), // Caesarea
      LatLng(36.2445, 29.9837), // Myra
      LatLng(35.2401, 24.4709), // Crete
      LatLng(35.9375, 14.3754), // Malta
      LatLng(41.9028, 12.4964), // Rome
    ],
  ),
  BiblicalJourney(
    id: 'paul_second',
    name: "Paul's Second Missionary Journey",
    description: 'Paul revisits churches and brings the Gospel to Europe for the first time.',
    emoji: '⛵',
    color: 0xFF1565C0,
    relatedBooks: ['Acts', 'Philippians', '1 Thessalonians', '2 Thessalonians'],
    stops: [
      kBiblicalPlaces.firstWhere((p) => p.name == 'Antioch'),
      kBiblicalPlaces.firstWhere((p) => p.name == 'Philippi'),
      kBiblicalPlaces.firstWhere((p) => p.name == 'Thessalonica'),
      kBiblicalPlaces.firstWhere((p) => p.name == 'Athens'),
      kBiblicalPlaces.firstWhere((p) => p.name == 'Corinth'),
      kBiblicalPlaces.firstWhere((p) => p.name == 'Ephesus'),
    ],
    route: [
      LatLng(36.2025, 36.1604), // Antioch
      LatLng(36.9190, 34.8938), // Tarsus
      LatLng(37.3588, 33.4150), // Derbe
      LatLng(37.5958, 32.3480), // Lystra
      LatLng(41.0117, 24.2867), // Philippi
      LatLng(40.6301, 22.9444), // Thessalonica
      LatLng(37.9838, 23.7275), // Athens
      LatLng(37.9063, 22.8788), // Corinth
      LatLng(37.9411, 27.3417), // Ephesus
      LatLng(36.2025, 36.1604), // Antioch
    ],
  ),
  BiblicalJourney(
    id: 'jesus_galilee',
    name: "Jesus's Galilean Ministry",
    description: 'Jesus teaches, heals, and calls his disciples around the Sea of Galilee.',
    emoji: '🐟',
    color: 0xFF2E7D32,
    relatedBooks: ['Matthew', 'Mark', 'Luke'],
    stops: [
      kBiblicalPlaces.firstWhere((p) => p.name == 'Nazareth'),
      kBiblicalPlaces.firstWhere((p) => p.name == 'Cana'),
      kBiblicalPlaces.firstWhere((p) => p.name == 'Capernaum'),
      kBiblicalPlaces.firstWhere((p) => p.name == 'Bethsaida'),
      kBiblicalPlaces.firstWhere((p) => p.name == 'Nain'),
      kBiblicalPlaces.firstWhere((p) => p.name == 'Caesarea Philippi'),
    ],
    route: [
      LatLng(32.6996, 35.3035), // Nazareth
      LatLng(32.7469, 35.3392), // Cana
      LatLng(32.8803, 35.5753), // Capernaum
      LatLng(32.8231, 35.5831), // Sea of Galilee area
      LatLng(32.9070, 35.6300), // Bethsaida
      LatLng(32.6350, 35.3500), // Nain
      LatLng(33.2474, 35.6942), // Caesarea Philippi
      LatLng(32.8803, 35.5753), // back to Capernaum
    ],
  ),

  // ─── New Journeys ──────────────────────────────────────────────

  BiblicalJourney(
    id: 'conquest_canaan',
    name: 'Conquest of Canaan',
    description: 'Joshua leads Israel across the Jordan to conquer the Promised Land city by city.',
    emoji: '⚔️',
    color: 0xFFE65100,
    relatedBooks: ['Joshua'],
    stops: [
      kBiblicalPlaces.firstWhere((p) => p.name == 'Jordan River'),
      kBiblicalPlaces.firstWhere((p) => p.name == 'Jericho'),
      kBiblicalPlaces.firstWhere((p) => p.name == 'Ai'),
      kBiblicalPlaces.firstWhere((p) => p.name == 'Gibeon'),
      kBiblicalPlaces.firstWhere((p) => p.name == 'Lachish'),
      kBiblicalPlaces.firstWhere((p) => p.name == 'Hazor'),
      kBiblicalPlaces.firstWhere((p) => p.name == 'Shechem'),
    ],
    route: [
      LatLng(31.7596, 35.5472), // Jordan River
      LatLng(31.8611, 35.4600), // Jericho
      LatLng(31.9153, 35.2564), // Ai
      LatLng(31.8481, 35.1856), // Gibeon
      LatLng(31.5647, 34.8489), // Lachish
      LatLng(33.0175, 35.5678), // Hazor
      LatLng(32.2141, 35.2681), // Shechem
    ],
  ),

  BiblicalJourney(
    id: 'elijah',
    name: "Elijah's Journey",
    description: 'The prophet Elijah confronts Baal worship, flees Jezebel, and meets God at Horeb.',
    emoji: '🔥',
    color: 0xFFFF6F00,
    relatedBooks: ['1 Kings', '2 Kings'],
    stops: [
      kBiblicalPlaces.firstWhere((p) => p.name == 'Samaria'),
      kBiblicalPlaces.firstWhere((p) => p.name == 'Mount Carmel'),
      kBiblicalPlaces.firstWhere((p) => p.name == 'Beersheba'),
      kBiblicalPlaces.firstWhere((p) => p.name == 'Mount Sinai'),
      kBiblicalPlaces.firstWhere((p) => p.name == 'Damascus'),
      kBiblicalPlaces.firstWhere((p) => p.name == 'Jordan River'),
    ],
    route: [
      LatLng(32.2753, 35.1903), // Samaria
      LatLng(32.7352, 34.9916), // Mount Carmel
      LatLng(31.2518, 34.7913), // Beersheba
      LatLng(28.5392, 33.9750), // Mount Sinai (Horeb)
      LatLng(33.5138, 36.2765), // Damascus
      LatLng(31.7596, 35.5472), // Jordan River (taken up)
    ],
  ),

  BiblicalJourney(
    id: 'paul_third',
    name: "Paul's Third Missionary Journey",
    description: 'Paul strengthens the churches of Asia Minor and Greece before his final trip to Jerusalem.',
    emoji: '⛵',
    color: 0xFF6A1B9A,
    relatedBooks: ['Acts', '1 Corinthians', '2 Corinthians', 'Romans', 'Galatians'],
    stops: [
      kBiblicalPlaces.firstWhere((p) => p.name == 'Antioch'),
      kBiblicalPlaces.firstWhere((p) => p.name == 'Ephesus'),
      kBiblicalPlaces.firstWhere((p) => p.name == 'Troas'),
      kBiblicalPlaces.firstWhere((p) => p.name == 'Philippi'),
      kBiblicalPlaces.firstWhere((p) => p.name == 'Corinth'),
      kBiblicalPlaces.firstWhere((p) => p.name == 'Miletus'),
      kBiblicalPlaces.firstWhere((p) => p.name == 'Caesarea'),
      kBiblicalPlaces.firstWhere((p) => p.name == 'Jerusalem'),
    ],
    route: [
      LatLng(36.2025, 36.1604), // Antioch
      LatLng(36.9190, 34.8938), // Tarsus
      LatLng(37.3588, 33.4150), // Derbe
      LatLng(37.5958, 32.3480), // Lystra
      LatLng(37.9411, 27.3417), // Ephesus
      LatLng(39.7567, 26.1700), // Troas
      LatLng(41.0117, 24.2867), // Philippi
      LatLng(40.6301, 22.9444), // Thessalonica
      LatLng(37.9063, 22.8788), // Corinth
      LatLng(39.7567, 26.1700), // back to Troas
      LatLng(37.5311, 27.2783), // Miletus
      LatLng(32.4996, 34.8903), // Caesarea
      LatLng(31.7683, 35.2137), // Jerusalem
    ],
  ),

  BiblicalJourney(
    id: 'seven_churches',
    name: 'Seven Churches of Revelation',
    description: 'The seven churches in Asia Minor that received letters from Jesus through John.',
    emoji: '🔥',
    color: 0xFFC62828,
    relatedBooks: ['Revelation'],
    stops: [
      kBiblicalPlaces.firstWhere((p) => p.name == 'Patmos'),
      kBiblicalPlaces.firstWhere((p) => p.name == 'Ephesus'),
      kBiblicalPlaces.firstWhere((p) => p.name == 'Smyrna'),
      kBiblicalPlaces.firstWhere((p) => p.name == 'Pergamum'),
      kBiblicalPlaces.firstWhere((p) => p.name == 'Thyatira'),
      kBiblicalPlaces.firstWhere((p) => p.name == 'Sardis'),
      kBiblicalPlaces.firstWhere((p) => p.name == 'Philadelphia'),
      kBiblicalPlaces.firstWhere((p) => p.name == 'Laodicea'),
    ],
    route: [
      LatLng(37.3227, 26.5453), // Patmos
      LatLng(37.9411, 27.3417), // Ephesus
      LatLng(38.4192, 27.1287), // Smyrna
      LatLng(39.1216, 27.1833), // Pergamum
      LatLng(38.9175, 27.8386), // Thyatira
      LatLng(38.4875, 28.0406), // Sardis
      LatLng(38.3500, 28.5167), // Philadelphia
      LatLng(37.8358, 29.1083), // Laodicea
    ],
  ),
];
