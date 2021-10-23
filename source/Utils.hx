package;

class Utils {
	public static function intStringWithMinLength(i:Int, minLength:Int):String {
		var s = Std.string(i);
		while (s.length < minLength) {
			s = "0" + s;
		}
		return s;
	}

	public static function normalizeAngle(angle:Float):Float {
		angle = angle % 360;

		if (angle < 0) {
			angle += 360;
		}
		return angle;
	}
}
