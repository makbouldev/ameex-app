-- ============================================================================
-- AMEEX DEMO SEED — 10 drivers + 40 orders with varied statuses
-- Run once in Supabase → SQL Editor → New query → Run.
-- Safe to re-run (uses ON CONFLICT DO NOTHING).
-- ============================================================================

-- 1) Create 10 Moroccan drivers (both auth.users AND profiles)
DO $$
DECLARE
  d record;
  drivers text[][] := ARRAY[
    ['11111111-1111-1111-1111-000000000001', 'Youssef El Idrissi',  'youssef.idrissi@ameex.ma',  '0612345671', 'Moto / Scooter',   'Casablanca - Maarif & Anfa'],
    ['11111111-1111-1111-1111-000000000002', 'Omar Benkirane',       'omar.benkirane@ameex.ma',    '0612345672', 'Moto / Scooter',   'Casablanca - Sidi Moumen'],
    ['11111111-1111-1111-1111-000000000003', 'Mehdi Alaoui',         'mehdi.alaoui@ameex.ma',      '0612345673', 'Voiture (Car)',    'Casablanca - Ain Diab'],
    ['11111111-1111-1111-1111-000000000004', 'Hamza Belhaj',         'hamza.belhaj@ameex.ma',      '0612345674', 'Moto / Scooter',   'Rabat - Agdal'],
    ['11111111-1111-1111-1111-000000000005', 'Khalid Tazi',          'khalid.tazi@ameex.ma',       '0612345675', 'Fourgonnette (Van)', 'Rabat - Hassan'],
    ['11111111-1111-1111-1111-000000000006', 'Rachid El Fassi',      'rachid.fassi@ameex.ma',      '0612345676', 'Voiture (Car)',    'Marrakech - Gueliz'],
    ['11111111-1111-1111-1111-000000000007', 'Ayoub Bennani',        'ayoub.bennani@ameex.ma',     '0612345677', 'Moto / Scooter',   'Marrakech - Medina'],
    ['11111111-1111-1111-1111-000000000008', 'Soufiane Lahlou',      'soufiane.lahlou@ameex.ma',   '0612345678', 'Vélo (Bike)',      'Tanger - Centre'],
    ['11111111-1111-1111-1111-000000000009', 'Ismail Chraibi',       'ismail.chraibi@ameex.ma',    '0612345679', 'Moto / Scooter',   'Fès - Atlas'],
    ['11111111-1111-1111-1111-000000000010', 'Nabil Mounir',         'nabil.mounir@ameex.ma',      '0612345680', 'Voiture (Car)',    'Agadir - Centre']
  ];
BEGIN
  FOR i IN 1..10 LOOP
    -- auth.users
    INSERT INTO auth.users (
      id, instance_id, email, encrypted_password, email_confirmed_at,
      created_at, updated_at, raw_app_meta_data, raw_user_meta_data,
      aud, role
    )
    VALUES (
      drivers[i][1]::uuid,
      '00000000-0000-0000-0000-000000000000',
      drivers[i][3],
      crypt('driver123456', gen_salt('bf')),
      now(), now(), now(),
      '{"provider":"email","providers":["email"]}'::jsonb,
      jsonb_build_object('full_name', drivers[i][2]),
      'authenticated', 'authenticated'
    )
    ON CONFLICT (id) DO NOTHING;

    -- public.profiles (no email column — email lives in auth.users)
    INSERT INTO public.profiles (id, full_name, phone, role, vehicle_type, zone)
    VALUES (
      drivers[i][1]::uuid,
      drivers[i][2],
      drivers[i][4],
      'driver',
      drivers[i][5],
      drivers[i][6]
    )
    ON CONFLICT (id) DO UPDATE SET
      full_name    = EXCLUDED.full_name,
      phone        = EXCLUDED.phone,
      role         = EXCLUDED.role,
      vehicle_type = EXCLUDED.vehicle_type,
      zone         = EXCLUDED.zone;
  END LOOP;
END $$;

-- 2) Create 40 orders with varied statuses, cities, dates and driver assignments
DO $$
DECLARE
  d1 uuid := '11111111-1111-1111-1111-000000000001';
  d2 uuid := '11111111-1111-1111-1111-000000000002';
  d3 uuid := '11111111-1111-1111-1111-000000000003';
  d4 uuid := '11111111-1111-1111-1111-000000000004';
  d5 uuid := '11111111-1111-1111-1111-000000000005';
  d6 uuid := '11111111-1111-1111-1111-000000000006';
  d7 uuid := '11111111-1111-1111-1111-000000000007';
  d8 uuid := '11111111-1111-1111-1111-000000000008';
  d9 uuid := '11111111-1111-1111-1111-000000000009';
  d10 uuid := '11111111-1111-1111-1111-000000000010';
BEGIN
  INSERT INTO public.orders
    (tracking_number, customer_name, customer_phone, destination_city, delivery_address, amount, driver_fee, status, assigned_driver_id, dest_latitude, dest_longitude, created_at, updated_at)
  VALUES
    -- DELIVERED (16) — mix of recent & this week
    ('AMX10001ABC', 'Fatima Zahra',     '0661112233', 'Casablanca', 'Maarif, Rue Al Massira [COLIS_REMIS_PAR_ADMIN]',          320, 25, 'delivered', d1, 33.5731, -7.5898, now() - interval '1 day',  now() - interval '1 day'),
    ('AMX10002DEF', 'Hassan El Ouali',  '0661112234', 'Casablanca', 'Anfa, Bd Al Massira [COLIS_REMIS_PAR_ADMIN]',             450, 30, 'delivered', d2, 33.5892, -7.6324, now() - interval '2 day',  now() - interval '2 day'),
    ('AMX10003GHI', 'Salma Benali',     '0661112235', 'Casablanca', 'Ain Diab, Corniche [COLIS_REMIS_PAR_ADMIN]',              180, 25, 'delivered', d3, 33.5979, -7.6708, now() - interval '3 day',  now() - interval '3 day'),
    ('AMX10004JKL', 'Imane Lahrichi',   '0661112236', 'Rabat',      'Agdal, Av Fal Ould Oumeir [COLIS_REMIS_PAR_ADMIN]',       520, 35, 'delivered', d4, 34.0133, -6.8326, now() - interval '1 day',  now() - interval '1 day'),
    ('AMX10005MNO', 'Karim Bouazza',    '0661112237', 'Rabat',      'Hassan, Rue Patrice Lumumba [COLIS_REMIS_PAR_ADMIN]',     275, 25, 'delivered', d5, 34.0151, -6.8326, now() - interval '4 day',  now() - interval '4 day'),
    ('AMX10006PQR', 'Zineb El Khatib',  '0661112238', 'Marrakech',  'Gueliz, Av Mohammed V [COLIS_REMIS_PAR_ADMIN]',           380, 30, 'delivered', d6, 31.6295, -7.9811, now() - interval '2 day',  now() - interval '2 day'),
    ('AMX10007STU', 'Amine Chraibi',    '0661112239', 'Marrakech',  'Medina, Place Jemaa el-Fna [COLIS_REMIS_PAR_ADMIN]',      240, 25, 'delivered', d7, 31.6258, -7.9892, now() - interval '5 day',  now() - interval '5 day'),
    ('AMX10008VWX', 'Nadia Belkadi',    '0661112240', 'Tanger',     'Centre, Grand Socco [COLIS_REMIS_PAR_ADMIN]',             410, 30, 'delivered', d8, 35.7595, -5.8340, now() - interval '3 day',  now() - interval '3 day'),
    ('AMX10009YZA', 'Yassine Haddad',   '0661112241', 'Fès',        'Atlas, Av Hassan II [COLIS_REMIS_PAR_ADMIN]',             295, 25, 'delivered', d9, 34.0181, -5.0078, now() - interval '6 day',  now() - interval '6 day'),
    ('AMX10010BCD', 'Hajar El Amrani',  '0661112242', 'Agadir',     'Centre, Bd du 20 Août [COLIS_REMIS_PAR_ADMIN]',           360, 30, 'delivered', d10, 30.4278, -9.5981, now() - interval '2 day',  now() - interval '2 day'),
    ('AMX10011EFG', 'Mohamed Alami',    '0661112243', 'Casablanca', 'Maarif, Rue Oued Fes [COLIS_REMIS_PAR_ADMIN]',            220, 25, 'delivered', d1, 33.5707, -7.5986, now() - interval '5 day',  now() - interval '5 day'),
    ('AMX10012HIJ', 'Sara Benjelloun',  '0661112244', 'Casablanca', 'Sidi Moumen, Rue 30 [COLIS_REMIS_PAR_ADMIN]',             195, 25, 'delivered', d2, 33.6005, -7.4854, now() - interval '7 day',  now() - interval '7 day'),
    ('AMX10013KLM', 'Jamal Karimi',     '0661112245', 'Rabat',      'Agdal, Rue Ibn Sina [COLIS_REMIS_PAR_ADMIN]',             480, 35, 'delivered', d4, 34.0098, -6.8375, now() - interval '4 day',  now() - interval '4 day'),
    ('AMX10014NOP', 'Laila Tazi',       '0661112246', 'Marrakech',  'Gueliz, Rue Yougoslavie [COLIS_REMIS_PAR_ADMIN]',         310, 30, 'delivered', d6, 31.6342, -7.9986, now() - interval '6 day',  now() - interval '6 day'),
    ('AMX10015QRS', 'Rania Idrissi',    '0661112247', 'Casablanca', 'Anfa, Bd d''Anfa [COLIS_REMIS_PAR_ADMIN]',                540, 35, 'delivered', d3, 33.5880, -7.6416, now(),                     now()),
    ('AMX10016TUV', 'Reda El Fassi',    '0661112248', 'Tanger',     'Centre, Av Pasteur [COLIS_REMIS_PAR_ADMIN]',              290, 25, 'delivered', d8, 35.7762, -5.8030, now() - interval '1 day',  now() - interval '1 day'),

    -- IN TRANSIT (8)
    ('AMX20001ABC', 'Ahmed Bennouna',   '0661113301', 'Casablanca', 'Maarif, Rue Pierre Parent',           340, 25, 'in_transit', d1, 33.5703, -7.5891, now() - interval '3 hour', now() - interval '3 hour'),
    ('AMX20002DEF', 'Siham Lahlou',     '0661113302', 'Casablanca', 'Anfa, Rue Ibnou Mounir',              220, 25, 'in_transit', d3, 33.5929, -7.6412, now() - interval '2 hour', now() - interval '2 hour'),
    ('AMX20003GHI', 'Driss Mounir',     '0661113303', 'Rabat',      'Hay Riad, Av Annakhil',               405, 35, 'in_transit', d4, 33.9869, -6.8698, now() - interval '5 hour', now() - interval '5 hour'),
    ('AMX20004JKL', 'Khadija Senhaji',  '0661113304', 'Marrakech',  'Hivernage, Av Mohamed VI',            460, 30, 'in_transit', d6, 31.6278, -7.9986, now() - interval '4 hour', now() - interval '4 hour'),
    ('AMX20005MNO', 'Samir Ouazzani',   '0661113305', 'Marrakech',  'Medina, Rue Bab Agnaou',              175, 25, 'in_transit', d7, 31.6207, -7.9890, now() - interval '1 hour', now() - interval '1 hour'),
    ('AMX20006PQR', 'Houda El Jadidi',  '0661113306', 'Tanger',     'Malabata, Av Mohammed VI',            315, 30, 'in_transit', d8, 35.7850, -5.7746, now() - interval '2 hour', now() - interval '2 hour'),
    ('AMX20007STU', 'Nawfal El Khattab','0661113307', 'Fès',        'Atlas, Rue Allal Ben Abdellah',       255, 25, 'in_transit', d9, 34.0210, -5.0140, now() - interval '6 hour', now() - interval '6 hour'),
    ('AMX20008VWX', 'Meriem Benchekroun','0661113308','Agadir',     'Centre, Bd Hassan II',                385, 30, 'in_transit', d10, 30.4216, -9.5940, now() - interval '3 hour', now() - interval '3 hour'),

    -- PENDING (6) — not yet assigned
    ('AMX30001ABC', 'Naoufal Belhaj',   '0661114401', 'Casablanca', 'Bourgogne, Rue Mustapha El Maani',    260, 25, 'pending',    null, null, null, now() - interval '30 min', now() - interval '30 min'),
    ('AMX30002DEF', 'Asma Benkirane',   '0661114402', 'Casablanca', 'Hay Hassani, Rue 10',                 190, 25, 'pending',    null, null, null, now() - interval '45 min', now() - interval '45 min'),
    ('AMX30003GHI', 'Issam Alaoui',     '0661114403', 'Rabat',      'Océan, Av des Nations Unies',         345, 30, 'pending',    null, null, null, now() - interval '1 hour', now() - interval '1 hour'),
    ('AMX30004JKL', 'Wafae El Ouali',   '0661114404', 'Marrakech',  'Sidi Ghanem, Zone industrielle',      420, 35, 'pending',    null, null, null, now() - interval '2 hour', now() - interval '2 hour'),
    ('AMX30005MNO', 'Hicham Tazi',      '0661114405', 'Tanger',     'Val Fleuri, Rue Hollande',            285, 25, 'pending',    null, null, null, now() - interval '1 hour', now() - interval '1 hour'),
    ('AMX30006PQR', 'Lamia Bennani',    '0661114406', 'Fès',        'Narjiss, Rue Al Yasmine',             215, 25, 'pending',    null, null, null, now() - interval '20 min', now() - interval '20 min'),

    -- ACCEPTED / WAITING AGENCY (5) — status='pending' + marker in address (UI derives "accepted" state)
    ('AMX40001ABC', 'Khadija Rachidi',  '0661115501', 'Casablanca', 'Maarif, Rue Chevalier Bayard [ETAT: ACCEPTE_ATTENTE_AGENCE]', 310, 25, 'pending', d2, null, null, now() - interval '1 hour', now() - interval '1 hour'),
    ('AMX40002DEF', 'Mourad El Idrissi','0661115502', 'Rabat',      'Agdal, Rue Oued Beth [ETAT: ACCEPTE_ATTENTE_AGENCE]',         395, 30, 'pending', d5, null, null, now() - interval '2 hour', now() - interval '2 hour'),
    ('AMX40003GHI', 'Fadwa Senhaji',    '0661115503', 'Marrakech',  'Gueliz, Rue Oum Errabia [ETAT: ACCEPTE_ATTENTE_AGENCE]',      240, 25, 'pending', d7, null, null, now() - interval '3 hour', now() - interval '3 hour'),
    ('AMX40004JKL', 'Tarik Mounir',     '0661115504', 'Tanger',     'Iberia, Av Moulay Abdellah [ETAT: ACCEPTE_ATTENTE_AGENCE]',   355, 30, 'pending', d8, null, null, now() - interval '2 hour', now() - interval '2 hour'),
    ('AMX40005MNO', 'Sanae Benjelloun', '0661115505', 'Agadir',     'Talborjt, Av Prince Moulay Abdellah [ETAT: ACCEPTE_ATTENTE_AGENCE]', 275, 25, 'pending', d10, null, null, now() - interval '1 hour', now() - interval '1 hour'),

    -- CANCELLED (5) — mix with/without compensation motif
    ('AMX50001ABC', 'Yasmine Chraibi',  '0661116601', 'Casablanca', 'Maarif, Rue Jean Jaurès [MOTIF: Client absent après 3 tentatives]', 180, 25, 'cancelled', d1, null, null, now() - interval '2 day',  now() - interval '2 day'),
    ('AMX50002DEF', 'Anas El Fassi',    '0661116602', 'Rabat',      'Hassan, Av Allal Ben Abdellah [MOTIF: Adresse introuvable]',        310, 25, 'cancelled', d4, null, null, now() - interval '3 day',  now() - interval '3 day'),
    ('AMX50003GHI', 'Btissam Alaoui',   '0661116603', 'Marrakech',  'Hivernage, Rue de la Liberté [INDEMNISÉ >50% MOTIF: Client refuse]', 420, 30, 'cancelled', d6, null, null, now() - interval '5 day',  now() - interval '5 day'),
    ('AMX50004JKL', 'Ghali Lahrichi',   '0661116604', 'Tanger',     'Centre, Rue Bou Arakia [INDEMNISÉ >50% MOTIF: Colis endommagé]',    265, 25, 'cancelled', d8, null, null, now() - interval '4 day',  now() - interval '4 day'),
    ('AMX50005MNO', 'Kenza Bouazza',    '0661116605', 'Fès',        'Atlas, Rue Al Andalous [MOTIF: Téléphone injoignable]',             195, 25, 'cancelled', d9, null, null, now() - interval '6 day',  now() - interval '6 day')
  ON CONFLICT (tracking_number) DO NOTHING;
END $$;

-- 3) Verify
SELECT 'drivers' AS what, count(*) FROM public.profiles WHERE role = 'driver'
UNION ALL
SELECT 'orders', count(*) FROM public.orders;
