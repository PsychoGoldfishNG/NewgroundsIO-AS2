/**
 * TestSuite
 *
 * A named group of test cases. Subclasses redefine build() and call add() once
 * per test; the runner then walks the cases in registration order.
 *
 * Suites are also the unit of "needs the network": a suite whose isLive is true
 * is skipped entirely when live testing is switched off.
 *
 * Two AS2 departures from the AS3 original, both deliberate:
 *
 *  - suiteName and pacingMs are plain methods, not implicit getters. Redefining
 *    a getter in a subclass works in AS2 but reads as an accident; a method
 *    that subclasses obviously replace is clearer, and there is no `override`
 *    keyword to signal intent either way.
 *  - add() and addSlow() are public, not protected. AS2 has no protected, and
 *    private members are not reachable from a subclass.
 */
class ngiotest.TestSuite {

	//==================== PROPERTIES ====================

	/** Registered TestCase instances, in the order they were added */
	public var cases:Array;

	/** Set true by suites that talk to the gateway */
	public var isLive:Boolean;

	/**
	 * The runner executing this suite. Assigned by TestRunner just before
	 * build() is called, so a suite can influence the rest of the run - see
	 * LiveGateSuite, which uses it to abandon the live suites.
	 */
	public var runner:ngiotest.TestRunner;

	//==================== CONSTRUCTOR ====================

	public function TestSuite() {
		// Assigned here, not at the declaration: an AS2 declaration
		// initialiser lives on the prototype, so `cases = []` up there would
		// give every suite in the run the same array.
		this.cases = [];
		this.isLive = false;
		this.runner = null;
	}

	//==================== REDEFINABLE ====================

	/**
	 * Display name for this suite. Redefine in every subclass.
	 */
	public function getSuiteName():String {
		return "Unnamed Suite";
	}

	/**
	 * Pause before each of this suite's cases, in milliseconds.
	 *
	 * Return -1 to use TestConfig.LIVE_TEST_PACING_MS like everything else.
	 * Redefine when one suite needs to be gentler than the rest.
	 *
	 * Only consulted for live suites; offline suites are never paced.
	 */
	public function getPacingMs():Number {
		return -1;
	}

	/**
	 * Register test cases here by calling add(). Called once, immediately
	 * before the suite runs, so a suite can look at global state (such as
	 * whether a user is logged in) while deciding what to register.
	 */
	public function build():Void {
		// Redefine in subclasses
	}

	/**
	 * Runs once before the suite's first test. Call done() when ready. The
	 * default implementation completes immediately.
	 */
	public function setUp(done:Function):Void {
		done.call(null);
	}

	/**
	 * Runs once after the suite's last test. Call done() when finished.
	 */
	public function tearDown(done:Function):Void {
		done.call(null);
	}

	//==================== REGISTRATION ====================

	/**
	 * Register a single test.
	 *
	 * @param name Human-readable description, shown in the report
	 * @param fn   function(t:TestContext):Void - must call t.done()
	 */
	public function add(name:String, fn:Function):Void {
		cases.push(new ngiotest.TestCase(name, fn, 0));
	}

	/**
	 * Register a test that needs longer than the default watchdog, such as one
	 * that waits on a person.
	 *
	 * @param name      Human-readable description
	 * @param timeoutMs Watchdog for this test only
	 * @param fn        function(t:TestContext):Void - must call t.done()
	 */
	public function addSlow(name:String, timeoutMs:Number, fn:Function):Void {
		cases.push(new ngiotest.TestCase(name, fn, timeoutMs));
	}
}
