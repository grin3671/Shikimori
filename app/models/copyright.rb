# rubocop:disable all
# модель для сбора id аниме и манги, заблокированных требованиями копирайта
module Copyright
  # by Hetzner abuse team
  # ANIME_SCREENSHOTS = [28215, 23587]
  ANIME_SCREENSHOTS = []
  ANIME_VIDEOS = ANIME_SCREENSHOTS

  # by Hetzner abuse team
  MANGA_IDS = [1]

  # taken from https://shikimori.one/collections/6269-zapreschyonnye-anime
  # CollectionLink.where(collection_id: 6269, group: 'Россия').pluck(:linked_id).sort.uniq.each {|v| puts "    #{v}, # #{Anime.find(v).name}" };
  CENSORED_IN_RUSSIA_ANIME_IDS = [
    47, # Akira
    226, # Elfen Lied
    257, # Ikkitousen
    527, # Pokemon
    1535, # Death Note
    6201, # Princess Lover!
    6987, # Aki-Sora
    7088, # Ichiban Ushiro no Daimaou
    10465, # Manyuu Hikenchou
    14829, # Fate/kaleid liner Prisma☆Illya
    14833, # Maoyuu Maou Yuusha
    17729, # Grisaia no Kajitsu
    19429, # Akuma no Riddle
    22319, # Tokyo Ghoul
    23283, # Zankyou no Terror
    24833, # Ansatsu Kyoushitsu
    30831, # Kono Subarashii Sekai ni Shukufuku wo!
    31478, # Bungou Stray Dogs
    32615, # Youjo Senki
    34019, # Tsugumomo
    34177, # Tenshi no 3P!
    34542, # Inuyashiki
    34658, # Nekopara OVA
    35241, # Konohana Kitan
    35849, # Darling in the FranXX
    36632, # Ore ga Suki nano wa Imouto dakedo Imouto ja Nai
    37055, # Youjo Senki Movie
    37210, # Isekai Maou to Shoukan Shoujo no Dorei Majutsu
    37430, # Tensei shitara Slime Datta Ken
    37517, # Happy Sugar Life
    37976, # Zombieland Saga
    37998, # Girly Air Force
    38397, # Nande Koko ni Sensei ga!?
    38656, # Darwin's Game
    39017, # Kyokou Suiri
    40010, # Ishuzoku Critiqueers
    40046 # Id:Invaded
  ]

  ABUSED_BY_RKN_CHARACTER_ART_IDS = [
    37698, # Kobato Hasegawa
    82525, # Shiro
    38934, # Maria Takayama
    65263, # Kotori Itsuka
    70603 # Yoshino
  ]

  ABUSED_BY_RKN_CHARACTER_IDS = [
    2515, # Pico
    15967, # Coco
    2516 # Chico
  ]

  ABUSED_BY_RKN_ANIME_IDS = [
    5391, # Pico to Chico
    4866, # Pico x CoCo x Chico
    34659, # Otokonoko ♂ Delivery
    17371, # Natsuyasumi.
    37405, # Dokidoki Little Ooyasan
    6546, # Pico: My Little Summer Story
    1639, # Boku no Pico
    1535 # Death Note
  ]

  ABUSED_BY_RKN_MANGA_IDS = [
    5467, # Boku no Pico
    124272 # Suicide Boy
  ]
  BANNED_BY_RKN_MANGA_IDS = [
    124272 # Suicide Boy
  ]
end
