/** ActionScript 2.0 **/
/** Auto-genertaed by ngio-object-model-generator: https://github.com/PsychoGoldfishNG/ngio-object-model-generator **/

import io.newgrounds.models.BaseObject;

/**
* Contains information about a score posted to a scoreboard.
*/
class io.newgrounds.models.objects.Score extends io.newgrounds.models.BaseObject {

	private var ___user:io.newgrounds.models.objects.User;
	private var ___value:Number;
	private var ___formatted_value:String;
	private var ___tag:String;

	/**
	* Constructor 
	* @param props An object of initial properties for this instance
	*/
	public function Score(props:Object)
    {
		super();

		this.__object = 'Score';
		this.__properties = this.__properties.concat(["user","value","formatted_value","tag"]);
		this.__required = [];

		this.__castTypes = {};
		this.__arrayTypes = {};

		this.__castTypes.user = io.newgrounds.models.objects.User;

		this.fillProperties(props);

	}

	/**
    * The user who earned score. If this property is absent, the score belongs to the active user.
    */
	public function get user():io.newgrounds.models.objects.User {
		return this.___user;
	}

    /**
    * @private
    */
	public function set user(___user:io.newgrounds.models.objects.User)
    {
        this.___user = ___user;
    }

	/**
    * The integer value of the score.
    */
	public function get value():Number {
		return this.___value;
	}

    /**
    * @private
    */
	public function set value(___value:Number)
    {
        this.___value = ___value;
    }

	/**
    * The score value in the format selected in your scoreboard settings.
    */
	public function get formatted_value():String {
		return this.___formatted_value;
	}

    /**
    * @private
    */
	public function set formatted_value(___formatted_value:String)
    {
        this.___formatted_value = ___formatted_value;
    }

	/**
    * The tag attached to this score (if any).
    */
	public function get tag():String {
		return this.___tag;
	}

    /**
    * @private
    */
	public function set tag(___tag:String)
    {
        this.___tag = ___tag;
    }


}
