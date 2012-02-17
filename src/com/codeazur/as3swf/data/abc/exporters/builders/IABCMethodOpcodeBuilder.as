package com.codeazur.as3swf.data.abc.exporters.builders
{
	import com.codeazur.as3swf.data.abc.bytecode.ABCMethodBody;
	import com.codeazur.as3swf.data.abc.bytecode.ABCParameter;
	import com.codeazur.as3swf.data.abc.bytecode.IABCMultiname;
	/**
	 * @author Simon Richardson - simon@ustwo.co.uk
	 */
	public interface IABCMethodOpcodeBuilder extends IABCBuilder {
		
		function get parameters():Vector.<ABCParameter>;
		function set parameters(value:Vector.<ABCParameter>):void;
		
		function get methodBody():ABCMethodBody;
		function set methodBody(value:ABCMethodBody):void;
		
		function get returnType():IABCMultiname;
		function set returnType(value:IABCMultiname):void;
	}
}
