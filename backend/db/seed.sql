-- Seed Data for Our Bible App
-- Admin user password: OurBible2024! (bcrypt hash generated at startup)
-- The admin user is inserted programmatically in server.js to use proper bcrypt hashing.

-- ============================================================
-- HYMNS (10 classic public domain hymns)
-- ============================================================

INSERT OR IGNORE INTO hymns (number, title, author, year, lyrics, category, source) VALUES
(1, 'Amazing Grace', 'John Newton', 1772,
'Amazing grace! How sweet the sound
That saved a wretch like me!
I once was lost, but now am found;
Was blind, but now I see.

''Twas grace that taught my heart to fear,
And grace my fears relieved;
How precious did that grace appear
The hour I first believed.

Through many dangers, toils, and snares,
I have already come;
''Tis grace hath brought me safe thus far,
And grace will lead me home.',
'grace', 'public_domain');

INSERT OR IGNORE INTO hymns (number, title, author, year, lyrics, category, source) VALUES
(2, 'How Great Thou Art', 'Carl Boberg', 1885,
'O Lord my God, when I in awesome wonder
Consider all the worlds Thy hands have made,
I see the stars, I hear the rolling thunder,
Thy power throughout the universe displayed.

Then sings my soul, my Saviour God, to Thee:
How great Thou art! How great Thou art!
Then sings my soul, my Saviour God, to Thee:
How great Thou art! How great Thou art!

When through the woods and forest glades I wander
And hear the birds sing sweetly in the trees,
When I look down from lofty mountain grandeur
And hear the brook and feel the gentle breeze.',
'praise', 'public_domain');

INSERT OR IGNORE INTO hymns (number, title, author, year, lyrics, category, source) VALUES
(3, 'It Is Well With My Soul', 'Horatio Spafford', 1873,
'When peace, like a river, attendeth my way,
When sorrows like sea billows roll;
Whatever my lot, Thou hast taught me to say,
It is well, it is well with my soul.

It is well with my soul,
It is well, it is well with my soul.

Though Satan should buffet, though trials should come,
Let this blest assurance control,
That Christ hath regarded my helpless estate,
And hath shed His own blood for my soul.

My sin, oh the bliss of this glorious thought!
My sin, not in part but the whole,
Is nailed to the cross, and I bear it no more,
Praise the Lord, praise the Lord, O my soul!',
'assurance', 'public_domain');

INSERT OR IGNORE INTO hymns (number, title, author, year, lyrics, category, source) VALUES
(4, 'Great Is Thy Faithfulness', 'Thomas Chisholm', 1923,
'Great is Thy faithfulness, O God my Father;
There is no shadow of turning with Thee;
Thou changest not, Thy compassions, they fail not;
As Thou hast been, Thou forever wilt be.

Great is Thy faithfulness!
Great is Thy faithfulness!
Morning by morning new mercies I see;
All I have needed Thy hand hath provided;
Great is Thy faithfulness, Lord, unto me!

Summer and winter and springtime and harvest,
Sun, moon, and stars in their courses above
Join with all nature in manifold witness
To Thy great faithfulness, mercy, and love.',
'faithfulness', 'public_domain');

INSERT OR IGNORE INTO hymns (number, title, author, year, lyrics, category, source) VALUES
(5, 'Blessed Assurance', 'Fanny Crosby', 1873,
'Blessed assurance, Jesus is mine!
Oh, what a foretaste of glory divine!
Heir of salvation, purchase of God,
Born of His Spirit, washed in His blood.

This is my story, this is my song,
Praising my Savior all the day long;
This is my story, this is my song,
Praising my Savior all the day long.

Perfect submission, perfect delight,
Visions of rapture now burst on my sight;
Angels descending bring from above
Echoes of mercy, whispers of love.',
'assurance', 'public_domain');

INSERT OR IGNORE INTO hymns (number, title, author, year, lyrics, category, source) VALUES
(6, 'Holy Holy Holy', 'Reginald Heber', 1826,
'Holy, holy, holy! Lord God Almighty!
Early in the morning our song shall rise to Thee;
Holy, holy, holy, merciful and mighty!
God in three Persons, blessed Trinity!

Holy, holy, holy! All the saints adore Thee,
Casting down their golden crowns around the glassy sea;
Cherubim and seraphim falling down before Thee,
Who wert, and art, and evermore shalt be.

Holy, holy, holy! Though the darkness hide Thee,
Though the eye of sinful man Thy glory may not see;
Only Thou art holy; there is none beside Thee,
Perfect in power, in love, and purity.',
'worship', 'public_domain');

INSERT OR IGNORE INTO hymns (number, title, author, year, lyrics, category, source) VALUES
(7, 'Rock of Ages', 'Augustus Toplady', 1763,
'Rock of Ages, cleft for me,
Let me hide myself in Thee;
Let the water and the blood,
From Thy wounded side which flowed,
Be of sin the double cure;
Save from wrath and make me pure.

Not the labors of my hands
Can fulfill Thy law''s demands;
Could my zeal no respite know,
Could my tears forever flow,
All for sin could not atone;
Thou must save, and Thou alone.

Nothing in my hand I bring,
Simply to the cross I cling;
Naked, come to Thee for dress;
Helpless, look to Thee for grace;
Foul, I to the fountain fly;
Wash me, Savior, or I die.',
'redemption', 'public_domain');

INSERT OR IGNORE INTO hymns (number, title, author, year, lyrics, category, source) VALUES
(8, 'Abide With Me', 'Henry Lyte', 1847,
'Abide with me; fast falls the eventide;
The darkness deepens; Lord, with me abide.
When other helpers fail and comforts flee,
Help of the helpless, O abide with me.

Swift to its close ebbs out life''s little day;
Earth''s joys grow dim; its glories pass away;
Change and decay in all around I see;
O Thou who changest not, abide with me.

I need Thy presence every passing hour.
What but Thy grace can foil the tempter''s power?
Who, like Thyself, my guide and stay can be?
Through cloud and sunshine, Lord, abide with me.',
'comfort', 'public_domain');

INSERT OR IGNORE INTO hymns (number, title, author, year, lyrics, category, source) VALUES
(9, 'What A Friend We Have In Jesus', 'Joseph Scriven', 1855,
'What a friend we have in Jesus,
All our sins and griefs to bear!
What a privilege to carry
Everything to God in prayer!
Oh, what peace we often forfeit,
Oh, what needless pain we bear,
All because we do not carry
Everything to God in prayer!

Have we trials and temptations?
Is there trouble anywhere?
We should never be discouraged;
Take it to the Lord in prayer!
Can we find a friend so faithful,
Who will all our sorrows share?
Jesus knows our every weakness;
Take it to the Lord in prayer!

Are we weak and heavy-laden,
Cumbered with a load of care?
Precious Savior, still our refuge;
Take it to the Lord in prayer!
Do thy friends despise, forsake thee?
Take it to the Lord in prayer!
In His arms He''ll take and shield thee;
Thou wilt find a solace there.',
'prayer', 'public_domain');

INSERT OR IGNORE INTO hymns (number, title, author, year, lyrics, category, source) VALUES
(10, 'Be Thou My Vision', 'Irish hymn (translated by Mary Byrne)', 800,
'Be Thou my Vision, O Lord of my heart;
Naught be all else to me, save that Thou art;
Thou my best thought, by day or by night,
Waking or sleeping, Thy presence my light.

Be Thou my Wisdom, and Thou my true Word;
I ever with Thee and Thou with me, Lord;
Thou my great Father, and I Thy true son;
Thou in me dwelling, and I with Thee one.

Riches I heed not, nor man''s empty praise,
Thou mine inheritance, now and always;
Thou and Thou only, first in my heart,
High King of heaven, my treasure Thou art.',
'devotion', 'public_domain');

-- ============================================================
-- STUDY MATERIALS - Open Heavens format (3 entries)
-- ============================================================

INSERT OR IGNORE INTO study_materials (title, author, source, category, date, bible_reading, memory_verse, content) VALUES
('Walking in the Light', 'Pastor E.A. Adeboye', 'Open Heavens', 'open_heavens', '2024-01-15',
'John 8:12-20', 'John 8:12 - Then spake Jesus again unto them, saying, I am the light of the world: he that followeth me shall not walk in darkness, but shall have the light of life.',
'In today''s reading, Jesus declares Himself the light of the world. This profound statement carries deep significance for every believer. When we walk in His light, we are guided away from the pitfalls of sin and darkness. The light of Christ illuminates our path, reveals hidden dangers, and gives us clarity of purpose. As children of God, we must choose daily to walk in this light by studying His Word, praying without ceasing, and living in obedience to His commands. Let us not be like those who prefer darkness because their deeds are evil, but rather let us embrace the light and let it shine through us to others.

Prayer Point: Father, help me to walk in Your light today and always. Let my life reflect Your glory to everyone around me.

Action Point: Identify one area of your life where you have been walking in darkness, and deliberately bring it into God''s light today through prayer and confession.');

INSERT OR IGNORE INTO study_materials (title, author, source, category, date, bible_reading, memory_verse, content) VALUES
('The Power of Faith', 'Pastor E.A. Adeboye', 'Open Heavens', 'open_heavens', '2024-01-16',
'Hebrews 11:1-6', 'Hebrews 11:6 - But without faith it is impossible to please him: for he that cometh to God must believe that he is, and that he is a rewarder of them that diligently seek him.',
'Faith is the currency of the Kingdom of God. Without it, we cannot please our Heavenly Father. In today''s Bible reading, the author of Hebrews lays out the foundation of faith: it is the substance of things hoped for and the evidence of things not seen. Faith is not wishful thinking or mere optimism; it is a deep-rooted confidence in the character and promises of God. The heroes of faith listed in Hebrews 11 did not achieve great things because they were extraordinary people, but because they served an extraordinary God and took Him at His Word.

Prayer Point: Lord, increase my faith. Help me to trust You completely, even when I cannot see the way forward.

Action Point: Write down three promises of God that you are standing on in this season, and declare them aloud each morning this week.');

INSERT OR IGNORE INTO study_materials (title, author, source, category, date, bible_reading, memory_verse, content) VALUES
('Grace for Every Season', 'Pastor E.A. Adeboye', 'Open Heavens', 'open_heavens', '2024-01-17',
'2 Corinthians 12:7-10', '2 Corinthians 12:9 - And he said unto me, My grace is sufficient for thee: for my strength is made perfect in weakness.',
'God''s grace is sufficient for every season of life. Whether we find ourselves in a season of abundance or a season of scarcity, in joy or in sorrow, God''s grace is always enough. Paul learned this lesson through his thorn in the flesh. Rather than removing the thorn, God gave Paul something greater: His grace. This teaches us that God does not always change our circumstances, but He always provides the grace to endure and overcome them. His strength is perfected in our weakness, which means our limitations become opportunities for God''s power to be displayed.

Prayer Point: Father, thank You for Your sufficient grace. Help me to rest in Your grace today, knowing that Your strength is made perfect in my weakness.

Action Point: Instead of complaining about a current difficulty, thank God for it and ask Him to reveal His grace and power through it.');

-- ============================================================
-- STUDY MATERIALS - Search the Scriptures format (3 entries)
-- ============================================================

INSERT OR IGNORE INTO study_materials (title, author, source, category, date, bible_reading, memory_verse, content) VALUES
('The Beginning of Wisdom', 'Scripture Union', 'Search the Scriptures', 'search_the_scriptures', '2024-01-15',
'Proverbs 1:1-19', 'Proverbs 1:7 - The fear of the LORD is the beginning of knowledge: but fools despise wisdom and instruction.',
'The book of Proverbs opens with a clear declaration of its purpose: to impart wisdom, instruction, and understanding. Solomon, the wisest man who ever lived, writes these proverbs not to show off his wisdom but to share it with future generations. The key verse establishes the foundation of all true knowledge: the fear of the Lord. This fear is not terror but a profound reverence and respect for God that shapes every decision and action.

Study Questions:
1. What are the stated purposes of the Proverbs according to verses 1-6?
2. What does it mean to fear the Lord in practical daily living?
3. How does the warning against sinful enticement in verses 10-19 apply to modern life?

Further Study: Compare Proverbs 1:7 with Proverbs 9:10 and Psalm 111:10. What common thread do you see?');

INSERT OR IGNORE INTO study_materials (title, author, source, category, date, bible_reading, memory_verse, content) VALUES
('God''s Covenant with Abraham', 'Scripture Union', 'Search the Scriptures', 'search_the_scriptures', '2024-01-16',
'Genesis 15:1-21', 'Genesis 15:6 - And he believed in the LORD; and he counted it to him for righteousness.',
'In this pivotal chapter, God makes a formal covenant with Abraham. Despite Abraham''s concerns about having no heir, God reassures him with a breathtaking promise: his descendants will be as numerous as the stars. Abraham''s response is one of the most significant moments in all of Scripture: he believed God, and it was credited to him as righteousness. This principle of justification by faith would later become the cornerstone of Christian theology, as Paul expounds in Romans 4 and Galatians 3.

Study Questions:
1. What was Abraham''s concern, and how did God address it?
2. What is the significance of God''s covenant ceremony in verses 9-17?
3. How does Abraham''s faith foreshadow the New Testament doctrine of justification by faith?

Further Study: Read Romans 4:1-12 and trace how Paul uses Abraham''s example to explain salvation by faith.');

INSERT OR IGNORE INTO study_materials (title, author, source, category, date, bible_reading, memory_verse, content) VALUES
('The Sermon on the Mount: The Beatitudes', 'Scripture Union', 'Search the Scriptures', 'search_the_scriptures', '2024-01-17',
'Matthew 5:1-16', 'Matthew 5:16 - Let your light so shine before men, that they may see your good works, and glorify your Father which is in heaven.',
'Jesus begins His most famous sermon with the Beatitudes, a series of blessings that turn worldly values upside down. In the Kingdom of God, the poor in spirit are blessed, the meek inherit the earth, and those who mourn find comfort. These statements would have shocked Jesus''s audience, who expected the Messiah to establish an earthly kingdom of power and prestige. Instead, Jesus reveals a kingdom built on humility, mercy, purity of heart, and peacemaking.

Study Questions:
1. List each Beatitude and its corresponding blessing. Which one challenges you the most?
2. What does it mean to be ''poor in spirit'' and why is this the first Beatitude?
3. How do verses 13-16 connect the character described in the Beatitudes to the believer''s mission in the world?

Further Study: Compare the Beatitudes in Matthew 5 with Luke 6:20-26. Note the differences and consider why Luke includes corresponding woes.');
