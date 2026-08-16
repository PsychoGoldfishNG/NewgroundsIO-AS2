/**
 * TestRunner
 *
 * Runs suites and their cases strictly one at a time, waiting for each test to
 * call done() before starting the next. Results go to trace(), so they land in
 * the Flash IDE Output panel.
 *
 * Sequencing matters here: live tests share one Core and one session, so
 * running them concurrently would let an unlock race a medal list refresh.
 *
 * AS2 notes:
 *  - flash.utils.Timer does not exist. Watchdogs and pacing use setInterval,
 *    cancelled on the first tick to behave as one-shots.
 *  - Nothing in a callback may rely on `this`; every closure below captures
 *    `self` first.
 */
class ngiotest.TestRunner {

	//==================== PROPERTIES ====================

	/**
	 * Suites queued for execution.
	 *
	 * Named `queuedSuites`, not `suites`. An instance property whose name
	 * matches an imported package shadows that whole package for the class, and
	 * the suites live in `ngiotest.suites` - so a property called `suites` here
	 * would quietly make every class in that package unreachable from this
	 * file the day someone added an import for one.
	 */
	private var queuedSuites:Array;

	/** Shared prompt/status UI passed down to every TestContext */
	private var ui:ngiotest.TestUI;

	/** Called with (runner) when every suite has finished */
	private var onComplete:Function;

	/** Index of the suite currently running */
	private var suiteIndex:Number;

	/** Index of the case currently running inside the active suite */
	private var caseIndex:Number;

	/** The suite currently running */
	private var activeSuite:ngiotest.TestSuite;

	/** Context for the test currently running */
	private var activeContext:ngiotest.TestContext;

	/** setInterval id for the watchdog on the test currently running */
	private var timeoutIntervalId:Number;

	/** setInterval id for the pause before the next live case */
	private var pacingIntervalId:Number;

	/**
	 * Trampoline state. A synchronous test calls done() from inside its own
	 * invocation, which would otherwise recurse one stack frame deeper per test
	 * and blow the stack on a few hundred cases. Instead done() just raises a
	 * flag and the loop in pump() picks it up.
	 */
	private var pumping:Boolean;
	private var advanceRequested:Boolean;

	/** Set once the pause before the next live case has been served */
	private var paced:Boolean;

	//==================== TALLIES ====================

	public var passedCount:Number;
	public var failedCount:Number;
	public var skippedCount:Number;
	public var assertionCount:Number;

	/** Names of failed tests, repeated in the final summary */
	private var failedNames:Array;

	/** Wall-clock start, for a total duration in the summary */
	private var startedAt:Number;

	/** Wall-clock start of the case currently running */
	private var caseStartedAt:Number;

	/**
	 * Total time spent inside tests that waited on a human.
	 *
	 * Subtracted from the headline duration, because the interesting number is
	 * what the SUITE costs. A run left sitting on the live-testing prompt
	 * reported 334.9s, which reads as a slow suite rather than a distracted
	 * tester - and that figure gets used to judge whether the pacing is too high.
	 */
	private var interactiveMs:Number;

	/** Set when a suite calls abortLiveSuites(); later live suites are skipped */
	private var liveAborted:Boolean;

	/** Why the live run was abandoned, shown against every skipped case */
	private var liveAbortReason:String;

	//==================== CONSTRUCTOR ====================

	/**
	 * Every field is initialised here rather than at its declaration, because
	 * an AS2 declaration initialiser lives on the prototype until the property
	 * is first written - which for the arrays and the counters would mean one
	 * shared value across every runner ever constructed.
	 */
	public function TestRunner(ui:ngiotest.TestUI) {
		this.ui = ui;
		this.queuedSuites = [];
		this.failedNames = [];
		this.onComplete = null;
		this.suiteIndex = -1;
		this.caseIndex = -1;
		this.activeSuite = null;
		this.activeContext = null;
		this.timeoutIntervalId = 0;
		this.pacingIntervalId = 0;
		this.pumping = false;
		this.advanceRequested = false;
		this.paced = false;
		this.passedCount = 0;
		this.failedCount = 0;
		this.skippedCount = 0;
		this.assertionCount = 0;
		this.startedAt = 0;
		this.caseStartedAt = 0;
		this.interactiveMs = 0;
		this.liveAborted = false;
		this.liveAbortReason = null;
	}

	//==================== PUBLIC API ====================

	/**
	 * Queue a suite. Live suites are dropped here rather than at run time so
	 * they never appear in the report when live testing is off.
	 */
	public function addSuite(suite:ngiotest.TestSuite):Void {
		if (suite.isLive && !ngiotest.TestConfig.RUN_LIVE_TESTS) {
			return;
		}
		if (!suite.isLive && !ngiotest.TestConfig.RUN_OFFLINE_TESTS) {
			return;
		}
		queuedSuites.push(suite);
	}

	/**
	 * Abandon the rest of the live run - every live suite that has not started,
	 * and every case left in the one that is running.
	 *
	 * Two callers, for opposite reasons. The confirmation gate uses it when the
	 * user declines to go online. LiveSuite uses it when the gateway stops
	 * answering, where stopping is the entire point: the limit counts requests
	 * per window, so continuing to fire at a gateway that has already refused us
	 * spends the next window's budget too.
	 *
	 * Offline suites are unaffected, and finished suites keep their results.
	 *
	 * @param reason Shown against each skipped case. Pass null for the default.
	 */
	public function abortLiveSuites(reason:String):Void {
		liveAborted = true;
		liveAbortReason = (reason == undefined || reason == null || reason.length == 0)
		                ? "live testing was declined"
		                : reason;
	}

	/**
	 * Start running. `onComplete` receives this runner once everything is done.
	 */
	public function run(onComplete:Function):Void {
		this.onComplete = (onComplete == undefined) ? null : onComplete;
		this.startedAt = new Date().getTime();

		ngiotest.NetworkLog.resetTotals();

		ngiotest.Reporter.header("NewgroundsIO-AS2 Unit Tests");
		ngiotest.Reporter.line("Gateway:  " + ngiotest.TestConfig.gatewayUrl());
		ngiotest.Reporter.line("App ID:   " + ngiotest.TestConfig.APP_ID);
		ngiotest.Reporter.line("Cipher:   RC4  (the AS2 library does not use AES)");
		ngiotest.Reporter.line("Debug:    " + ngiotest.TestConfig.USE_DEBUG_MODE + "  (debug mode does not persist changes on the server)");
		ngiotest.Reporter.line("Offline:  " + ngiotest.TestConfig.RUN_OFFLINE_TESTS + "     Live: " + ngiotest.TestConfig.RUN_LIVE_TESTS);
		ngiotest.Reporter.blank();

		suiteIndex = -1;
		advanceSuite();
	}

	//==================== SUITE SEQUENCING ====================

	private function advanceSuite():Void {
		var self:ngiotest.TestRunner = this;

		// Let the previous suite tear down before moving on
		if (activeSuite != null) {
			var finishedSuite:ngiotest.TestSuite = activeSuite;
			activeSuite = null;
			finishedSuite.tearDown(function():Void {
				self.advanceSuite();
			});
			return;
		}

		suiteIndex++;

		if (suiteIndex >= queuedSuites.length) {
			finishRun();
			return;
		}

		activeSuite = ngiotest.TestSuite(queuedSuites[suiteIndex]);
		caseIndex = -1;

		// A gate suite may have called off the rest of the live run
		if (activeSuite.isLive && liveAborted) {
			ngiotest.Reporter.suite(activeSuite.getSuiteName());
			ngiotest.Reporter.skip("<entire suite>", liveAbortReason);
			skippedCount++;
			activeSuite = null;
			advanceSuite();
			return;
		}

		activeSuite.runner = this;

		try {
			activeSuite.build();
		} catch (buildError) {
			ngiotest.Reporter.suite(activeSuite.getSuiteName());
			ngiotest.Reporter.fail("<suite build>", ["build() threw: " + describeThrown(buildError)]);
			failedCount++;
			failedNames.push(activeSuite.getSuiteName() + " / <suite build>");
			// Skip straight past a suite that could not be assembled
			activeSuite = null;
			advanceSuite();
			return;
		}

		ngiotest.Reporter.suite(activeSuite.getSuiteName());
		showSuiteBanner();

		// Say so when a suite runs at its own pace. Otherwise a run that takes
		// 14 seconds longer than the last one looks like the gateway got
		// slower, and a green result here means nothing unless the reader knows
		// the spacing that produced it.
		if (activeSuite.isLive && activeSuite.getPacingMs() >= 0 &&
		    activeSuite.getPacingMs() != ngiotest.TestConfig.LIVE_TEST_PACING_MS) {
			ngiotest.Reporter.note("this suite is paced at " + activeSuite.getPacingMs() +
			                       "ms between cases, not the usual " + ngiotest.TestConfig.LIVE_TEST_PACING_MS + "ms");
		}

		try {
			activeSuite.setUp(function():Void {
				self.pump();
			});
		} catch (setupError) {
			ngiotest.Reporter.fail("<suite setUp>", ["setUp() threw: " + describeThrown(setupError)]);
			failedCount++;
			failedNames.push(activeSuite.getSuiteName() + " / <suite setUp>");
			activeSuite = null;
			advanceSuite();
		}
	}

	//==================== CASE SEQUENCING ====================

	/**
	 * Ask the loop to start the next test. Safe to call from inside a test: the
	 * flag is picked up by the active pump() rather than recursing.
	 */
	public function pump():Void {
		advanceRequested = true;

		if (pumping) {
			return;
		}

		pumping = true;
		while (advanceRequested) {
			advanceRequested = false;
			startNextCase();
		}
		pumping = false;
	}

	private function startNextCase():Void {
		if (activeSuite == null) {
			return;
		}

		// Space out gateway traffic. This is what currently keeps a full run
		// inside the allowance: the limit is a count per time window, so
		// spreading the run across more seconds moves requests between windows.
		// See TestConfig.LIVE_TEST_PACING_MS - it only works because it applies
		// to the whole run.
		//
		// Returning here leaves pump()'s loop with nothing to do, so it exits
		// cleanly; the interval calls pump() again once the pause is served.
		var pacing:Number = (activeSuite.getPacingMs() >= 0)
		                  ? activeSuite.getPacingMs()
		                  : ngiotest.TestConfig.LIVE_TEST_PACING_MS;

		if (activeSuite.isLive && pacing > 0 && !paced) {
			paced = true;
			startPacing(pacing);
			return;
		}
		paced = false;

		caseIndex++;

		if (caseIndex >= activeSuite.cases.length) {
			// Suite exhausted. advanceSuite() handles tearDown.
			advanceSuite();
			return;
		}

		var testCase:ngiotest.TestCase = ngiotest.TestCase(activeSuite.cases[caseIndex]);
		var self:ngiotest.TestRunner = this;

		// Stop the suite that was RUNNING when the live run was called off.
		// advanceSuite() only catches suites that have not started, so without
		// this the remaining cases here would each fire another request at a
		// gateway that has already refused us - which is what turns a short
		// rate-limit cool-off into a long one. Skipped without constructing a
		// context, so nothing can make a call.
		if (activeSuite.isLive && liveAborted) {
			ngiotest.Reporter.skip(testCase.name, liveAbortReason);
			skippedCount++;
			pump();
			return;
		}

		var context:ngiotest.TestContext = new ngiotest.TestContext(testCase.name, ui, function(finished:ngiotest.TestContext):Void {
			self.completeCase(finished);
		});
		activeContext = context;

		var timeoutMs:Number = (testCase.timeoutMs > 0) ? testCase.timeoutMs : ngiotest.TestConfig.TEST_TIMEOUT_MS;
		startTimeout(timeoutMs, context);

		// Traffic is recorded per test, so a failure dump shows only the
		// exchanges that belong to it
		ngiotest.NetworkLog.reset();

		caseStartedAt = new Date().getTime();

		try {
			testCase.fn.call(null, context);
		} catch (testError) {
			// A throw is a failure, not a crash - record it and keep going.
			//
			// Held in a local rather than read back from activeContext: a test
			// that calls done() and only then throws has already been
			// completed, which nulls activeContext. Recording against the local
			// keeps that case from turning into an error here, and the
			// isFinished guard stops it being counted twice.
			if (!context.isFinished()) {
				context.fail("threw " + describeThrown(testError));
				context.done();
			} else {
				ngiotest.Reporter.note("after done(), " + testCase.name + " threw " + describeThrown(testError));
			}
		}
	}

	/**
	 * Public only because TestContext invokes it through a closure; AS2 cannot
	 * reach a private member from a nested function. Not part of the interface.
	 */
	public function completeCase(context:ngiotest.TestContext):Void {
		// Ignore a late done() from a test that already timed out
		if (context !== activeContext) {
			return;
		}

		stopTimeout();
		activeContext = null;

		// Charged to the human, not to the suite. The whole case is counted
		// rather than just the pause - there is no way to know when the reader
		// actually looked at the screen, and a prompted test does almost nothing
		// else anyway.
		if (context.waitedForInput && caseStartedAt > 0) {
			interactiveMs += (new Date().getTime() - caseStartedAt);
		}
		caseStartedAt = 0;

		assertionCount += context.assertionCount;

		if (context.skipped) {
			skippedCount++;
			ngiotest.Reporter.skip(context.name, context.skipReason);
		} else if (context.failures.length > 0) {
			failedCount++;
			failedNames.push(activeSuite.getSuiteName() + " / " + context.name);
			ngiotest.Reporter.fail(context.name, context.failures);

			// Show what actually crossed the wire. Only on failure - doing it
			// for passes would bury the report.
			if (ngiotest.TestConfig.CAPTURE_PACKETS_ON_FAILURE && !ngiotest.NetworkLog.isEmpty()) {
				ngiotest.Reporter.packets(ngiotest.NetworkLog.dump());
			}
		} else {
			passedCount++;
			ngiotest.Reporter.pass(context.name, context.assertionCount);
		}

		for (var i:Number = 0; i < context.notes.length; i++) {
			ngiotest.Reporter.note(context.notes[i]);
		}

		if (ui != null) {
			ui.hideButton();
			// Put the banner back. Without this, whatever a prompt or a status()
			// call left on screen stays there for the rest of the run - which is
			// how the stage ended up describing something that had finished
			// several suites ago.
			showSuiteBanner();
		}

		pump();
	}

	//==================== ON-STAGE TEXT ====================

	/**
	 * Name the suite in progress, and nothing else.
	 *
	 * The on-stage field deliberately does NOT track individual tests. It used
	 * to, and the result was a line that was almost always describing work that
	 * had already finished - a test completes in milliseconds, while a person
	 * reads at human speed. The Output panel is the report; this is a sign
	 * saying which part of the run you are in.
	 *
	 * So it changes exactly twice per suite: when the suite starts, and when a
	 * test needs an answer from you.
	 *
	 * Public because advanceSuite reaches it directly and AS2 has no protected.
	 */
	public function showSuiteBanner():Void {
		if (ui == null || activeSuite == null) {
			return;
		}

		ui.setInfo(
			activeSuite.getSuiteName() + "   (" + (suiteIndex + 1) + " of " + queuedSuites.length + ")" +
			"\n\nRunning - results appear in the Output panel."
		);
	}

	//==================== TIMERS ====================

	/**
	 * Waits the given interval, then resumes the runner.
	 *
	 * Deliberately separate from the per-test watchdog: that one is armed for
	 * the case currently running, and reusing it would cancel a live test's
	 * timeout the moment the next one was queued.
	 */
	private function startPacing(milliseconds:Number):Void {
		stopPacing();

		var self:ngiotest.TestRunner = this;
		pacingIntervalId = setInterval(function():Void {
			// setInterval repeats; clear it first so this behaves as a
			// one-shot even if pump() takes longer than the interval.
			self.stopPacing();
			self.pump();
		}, milliseconds);
	}

	/** Public for the same reason as completeCase() - reached from a closure. */
	public function stopPacing():Void {
		if (pacingIntervalId != 0) {
			clearInterval(pacingIntervalId);
			pacingIntervalId = 0;
		}
	}

	private function startTimeout(milliseconds:Number, context:ngiotest.TestContext):Void {
		stopTimeout();

		var self:ngiotest.TestRunner = this;
		timeoutIntervalId = setInterval(function():Void {
			self.stopTimeout();

			if (context.isFinished()) {
				return;
			}

			// Give the test a chance to treat the timeout as a valid outcome
			if (context.onTimeout != null) {
				try {
					context.onTimeout.call(null);
				} catch (hookError) {
					context.fail("onTimeout hook threw: " + context.describeThrown(hookError));
				}
				if (context.isFinished()) {
					return;
				}
			}

			context.fail("timed out after " + milliseconds + "ms");
			context.done();
		}, milliseconds);
	}

	/** Public for the same reason as completeCase() - reached from a closure. */
	public function stopTimeout():Void {
		if (timeoutIntervalId != 0) {
			clearInterval(timeoutIntervalId);
			timeoutIntervalId = 0;
		}
	}

	//==================== COMPLETION ====================

	private function finishRun():Void {
		var totalMs:Number = new Date().getTime() - startedAt;

		// The headline figure is what the SUITE cost. Time spent waiting on a
		// person - the live-testing gate, the session hand-off choice, Passport
		// sign-in - is reported separately rather than folded in, because the
		// combined number is what gets used to judge whether the pacing is too
		// high or the run too expensive, and a distracted tester should not look
		// like a slow suite.
		var suiteSeconds:Number = Math.round((totalMs - interactiveMs) / 100) / 10;
		var elapsedSeconds:Number = Math.round(totalMs / 100) / 10;

		ngiotest.Reporter.blank();
		ngiotest.Reporter.header("Summary");
		ngiotest.Reporter.line("Passed:     " + passedCount);
		ngiotest.Reporter.line("Failed:     " + failedCount);
		ngiotest.Reporter.line("Skipped:    " + skippedCount);
		ngiotest.Reporter.line("Assertions: " + assertionCount);

		if (interactiveMs > 0) {
			var waitSeconds:Number = Math.round(interactiveMs / 100) / 10;
			ngiotest.Reporter.line("Duration:   " + suiteSeconds + "s running, plus " +
			                       waitSeconds + "s waiting for a human (" + elapsedSeconds + "s total)");
		} else {
			ngiotest.Reporter.line("Duration:   " + elapsedSeconds + "s");
		}

		// Reported because the gateway limits a count of requests within a
		// window and the suite is the only thing here that can measure its own
		// draw on that budget. Offline-only runs sit at 0 and the line is quiet.
		if (ngiotest.NetworkLog.totalRequests() > 0) {
			ngiotest.Reporter.line("Requests:   " + ngiotest.NetworkLog.totalRequests() +
			                       " gateway calls (at least - see NetworkLog.totalRequests)");
		}

		if (failedCount > 0) {
			ngiotest.Reporter.blank();
			ngiotest.Reporter.line("Failed tests:");
			for (var i:Number = 0; i < failedNames.length; i++) {
				ngiotest.Reporter.line("  - " + failedNames[i]);
			}
		}

		ngiotest.Reporter.blank();
		ngiotest.Reporter.line((failedCount == 0) ? "RESULT: ALL TESTS PASSED" : "RESULT: " + failedCount + " TEST(S) FAILED");
		ngiotest.Reporter.rule();

		if (ui != null) {
			ui.hideButton();
			ui.setInfo(
				((failedCount == 0) ? "All tests passed." : failedCount + " test(s) failed.") +
				"\n\nPassed " + passedCount + " / Failed " + failedCount + " / Skipped " + skippedCount +
				"\n\nFull results are in the Output panel."
			);
		}

		if (onComplete != null) {
			onComplete.call(null, this);
		}
	}

	//==================== HELPERS ====================

	/**
	 * Renders whatever was thrown. AS2 has no ArgumentError / RangeError, and
	 * any value at all can be thrown - the bundled JSON decoder throws a plain
	 * object - so this cannot assume an Error.
	 */
	private function describeThrown(thrown):String {
		if (thrown == null || thrown == undefined) {
			return "(nothing)";
		}

		if (thrown instanceof Error) {
			return "Error: " + thrown.message;
		}

		if (thrown.name != undefined && thrown.message != undefined) {
			return String(thrown.name) + ": " + String(thrown.message);
		}

		if (thrown.message != undefined) {
			return String(thrown.message);
		}

		return String(thrown);
	}
}
