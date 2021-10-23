package ui;

import djFlixel.D;
import openfl.events.KeyboardEvent;

class SimpleTextInput extends FlxSpriteGroup {
	public var textBox:FlxText;
	public var bg:FlxSprite;
	public var hasFocus:Bool = true;
	public var maxLength:Int = -1;

	override public function new(textBox:FlxText, bgColor:FlxColor, paddingX:Int, paddingY:Int) {
		super();
		this.textBox = textBox;

		bg = new FlxSprite();
		bg.makeGraphic(Std.int(textBox.width) + paddingX * 2, Std.int(textBox.height) + paddingY * 2, bgColor);

		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown); // TODO: remove the listener on destroy()

		D.align.XAxis(bg, textBox);
		D.align.YAxis(bg, textBox);

		add(bg);
		add(textBox);
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		if (hasFocus && FlxG.keys.justPressed.SPACE) {
			tryAddText(" ");
		}
	}

	public function tryAddText(newText:String) {
		if (maxLength >= 0 && textBox.text.length >= maxLength) {
			return;
		}
		textBox.visible = true;
		this.textBox.text += newText;
	}

	/**
	 * Handles keypresses generated on the stage.
	 */
	private function onKeyDown(e:KeyboardEvent):Void {
		var key:Int = e.keyCode;
		trace(key);
		if (hasFocus) {
			// Do nothing for Shift, Ctrl, Esc, and flixel console hotkey
			if (key == 16 || key == 17 || key == 220 || key == 27) {
				return;
			}
			// Backspace
			else if (key == 8) {
				if (textBox.text.length == 1) {
					textBox.text = "";
					textBox.visible = false;
				} else {
					textBox.text = textBox.text.substr(0, textBox.text.length - 1);
				}
			}
			// Delete
			else if (key == 46) {
				if (textBox.text.length == 1) {
					textBox.text = "";
					textBox.visible = false;
				} else {
					textBox.text = textBox.text.substr(0, textBox.text.length - 1);
				}
			}
			// Enter
			else if (key == 13) {
				// onChange(ENTER_ACTION);
			}
			// Actually add some text
			else {
				var newText:String = String.fromCharCode(e.charCode);

				if (e.charCode == 0) // non-printable characters crash String.fromCharCode
				{
					return;
				}
				tryAddText(newText);
			}
		}
	}
}
