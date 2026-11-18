// QA PR #88 (BUG-QA13-UID): sub of the fake Google token vs the UID assigned by the Auth emulator.
// Run only inside the Auth emulator, through the shared-resource lock, e.g. (from backend/):
//   powershell -NoProfile -ExecutionPolicy Bypass -File ..\.farm\test-lock.ps1 -Resource firebase-emulators `
//     -Command "firebase emulators:exec --project demo-tamitu --only auth 'node <path>/verify-PR-88-uid.mjs'"
// Prints only lengths/booleans and the test `sub` values (no personal data, no secrets).
const host = process.env.FIREBASE_AUTH_EMULATOR_HOST || '127.0.0.1:9099';
const project = 'demo-tamitu';
const base = `http://${host}/identitytoolkit.googleapis.com/v1`;

// Unsigned fake token, same shape as the emulator flow in the app.
const fakeIdToken = (sub) =>
  JSON.stringify({ sub, email: `${sub}@example.com`, email_verified: true });

async function signIn(sub) {
  const r = await fetch(`${base}/accounts:signInWithIdp?key=fake-api-key`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({
      requestUri: 'http://localhost',
      postBody: `id_token=${encodeURIComponent(fakeIdToken(sub))}&providerId=google.com`,
      returnSecureToken: true,
      returnIdpCredential: true,
    }),
  });
  const j = await r.json();
  return { status: r.status, localId: j.localId };
}

const a = await signIn('qa-emulator-user');
const b = await signIn('qa-emulator-user');
const c = await signIn('qa-other-user');
console.log('signIn#1 status', a.status, 'localIdLen', a.localId?.length, 'localId==sub', a.localId === 'qa-emulator-user');
console.log('signIn#2 same sub -> same UID:', a.localId === b.localId);
console.log('other sub -> different UID:', c.localId !== a.localId);

const q = await fetch(`${base}/projects/${project}/accounts:query`, {
  method: 'POST',
  headers: { authorization: 'Bearer owner', 'content-type': 'application/json' },
  body: JSON.stringify({ returnUserInfo: true }),
});
const qj = await q.json();
console.log('accounts:query status', q.status, 'users', qj.userInfo?.length);
for (const u of qj.userInfo ?? []) {
  console.log(' rawId', u.providerUserInfo?.[0]?.rawId, 'localIdLen', u.localId.length,
    'localId matches signIn UID', u.localId === a.localId || u.localId === c.localId);
}
