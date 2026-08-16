/**
 * NetworkLog
 *
 * Records the raw JSON going to and from the gateway so a failing test can show
 * it. The runner clears the log before each test and dumps it under any [FAIL],
 * so failures carry the traffic that produced them and passes stay quiet.
 *
 * Attaches via Core.networkObserver. Nothing here runs unless attach() is
 * called, and offline suites simply produce an empty log.
 *
 * Two things it does that a plain packet trace cannot:
 *
 *  - decrypts the `secure` blob on outgoing requests. Medal unlocks and score
 *    posts are encrypted, so the interesting half of a failed unlock is
 *    normally unreadable. The suite holds the key, so it can show the plaintext
 *    the server would have seen. In AS2 that is one RC4 call - RC4 is
 *    symmetric, and the key is the same Base64 string Core was given.
 *  - pretty-prints, because a medal list on one line is not debuggable.
 */
import io.newgrounds.Core;
import io.newgrounds.encoders.JSON;
import io.newgrounds.encoders.RC4;

class ngiotest.NetworkLog {

	//==================== STATE ====================

	/** Captured entries for the current test, as {direction, detail} */
	private static var entries:Array = [];

	/** Set once attach() has installed the observer */
	private static var attached:Boolean = false;

	/**
	 * Gateway requests seen since resetTotals(), across the whole run.
	 *
	 * Separate from `entries`, which the runner clears before every test. This
	 * one survives, so the summary can report what the run actually cost - the
	 * gateway limits a count of requests within a window, and a run total is
	 * the only way to know how close the suite sits to that.
	 */
	private static var requestTotal:Number = 0;

	/**
	 * Requests that came back with nothing, since resetTotals().
	 *
	 * The signal the live suites use to decide the gateway has stopped answering.
	 * Deliberately counted HERE rather than inferred from an error code: the code
	 * for "nothing came back" is INVALID_RESPONSE, which is shared with "a 2xx
	 * whose body would not parse" - a real failure that must keep being reported
	 * as one. The observer sees the difference; the error does not.
	 */
	private static var transportFailureTotal:Number = 0;

	//==================== SETUP ====================

	/**
	 * Start recording traffic from this Core. Safe to call repeatedly.
	 */
	public static function attach(core:io.newgrounds.Core):Void {
		if (core == null || attached) {
			return;
		}

		// No `this` to capture - everything here is static, which is also why
		// the observer can be a bare function literal without the usual AS2
		// `var self = this` dance.
		core.networkObserver = function(direction:String, detail:String):Void {
			ngiotest.NetworkLog.record(direction, detail);
		};
		attached = true;
	}

	/**
	 * Forget everything captured so far. The runner calls this before each test
	 * so a failure only shows its own traffic.
	 */
	public static function reset():Void {
		entries = [];
	}

	public static function isEmpty():Boolean {
		return (entries.length == 0);
	}

	/**
	 * Zero the run-wide request count. Called once when a run starts, NOT per
	 * test - reset() deliberately leaves this alone.
	 */
	public static function resetTotals():Void {
		requestTotal = 0;
		transportFailureTotal = 0;
	}

	/**
	 * How many requests this run got no response to at all.
	 *
	 * Non-zero means the gateway stopped answering - rate limited, unreachable,
	 * or refused. Once that has happened nothing later in the run is trustworthy,
	 * which is why LiveSuite treats the first one as grounds to stop.
	 */
	public static function transportFailures():Number {
		return transportFailureTotal;
	}

	/**
	 * Gateway requests this run has made.
	 *
	 * A FLOOR, not an exact figure. It counts what the observer saw, so it
	 * misses anything the host sent before attach() - typically the session and
	 * preload calls a game makes before handing over to the runner. It also
	 * does not count Loader urls opened in the browser, which navigate rather
	 * than call the gateway.
	 */
	public static function totalRequests():Number {
		return requestTotal;
	}

	//==================== CAPTURE ====================

	/**
	 * Public only because the observer closure above has to reach it; AS2 has
	 * no way to expose a static to a nested function otherwise. Not part of the
	 * interface.
	 */
	public static function record(direction:String, detail:String):Void {
		// Counted before the buffer trim below, which drops old entries to stay
		// bounded. The total has to survive that - a run that made 180 requests
		// made 180 requests whether or not they are still shown.
		if (direction == "request") {
			requestTotal++;
		}

		// Both totals are counted before the buffer trim below, for the same
		// reason: they describe the run, not what is still on screen.
		if (direction == "error") {
			transportFailureTotal++;
		}

		// Keep the buffer bounded. A test that loops requests should not be
		// able to push the interesting first exchange out of a failure dump AND
		// flood the Output panel, so drop from the middle instead.
		if (entries.length >= ngiotest.TestConfig.MAX_CAPTURED_PACKETS) {
			entries.splice(1, 1);
		}

		entries.push({ direction: direction, detail: detail });
	}

	//==================== OUTPUT ====================

	/**
	 * Render everything captured, as lines ready for the Reporter.
	 */
	public static function dump():Array {
		var lines:Array = [];

		for (var i:Number = 0; i < entries.length; i++) {
			var entry:Object = entries[i];
			var label:String = String(entry.direction).toUpperCase();
			var body:String = String(entry.detail);

			if (entry.direction == "error") {
				lines.push("--- " + label + " ---");
				lines.push(body);
				continue;
			}

			// Name the component in the header. The log is a flat,
			// time-ordered buffer with no request/response pairing, so a call
			// still in flight when a test ends lands in the NEXT test's dump.
			// Labelling makes that obvious instead of leaving the reader to
			// notice that the first block answers a different component than
			// the one that failed.
			var componentLabel:String = describeComponents(body, entry.direction == "request");
			lines.push("--- " + label + componentLabel + " ---");

			var rendered:String = render(body, entry.direction == "request");
			var chunks:Array = rendered.split("\n");
			for (var j:Number = 0; j < chunks.length; j++) {
				lines.push(chunks[j]);
			}
		}

		return lines;
	}

	/**
	 * Extracts the component name(s) a packet concerns, as " (Medal.unlock)" or
	 * " (Medal.getList, ScoreBoard.getScores)".
	 *
	 * Returns "" when nothing can be identified - a Loader redirect, an
	 * unparseable body - rather than guessing.
	 */
	private static function describeComponents(raw:String, isRequest:Boolean):String {
		var parsed:Object;
		try {
			parsed = io.newgrounds.encoders.JSON.decode(raw);
		} catch (e) {
			return "";
		}

		if (parsed == null) {
			return "";
		}

		var names:Array = [];

		if (isRequest) {
			collectComponentNames(parsed.execute, names);
		} else {
			collectComponentNames(parsed.result, names);
		}

		if (names.length == 0) {
			return "";
		}

		return " (" + names.join(", ") + ")";
	}

	/**
	 * Pushes any `component` values found on an execute or result entry, which
	 * may be a single object or an array of them.
	 */
	private static function collectComponentNames(value, names:Array):Void {
		if (value == null || value == undefined) {
			return;
		}

		if (value instanceof Array) {
			for (var i:Number = 0; i < value.length; i++) {
				collectComponentNames(value[i], names);
			}
			return;
		}

		if (value.component != undefined && value.component != null) {
			names.push(String(value.component));
			return;
		}

		// A secure execute hides its component inside the encrypted blob, so an
		// unlock or score post would otherwise show as an unlabelled packet -
		// exactly the ones worth identifying.
		if (value.secure != undefined) {
			names.push("secure");
		}
	}

	/**
	 * Turn a raw packet into something readable: parse it, reveal any encrypted
	 * payload, pretty-print, then truncate.
	 */
	private static function render(raw:String, isRequest:Boolean):String {
		if (raw == null || raw.length == 0) {
			return "(empty)";
		}

		var parsed:Object;
		try {
			parsed = io.newgrounds.encoders.JSON.decode(raw);
		} catch (e) {
			// Not JSON at all - which is itself worth seeing verbatim, since
			// that is what an HTML error page looks like.
			return truncate(raw);
		}

		if (isRequest) {
			revealSecureExecutes(parsed);
		}

		var text:String;
		if (ngiotest.TestConfig.PRETTY_PRINT_PACKETS) {
			text = prettyPrint(parsed, 0);
		} else {
			text = io.newgrounds.encoders.JSON.encode(parsed, false);
		}

		return truncate(text);
	}

	/**
	 * Walk a request envelope and decrypt any {secure: "..."} execute entries
	 * in place, adding the plaintext alongside.
	 *
	 * Failure is deliberately quiet: the point is to help debug, and a blob we
	 * cannot read is still shown in its encrypted form.
	 */
	private static function revealSecureExecutes(envelope:Object):Void {
		if (envelope == null || envelope.execute == undefined) {
			return;
		}

		var execute = envelope.execute;

		if (execute instanceof Array) {
			for (var i:Number = 0; i < execute.length; i++) {
				revealSecureExecute(execute[i]);
			}
			return;
		}

		revealSecureExecute(execute);
	}

	private static function revealSecureExecute(item:Object):Void {
		if (item == null || item.secure == undefined || item.secure == null) {
			return;
		}

		try {
			item["secure (decrypted by the test suite)"] =
				io.newgrounds.encoders.JSON.decode(decrypt(String(item.secure)));
		} catch (e) {
			item["secure (decrypted by the test suite)"] = "<could not decrypt>";
		}
	}

	/**
	 * RC4 is symmetric and takes the Base64 key string exactly as Core was
	 * given it, so this is the whole of the AS2 decryption path - no cipher
	 * setup, no IV, no padding. The AS3 equivalent needs six lines of as3crypto.
	 */
	private static function decrypt(base64Text:String):String {
		return io.newgrounds.encoders.RC4.decrypt(base64Text, ngiotest.TestConfig.ENCRYPTION_KEY);
	}

	//==================== FORMATTING ====================

	/**
	 * Minimal JSON pretty-printer.
	 *
	 * The bundled AS2 encoder has no indent option and there is no native JSON
	 * in any player this .fla targets, so the only way to get readable output
	 * is to write it here.
	 */
	private static function prettyPrint(value, depth:Number):String {
		var pad:String = indent(depth);
		var childPad:String = indent(depth + 1);
		var parts:Array = [];
		var i:Number;

		if (value === null || value === undefined) {
			return "null";
		}

		var valueType:String = typeof(value);

		if (valueType == "string") {
			return quote(String(value));
		}

		if (valueType == "number" || valueType == "boolean") {
			return String(value);
		}

		if (value instanceof Array) {
			if (value.length == 0) {
				return "[]";
			}
			for (i = 0; i < value.length; i++) {
				parts.push(childPad + prettyPrint(value[i], depth + 1));
			}
			return "[\n" + parts.join(",\n") + "\n" + pad + "]";
		}

		var keys:Array = [];
		for (var key:String in value) {
			keys.push(key);
		}
		if (keys.length == 0) {
			return "{}";
		}
		keys.sort();

		for (i = 0; i < keys.length; i++) {
			parts.push(childPad + quote(keys[i]) + ": " + prettyPrint(value[keys[i]], depth + 1));
		}
		return "{\n" + parts.join(",\n") + "\n" + pad + "}";
	}

	private static function indent(depth:Number):String {
		var text:String = "";
		for (var i:Number = 0; i < depth; i++) {
			text += "  ";
		}
		return text;
	}

	private static function quote(text:String):String {
		var result:String = "\"";
		for (var i:Number = 0; i < text.length; i++) {
			var ch:String = text.charAt(i);
			if (ch == "\"") {
				result += "\\\"";
			} else if (ch == "\\") {
				result += "\\\\";
			} else if (ch == "\n") {
				result += "\\n";
			} else if (ch == "\r") {
				result += "\\r";
			} else if (ch == "\t") {
				result += "\\t";
			} else {
				result += ch;
			}
		}
		return result + "\"";
	}

	private static function truncate(text:String):String {
		var limit:Number = ngiotest.TestConfig.MAX_CAPTURED_PACKET_CHARS;
		if (limit <= 0 || text.length <= limit) {
			return text;
		}
		return text.substr(0, limit) +
		       "\n... [truncated, " + text.length + " chars total - " +
		       "raise TestConfig.MAX_CAPTURED_PACKET_CHARS to see it all]";
	}
}
