-- ============================================================================
-- Revert: @gmail.com → @ameex.ma for the 10 seeded drivers
-- Updates both auth.users and auth.identities.identity_data
-- Safe to re-run.
-- ============================================================================

UPDATE auth.users
SET email = replace(email, '@gmail.com', '@ameex.ma'),
    updated_at = now()
WHERE id::text LIKE '11111111-1111-1111-1111-0000000000%'
  AND email LIKE '%@gmail.com';

UPDATE auth.identities
SET identity_data = jsonb_set(
      identity_data,
      '{email}',
      to_jsonb(replace(identity_data->>'email', '@gmail.com', '@ameex.ma'))
    ),
    updated_at = now()
WHERE user_id::text LIKE '11111111-1111-1111-1111-0000000000%'
  AND identity_data->>'email' LIKE '%@gmail.com';

-- Verify
SELECT id, email FROM auth.users
WHERE id::text LIKE '11111111-1111-1111-1111-0000000000%'
ORDER BY email;
