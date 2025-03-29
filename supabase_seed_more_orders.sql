-- ============================================================================
-- Additional orders seed — appends ~55 new commandes to the existing data.
-- Uses tracking-number prefixes AMX6*, AMX7*, AMX8*, AMX9*, AMXA* to avoid
-- any conflict with the base seed (AMX1..AMX5).
--
-- Reuses the 10 seeded drivers (ids 11111111-1111-1111-1111-00000000000X).
-- Safe to re-run: ON CONFLICT (tracking_number) DO NOTHING.
-- ============================================================================

DO $$
DECLARE
  d1  uuid := '11111111-1111-1111-1111-000000000001';
  d2  uuid := '11111111-1111-1111-1111-000000000002';
  d3  uuid := '11111111-1111-1111-1111-000000000003';
  d4  uuid := '11111111-1111-1111-1111-000000000004';
  d5  uuid := '11111111-1111-1111-1111-000000000005';
  d6  uuid := '11111111-1111-1111-1111-000000000006';
  d7  uuid := '11111111-1111-1111-1111-000000000007';
  d8  uuid := '11111111-1111-1111-1111-000000000008';
  d9  uuid := '11111111-1111-1111-1111-000000000009';
  d10 uuid := '11111111-1111-1111-1111-000000000010';
BEGIN
  INSERT INTO public.orders
    (tracking_number, customer_name, customer_phone, destination_city, delivery_address, amount, driver_fee, status, assigned_driver_id, dest_latitude, dest_longitude, created_at, updated_at)
  VALUES
    -- ========================================================================
    -- DELIVERED (20 new) — mix of today, yesterday, this week, last week
    -- ========================================================================
    ('AMX60001ABC', 'Soukaina El Alami',    '0662220001', 'Casablanca', 'Maarif, Rue Soldat Bertin [COLIS_REMIS_PAR_ADMIN]',           290, 25, 'delivered', d1,  33.5751, -7.5920, now() - interval '1 day',  now() - interval '1 day'),
    ('AMX60002DEF', 'Rachid Ouarzazi',      '0662220002', 'Casablanca', 'Anfa, Bd Zerktouni [COLIS_REMIS_PAR_ADMIN]',                  510, 35, 'delivered', d2,  33.5861, -7.6291, now() - interval '2 day',  now() - interval '2 day'),
    ('AMX60003GHI', 'Nabila Lahrichi',      '0662220003', 'Casablanca', 'Sidi Maarouf, Rue Jahid [COLIS_REMIS_PAR_ADMIN]',             235, 25, 'delivered', d3,  33.5420, -7.6450, now() - interval '3 day',  now() - interval '3 day'),
    ('AMX60004JKL', 'Youssef Bennani',      '0662220004', 'Rabat',      'Hay Riad, Av Annakhil [COLIS_REMIS_PAR_ADMIN]',               445, 30, 'delivered', d4,  33.9862, -6.8711, now() - interval '1 day',  now() - interval '1 day'),
    ('AMX60005MNO', 'Oumaima Bensouda',     '0662220005', 'Rabat',      'Agdal, Rue Oued Ziz [COLIS_REMIS_PAR_ADMIN]',                 325, 25, 'delivered', d5,  34.0120, -6.8352, now() - interval '4 day',  now() - interval '4 day'),
    ('AMX60006PQR', 'Abderrahim Fassi',     '0662220006', 'Marrakech',  'Hivernage, Av de la Menara [COLIS_REMIS_PAR_ADMIN]',          395, 30, 'delivered', d6,  31.6241, -7.9962, now() - interval '2 day',  now() - interval '2 day'),
    ('AMX60007STU', 'Loubna Chraibi',       '0662220007', 'Marrakech',  'Gueliz, Rue Mauritanie [COLIS_REMIS_PAR_ADMIN]',              270, 25, 'delivered', d7,  31.6308, -7.9981, now() - interval '5 day',  now() - interval '5 day'),
    ('AMX60008VWX', 'Omar El Idrissi',      '0662220008', 'Tanger',     'Iberia, Rue Belgique [COLIS_REMIS_PAR_ADMIN]',                430, 30, 'delivered', d8,  35.7650, -5.8102, now() - interval '3 day',  now() - interval '3 day'),
    ('AMX60009YZA', 'Ikram Benjelloun',     '0662220009', 'Fès',        'Narjiss, Rue Al Massira [COLIS_REMIS_PAR_ADMIN]',             315, 25, 'delivered', d9,  34.0159, -5.0101, now() - interval '6 day',  now() - interval '6 day'),
    ('AMX60010BCD', 'Mehdi Bouchentouf',    '0662220010', 'Agadir',     'Talborjt, Rue de l''Hôpital [COLIS_REMIS_PAR_ADMIN]',         380, 30, 'delivered', d10, 30.4180, -9.5870, now() - interval '2 day',  now() - interval '2 day'),
    ('AMX60011EFG', 'Zakaria Alaoui',       '0662220011', 'Casablanca', 'Bourgogne, Rue Taha Houcine [COLIS_REMIS_PAR_ADMIN]',         260, 25, 'delivered', d1,  33.5810, -7.6180, now() - interval '5 day',  now() - interval '5 day'),
    ('AMX60012HIJ', 'Fadoua El Khatib',     '0662220012', 'Casablanca', 'Ain Sebaa, Bd Chefchaouni [COLIS_REMIS_PAR_ADMIN]',           210, 25, 'delivered', d2,  33.6150, -7.5440, now() - interval '7 day',  now() - interval '7 day'),
    ('AMX60013KLM', 'Tariq El Fassi',       '0662220013', 'Rabat',      'Hassan, Rue de la Marne [COLIS_REMIS_PAR_ADMIN]',             495, 35, 'delivered', d4,  34.0162, -6.8311, now() - interval '4 day',  now() - interval '4 day'),
    ('AMX60014NOP', 'Chaima Senhaji',       '0662220014', 'Marrakech',  'Medina, Rue de Bab Doukkala [COLIS_REMIS_PAR_ADMIN]',         340, 30, 'delivered', d6,  31.6310, -7.9912, now() - interval '6 day',  now() - interval '6 day'),
    ('AMX60015QRS', 'Imad Ouazzani',        '0662220015', 'Casablanca', 'Bd d''Anfa, Rue Sorbonne [COLIS_REMIS_PAR_ADMIN]',            560, 35, 'delivered', d3,  33.5870, -7.6422, now(),                     now()),
    ('AMX60016TUV', 'Siham El Ouali',       '0662220016', 'Tanger',     'Centre, Av Hassan II [COLIS_REMIS_PAR_ADMIN]',                280, 25, 'delivered', d8,  35.7781, -5.8098, now() - interval '1 day',  now() - interval '1 day'),
    ('AMX60017WXY', 'Jihane Rachidi',       '0662220017', 'Casablanca', 'Maarif, Rue Al Yarmouk [COLIS_REMIS_PAR_ADMIN]',              310, 25, 'delivered', d1,  33.5728, -7.5870, now() - interval '8 day',  now() - interval '8 day'),
    ('AMX60018XYZ', 'Adil Benslimane',      '0662220018', 'Rabat',      'Agdal, Rue Patrice Lumumba [COLIS_REMIS_PAR_ADMIN]',          420, 30, 'delivered', d5,  34.0125, -6.8360, now() - interval '9 day',  now() - interval '9 day'),
    ('AMX60019ZAB', 'Nouhaila Alaoui',      '0662220019', 'Fès',        'Atlas, Bd Allal El Fassi [COLIS_REMIS_PAR_ADMIN]',            265, 25, 'delivered', d9,  34.0220, -5.0050, now() - interval '10 day', now() - interval '10 day'),
    ('AMX60020BCE', 'Hamza Chakir',         '0662220020', 'Agadir',     'Centre, Av Mohamed V [COLIS_REMIS_PAR_ADMIN]',                355, 30, 'delivered', d10, 30.4230, -9.5985, now(),                     now()),

    -- ========================================================================
    -- IN TRANSIT (10 new) — currently being delivered
    -- ========================================================================
    ('AMX70001ABC', 'Soufiane Haddad',      '0663330001', 'Casablanca', 'Maarif, Rue de Normandie',             350, 25, 'in_transit', d1,  33.5720, -7.5880, now() - interval '3 hour', now() - interval '3 hour'),
    ('AMX70002DEF', 'Rania El Alami',       '0663330002', 'Casablanca', 'Anfa, Bd Ghandi',                      230, 25, 'in_transit', d3,  33.5912, -7.6400, now() - interval '2 hour', now() - interval '2 hour'),
    ('AMX70003GHI', 'Hicham Mounir',        '0663330003', 'Casablanca', 'Ain Diab, Corniche',                   415, 30, 'in_transit', d2,  33.5980, -7.6720, now() - interval '5 hour', now() - interval '5 hour'),
    ('AMX70004JKL', 'Nawal Senhaji',        '0663330004', 'Rabat',      'Agdal, Av Annakhil',                   470, 35, 'in_transit', d4,  34.0100, -6.8370, now() - interval '4 hour', now() - interval '4 hour'),
    ('AMX70005MNO', 'Mustapha Lahlou',      '0663330005', 'Rabat',      'Hassan, Av Mohammed V',                185, 25, 'in_transit', d5,  34.0160, -6.8340, now() - interval '1 hour', now() - interval '1 hour'),
    ('AMX70006PQR', 'Dounia El Khattab',    '0663330006', 'Marrakech',  'Gueliz, Rue Yougoslavie',              325, 30, 'in_transit', d6,  31.6300, -7.9980, now() - interval '2 hour', now() - interval '2 hour'),
    ('AMX70007STU', 'Younes Benchekroun',   '0663330007', 'Marrakech',  'Hivernage, Av Echouhada',              265, 25, 'in_transit', d7,  31.6270, -7.9990, now() - interval '6 hour', now() - interval '6 hour'),
    ('AMX70008VWX', 'Sanae Bennouna',       '0663330008', 'Tanger',     'Malabata, Rue Ibn Sina',               395, 30, 'in_transit', d8,  35.7840, -5.7750, now() - interval '3 hour', now() - interval '3 hour'),
    ('AMX70009YZA', 'Amal Idrissi',         '0663330009', 'Fès',        'Narjiss, Rue Ibn Rochd',               275, 25, 'in_transit', d9,  34.0200, -5.0130, now() - interval '5 hour', now() - interval '5 hour'),
    ('AMX70010BCD', 'Reda Belkadi',         '0663330010', 'Agadir',     'Centre, Rue de la Foire',              340, 30, 'in_transit', d10, 30.4220, -9.5950, now() - interval '2 hour', now() - interval '2 hour'),

    -- ========================================================================
    -- PENDING (10 new) — unassigned, waiting for a driver
    -- ========================================================================
    ('AMX80001ABC', 'Khalid El Yaakoubi',   '0664440001', 'Casablanca', 'Bourgogne, Rue Omar Slaoui',           240, 25, 'pending', null, null, null, now() - interval '15 min', now() - interval '15 min'),
    ('AMX80002DEF', 'Salima Bensaid',       '0664440002', 'Casablanca', 'Hay Hassani, Rue 42',                  175, 25, 'pending', null, null, null, now() - interval '25 min', now() - interval '25 min'),
    ('AMX80003GHI', 'Mounir Tazi',          '0664440003', 'Casablanca', 'Sidi Moumen, Rue 12',                  195, 25, 'pending', null, null, null, now() - interval '35 min', now() - interval '35 min'),
    ('AMX80004JKL', 'Rajae El Fassi',       '0664440004', 'Rabat',      'Océan, Rue Patrice Lumumba',           365, 30, 'pending', null, null, null, now() - interval '50 min', now() - interval '50 min'),
    ('AMX80005MNO', 'Ilyas Benjelloun',     '0664440005', 'Rabat',      'Hay Riad, Av Attine',                  410, 35, 'pending', null, null, null, now() - interval '1 hour', now() - interval '1 hour'),
    ('AMX80006PQR', 'Hajar Alaoui',         '0664440006', 'Marrakech',  'Sidi Ghanem, Lot 23',                  430, 35, 'pending', null, null, null, now() - interval '1 hour', now() - interval '1 hour'),
    ('AMX80007STU', 'Zouhair Mounir',       '0664440007', 'Marrakech',  'Medina, Rue Riad Zitoun',              225, 25, 'pending', null, null, null, now() - interval '2 hour', now() - interval '2 hour'),
    ('AMX80008VWX', 'Btissam Rachidi',      '0664440008', 'Tanger',     'Val Fleuri, Av Espagne',               295, 25, 'pending', null, null, null, now() - interval '2 hour', now() - interval '2 hour'),
    ('AMX80009YZA', 'Anouar Lahrichi',      '0664440009', 'Fès',        'Atlas, Rue Al Yasmine',                235, 25, 'pending', null, null, null, now() - interval '40 min', now() - interval '40 min'),
    ('AMX80010BCD', 'Souad El Ouali',       '0664440010', 'Agadir',     'Talborjt, Av Prince Moulay',           305, 25, 'pending', null, null, null, now() - interval '15 min', now() - interval '15 min'),

    -- ========================================================================
    -- ACCEPTED / WAITING AGENCY (8 new) — driver accepted, parcel not picked up yet
    -- ========================================================================
    ('AMX90001ABC', 'Rachida Ouazzani',     '0665550001', 'Casablanca', 'Maarif, Rue de Verdun [ETAT: ACCEPTE_ATTENTE_AGENCE]',        320, 25, 'accepted', d2,  null, null, now() - interval '1 hour',  now() - interval '1 hour'),
    ('AMX90002DEF', 'Brahim Chakir',        '0665550002', 'Casablanca', 'Anfa, Rue Ibnou Khaldoune [ETAT: ACCEPTE_ATTENTE_AGENCE]',    405, 30, 'accepted', d3,  null, null, now() - interval '2 hour',  now() - interval '2 hour'),
    ('AMX90003GHI', 'Ghita Bouchentouf',    '0665550003', 'Rabat',      'Agdal, Rue Ibn Sina [ETAT: ACCEPTE_ATTENTE_AGENCE]',          385, 30, 'accepted', d5,  null, null, now() - interval '2 hour',  now() - interval '2 hour'),
    ('AMX90004JKL', 'Hamid Senhaji',        '0665550004', 'Marrakech',  'Gueliz, Av Yacoub El Mansour [ETAT: ACCEPTE_ATTENTE_AGENCE]', 255, 25, 'accepted', d7,  null, null, now() - interval '3 hour',  now() - interval '3 hour'),
    ('AMX90005MNO', 'Widad El Alami',       '0665550005', 'Marrakech',  'Hivernage, Rue Harroun Rachid [ETAT: ACCEPTE_ATTENTE_AGENCE]',370, 30, 'accepted', d6,  null, null, now() - interval '1 hour',  now() - interval '1 hour'),
    ('AMX90006PQR', 'Othman Lahlou',        '0665550006', 'Tanger',     'Centre, Rue de Hollande [ETAT: ACCEPTE_ATTENTE_AGENCE]',      345, 30, 'accepted', d8,  null, null, now() - interval '2 hour',  now() - interval '2 hour'),
    ('AMX90007STU', 'Naima Idrissi',        '0665550007', 'Fès',        'Narjiss, Bd Mohammed V [ETAT: ACCEPTE_ATTENTE_AGENCE]',       265, 25, 'accepted', d9,  null, null, now() - interval '3 hour',  now() - interval '3 hour'),
    ('AMX90008VWX', 'Youssef Rachidi',      '0665550008', 'Agadir',     'Centre, Rue Oued Souss [ETAT: ACCEPTE_ATTENTE_AGENCE]',       290, 25, 'accepted', d10, null, null, now() - interval '1 hour',  now() - interval '1 hour'),

    -- ========================================================================
    -- CANCELLED (7 new) — with and without compensation motif
    -- ========================================================================
    ('AMXA0001ABC', 'Kawtar Benslimane',    '0666660001', 'Casablanca', 'Maarif, Rue Lahcen Rouaneh [MOTIF: Client absent]',                    190, 25, 'cancelled', d1,  null, null, now() - interval '2 day',  now() - interval '2 day'),
    ('AMXA0002DEF', 'Mohcine El Jadidi',    '0666660002', 'Casablanca', 'Anfa, Rue Ahmed Lamsaki [INDEMNISÉ >50% MOTIF: Client refuse livraison]', 340, 25, 'cancelled', d2,  null, null, now() - interval '3 day',  now() - interval '3 day'),
    ('AMXA0003GHI', 'Hind El Khatib',       '0666660003', 'Rabat',      'Hassan, Rue Al Bouhtouri [MOTIF: Adresse incorrecte]',                 295, 25, 'cancelled', d4,  null, null, now() - interval '4 day',  now() - interval '4 day'),
    ('AMXA0004JKL', 'Anas Bennani',         '0666660004', 'Marrakech',  'Gueliz, Rue Loubnane [INDEMNISÉ >50% MOTIF: Colis endommagé transport]', 450, 30, 'cancelled', d6,  null, null, now() - interval '5 day',  now() - interval '5 day'),
    ('AMXA0005MNO', 'Leila Chraibi',        '0666660005', 'Marrakech',  'Medina, Rue Bab Agnaou [MOTIF: Téléphone injoignable]',                215, 25, 'cancelled', d7,  null, null, now() - interval '6 day',  now() - interval '6 day'),
    ('AMXA0006PQR', 'Said Ouarzazi',        '0666660006', 'Tanger',     'Iberia, Rue Belgique [INDEMNISÉ >50% MOTIF: Client refuse]',           285, 25, 'cancelled', d8,  null, null, now() - interval '4 day',  now() - interval '4 day'),
    ('AMXA0007STU', 'Bouchra El Fassi',     '0666660007', 'Fès',        'Atlas, Rue Al Andalous [MOTIF: Annulé par le client]',                 205, 25, 'cancelled', d9,  null, null, now() - interval '5 day',  now() - interval '5 day')
  ON CONFLICT (tracking_number) DO NOTHING;
END $$;

-- ============================================================================
-- Verify
-- ============================================================================
SELECT status, count(*) AS total
FROM public.orders
GROUP BY status
ORDER BY status;

SELECT 'total orders' AS what, count(*) FROM public.orders;
