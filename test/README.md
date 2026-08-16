# NewgroundsIO-AS2 test suite

224 tests across 19 suites — 226 across 20 when a remembered login is found and
`LiveSignOutSuite` joins the run. Covers the class library in `../build`. It does
**not** test the drag-and-drop components in `../src` — only the code a
developer talks to directly (`NGIO`, `Core`, the models, the helpers).

Ported from `../../NewgroundsIO-AS3/test`, which is a verified reference: all
of its tests pass against the live gateway. Where the two suites disagree, the
disagreement is deliberate and the AS2 test says why in a comment — see
[Where AS2 differs](#where-as2-differs-from-as3).

> **Runs green.** There is no ActionScript 2 compiler on this machine, so the
> Flash IDE is the only way to check this. The first compile and the first run
> each turned up one defect — both in the library, not the tests — and the two
> JSON failures that were red by design are now fixed. See [Status](#status) for
> the last recorded run and for what has changed since it.

## Running it

Open **`NgioUnitTest.fla`** in Flash Professional (CS5 or newer) and press
**Ctrl+Enter**. Results appear in the **Output** panel.

That's it. The .fla's first frame is just:

```actionscript
import initiator.NgioUnitTest;
initiator.NgioUnitTest.startTests(this);
```

with AS2 class paths set to `.` and `..\build`.

### Before the first live run

Publish Settings → Flash → **Local playback security** must be
**"Access network only"**. The .fla currently ships set to *Access local files
only*, which silently blocks every gateway request when you test from the IDE.
The offline suites don't care; the live ones will all fail without it.

If every test in `Live / Gateway` fails at once, check this before anything
else.

### What you'll be asked to do

The run is unattended until the live tests start. Then the on-stage buttons
appear up to three times:

1. **"Run live tests"** — a confirmation, so you can read the offline results
   first. Ignore it for 90 seconds and the live suites are skipped cleanly.
2. **"Keep my login" / "Sign out and test it"** — shown **only if a remembered
   login was found**. Keeping it is the default and an unanswered prompt lands
   there, so you can ignore this one safely. See
   [The one state that cannot be manufactured](#the-one-state-that-cannot-be-manufactured).
3. **"Open Newgrounds sign-in"** — opens Passport in your browser. Approve the
   app and come back; the suite polls until it sees the session and carries on
   by itself. Already signed in, this one passes without asking.

You do **not** need to re-lock the medal between runs. `TestConfig.USE_DEBUG_MODE`
is on by default, so the gateway validates unlocks and score posts normally
without committing them.

## Layout

```
test/
  NgioUnitTest.fla            the entry point you open
  initiator/NgioUnitTest.as   wiring: finds the stage objects, registers suites
  ngiotest/
    TestConfig.as             every knob: credentials, toggles, timeouts
    TestRunner.as             sequential async runner + watchdog
    TestContext.as            assertions, done(), prompt(), promptChoice()
    TestSuite.as / TestCase.as
    TestUI.as                 drives infoText and both button/label pairs
    Reporter.as               output formatting
    NetworkLog.as             per-test packet buffer, printed under [FAIL]
    LiveSuite.as              base for gateway suites; shared NGIO.init(),
                              session parking, checkSession throttle wait
    suites/                   the tests themselves
```

There is no `build-tests.ps1` and no standalone entry point, unlike the AS3
suite. Both exist there because `mxmlc` can build AS3 from the command line;
nothing equivalent builds ActionScript 2, so the IDE is the only route.

## The suites

Registration order in `initiator/NgioUnitTest.as` is deliberate: offline first
(fastest, most precise failures), then gateway connectivity, then login, then
everything that depends on a session.

### Offline — no network, no login (135 tests)

| Suite | What it pins down |
|---|---|
| `OfflineBaseObjectSuite` | Import/export for every model: defaults on omitted fields, nested and `array-of-X` casting, error payloads, required-property validation. Also pins the two places AS2 behaves differently from AS3 — no type coercion on import, and dead `parent` / `parentPropertyName` |
| `OfflineObjectFactorySuite` | Walks the full inventory — 11 objects, 25 components, 25 results — so a model added to the codebase but not to the factory's switch fails here rather than silently returning null |
| `OfflineJsonSuite` | `io.newgrounds.encoders.JSON` round-trips: escapes, unicode, big timestamps. Pins the non-ASCII escaping the RC4 path depends on. Also covers the **chunked** `background_encode` / `background_decode` pair, which has no AS3 counterpart and nothing in the library calls |
| `OfflineCryptoSuite` | **Decrypts what `Core` encrypted**, independently, through the same RC4 the server uses. Rewritten rather than ported — see [RC4, not AES](#rc4-not-aes) |
| `OfflineWireFormatSuite` | Builds the exact gateway envelope and reads canned server replies through the real importer. Confirms secure components serialise to `{secure:...}` only, `debug` is omitted when off, unknown result types are skipped, and results sync into `AppState`. Also drives `Core.forwardHTTPResponse` with a failing status, which is the only offline coverage of the transport's error path. The best value per line in the whole suite |
| `OfflineModelSuite` | Hand-written model behaviour: `toString`, session clearing, `ScoreBoard.getScores` argument validation, `Errors` codes, `AppState` status derivation, and `HttpStatusHelper` |
| `OfflineForeignGuardSuite` | The write guards on objects loaded from another app. Confirms `unlock`, `postScore`, `saveData`, `saveDataRaw` and `clearData` all throw on a foreign object — and that the reads (`loadDataRaw`, `getScores`, including `social`) and every local object are left alone |

### Live — real gateway (89 tests, 91 with the sign-out suite)

The first suites walk the **session states in order**, and the order is the
whole point — each tests something only reachable before the next has run. See
[Session states](#session-states).

| Suite | Needs login? | Notes |
|---|---|---|
| `LiveGateSuite` | no | The confirmation prompt. Registers two cases, runs exactly one |
| `LiveGatewaySuite` | no | ping, version, server time, host license, custom event. **Read this first when a live run goes wrong** — if ping fails, nothing below matters |
| `LiveSignOutSuite` | — | **Only present when a remembered login exists.** Asks whether to sign out; if you do, ends your real login, checks the stored id is gone, and proves the server rejects the ended session. Keeping it is the default |
| `LiveNoSessionSuite` | no | No session at all. Proves the sixteen components that never touch a session work that way — a medal list on a title screen — and that the session-gated ones are refused with `[102] Missing required session_id`. Also loads the medal and scoreboard lists later suites reuse |
| `LiveSessionSuite` | — | Proves a session can be obtained at all, before anything depends on one |
| `LiveGuestSuite` | no | A real session id with no user attached. Reads stay open; writes and per-user queries are refused with `[110] User is not logged in` — a *different* code from the no-session case, which is why these are two suites. Also where `App.endSession` is covered without a prompt |
| `LiveSignInSuite` | — | The Passport flow. Split out of `LiveSessionSuite` so the guest suite can sit between them. Also checks the session id reaches local storage when — and only when — the server sets `remember` |
| `LiveAppDataSuite` | partly | Batch-loads medals/scoreboards/save slots, checks counts against `TestConfig`, verifies lookup-by-id returns cached instances |
| `LiveMedalSuite` | yes | The encrypted `Medal.unlock` path, repeat unlocks, unknown-id rejection, and that an unlock does not touch its neighbours |
| `LiveScoreBoardSuite` | yes | `postScore` (also encrypted), plus every documented `getScores` filter **including `social`**. Also probes the server's own `limit` clamping and `skip` handling through `callComponent`, since the model throws before those can reach the gateway |
| `LiveCloudSaveSuite` | yes | Write, read back over HTTP, structured round-trip, clear |
| `LiveCrossAppSuite` | partly | Reads another app's data via the `app_id` parameter, proves it cannot reach this app's caches, and checks that a foreign board forwards its `app_id` (and accepts a `social` filter) on reads while a foreign medal refuses to unlock |
| `LiveLoaderSuite` | no | Resolves all five Loader URLs using the non-redirect form, so it doesn't open browser tabs |

Tests needing a user report `[SKIP]` rather than `[FAIL]` when you run as a
guest, so a guest-only run still reads cleanly.

### Session states

There are three, and they behave differently. Only the third had live coverage
before:

| State | `hasSession()` | `hasUser()` | Suite | A session-gated call is refused with |
|---|---|---|---|---|
| No session at all | false | false | `LiveNoSessionSuite` | `[102] Missing required session_id` |
| Guest session | **true** | false | `LiveGuestSuite` | `[110] User is not logged in` |
| Signed in | true | true | everything after `LiveSignInSuite` | — it succeeds |

**A single run covers all three, on any machine, whatever you are logged into.**
No prompt, no state-dependent skips, and no need to clear anything by hand.
Neither suite waits for a run that happens to be in the right state — each
creates it:

| Suite | How it gets there | Cost |
|---|---|---|
| `LiveNoSessionSuite` | `setUp` **parks** the session `AppState` restored, `tearDown` puts it back | Nothing sent; no session ended |
| `LiveGuestSuite` | Parks any login, then asks the gateway for a **real guest session**; ends it; restores the parked login | 3 extra gateway calls |

Parking is purely local and entirely honest: the request envelope is built from
`appState.session.id`, so clearing that id reproduces exactly the wire condition
being tested — a request with no `session_id`. Your login is never ended and
never leaves the machine. `stashSession()` / `restoreSession()` on `LiveSuite`
do it, and they clear the whole session object rather than just the id so
`hasUser()` goes false too — otherwise the `keepAlive` interval fires a ping
into the window that was just opened.

Guest state cannot be faked that way. *"This session has no user"* is a
judgement the **server** makes, so a locally-faked guest session would still be
signed in as far as the gateway is concerned and every refusal test would fail.
Hence the real guest session.

**This is also why `App.endSession` no longer needs a prompt.** It is tested on
the throwaway guest session the suite just created, so nobody's login is at
stake.

**The two refusal codes differ, and that is the empirical case for two suites
rather than one.** With no session there is no `session_id` in the envelope to
check, so the gateway reports a missing parameter; with a guest session the id is
present and belongs to nobody. Same call, same component, two genuinely different
answers — both asserted, since both are documented `Errors` constants rather than
transient server conditions.

**Why parking was necessary at all.** The suite used to rely on finding a
naturally session-free window between `init()` and the first `checkSession()`.
`init()` fires only `App.logView`, and the `keepAlive` interval returns early
unless `hasUser()`, so nothing in the library opens a session on its own — but
`AppState` picks one up during construction from either of two pre-authorised
sources:

1. **A remembered session in the SharedObject** (`ngio`), checked **first**. This
   is the usual case when testing locally. It does **not** set
   `preauthenticatedId`.
2. **`ngio_session_id` on the page URL**, checked only if there was no saved one.
   This is how Newgrounds hands a logged-in session to an embedded game, and it
   **does** set `preauthenticatedId`.

Those are the two common cases — a developer with a remembered login, and a game
embedded on Newgrounds — so on exactly the machines people test on there was no
window, and the whole suite reported permanent skips. This file used to tell you
to clear the `ngio` SharedObject by hand to get around that. **You no longer need
to**; parking makes the window on demand.

Sixteen of the twenty-five components never touch a session, and games use them
that way — a medal list or high score table on a title screen, before anyone
signs in. Nothing proved that worked until now, because every other live suite
runs after the session exists.

**The guard is server-side, not client-side.** `BaseComponent.hasValidProperties()`
checks `requiresSession` and would reject these calls before they left the
machine — but **nothing in `build/` ever calls it**. Confirmed by grep: the only
callers are in the offline tests. So the request goes out and comes back refused,
and the offline test *a session-gated component is invalid without a session*
pins a method the library never consults at runtime. Both are worth having;
neither should be mistaken for the other.

Note also that `hasValidProperties()` demands `session.user`, not just a session
id — so by its own definition a guest session does not satisfy `requiresSession`.

#### Two tests that could never run

`LiveMedalSuite` → *refuses a session-gated unlock when signed out* and
`LiveCloudSaveSuite` → *refuses cloud saves when signed out* were both removed.
Each guarded itself with "skip if signed in" while sitting in a suite registered
*after* sign-in, so both reported `[SKIP] this path cannot be reached` on every
run a developer actually does. Coverage on paper only.

What they meant to test now lives in the two suites above, where it is
reachable — and split across the two states, which behave differently.

#### The one state that cannot be manufactured

**Signing out.** A remembered login requires a human to have signed in through
Passport, so `LiveSignOutSuite` cannot create its own precondition the way the
other two do. Instead it is **registered only when local storage actually holds a
session id** — checked before `NGIO.init()`, since the storage helpers are plain
statics — so a machine with no remembered login simply does not see the suite,
rather than seeing it skip.

When it is present it **asks**, using both on-stage buttons, and keeping your
login is the default (an unanswered prompt lands there). Sign out and you get
three things nothing else covers:

- `App.endSession` against a **real, signed-in, remembered** session rather than
  the throwaway guest one `LiveGuestSuite` creates;
- proof the stored session id is actually removed, so the next launch does not
  auto-login. `LiveGuestSuite` cannot assert this, because it restores your login
  afterwards and the library may re-save the id when the server re-verifies it;
- **proof `endSession` reached the server at all.** It hands its callback nothing
  and clears local state regardless of the reply, so every other assertion about
  it describes the client. The follow-up case puts the dead id back and confirms
  the gateway refuses to honour it.

It runs first, so the rest of the run then exercises the fresh-machine path —
including a genuine Passport sign-in, which you will have to complete.

The other half of that contract is in `LiveSignInSuite`: *saves the session id
locally when the server says remember* checks the id reaches the SharedObject
when — and only when — `session.remember` is true. When `remember` is false it
**skips** rather than asserting the inverse, because
`finalizeSessionPersistenceState` only ever *writes* on true and never clears on
false, so an id found in storage during a `remember=false` run may be a
legitimate leftover from an earlier login. The skip states which answer the
server gave.

This needs **`inputButton2` / `inputButtonLabel2`** on the stage. They are
optional — a .fla with only one button skips the sign-out prompt with a reason
and runs everything else. `promptChoice()` skips rather than fails for that
reason: unlike a single prompt there is no sensible default, because the entire
point is that the harness cannot guess which branch you want.

### Ending a session

Two library behaviours the guest and sign-out suites pin, both shared with AS3
rather than AS2 quirks:

- `endSession()` passes its callback **nothing** — no result, no error — so
  inspecting local state afterwards cannot tell you whether the *server* honoured
  it. `LiveSignOutSuite` is the one place that settles it, by offering the ended
  id back and confirming the gateway refuses it.
- `NgioAuthHelper` calls `appState.clearSession()` **synchronously**, right after
  dispatching the component rather than inside its callback, so the local
  session is already gone by the time the callback runs. That is why the client
  looks signed out whether or not the request ever landed.

And one trap worth knowing outside the tests: `checkSession` is throttled to one
server call every 3 seconds, and inside that window it answers locally **without
starting a new session**. A game that calls `endSession()` and immediately
`checkSession()` gets no session and a misleading `UNVERIFIED`. The tests wait
`TestConfig.SESSION_THROTTLE_WAIT_MS` (via `LiveSuite.afterThrottle()`) for
exactly this reason — it is not padding.

## Configuration

Everything lives in `ngiotest/TestConfig.as`. ActionScript 2 has no `const`, so
these are `static var` by necessity — nothing in the suite writes to them.

| Setting | Default | Effect |
|---|---|---|
| `RUN_OFFLINE_TESTS` | `true` | |
| `RUN_LIVE_TESTS` | `true` | `false` drops all live suites, including the prompt |
| `LIVE_TEST_PACING_MS` | `750` | Pause between **live** cases. Offline suites are never paced. Temporarily raised from `100` to stay inside the gateway allowance — see [Pacing](#pacing-temporary), and drop it back once the server-side limit is updated |
| `LOADER_PACING_MS` | `-1` | Pause before each **Loader** case only. `-1` uses the normal pace; kept as the worked example of `TestSuite.getPacingMs()` |
| `SESSION_THROTTLE_WAIT_MS` | `4000` | How long to wait before a `checkSession` that must genuinely reach the server. `NgioAuthHelper` throttles it to one server call every 3s, and answers locally *without starting a session* inside that window. `LiveSuite.afterThrottle()` is the shared wait |
| `USE_DEBUG_MODE` | `true` | Gateway validates without committing. Turn off only to verify persistence — then expect to re-lock the medal on the server |
| `REQUIRE_LOGIN` | `true` | `false` skips the Passport prompt and everything needing a user |
| `CONFIRM_BEFORE_LIVE` | `true` | `false` goes straight online |
| `APP_ID` / `ENCRYPTION_KEY` | AS2 test app | Unpublished app `59735:NNSlBwZV`, used only for this suite. The key is **RC4**, not AES |
| `TEST_SAVE_SLOT_ID` | `1` | Cloud save tests write here and clear it afterwards |

The expected counts (`EXPECTED_MEDAL_COUNT` and friends) are asserted against,
so if the test app's configuration changes on Newgrounds, update them here.

### App configuration, confirmed 2026-08-15

`CUSTOM_EVENT` (`ngio_unit_test`), `CUSTOM_REFERRAL` (`my_referral`, aimed at
`https://www.newgrounds.io`) and the three medals were all checked against the
project settings. `AUDIT/05-information-for-testing.md` still describes this app
as "largely set up the same" as the AS3 one without listing its event and
referral names — worth correcting there.

One limit survives confirmation: **a passing custom-event test does not prove the
event was recorded.** The gateway accepts undefined event names silently by
design, so the test can only show the component round-tripped. It is
`CUSTOM_EVENT` being correct that makes the event land, not the assertion.

A wrong **referral** name *is* reported by the gateway, so that test asserts
properly.

### Testing against a development gateway

`Core.GATEWAY_URL` is a `public static var` in AS2, not a `const` as in AS3 — so
a development host can be selected at runtime instead of editing library source.
`TestConfig.applyGatewayOverride()` is the place for it, called by `LiveSuite`
before `NGIO.init()`. It ships with the assignment commented out, and **no
development hostname is committed anywhere in this suite**.

Remember the app credentials have to change with the host: the development
environment has its own database and its own app ids. The runner prints the
gateway in force in its header, so a report always records which server produced
it.

## Where AS2 differs from AS3

The harness design is carried over wholesale. These are the places the *tests*
had to change, all of them asserted and commented rather than glossed over.

### RC4, not AES

`Core.encryptData()` calls `io.newgrounds.encoders.RC4.encrypt(text, key)`,
where the key is the Base64 string passed straight through. RC4 is symmetric, so
the suite decrypts with one call rather than six lines of as3crypto.

Three AS3 crypto tests are **not** ported because they are AES-specific and
meaningless here: *"uses a fresh IV for every call"*, *"output is Base64 of IV +
whole cipher blocks"*, and *"pads correctly at an exact block boundary"*.

One is **inverted**. RC4 has no IV, so identical plaintext produces identical
ciphertext; where the AS3 suite asserts two encryptions *differ*, this one
asserts they *match*, and the test explains why so nobody "fixes" it later.

Non-ASCII text survives encryption because the **JSON encoder escapes it to
`\uXXXX` before RC4 sees it**, not because RC4 handles it. `RC4.strToChars()`
reads UTF-16 code units with `charCodeAt`, and the Base64 encoder underneath is
byte-oriented — anything above U+00FF would corrupt the stream outright.
`OfflineJsonSuite` pins the escaping; `OfflineCryptoSuite` pins the round-trip
through `encryptObject`.

### AS2 does not coerce on assignment

`BaseObject.importFromObject()` assigns through `this[propertyName]`. In AS3
that coerces to the declared slot type, so importing `{id: "42"}` leaves
`medal.id` as the **number** 42. AVM1 has no typed slots at all, so AS2 stores
the string.

It hides easily — the value still compares equal with `==` — until something
does arithmetic on it and `"5" + 1` is `"51"`. The test asserts the real
behaviour and notes the difference.

### Closures do not capture `this`

Every callback in the suite captures `var self = this` first. This is the single
largest source of port bugs in AS2 and the reason a number of helper methods
that would be `private` or `protected` in AS3 are `public` here — AS2 has no
`protected`, and its `private` is not reachable from a nested function or a
subclass.

### Other language substitutions

| AS3 | AS2 |
|---|---|
| `flash.utils.Timer` | `setInterval` / `clearInterval`, cleared on the first tick for one-shots |
| `addEventListener(MouseEvent.CLICK, fn)` | `button.onRelease = fn`, assigned to **both** the button and its label |
| `catch (e:Error)` | untyped `catch (e)` — the JSON decoder throws a plain object, which a typed catch would miss entirely |
| `override`, `const`, `for each`, `int` | none of these |
| default parameter values | not supported; every call passes every argument |
| `suiteName` / `pacingMs` getters | `getSuiteName()` / `getPacingMs()` methods |

Two AS2 hazards produced their own regression tests, because both are silent:

- **`Array.indexOf` does not exist.** It returns `undefined`, so `== -1` is
  never true and `!= -1` always is. See [Library changes](#library-changes).
- **Property initialisers live on the prototype** until the property is first
  written on an instance. A `var x:Array = []` at the declaration is shared by
  every instance of that class. Everything mutable in the harness is assigned in
  a constructor for this reason, and `OfflineWireFormatSuite` has a test that two
  `Core`s do not share one `AppState`'s loaded-data record.

## Coverage notes

### Medal count (resolved)

The AS2 test app had **one** medal where the AS3 app has three, which cost a
real test: with a single medal there is no second, still-locked medal to check,
so "the unlock landed on the right medal" and "the unlock did nothing" produce
identical observations.

Two medals were added on 2026-08-15 and `LiveMedalSuite`'s *"unlocking one medal
does not unlock another"* now runs. It still guards on
`TestConfig.EXPECTED_MEDAL_COUNT` and skips itself with a reason if the app is
ever reduced again — medal count is server-side configuration that can change
without anyone touching this repo.

### `BaseObject.parent` is dead

`parent` and `parentPropertyName` are declared on `BaseObject` in **both**
libraries and documented in the wiki as "set when a model is nested during
import". Nothing anywhere ever assigns them — verified by grepping the whole
build tree.

`getFullObjectName()` depends on them, so it silently never produces a
hierarchical name. `OfflineBaseObjectSuite` asserts the behaviour that actually
exists (a flat name) and notes why, rather than asserting the documented
behaviour and failing for a reason that has nothing to do with AS2. The
properties should be either wired up or removed; that decision has not been
made.

## Reading the output

```
--- Offline / Encryption ==========================================
  [PASS] encryptData() output decrypts back to the original text  (3 assertions)
  [FAIL] is deterministic - the same input gives the same ciphertext
         two encryptions of the same text match (RC4 has no IV) -- expected <...>
  [SKIP] posts a score -- needs a signed-in user
         . gateway version 3.0.0
```

Lines beginning `.` are notes — values pulled from the server that are worth
eyeballing but aren't assertions. The summary at the end lists every failed test
by name, and reports a `Requests:` total for any run that touched the network.

`Duration:` splits human wait-time out of the headline figure:

```
Duration:   58.2s running, plus 276.7s waiting for a human (334.9s total)
```

The first number is what the **suite** costs, and it is the one to judge pacing
and run cost by. Anything that put a prompt on screen — the live-testing gate,
the sign-out choice, Passport sign-in — is charged to the second. A run
left sitting on the confirmation button used to report the combined figure, which
reads as a slow suite rather than a distracted tester. Offline-only runs print a
single number.

### What the on-stage text shows

`infoText` names the **suite** in progress and nothing finer:

```
Live / Sign-in   (11 of 20)

Running - results appear in the Output panel.
```

It changes exactly twice per suite: when the suite starts, and when a test needs
an answer from you — after which the banner comes straight back.

This is deliberate. It used to update per test, which sounds more informative and
was not: a test finishes in milliseconds while a person reads at human speed, so
the line on screen was almost always describing work that had already finished,
and a prompt or status message would sit there for the rest of the run. The
Output panel is the report; the stage is a sign saying which part of the run you
are in.

`TestContext.status()` still exists for the one case that earns it — telling you
the suite is polling after you have clicked through to Passport — but it is not a
progress display, and the runner overwrites it when the case ends.

## Debugging a failure

**A failing live test prints the JSON it exchanged with the gateway**, right
under the failure:

```
  [FAIL] unlocks a medal
         unlock accepted by the server -- gateway returned [202] Requested Medal does not exist...
         --- gateway traffic for this test ---
         | --- REQUEST (secure) ---
         | {
         |   "app_id": "59735:NNSlBwZV",
         |   "debug": true,
         |   "execute": {
         |     "secure": "Ux9k2b...==",
         |     "secure (decrypted by the test suite)": {
         |       "component": "Medal.unlock",
         |       "parameters": { "id": 0 }
         |     }
         |   },
         |   "session_id": "..."
         | }
         --- end traffic ---
```

Three things make this useful:

- **Only failures print traffic.** Passing tests stay quiet, and the log is
  cleared before each test, so you see only the exchanges that test caused.
- **Encrypted payloads are decrypted.** `Medal.unlock` and `ScoreBoard.postScore`
  go out as an opaque `secure` blob. The suite holds the key, so it shows the
  plaintext the server would have seen. In the example above, that immediately
  reveals the real bug: `"id": 0`, not a 202 problem at all.
- **Non-JSON responses print verbatim**, which is what you want when the server
  returns an HTML error page instead of JSON.

> **Check the component name in the header before trusting a packet.** The log
> is a flat, time-ordered buffer that is cleared at the start of each test — it
> does not pair requests with responses. A call still in flight when a test ends
> lands in the *next* test's dump, so a failure can show a packet that has
> nothing to do with it. Each block is labelled `--- RESPONSE (Gateway.getVersion) ---`
> for exactly this reason. Encrypted calls show as `(secure)`, since the
> component name is inside the blob; the decrypted body appears in the packet
> itself.

Offline failures print no traffic (they make no requests), but assertion
messages render models and objects rather than `[object Object]`, so the
expected/actual comparison names the actual data. That rendering is
depth-limited and skips `core` / `parent` / `appState` deliberately: those point
back up the object graph, and walking them would recurse until the player gave
up — turning a failed assertion into a hang.

### Knobs

| `TestConfig` setting | Default | Effect |
|---|---|---|
| `CAPTURE_PACKETS_ON_FAILURE` | `true` | Attach traffic to failing tests |
| `TRACE_ALL_PACKETS` | `false` | Trace every packet as it happens, pass or fail (`Core.debugNetworkCalls`). Noisy, but useful when a failure won't reproduce |
| `PRETTY_PRINT_PACKETS` | `true` | Indent captured JSON; off gives one-line packets |
| `MAX_CAPTURED_PACKET_CHARS` | `4000` | Per-packet truncation. Raise it for full medal lists; `0` disables |
| `MAX_CAPTURED_PACKETS` | `12` | Packets retained per test |

## Rate limiting

The gateway rate limits by request **count** over a time window. The specific
thresholds are deliberately not documented here — they are operational settings,
and publishing them mostly helps someone work out what they can get away with.

What matters for running these tests: a full run is dense enough to approach the
limit, and the AS3 suite has at times been refused on its own final request with
an HTTP 429. That is a property of the suite's size, not a defect — no real game
produces traffic like this. The summary reports a `Requests:` total for any run
that touched the network, so if the suite grows the cost stays visible.

A 429 near the end of a run is therefore expected rather than a regression. If
it happens, wait a short while before re-running rather than retrying
immediately. **If the count grows much further, split the run** rather than
asking for more allowance.

It is **not tied to any component**: the failure follows whichever call happens
to be last in the run, which for a long time made the `Loader` suite look guilty
when it was simply at the end. If you find yourself explaining a 429 by what the
failing call does, check where it sits in the run first.

### Pacing (temporary)

`TestConfig.LIVE_TEST_PACING_MS` is **750ms**, set at the gateway owner's
direction to keep a full run inside the current allowance until the server-side
limit is updated. **Drop it back to 100 once that ships.**

What is known, since this is worth tuning from evidence rather than feel:

| Pacing | Result |
|---|---|
| 100ms | ~60 requests in ~25s — **refused on request 60** (2026-08-15) |
| 1200ms | 71 requests, no refusal (2026-08-16) |
| 750ms | 75 and 78 requests, no refusal on either (2026-08-16, two runs) |

Lowering it is low-risk to try. Since [the run stops itself](#the-run-stops-itself)
at the first dead request, guessing too low costs a short burst of honest skips
rather than a cascade of failures and false passes.

**Pacing dominates the runtime.** At 1200ms it accounted for roughly 102s of a
~120s suite run — the actual work is closer to 20s. At 750ms it is ~68s of a
measured 99.5s run (90 live cases), so pacing is still two thirds of the clock.

This corrects something this file previously claimed. The earlier note said
pacing could not help because the limit counts requests rather than measuring a
rate. That was the wrong lesson drawn from a real experiment: slowing the
**Loader suite alone** changed nothing, because the fifty-odd requests before it
were just as densely packed and had already filled the window. The limit is a
count *per time window*, so spreading the **whole run** across more seconds does
move requests between windows. Pacing one suite at the end cannot; pacing
everything can.

Two honest limits on it:

- It paces **cases, not calls**. A test making three gateway calls still bursts
  them. This run averages close to one call per case, which is why per-case
  pacing is a good enough approximation.
- It paces **every live case**, including ones that skip or make no request at
  all — roughly a sixth of them. That is wasted time rather than protection.
  Pacing only after a case that actually touched the network would cost less for
  the same request density; `NetworkLog.totalRequests()` already provides the
  before/after figure needed to do it.
- It does not reduce the request count, so it is a way of staying under the
  limit, not of making the suite cheaper. If the count grows much further, split
  the run.

That `Requests:` figure is a **floor**. It counts what the network observer saw,
so it misses any session or preload calls made before the runner started, and it
does not count Loader urls, which navigate rather than call the gateway.

### The run stops itself

The first request that comes back with nothing ends the live run. `LiveSuite`
skips that test, notes why, and calls `TestRunner.abortLiveSuites()`, which skips
every remaining live case — both in the suites that have not started and in the
one that was running.

Stopping is the point, not a tidy-up. The limit counts requests per window, so
continuing to fire at a gateway that has already refused spends the **next**
window's budget as well, turning a short cool-off into a long one. For the same
reason, do not re-run immediately after a stopped run.

The signal is `NetworkLog.transportFailures()` — an observer-level count of
requests that got no response — plus an explicit `TOO_MANY_REQUESTS` when the
player managed to report a real 429. It is deliberately **not** inferred from the
error code alone: `INVALID_RESPONSE` covers both "nothing came back" and "a 2xx
whose body would not parse", and the second is a real failure that must keep
being reported as one.

### Why this matters more than it looks: the false passes

A rate-limited run does not simply fail. It **passes tests it should not**, and
that is what the stop is really protecting against.

Any test asserting an *absence* or an *error* goes green when the request never
lands — a cache is empty because nothing loaded, a call "was rejected" because it
never arrived. A rate-limited run on 2026-08-15 passed six such tests on 31
assertions:

| Test | Passed on | What it should have shown |
|---|---|---|
| `foreign save slots never enter the local cache` | 12 assertions | the load failed, so the cache was trivially empty |
| `foreign medals never enter the local cache` | 9 | same |
| `refuses an app that has not granted access` | 5 | `[0] Access denied for external app id`, not a transport error |
| `a foreign scoreboard never enters the local board cache` | 3 | same as the other cache tests |
| `the same board without the stamp is rejected` | 1 | `[203] The scoreboard id (5853) does not match…` |
| `reports an unconfigured referral` | 1 | a real gateway rejection |

The three cache tests are the worst of them: 24 assertions that are at their
most confident exactly when the network is most broken. Stopping at the first
dead request is what keeps that from being reported as a green run.

Confirmed on the run that followed. Reaching the gateway before the limit, those
same tests reported real answers for the first time — `[103] Invalid custom URL
name`, `[0] Access denied for external app id`, `[203] The scoreboard id (5853)
does not match any scoreboards for this app` — where the rate-limited run had
accepted a transport error in place of each one.

**Known hole.** The guard lives in `assertNoError`, so it only fires for tests
that assert a call *succeeded*. A test that expects an error and never calls it —
`reports an unconfigured referral`, `refuses an app that has not granted access` —
can still pass on a transport failure if it is the first test to meet the dead
gateway. In practice something else usually trips the stop first, but if you are
hardening one of those tests, have it check `isTransportFailure(error)` before
concluding the gateway rejected anything.

## Server-side conditions — do not chase these

Failures you may hit that are **not** the suite's fault. Every one was seen on
the AS3 suite, diagnosed, and is either already patched upstream or deliberate.
`AUDIT/05-information-for-testing.md` carries the full record.

**Score `limit` is not clamped on production.** The gateway is supposed to clamp
`limit` into 1–100, and does on the development branch. On production as of
2026-08-14 it passes `limit` through unchanged and returns an **empty list** for
`limit: 0`. `TestConfig.SERVER_CLAMPS_SCORE_LIMIT` is `false` by default: the
three probes still run and report what the server did, but skip instead of
failing. Flip it when the clamp ships.

The library's own 1–100 rejection is correct either way, and matters *more*
before the clamp exists — without it, `limit: 0` silently returns nothing at all.

**The echoed `skip` was one higher than requested.** Fixed on the development
branch; no NGIO library reads the value back. The test asserts the contractual
part — a large skip is accepted and not capped — and emits a note when the echo
differs. The note disappearing is how the deploy gets noticed.

**Deliberate, not defects.** All confirmed with the API owner:

- Undefined custom event names fail silently (legacy support).
- `Loader.loadMoreGames` and `Loader.loadNewgrounds` return production
  newgrounds.com urls on every environment — they are hardcoded site-wide links,
  not app links. Only the official and author urls follow the environment.
- Official and author urls are per project and editable by the author, so they
  are not guaranteed to sit on a Newgrounds domain at all. That is why the
  domain assertion lives in `TestConfig.SITE_DOMAIN`.
- Medals report 0 points until unlocked once outside debug mode.
- `debug_backtrace` in error responses is development-environment only.

## Library changes

Five changes were made to `../build` while building this suite.

### The diagnostics hook

Capturing traffic needed one small addition, mirroring the AS3 side:

- `io/newgrounds/Core.as` — new `networkObserver:Function` property and a
  `reportNetworkActivity()` method
- `io/newgrounds/helpers/CoreTransportHelper.as` — calls it at the five points
  that already honoured `debugNetworkCalls`

It is inert unless something attaches an observer, and independent of
`debugNetworkCalls`. It is also useful outside the tests — a game can pipe
gateway packets into its own logger with it. If you'd rather not carry it,
reverting those two files just means `CAPTURE_PACKETS_ON_FAILURE` has nothing to
record; nothing else in the suite depends on it.

### `HttpStatusHelper`

`io/newgrounds/helpers/HttpStatusHelper.as` is new, ported from AS3 so
`OfflineModelSuite` has its counterpart to test and so both libraries answer the
same question the same way.

`Core.onHTTPResponse` now calls it at both of its error branches, and
`CoreTransportHelper` now captures a real HTTP status when one is available. It
previously called `Errors.getError(statusCode)`, which treated the HTTP status
**as** an Errors code — see
[What the first complete run found](#what-the-first-complete-run-found) for what
that produced.

**Report the true status when we have one, `UNKNOWN_STATUS` when we don't.**
`LoadVars.onHTTPStatus` exists in Flash Player 8+ but only fires when the host
supplies a code — in the standalone player and the IDE test movie, usually never,
or with 0. So the transport captures it when it can and reports
`UNKNOWN_STATUS` otherwise, rather than synthesising 500.

| Situation | Status forwarded | Error code | Message |
|---|---|---|---|
| Body arrived, status known | the real status | per `codeForStatus` | names the status |
| Body arrived, no status | 200 | — parsed normally | — |
| No body, status known | the real status | e.g. 429 → `TOO_MANY_REQUESTS` | names the status |
| No body, no status | `UNKNOWN_STATUS` (0) | `INVALID_RESPONSE` (505) | *"…failed, and no HTTP status was reported"* |

The last row is the common one in AS2, and it is the behaviour change: that case
used to report `SERVER_ERROR` (500) with *"An unexpected error has occurred on
the server. If error persists, contact support."* A dropped connection, a blocked
domain and a rate limit all land there, and none of them are the server failing.

**This diverges from AS3**, which falls back to 500 when no status is reported
rather than to `UNKNOWN_STATUS`. AS3 gets a real status far more often, so the
fallback matters less there — but the two libraries now answer differently for
the same situation, and aligning them means changing AS3 to match.

One AS2-only consequence worth knowing: AS3's `COMPLETE` only fires for a 2xx, so
it never sees a body attached to an error status. `LoadVars.onData` hands over the
body whatever the status, so a genuine non-2xx that carried a body is now reported
as the error it was, instead of being parsed as though it had succeeded.

### The JSON decoder

`io/newgrounds/encoders/JSON.as` is vendored — a 2005 ActionScript port of
Crockford's `json.js`, not generated from `src/templates`, so it has no
propagation set. It had two decoder defects, both of which AS3 hit and fixed in
`NGJSON`; the AS2 copy never got the fix. Three changes:

**1. `_number()` had no exponent branch.** It read an optional `-`, digits, and
one `.` with digits, then stopped dead at an `e`.

This was not a theoretical gap: **the library could not decode its own output.**
`encode()` renders numbers with `String(arg)`, and AVM1 switches to exponent form
below `1e-6` and at or above `1e21`. So `0.0000001` was written as `1e-7` and
then failed to load. Cloud saves go through this encoder, which made it a
data-loss path for any game storing a small float. Inbound risk was much lower —
the gateway's numeric fields are integers and `exec_time` arrives quoted.

Where it surfaced depended on position, which made one bug look like three:

- `{"v":1e3}` → `_number()` returned `1`, then `_object()` wanted `,` or `}`,
  found `e` → **"Bad object"**
- `[1e3]` → the same from `_array()` → **"Bad array"**
- a bare `1e3` → returned **`1`**, silently discarding `e3`

**2. `decode()` never checked the input was exhausted.** It ended at
`return _value()`, so `{"a":1}<html>…` parsed and returned `{a:1}`. Crockford's
original does the check and the 2005 port dropped it. That is the shape of a
proxy interstitial or a PHP notice appended after a real response — the case
where trusting the first half is worst. It is also why the bare `1e3` above was
silent rather than an error: with nothing checking for leftovers, there was
nothing to object.

**3. `background_decode()` has its own number scanner** with the same gap —
`valid` is now `"01234567890.-eE+"`. Fixing only `decode()` would have left the
chunked path unable to read what the chunked *encoder* writes, and the two are
used as a pair on exactly the large saves where a tiny float is likeliest.

**4. `decode_chunk()` wiped the input of a job its own callback had started.**
Found while fixing 3, and much the more serious of the two.

`cache.arg = ""` ran *after* the callback. By then `busy` was already false, so a
callback was free to start another `background_decode()` — which replaces the
static `cache` wholesale. The clear therefore emptied the **new** job's input.
That job then saw `pos (0) >= arg.length (0)`, declared itself complete without
reading a character, traced *"NaN% decoded"* from the `0/0`, and handed its
callback an undefined root.

Two consecutive chunked decodes is all it takes, with the second started from the
first's callback — which is what a test suite does, and what any queue of saves
would do. `encode_chunk()` had the same shape and got the same fix; there the
result has to be captured before clearing, since it is the value being handed
over rather than spent input.

This one cost a run to find. The character-set change in 3 was made, blamed for
the `NaN%` failure, reverted, and then reinstated unaltered once the real cause
was isolated by transliterating `chunk_decoder` into JavaScript and running it —
where the scanner decoded `1e-7`, `1e+21` and `1E3` correctly, proving the fault
lay outside it.

Four tests cover this area: *parses exponent notation* (six forms),
*round-trips a number this encoder writes in exponent form* (the round trip that
motivated it, plus the `1e-6` boundary that must not regress),
*background_decode rebuilds an object from a JSON string*, and
*background_decode reads exponent notation too* — the last two being consecutive
on purpose, since that adjacency is what exercises the lifecycle fix.

### `NgioExternalAppHelper.call()` renamed to `dispatch()`

Not a behaviour change - it simply could not compile. See
[What the first compile found](#what-the-first-compile-found).

### The three layers a request can fail at

Worth stating plainly, because **most of the error-reporting bugs found during
this work were the same mistake**: checking one layer and assuming it covered
the others.

| Layer | Where it shows | Meaning |
|---|---|---|
| 1. **Transport** | no HTTP response, or a non-2xx | Nothing reached the gateway, or nothing came back. No component ran |
| 2. **Envelope** | `response.success !== true`, `response.error` | The request as a whole was rejected — bad app id, malformed body, unparseable reply. No component ran |
| 3. **Component** | `result.success !== true`, `result.error` | *This* component failed. Others in the same envelope may have succeeded |

Layer 3 exists because **an envelope can carry several components at once**, so
"did it work?" is not one question — it is one question per component, and the
answer has to say *where*. `loadData(['medals','saveSlots'])` as a guest returns
a perfectly successful envelope in which one component worked and the other was
refused.

`AppState.resultErrors()` returns `{component, error}` pairs for exactly this
reason; `firstResultError()` is the convenience wrapper `loadData` uses to keep
its `(appState, error)` callback signature. Properties that loaded are still
cached, so `hasLoaded()` answers "what actually arrived".

Every one of these was a single-layer check that missed another:

| Fixed in | Was checking | Missed |
|---|---|---|
| `NgioLoaderHelper.loadUrl` | result only | a failed request has no result at all → `(null, null)` |
| `AppState.loadData` | envelope only | a refused component inside a successful envelope |
| `Core.onHTTPResponse` | — | reported transport failures as a *server* error |

### `AppState.loadData` swallowed component-level errors

Found by `LiveGuestSuite` on its first run, and **not AS2-only** — check AS3.

`loadData`'s callback inspected `response.error` and nothing else. But a request
can succeed while an individual *component* inside it is refused, and that is the
ordinary shape of "you are not logged in":

```json
{"success":true,"result":[{"component":"CloudSave.loadSlots","data":{
  "success":false,"error":{"code":110,"message":"User is not logged in."}}}]}
```

Response-level success, component-level refusal. The caller got
`(appState, null)` — no data and no reason. `NGIO.loadSaveSlots`,
`NGIO.loadMedalScore` and `NGIO.loadAppData` all inherit it, so a game asking for
save slots while signed out would read the silence as *"this user has no saves"*
rather than *"this user is not signed in"*.

Fixed with `AppState.firstResultError()`, which handles both response shapes
(`result` for one component, `resultList` for a batch) and falls back to
`INVALID_RESPONSE` when a component reports `success:false` with no error object
— otherwise the silent failure just returns by another route.

Batches report the **first** error, which keeps the callback signature unchanged.
Properties that did load are still cached, and `hasLoaded()` distinguishes them.

This is the same defect already fixed in `NgioLoaderHelper.loadUrl`,
`Medal.unlock` and `ScoreBoard.getScores` — *"a failed load surfaces at either of
two levels, and both have to be checked"*. `loadData` was the one that got
missed. Four offline tests now pin it, plus two live guest tests that assert the
specific code 110.

### Two AppState bugs

Both are AS2-only, both were silent, and neither exists in the AS3 library.

**`Array.indexOf` does not exist in AVM1.** `AppState` used it in five places to
validate property names. It returns `undefined`, so `undefined == -1` never
fired the throw and `undefined != -1` was always true. The observable results:

- `hasLoaded(anything)` returned **true**, for data that had never been loaded
- `markLoaded()` returned early every time and recorded **nothing**
- `loadData()` accepted property names that do not exist

Replaced with a private linear search, `indexOfValue()`.

**`dataLoaded` lived on the prototype.** Its only initialiser was at the
declaration, so every `AppState` pushed `markLoaded()` names into one shared
array. A game with a single `Core` would never notice; this suite builds one per
test, and would have failed by run order. Now assigned in the constructor.

`OfflineWireFormatSuite` and `OfflineModelSuite` both carry regression tests for
these.

## Writing a test

```actionscript
add("does the thing", function(t:ngiotest.TestContext):Void {
    t.assertEquals(expected, actual, "what should be true");
    t.done();                       // required, sync or async
});
```

Tests are async by default — the runner waits for `done()` and applies a
20-second watchdog (`TestConfig.TEST_TIMEOUT_MS`). For something slower, or
something that waits on a person, use `addSlow(name, timeoutMs, fn)`. To ask the
user for something, use `t.prompt(message, buttonLabel, handler)`.

Register the suite in `initiator/NgioUnitTest.as`.

Two AS2 rules the harness cannot enforce for you:

- **Capture `self` before any closure.** A callback that says `this` is talking
  about the caller, not your suite. Helper methods reached from a callback have
  to be `public`.
- **Pass every argument.** There are no default parameter values, so
  `medal.unlock()` is `medal.unlock(null, null)` and `toObject()` is
  `toObject(true, true)`.

Keep source **ASCII**. Flash text fields render em-dashes, smart quotes and
ellipses as boxes, and `Reporter.sink` can push any emitted line into an
on-stage field. The one test that needs a non-ASCII character builds it with
`String.fromCharCode()`.

## Status

**Fully green.** Run on 2026-08-16 at 750ms pacing, from a machine with a
remembered login — down each branch of the sign-out prompt, so both paths
through the suite are verified rather than one:

| Sign-out prompt | Passed | Failed | Skipped | Assertions | Requests | Duration |
|---|---|---|---|---|---|---|
| **Sign out and test it** | 223 | 0 | 2 | 1076 | 78 | 99.8s + 16.8s human |
| **Keep my login** | 221 | 0 | 4 | 1075 | 75 | 100.6s + 8.2s human |

Both reconcile to the same 225 cases (135 offline + 90 live; `LiveGateSuite`
registers two mutually exclusive cases and runs one).

Both branches have been run more than once and reproduce their counts **exactly**
— same passes, skips, assertions and request total every time. Only the durations
move, and only within about a second of suite time. That reproducibility is worth
more than any single figure here: it is what makes a changed count meaningful
rather than noise.

**Signing out is the more thorough run**, which is worth knowing before you
answer the prompt. It costs a Passport sign-in and 3 extra gateway calls, and in
exchange the two sign-out cases execute instead of skipping — so it has *fewer*
skips than keeping your login, not more.

| Skipped | On which branch | Why |
|---|---|---|
| `ScoreBoard` clamping probes (2) | both | server-side clamping is not enabled on this gateway — see [Server-side conditions](#server-side-conditions--do-not-chase-these) |
| `Live / Sign-out` (2) | keep only | you chose to keep your login, so there is no ended session to re-offer |

Every remaining skip is a stated choice or a server-side condition. **No skip is
a masked failure, and none is state-dependent.** Getting there took four passes:
10 skips, then 3, then 2, then this — each round replacing a "that state was not
available today" skip with a suite that **makes** the state.

Two things the sign-out run confirmed for the first time:

- **`endSession` reaches the server.** Re-offering the ended id came back
  `not-logged-in`, and the gateway did not hand the dead id back. Until this run,
  every assertion about `endSession` described only the client.
- **The gateway echoes `remember` on a *restored* session**, not just at the
  moment of Passport sign-in. Both runs reported `session.remember = true` —
  the keep-login run on a session restored from the SharedObject and re-verified,
  the sign-out run on a session freshly issued through Passport. This was an open
  question when the test was written; had the echo been missing, the library's
  re-save on every result would quietly stop refreshing a remembered login.

An earlier run also hit the rate limit — one dead request after 60 sent, on the
fourth `Live / Loader URLs` test — and the stop handled it: one skip carrying the
explanation, three more skipped without firing a request, and no failures or
false passes from it. See [Rate limiting](#rate-limiting).

There is no ActionScript 2 compiler on this machine — `mxmlc` builds AS3 only,
and the Flash Player debugger here refuses to execute any SWF passed on the
command line. The Flash IDE is the only compile check and the only way to run the
suite, so every change here is reviewed but unverified until someone runs it.

### What the first compile found

Exactly one error, and it was in the **library**, not the tests —
`NgioExternalAppHelper`, part of the batch of changes that shipped alongside the
AS3 work and had never been compiled by anything.

`NgioExternalAppHelper` had a private static method named `call()`. ActionScript
2 inherits a global `call(frame)` action from ActionScript 1, and an unqualified
`call(...)` inside a class resolves to **that**, not to the class's own member —
so all four call sites failed with *"Wrong number of parameters; call requires
exactly 1"*, and the four `NGIO.as` warnings about the package not existing were
just the cascade from that file failing to compile.

Renamed to `dispatch()`. The same trap applies to any AS1 global action used as a
method name (`play`, `stop`, `print`, `trace`, `getURL`, `random`, `eval`, …); a
sweep of `build/` and `test/` found no others.

That is worth knowing beyond this repo: **it is a name collision the compiler
reports as an arity error**, which points at the argument list rather than the
name, and nothing about it hints that a global is involved.

### What the first run found

One infinite recursion, in the same file and from the same port, but this time
invisible to the compiler:

```
256 levels of recursion were exceeded in one action list.
```

`stampForeign()` walked an array via `Array(value)`. That is **not a cast** in
ActionScript 2 — `Array` is the ECMAScript conversion function, and called with
a single non-numeric argument it returns a new one-element array wrapping its
argument. So `Array(someArray)` is `[someArray]`, the loop found one entry (the
original array), recursed on it, and wrapped it again forever. The AS3 original
says `value as Array`, which is a real cast; `as` does not exist in AS2 and
`Array(...)` is the natural-looking substitute.

It fired on the first cross-app read, in `Live / Cross-app access`. Worth knowing
what that costs: **"Further execution of actions has been disabled in this movie"
stops the whole SWF**, so the rest of that suite and all of `Live / Loader URLs`
never ran — the failure reads as "the run stopped" rather than as one bad
function.

Fixed, and the second run completed both of those suites: all 18 cross-app tests
pass, including the four that had never executed.

### What the first complete run found

Nothing new in the library, and one thing worth fixing in this suite.

**A transport failure is reported to the game as a server error.** All four
loader failures read:

```
gateway returned [500] An unexpected error has occurred on the server.
                       If error persists, contact support.
```

The server said nothing at all. `LoadVars` exposes no HTTP status, so
`CoreTransportHelper` **synthesises** 500 when `onData` receives nothing, and
`Core.onHTTPResponse` feeds that straight to `Errors.getError(500)` — which
happens to be a real NGIO code with a plausible-sounding message. So every
transport failure the AS2 library can have (rate limited, offline, DNS, blocked
domain, gateway down) tells the game the *server* had an unexpected error and
the user should contact support.

The Flash Player's own `Error opening URL "…/gateway_v3.php"` lines in the
output are the honest signal here; they come from the failed `sendAndLoad`, not
from any `getURL`, and not from the library.

**Fixed**, in two steps. `Core.onHTTPResponse` now builds both of its errors
through `HttpStatusHelper.errorForStatus`, and `CoreTransportHelper` captures a
real status via `LoadVars.onHTTPStatus` when the player reports one, falling back
to `UNKNOWN_STATUS` rather than to an invented 500. See
[`HttpStatusHelper`](#httpstatushelper) for the full table.

A rate limit that *does* come with a status now arrives as
`TOO_MANY_REQUESTS`, and one that doesn't arrives as "no HTTP status was
reported" — either way distinguishable from the server failing, which is what
lets the harness stop rather than retry. Two offline tests pin it:
*a transport failure is not reported as a server error* and *no HTTP status is
reported as unknown, not invented*, both driving `forwardHTTPResponse` directly.

**`Live / Loader URLs` → *reports an unconfigured referral* passed for the wrong
reason.** It asserts only that an error came back, and a rate-limited request is
an error. It never reached the gateway, so it did not test that an unknown
referral is rejected. Any hardening should distinguish a gateway-level rejection
from a transport failure — the same distinction the clamping probes make when
they skip.

### The two JSON failures — fixed

These were red by design from the start, asserting what the decoder *should* do.
Both are now fixed in `io/newgrounds/encoders/JSON.as`; see
[The JSON decoder](#the-json-decoder) under Library changes for what changed and
why it mattered.

The chunked encoder tests are the other thing to watch. They are new coverage
with no AS3 counterpart, they share one static `busy` flag, and `background_decode`
dispatches through `eval()`. They are written to **skip** rather than fail when
a previous chunked test has not released the flag, so one hang cannot cascade —
but if they all skip, the first one is where to look.
