package com.codeazur.as3swf.data.abc.exporters.builders.js
{

	import com.codeazur.as3swf.data.abc.ABC;
	import com.codeazur.as3swf.data.abc.bytecode.ABCParameter;
	import com.codeazur.as3swf.data.abc.exporters.builders.IABCParameterBuilder;
	import com.codeazur.utils.StringUtils;

	import flash.utils.ByteArray;
	/**
	 * @author Simon Richardson - simon@ustwo.co.uk
	 */
	public class JSParameterBuilder implements IABCParameterBuilder
	{
		private var _parameter:ABCParameter;

		public function JSParameterBuilder() {
		}
		
		public static function create(parameter:ABCParameter):JSParameterBuilder {
			const builder:JSParameterBuilder = new JSParameterBuilder();
			builder.parameter = parameter;
			return builder;
		}
		
		public function write(data:ByteArray):void {
			data.writeUTF(parameter.label);
		}
		
		public function get parameter():ABCParameter { return _parameter; }
		public function set parameter(value:ABCParameter) : void { _parameter = value; }
		
		public function get name():String { return "JSValueBuilder"; }
		
		public function toString(indent:uint=0):String {
			var str:String = ABC.toStringCommon(name, indent);
			
			str += "\n" + StringUtils.repeat(indent + 2) + "Parameter:";
			str += "\n" + parameter.toString(indent + 4);
			
			return str;
		}
	}
}