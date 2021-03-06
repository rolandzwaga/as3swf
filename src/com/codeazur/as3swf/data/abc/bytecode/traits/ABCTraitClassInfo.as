package com.codeazur.as3swf.data.abc.bytecode.traits
{
	import com.codeazur.as3swf.SWFData;
	import com.codeazur.as3swf.data.abc.ABCData;
	import com.codeazur.as3swf.data.abc.bytecode.ABCClassInfo;
	import com.codeazur.as3swf.data.abc.bytecode.IABCMultiname;
	import com.codeazur.as3swf.data.abc.io.ABCScanner;
	import com.codeazur.utils.StringUtils;

	/**
	 * @author Simon Richardson - simon@ustwo.co.uk
	 */
	public class ABCTraitClassInfo extends ABCTraitInfo
	{
		
		public var id:uint;
		public var index:uint;
		public var classInfo:ABCClassInfo;

		public function ABCTraitClassInfo(abcData : ABCData) {
			super(abcData);
		}
		
		public static function create(data:ABCData, qname:IABCMultiname, kind:uint, kindType:ABCTraitInfoKind):ABCTraitClassInfo {
			const classInfo:ABCTraitClassInfo = new ABCTraitClassInfo(data);
			classInfo.qname = qname;
			classInfo.kind = kind;
			classInfo.kindType = kindType;
			return classInfo;
		}
		
		override public function read(data : SWFData, scanner:ABCScanner) : void {
			id = data.readEncodedU30();
			index = data.readEncodedU30();
			
			classInfo = getClassInfoByIndex(index);
			
			super.read(data, scanner);
		}
		
		override public function write(bytes : SWFData) : void
		{
			bytes.writeEncodedU32(id);
			bytes.writeEncodedU32(index);
			
			super.write(bytes);
		}

		override public function get name() : String { return "ABCTraitClassInfo"; }
		
		override public function toString(indent : uint = 0) : String {
			var str:String = super.toString(indent);
			
			str += "\n" + StringUtils.repeat(indent + 2) + "ID: " + id;
			str += "\n" + StringUtils.repeat(indent + 2) + "Index: " + index;
			str += "\n" + StringUtils.repeat(indent + 2) + "ClassInfo: ";
			str += "\n" + classInfo.toString(indent + 4);
			
			return str;
		}
	}
}
