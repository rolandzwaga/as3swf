package com.codeazur.as3swf.data.abc.bytecode.traits
{
	import com.codeazur.as3swf.SWFData;
	import com.codeazur.as3swf.data.abc.ABCData;
	import com.codeazur.as3swf.data.abc.bytecode.ABCMethodInfo;
	import com.codeazur.as3swf.data.abc.bytecode.IABCMultiname;
	import com.codeazur.as3swf.data.abc.bytecode.multiname.ABCQualifiedName;
	import com.codeazur.as3swf.data.abc.io.ABCScanner;
	import com.codeazur.utils.StringUtils;

	/**
	 * @author Simon Richardson - simon@ustwo.co.uk
	 */
	public class ABCTraitMethodInfo extends ABCTraitInfo
	{
		
		public var id:uint;
		public var isStatic:Boolean;
		public var methodInfo:ABCMethodInfo;
		
		public function ABCTraitMethodInfo(abcData : ABCData) {
			super(abcData);
		}
		
		public static function create(data:ABCData, qname:IABCMultiname, kind:uint, kindType:ABCTraitInfoKind, isStatic:Boolean = false):ABCTraitMethodInfo {
			const trait:ABCTraitMethodInfo = new ABCTraitMethodInfo(data);
			trait.multiname = qname;
			trait.kind = kind;
			trait.kindType = kindType;
			trait.isStatic = isStatic;
			return trait;
		}
		
		override public function read(data:SWFData, scanner:ABCScanner) : void {
			id = data.readEncodedU30();
			
			const index:uint = data.readEncodedU30();
			methodInfo = getMethodInfoByIndex(index);
			methodInfo.multiname = multiname;
			
			const qname:ABCQualifiedName = multiname.toQualifiedName();
			if(qname) {
				methodInfo.methodNameLabel = qname.fullName;
				methodInfo.isValidMethodName = true;
			} else {
				methodInfo.isValidMethodName = false;
			}
			
			super.read(data, scanner);
		}
		
		override public function write(bytes : SWFData) : void {
			bytes.writeEncodedU32(id);
			bytes.writeEncodedU32(getMethodInfoIndex(methodInfo));
			
			super.write(bytes);
		}

		override public function get name() : String { return "ABCTraitMethodInfo"; }
		
		override public function toString(indent : uint = 0) : String {
			var str:String = super.toString(indent);
			
			str += "\n" + StringUtils.repeat(indent + 2) + "ID: " + id;
			str += "\n" + StringUtils.repeat(indent + 2) + "Static: " + isStatic;
			
			if(methodInfo) {
				str += "\n" + StringUtils.repeat(indent + 2) + "MethodInfo: ";
				str += "\n" + methodInfo.toString(indent + 4);
			}
			
			return str;
		}
	}
}
