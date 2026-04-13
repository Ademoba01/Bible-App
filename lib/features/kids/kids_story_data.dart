/// Rich illustrated kids Bible stories with page-by-page content,
/// emojis as visual illustrations, pastel backgrounds, and moral lessons.
class IllustratedStory {
  final String title;
  final String emoji;
  final List<StoryPage> pages;
  final String moralLesson;
  final String bibleReference;
  final int color;

  const IllustratedStory({
    required this.title,
    required this.emoji,
    required this.pages,
    required this.moralLesson,
    required this.bibleReference,
    required this.color,
  });
}

class StoryPage {
  final String text;
  final String emoji;
  final int backgroundColor;

  const StoryPage({
    required this.text,
    required this.emoji,
    required this.backgroundColor,
  });
}

const kIllustratedStories = <IllustratedStory>[
  // ── 1. Creation ──
  IllustratedStory(
    title: 'Creation',
    emoji: '🌍',
    bibleReference: 'Genesis 1-2',
    color: 0xFF66BB6A,
    moralLesson: 'God made everything beautiful, and He loves all of His creation - especially you!',
    pages: [
      StoryPage(text: 'In the very beginning, there was nothing at all. No sky, no ground, no animals. Just darkness everywhere.', emoji: '🌑', backgroundColor: 0xFFE8EAF6),
      StoryPage(text: 'Then God said, "Let there be light!" And suddenly, beautiful bright light appeared! God called the light "Day" and the darkness "Night."', emoji: '☀️', backgroundColor: 0xFFFFF9C4),
      StoryPage(text: 'Next, God made the big blue sky above and the sparkling waters below. He made rivers, lakes, and huge oceans!', emoji: '🌊', backgroundColor: 0xFFBBDEFB),
      StoryPage(text: 'God covered the ground with soft green grass, tall trees, and colorful flowers. Red roses, yellow sunflowers, and purple violets!', emoji: '🌸', backgroundColor: 0xFFC8E6C9),
      StoryPage(text: 'He put the bright sun in the sky for daytime and the glowing moon and twinkly stars for nighttime.', emoji: '🌙', backgroundColor: 0xFFE1BEE7),
      StoryPage(text: 'God filled the oceans with fish and the sky with birds. Tiny hummingbirds, giant eagles, and silly penguins!', emoji: '🐟', backgroundColor: 0xFFB3E5FC),
      StoryPage(text: 'Then God made all the animals - fuzzy bears, tall giraffes, bouncy kangaroos, and every creature you can imagine!', emoji: '🦁', backgroundColor: 0xFFFFE0B2),
      StoryPage(text: 'Finally, God made people - a man named Adam and a woman named Eve. God looked at everything and said, "It is very good!"', emoji: '👨‍👩‍👧', backgroundColor: 0xFFF8BBD0),
    ],
  ),

  // ── 2. Adam and Eve ──
  IllustratedStory(
    title: 'Adam and Eve',
    emoji: '🍎',
    bibleReference: 'Genesis 3',
    color: 0xFFEF5350,
    moralLesson: 'It is always best to listen to God, even when other choices look tempting.',
    pages: [
      StoryPage(text: 'Adam and Eve lived in a beautiful garden called Eden. It had yummy fruit, friendly animals, and a river running through it.', emoji: '🏡', backgroundColor: 0xFFC8E6C9),
      StoryPage(text: 'God told them, "You may eat fruit from any tree, but NOT from the tree in the middle of the garden."', emoji: '🌳', backgroundColor: 0xFFDCEDC8),
      StoryPage(text: 'One day, a sneaky snake came and said to Eve, "Go on, eat the fruit! It will make you super smart!"', emoji: '🐍', backgroundColor: 0xFFFFF9C4),
      StoryPage(text: 'Eve looked at the fruit. It was pretty and it smelled delicious. She took a bite and gave some to Adam too.', emoji: '🍎', backgroundColor: 0xFFFFCDD2),
      StoryPage(text: 'Right away, they felt bad inside. They knew they had disobeyed God. They tried to hide behind some bushes.', emoji: '🌿', backgroundColor: 0xFFE8EAF6),
      StoryPage(text: 'God found them and was sad they did not listen. They had to leave the beautiful garden. But God still loved them and promised to take care of them.', emoji: '💝', backgroundColor: 0xFFF8BBD0),
    ],
  ),

  // ── 3. Noah's Ark ──
  IllustratedStory(
    title: "Noah's Ark",
    emoji: '🚢',
    bibleReference: 'Genesis 6-9',
    color: 0xFF42A5F5,
    moralLesson: 'When we trust God and obey Him, He keeps us safe no matter what.',
    pages: [
      StoryPage(text: 'People on Earth were being very mean and unkind. But there was one good man named Noah who loved God.', emoji: '👴', backgroundColor: 0xFFE8EAF6),
      StoryPage(text: 'God told Noah, "Build a really, really big boat called an ark! A great flood is coming."', emoji: '🔨', backgroundColor: 0xFFFFE0B2),
      StoryPage(text: 'Noah worked hard for a long time. People laughed at him, but Noah kept building because he trusted God.', emoji: '🚢', backgroundColor: 0xFFBBDEFB),
      StoryPage(text: 'When the ark was ready, animals came walking, flying, and crawling - two of every kind! Lions, butterflies, turtles, and more!', emoji: '🦒', backgroundColor: 0xFFC8E6C9),
      StoryPage(text: 'Then the rain started. It rained and rained for forty days and forty nights! Water covered everything.', emoji: '🌧️', backgroundColor: 0xFFB3E5FC),
      StoryPage(text: 'But Noah, his family, and all the animals were safe and cozy inside the ark, floating on the water.', emoji: '🌊', backgroundColor: 0xFFBBDEFB),
      StoryPage(text: 'Finally the rain stopped. Noah sent out a dove, and it came back with a green olive leaf. Land was near!', emoji: '🕊️', backgroundColor: 0xFFFFF9C4),
      StoryPage(text: 'God put a beautiful rainbow in the sky and promised, "I will never flood the whole Earth again." Every rainbow reminds us of God\'s promise!', emoji: '🌈', backgroundColor: 0xFFF8BBD0),
    ],
  ),

  // ── 4. Tower of Babel ──
  IllustratedStory(
    title: 'Tower of Babel',
    emoji: '🏗️',
    bibleReference: 'Genesis 11',
    color: 0xFFFF7043,
    moralLesson: 'We should use our abilities to honor God, not to show off.',
    pages: [
      StoryPage(text: 'After the flood, everyone in the world spoke the same language. They could all understand each other perfectly!', emoji: '🗣️', backgroundColor: 0xFFFFF9C4),
      StoryPage(text: 'Some people got a big idea. "Let\'s build a tower so tall it reaches the sky! Then everyone will think we\'re amazing!"', emoji: '🏗️', backgroundColor: 0xFFFFE0B2),
      StoryPage(text: 'They stacked bricks higher and higher. The tower grew taller and taller. They wanted to be as great as God!', emoji: '🧱', backgroundColor: 0xFFFFCCBC),
      StoryPage(text: 'God saw what they were doing. He knew they were being proud and not thinking about Him at all.', emoji: '👀', backgroundColor: 0xFFE1BEE7),
      StoryPage(text: 'So God mixed up their words! Suddenly, no one could understand each other. "Blah blah?" "Huh?" It was so confusing!', emoji: '😵', backgroundColor: 0xFFBBDEFB),
      StoryPage(text: 'The people stopped building and spread out all over the world, speaking many different languages. That\'s why we have so many languages today!', emoji: '🌍', backgroundColor: 0xFFC8E6C9),
    ],
  ),

  // ── 5. Abraham's Big Move ──
  IllustratedStory(
    title: "Abraham's Big Move",
    emoji: '🐪',
    bibleReference: 'Genesis 12',
    color: 0xFFFFCA28,
    moralLesson: 'When God asks us to do something, we can trust Him even if we do not know what will happen.',
    pages: [
      StoryPage(text: 'There was a man named Abraham who lived in a city with his wife Sarah. They had a nice home and lots of friends.', emoji: '🏠', backgroundColor: 0xFFFFF9C4),
      StoryPage(text: 'One day, God said to Abraham, "Leave your home and go to a new land that I will show you. I have big plans for you!"', emoji: '✨', backgroundColor: 0xFFE1BEE7),
      StoryPage(text: 'Abraham did not know where he was going! But he trusted God. He packed up his things and put them on camels.', emoji: '🐪', backgroundColor: 0xFFFFE0B2),
      StoryPage(text: 'Abraham, Sarah, and their family walked for days and days through hot deserts and over rocky hills.', emoji: '🏜️', backgroundColor: 0xFFFFCCBC),
      StoryPage(text: 'God promised Abraham, "I will give you more children and grandchildren than there are stars in the sky!"', emoji: '⭐', backgroundColor: 0xFFE8EAF6),
      StoryPage(text: 'Abraham believed God\'s promise. And God kept His word! Abraham became the father of a great big family that God blessed forever.', emoji: '👨‍👩‍👧‍👦', backgroundColor: 0xFFC8E6C9),
    ],
  ),

  // ── 6. Joseph and the Colorful Coat ──
  IllustratedStory(
    title: 'Joseph and the Colorful Coat',
    emoji: '🧥',
    bibleReference: 'Genesis 37-45',
    color: 0xFFAB47BC,
    moralLesson: 'Even when bad things happen, God can turn them into something wonderful.',
    pages: [
      StoryPage(text: 'Joseph was a young boy with eleven brothers. His dad Jacob loved him very much and gave him a beautiful coat with many colors!', emoji: '🧥', backgroundColor: 0xFFE1BEE7),
      StoryPage(text: 'His brothers were jealous. "Why does HE get a special coat?" They were so angry they made a terrible plan.', emoji: '😠', backgroundColor: 0xFFFFCDD2),
      StoryPage(text: 'The brothers sold Joseph to strangers who took him far away to Egypt. They told their dad a lion had gotten him!', emoji: '😢', backgroundColor: 0xFFBBDEFB),
      StoryPage(text: 'In Egypt, things got even worse. Joseph was put in prison! But even there, God was with him.', emoji: '🔒', backgroundColor: 0xFFE8EAF6),
      StoryPage(text: 'God gave Joseph the special gift of understanding dreams. He helped the king of Egypt understand a very important dream!', emoji: '👑', backgroundColor: 0xFFFFF9C4),
      StoryPage(text: 'The king was so thankful that he made Joseph an important leader! Joseph helped save everyone when there was no food.', emoji: '🌾', backgroundColor: 0xFFDCEDC8),
      StoryPage(text: 'Joseph\'s brothers came to Egypt looking for food. Joseph forgave them and said, "What you meant for bad, God used for good!" The whole family was together again!', emoji: '🤗', backgroundColor: 0xFFF8BBD0),
    ],
  ),

  // ── 7. Baby Moses in the Basket ──
  IllustratedStory(
    title: 'Baby Moses in the Basket',
    emoji: '👶',
    bibleReference: 'Exodus 2',
    color: 0xFF26C6DA,
    moralLesson: 'God watches over us and protects us, even when things seem scary.',
    pages: [
      StoryPage(text: 'A long time ago in Egypt, a mean king said all baby boys had to be thrown in the river. It was very scary!', emoji: '😰', backgroundColor: 0xFFFFCDD2),
      StoryPage(text: 'One brave mom had a beautiful baby boy. She loved him so much and wanted to keep him safe.', emoji: '👶', backgroundColor: 0xFFF8BBD0),
      StoryPage(text: 'She made a little basket-boat and covered it so no water could get in. She placed her baby inside carefully.', emoji: '🧺', backgroundColor: 0xFFFFE0B2),
      StoryPage(text: 'She put the basket in the river near some tall grass. The baby\'s big sister Miriam hid nearby to watch.', emoji: '🌿', backgroundColor: 0xFFC8E6C9),
      StoryPage(text: 'A princess came to the river to take a bath. She found the basket and saw the cute baby crying. "Oh, what a sweet baby!" she said.', emoji: '👸', backgroundColor: 0xFFE1BEE7),
      StoryPage(text: 'Miriam ran up and said, "I know someone who can take care of him!" She brought their own mother! The princess named the baby Moses.', emoji: '💕', backgroundColor: 0xFFF8BBD0),
      StoryPage(text: 'Moses grew up safe in the palace. God had a very special plan for him - he would one day set his people free!', emoji: '⭐', backgroundColor: 0xFFFFF9C4),
    ],
  ),

  // ── 8. Moses and the Red Sea ──
  IllustratedStory(
    title: 'Moses and the Red Sea',
    emoji: '🌊',
    bibleReference: 'Exodus 14',
    color: 0xFF1E88E5,
    moralLesson: 'When we face impossible problems, God can make a way through.',
    pages: [
      StoryPage(text: 'God\'s people were slaves in Egypt. They had to work so hard every day. Moses asked the king, "Let my people go!"', emoji: '✊', backgroundColor: 0xFFFFE0B2),
      StoryPage(text: 'Finally, the king said yes! Moses led thousands and thousands of people out of Egypt. They were free at last!', emoji: '🎉', backgroundColor: 0xFFFFF9C4),
      StoryPage(text: 'But then the king changed his mind! He sent his army chasing after them with horses and chariots!', emoji: '🐎', backgroundColor: 0xFFFFCDD2),
      StoryPage(text: 'The people reached the Red Sea. Water in front, army behind! "We\'re trapped!" they cried. But Moses said, "Don\'t be afraid! Watch what God will do!"', emoji: '😟', backgroundColor: 0xFFBBDEFB),
      StoryPage(text: 'Moses stretched his hand over the sea. God sent a strong wind that split the water in two! There was a dry path right through the middle!', emoji: '💨', backgroundColor: 0xFFB3E5FC),
      StoryPage(text: 'All the people walked through on dry ground with walls of water on each side. It was amazing!', emoji: '🚶', backgroundColor: 0xFFC8E6C9),
      StoryPage(text: 'When everyone was safe on the other side, the water crashed back together. God saved His people! They sang and danced to thank Him!', emoji: '🎵', backgroundColor: 0xFFF8BBD0),
    ],
  ),

  // ── 9. David and Goliath ──
  IllustratedStory(
    title: 'David and Goliath',
    emoji: '🪨',
    bibleReference: '1 Samuel 17',
    color: 0xFF5C6BC0,
    moralLesson: 'With God on your side, you can be brave even when facing something much bigger than you.',
    pages: [
      StoryPage(text: 'There was a giant named Goliath. He was taller than a door! He wore heavy armor and carried a huge sword.', emoji: '😤', backgroundColor: 0xFFE8EAF6),
      StoryPage(text: 'Every day, Goliath yelled at God\'s people: "Send someone to fight me! I bet nobody is brave enough!" Everyone was terrified.', emoji: '😱', backgroundColor: 0xFFFFCDD2),
      StoryPage(text: 'A young boy named David came to bring lunch to his brothers in the army. He heard Goliath yelling mean things about God.', emoji: '👦', backgroundColor: 0xFFC8E6C9),
      StoryPage(text: '"I\'ll fight the giant!" said David. The king said, "But you\'re just a boy!" David said, "God will help me!"', emoji: '💪', backgroundColor: 0xFFFFF9C4),
      StoryPage(text: 'David did not take a sword or armor. He picked up five smooth stones from a stream and took his slingshot.', emoji: '🪨', backgroundColor: 0xFFBBDEFB),
      StoryPage(text: 'Goliath laughed at tiny David. But David swung his sling and let one stone fly. BONK! It hit Goliath right on the forehead!', emoji: '🎯', backgroundColor: 0xFFFFE0B2),
      StoryPage(text: 'The giant fell down with a big CRASH! David won! Everyone cheered! It was not the stone that won - it was God!', emoji: '🎉', backgroundColor: 0xFFF8BBD0),
    ],
  ),

  // ── 10. Daniel and the Lions ──
  IllustratedStory(
    title: 'Daniel and the Lions',
    emoji: '🦁',
    bibleReference: 'Daniel 6',
    color: 0xFFFF8A65,
    moralLesson: 'Keep praying and trusting God, even when others try to stop you.',
    pages: [
      StoryPage(text: 'Daniel loved God and prayed three times every single day. He would open his window and talk to God.', emoji: '🙏', backgroundColor: 0xFFFFF9C4),
      StoryPage(text: 'Some jealous men tricked the king into making a rule: "No one can pray to anyone except the king! Or they go to the lions!"', emoji: '📜', backgroundColor: 0xFFFFE0B2),
      StoryPage(text: 'Daniel heard about the rule. But he kept praying to God anyway! He was not going to stop.', emoji: '💪', backgroundColor: 0xFFE1BEE7),
      StoryPage(text: 'The mean men caught Daniel praying and told the king. The king was sad because he liked Daniel, but he had to follow the rule.', emoji: '😢', backgroundColor: 0xFFBBDEFB),
      StoryPage(text: 'Daniel was thrown into a dark den full of hungry lions! ROAR! The king said, "I hope your God saves you!"', emoji: '🦁', backgroundColor: 0xFFFFCCBC),
      StoryPage(text: 'God sent an angel who shut the lions\' mouths! The lions just lay down quietly. Daniel slept peacefully all night!', emoji: '😇', backgroundColor: 0xFFE8EAF6),
      StoryPage(text: 'In the morning, the king ran to the den. "Daniel! Are you okay?" Daniel said, "God sent His angel to protect me!" The king was so happy!', emoji: '🎉', backgroundColor: 0xFFC8E6C9),
    ],
  ),

  // ── 11. Jonah and the Big Fish ──
  IllustratedStory(
    title: 'Jonah and the Big Fish',
    emoji: '🐋',
    bibleReference: 'Jonah 1-4',
    color: 0xFF26A69A,
    moralLesson: 'We cannot run away from God. He loves us and wants us to do what is right.',
    pages: [
      StoryPage(text: 'God told Jonah, "Go to the big city of Nineveh and tell the people to be good." But Jonah did NOT want to go!', emoji: '🙅', backgroundColor: 0xFFFFF9C4),
      StoryPage(text: 'Jonah ran the other way! He jumped on a boat going far, far away. "God won\'t find me here," he thought.', emoji: '⛵', backgroundColor: 0xFFBBDEFB),
      StoryPage(text: 'But God sent a huge storm! The waves crashed and the boat rocked back and forth. The sailors were so scared!', emoji: '⛈️', backgroundColor: 0xFFE8EAF6),
      StoryPage(text: 'Jonah knew it was his fault. "Throw me in the sea and the storm will stop!" he said. Splash! Into the water he went!', emoji: '🌊', backgroundColor: 0xFFB3E5FC),
      StoryPage(text: 'A GIANT fish swallowed Jonah whole! He sat inside the fish\'s dark, stinky belly for three whole days!', emoji: '🐋', backgroundColor: 0xFFC8E6C9),
      StoryPage(text: 'Inside the fish, Jonah prayed, "I\'m sorry, God! I\'ll do what you asked!" And the fish spit him out onto the beach. Bleh!', emoji: '🙏', backgroundColor: 0xFFFFE0B2),
      StoryPage(text: 'This time, Jonah went to Nineveh like God asked. The people listened and said sorry to God. Everyone was saved! God was so happy!', emoji: '😊', backgroundColor: 0xFFF8BBD0),
    ],
  ),

  // ── 12. Ruth and Naomi ──
  IllustratedStory(
    title: 'Ruth and Naomi',
    emoji: '💕',
    bibleReference: 'Ruth 1-4',
    color: 0xFFEC407A,
    moralLesson: 'Being loyal and kind to others is always the right thing to do.',
    pages: [
      StoryPage(text: 'Naomi was a kind old woman who had lost her husband and her sons. She was very sad and all alone.', emoji: '😢', backgroundColor: 0xFFE8EAF6),
      StoryPage(text: 'Ruth was married to one of Naomi\'s sons. Even after he died, Ruth said, "I will stay with you, Naomi. I will never leave you!"', emoji: '🤝', backgroundColor: 0xFFF8BBD0),
      StoryPage(text: 'They walked together to Naomi\'s old home. They were very poor and had no food.', emoji: '🚶‍♀️', backgroundColor: 0xFFFFE0B2),
      StoryPage(text: 'Ruth worked hard picking up leftover grain in a farmer\'s field so they could eat. She never complained!', emoji: '🌾', backgroundColor: 0xFFFFF9C4),
      StoryPage(text: 'The farmer\'s name was Boaz. He saw how kind and hardworking Ruth was. He made sure she always had extra grain to take home.', emoji: '😊', backgroundColor: 0xFFC8E6C9),
      StoryPage(text: 'Boaz fell in love with Ruth because of her beautiful heart. They got married! Naomi was so happy she had a family again!', emoji: '💒', backgroundColor: 0xFFE1BEE7),
      StoryPage(text: 'Ruth and Boaz had a baby boy. This baby would grow up to be the great-grandpa of King David! God blessed Ruth\'s kindness in an amazing way!', emoji: '👶', backgroundColor: 0xFFF8BBD0),
    ],
  ),

  // ── 13. The Birth of Jesus ──
  IllustratedStory(
    title: 'The Birth of Jesus',
    emoji: '⭐',
    bibleReference: 'Luke 2',
    color: 0xFFFFB300,
    moralLesson: 'Jesus came as a tiny baby to show us how much God loves every single person.',
    pages: [
      StoryPage(text: 'An angel visited a young woman named Mary. "Don\'t be afraid! God has chosen you to be the mother of a very special baby. His name will be Jesus!"', emoji: '😇', backgroundColor: 0xFFE1BEE7),
      StoryPage(text: 'Mary and her husband Joseph had to travel to a town called Bethlehem. Mary rode on a donkey because the baby was coming soon!', emoji: '🫏', backgroundColor: 0xFFFFE0B2),
      StoryPage(text: 'When they got to Bethlehem, every inn was full. "No room! No room!" Finally, someone let them stay in a stable with the animals.', emoji: '🏨', backgroundColor: 0xFFBBDEFB),
      StoryPage(text: 'That night, baby Jesus was born! Mary wrapped him in soft cloths and laid him in a manger - a feeding box for animals. The animals kept him warm.', emoji: '👶', backgroundColor: 0xFFFFF9C4),
      StoryPage(text: 'On a hillside nearby, shepherds were watching their sheep. Suddenly, the sky lit up with angels singing, "Glory to God! A Savior is born!"', emoji: '🎶', backgroundColor: 0xFFE8EAF6),
      StoryPage(text: 'The shepherds ran to Bethlehem and found baby Jesus, just like the angels said! They knelt down and worshipped him.', emoji: '🐑', backgroundColor: 0xFFC8E6C9),
      StoryPage(text: 'A bright star shone in the sky. Wise men followed it from far away and brought gifts of gold, frankincense, and myrrh for the baby king!', emoji: '⭐', backgroundColor: 0xFFFFF9C4),
    ],
  ),

  // ── 14. Jesus Feeds 5000 People ──
  IllustratedStory(
    title: 'Jesus Feeds 5000',
    emoji: '🍞',
    bibleReference: 'John 6:1-14',
    color: 0xFF8D6E63,
    moralLesson: 'When we share what little we have, God can do amazing things with it.',
    pages: [
      StoryPage(text: 'Thousands and thousands of people followed Jesus to hear him teach. They stayed all day and got very hungry!', emoji: '👥', backgroundColor: 0xFFFFE0B2),
      StoryPage(text: 'The disciples said, "Jesus, there are over 5,000 people here! We don\'t have enough food or money to feed them all!"', emoji: '😟', backgroundColor: 0xFFBBDEFB),
      StoryPage(text: 'A little boy stepped forward. "I have five small loaves of bread and two fish! You can have my lunch!"', emoji: '👦', backgroundColor: 0xFFC8E6C9),
      StoryPage(text: 'Jesus smiled and said, "Thank you!" He took the bread and fish, looked up to heaven, and thanked God for the food.', emoji: '🙏', backgroundColor: 0xFFFFF9C4),
      StoryPage(text: 'Then something amazing happened! Jesus broke the bread and kept breaking it. It never ran out! More and more food appeared!', emoji: '🍞', backgroundColor: 0xFFFFE0B2),
      StoryPage(text: 'Everyone ate until they were completely full. Five loaves and two fish fed over 5,000 people! And there were twelve baskets of leftovers!', emoji: '🧺', backgroundColor: 0xFFF8BBD0),
    ],
  ),

  // ── 15. The Good Samaritan ──
  IllustratedStory(
    title: 'The Good Samaritan',
    emoji: '🩹',
    bibleReference: 'Luke 10:25-37',
    color: 0xFF66BB6A,
    moralLesson: 'Be kind to everyone, even people who are different from you. Everyone is your neighbor.',
    pages: [
      StoryPage(text: 'Someone asked Jesus, "Who is my neighbor?" Jesus told this story to teach an important lesson.', emoji: '🤔', backgroundColor: 0xFFFFF9C4),
      StoryPage(text: 'A man was walking down a road when robbers attacked him! They took his things and hurt him badly. He lay on the road, crying for help.', emoji: '😢', backgroundColor: 0xFFFFCDD2),
      StoryPage(text: 'A priest walked by and saw the hurt man. But he crossed to the other side of the road and kept walking!', emoji: '🚶', backgroundColor: 0xFFE8EAF6),
      StoryPage(text: 'Another religious man came by. He also looked at the hurt man, but walked away too! Nobody would help!', emoji: '😔', backgroundColor: 0xFFBBDEFB),
      StoryPage(text: 'Then a Samaritan came. Most people didn\'t like Samaritans. But this man stopped! He cleaned the man\'s cuts and bandaged them carefully.', emoji: '🩹', backgroundColor: 0xFFC8E6C9),
      StoryPage(text: 'He put the hurt man on his donkey, took him to an inn, and paid for his room. "Take care of him," he said. "I\'ll pay for everything!"', emoji: '💕', backgroundColor: 0xFFE1BEE7),
      StoryPage(text: 'Jesus asked, "Which one was a good neighbor?" The answer was clear - the one who showed kindness! Jesus said, "Go and do the same."', emoji: '❤️', backgroundColor: 0xFFF8BBD0),
    ],
  ),

  // ── 16. Jesus Walks on Water ──
  IllustratedStory(
    title: 'Jesus Walks on Water',
    emoji: '🌊',
    bibleReference: 'Matthew 14:22-33',
    color: 0xFF29B6F6,
    moralLesson: 'When we keep our eyes on Jesus and trust Him, we can do things we never thought possible.',
    pages: [
      StoryPage(text: 'Jesus told his friends to get in a boat and go across the lake. "I\'ll catch up later," he said. Then he went up a mountain to pray.', emoji: '🙏', backgroundColor: 0xFFE1BEE7),
      StoryPage(text: 'Late at night, a big storm came! The wind was howling and the waves were crashing against the boat. The disciples were scared!', emoji: '⛈️', backgroundColor: 0xFFBBDEFB),
      StoryPage(text: 'Then they saw something on the water. Someone was WALKING on the waves! "It\'s a ghost!" they screamed!', emoji: '😱', backgroundColor: 0xFFE8EAF6),
      StoryPage(text: 'But it was Jesus! "Don\'t be afraid! It\'s me!" he called out. Peter said, "Lord, if it\'s really you, let me walk on the water too!"', emoji: '😮', backgroundColor: 0xFFFFF9C4),
      StoryPage(text: 'Jesus said, "Come!" Peter stepped out of the boat and started walking on the water toward Jesus! He was actually doing it!', emoji: '🚶', backgroundColor: 0xFFB3E5FC),
      StoryPage(text: 'But when Peter looked at the scary waves, he got scared and started sinking! "Help me, Jesus!" he cried.', emoji: '😰', backgroundColor: 0xFFFFCDD2),
      StoryPage(text: 'Jesus grabbed Peter\'s hand right away. "Why did you doubt?" When they got in the boat, the storm stopped completely. Everyone worshipped Jesus!', emoji: '✨', backgroundColor: 0xFFF8BBD0),
    ],
  ),

  // ── 17. Jesus and the Children ──
  IllustratedStory(
    title: 'Jesus and the Children',
    emoji: '👧',
    bibleReference: 'Mark 10:13-16',
    color: 0xFFEC407A,
    moralLesson: 'Jesus loves children and thinks they are very important. You are special to Him!',
    pages: [
      StoryPage(text: 'One day, moms and dads brought their children to see Jesus. They wanted Jesus to bless their kids!', emoji: '👨‍👩‍👧‍👦', backgroundColor: 0xFFF8BBD0),
      StoryPage(text: 'But Jesus\'s disciples said, "Go away! Jesus is too busy and too important to play with kids!"', emoji: '🙅', backgroundColor: 0xFFFFCDD2),
      StoryPage(text: 'When Jesus heard this, he was not happy at all! "Don\'t stop the children from coming to me!" he said.', emoji: '😤', backgroundColor: 0xFFFFF9C4),
      StoryPage(text: 'Jesus opened his arms wide and the children ran to him! He hugged them, held them, and laughed with them.', emoji: '🤗', backgroundColor: 0xFFC8E6C9),
      StoryPage(text: 'Jesus said something beautiful: "God\'s kingdom belongs to people who have faith like little children."', emoji: '💝', backgroundColor: 0xFFE1BEE7),
      StoryPage(text: 'He put his hands on each child and blessed them one by one. Jesus showed everyone that kids are super important to God!', emoji: '⭐', backgroundColor: 0xFFFFF9C4),
    ],
  ),

  // ── 18. Zacchaeus ──
  IllustratedStory(
    title: 'Zacchaeus the Tax Collector',
    emoji: '🌳',
    bibleReference: 'Luke 19:1-10',
    color: 0xFF66BB6A,
    moralLesson: 'No matter what you have done wrong, Jesus loves you and you can always start fresh.',
    pages: [
      StoryPage(text: 'Zacchaeus was a very short man who collected taxes. He took too much money from people, so nobody liked him.', emoji: '💰', backgroundColor: 0xFFFFE0B2),
      StoryPage(text: 'One day, Jesus was coming to town! Zacchaeus wanted to see him, but he was too short to see over the crowd.', emoji: '👀', backgroundColor: 0xFFFFF9C4),
      StoryPage(text: 'So Zacchaeus ran ahead and climbed up a big sycamore tree! From up there, he could see everything!', emoji: '🌳', backgroundColor: 0xFFC8E6C9),
      StoryPage(text: 'When Jesus walked by, he looked up and said, "Zacchaeus, come down! I want to come to YOUR house today!"', emoji: '😃', backgroundColor: 0xFFBBDEFB),
      StoryPage(text: 'Zacchaeus was so happy! He slid down the tree and took Jesus to his house. People grumbled, "Why is Jesus visiting HIM?"', emoji: '🏠', backgroundColor: 0xFFE1BEE7),
      StoryPage(text: 'Meeting Jesus changed Zacchaeus\'s heart. "I will give half my money to the poor! And I will pay back everyone four times what I stole!"', emoji: '❤️', backgroundColor: 0xFFF8BBD0),
      StoryPage(text: 'Jesus smiled and said, "Today you are saved! I came to find and rescue people who are lost." Zacchaeus became a completely new person!', emoji: '🎉', backgroundColor: 0xFFFFF9C4),
    ],
  ),

  // ── 19. The Prodigal Son ──
  IllustratedStory(
    title: 'The Prodigal Son',
    emoji: '🏠',
    bibleReference: 'Luke 15:11-32',
    color: 0xFF7E57C2,
    moralLesson: 'No matter how far you wander, God is always waiting with open arms to welcome you home.',
    pages: [
      StoryPage(text: 'A father had two sons. The younger son said, "Dad, give me my share of money now!" So the father gave it to him.', emoji: '💰', backgroundColor: 0xFFFFF9C4),
      StoryPage(text: 'The young man went far away and spent all his money on silly things. Parties, fancy clothes, and bad choices!', emoji: '🎊', backgroundColor: 0xFFFFE0B2),
      StoryPage(text: 'Soon all his money was gone. A famine came and he had nothing to eat. He got a job feeding pigs and was so hungry he wanted to eat PIG FOOD!', emoji: '🐷', backgroundColor: 0xFFE8EAF6),
      StoryPage(text: 'Sitting with the pigs, he thought, "Even my dad\'s servants eat better than this! I\'ll go home and say sorry."', emoji: '💭', backgroundColor: 0xFFBBDEFB),
      StoryPage(text: 'He started walking home, scared and ashamed. But his father saw him from far away and RAN to meet him!', emoji: '🏃', backgroundColor: 0xFFC8E6C9),
      StoryPage(text: 'The father hugged and kissed his son. "I\'m so sorry, Dad!" the boy cried. But his father said, "My son was lost, and now he\'s found!"', emoji: '🤗', backgroundColor: 0xFFF8BBD0),
      StoryPage(text: 'The father threw a big party with music and dancing! He gave his son new clothes and a ring. That\'s how much God loves us when we come back to Him!', emoji: '🎉', backgroundColor: 0xFFE1BEE7),
    ],
  ),

  // ── 20. Jesus Rises from the Dead ──
  IllustratedStory(
    title: 'Jesus Rises!',
    emoji: '✝️',
    bibleReference: 'Matthew 28',
    color: 0xFFFFD54F,
    moralLesson: 'Jesus is alive forever! Because of Him, we have hope and life that never ends.',
    pages: [
      StoryPage(text: 'Some people did not like Jesus. They arrested him and nailed him to a cross. Jesus died on a Friday. His friends were very, very sad.', emoji: '😢', backgroundColor: 0xFFE8EAF6),
      StoryPage(text: 'They put Jesus\'s body in a tomb carved out of rock and rolled a huge stone in front of the door.', emoji: '🪨', backgroundColor: 0xFFBBDEFB),
      StoryPage(text: 'On Sunday morning, some women went to visit the tomb. But when they got there, the big stone was rolled away!', emoji: '😲', backgroundColor: 0xFFFFF9C4),
      StoryPage(text: 'An angel in shining white clothes was sitting there! "Don\'t be afraid!" the angel said. "Jesus is not here. He has risen! He is alive!"', emoji: '😇', backgroundColor: 0xFFE1BEE7),
      StoryPage(text: 'The women ran to tell the disciples. "Jesus is alive! We saw the empty tomb!" Their hearts were bursting with joy!', emoji: '🏃‍♀️', backgroundColor: 0xFFFFE0B2),
      StoryPage(text: 'Then Jesus himself appeared to his friends! "Peace be with you!" They could hardly believe their eyes. They touched his hands. It was really Him!', emoji: '✨', backgroundColor: 0xFFC8E6C9),
      StoryPage(text: 'Jesus said, "Go and tell everyone the good news! I am with you always, forever and ever." And He is still with us today!', emoji: '❤️', backgroundColor: 0xFFF8BBD0),
    ],
  ),
];
