package com.codeazur.as3swf.data.abc.exporters.js.builders.expressions
{

	import flash.utils.ByteArray;
	/**
	 * @author Simon Richardson - simon@ustwo.co.uk
	 */
	public class JSIfTrueExpression extends JSIfExpression {

		public function JSIfTrueExpression() {
		}
		
		public static function create():JSIfTrueExpression {
			const instance:JSIfTrueExpression = new JSIfTrueExpression();
			return instance;
		}

		override public function write(data : ByteArray) : void {
		}

		override public function get name() : String { return "JSIfTrueExpression"; }
	}
}
