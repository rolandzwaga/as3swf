package com.codeazur.as3swf.data.abc.exporters.js.builders.arguments
{
	import com.codeazur.as3swf.data.abc.ABC;
	import com.codeazur.as3swf.data.abc.bytecode.ABCNamespace;
	import com.codeazur.as3swf.data.abc.bytecode.ABCNamespaceKind;
	import com.codeazur.as3swf.data.abc.bytecode.ABCParameter;
	import com.codeazur.as3swf.data.abc.bytecode.IABCMultiname;
	import com.codeazur.as3swf.data.abc.bytecode.multiname.ABCQualifiedName;
	import com.codeazur.as3swf.data.abc.exporters.builders.IABCArgumentBuilder;
	import com.codeazur.as3swf.data.abc.exporters.js.builders.JSReservedKind;
	import com.codeazur.as3swf.data.abc.exporters.js.builders.JSTokenKind;
	import flash.utils.ByteArray;


	/**
	 * @author Simon Richardson - simon@ustwo.co.uk
	 */
	public class JSRestArgumentBuilder implements IABCArgumentBuilder {
		
		
		private static const ARRAY_PROTOTYPE_CALL:IABCMultiname = ABCQualifiedName.create("call", ABCNamespace.create(ABCNamespaceKind.NAMESPACE.type, "Array.prototype.slice"));
		
		public var start:uint;
		
		private var _parameter:ABCParameter;

		public function JSRestArgumentBuilder() {
		}
		
		public static function create(start:uint=0):JSRestArgumentBuilder {
			const builder:JSRestArgumentBuilder = new JSRestArgumentBuilder();
			builder.start = start;
			builder.argument = ABCParameter.create(ARRAY_PROTOTYPE_CALL, JSReservedKind.ARGUMENTS.type);
			return builder;
		}
		
		public function write(data:ByteArray):void {
			data.writeUTF(argument.qname.fullName);
			JSTokenKind.LEFT_PARENTHESES.write(data);
			data.writeUTF(argument.label);
			
			if(start > 0) {
				JSTokenKind.COMMA.write(data);
				data.writeUTF(start.toString(10));
			}
			
			JSTokenKind.RIGHT_PARENTHESES.write(data);
		}
		
		public function get argument():ABCParameter { return _parameter; }
		public function set argument(value:ABCParameter) : void { _parameter = value; }
		
		public function get name():String { return "JSRestArgumentBuilder"; }
		
		public function toString(indent:uint=0):String {
			return ABC.toStringCommon(name, indent);
		}
	}
}