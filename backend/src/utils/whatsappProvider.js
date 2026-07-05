/**
 * whatsappProvider.js
 *
 * Pluggable WhatsApp provider abstraction for bulk message dispatch.
 *
 * Supports:
 *   WHATSAPP_PROVIDER = 'twilio' | 'meta'
 *
 * If WHATSAPP_PROVIDER is not set, or the API credentials are missing,
 * the module silently falls back to "safe mock mode":
 *   — Simulates a successful send after a short delay.
 *   — Logs a clear warning so the developer knows no real message was sent.
 *   — Allows the entire feature to be tested end-to-end without credentials.
 *
 * Phone numbers are expected as 10-digit Indian mobile strings.
 * This module prefixes them with +91 before dispatching.
 */

const PROVIDER    = process.env.WHATSAPP_PROVIDER  || '';
const API_KEY     = process.env.WHATSAPP_API_KEY   || '';
const API_SECRET  = process.env.WHATSAPP_API_SECRET || '';

// ── Determine effective mode ────────────────────────────────────────────────

const isMockMode =
  !PROVIDER ||
  PROVIDER === 'mock' ||
  !API_KEY  ||
  API_KEY   === 'your_whatsapp_api_key_here' ||
  !API_SECRET ||
  API_SECRET === 'your_whatsapp_api_secret_here';

if (isMockMode) {
  console.warn(
    '[WhatsApp] ⚠️  Running in MOCK mode — no real messages will be sent. ' +
    'Set WHATSAPP_PROVIDER, WHATSAPP_API_KEY, and WHATSAPP_API_SECRET to enable real dispatch.'
  );
}

// ── Mock provider ────────────────────────────────────────────────────────────

/**
 * Mock implementation: resolves after a tiny delay to simulate network I/O.
 */
async function sendMock(toNumber, message) {
  await new Promise((resolve) => setTimeout(resolve, 50));
  console.log(`[WhatsApp MOCK] Would send to +91${toNumber}: "${message.slice(0, 60)}…"`);
  return { success: true, mode: 'mock' };
}

// ── Twilio provider ──────────────────────────────────────────────────────────

/**
 * Twilio WhatsApp Business API implementation.
 * Requires:
 *   WHATSAPP_API_KEY    = Twilio Account SID
 *   WHATSAPP_API_SECRET = Twilio Auth Token
 *   TWILIO_FROM_NUMBER  = e.g. "+14155238886" (your Twilio WhatsApp sender)
 */
async function sendTwilio(toNumber, message) {
  // Lazy-require so the app doesn't crash if twilio is not installed
  // when running in mock mode.
  let twilio;
  try {
    twilio = require('twilio');
  } catch {
    throw new Error(
      'Twilio SDK not installed. Run: npm install twilio'
    );
  }

  const client = twilio(API_KEY, API_SECRET);
  const fromNumber = process.env.TWILIO_FROM_NUMBER;
  if (!fromNumber) throw new Error('TWILIO_FROM_NUMBER env var is not set.');

  await client.messages.create({
    from: `whatsapp:${fromNumber}`,
    to:   `whatsapp:+91${toNumber}`,
    body: message,
  });

  return { success: true, mode: 'twilio' };
}

// ── Meta (Cloud API) provider ────────────────────────────────────────────────

/**
 * Meta WhatsApp Business Cloud API implementation.
 * Requires:
 *   WHATSAPP_API_KEY    = Meta permanent access token
 *   WHATSAPP_API_SECRET = Phone Number ID (from Meta dashboard)
 */
async function sendMeta(toNumber, message) {
  const https = require('https');

  const phoneNumberId = API_SECRET;
  const body = JSON.stringify({
    messaging_product: 'whatsapp',
    to:                `+91${toNumber}`,
    type:              'text',
    text:              { body: message },
  });

  await new Promise((resolve, reject) => {
    const options = {
      hostname: 'graph.facebook.com',
      path:     `/v19.0/${phoneNumberId}/messages`,
      method:   'POST',
      headers:  {
        'Authorization': `Bearer ${API_KEY}`,
        'Content-Type':  'application/json',
        'Content-Length': Buffer.byteLength(body),
      },
    };

    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => { data += chunk; });
      res.on('end', () => {
        const parsed = JSON.parse(data);
        if (parsed.error) {
          reject(new Error(parsed.error.message || 'Meta API error'));
        } else {
          resolve(parsed);
        }
      });
    });

    req.on('error', reject);
    req.write(body);
    req.end();
  });

  return { success: true, mode: 'meta' };
}

// ── Public API ───────────────────────────────────────────────────────────────

/**
 * Send a WhatsApp message to a single recipient.
 *
 * @param {string} toNumber  - 10-digit Indian mobile number (no country code)
 * @param {string} message   - Plain-text message body
 * @returns {Promise<{ success: boolean, mode: string }>}
 */
async function sendMessage(toNumber, message) {
  if (isMockMode) return sendMock(toNumber, message);

  switch (PROVIDER.toLowerCase()) {
    case 'twilio': return sendTwilio(toNumber, message);
    case 'meta':   return sendMeta(toNumber, message);
    default:
      console.warn(`[WhatsApp] Unknown provider "${PROVIDER}", falling back to mock.`);
      return sendMock(toNumber, message);
  }
}

module.exports = { sendMessage, isMockMode };
