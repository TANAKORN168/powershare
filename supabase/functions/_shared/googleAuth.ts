// Minimal Google OAuth2 service-account access token generator (no external deps)
// Uses RS256-signed JWT to exchange for an access_token.

function base64UrlEncode(input: string | Uint8Array): string {
  const bytes = typeof input === 'string' ? new TextEncoder().encode(input) : input;
  let binary = '';
  for (const b of bytes) binary += String.fromCharCode(b);
  const b64 = btoa(binary);
  return b64.replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/g, '');
}

async function importPrivateKey(pem: string): Promise<CryptoKey> {
  // FIREBASE_PRIVATE_KEY typically comes with escaped newlines.
  const normalized = pem.replace(/\\n/g, '\n');
  const pemBody = normalized
    .replace('-----BEGIN PRIVATE KEY-----', '')
    .replace('-----END PRIVATE KEY-----', '')
    .replace(/\s+/g, '');

  const raw = Uint8Array.from(atob(pemBody), (c) => c.charCodeAt(0));
  return crypto.subtle.importKey(
    'pkcs8',
    raw.buffer,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  );
}

export async function getGoogleAccessToken(params: {
  clientEmail: string;
  privateKeyPem: string;
  scope: string;
}): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: 'RS256', typ: 'JWT' };
  const claimSet = {
    iss: params.clientEmail,
    scope: params.scope,
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 60 * 60,
  };

  const encodedHeader = base64UrlEncode(JSON.stringify(header));
  const encodedClaimSet = base64UrlEncode(JSON.stringify(claimSet));
  const signingInput = `${encodedHeader}.${encodedClaimSet}`;

  const key = await importPrivateKey(params.privateKeyPem);
  const signature = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    key,
    new TextEncoder().encode(signingInput),
  );

  const jwt = `${signingInput}.${base64UrlEncode(new Uint8Array(signature))}`;

  const body = new URLSearchParams({
    grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
    assertion: jwt,
  });

  const resp = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body,
  });

  const text = await resp.text();
  if (!resp.ok) {
    throw new Error(`oauth token exchange failed: ${resp.status} ${text}`);
  }

  const json = JSON.parse(text);
  if (!json.access_token) {
    throw new Error(`oauth token exchange missing access_token: ${text}`);
  }

  return json.access_token as string;
}
