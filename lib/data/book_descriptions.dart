/// Beginner-friendly descriptions for all 66 books of the Bible.
const kBookDescriptions = <String, String>{
  // ── Old Testament ──
  'Genesis':
      'The book of beginnings \u2014 creation, the first humans, Noah\'s flood, and the stories of Abraham, Isaac, Jacob, and Joseph.',
  'Exodus':
      'God frees His people from slavery in Egypt through Moses, parts the Red Sea, and gives the Ten Commandments.',
  'Leviticus':
      'Laws and instructions God gave Israel for worship, sacrifices, and daily living.',
  'Numbers':
      'Israel\'s 40-year journey through the wilderness, full of struggles, miracles, and lessons in trusting God.',
  'Deuteronomy':
      'Moses\' farewell speeches to Israel before they enter the Promised Land \u2014 a reminder to love and obey God.',
  'Joshua':
      'Israel finally enters the Promised Land under Joshua\'s leadership, conquering cities and settling the tribes.',
  'Judges':
      'A cycle of Israel turning from God, falling into trouble, and being rescued by heroes like Gideon, Deborah, and Samson.',
  'Ruth':
      'A beautiful love story of loyalty and redemption \u2014 Ruth stays faithful to her mother-in-law and finds a new home.',
  '1 Samuel':
      'Israel asks for a king. Samuel anoints Saul, then David \u2014 the shepherd boy who defeats Goliath.',
  '2 Samuel':
      'David becomes king of Israel. His reign brings both great victories and painful consequences.',
  '1 Kings':
      'Solomon builds the Temple, but the kingdom splits in two after his death. Elijah the prophet stands for God.',
  '2 Kings':
      'The two kingdoms decline as most kings reject God. Israel and then Judah are conquered and sent into exile.',
  '1 Chronicles':
      'A retelling of Israel\'s history focused on David\'s reign and his passion for worshipping God.',
  '2 Chronicles':
      'The history of Judah\'s kings from Solomon to the exile, highlighting those who followed God and those who didn\'t.',
  'Ezra':
      'The Jewish people return from exile to rebuild the Temple in Jerusalem and renew their commitment to God.',
  'Nehemiah':
      'Nehemiah leads the effort to rebuild Jerusalem\'s walls and restore the community\'s faith.',
  'Esther':
      'A brave Jewish queen risks her life to save her people from a deadly plot \u2014 God works behind the scenes.',
  'Job':
      'A righteous man suffers terrible losses and wrestles with the big question: why do good people suffer?',
  'Psalms':
      'A collection of 150 songs and prayers covering every human emotion \u2014 praise, grief, anger, joy, and hope.',
  'Proverbs':
      'Practical wisdom for everyday life \u2014 short, memorable sayings about relationships, work, money, and character.',
  'Ecclesiastes':
      'A wise man searches for the meaning of life and concludes that true purpose is found in God alone.',
  'Song of Solomon':
      'A poetic celebration of love between a bride and groom, often seen as a picture of God\'s love for His people.',
  'Isaiah':
      'A major prophet warns Israel of judgment but also shares beautiful promises of a coming Savior and future hope.',
  'Jeremiah':
      'Known as the "weeping prophet," Jeremiah pleads with Judah to turn back to God before it\'s too late.',
  'Lamentations':
      'Heartbroken poems mourning the destruction of Jerusalem, yet still holding on to God\'s faithfulness.',
  'Ezekiel':
      'Dramatic visions and symbolic acts from a prophet in exile, pointing to God\'s glory and future restoration.',
  'Daniel':
      'A young man stays faithful to God in a foreign empire \u2014 surviving a lion\'s den and interpreting dreams.',
  'Hosea':
      'God uses Hosea\'s marriage to an unfaithful wife to show how deeply He loves His wandering people.',
  'Joel':
      'A prophet calls the people to repent after a devastating plague, promising God will pour out His Spirit.',
  'Amos':
      'A shepherd turned prophet confronts Israel\'s injustice and warns that God cares about how we treat others.',
  'Obadiah':
      'The shortest Old Testament book \u2014 a warning to the nation of Edom for mistreating Israel.',
  'Jonah':
      'A prophet runs from God, gets swallowed by a great fish, and learns that God\'s mercy extends to everyone.',
  'Micah':
      'A prophet calls for justice, mercy, and humility, and predicts the Messiah will be born in Bethlehem.',
  'Nahum':
      'A prophecy about the fall of Nineveh, showing that God will bring justice against cruelty and oppression.',
  'Habakkuk':
      'A prophet honestly questions God about suffering and injustice, and learns to trust God\'s bigger plan.',
  'Zephaniah':
      'A warning of coming judgment mixed with a beautiful promise that God rejoices over His people with singing.',
  'Haggai':
      'A short, urgent call to the people to stop neglecting God\'s Temple and put Him first again.',
  'Zechariah':
      'Visions of hope and prophecies about the coming Messiah, encouraging the people rebuilding the Temple.',
  'Malachi':
      'The last Old Testament prophet challenges the people\'s half-hearted worship and points to a messenger who will come.',

  // ── New Testament ──
  'Matthew':
      'Tells the story of Jesus as the promised King, including His birth, teachings, miracles, death, and resurrection.',
  'Mark':
      'A fast-paced account of Jesus\' life focused on His actions \u2014 miracles, healings, and ultimate sacrifice.',
  'Luke':
      'A detailed, orderly account of Jesus\' life with special attention to outcasts, women, and the poor.',
  'John':
      'A deeply personal account of Jesus as the Son of God, filled with conversations, miracles, and the meaning of belief.',
  'Acts':
      'The exciting story of the early church after Jesus ascends \u2014 the Holy Spirit comes, and the gospel spreads worldwide.',
  'Romans':
      'Paul\'s masterpiece explaining how everyone can be made right with God through faith in Jesus.',
  '1 Corinthians':
      'Paul addresses problems in the Corinthian church \u2014 divisions, love, spiritual gifts, and the resurrection.',
  '2 Corinthians':
      'Paul defends his ministry and shares how God\'s power is made perfect in our weakness.',
  'Galatians':
      'Paul passionately argues that we are saved by faith in Jesus, not by following rules.',
  'Ephesians':
      'A letter about the church as one body in Christ \u2014 our identity, unity, and how to live as God\'s family.',
  'Philippians':
      'A joyful letter from prison encouraging believers to find happiness in Jesus no matter the circumstances.',
  'Colossians':
      'Paul reminds believers that Jesus is supreme over everything and is all we need.',
  '1 Thessalonians':
      'Paul encourages a young church to keep growing in faith and gives hope about Jesus\' return.',
  '2 Thessalonians':
      'Paul clears up confusion about Jesus\' return and encourages the church to stay faithful and hardworking.',
  '1 Timothy':
      'Paul gives his young protege Timothy practical advice on leading the church and living with integrity.',
  '2 Timothy':
      'Paul\'s final letter, written from prison, urging Timothy to stay strong and guard the truth of the gospel.',
  'Titus':
      'Instructions for Titus on organizing churches and living a life that reflects the gospel.',
  'Philemon':
      'A short, personal letter asking Philemon to forgive and welcome back his runaway servant as a brother in Christ.',
  'Hebrews':
      'Shows how Jesus is greater than everything in the old system \u2014 greater than angels, Moses, and the old sacrifices.',
  'James':
      'Practical wisdom on living out your faith \u2014 controlling your tongue, helping the poor, and persevering.',
  '1 Peter':
      'Encouragement for suffering Christians to stand firm, remembering that Jesus also suffered for us.',
  '2 Peter':
      'A warning against false teachers and a reminder to grow in knowing God while waiting for Jesus\' return.',
  '1 John':
      'A warm letter about love, light, and confidence \u2014 how to know you truly belong to God.',
  '2 John':
      'A brief letter urging believers to walk in truth and love while watching out for deceivers.',
  '3 John':
      'A short note praising faithful hospitality and warning against a church leader who loves being in charge.',
  'Jude':
      'An urgent call to defend the faith against people who twist God\'s grace into an excuse for sin.',
  'Revelation':
      'A dramatic vision of the end times \u2014 the ultimate victory of Jesus, the defeat of evil, and a new heaven and earth.',
};
