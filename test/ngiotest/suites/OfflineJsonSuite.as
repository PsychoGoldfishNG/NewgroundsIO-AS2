/**
 * OfflineJsonSuite
 *
 * The AS2 library ships its own JSON implementation at
 * io.newgrounds.encoders.JSON and there is no native fallback question - AVM1
 * has no native JSON on any player, so this class is always what runs. The AS3
 * suite's "which implementation is active" test has no counterpart here and is
 * deliberately not ported.
 *
 * Two halves:
 *
 *  - encode() / decode(), the synchronous pair everything in the library uses.
 *  - background_encode() / background_decode(), a chunked asynchronous pair with
 *    NO AS3 counterpart. Nothing in the library calls them, which is exactly why
 *    they are tested here: unreferenced code with no tests rots quietly.
 *
 * Source stays ASCII. Non-ASCII literals in an .as file are a reliable way to
 * get mojibake out of the Output panel, so the one test that needs a non-ASCII
 * character builds it with String.fromCharCode().
 */
import io.newgrounds.encoders.JSON;

import ngiotest.TestContext;
import ngiotest.TestSuite;

class ngiotest.suites.OfflineJsonSuite extends ngiotest.TestSuite {

	public function OfflineJsonSuite() {
		super();
	}

	public function getSuiteName():String {
		return "Offline / JSON";
	}

	public function build():Void {

		var self:ngiotest.suites.OfflineJsonSuite = this;

		//==================== ENCODE / DECODE ====================

		add("round-trips scalars", function(t:ngiotest.TestContext):Void {
			self.assertRoundTrip(t, { s: "text" }, "string");
			self.assertRoundTrip(t, { n: 42 }, "integer");
			self.assertRoundTrip(t, { n: -17 }, "negative integer");
			self.assertRoundTrip(t, { n: 3.5 }, "float");
			self.assertRoundTrip(t, { b: true }, "true");
			self.assertRoundTrip(t, { b: false }, "false");
			t.done();
		});

		add("round-trips nested structures", function(t:ngiotest.TestContext):Void {
			var source:Object = {
				app_id: "1:abc",
				execute: [
					{ component: "Medal.getList", parameters: {} },
					{ component: "ScoreBoard.getScores", parameters: { id: 1, limit: 10 } }
				]
			};

			var decoded:Object = io.newgrounds.encoders.JSON.decode(
				io.newgrounds.encoders.JSON.encode(source, false)
			);

			t.assertEquals("1:abc", decoded.app_id, "top-level string");
			t.assertEquals(2, decoded.execute.length, "array length");
			t.assertEquals("Medal.getList", decoded.execute[0].component, "nested string");
			t.assertEquals(10, decoded.execute[1].parameters.limit, "deeply nested number");
			t.done();
		});

		add("escapes strings correctly", function(t:ngiotest.TestContext):Void {
			// Score tags and save data are free text, so an unescaped quote or
			// newline turns into a malformed request the gateway rejects.
			self.assertRoundTrip(t, { v: 'has "quotes"' }, "double quotes");
			self.assertRoundTrip(t, { v: "has \\ backslash" }, "backslash");
			self.assertRoundTrip(t, { v: "line1\nline2" }, "newline");
			self.assertRoundTrip(t, { v: "col1\tcol2" }, "tab");
			self.assertRoundTrip(t, { v: "carriage\rreturn" }, "carriage return");
			self.assertRoundTrip(t, { v: "" }, "empty string");
			t.done();
		});

		add("escapes every non-ASCII character, which is what keeps RC4 correct", function(t:ngiotest.TestContext):Void {
			// This is AS2-specific and load-bearing. Core.encryptObject() feeds
			// this encoder's output straight into RC4.encrypt(), whose
			// strToChars() reads the plaintext with charCodeAt - UTF-16 code
			// units, not UTF-8 bytes. Anything above U+007F left raw would be
			// XORed as the wrong value, and anything above U+00FF would push a
			// number over 255 into a byte-oriented Base64 encoder and corrupt
			// the stream outright.
			//
			// Escaping to \uXXXX here means RC4 only ever sees printable ASCII,
			// where charCodeAt and UTF-8 bytes are identical by definition.
			var eAcute:String = String.fromCharCode(0xE9);          // e-acute, U+00E9
			var cjk:String = String.fromCharCode(0x4E2D);           // U+4E2D, above U+00FF

			var encoded:String = io.newgrounds.encoders.JSON.encode({ v: "caf" + eAcute }, false);
			t.assertTrue(encoded.indexOf("\\u00e9") >= 0, "U+00E9 escaped as \\u00e9, not emitted raw");
			t.assertEquals(-1, encoded.indexOf(eAcute), "the raw character is not present");

			var wide:String = io.newgrounds.encoders.JSON.encode({ v: cjk }, false);
			t.assertTrue(wide.indexOf("\\u4e2d") >= 0, "U+4E2D escaped with four hex digits, not truncated to two");

			// And it still round-trips, because \uXXXX is plain JSON.
			t.assertEquals("caf" + eAcute, io.newgrounds.encoders.JSON.decode(encoded).v, "round-trips through decode()");
			t.assertEquals(cjk, io.newgrounds.encoders.JSON.decode(wide).v, "so does the wide character");
			t.done();
		});

		add("handles empty containers", function(t:ngiotest.TestContext):Void {
			var decoded:Object = io.newgrounds.encoders.JSON.decode(
				io.newgrounds.encoders.JSON.encode({ obj: {}, arr: [] }, false)
			);
			t.assertNotNull(decoded.obj, "empty object survived");
			t.assertNotNull(decoded.arr, "empty array survived");
			t.assertEquals(0, decoded.arr.length, "array is empty");
			t.done();
		});

		add("encodes null", function(t:ngiotest.TestContext):Void {
			var decoded:Object = io.newgrounds.encoders.JSON.decode(
				io.newgrounds.encoders.JSON.encode({ v: null }, false)
			);
			t.assertNull(decoded.v, "null survived");
			t.done();
		});

		add("parses whitespace-padded JSON", function(t:ngiotest.TestContext):Void {
			var decoded:Object = io.newgrounds.encoders.JSON.decode('  {  "a" : 1 ,  "b" : [ 1 , 2 ]  }  ');
			t.assertEquals(1, decoded.a, "value past the whitespace");
			t.assertEquals(2, decoded.b.length, "array parsed");
			t.done();
		});

		add("parses unicode escapes", function(t:ngiotest.TestContext):Void {
			var decoded:Object = io.newgrounds.encoders.JSON.decode('{"v":"caf\\u00e9"}');
			t.assertEquals("caf" + String.fromCharCode(0xE9), decoded.v, "\\u escape decoded");
			t.done();
		});

		add("parses exponent notation", function(t:ngiotest.TestContext):Void {
			// Regression test. _number() accepted an optional '-', digits, and one
			// '.' followed by digits, and had no 'e' branch at all - it stopped
			// dead at the exponent marker.
			//
			// Where that surfaced depended on position, which made one bug look
			// like three: inside an object the leftover 'e' was reported as "Bad
			// object", inside an array as "Bad array", and at the top level it was
			// silently discarded, so '1e3' decoded as 1. The last of those is the
			// two decoder defects compounding - see the trailing-content test.
			//
			// Each case runs through a helper that catches the throw, so all four
			// are reported. Inline, the first throw would end the test and hide
			// that the failure was identical in every form.
			self.assertDecodesTo(t, '{"v":1e3}', 1000, "1e3");
			self.assertDecodesTo(t, '{"v":1e-3}', 0.001, "1e-3");
			self.assertDecodesTo(t, '{"v":-2.5e2}', -250, "-2.5e2");
			self.assertDecodesTo(t, '[1e3]', 1000, "1e3 as a bare array element");
			self.assertDecodesTo(t, '{"v":1E3}', 1000, "capital E");
			self.assertDecodesTo(t, '{"v":1e+3}', 1000, "explicit + in the exponent");
			t.done();
		});

		add("round-trips a number this encoder writes in exponent form", function(t:ngiotest.TestContext):Void {
			// The reason the exponent gap mattered: this file's OWN encoder
			// produces exponent notation, so the decoder could not read back what
			// the encoder wrote.
			//
			// encode() renders numbers with String(arg), and AVM1 switches to
			// exponent form below 1e-6 and at or above 1e21. Cloud saves go
			// through this encoder, so a game storing a small float wrote a slot
			// it could never load again.
			//
			// Asserted as a round trip rather than against a literal string,
			// because the exact formatting is AVM1's business - what has to hold
			// is that decode(encode(x)) == x.
			var tiny:Number = 0.0000001;
			var encodedTiny:String = io.newgrounds.encoders.JSON.encode({ v: tiny }, false);
			t.note("0.0000001 encodes as " + encodedTiny);

			var decodedTiny:Object = io.newgrounds.encoders.JSON.decode(encodedTiny);
			t.assertEquals(tiny, decodedTiny.v, "a value below 1e-6 survives the round trip");

			var huge:Number = 1e21;
			var encodedHuge:String = io.newgrounds.encoders.JSON.encode({ v: huge }, false);
			t.note("1e21 encodes as " + encodedHuge);

			var decodedHuge:Object = io.newgrounds.encoders.JSON.decode(encodedHuge);
			t.assertEquals(huge, decodedHuge.v, "a value at 1e21 survives the round trip");

			// The boundary either side, which must NOT regress: these already
			// worked, because AVM1 writes them in plain notation.
			var plain:Number = 0.000001;
			t.assertEquals(plain,
				io.newgrounds.encoders.JSON.decode(
					io.newgrounds.encoders.JSON.encode({ v: plain }, false)).v,
				"1e-6 itself is written plainly and still round-trips");

			t.done();
		});

		add("round-trips a large timestamp without precision loss", function(t:ngiotest.TestContext):Void {
			// Unix timestamps in milliseconds exceed the 32-bit integer range.
			// AS2 has only Number, so there is no int to fall back to - but the
			// decoder builds its value with `1 * n` on a string, which is worth
			// pinning either way.
			var big:Number = 1767225600000;
			var decoded:Object = io.newgrounds.encoders.JSON.decode(
				io.newgrounds.encoders.JSON.encode({ v: big }, false)
			);
			t.assertEquals(big, decoded.v, "millisecond timestamp");
			t.done();
		});

		add("encode() honours the noquotes flag", function(t:ngiotest.TestContext):Void {
			// AS2-only: encode() takes a second argument the AS3 encoder has no
			// equivalent for. Nothing in the library passes it, so this is the
			// only thing pinning what it does.
			t.assertEquals('"plain"', io.newgrounds.encoders.JSON.encode("plain", false), "quoted by default");
			t.assertEquals('plain', io.newgrounds.encoders.JSON.encode("plain", true), "unquoted when asked");
			t.done();
		});

		//==================== REJECTING NON-JSON ====================
		//
		// Regression tests for a real defect found on the AS3 side. A cloud save
		// url that returned an HTML page - a proxy interstitial, a CDN error, a
		// captive portal - parsed to a plausible value instead of throwing.
		//
		// SaveSlot.loadData() catches parse ERRORS and reports them, so the
		// caller would have been told the load failed. It cannot catch a parse
		// that succeeds wrongly - the game just receives the wrong data.

		add("rejects an HTML page instead of parsing it", function(t:ngiotest.TestContext):Void {
			var html:String =
				"<!DOCTYPE html>\n<html>\n<head>\n\t<title>Dev Instance Switcher</title>\n" +
				"</head>\n<body>\n<h1>Select an instance</h1>\n</body>\n</html>";

			var thrown = t.assertThrows(function():Void {
				io.newgrounds.encoders.JSON.decode(html);
			}, "an HTML body is not valid JSON");

			if (thrown != null) {
				t.note(t.describeThrown(thrown));
			}
			t.done();
		});

		add("rejects other non-JSON leading characters", function(t:ngiotest.TestContext):Void {
			var samples:Array = ["<xml/>", "Not Found", "%PDF-1.4", "@", "'single quoted'"];

			for (var i:Number = 0; i < samples.length; i++) {
				// The sample is copied into a local the closure captures, rather
				// than read from the loop variable. AS2 closures capture the
				// enclosing scope, not a snapshot of it, so a closure reading `i`
				// later would see whatever the loop finished on.
				var sample:String = samples[i];
				self.assertRejects(t, sample);
			}
			t.done();
		});

		add("rejects trailing content after a valid value", function(t:ngiotest.TestContext):Void {
			// Regression test, for the same defect AS3 had and fixed.
			//
			// decode() ended at `return _value()` and never checked that the input
			// was exhausted, so a document that STARTS as valid JSON parsed and
			// the rest was discarded. An error page beginning with a digit, or a
			// truncated file followed by garbage, both land here - and unlike the
			// leading-garbage cases above, the caller got no error at all.
			//
			// Crockford's original does this check; the 2005 ActionScript port
			// dropped it.
			t.assertThrows(function():Void {
				io.newgrounds.encoders.JSON.decode("123<html>");
			}, "number followed by markup");

			t.assertThrows(function():Void {
				io.newgrounds.encoders.JSON.decode("{\"a\":1} <!DOCTYPE html>");
			}, "object followed by markup");

			t.assertThrows(function():Void {
				io.newgrounds.encoders.JSON.decode("[1,2][3,4]");
			}, "two documents concatenated");
			t.done();
		});

		add("still accepts valid documents with surrounding whitespace", function(t:ngiotest.TestContext):Void {
			// The trailing-content check, once it exists, must not reject
			// legitimate padding - servers routinely send a trailing newline.
			t.assertDoesNotThrow(function():Void {
				io.newgrounds.encoders.JSON.decode("  {\"a\":1}  \n");
			}, "leading and trailing whitespace is fine");

			var decoded = io.newgrounds.encoders.JSON.decode("\n\t[1,2,3]\r\n");
			t.assertNotNull(decoded, "and the value still comes back");
			t.assertEquals(3, decoded.length, "intact");
			t.done();
		});

		add("accepts a bare number, which is a valid JSON document", function(t:ngiotest.TestContext):Void {
			// Guard against over-correcting: rejecting non-numeric leads must not
			// start rejecting numbers at the top level.
			t.assertStrictEquals(0, io.newgrounds.encoders.JSON.decode("0"), "zero");
			t.assertStrictEquals(42, io.newgrounds.encoders.JSON.decode("42"), "positive integer");
			t.assertStrictEquals(-7.5, io.newgrounds.encoders.JSON.decode("-7.5"), "negative decimal");
			t.done();
		});

		//==================== CHUNKED ENCODER / DECODER ====================
		//
		// background_encode() and background_decode() split the work across
		// setInterval ticks so a very large object cannot lock the player up.
		// They have no AS3 counterpart and nothing in the library calls them.
		//
		// They share ONE static `busy` flag and one static `cache`, so only one
		// can be in flight at a time - which is why these tests are written to
		// skip rather than fail when a previous one has not released the flag.
		// Without that, a single hang would cascade into every case below it.

		addSlow("background_encode produces JSON decode() can read back", 8000, function(t:ngiotest.TestContext):Void {
			var source:Object = { name: "chunked", count: 3, flag: true, items: [1, 2, 3] };

			var started:Boolean = io.newgrounds.encoders.JSON.background_encode(source, function(encoded:String, elapsedMs:Number):Void {
				t.assertNotNull(encoded, "callback received a string");

				var decoded:Object = io.newgrounds.encoders.JSON.decode(encoded);
				t.assertEquals("chunked", decoded.name, "string survived");
				t.assertEquals(3, decoded.count, "number survived");
				t.assertStrictEquals(true, decoded.flag, "boolean survived");
				t.assertEquals(3, decoded.items.length, "array survived");
				t.assertEquals(2, decoded.items[1], "array contents survived");

				t.assertTrue(elapsedMs >= 0, "callback also reports how long it took");
				t.done();
			});

			if (!started) {
				t.skip("the encoder was still busy - an earlier chunked test never completed");
			}
		});

		addSlow("background_encode CONSUMES the object it is given", 8000, function(t:ngiotest.TestContext):Void {
			// Not a quirk worth preserving, but very much worth knowing: the
			// chunk encoder walks the source by DELETING each key as it emits it
			// (see getParent()). The caller's object comes back empty.
			//
			// A game encoding its save state in the background would find the
			// state gone afterwards. Pass a copy, or fix the encoder.
			var source:Object = { a: 1, b: 2 };

			var started:Boolean = io.newgrounds.encoders.JSON.background_encode(source, function(encoded:String, elapsedMs:Number):Void {
				t.assertNotNull(encoded, "encoding completed");
				t.assertEquals(0, self.countKeys(source), "every key was deleted from the caller's object");
				t.note("background_encode() is destructive - it empties the object passed to it. Pass a copy.");
				t.done();
			});

			if (!started) {
				t.skip("the encoder was still busy - an earlier chunked test never completed");
			}
		});

		addSlow("background_encode refuses a call with no callback", 8000, function(t:ngiotest.TestContext):Void {
			// Returns false rather than throwing, and - importantly - does so
			// BEFORE setting the busy flag, so a mistake here does not wedge the
			// encoder for the rest of the session.
			t.assertStrictEquals(false, io.newgrounds.encoders.JSON.background_encode({ a: 1 }, null),
				"missing callback is refused");

			// Proven by starting a real encode afterwards - and this test does
			// not finish until that encode COMPLETES. Firing it and calling
			// done() straight away would leave the shared busy flag set, and the
			// next chunked test would skip itself for a reason that had nothing
			// to do with it.
			var recovered:Boolean = io.newgrounds.encoders.JSON.background_encode({ a: 1 }, function(encoded:String, elapsedMs:Number):Void {
				t.assertNotNull(encoded, "and the encode that followed it completed");
				t.done();
			});

			if (!t.assertStrictEquals(true, recovered, "and the encoder is still usable afterwards")) {
				t.done();
			}
		});

		addSlow("background_decode rebuilds an object from a JSON string", 8000, function(t:ngiotest.TestContext):Void {
			var json:String = '{"name":"chunked","count":3,"flag":true,"items":[1,2,3]}';

			var started:Boolean = io.newgrounds.encoders.JSON.background_decode(json, function(decoded:Object, elapsedMs:Number):Void {
				if (!t.assertNotNull(decoded, "callback received an object")) {
					t.done();
					return;
				}

				t.assertEquals("chunked", decoded.name, "string decoded");
				t.assertEquals(3, decoded.count, "number decoded");
				t.assertStrictEquals(true, decoded.flag, "boolean decoded");
				t.assertEquals(3, decoded.items.length, "array decoded");
				t.assertEquals(2, decoded.items[1], "array contents decoded");
				t.done();
			});

			if (!started) {
				t.skip("the decoder was still busy - an earlier chunked test never completed");
			}
		});

		addSlow("background_decode reads exponent notation too", 8000, function(t:ngiotest.TestContext):Void {
			// background_decode has its OWN number scanner, separate from
			// decode()'s _number(), and it had the same exponent gap. Fixing only
			// decode() would have left the chunked path unable to read what the
			// chunked encoder wrote - and the two are used as a pair on exactly
			// the large cloud saves where a tiny float is most likely to appear.
			//
			// This test also covers something it does not look like it covers: it
			// is the SECOND consecutive chunked decode in this suite, and it
			// starts from inside the previous one's callback. That is the only
			// shape that triggers the decode_chunk lifecycle bug where a finishing
			// job wiped the input of the one its callback had just started. If
			// this test ever reports a null object and the output shows
			// "NaN% decoded", that bug is back - do not go looking at the
			// character set.
			var json:String = '{"tiny":1e-7,"huge":1e+21,"caps":1E3,"plain":42}';

			var started:Boolean = io.newgrounds.encoders.JSON.background_decode(json, function(decoded:Object, elapsedMs:Number):Void {
				if (!t.assertNotNull(decoded, "callback received an object")) {
					t.done();
					return;
				}

				t.assertEquals(1e-7, decoded.tiny, "negative exponent");
				t.assertEquals(1e21, decoded.huge, "positive exponent with an explicit +");
				t.assertEquals(1000, decoded.caps, "capital E");
				t.assertEquals(42, decoded.plain, "a plain number still decodes");
				t.done();
			});

			if (!started) {
				t.skip("the decoder was still busy - an earlier chunked test never completed");
			}
		});

		add("background_decode refuses a call with no callback", function(t:ngiotest.TestContext):Void {
			t.assertStrictEquals(false, io.newgrounds.encoders.JSON.background_decode('{"a":1}', null),
				"missing callback is refused");
			t.done();
		});
	}

	//==================== HELPERS ====================
	//
	// Public because the closures above reach them through `self`, and AS2
	// cannot see a private member from inside a nested function.

	public function assertRoundTrip(t:ngiotest.TestContext, source:Object, label:String):Void {
		var decoded:Object = io.newgrounds.encoders.JSON.decode(
			io.newgrounds.encoders.JSON.encode(source, false)
		);

		for (var key:String in source) {
			t.assertStrictEquals(source[key], decoded[key], label);
		}
	}

	/**
	 * Decodes `json` and compares the value at `v` (or the first array element)
	 * against `expected`, reporting a throw as a failure rather than letting it
	 * escape to the runner.
	 *
	 * The point is that one broken case does not hide the others: the runner
	 * treats an escaped throw as the end of the test.
	 */
	public function assertDecodesTo(t:ngiotest.TestContext, json:String, expected, label:String):Void {
		var decoded;

		try {
			decoded = io.newgrounds.encoders.JSON.decode(json);
		} catch (e) {
			t.fail(label + " -- decode threw " + t.describeThrown(e));
			return;
		}

		var actual = (decoded instanceof Array) ? decoded[0] : decoded.v;
		t.assertEquals(expected, actual, label);
	}

	/**
	 * Wraps one rejection assertion so the sample text is bound to this call
	 * rather than read out of a loop variable that has since moved on.
	 */
	public function assertRejects(t:ngiotest.TestContext, text:String):Void {
		t.assertThrows(function():Void {
			io.newgrounds.encoders.JSON.decode(text);
		}, "rejects <" + text + ">");
	}

	public function countKeys(source:Object):Number {
		var count:Number = 0;
		for (var key:String in source) {
			count++;
		}
		return count;
	}
}
