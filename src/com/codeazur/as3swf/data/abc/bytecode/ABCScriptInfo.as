package com.codeazur.as3swf.data.abc.bytecode
{
	import com.codeazur.as3swf.SWFData;
	import com.codeazur.as3swf.data.abc.ABCData;
	import com.codeazur.as3swf.data.abc.ABCTraitSet;
	import com.codeazur.utils.StringUtils;
	/**
	 * @author Simon Richardson - simon@ustwo.co.uk
	 */
	public class ABCScriptInfo extends ABCTraitSet {
		
		public var scriptInitialiser:ABCMethodInfo;
		
		public function ABCScriptInfo(abcData:ABCData) {
			super(abcData);
		}
		
		public static function create(abcData:ABCData, scriptInitialiser:ABCMethodInfo):ABCScriptInfo {
			const scriptInfo:ABCScriptInfo = new ABCScriptInfo(abcData);
			scriptInfo.scriptInitialiser = scriptInitialiser;
			return scriptInfo;
		}
		
		override public function parse(data:SWFData):void {
			super.parse(data);
		}
		
		override public function get name():String { return "ABCScriptInfo"; }
		
		override public function toString(indent:uint=0):String {
			var str:String = super.toString(indent);
			
			str += "\n" + StringUtils.repeat(indent + 2) + "ScriptInitialiser:";
			str += "\n" + scriptInitialiser.toString(indent + 4);
			
			return str;
		}

	}
}
