package com.codeazur.as3swf.data.abc.exporters.js.builders.arguments
{

	import com.codeazur.as3swf.data.abc.bytecode.attributes.ABCOpcodeAttribute;
	import com.codeazur.as3swf.data.abc.bytecode.attributes.ABCOpcodeMultinameAttribute;
	import com.codeazur.as3swf.data.abc.bytecode.attributes.ABCOpcodeMultinameUIntAttribute;
	import com.codeazur.as3swf.data.abc.bytecode.attributes.ABCOpcodeStringAttribute;
	import com.codeazur.as3swf.data.abc.bytecode.attributes.IABCOpcodeIntegerAttribute;
	import com.codeazur.as3swf.data.abc.bytecode.attributes.IABCOpcodeUnsignedIntegerAttribute;
	import com.codeazur.as3swf.data.abc.exporters.builders.IABCArgumentBuilder;
	/**
	 * @author Simon Richardson - simon@ustwo.co.uk
	 */
	public class JSArgumentBuilderFactory
	{
		
		public static function create(attribute:ABCOpcodeAttribute):IABCArgumentBuilder {
			var builder:IABCArgumentBuilder;
			if(attribute is IABCOpcodeIntegerAttribute) { 
				const intAttr:IABCOpcodeIntegerAttribute = IABCOpcodeIntegerAttribute(attribute);
				builder = JSIntegerArgumentBuilder.create(intAttr.integer);
			
			} else if(attribute is IABCOpcodeUnsignedIntegerAttribute) {
				const uintAttr:IABCOpcodeUnsignedIntegerAttribute = IABCOpcodeUnsignedIntegerAttribute(attribute);
				builder = JSUnsignedIntegerArgumentBuilder.create(uintAttr.unsignedInteger);
				
			} else if(attribute is ABCOpcodeMultinameAttribute) {
				const mnameAttr:ABCOpcodeMultinameAttribute = ABCOpcodeMultinameAttribute(attribute);
				builder = JSMultinameArgumentBuilder.create(mnameAttr.multiname);
				
			} else if(attribute is ABCOpcodeStringAttribute) {
				const strAttr:ABCOpcodeStringAttribute = ABCOpcodeStringAttribute(attribute);
				builder = JSStringArgumentBuilder.create(strAttr.string);
				
			} else {
				throw new Error(attribute);
			}
						
			return builder;					
		}
		
		public static function getNumberArguments(attribute:ABCOpcodeAttribute):uint {
			var numArguments:uint = 0;
			if(attribute is ABCOpcodeMultinameUIntAttribute){
				numArguments = ABCOpcodeMultinameUIntAttribute(attribute).numArguments;
			} else if(attribute is IABCOpcodeIntegerAttribute){
				numArguments = IABCOpcodeIntegerAttribute(attribute).integer;
			} else if(attribute is IABCOpcodeUnsignedIntegerAttribute){
				numArguments = IABCOpcodeUnsignedIntegerAttribute(attribute).unsignedInteger;
			}
			return numArguments;
		}
	}
}
