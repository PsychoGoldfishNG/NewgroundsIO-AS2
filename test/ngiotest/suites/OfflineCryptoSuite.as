/**
 * OfflineCryptoSuite
 *
 * Verifies that Core produces ciphertext the gateway can actually read.
 *
 * The AS2 library encrypts with RC4, not AES. That makes this suite much
 * shorter than its AS3 counterpart and changes what is worth asserting:
 *
 *  - RC4 is a symmetric stream cipher, so decrypting is the same call with the
 *    same key. There is no separate cipher configuration to drift.
 *  - There is NO IV, NO block size and NO padding, so the three AS3 tests that
 *    pin those (fresh IV per call, Base64 of IV + whole blocks, padding at an
 *    exact block boundary) have no meaning here and are deliberately not
 *    ported.
 *  - RC4 is deterministic. Where the AS3 suite asserts that two encryptions of
 *    the same text DIFFER, this one asserts they MATCH - see the test below for
 *    why that is expected rather than a defect.
 *
 * If any of this drifts, the round-trip breaks here instead of turning into an
 * "encrypted object failed to decrypt" (error 201) against a live app.
 */
import io.newgrounds.Core;
import io.newgrounds.encoders.JSON;
import io.newgrounds.encoders.RC4;

import ngiotest.TestConfig;
import ngiotest.TestContext;
import ngiotest.TestSuite;

class ngiotest.suites.OfflineCryptoSuite extends ngiotest.TestSuite {

	private var core:io.newgrounds.Core;

	public function OfflineCryptoSuite() {
		super();
		this.core = null;
	}

	public function getSuiteName():String {
		return "Offline / Encryption";
	}

	public function setUp(done:Function):Void {
		// Uses the real test-app key so the ciphertext format matches what the
		// live suite will send, but makes no network calls.
		core = new io.newgrounds.Core("unit-test:crypto", ngiotest.TestConfig.ENCRYPTION_KEY, null, false);
		done.call(null);
	}

	public function build():Void {

		var self:ngiotest.suites.OfflineCryptoSuite = this;

		add("encryptData() output decrypts back to the original text", function(t:ngiotest.TestContext):Void {
			var plain:String = "Hello, Newgrounds!";
			var encrypted:String = self.core.encryptData(plain);

			if (!t.assertNotNull(encrypted, "encryptData returned a value")) {
				t.done();
				return;
			}

			t.assertNotEquals(plain, encrypted, "output is not the plaintext");
			t.assertEquals(plain, self.decrypt(encrypted), "round-trips through RC4");
			t.done();
		});

		add("encryptObject() round-trips a full component payload", function(t:ngiotest.TestContext):Void {
			var payload:Object = {
				component: "Medal.unlock",
				parameters: { id: 12345 }
			};

			var encrypted:String = self.core.encryptObject(payload);
			if (!t.assertNotNull(encrypted, "encryptObject returned a value")) {
				t.done();
				return;
			}

			var decoded:Object = io.newgrounds.encoders.JSON.decode(self.decrypt(encrypted));
			t.assertNotNull(decoded, "decrypted text parsed as JSON");
			t.assertEquals("Medal.unlock", decoded.component, "component name survived");
			t.assertEquals(12345, decoded.parameters.id, "nested parameter survived");
			t.done();
		});

		add("is deterministic - the same input gives the same ciphertext", function(t:ngiotest.TestContext):Void {
			// DELIBERATE, AND THE OPPOSITE OF THE AS3 ASSERTION. Do not "fix"
			// this to expect a difference.
			//
			// AES-CBC as the AS3 library uses it prepends a fresh random IV to
			// every message, so encrypting the same text twice produces two
			// different blobs. RC4 has no IV and no nonce: the keystream is a
			// pure function of the key, so identical plaintext always yields
			// identical ciphertext.
			//
			// That is a genuine weakness of the AS2 cipher rather than a bug in
			// the library - it is what the gateway expects for this app, and the
			// key is per-app. It is written down here so that someone reading a
			// green run knows the suite noticed.
			var plain:String = "same input every time";
			var first:String = self.core.encryptData(plain);
			var second:String = self.core.encryptData(plain);

			t.assertEquals(first, second, "two encryptions of the same text match (RC4 has no IV)");
			t.assertEquals(plain, self.decrypt(first), "first still decrypts");
			t.assertEquals(plain, self.decrypt(second), "second still decrypts");

			t.note("RC4 is deterministic and unauthenticated. Identical payloads are identifiable on the wire; " +
			       "AES-CBC in the AS3 library is not, because it prepends a random IV.");
			t.done();
		});

		add("output is Base64", function(t:ngiotest.TestContext):Void {
			// All that is left of the AS3 "IV + whole blocks" test. RC4 is a
			// stream cipher, so the ciphertext is exactly as long as the
			// plaintext and there is no block structure to assert - but it is
			// still Base64 on the wire, and a stray character there is an
			// instant error 201.
			var encrypted:String = self.core.encryptData("alphabet check");

			if (!t.assertNotNull(encrypted, "encryptData returned a value")) {
				t.done();
				return;
			}

			var legal:String = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=";
			var offender:String = null;

			for (var i:Number = 0; i < encrypted.length; i++) {
				if (legal.indexOf(encrypted.charAt(i)) < 0) {
					offender = encrypted.charAt(i);
					break;
				}
			}

			t.assertNull(offender, "every character is in the Base64 alphabet");
			t.assertEquals(0, encrypted.length % 4, "length is a whole number of Base64 quartets");
			t.done();
		});

		add("carries non-ASCII text through encryptObject()", function(t:ngiotest.TestContext):Void {
			// User names and score tags are free text, so a non-ASCII payload
			// has to survive the trip.
			//
			// It survives because of the JSON encoder, not because of RC4. The
			// encoder escapes everything outside printable ASCII to \uXXXX
			// before the cipher sees it, so RC4's charCodeAt-based strToChars
			// only ever reads values below 128 - where a UTF-16 code unit and a
			// UTF-8 byte are the same number.
			//
			// encryptData() on its own is byte-oriented and offers no such
			// protection; the library never hands it anything but encoder
			// output, and neither should anyone else.
			var eAcute:String = String.fromCharCode(0xE9);      // U+00E9
			var cjk:String = String.fromCharCode(0x65E5);       // U+65E5, above U+00FF
			var text:String = "caf" + eAcute + " - " + cjk;

			var encrypted:String = self.core.encryptObject({ tag: text });
			if (!t.assertNotNull(encrypted, "encryptObject returned a value")) {
				t.done();
				return;
			}

			var decoded:Object = io.newgrounds.encoders.JSON.decode(self.decrypt(encrypted));
			t.assertEquals(text, decoded.tag, "non-ASCII text round-trips");
			t.done();
		});

		add("handles an empty string", function(t:ngiotest.TestContext):Void {
			var encrypted:String = self.core.encryptData("");
			if (t.assertNotNull(encrypted, "empty input still produces output")) {
				t.assertEquals("", self.decrypt(encrypted), "decrypts back to empty");
			}
			t.done();
		});

		add("returns null when no key was supplied", function(t:ngiotest.TestContext):Void {
			// A missing key must fail loudly-ish rather than send plaintext
			// where ciphertext is expected.
			var keyless:io.newgrounds.Core = new io.newgrounds.Core("unit-test:nokey", "", null, false);
			t.assertNull(keyless.encryptData("secret"), "encryptData with an empty key");
			t.assertNull(keyless.encryptObject({ a: 1 }), "encryptObject with an empty key");

			var nullKey:io.newgrounds.Core = new io.newgrounds.Core("unit-test:nullkey", null, null, false);
			t.assertNull(nullKey.encryptData("secret"), "encryptData with a null key");
			t.done();
		});

		add("does not carry cipher state between calls", function(t:ngiotest.TestContext):Void {
			// The AS3 version of this test guards against a ByteArray key being
			// read to its end and left there. The AS2 hazard is different but
			// lands in the same place: RC4 keeps its S-box and key schedule in
			// STATIC arrays shared by every call, and initialize() has to reset
			// both. If it ever stopped doing so, the second call would encrypt
			// with the first call's exhausted keystream.
			//
			// Three calls, because two would still pass if the state reset only
			// on alternate calls.
			var first:String = self.core.encryptData("first call");
			var second:String = self.core.encryptData("second call");
			var third:String = self.core.encryptData("third call");

			t.assertEquals("first call", self.decrypt(first), "call 1 decrypts");
			t.assertEquals("second call", self.decrypt(second), "call 2 decrypts");
			t.assertEquals("third call", self.decrypt(third), "call 3 decrypts");
			t.done();
		});

		add("an interleaved decrypt does not disturb an encrypt", function(t:ngiotest.TestContext):Void {
			// The sharpest version of the static-state question, and the one the
			// test harness itself depends on: NetworkLog decrypts captured
			// packets while the suite keeps making calls. Both go through the
			// same static sbox.
			var a:String = self.core.encryptData("payload A");
			self.decrypt(a);
			var b:String = self.core.encryptData("payload B");

			t.assertEquals("payload A", self.decrypt(a), "A still decrypts after B was encrypted");
			t.assertEquals("payload B", self.decrypt(b), "B decrypts after an interleaved decrypt");
			t.done();
		});
	}

	//==================== HELPERS ====================

	/**
	 * Independently decrypt what Core produced.
	 *
	 * Public because the closures above reach it through `self`. This is the
	 * whole of the AS2 decryption path - RC4 is symmetric and takes the same
	 * Base64 key string Core was constructed with, decoding it internally. The
	 * AS3 equivalent needs a cipher, a padding mode and two ByteArrays.
	 */
	public function decrypt(base64Text:String):String {
		return io.newgrounds.encoders.RC4.decrypt(base64Text, ngiotest.TestConfig.ENCRYPTION_KEY);
	}
}
