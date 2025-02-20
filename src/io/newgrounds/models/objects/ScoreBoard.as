/** ActionScript 2.0 **/
/** Auto-genertaed by ngio-object-model-generator: https://github.com/PsychoGoldfishNG/ngio-object-model-generator **/

import io.newgrounds.models.BaseObject;

/**
* Contains information about a scoreboard.
*/
class io.newgrounds.models.objects.ScoreBoard extends io.newgrounds.models.BaseObject {

	private var ___id:Number;
	private var ___name:String;

	/**
	* Constructor 
	* @param props An object of initial properties for this instance
	*/
	public function ScoreBoard(props:Object)
    {
		super();

		this.__object = 'ScoreBoard';
		this.__properties = this.__properties.concat(["id","name"]);
		this.__required = [];

		this.__castTypes = {};
		this.__arrayTypes = {};

		this.fillProperties(props);

	}

	/**
    * The numeric ID of the scoreboard.
    */
	public function get id():Number {
		return this.___id;
	}

    /**
    * @private
    */
	public function set id(___id:Number)
    {
        this.___id = ___id;
    }

	/**
    * The name of the scoreboard.
    */
	public function get name():String {
		return this.___name;
	}

    /**
    * @private
    */
	public function set name(___name:String)
    {
        this.___name = ___name;
    }


}
