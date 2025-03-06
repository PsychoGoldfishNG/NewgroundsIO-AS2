/** ActionScript 2.0 **/
/** Auto-genertaed by ngio-object-model-generator: https://github.com/PsychoGoldfishNG/ngio-object-model-generator **/

import io.newgrounds.models.BaseObject;
import io.newgrounds.models.BaseResult;

/**
 * Returned when ScoreBoard.getBoards component is called
 */
class io.newgrounds.models.results.ScoreBoard.getBoards extends io.newgrounds.models.BaseResult {
	private var ___scoreboards:Array;

	/**
	* Constructor 
	 * @param props An object of initial properties for this instance
	*/
	public function getBoards(props:Object) {
		super();
		this.__object = "ScoreBoard.getBoards";
		this.__properties = this.__properties.concat(["scoreboards"]);
		this.__castTypes = {};
		this.__arrayTypes = {};
		this.__castTypes.scoreboards = io.newgrounds.models.objects.ScoreBoard;
		this.__arrayTypes.scoreboards = true;
		this.fillProperties(props);
	}

	/**
	* An array of io.newgrounds.models.objects.ScoreBoard objects.
	*/
	public function get scoreboards():Array {
		return this.___scoreboards;
	}

	/**
	* @private
	*/
	public function set scoreboards(___scoreboards:Array) {
		if (___scoreboards instanceof Array) {
            var newArr = [];
            var val;
            for (var i=0; i<___scoreboards.length; i++) {
                newArr.push(this.castValue('scoreboards', ___scoreboards[i]));
            }
            this.___scoreboards = newArr;
        } else {
            this.___scoreboards = ___scoreboards;
        }
	}
}