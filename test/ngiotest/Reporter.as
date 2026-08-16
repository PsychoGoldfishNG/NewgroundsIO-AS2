/**
 * Reporter
 *
 * All test output funnels through here so the formatting stays consistent and
 * there is exactly one place to change if the output ever needs to go
 * somewhere other than trace().
 *
 * Output is plain ASCII on purpose, and this matters more in AS2 than it did
 * in AS3: the Flash IDE Output panel and flashlog.txt are not reliably UTF-8,
 * and Flash TextFields render em-dashes, smart quotes and ellipses as boxes or
 * nothing at all. Reporter.sink can push these same lines into an on-stage
 * field, so anything emitted here has to survive that trip.
 */
class ngiotest.Reporter {

	/** Width of the ==== rules, chosen to fit the Output panel without wrapping */
	private static var RULE_WIDTH:Number = 66;

	/**
	 * Optional extra destination for every emitted line, as
	 * function(line:String):Void
	 *
	 * trace() always fires; this is in addition. Set it when the Output panel
	 * is not available - to mirror the report into an on-screen field, or to
	 * capture it from a test rig.
	 */
	public static var sink:Function = null;

	/**
	 * Emit a banner: rule, title, rule.
	 */
	public static function header(title:String):Void {
		rule();
		emit(title);
		rule();
	}

	/**
	 * Start a new suite section.
	 */
	public static function suite(name:String):Void {
		emit("");
		emit("--- " + name + " " + dashes(RULE_WIDTH - 5 - name.length));
	}

	public static function pass(name:String, assertions:Number):Void {
		emit("  [PASS] " + name + assertionSuffix(assertions));
	}

	/**
	 * Report a failure plus every assertion message that produced it.
	 */
	public static function fail(name:String, messages:Array):Void {
		emit("  [FAIL] " + name);

		if (messages == null) {
			return;
		}

		for (var i:Number = 0; i < messages.length; i++) {
			emit("         " + messages[i]);
		}
	}

	/**
	 * Print the gateway traffic captured during a failing test, indented under
	 * the failure it belongs to.
	 */
	public static function packets(lines:Array):Void {
		if (lines == null || lines.length == 0) {
			return;
		}

		emit("         --- gateway traffic for this test ---");
		for (var i:Number = 0; i < lines.length; i++) {
			emit("         | " + lines[i]);
		}
		emit("         --- end traffic ---");
	}

	public static function skip(name:String, reason:String):Void {
		emit("  [SKIP] " + name + ((reason != null && reason.length > 0) ? " -- " + reason : ""));
	}

	/**
	 * A value a test wanted surfaced in the log (server versions, user names).
	 */
	public static function note(message:String):Void {
		emit("         . " + message);
	}

	public static function line(message:String):Void {
		emit(message);
	}

	public static function blank():Void {
		emit("");
	}

	public static function rule():Void {
		emit(dashes(RULE_WIDTH));
	}

	//==================== PRIVATE ====================

	/**
	 * The single exit point for every line of output.
	 */
	private static function emit(text:String):Void {
		trace(text);

		if (sink != null) {
			try {
				sink.call(null, text);
			} catch (e) {
				// A broken sink must never take the test run down with it
			}
		}
	}

	private static function assertionSuffix(assertions:Number):String {
		if (assertions <= 0) {
			return "";
		}
		return "  (" + assertions + ((assertions == 1) ? " assertion)" : " assertions)");
	}

	private static function dashes(count:Number):String {
		var text:String = "";
		for (var i:Number = 0; i < count; i++) {
			text += "=";
		}
		return text;
	}
}
