conn = ActiveRecord::Base.connection

puts "Clearing existing PostgreSQL data..."
conn.execute("DELETE FROM votes")
conn.execute("DELETE FROM items")
conn.execute("DELETE FROM availabilities")
conn.execute("DELETE FROM invites")
conn.execute("DELETE FROM events")
conn.execute("DELETE FROM users")

puts "Inserting users..."
conn.execute(<<~SQL)
  INSERT INTO users (id, username, email, phone, contact_type, display_name, password_digest, created_at, updated_at) VALUES
  (1, 'Holly',   'admin@test.com',          NULL,           'email', NULL, '$2a$12$2wRr3g83xmtcTMIDXHGc.umt/8HwuRgA5Vw5m0sLWTR07YSyut4XO', '2026-04-15 15:42:01.737822', '2026-04-15 15:42:01.737822'),
  (2, 'JoJo',    'guest@test.com',           NULL,           'email', NULL, '$2a$12$3VvDa4uvH8UCgugwP8lULugf/BNF4.Vsi0tTNgB8j4V0U4awNxTMC',  '2026-04-15 15:45:17.346501', '2026-04-15 15:45:17.346501'),
  (3, 'Millie',  NULL,                       '222-222-2222', 'phone', NULL, '$2a$12$lF0qV5r1XmFtREqc4CiKKO0YMvsk.LEMXEIitKQF3GYU.N3F8VQ3u',  '2026-04-15 15:46:37.028652', '2026-04-15 15:46:37.028652'),
  (4, 'Cartman', 'guest3@test.com',          NULL,           'email', NULL, '$2a$12$thAG8EgM7THdTpa8RcV3RugeyJIMnHDCISBN08Iv795K2ciEmJEFS',   '2026-04-15 16:25:18.497628', '2026-04-15 16:25:18.497628'),
  (5, 'Akasha',  'guest1@test.com',          NULL,           'email', NULL, '$2a$12$qwH905l.KnQ4qfdNxEabJe4pRnyaaHmksnXqAkgO7iz.Gw2f4i2Hu',  '2026-04-15 21:46:38.780949', '2026-04-15 21:46:38.780949'),
  (6, 'Mob',     'guest2@test.com',          NULL,           'email', NULL, '$2a$12$UvIJzbW8fs/NZHttrq9h0ODN1wNSfx0TmTzUuNrAc6AGA1z3CD01m',  '2026-04-15 21:48:33.888076', '2026-04-15 21:48:33.888076'),
  (7, 'Glen',    'guest4@test.com',          NULL,           'email', NULL, '$2a$12$CrMJTQjWl/tPlTiDxdlYi.Z/473qK4jpN28nkW7FrGuM67UVoE.BW',  '2026-04-18 03:05:30.624874', '2026-04-18 03:05:30.624874'),
  (8, 'Admin',   'catherderapp@gmail.com',   NULL,           'email', NULL, '$2a$12$xRAJoPMkXDIEwYusUnCKmOooUKMIBsdAchq3j.fbZhT2sFoXrSgee',  '2026-04-24 18:08:25.302660', '2026-04-24 18:08:25.302660')
SQL

puts "Inserting events..."
conn.execute(<<~SQL)
  INSERT INTO events (id, name, description, vote_mode, items_mode, gift_hidden_from, date_range_start, date_range_end, confirmed_date, status, owner_id, invite_permission, vip_permission, start_time_mode, start_time, invite_guest_contact, gift_hidden_from_type, invite_guest_contact_type, bring_label, availability_deadline, created_at, updated_at) VALUES
  (16, 'Test',                        'test event, range, items hidden from jojo, guest vote, tie vote no vip guest can invite', true,  'gift',      'JoJo', '2026-04-20', '2026-04-23', '2026-04-20',      'confirmed', 7, 'anyone', 'none', 'fixed',  '06:00', NULL,     'username', 'username', NULL,     '2026-04-19', '2026-04-18 03:07:37.432406', '2026-04-18 03:12:00.328877'),
  (17, 'Testing without tie since vip','vote on setting a time, guest sets vip, hide from jojo Millie can invite',                true,  'gift',      'JoJo', '2026-04-24', '2026-04-26', '2026-04-26T17:00','confirmed', 1, 'select', 'host', 'vote',   NULL,    'Millie', 'username', 'username', NULL,     '2026-04-23', '2026-04-20 21:20:01.233238', '2026-04-20 21:27:59.686067'),
  (18, 'test tie',                    'no vip, vote on time potluck, host only invites',                                         true,  'open',      NULL,   '2026-04-25', '2026-04-26', '2026-04-26',      'confirmed', 1, 'anyone', 'none', 'fixed',  '17:00', NULL,     'username', 'username', NULL,     '2026-04-23', '2026-04-20 21:35:39.295658', '2026-04-20 21:43:54.839665'),
  (19, 'DnD PARTY',                   'GAMES!!!!!',                                                                              false, 'simpleYes', NULL,   '2026-04-20', '2026-04-20', NULL,              'open',      1, 'host',   'none', 'vote',   NULL,    NULL,     'username', 'username', 'snacks', NULL,         '2026-04-20 22:59:40.275261', '2026-04-22 17:37:38.422303'),
  (20, 'Test',                        NULL,                                                                                      false, 'none',      NULL,   '2026-04-23', '2026-04-23', NULL,              'open',      6, 'host',   'none', 'vote',   NULL,    NULL,     'username', 'username', NULL,     NULL,         '2026-04-22 18:58:53.105124', '2026-04-22 18:58:53.105124'),
  (21, 'Test',                        NULL,                                                                                      false, 'open',      NULL,   '2026-04-26', '2026-04-26', NULL,              'open',      8, 'host',   'none', 'fixed',  NULL,    NULL,     'username', 'username', NULL,     NULL,         '2026-04-25 02:44:32.115318', '2026-04-25 02:44:32.115318')
SQL

puts "Inserting invites..."
conn.execute(<<~SQL)
  INSERT INTO invites (id, contact, contact_type, status, is_vip, event_id, user_id, nickname, created_at, updated_at) VALUES
  (47, 'jojo',                       'username', 'declined', false, 16, 2,    NULL, '2026-04-18 03:07:37.436495', '2026-04-18 03:10:00.824537'),
  (48, 'Mob',                        'username', 'maybe',    false, 16, 6,    NULL, '2026-04-18 03:07:37.442869', '2026-04-18 03:09:43.773290'),
  (49, 'admin@test.com',             'email',    'accepted', false, 16, 1,    NULL, '2026-04-18 03:07:37.448250', '2026-04-18 03:09:09.565419'),
  (50, '222-222-2222',               'phone',    'accepted', false, 16, 3,    NULL, '2026-04-18 03:07:37.454438', '2026-04-18 03:08:26.672861'),
  (51, 'guest@test.com',             'email',    'accepted', true,  17, 2,    'j',  '2026-04-20 21:20:01.237477', '2026-04-20 21:25:29.467271'),
  (52, '222-222-2222',               'phone',    'accepted', false, 17, 3,    NULL, '2026-04-20 21:20:01.242766', '2026-04-20 21:23:14.631041'),
  (53, 'Akasha',                     'username', 'accepted', false, 17, 5,    NULL, '2026-04-20 21:20:01.247735', '2026-04-20 21:24:31.998348'),
  (54, 'mob',                        'username', 'declined', false, 17, 6,    NULL, '2026-04-20 21:23:32.886860', '2026-04-20 21:26:02.184870'),
  (55, 'JoJo',                       'username', 'accepted', false, 18, 2,    NULL, '2026-04-20 21:35:39.309793', '2026-04-20 21:42:17.255624'),
  (56, 'Akasha',                     'username', 'accepted', false, 18, 5,    NULL, '2026-04-20 21:35:39.314295', '2026-04-20 21:41:53.003902'),
  (57, 'Mob',                        'username', 'maybe',    false, 18, 6,    NULL, '2026-04-20 21:35:39.318688', '2026-04-20 21:42:48.899937'),
  (58, 'guest@test.com',             'email',    'accepted', false, 19, 2,    NULL, '2026-04-20 22:59:40.279707', '2026-04-20 23:07:03.108222'),
  (59, 'akasha',                     'username', 'maybe',    false, 19, 5,    NULL, '2026-04-22 18:35:54.050159', '2026-04-22 18:36:16.302367'),
  (60, 'mob',                        'username', 'declined', false, 19, 6,    NULL, '2026-04-22 18:35:54.055086', '2026-04-22 18:36:33.695523'),
  (61, 'holly',                      'username', 'accepted', false, 20, 1,    NULL, '2026-04-22 18:58:53.109591', '2026-04-22 18:59:09.643032'),
  (66, 'catherderapp@gmail.com',     'email',    'pending',  false, 19, 8,    NULL, '2026-04-24 18:02:00.965079', '2026-04-24 18:02:00.965079'),
  (68, 'hollygracemaguire@gmail.com','email',    'pending',  false, 19, NULL, NULL, '2026-04-24 18:09:32.359471', '2026-04-24 18:09:32.359471'),
  (69, 'JoJo',                       'username', 'accepted', false, 21, 2,    NULL, '2026-04-25 02:44:32.119393', '2026-04-25 02:52:37.699988'),
  (70, 'Akasha',                     'username', 'pending',  false, 21, 5,    NULL, '2026-04-25 02:44:32.124644', '2026-04-25 02:44:32.129702')
SQL

puts "Inserting availabilities..."
conn.execute(<<~SQL)
  INSERT INTO availabilities (id, slots, user_id, event_id, created_at, updated_at) VALUES
  (41, '["2026-04-20"]',                                              3, 16, '2026-04-18 03:08:24.435796', '2026-04-18 03:08:24.435796'),
  (42, '["2026-04-20"]',                                              1, 16, '2026-04-18 03:09:02.112096', '2026-04-18 03:09:02.112096'),
  (43, '["2026-04-21"]',                                              6, 16, '2026-04-18 03:09:38.548040', '2026-04-18 03:09:38.548040'),
  (44, '["2026-04-24T04:00","2026-04-25T05:00","2026-04-26T17:00"]', 1, 17, '2026-04-20 21:21:21.885525', '2026-04-20 21:21:21.885525'),
  (45, '["2026-04-26T17:00"]',                                        3, 17, '2026-04-20 21:23:12.143399', '2026-04-20 21:23:12.143399'),
  (46, '["2026-04-26T17:00"]',                                        2, 17, '2026-04-20 21:25:27.288322', '2026-04-20 21:25:27.288322'),
  (47, '["2026-04-25T03:00"]',                                        5, 17, '2026-04-20 21:27:33.190326', '2026-04-20 21:27:33.190326'),
  (48, '["2026-04-26"]',                                              1, 18, '2026-04-20 21:41:02.012995', '2026-04-20 21:41:02.012995'),
  (49, '["2026-04-25"]',                                              5, 18, '2026-04-20 21:41:44.286307', '2026-04-20 21:41:44.286307'),
  (50, '["2026-04-26"]',                                              2, 18, '2026-04-20 21:42:14.795660', '2026-04-20 21:42:14.795660'),
  (51, '["2026-04-25"]',                                              6, 18, '2026-04-20 21:42:41.466802', '2026-04-20 21:42:41.466802')
SQL

puts "Inserting items..."
conn.execute(<<~SQL)
  INSERT INTO items (id, name, event_id, claimed_by_id, added_by_id, created_at, updated_at) VALUES
  (15, 'glenn',       16, NULL, 7, '2026-04-18 03:07:56.616959', '2026-04-18 03:07:56.616959'),
  (16, 'test',        16, NULL, 1, '2026-04-18 03:09:07.786494', '2026-04-18 03:09:07.786494'),
  (17, 'Admin''s gift',17, NULL, 1, '2026-04-20 21:21:44.518936', '2026-04-20 21:21:44.518936'),
  (19, 'millie gift', 17, NULL, 3, '2026-04-20 21:23:22.193744', '2026-04-20 21:23:22.193744'),
  (20, 'akasha gift', 17, NULL, 5, '2026-04-20 21:24:37.178503', '2026-04-20 21:24:37.178503'),
  (22, 'food1',       18, NULL, 1, '2026-04-20 21:41:09.030513', '2026-04-20 21:41:09.030513'),
  (23, 'tems',        18, NULL, 5, '2026-04-20 21:41:51.487409', '2026-04-20 21:41:51.487409'),
  (24, 'stuff',       18, NULL, 2, '2026-04-20 21:42:24.721610', '2026-04-20 21:42:24.721610'),
  (25, 'drank',       18, NULL, 6, '2026-04-20 21:42:47.374287', '2026-04-20 21:42:47.374287'),
  (26, 'book',        21, NULL, 5, '2026-04-25 03:01:04.188481', '2026-04-25 03:01:04.188481')
SQL

puts "Inserting votes..."
conn.execute(<<~SQL)
  INSERT INTO votes (id, chosen_slot, user_id, event_id, created_at, updated_at) VALUES
  (16, '2026-04-26', 6, 18, '2026-04-20 21:43:00.017619', '2026-04-20 21:43:00.017619'),
  (17, '2026-04-26', 5, 18, '2026-04-20 21:43:20.679835', '2026-04-20 21:43:20.679835'),
  (18, '2026-04-25', 2, 18, '2026-04-20 21:43:34.317526', '2026-04-20 21:43:34.317526'),
  (19, '2026-04-26', 1, 18, '2026-04-20 21:43:48.747776', '2026-04-20 21:43:48.747776')
SQL

puts "Resetting PostgreSQL sequences..."
%w[users events invites availabilities items votes].each do |table|
  conn.execute("SELECT setval('#{table}_id_seq', (SELECT MAX(id) FROM #{table}))")
end

puts "Done! Migration complete."
puts "Users: #{User.count}, Events: #{Event.count}, Invites: #{Invite.count}"
