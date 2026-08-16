/**
 * TestContext
 *
 * Handed to every test function. Carries the assertions, the "I'm finished"
 * signal, and access to the on-stage prompt for tests that need a human.
 *
 * Tests are async by default: the runner does not move on until done() is
 * called. Purely synchronous tests simply call done() as their last statement.
 */
import io.newgrounds.BaseObject;
import io.newgrounds.encoders.JSON;

class ngiotest.TestContext {

	//==================== CONSTANTS ====================

	/** How deep describe() will walk before printing "..." */
	private static var MAX_DESCRIBE_DEPTH:Number = 4;

	/** How many array entries or object keys describe() will print per level */
	private static var MAX_DESCRIBE_ITEMS:Number = 12;

	//==================== PROPERTIES ====================

	/** Name of the test being run, used in the report */
	public var name:String;

	/** Failure messages collected by the assert* methods */
	public var failures:Array;

	/** Informational lines a test chose to record (always shown) */
	public var notes:Array;

	/** Number of assertions that passed, for a per-test count */
	public var assertionCount:Number;

	/** Set when the test asked to be skipped rather than pass/fail */
	public var skipped:Boolean;

	/**
	 * Set when this test put a prompt on screen and waited for a click.
	 *
	 * The runner uses it to keep human think-time out of the headline duration.
	 * A run that sat on the live-testing prompt for four minutes was reporting
	 * 334.9s, which reads as a slow suite rather than a slow tester - and that
	 * number gets used to decide things like whether the pacing is too high.
	 */
	public var waitedForInput:Boolean;

	/** Reason recorded alongside a skip */
	public var skipReason:String;

	/** Shared prompt/status UI */
	public var ui:ngiotest.TestUI;

	/**
	 * Optional hook invoked instead of the default "timed out" failure when the
	 * runner's watchdog fires. Set it when a timeout is a legitimate outcome
	 * rather than a fault - a prompt nobody answered, say. The hook is expected
	 * to finish the test; if it does not, the normal failure still applies.
	 */
	public var onTimeout:Function;

	/** Invoked exactly once, when the test signals completion */
	private var onDone:Function;

	/** Guards against a test calling done() twice (common with callbacks) */
	private var finished:Boolean;

	//==================== CONSTRUCTOR ====================

	/**
	 * Note that every mutable field is assigned here rather than at its
	 * declaration. AS2 stores a declaration initialiser on the PROTOTYPE until
	 * the property is first written on the instance, so `assertionCount = 0` at
	 * the declaration would have every context incrementing one shared counter,
	 * and `failures = []` would have them all pushing into one shared array.
	 */
	public function TestContext(name:String, ui:ngiotest.TestUI, onDone:Function) {
		this.name = name;
		this.ui = ui;
		this.onDone = onDone;
		this.failures = [];
		this.notes = [];
		this.assertionCount = 0;
		this.skipped = false;
		this.skipReason = null;
		this.waitedForInput = false;
		this.onTimeout = null;
		this.finished = false;
	}

	//==================== COMPLETION ====================

	/**
	 * Signal that this test is finished. Safe to call more than once - later
	 * calls are ignored, which matters because a flaky async path can otherwise
	 * advance the runner twice and corrupt the report.
	 */
	public function done():Void {
		if (finished) {
			return;
		}
		finished = true;
		onDone.call(null, this);
	}

	/** True once done() has been honoured */
	public function isFinished():Boolean {
		return finished;
	}

	/**
	 * Abandon this test without counting it as a failure, e.g. when a
	 * precondition the test cannot control (no login) isn't met.
	 */
	public function skip(reason:String):Void {
		skipped = true;
		skipReason = reason;
		done();
	}

	//==================== ASSERTIONS ====================

	/**
	 * Record an unconditional failure.
	 */
	public function fail(message:String):Void {
		failures.push(message);
	}

	/**
	 * Record a note that shows up in the report regardless of pass/fail. Use it
	 * for server-supplied values worth eyeballing (user names, gateway
	 * versions, medal counts).
	 */
	public function note(message:String):Void {
		notes.push(message);
	}

	public function assert(condition:Boolean, message:String):Boolean {
		if (condition) {
			assertionCount++;
			return true;
		}
		failures.push(message);
		return false;
	}

	/**
	 * Compares with == rather than ===, because values arriving from JSON are
	 * frequently a different type than the literal written in the test while
	 * being the same value.
	 */
	public function assertEquals(expected, actual, message:String):Boolean {
		if (expected == actual) {
			assertionCount++;
			return true;
		}
		failures.push(message + " -- expected <" + describe(expected) + ">, got <" + describe(actual) + ">");
		return false;
	}

	public function assertStrictEquals(expected, actual, message:String):Boolean {
		if (expected === actual) {
			assertionCount++;
			return true;
		}
		failures.push(message + " -- expected strictly <" + describe(expected) + ">, got <" + describe(actual) + ">");
		return false;
	}

	public function assertNotEquals(unexpected, actual, message:String):Boolean {
		if (unexpected != actual) {
			assertionCount++;
			return true;
		}
		failures.push(message + " -- expected anything but <" + describe(unexpected) + ">");
		return false;
	}

	public function assertNotNull(value, message:String):Boolean {
		if (value !== null && value !== undefined) {
			assertionCount++;
			return true;
		}
		failures.push(message + " -- value was null/undefined");
		return false;
	}

	/**
	 * Accepts null OR undefined.
	 *
	 * Deliberately lenient, and this is more than an AS3/AS2 cosmetic
	 * difference: reading an undeclared property yields undefined in AS2 where
	 * AS3 gives null, so a test asserting "the library did not set this" would
	 * otherwise have to know which of the two it was going to get.
	 */
	public function assertNull(value, message:String):Boolean {
		if (value === null || value === undefined) {
			assertionCount++;
			return true;
		}
		failures.push(message + " -- expected null, got <" + describe(value) + ">");
		return false;
	}

	public function assertTrue(value, message:String):Boolean {
		return assertStrictEquals(true, value, message);
	}

	public function assertFalse(value, message:String):Boolean {
		return assertStrictEquals(false, value, message);
	}

	/**
	 * @param type A class reference, e.g. io.newgrounds.models.objects.Medal
	 */
	public function assertIsType(value, type, message:String):Boolean {
		if (value instanceof type) {
			assertionCount++;
			return true;
		}
		failures.push(message + " -- got <" + describe(value) + ">");
		return false;
	}

	/**
	 * Assert a value sits within a tolerance of a target. Used for clock
	 * comparisons against the server, which will never match exactly.
	 */
	public function assertWithin(expected:Number, actual:Number, tolerance:Number, message:String):Boolean {
		var difference:Number = Math.abs(expected - actual);
		if (difference <= tolerance) {
			assertionCount++;
			return true;
		}
		failures.push(message + " -- " + actual + " is " + difference + " away from " + expected + " (tolerance " + tolerance + ")");
		return false;
	}

	/**
	 * Assert that calling fn throws. Returns whatever was caught, or null.
	 *
	 * The catch is UNTYPED on purpose, and it has to be. AS2 lets any value be
	 * thrown, and the bundled JSON decoder throws a plain object literal
	 * ({name, message, at, text}) rather than an Error. A `catch (e:Error)`
	 * would not catch it, so the parser-strictness tests would report "no error
	 * was thrown" for a parser that threw perfectly well.
	 */
	public function assertThrows(fn:Function, message:String) {
		try {
			fn.call(null);
		} catch (e) {
			assertionCount++;
			return e;
		}
		failures.push(message + " -- no error was thrown");
		return null;
	}

	/**
	 * Asserts that fn runs to completion.
	 *
	 * The mirror of assertThrows, for guards that must NOT fire: one that
	 * blocks too much is as real a bug as one that blocks too little, and "it
	 * didn't throw" is otherwise an assertion no test actually records.
	 */
	public function assertDoesNotThrow(fn:Function, message:String):Void {
		try {
			fn.call(null);
			assertionCount++;
		} catch (e) {
			failures.push(message + " -- threw " + describeThrown(e));
		}
	}

	//==================== HUMAN INPUT ====================

	/**
	 * Show a message plus a button and wait for the user to click it. The
	 * button is hidden again before the handler runs.
	 */
	public function prompt(message:String, buttonLabel:String, handler:Function):Void {
		if (ui == null || !ui.hasButton()) {
			fail("Test needs the on-stage button but the .fla did not supply one");
			done();
			return;
		}
		waitedForInput = true;
		ui.setInfo(message);
		ui.showButton(buttonLabel, handler);
	}

	/**
	 * Offer the user a genuine either/or choice, using both on-stage buttons.
	 *
	 * SKIPS rather than fails when the .fla has only one button, because unlike
	 * prompt() there is no sensible default: the whole point is that the test
	 * cannot know which branch the user wants. A one-button .fla is an older
	 * stage layout, not a broken one.
	 *
	 * Exactly one handler runs - showButtons() tears both down on the first
	 * click.
	 */
	public function promptChoice(message:String, buttonLabel:String, handler:Function,
	                             buttonLabel2:String, handler2:Function):Void {
		if (ui == null || !ui.hasButton()) {
			fail("Test needs the on-stage button but the .fla did not supply one");
			done();
			return;
		}

		if (!ui.hasButton2()) {
			skip("needs the second on-stage button (inputButton2) and this .fla has only one");
			return;
		}

		waitedForInput = true;
		ui.setInfo(message);
		ui.showButtons(buttonLabel, handler, buttonLabel2, handler2);
	}

	/**
	 * Update the on-stage status text without asking for input.
	 */
	public function status(message:String):Void {
		if (ui != null) {
			ui.setInfo(message);
		}
	}

	//==================== DESCRIPTION ====================

	/**
	 * Renders anything that was thrown, which in AS2 may not be an Error.
	 */
	public function describeThrown(thrown):String {
		if (thrown == null || thrown == undefined) {
			return "(nothing)";
		}

		if (thrown instanceof Error) {
			return "Error: " + thrown.message;
		}

		// The JSON decoder's shape - worth naming, since these are the throws a
		// test is most likely to be looking at.
		if (thrown.name != undefined && thrown.message != undefined) {
			return String(thrown.name) + ": " + String(thrown.message);
		}

		if (thrown.message != undefined) {
			return String(thrown.message);
		}

		return describe(thrown);
	}

	/**
	 * Renders a value for an assertion message.
	 *
	 * Worth the effort: the default toString() gives "[object Object]" for
	 * anything structured, which turns a failed comparison into a message that
	 * says nothing at all. Models and plain objects are rendered so the failure
	 * names the actual data.
	 *
	 * DEPTH-LIMITED, AND NOT VIA JSON.encode(). The bundled encoder walks an
	 * object with for-in, which on a library model reaches `core` - and a Core
	 * points back at an AppState that points back at the Core. Encoding that
	 * recurses until the player gives up, so an assertion failure would hang the
	 * run instead of printing a message. Keys known to point back up the graph
	 * are skipped, and depth is capped.
	 */
	public function describe(value):String {
		return describeAtDepth(value, 0);
	}

	private function describeAtDepth(value, depth:Number):String {
		if (value === null) {
			return "null";
		}
		if (value === undefined) {
			return "undefined";
		}

		var valueType:String = typeof(value);

		if (valueType == "string") {
			return '"' + value + '"';
		}
		if (valueType == "number" || valueType == "boolean") {
			return String(value);
		}
		if (valueType == "function") {
			return "<function>";
		}

		if (depth >= MAX_DESCRIBE_DEPTH) {
			return "...";
		}

		// Library models know how to serialise themselves, and toJsonString()
		// walks propertyNames rather than every instance property - so it never
		// reaches `core` and cannot cycle.
		if (value instanceof io.newgrounds.BaseObject) {
			try {
				return value.objectName + " " + value.toJsonString();
			} catch (modelError) {
			}
			return "<" + value.objectName + ">";
		}

		var parts:Array = [];
		var i:Number;

		if (value instanceof Array) {
			for (i = 0; i < value.length && i < MAX_DESCRIBE_ITEMS; i++) {
				parts.push(describeAtDepth(value[i], depth + 1));
			}
			if (value.length > MAX_DESCRIBE_ITEMS) {
				parts.push("... " + (value.length - MAX_DESCRIBE_ITEMS) + " more");
			}
			return "Array(" + value.length + ") [" + parts.join(", ") + "]";
		}

		if (value instanceof Date) {
			return String(value);
		}

		var shown:Number = 0;
		for (var key:String in value) {
			if (isBackReference(key)) {
				continue;
			}
			if (shown >= MAX_DESCRIBE_ITEMS) {
				parts.push("...");
				break;
			}
			if (typeof(value[key]) == "function") {
				continue;
			}
			parts.push(key + ": " + describeAtDepth(value[key], depth + 1));
			shown++;
		}

		if (parts.length == 0) {
			// Nothing enumerable, or everything was skipped - a Core, say.
			try {
				return "<" + String(value) + ">";
			} catch (e) {
			}
			return "<unprintable>";
		}

		return "{" + parts.join(", ") + "}";
	}

	/**
	 * Property names that point back up the object graph.
	 *
	 * `core` is the one that actually cycles - every model holds one, and a Core
	 * holds an AppState holding models holding the same Core. The others are
	 * listed because they are noise in a failure message rather than because
	 * they are dangerous.
	 */
	private function isBackReference(key:String):Boolean {
		return (key == "core" || key == "parent" || key == "appState" || key == "componentModel");
	}
}
