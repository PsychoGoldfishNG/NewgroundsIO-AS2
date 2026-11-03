/**
 * DateTimeHelper
 *
 * ISO 8601 datetimes, for comparing a local save copy against the cloud's.
 * Flash's Date can't read or write ISO 8601, and AS2 has no RegExp, so this
 * walks the string by hand. Digits are converted one at a time rather than with
 * Number() or parseInt(), which can read a leading zero as octal.
 */
class io.newgrounds.helpers.DateTimeHelper {

	/**
	 * Milliseconds since the epoch for an ISO 8601 datetime such as
	 * "2026-08-25T17:42:42-04:00" or "2026-08-25T21:42:42.000Z", or NaN if it
	 * won't parse. The offset is applied, so two datetimes from different time
	 * zones compare correctly. One with no offset is read as UTC.
	 */
	public static function parseIso(value:String):Number {
		if (value == null || value == undefined || value.length < 19) return NaN;
		if (value.charAt(4) != "-" || value.charAt(7) != "-" || value.charAt(10) != "T"
			|| value.charAt(13) != ":" || value.charAt(16) != ":") {
			return NaN;
		}

		var year:Number = io.newgrounds.helpers.DateTimeHelper.readDigits(value, 0, 4);
		var month:Number = io.newgrounds.helpers.DateTimeHelper.readDigits(value, 5, 2);
		var day:Number = io.newgrounds.helpers.DateTimeHelper.readDigits(value, 8, 2);
		var hour:Number = io.newgrounds.helpers.DateTimeHelper.readDigits(value, 11, 2);
		var minute:Number = io.newgrounds.helpers.DateTimeHelper.readDigits(value, 14, 2);
		var second:Number = io.newgrounds.helpers.DateTimeHelper.readDigits(value, 17, 2);
		if (isNaN(year) || isNaN(month) || isNaN(day) || isNaN(hour) || isNaN(minute) || isNaN(second)) return NaN;

		var position:Number = 19;
		var milliseconds:Number = 0;
		if (value.charAt(position) == ".") {
			position++;
			var fraction:Number = 0;
			var scale:Number = 100;
			var start:Number = position;
			while (position < value.length && io.newgrounds.helpers.DateTimeHelper.isDigitAt(value, position)) {
				// Only the first three digits count: ".5" is 500ms, ".123456" is 123ms.
				fraction += (value.charCodeAt(position) - 48) * scale;
				scale = scale / 10;
				position++;
			}
			if (position == start) return NaN;
			milliseconds = Math.floor(fraction);
		}

		var offsetMinutes:Number = 0;
		if (position < value.length) {
			var zone:String = value.substring(position);
			if (zone != "Z") {
				var sign:Number;
				if (zone.charAt(0) == "+") {
					sign = 1;
				} else if (zone.charAt(0) == "-") {
					sign = -1;
				} else {
					return NaN;
				}
				var digits:String = zone.substring(1);
				if (digits.length == 5 && digits.charAt(2) == ":") {
					digits = digits.substring(0, 2) + digits.substring(3);
				}
				if (digits.length != 4) return NaN;
				var offsetHours:Number = io.newgrounds.helpers.DateTimeHelper.readDigits(digits, 0, 2);
				var offsetRest:Number = io.newgrounds.helpers.DateTimeHelper.readDigits(digits, 2, 2);
				if (isNaN(offsetHours) || isNaN(offsetRest)) return NaN;
				offsetMinutes = sign * (offsetHours * 60 + offsetRest);
			}
		}

		var time:Number = Date.UTC(year, month - 1, day, hour, minute, second, milliseconds);
		return time - offsetMinutes * 60000;
	}

	/** An ISO 8601 datetime in UTC, such as "2026-08-25T21:42:42.000Z". */
	public static function toIso(time:Number):String {
		var date:Date = new Date(time);
		var pad:Function = io.newgrounds.helpers.DateTimeHelper.pad;
		return date.getUTCFullYear() + "-" + pad(date.getUTCMonth() + 1, 2) + "-" + pad(date.getUTCDate(), 2)
			+ "T" + pad(date.getUTCHours(), 2) + ":" + pad(date.getUTCMinutes(), 2) + ":" + pad(date.getUTCSeconds(), 2)
			+ "." + pad(date.getUTCMilliseconds(), 3) + "Z";
	}

	/** The current time as an ISO 8601 datetime in UTC. */
	public static function nowIso():String {
		return io.newgrounds.helpers.DateTimeHelper.toIso(new Date().getTime());
	}

	/** Reads `count` decimal digits starting at `start`, or NaN if any isn't a digit. */
	public static function readDigits(text:String, start:Number, count:Number):Number {
		var result:Number = 0;
		for (var i:Number = start; i < start + count; i++) {
			if (!io.newgrounds.helpers.DateTimeHelper.isDigitAt(text, i)) return NaN;
			result = result * 10 + (text.charCodeAt(i) - 48);
		}
		return result;
	}

	public static function isDigitAt(text:String, index:Number):Boolean {
		var code:Number = text.charCodeAt(index);
		return code >= 48 && code <= 57;
	}

	public static function pad(value:Number, width:Number):String {
		var text:String = String(value);
		while (text.length < width) text = "0" + text;
		return text;
	}
}
