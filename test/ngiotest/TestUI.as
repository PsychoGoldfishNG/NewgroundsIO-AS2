/**
 * TestUI
 *
 * Wraps the display objects the .fla puts on the stage (infoText, inputButton,
 * inputButtonLabel, and the optional inputButton2 / inputButtonLabel2) so suites
 * can talk to the user without knowing anything about the timeline.
 *
 * Two AS2 details drive the shape of this class:
 *
 *  - A symbol placed on the stage with "Button" behaviour is a Button, not a
 *    MovieClip. The .fla's stub already had this right; the AS3 side did not,
 *    and `as MovieClip` on a button yields null, which silently disables every
 *    interactive test. The objects are held untyped here so a Button, MovieClip
 *    or Sprite-like clip all work.
 *  - AS2 closures do not capture `this`. Every handler assigned below captures
 *    `self` explicitly.
 *
 * The second button is OPTIONAL. A .fla without it still runs everything except
 * the tests that need a genuine either/or choice, which check hasButton2() and
 * skip with a reason rather than hanging.
 */
class ngiotest.TestUI {

	//==================== PROPERTIES ====================

	/** Multiline field used to tell the user what is happening / what to do */
	private var infoText:TextField;

	/**
	 * The clickable controls. Untyped: each may be a Button or a MovieClip, and
	 * AS2 has no common ancestor of the two that carries onRelease.
	 */
	private var button;
	private var button2;

	/** Text fields sitting over the buttons, holding their captions */
	private var buttonLabel:TextField;
	private var buttonLabel2:TextField;

	/** Callbacks to fire on the next click, or null when no input is wanted */
	private var pendingHandler:Function;
	private var pendingHandler2:Function;

	//==================== CONSTRUCTOR ====================

	/**
	 * @param button2      Optional. Pass null when the .fla has only one button.
	 * @param buttonLabel2 Optional, same.
	 */
	public function TestUI(infoText:TextField, button, buttonLabel:TextField, button2, buttonLabel2:TextField) {
		this.infoText = infoText;
		this.button = button;
		this.buttonLabel = buttonLabel;
		this.button2 = button2;
		this.buttonLabel2 = buttonLabel2;
		this.pendingHandler = null;
		this.pendingHandler2 = null;

		var self:ngiotest.TestUI = this;

		if (this.button != null && this.button != undefined) {
			this.button.onRelease = function():Void {
				self.onButtonClick();
			};
			this.button.useHandCursor = true;
		}

		// The label sits over the button and eats the click wherever it
		// overlaps. AS3 solved this by listening on both objects; AS2 does the
		// same by assigning the same handler to both. A TextField also needs
		// selectable = false before it will behave as a button at all -
		// otherwise the press starts a text selection and no release fires.
		if (this.buttonLabel != null && this.buttonLabel != undefined) {
			this.buttonLabel.selectable = false;
			this.buttonLabel.onRelease = function():Void {
				self.onButtonClick();
			};
		}

		if (this.button2 != null && this.button2 != undefined) {
			this.button2.onRelease = function():Void {
				self.onButton2Click();
			};
			this.button2.useHandCursor = true;
		}

		if (this.buttonLabel2 != null && this.buttonLabel2 != undefined) {
			this.buttonLabel2.selectable = false;
			this.buttonLabel2.onRelease = function():Void {
				self.onButton2Click();
			};
		}

		hideButton();
	}

	//==================== PUBLIC METHODS ====================

	/**
	 * Replace the informational text shown to the user.
	 */
	public function setInfo(message:String):Void {
		if (infoText != null && infoText != undefined) {
			infoText.text = (message != null) ? message : "";
		}
	}

	/**
	 * Show the primary button with a caption and wait for a click.
	 *
	 * @param label   Caption to display on/next to the button
	 * @param handler Called once, on the next click. Cleared before it fires,
	 *                so a handler is free to call showButton() again.
	 */
	public function showButton(label:String, handler:Function):Void {
		pendingHandler = handler;

		if (buttonLabel != null && buttonLabel != undefined) {
			buttonLabel.text = (label != null) ? label : "Continue";
			buttonLabel._visible = true;
		}

		if (button != null && button != undefined) {
			button._visible = true;
			button.enabled = true;
		}
	}

	/**
	 * Show BOTH buttons and wait for whichever is clicked.
	 *
	 * Whichever fires, the other is torn down first - hideButton() clears both
	 * pending handlers, so a two-way choice cannot fire twice even if the user
	 * manages to hit both controls.
	 */
	public function showButtons(label:String, handler:Function, label2:String, handler2:Function):Void {
		showButton(label, handler);

		pendingHandler2 = handler2;

		if (buttonLabel2 != null && buttonLabel2 != undefined) {
			buttonLabel2.text = (label2 != null) ? label2 : "Continue";
			buttonLabel2._visible = true;
		}

		if (button2 != null && button2 != undefined) {
			button2._visible = true;
			button2.enabled = true;
		}
	}

	/**
	 * Hide both buttons and drop any handlers waiting on them.
	 */
	public function hideButton():Void {
		pendingHandler = null;
		pendingHandler2 = null;

		if (buttonLabel != null && buttonLabel != undefined) {
			buttonLabel._visible = false;
		}

		if (button != null && button != undefined) {
			button._visible = false;
			button.enabled = false;
		}

		if (buttonLabel2 != null && buttonLabel2 != undefined) {
			buttonLabel2._visible = false;
		}

		if (button2 != null && button2 != undefined) {
			button2._visible = false;
			button2.enabled = false;
		}
	}

	/**
	 * True when the stage actually provided a usable button. Suites that need
	 * human input check this so they can skip rather than hang forever.
	 */
	public function hasButton():Boolean {
		return (button != null && button != undefined);
	}

	/**
	 * True when the stage provided a usable SECOND button.
	 *
	 * Separate from hasButton() because the second one is optional: a .fla
	 * carrying only inputButton still runs every single-choice prompt.
	 */
	public function hasButton2():Boolean {
		return (button2 != null && button2 != undefined);
	}

	//==================== PRIVATE METHODS ====================

	private function onButtonClick():Void {
		if (pendingHandler == null) {
			return;
		}

		// Clear state BEFORE invoking, so the handler can immediately arm
		// another prompt without it being wiped by our own cleanup. hideButton()
		// drops BOTH handlers, which is what stops a two-way choice resolving
		// twice.
		var handler:Function = pendingHandler;
		hideButton();
		handler.call(null);
	}

	private function onButton2Click():Void {
		if (pendingHandler2 == null) {
			return;
		}

		var handler:Function = pendingHandler2;
		hideButton();
		handler.call(null);
	}
}
