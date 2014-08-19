
-- DreamGuild.eu database schema


BEGIN;


CREATE TABLE user (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  email      TEXT NOT NULL UNIQUE,
  password   TEXT NOT NULL,

  -- user level
  -- 0: just registered didn't send any app
  -- 5: guild member
  -- 20: gm
  -- 30: admin
  level      INTEGER DEFAULT 0,     -- user level
  main       INTEGER DEFAULT 0,     -- main character id
  appid      INTEGER DEFAULT 0,     -- aplication id
  dkp        INTEGER DEFAULT 0,
  join_time  INTEGER DEFAULT 0,     -- joined date
  last_active INTEGER DEFAULT 0
);


CREATE TABLE roster (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  name       TEXT,
  uid        INTEGER DEFAULT 0,
  class      INTEGER DEFAULT 0,
  race       INTEGER DEFAULT 0,
  level      INTEGER DEFAULT 0,
  ailvl      INTEGER DEFAULT 0,
  eilvl      INTEGER DEFAULT 0,
  rank       INTEGER DEFAULT 0,
  thumbnail  TEXT,
  spec       TEXT,
  role       INTEGER DEFAULT 0,
  talents    TEXT,
  items      TEXT,
  progress   TEXT,
  achievement_points INTEGER DEFAULT 0,
  last_update INTEGER DEFAULT 0,
  is_main        INTEGER DEFAULT 0,
  lottery_ticket INTEGER DEFAULT 0
);


CREATE TABLE ilvl_history (
  uid        INTEGER DEFAULT 0,
  ilvl       INTEGER DEFAULT 0,
  time       INTEGER DEFAULT 0,
  UNIQUE     (uid, ilvl)
);


CREATE TABLE progress_history (
  uid        INTEGER DEFAULT 0,
  points     INTEGER DEFAULT 0,
  time       INTEGER DEFAULT 0,
  UNIQUE     (uid, points)
);


CREATE TABLE application (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  uid        INTEGER DEFAULT 0,
  status     INTEGER DEFAULT 0,
  app_id     TEXT UNIQUE,
  name       TEXT,
  class      INTEGER DEFAULT 0,
  race       INTEGER DEFAULT 0,
  level      INTEGER DEFAULT 0,
  ailvl      INTEGER DEFAULT 0,
  eilvl      INTEGER DEFAULT 0,
  thumbnail  TEXT,
  talents    TEXT,
  items      TEXT,
  progress   TEXT,
  achievement_points INTEGER DEFAULT 0,
  questions  TEXT,
  time       INTEGER DEFAULT 0,
  update_time INTEGER DEFAULT 0,
  yes        INTEGER DEFAULT 0,
  no         INTEGER DEFAULT 0,
  points     INTEGER DEFAULT 0,
  issued_by  INTEGER DEFAULT 0,
  reason     TEXT
);


CREATE TABLE application_votes (
  uid        INTEGER NOT NULL,
  appid      INTEGER NOT NULL,
  vote       INTEGER DEFAULT 0,
  points     INTEGER DEFAULT 0,
  time       INTEGER DEFAULT 0 NOT NULL,
  UNIQUE     (uid, appid)
);


CREATE TABLE application_comments (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  appid      INTEGER NOT NULL,
  uid        INTEGER NOT NULL,
  comment    TEXT,
  time       INTEGER DEFAULT 0 NOT NULL
);


CREATE TABLE news (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  uid        INTEGER NOT NULL,
  title      TEXT,
  content    TEXT,
  time       INTEGER
);



-- FACEBOOK FEEDS

CREATE TABLE facebook (
  fbid       INTEGER PRIMARY KEY,
  rootid     INTEGER DEFAULT 0,
  from_name  TEXT,
  from_fbid  INTEGER DEFAULT 0,
  from_id    INTEGER DEFAULT 0,
  message_orig TEXT,
  message    TEXT,
  picture    TEXT,
  likes      TEXT,
  created_time INTEGER,
  updated_time INTEGER,
  comments   INTEGER
);



CREATE TABLE options (
  option TEXT PRIMARY KEY NOT NULL,
  value  TEXT NOT NULL
);


INSERT INTO options VALUES (
  'questions',
  '[
   {
      "section" : "Personal Information",
      "questions" : [
         {
            "question" : "Real Name"
         },
         {
            "question" : "Age"
         },
         {
            "question" : "Country"
         }
      ]
   },
   {
      "section" : "Character Information",
      "questions" : [
         {
            "type" : "textarea",
            "question" : "How well do you know your class and role?"
         },
         {
            "question" : "Screenshot of your UI"
         },
         {
            "type" : "textarea",
            "question" : "Do you have an off-spec? How well do you play it?"
         },
         {
            "question" : "List your alternate characters if there are any",
            "type" : "textarea"
         }
      ]
   },
   {
      "section" : "Technical Information",
      "questions" : [
         {
            "question" : "Your FPS during a 25-man/LFR Raid"
         },
         {
            "question" : "Your ping/latency during a 25-man/LFR Raid"
         },
         {
            "question" : "AddOns you use",
            "type" : "textarea"
         },
         {
            "question" : "Availability to attend guild raid/event in general"
         },
         {
            "type" : "textarea",
            "question" : "Date/time you are unavailable to participate a raid"
         }
      ]
   },
   {
      "section" : "Other Information",
      "questions" : [
         {
            "question" : "Previous/current guilds",
            "type" : "textarea"
         },
         {
            "question" : "Why did you choose Dream?",
            "type" : "textarea"
         },
         {
            "type" : "textarea",
            "question" : "What is your goal in this game? Does it have a correlation with the decision to join this guild?"
         },
         {
            "type" : "textarea",
            "question" : "Are you applying to any other guild?"
         },
         {
            "question" : "How do you make gold?",
            "type" : "textarea"
         }
      ]
   },
   {
      "questions" : [
         {
            "question" : "Is there any way we can contact you on daily basis and emergency stuff?",
            "type" : "textarea"
         }
      ],
      "section" : "Contact Information"
   }
]');

INSERT INTO options VALUES (
  'questions-description',
  "  <p>Few things you need to know regarding this application form:</p>
  <ul>
    <li>Applications that are explained in detail will be taken more seriously than those that are not.</li>
    <li>All questions need to be answered correctly, complete with the appropriate format if requested. We do NOT accept a blank, <em>-</em>, or a <em>I don't know</em> as an answer. This especially applies when we ask for tactics (if there is any). Failure to comply is an automatic incomplete application and it will not be reviewed further.</li>
    <li>Be honest on the answers, we will find out if you lie.</li>
    <li>There's no trick or trap question in this form.</li>
    <li>Do not make any copy-paste answers except for pasting URL links.</li>
    <li>Do not contact any of our members regarding your application.</li>
  </ul>");


COMMIT;
