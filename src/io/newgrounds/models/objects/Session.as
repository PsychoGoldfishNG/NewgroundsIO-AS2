/** ActionScript 2.0 **/
/** Auto-genertaed by ngio-object-model-generator: https://github.com/PsychoGoldfishNG/ngio-object-model-generator **/

import io.newgrounds.models.BaseObject;

/**
* Contains information about the current user session.
*/
class io.newgrounds.models.objects.Session extends io.newgrounds.models.BaseObject {

	private var ___id:String;
	private var ___user:io.newgrounds.models.objects.User;
	private var ___expired:Boolean;
	private var ___remember:Boolean;
	private var ___passport_url:String;

	/**
	* Constructor 
	* @param props An object of initial properties for this instance
	*/
	public function Session(props:Object)
    {
		super();

		this.__object = 'Session';
		this.__properties = this.__properties.concat(["id","user","expired","remember","passport_url"]);
		this.__required = [];

		this.__castTypes = {};
		this.__arrayTypes = {};

		this.__castTypes.user = io.newgrounds.models.objects.User;

		this.fillProperties(props);

	}

	/**
    * A unique session identifier
    */
	public function get id():String {
		return this.___id;
	}

    /**
    * @private
    */
	public function set id(___id:String)
    {
        this.___id = ___id;
    }

	/**
    * If the user has not signed in, or granted access to your app, this will be null
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
    * If true, the session_id is expired. Use App.startSession to get a new one.
    */
	public function get expired():Boolean {
		return this.___expired;
	}

    /**
    * @private
    */
	public function set expired(___expired:Boolean)
    {
        this.___expired = ___expired;
    }

	/**
    * If true, the user would like you to remember their session id.
    */
	public function get remember():Boolean {
		return this.___remember;
	}

    /**
    * @private
    */
	public function set remember(___remember:Boolean)
    {
        this.___remember = ___remember;
    }

	/**
    * If the session has no associated user but is not expired, this property will provide a URL that can be used to sign the user in.
    */
	public function get passport_url():String {
		return this.___passport_url;
	}

    /**
    * @private
    */
	public function set passport_url(___passport_url:String)
    {
        this.___passport_url = ___passport_url;
    }


}
