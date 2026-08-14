class initiator.NgioUnitTest {

    public static var instance:NgioUnitTest;

    public static function startTests(caller:MovieClip):Void {
        var infoText:TextField = TextField(caller["infoText"]);
        var inputButton:Button = Button(caller["inputButton"]);
        var inputButtonLabel:TextField = TextField(caller["inputButtonLabel"]);

        instance = new NgioUnitTest(infoText, inputButton, inputButtonLabel);
    }

    public var infoText:TextField;
    public var inputButton:Button;
    public var inputButtonLabel:TextField;

    public function NgioUnitTest(infoText:TextField, inputButton:Button, inputButtonLabel:TextField) {
        // Constructor
        this.infoText = infoText;
        this.inputButton = inputButton;
        this.inputButtonLabel = inputButtonLabel;

        // start the tests
        trace("Starting AS2 NgioUnitTest...");
    }
}