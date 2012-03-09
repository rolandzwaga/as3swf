package com.codeazur.as3swf.data.abc.exporters.js.builders.expressions
{
	import com.codeazur.as3swf.data.abc.exporters.builders.IABCOperatorExpression;
	import com.codeazur.as3swf.data.abc.exporters.js.builders.JSConsumableBlock;
	import com.codeazur.as3swf.data.abc.exporters.js.builders.JSOperatorKind;
	import com.codeazur.as3swf.data.abc.exporters.js.builders.JSTokenKind;
	import com.codeazur.as3swf.data.abc.io.IABCWriteable;

	import flash.utils.ByteArray;
	/**
	 * @author Simon Richardson - simon@ustwo.co.uk
	 */
	public class JSSubtractExpression extends JSConsumableBlock implements IABCOperatorExpression {

		public function JSSubtractExpression() {
		}

		public static function create(left:IABCWriteable = null, right:IABCWriteable = null):JSSubtractExpression {
			const expression:JSSubtractExpression = new JSSubtractExpression();
			expression.left = left;
			expression.right = right;
			return expression;
		}

		override public function write(data:ByteArray):void {
			JSTokenKind.LEFT_PARENTHESES.write(data);
			
			left.write(data);
			JSOperatorKind.SUBTRACTION.write(data);
			right.write(data);
			
			JSTokenKind.RIGHT_PARENTHESES.write(data);			
		}
		
		override public function get name():String { return "JSSubtractExpression"; }
	}
}
