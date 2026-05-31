insert into public.word_boards (slug, category, board_data) values
('fruits', 'Fruits', '{
  "A1":"Apple","A2":"Banana","A3":"Orange","A4":"Mango","A5":"Strawberry","A6":"Watermelon",
  "B1":"Pineapple","B2":"Grape","B3":"Pear","B4":"Peach","B5":"Cherry","B6":"Kiwi",
  "C1":"Papaya","C2":"Dragon Fruit","C3":"Durian","C4":"Lychee","C5":"Coconut","C6":"Lemon",
  "D1":"Lime","D2":"Blueberry","D3":"Raspberry","D4":"Avocado","D5":"Guava","D6":"Pomegranate",
  "E1":"Passion Fruit","E2":"Jackfruit","E3":"Plum","E4":"Apricot","E5":"Fig","E6":"Melon"
}'::jsonb),
('landmarks', 'Famous Landmarks', '{
  "A1":"Statue of Liberty","A2":"Eiffel Tower","A3":"Sydney Opera House","A4":"Colosseum","A5":"Great Wall of China","A6":"Taj Mahal",
  "B1":"Big Ben","B2":"Golden Gate Bridge","B3":"Machu Picchu","B4":"Pyramids of Giza","B5":"Mount Rushmore","B6":"Leaning Tower of Pisa",
  "C1":"Christ the Redeemer","C2":"Burj Khalifa","C3":"Angkor Wat","C4":"Stonehenge","C5":"Petra","C6":"Sagrada Familia",
  "D1":"Marina Bay Sands","D2":"Merlion","D3":"Gardens by the Bay","D4":"Niagara Falls","D5":"Grand Canyon","D6":"Mount Fuji",
  "E1":"Hollywood Sign","E2":"Empire State Building","E3":"Acropolis","E4":"Louvre Museum","E5":"Brandenburg Gate","E6":"Chichen Itza"
}'::jsonb),
('feelings', 'Feelings', '{
  "A1":"Happy","A2":"Sad","A3":"Angry","A4":"Excited","A5":"Nervous","A6":"Surprised",
  "B1":"Confused","B2":"Proud","B3":"Embarrassed","B4":"Jealous","B5":"Calm","B6":"Bored",
  "C1":"Scared","C2":"Grateful","C3":"Lonely","C4":"Hopeful","C5":"Curious","C6":"Frustrated",
  "D1":"Relaxed","D2":"Guilty","D3":"Shy","D4":"Disappointed","D5":"Relieved","D6":"Impatient",
  "E1":"Loved","E2":"Sleepy","E3":"Silly","E4":"Worried","E5":"Annoyed","E6":"Confident"
}'::jsonb),
('hobbies', 'Hobbies', '{
  "A1":"Reading","A2":"Cooking","A3":"Gardening","A4":"Painting","A5":"Photography","A6":"Gaming",
  "B1":"Hiking","B2":"Cycling","B3":"Swimming","B4":"Fishing","B5":"Baking","B6":"Knitting",
  "C1":"Dancing","C2":"Singing","C3":"Drawing","C4":"Writing","C5":"Camping","C6":"Yoga",
  "D1":"Running","D2":"Pottery","D3":"Chess","D4":"Skateboarding","D5":"Origami","D6":"Collecting",
  "E1":"Woodworking","E2":"Birdwatching","E3":"Calligraphy","E4":"Surfing","E5":"Sewing","E6":"Meditation"
}'::jsonb),
('celebrities', 'Celebrities', '{
  "A1":"Taylor Swift","A2":"Beyonce","A3":"Cristiano Ronaldo","A4":"Lionel Messi","A5":"Jackie Chan","A6":"Adele",
  "B1":"Bruno Mars","B2":"Lady Gaga","B3":"Dwayne Johnson","B4":"Tom Cruise","B5":"Rihanna","B6":"Ed Sheeran",
  "C1":"Selena Gomez","C2":"Justin Bieber","C3":"Ariana Grande","C4":"Zendaya","C5":"LeBron James","C6":"Serena Williams",
  "D1":"Gordon Ramsay","D2":"Oprah Winfrey","D3":"MrBeast","D4":"David Beckham","D5":"Billie Eilish","D6":"Keanu Reeves",
  "E1":"Chris Hemsworth","E2":"Alicia Keys","E3":"Katy Perry","E4":"Ryan Reynolds","E5":"Michelle Yeoh","E6":"Shah Rukh Khan"
}'::jsonb),
('subjects', 'School Subjects', '{
  "A1":"Math","A2":"English","A3":"Science","A4":"History","A5":"Geography","A6":"Art",
  "B1":"Music","B2":"Biology","B3":"Chemistry","B4":"Physics","B5":"Literature","B6":"Economics",
  "C1":"Computing","C2":"Drama","C3":"Physical Education","C4":"Social Studies","C5":"Design","C6":"Accounting",
  "D1":"Psychology","D2":"Sociology","D3":"Philosophy","D4":"Business","D5":"Statistics","D6":"Civics",
  "E1":"Robotics","E2":"Astronomy","E3":"Languages","E4":"Health","E5":"Media Studies","E6":"Environmental Science"
}'::jsonb),
('actors', 'Actors', '{
  "A1":"Tom Hanks","A2":"Meryl Streep","A3":"Leonardo DiCaprio","A4":"Scarlett Johansson","A5":"Jackie Chan","A6":"Michelle Yeoh",
  "B1":"Tom Holland","B2":"Zendaya","B3":"Robert Downey Jr.","B4":"Chris Evans","B5":"Emma Stone","B6":"Ryan Gosling",
  "C1":"Jennifer Lawrence","C2":"Will Smith","C3":"Keanu Reeves","C4":"Margot Robbie","C5":"Denzel Washington","C6":"Natalie Portman",
  "D1":"Hugh Jackman","D2":"Viola Davis","D3":"Chris Hemsworth","D4":"Anne Hathaway","D5":"Daniel Radcliffe","D6":"Sandra Bullock",
  "E1":"Morgan Freeman","E2":"Gal Gadot","E3":"Shah Rukh Khan","E4":"Song Kang-ho","E5":"Samuel L. Jackson","E6":"Nicole Kidman"
}'::jsonb),
('body-parts', 'Body Parts', '{
  "A1":"Head","A2":"Shoulder","A3":"Knee","A4":"Toe","A5":"Eye","A6":"Ear",
  "B1":"Nose","B2":"Mouth","B3":"Hand","B4":"Foot","B5":"Finger","B6":"Thumb",
  "C1":"Elbow","C2":"Wrist","C3":"Ankle","C4":"Neck","C5":"Back","C6":"Chest",
  "D1":"Stomach","D2":"Hip","D3":"Leg","D4":"Arm","D5":"Heart","D6":"Brain",
  "E1":"Tongue","E2":"Teeth","E3":"Hair","E4":"Skin","E5":"Chin","E6":"Cheek"
}'::jsonb),
('tv-shows', 'TV Shows', '{
  "A1":"Friends","A2":"The Office","A3":"Stranger Things","A4":"Squid Game","A5":"Wednesday","A6":"The Simpsons",
  "B1":"Game of Thrones","B2":"Breaking Bad","B3":"Brooklyn Nine-Nine","B4":"Modern Family","B5":"Sherlock","B6":"The Crown",
  "C1":"Survivor","C2":"MasterChef","C3":"The Voice","C4":"SpongeBob SquarePants","C5":"Peppa Pig","C6":"Sesame Street",
  "D1":"Grey''s Anatomy","D2":"Doctor Who","D3":"Money Heist","D4":"The Mandalorian","D5":"The Big Bang Theory","D6":"Avatar: The Last Airbender",
  "E1":"Black Mirror","E2":"One Piece","E3":"Pokemon","E4":"The Amazing Race","E5":"Glee","E6":"Mr. Bean"
}'::jsonb),
('songs', 'Songs', '{
  "A1":"Happy Birthday","A2":"Let It Go","A3":"Shape of You","A4":"Shake It Off","A5":"Uptown Funk","A6":"Someone Like You",
  "B1":"Roar","B2":"Firework","B3":"Rolling in the Deep","B4":"Counting Stars","B5":"Perfect","B6":"Bad Guy",
  "C1":"Just the Way You Are","C2":"Blank Space","C3":"Flowers","C4":"As It Was","C5":"Hello","C6":"Dance Monkey",
  "D1":"Levitating","D2":"Havana","D3":"Radioactive","D4":"Closer","D5":"Cheap Thrills","D6":"Thunder",
  "E1":"Watermelon Sugar","E2":"Stay","E3":"Dynamite","E4":"Call Me Maybe","E5":"We Are Young","E6":"Moves Like Jagger"
}'::jsonb),
('mrt-stations', 'Singapore MRT Stations', '{
  "A1":"Orchard","A2":"Dhoby Ghaut","A3":"City Hall","A4":"Raffles Place","A5":"Bugis","A6":"Tampines",
  "B1":"Jurong East","B2":"Bishan","B3":"Woodlands","B4":"Yishun","B5":"Punggol","B6":"Serangoon",
  "C1":"HarbourFront","C2":"Changi Airport","C3":"Expo","C4":"Ang Mo Kio","C5":"Toa Payoh","C6":"Clementi",
  "D1":"Queenstown","D2":"Bedok","D3":"Pasir Ris","D4":"Kallang","D5":"Novena","D6":"Buona Vista",
  "E1":"Botanic Gardens","E2":"Little India","E3":"Chinatown","E4":"Marina Bay","E5":"Bayfront","E6":"Outram Park"
}'::jsonb),
('drinks', 'Drinks', '{
  "A1":"Water","A2":"Coffee","A3":"Tea","A4":"Orange Juice","A5":"Milk","A6":"Hot Chocolate",
  "B1":"Lemonade","B2":"Cola","B3":"Bubble Tea","B4":"Smoothie","B5":"Milkshake","B6":"Iced Tea",
  "C1":"Apple Juice","C2":"Coconut Water","C3":"Energy Drink","C4":"Sports Drink","C5":"Soda Water","C6":"Root Beer",
  "D1":"Latte","D2":"Cappuccino","D3":"Espresso","D4":"Milo","D5":"Soy Milk","D6":"Bandung",
  "E1":"Teh Tarik","E2":"Kopi","E3":"Lime Juice","E4":"Ginger Ale","E5":"Mocktail","E6":"Slushie"
}'::jsonb),
('bands', 'Bands', '{
  "A1":"The Beatles","A2":"Coldplay","A3":"Maroon 5","A4":"One Direction","A5":"BTS","A6":"Blackpink",
  "B1":"Queen","B2":"ABBA","B3":"Imagine Dragons","B4":"Linkin Park","B5":"Green Day","B6":"The Rolling Stones",
  "C1":"Spice Girls","C2":"Backstreet Boys","C3":"Jonas Brothers","C4":"Destiny''s Child","C5":"Paramore","C6":"Arctic Monkeys",
  "D1":"Fall Out Boy","D2":"Red Hot Chili Peppers","D3":"Westlife","D4":"Bee Gees","D5":"U2","D6":"Foo Fighters",
  "E1":"The Cranberries","E2":"NSYNC","E3":"Little Mix","E4":"The Pussycat Dolls","E5":"Simple Plan","E6":"The Script"
}'::jsonb),
('singers', 'Singers', '{
  "A1":"Taylor Swift","A2":"Adele","A3":"Bruno Mars","A4":"Beyonce","A5":"Ed Sheeran","A6":"Rihanna",
  "B1":"Ariana Grande","B2":"Justin Bieber","B3":"Lady Gaga","B4":"Katy Perry","B5":"Billie Eilish","B6":"The Weeknd",
  "C1":"Shawn Mendes","C2":"Olivia Rodrigo","C3":"Dua Lipa","C4":"Miley Cyrus","C5":"Selena Gomez","C6":"Harry Styles",
  "D1":"Michael Jackson","D2":"Elvis Presley","D3":"Celine Dion","D4":"Whitney Houston","D5":"Mariah Carey","D6":"Alicia Keys",
  "E1":"Jay Chou","E2":"JJ Lin","E3":"Stefanie Sun","E4":"BLACKPINK Rose","E5":"Jungkook","E6":"Shakira"
}'::jsonb),
('fairy-tales', 'Fairy Tales', '{
  "A1":"Snow White","A2":"Rapunzel","A3":"Cinderella","A4":"Sleeping Beauty","A5":"Little Red Riding Hood","A6":"Hansel and Gretel",
  "B1":"Jack and the Beanstalk","B2":"Goldilocks","B3":"The Three Little Pigs","B4":"The Ugly Duckling","B5":"The Little Mermaid","B6":"Beauty and the Beast",
  "C1":"The Frog Prince","C2":"Rumpelstiltskin","C3":"Puss in Boots","C4":"The Emperor''s New Clothes","C5":"The Princess and the Pea","C6":"The Gingerbread Man",
  "D1":"Pinocchio","D2":"Aladdin","D3":"The Pied Piper","D4":"The Snow Queen","D5":"Thumbelina","D6":"The Elves and the Shoemaker",
  "E1":"The Boy Who Cried Wolf","E2":"The Tortoise and the Hare","E3":"The Golden Goose","E4":"The Twelve Dancing Princesses","E5":"The Bremen Town Musicians","E6":"The Brave Little Tailor"
}'::jsonb),
('mythical-creatures', 'Mythical Creatures', '{
  "A1":"Phoenix","A2":"Bigfoot","A3":"Loch Ness Monster","A4":"Unicorn","A5":"Dragon","A6":"Mermaid",
  "B1":"Centaur","B2":"Griffin","B3":"Kraken","B4":"Pegasus","B5":"Cyclops","B6":"Minotaur",
  "C1":"Werewolf","C2":"Vampire","C3":"Yeti","C4":"Sphinx","C5":"Hydra","C6":"Fairy",
  "D1":"Genie","D2":"Goblin","D3":"Basilisk","D4":"Cerberus","D5":"Gnome","D6":"Banshee",
  "E1":"Kitsune","E2":"Naga","E3":"Siren","E4":"Chimera","E5":"Kelpie","E6":"Manticore"
}'::jsonb),
('under-the-sea', 'Under the Sea', '{
  "A1":"Stingray","A2":"Seahorse","A3":"Dolphin","A4":"Swordfish","A5":"Crab","A6":"Shark",
  "B1":"Octopus","B2":"Jellyfish","B3":"Starfish","B4":"Turtle","B5":"Whale","B6":"Lobster",
  "C1":"Clownfish","C2":"Eel","C3":"Pufferfish","C4":"Squid","C5":"Seal","C6":"Walrus",
  "D1":"Coral","D2":"Seaweed","D3":"Shrimp","D4":"Oyster","D5":"Mussel","D6":"Barnacle",
  "E1":"Angelfish","E2":"Barracuda","E3":"Manta Ray","E4":"Orca","E5":"Sea Urchin","E6":"Hermit Crab"
}'::jsonb),
('musicals', 'Musicals', '{
  "A1":"Chicago","A2":"Cats","A3":"Into the Woods","A4":"Les Miserables","A5":"Annie","A6":"Oliver!",
  "B1":"Hamilton","B2":"Wicked","B3":"The Lion King","B4":"Grease","B5":"Mamma Mia!","B6":"The Phantom of the Opera",
  "C1":"The Sound of Music","C2":"West Side Story","C3":"Hairspray","C4":"Matilda","C5":"Rent","C6":"Aladdin",
  "D1":"Frozen","D2":"Mary Poppins","D3":"School of Rock","D4":"Billy Elliot","D5":"Dear Evan Hansen","D6":"The Book of Mormon",
  "E1":"Cabaret","E2":"Sweeney Todd","E3":"Evita","E4":"Guys and Dolls","E5":"Joseph","E6":"Six"
}'::jsonb),
('zoo', 'Zoo', '{
  "A1":"Giraffe","A2":"Hippo","A3":"Penguin","A4":"Lion","A5":"Zebra","A6":"Gorilla",
  "B1":"Elephant","B2":"Tiger","B3":"Monkey","B4":"Panda","B5":"Kangaroo","B6":"Rhinoceros",
  "C1":"Flamingo","C2":"Crocodile","C3":"Tortoise","C4":"Meerkat","C5":"Leopard","C6":"Cheetah",
  "D1":"Orangutan","D2":"Polar Bear","D3":"Ostrich","D4":"Peacock","D5":"Koala","D6":"Sloth",
  "E1":"Camel","E2":"Hyena","E3":"Lemur","E4":"Otter","E5":"Tapir","E6":"Red Panda"
}'::jsonb),
('famous-characters', 'Famous Characters', '{
  "A1":"Superman","A2":"Iron Man","A3":"Sonic the Hedgehog","A4":"SpongeBob SquarePants","A5":"Spider-Man","A6":"Batman",
  "B1":"Mickey Mouse","B2":"Harry Potter","B3":"Elsa","B4":"Mario","B5":"Pikachu","B6":"Darth Vader",
  "C1":"Shrek","C2":"Winnie the Pooh","C3":"Hello Kitty","C4":"Sherlock Holmes","C5":"Wonder Woman","C6":"Homer Simpson",
  "D1":"Captain America","D2":"The Hulk","D3":"Buzz Lightyear","D4":"Woody","D5":"Gru","D6":"Paddington",
  "E1":"James Bond","E2":"Gandalf","E3":"Katniss Everdeen","E4":"Wednesday Addams","E5":"Po","E6":"Sailor Moon"
}'::jsonb),
('no-1-hits', 'No. 1 Hits', '{
  "A1":"We Found Love","A2":"Gangnam Style","A3":"Baby","A4":"Thank U, Next","A5":"Blinding Lights","A6":"Flowers",
  "B1":"Shape of You","B2":"Roar","B3":"Uptown Funk","B4":"Rolling in the Deep","B5":"Bad Guy","B6":"Call Me Maybe",
  "C1":"Shake It Off","C2":"Someone Like You","C3":"As It Was","C4":"Havana","C5":"Perfect","C6":"Happy",
  "D1":"Firework","D2":"Party in the U.S.A.","D3":"Despacito","D4":"Love Story","D5":"Stay","D6":"Dynamite",
  "E1":"Umbrella","E2":"Hello","E3":"Levitating","E4":"Dance Monkey","E5":"Old Town Road","E6":"Watermelon Sugar"
}'::jsonb),
('christmas', 'Christmas', '{
  "A1":"Jingle Bells","A2":"Santa Claus","A3":"Presents","A4":"Cookies and Milk","A5":"Peppermint","A6":"Christmas Tree",
  "B1":"Snowman","B2":"Reindeer","B3":"Stocking","B4":"Candy Cane","B5":"Mistletoe","B6":"Sleigh",
  "C1":"Elf","C2":"Ornament","C3":"Gingerbread","C4":"Wrapping Paper","C5":"Fireplace","C6":"Carols",
  "D1":"North Pole","D2":"Tinsel","D3":"Wreath","D4":"Snowflake","D5":"Star","D6":"Chimney",
  "E1":"Advent Calendar","E2":"Fruitcake","E3":"Nutcracker","E4":"Bell","E5":"Fairy Lights","E6":"Christmas Card"
}'::jsonb),
('things-flush-down', 'Things Flushed Down', '{
  "A1":"Tissue","A2":"Tampons","A3":"Money","A4":"Goldfish","A5":"Toothbrush","A6":"Lego",
  "B1":"Snake","B2":"Wet Wipes","B3":"Cotton Buds","B4":"Hair","B5":"Dental Floss","B6":"Paper Towel",
  "C1":"Bandage","C2":"Toy Car","C3":"Keys","C4":"Phone","C5":"Ring","C6":"Coin",
  "D1":"Sock","D2":"Diaper","D3":"Food","D4":"Medicine","D5":"Contact Lens","D6":"Soap",
  "E1":"Bottle Cap","E2":"Chewing Gum","E3":"Tea Bag","E4":"Plastic Wrapper","E5":"Pen","E6":"Ping Pong Ball"
}'::jsonb),
('brands', 'Brands', '{
  "A1":"Apple","A2":"Microsoft","A3":"Hasbro","A4":"Nike","A5":"Adidas","A6":"Samsung",
  "B1":"Google","B2":"Amazon","B3":"Coca-Cola","B4":"Pepsi","B5":"McDonald''s","B6":"Starbucks",
  "C1":"Lego","C2":"Disney","C3":"Netflix","C4":"Toyota","C5":"Honda","C6":"IKEA",
  "D1":"Uniqlo","D2":"Zara","D3":"H&M","D4":"Sony","D5":"Nintendo","D6":"Canon",
  "E1":"KitKat","E2":"Oreo","E3":"Nescafe","E4":"YouTube","E5":"WhatsApp","E6":"Grab"
}'::jsonb)
on conflict (slug) do update
set category = excluded.category,
    board_data = excluded.board_data,
    is_active = true;
