package com.codeazur.as3swf.data.abc.bytecode.multiname
{

	import com.codeazur.as3swf.data.abc.ABC;
	/**
	 * @author Simon Richardson - stickupkid@gmail.com
	 */
	public class ABCRuntimeQualifiedName extends ABCNamedMultiname {
		
		public function ABCRuntimeQualifiedName() {}

		public static function create(name:String, kind:int = -1):ABCQualifiedName {
			const qname : ABCQualifiedName = new ABCQualifiedName();
			qname.label = name;
			qname.kind = kind < 0? ABCMultinameKind.RUNTIME_QNAME : ABCMultinameKind.getType(kind);
			return qname;
		}
		
		override public function get name():String { return "ABCRuntimeQualifiedName"; }
		
		override public function toString(indent:uint = 0):String {
			return ABC.toStringCommon(name, indent) + 
				"Label: " + label + ", " + 
				"Kind: " + kind.toString();
		}
	}
}
