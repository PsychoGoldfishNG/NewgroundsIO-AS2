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
	public function ScoreBoard(props:Object) {
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
	public function set id(___id:Number) {
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
	public function set name(___name:String) {
		this.___name = ___name;
	}

    public var _validPeriods = ['D','W','M','Y','A'];

    public function getScores(filters:Object, callback:Function, thisArg:Object)
    {

        if (!this.getCore()) {
            throw new Error('Error in '+this.getFullClassName()+': You must attach a core with setCore() before executing unlock().');
            return;
        }

        if (typeof(filters) !== 'object') filters = {};
        var props = {};

        if (filters.user_id !== undefined) {
            filters.user = new io.newgrounds.models.objects.User({id: filters.user_id});
        }

        if (filters.user_name !== undefined) {
            if (filters.user !== undefined) {
                filters.user.name = filters.user_name;
            } else {
                filters.user = new io.newgrounds.models.objects.User({name: filters.user_name});
            }
        }

        // default period to daily
        if (filters.period === undefined || filters.period === null) {
            filters.period = 'D';

        // make sure its a string
        } else if (typeof filters.period !== 'string') {
            throw new Error('Error in '+this.getFullClassName()+': Invalid period value. Must be one of the folloiwing: '+this._validPeriods.join(', ')+'.');
            return;

        // make sure it's uppercase and only one character
        } else {
            filters.period = filters.period.charAt(0).toUpperCase();
        }

        // make sure it's a valid period
        if (this._validPeriods.indexOf(filters.period) === -1) {
            throw new Error('Error in '+this.getFullClassName()+': Invalid period value. Must be one of: '+this._validPeriods.join(', '));
            return;
        }

        props.period = filters.period;

        // default limit to 10
        if (filters.limit === undefined || filters.limit === null) filters.limit = 10;

        // let's make sure the limit is valid, and maybe put some reasonable limits on it
        if (typeof(filters.limit) !== 'number' || filters.limit < 1) {
            throw new Error('Error in '+this.getFullClassName()+': Invalid limit value. Must be a number greater than 0.');
            return;
        }

        if (filters.limit > 100) {
            trace('Warning in '+this.getFullClassName()+': Excessive limit detected, reducing the number of scores to 100.');
            filters.limit = 100;
        }

        props.limit = filters.limit;

        if (typeof(filters.skip) !== 'number' || filters.skip < 0) {
            filters.skip = 0;
        }

        props.skip = filters.skip;

        // if a user is logged in we can check for social scores
        if (this.getCore() && this.getCore().session && this.getCore().session.user) {
            if (filters.social === true) {
                props.social = true;
            }
        }

        if (typeof(filters.tag === 'string')) {
            props.tag = filters.tag;
        }

        if ( (typeof(filters.user) === Number && filters.user > 0) || (typeof(filters.user) === String && filters.user.length > 0) || (filters.user instanceof io.newgrounds.models.objects.User) ) {
            props.user = filters.user;
        }

        props.id = this.id;

        var component = new io.newgrounds.models.components.ScoreBoard.getScores(props);

        var callbackParams = {
            callback: callback,
            thisArg: thisArg
        };

        this.getCore().executeComponent(component, this.onScoresLoaded, this, callbackParams);
    }

    public function onScoresLoaded(result:io.newgrounds.models.results.ScoreBoard.getScores, callbackParams:Object)
    {
        callbackParams.callback.call(callbackParams.thisArg, result.scores);
    }

    public function postScore(value:Number, tag:String, callback:Function, thisArg:Object)
    {
        if (!this.getCore()) {
            throw new Error('Error in '+this.getFullClassName()+': You must attach a core with setCore() before executing unlock().');
            return;
        }

        var props = {
            id: this.id,
            value: value
        };

        if (typeof(tag) === 'string' && tag.length > 0) {
            props.tag = tag;
        }

        var component = new io.newgrounds.models.components.ScoreBoard.postScore(props);

        var callbackParams = {
            callback: callback,
            thisArg: thisArg
        };

        this.getCore().executeComponent(component, this.onPostScore, this, callbackParams);
    }

    public function onPostScore(result:io.newgrounds.models.results.ScoreBoard.postScore, callbackParams:Object)
    {
        callbackParams.callback.call(callbackParams.thisArg, result.score);
    }

}