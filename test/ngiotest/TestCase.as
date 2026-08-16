/**
 * TestCase
 *
 * A single named test. `fn` receives a TestContext and must call done() on it,
 * either synchronously or from a callback.
 */
class ngiotest.TestCase {

	/** Description shown in the report */
	public var name:String;

	/** function(t:TestContext):Void */
	public var fn:Function;

	/**
	 * Per-test override for the runner's timeout, in milliseconds.
	 * Left at 0 to use the suite-wide default from TestConfig.
	 */
	public var timeoutMs:Number;

	public function TestCase(name:String, fn:Function, timeoutMs:Number) {
		// Every field assigned here rather than at the declaration. In AS2 a
		// property initialiser lives on the prototype until the property is
		// first written, so an unassigned field would be shared by every
		// TestCase instance.
		this.name = name;
		this.fn = fn;
		this.timeoutMs = (timeoutMs == undefined) ? 0 : timeoutMs;
	}
}
