/** ActionScript 2.0 **/
/** Auto-genertaed by ngio-object-model-generator: https://github.com/PsychoGoldfishNG/ngio-object-model-generator **/

import io.newgrounds.models.BaseObject;
import io.newgrounds.models.BaseResult;

/**
 * Returned when ScoreBoard.postScore component is called
 */
class io.newgrounds.models.results.ScoreBoard.postScore extends io.newgrounds.models.BaseResult 
{
    private var ___scoreboard:io.newgrounds.models.objects.ScoreBoard;
	private var ___score:io.newgrounds.models.objects.Score;

	/**
	* Constructor 
	 * @param props An object of initial properties for this instance
	*/
	public function postScore(props:Object) 
    {
		super();

		this.__object = "ScoreBoard.postScore";
		this.__properties = this.__properties.concat(["scoreboard","score"]);

				this.__castTypes = {};

		this.__castTypes.scoreboard = io.newgrounds.models.objects.ScoreBoard;

		this.__castTypes.score = io.newgrounds.models.objects.Score;

		this.fillProperties(props);

	}


    /**
    * The io.newgrounds.models.objects.ScoreBoard that was posted to.
    */
	public function get scoreboard():io.newgrounds.models.objects.ScoreBoard {
		return this.___scoreboard;
	}

    /**
    * @private
    */
	public function set scoreboard(___scoreboard:io.newgrounds.models.objects.ScoreBoard)
    {
        this.___scoreboard = ___scoreboard;
    }


    /**
    * The io.newgrounds.models.objects.Score that was posted to the board.
    */
	public function get score():io.newgrounds.models.objects.Score {
		return this.___score;
	}

    /**
    * @private
    */
	public function set score(___score:io.newgrounds.models.objects.Score)
    {
        this.___score = ___score;
    }


}
