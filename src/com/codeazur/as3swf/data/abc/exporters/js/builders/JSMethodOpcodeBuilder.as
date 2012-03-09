package com.codeazur.as3swf.data.abc.exporters.js.builders
{
	import com.codeazur.as3swf.data.abc.ABC;
	import com.codeazur.as3swf.data.abc.bytecode.ABCMethodInfo;
	import com.codeazur.as3swf.data.abc.bytecode.ABCNamespaceType;
	import com.codeazur.as3swf.data.abc.bytecode.ABCOpcode;
	import com.codeazur.as3swf.data.abc.bytecode.ABCOpcodeKind;
	import com.codeazur.as3swf.data.abc.bytecode.ABCOpcodeSet;
	import com.codeazur.as3swf.data.abc.bytecode.ABCParameter;
	import com.codeazur.as3swf.data.abc.bytecode.ABCTraitInfo;
	import com.codeazur.as3swf.data.abc.bytecode.attributes.ABCOpcodeAttribute;
	import com.codeazur.as3swf.data.abc.bytecode.multiname.ABCQualifiedName;
	import com.codeazur.as3swf.data.abc.bytecode.multiname.ABCQualifiedNameType;
	import com.codeazur.as3swf.data.abc.exporters.builders.IABCAttributeBuilder;
	import com.codeazur.as3swf.data.abc.exporters.builders.IABCMethodCallBuilder;
	import com.codeazur.as3swf.data.abc.exporters.builders.IABCMethodOpcodeBuilder;
	import com.codeazur.as3swf.data.abc.exporters.builders.IABCMultinameAttributeBuilder;
	import com.codeazur.as3swf.data.abc.exporters.builders.IABCOperatorExpression;
	import com.codeazur.as3swf.data.abc.exporters.builders.IABCValueBuilder;
	import com.codeazur.as3swf.data.abc.exporters.builders.IABCVariableBuilder;
	import com.codeazur.as3swf.data.abc.exporters.js.builders.arguments.JSArgumentBuilder;
	import com.codeazur.as3swf.data.abc.exporters.js.builders.arguments.JSArgumentsBuilder;
	import com.codeazur.as3swf.data.abc.exporters.js.builders.arguments.JSAttributeBuilderFactory;
	import com.codeazur.as3swf.data.abc.exporters.js.builders.arguments.JSMultinameArgumentBuilder;
	import com.codeazur.as3swf.data.abc.exporters.js.builders.arguments.JSThisArgumentBuilder;
	import com.codeazur.as3swf.data.abc.exporters.js.builders.expressions.JSOperatorExpressionFactory;
	import com.codeazur.as3swf.data.abc.exporters.js.builders.expressions.JSPrimaryExpressionFactory;
	import com.codeazur.as3swf.data.abc.exporters.translator.ABCOpcodeTranslateData;
	import com.codeazur.as3swf.data.abc.io.IABCWriteable;

	import flash.utils.ByteArray;


	/**
	 * @author Simon Richardson - simon@ustwo.co.uk
	 */
	public class JSMethodOpcodeBuilder implements IABCMethodOpcodeBuilder {
		
		private var _methodInfo:ABCMethodInfo;
		private var _traits:Vector.<ABCTraitInfo>;
		private var _translateData:ABCOpcodeTranslateData;
		
		private var _stack:JSStack;
		private var _position:uint;
		private var _arguments:Vector.<ABCParameter>;
		
		public function JSMethodOpcodeBuilder() {
			_stack = JSStack.create();
			_arguments = new Vector.<ABCParameter>();
		}
		
		public static function create(methodInfo:ABCMethodInfo, traits:Vector.<ABCTraitInfo>, translateData:ABCOpcodeTranslateData):JSMethodOpcodeBuilder {
			const builder:JSMethodOpcodeBuilder = new JSMethodOpcodeBuilder();
			builder.methodInfo = methodInfo;
			builder.traits = traits;
			builder.translateData = translateData;
			return builder;
		}

		public function write(data : ByteArray) : void {
			const parameters:Vector.<ABCParameter> = methodInfo.parameters;
			const parameterTotal:uint = parameters.length;
			for(var i:uint=0; i<parameterTotal; i++) {
				_arguments.push(parameters[i]);
			}
			
			const total:uint = translateData.length;
			if(total > 0) {
				_position = 0;
				recursive(_stack, 0);
			}
			
			_stack.write(data);
		}
		
		private function recursive(stack:JSStack, indent:uint=0, tail:ABCOpcode = null):void {
			const total:uint = translateData.length;
			for(; _position<total; _position++) {
				
				const opcodes:Vector.<ABCOpcode> = translateData.getAt(_position);
				
				if(tail) {
					if(opcodes.indexOf(tail) > -1) {
						return;
					} else if(ABCOpcodeKind.isType(opcodes[opcodes.length - 1].kind, ABCOpcodeKind.JUMP)) {
						const next:Vector.<ABCOpcode> = translateData.getAt(_position + 1);
						if(next.indexOf(tail) > -1) {
							return;
						}
					} 
				} 
				
				// Get the tail items so that we know what to do with the item
				const opcode:ABCOpcode = opcodes.pop();
				const offset:int = opcodes.length - 1;
				
				const numArguments:int = JSAttributeBuilderFactory.getNumberArguments(opcode.attribute);
				
				var consumables:Vector.<IABCWriteable> = null;
				
				const kind:ABCOpcodeKind = opcode.kind;
				switch(kind) {
					case ABCOpcodeKind.CONSTRUCTSUPER:
						consumables = consumeTail(opcodes, opcodes.length, 0);
					
						const superQName:ABCQualifiedName = ABCQualifiedName.create(JSReservedKind.SUPER.type, ABCNamespaceType.SUPER.ns);
						const superName:IABCMultinameAttributeBuilder = JSMultinameArgumentBuilder.create(superQName);
						const superArguments:Vector.<IABCWriteable> = consumables.splice(0, numArguments);
						
						if(superArguments.length != numArguments) {
							throw new Error('Super argument mismatch');
						}
						
						stack.add(JSNameBuilder.create(consumables), JSMethodCallBuilder.create(superName, superArguments)).terminator = true;
						break;
					
					case ABCOpcodeKind.CALLPROPERTY:
					case ABCOpcodeKind.CALLPROPVOID:
						consumables = consumeTail(opcodes, opcodes.length, 0);
						
						const propertyName:IABCMultinameAttributeBuilder = JSAttributeBuilderFactory.create(traits, opcode.attribute) as IABCMultinameAttributeBuilder;
						if(propertyName) {
							const propertyArguments:Vector.<IABCWriteable> = consumables.splice(0, numArguments);
							
							if(propertyArguments.length != numArguments) {
								throw new Error('Property argument mismatch');
							}
							
							stack.add(JSNameBuilder.create(consumables), JSMethodCallBuilder.create(propertyName, propertyArguments)).terminator = true;
						} else {
							throw new Error('Property name mismatch');
						}
						break;
						
					case ABCOpcodeKind.INITPROPERTY:
						const propertyQName:IABCAttributeBuilder = JSAttributeBuilderFactory.create(traits, opcode.attribute);
						stack.add(JSPropertyBuilder.create(propertyQName, consume(opcodes, 0, offset))).terminator = true;
						break;
					
					case ABCOpcodeKind.IFEQ:
					case ABCOpcodeKind.IFFALSE:
					case ABCOpcodeKind.IFGE:
					case ABCOpcodeKind.IFGT:
					case ABCOpcodeKind.IFLE:
					case ABCOpcodeKind.IFLT:
					case ABCOpcodeKind.IFNE:
					case ABCOpcodeKind.IFNGE:
					case ABCOpcodeKind.IFNGT:
					case ABCOpcodeKind.IFNLE:
					case ABCOpcodeKind.IFNLT:
					case ABCOpcodeKind.IFSTRICTEQ:
					case ABCOpcodeKind.IFSTRICTNE:
					case ABCOpcodeKind.IFTRUE:
						const ifExpr:JSConsumableBlock = createIfStatementExpression(opcodes);
						const ifBody:JSStack = parseInternalBlock(opcode, indent);
						stack.add(JSIfStatementBuilder.create(kind, ifExpr, ifBody));
						break;
						
					case ABCOpcodeKind.JUMP:
						const jumpcode:ABCOpcode = opcodes.length > 2 ? opcodes[opcodes.length - 2] : opcodes[opcodes.length - 1];
						const jumpExpr:JSConsumableBlock = createIfStatementExpression(opcodes);
						const jumpBody:JSStack = parseInternalBlock(jumpcode, indent);
						stack.add(JSIfStatementBuilder.create(kind, jumpExpr, jumpBody));
						break;
				
					case ABCOpcodeKind.GETLOCAL_0:
						consumables = consumeTail(opcodes, opcodes.length, 0);
						
						if(consumables.length > 0) {
							throw new Error('Invalid stack length');
						}
						
						stack.add(getLocal(0)).terminator = true;
						break;
					
					case ABCOpcodeKind.SETLOCAL_1:
						stack.add(createLocalVariable(0, opcodes, offset));
						break;
						
					case ABCOpcodeKind.SETLOCAL_2:
						stack.add(createLocalVariable(1, opcodes, offset));
						break;
						
					case ABCOpcodeKind.SETLOCAL_3:
						stack.add(createLocalVariable(2, opcodes, offset));
						break;
					
					case ABCOpcodeKind.RETURNVALUE:
						const returnValue:Vector.<IABCWriteable> = consume(opcodes, 0, offset);
						stack.add(JSReturnBuilder.create(JSNameBuilder.create(returnValue))).terminator = true;
						break;
					
					case ABCOpcodeKind.RETURNVOID:
						stack.add(JSReturnVoidBuilder.create()).terminator = true;
						break;
					
					case ABCOpcodeKind.DEBUG:
					case ABCOpcodeKind.DEBUGFILE:
					case ABCOpcodeKind.DEBUGLINE:
						// do nothing here
						break;
					
					default:
						trace(">>", kind);
						break;
				}
			}
		}
		
		private function consumeTail(opcodes:Vector.<ABCOpcode>, total:int, indent:int):Vector.<IABCWriteable> {
			const result:Vector.<IABCWriteable> = new Vector.<IABCWriteable>();
			
			var previous:IABCWriteable;
			
			var index:int = opcodes.length;
			var end:int = (index - total) - 1;
			while(--index > end) {
				if(index >= opcodes.length) {
					break;
				}
				
				const opcode:ABCOpcode = opcodes.splice(index, 1)[0];
				const kind:ABCOpcodeKind = opcode.kind;
				const attribute:ABCOpcodeAttribute = opcode.attribute;
				
				opcodes.slice().reverse().forEach(function(opcode:ABCOpcode, index:int, vector:Vector.<ABCOpcode>):void { trace(opcode.kind); });
				
				switch(kind) {
					case ABCOpcodeKind.ADD:
					case ABCOpcodeKind.ADD_D:
					case ABCOpcodeKind.ADD_I:
					case ABCOpcodeKind.DECREMENT:
					case ABCOpcodeKind.DECREMENT_I:
					case ABCOpcodeKind.DIVIDE:
					case ABCOpcodeKind.EQUALS:
					case ABCOpcodeKind.INCREMENT:
					case ABCOpcodeKind.INCREMENT_I:
					case ABCOpcodeKind.MULTIPLY:
					case ABCOpcodeKind.MULTIPLY_I:
					case ABCOpcodeKind.NOT:
					case ABCOpcodeKind.SUBTRACT:
					case ABCOpcodeKind.SUBTRACT_I:
					
						const operatorNumArgument:int = 2;
						const operatorArguments:Vector.<IABCWriteable> = consumeTail(opcodes, operatorNumArgument, indent+1);
						
						if(operatorArguments.length != operatorNumArgument) {
							throw new Error('Operator argument count mismatch (expected=2, recieved=' + operatorArguments.length + ")");
						}
						
						const operatorExpression:IABCOperatorExpression = JSOperatorExpressionFactory.create(opcode.kind, operatorArguments);
						
						// Back patch!
						previous = result.length > 0 ? result[result.length - 1] : null;
						if(previous is IABCMethodCallBuilder && isBuiltinMethod(IABCMethodCallBuilder(previous))) {
							result.push(JSConsumableBlock.create(operatorExpression, result.pop()));
						} else {
							result.push(operatorExpression);
						}
						
						end -= operatorNumArgument;
						index -= operatorNumArgument;
						break;
					
					case ABCOpcodeKind.CALLPROPERTY:
					
						const propertyMethod:IABCMultinameAttributeBuilder = JSAttributeBuilderFactory.create(traits, attribute) as IABCMultinameAttributeBuilder;
						if(propertyMethod) {
							
							const propertyNumArguments:int = JSAttributeBuilderFactory.getNumberArguments(attribute);
							const propertyArguments:Vector.<IABCWriteable> = consumeTail(opcodes, propertyNumArguments, indent+1);
							
							if(propertyArguments.length != propertyNumArguments) {
								throw new Error('Argument count mismatch');
							}
							
							result.push(JSMethodCallBuilder.create(propertyMethod, propertyArguments));
							
							index -= propertyNumArguments;
						} else {
							throw new Error('Unexpected method type');
						}
						
						break;
					
					case ABCOpcodeKind.GETLOCAL_0:
						result.push(getLocal(0));
						break;
					
					case ABCOpcodeKind.PUSHBYTE:
					case ABCOpcodeKind.PUSHDECIMAL:
					case ABCOpcodeKind.PUSHDOUBLE:
					case ABCOpcodeKind.PUSHINT:
					case ABCOpcodeKind.PUSHSTRING:
					case ABCOpcodeKind.PUSHSTRING:
						const attributeBuilder:IABCAttributeBuilder = JSAttributeBuilderFactory.create(traits, opcode.attribute);
						
						// Back patch!
						previous = result.length > 0 ? result[result.length - 1] : null;
						if(previous is IABCMethodCallBuilder && isBuiltinMethod(IABCMethodCallBuilder(previous))) {
							result.push(JSConsumableBlock.create(attributeBuilder, result.pop()));
						} else {
							result.push(attributeBuilder);
						}
						break;
					
					case ABCOpcodeKind.DEBUG:
					case ABCOpcodeKind.DEBUGFILE:
					case ABCOpcodeKind.DEBUGLINE:
						// do nothing here
						break;
					
					default:
						trace(">>>>", kind);
						break;
				}
			}
			
			return result;
		}
		
		private function isBuiltinMethod(method:IABCMethodCallBuilder):Boolean {
			return ABCQualifiedNameType.isBuiltin(method.method.multiname.toQualifiedName());
		}
		
		private function consume(opcodes:Vector.<ABCOpcode>, start:uint, finish:uint):Vector.<IABCWriteable> {
			const result:Vector.<IABCWriteable> = new Vector.<IABCWriteable>();
			
			// TODO: Future scan so we consume future items.
			
			for(var i:uint=start; i<finish; i++) {
				const opcode:ABCOpcode = opcodes.splice(i, 1)[0];
				const kind:ABCOpcodeKind = opcode.kind;
							
				switch(kind) {
					case ABCOpcodeKind.CALLPROPERTY:
					case ABCOpcodeKind.CONSTRUCTPROP:
						const propertyMethod:IABCValueBuilder = JSValueAttributeBuilder.create(opcode.attribute);
						const propertyArguments:Vector.<IABCWriteable> = consumeMethodArguments(result, opcode.attribute);
						if(result.length > 0) {
							// TODO: Should we consume the whole results
							//result.push(JSConsumableBlock.create(result.pop(), JSMethodCallBuilder.create(propertyMethod, propertyArguments)));
						} else {
							//result.push(JSMethodCallBuilder.create(propertyMethod, propertyArguments));
						}
						break;
						
					case ABCOpcodeKind.GETLOCAL_0:
						result.push(getLocal(0));
						break;
						
					case ABCOpcodeKind.GETLOCAL_1:
						result.push(getLocal(1));
						break;
					
					case ABCOpcodeKind.GETLOCAL_2:
						result.push(getLocal(2));
						break;
					
					case ABCOpcodeKind.GETLOCAL_3:
						result.push(getLocal(3));
						break;
						
					case ABCOpcodeKind.GETSUPER:
						const superProperty:IABCValueBuilder = JSValueAttributeBuilder.create(opcode.attribute);
						if(result.length > 0) {
							// TODO: Should we consume the whole results
							result.push(JSConsumableBlock.create(result.pop(), JSConsumableBlock.create(JSValueBuilder.create(JSReservedKind.SUPER.type), superProperty)));
						} else {
							result.push(JSConsumableBlock.create(JSValueBuilder.create(JSReservedKind.SUPER.type), superProperty));
						}
						break;
						
					case ABCOpcodeKind.IFEQ:
					case ABCOpcodeKind.IFFALSE:
					case ABCOpcodeKind.IFGE:
					case ABCOpcodeKind.IFGT:
					case ABCOpcodeKind.IFLE:
					case ABCOpcodeKind.IFLT:
					case ABCOpcodeKind.IFNE:
					case ABCOpcodeKind.IFNGE:
					case ABCOpcodeKind.IFNGT:
					case ABCOpcodeKind.IFNLE:
					case ABCOpcodeKind.IFNLT:
					case ABCOpcodeKind.IFSTRICTEQ:
					case ABCOpcodeKind.IFSTRICTNE:
					case ABCOpcodeKind.IFTRUE:
						result.push(JSIfStatementFactory.create(kind, result.splice(0, result.length)));
						break;
	
					case ABCOpcodeKind.ADD:
					case ABCOpcodeKind.ADD_D:
					case ABCOpcodeKind.ADD_I:
					case ABCOpcodeKind.DECREMENT:
					case ABCOpcodeKind.DECREMENT_I:
					case ABCOpcodeKind.DIVIDE:
					case ABCOpcodeKind.EQUALS:
					case ABCOpcodeKind.INCREMENT:
					case ABCOpcodeKind.INCREMENT_I:
					case ABCOpcodeKind.MULTIPLY:
					case ABCOpcodeKind.MULTIPLY_I:
					case ABCOpcodeKind.NOT:
					case ABCOpcodeKind.SUBTRACT:
					case ABCOpcodeKind.SUBTRACT_I:
						result.push(JSOperatorExpressionFactory.create(opcode.kind, result.splice(0, result.length)));
						break;
					
					case ABCOpcodeKind.PUSHFALSE:
					case ABCOpcodeKind.PUSHNULL:
					case ABCOpcodeKind.PUSHTRUE:
						result.push(JSPrimaryExpressionFactory.create(opcode.kind));
						break;
						
					case ABCOpcodeKind.PUSHBYTE:
					case ABCOpcodeKind.PUSHDECIMAL:
					case ABCOpcodeKind.PUSHDOUBLE:
					case ABCOpcodeKind.PUSHINT:
					case ABCOpcodeKind.PUSHSTRING:
					case ABCOpcodeKind.GETLEX:
					case ABCOpcodeKind.GETPROPERTY:
					case ABCOpcodeKind.PUSHSTRING:
						result.push(JSAttributeBuilderFactory.create(traits, opcode.attribute));
						break;
					
					case ABCOpcodeKind.DUP:
						throw new Error('Invalid duplication (expected=null, recieved=' + kind + ")");
						break;
					
					case ABCOpcodeKind.DEBUG:
					case ABCOpcodeKind.DEBUGFILE:
					case ABCOpcodeKind.DEBUGLINE:
						// do nothing here
						break;
					
					case ABCOpcodeKind.COERCE:
					case ABCOpcodeKind.COERCE_A:
					case ABCOpcodeKind.COERCE_B:
					case ABCOpcodeKind.COERCE_D:
					case ABCOpcodeKind.COERCE_I:
					case ABCOpcodeKind.COERCE_O:
					case ABCOpcodeKind.COERCE_S:
					case ABCOpcodeKind.COERCE_U:
					case ABCOpcodeKind.CONVERT_B:
					case ABCOpcodeKind.CONVERT_D:
					case ABCOpcodeKind.CONVERT_I:
					case ABCOpcodeKind.CONVERT_O:
					case ABCOpcodeKind.CONVERT_S:
					case ABCOpcodeKind.CONVERT_U:
					case ABCOpcodeKind.FINDPROPSTRICT:
						// Ignore these for JS output.
						break;
						
					default:
						trace(">>>", kind);
						break;
				}
			}
			
			return result;
		}
		
		private function consumeMethodArguments(items:Vector.<IABCWriteable>, attribute:ABCOpcodeAttribute):Vector.<IABCWriteable> {
			const numArguments:uint = JSAttributeBuilderFactory.getNumberArguments(attribute);
			return items.splice(items.length - numArguments, numArguments);
		}
				
		private function getLocal(index:uint):IABCAttributeBuilder {
			var result:IABCAttributeBuilder = null;
			
			if(index == 0) {
				result = JSThisArgumentBuilder.create();
			} else if(index <= methodInfo.parameters.length) {
				result = JSArgumentBuilder.create(_arguments[index - 1]);
			} else {
				if(!(methodInfo.needRest || methodInfo.needArguments)) {
					result = JSArgumentBuilder.create(_arguments[index - 1]);
				} else if(methodInfo.needRest){
					result = JSArgumentsBuilder.create();
				} else {
					throw new Error();
				}
			}
			
			return result;
		}
		
		private function addLocal(local:IABCVariableBuilder):Boolean {
			var exists:Boolean = false;
			
			const total:uint = _arguments.length;
			for(var i:uint=0; i<total; i++) {
				const abcParameter:ABCParameter = _arguments[i];
				if(abcParameter.qname.fullName == local.variable.fullName) {
					exists = true;
					break;
				}
			}
			
			if(!exists) {
				_arguments.push(ABCParameter.create(local.variable, local.variable.fullName));
			}
			
			return !exists;
		}
		
		private function createName(opcodes:Vector.<ABCOpcode>, attribute:ABCOpcodeAttribute):Vector.<IABCWriteable> {
			const total:int = opcodes.length - 1;
			const numArguments:uint = JSAttributeBuilderFactory.getNumberArguments(attribute);
			return consume(opcodes, 0, (total - numArguments) - 1);
		}
		
		private function createMethodArguments(opcodes:Vector.<ABCOpcode>, attribute:ABCOpcodeAttribute):Vector.<IABCWriteable> {
			const total:int = opcodes.length - 1;
			const numArguments:uint = JSAttributeBuilderFactory.getNumberArguments(attribute);
			return consume(opcodes, total - numArguments, total);
		}
		
		private function createIfStatementExpression(opcodes:Vector.<ABCOpcode>):JSConsumableBlock {
			const items:Vector.<IABCWriteable> = new Vector.<IABCWriteable>();
			
			const total:uint = opcodes.length;
			
			var previous:uint = 0;
			for(var i:uint=0; i<total; i++) {
				const opcode:ABCOpcode = opcodes[i];
				if(ABCOpcodeKind.isIfType(opcode.kind)) {
					const index:uint = i + 1;
					const statement:Vector.<IABCWriteable> = consume(opcodes, previous, index);
					if(statement.length == 1) {
						items.push(statement[0]);
					} else {
						throw new Error();
					}
					previous = index;
				} else if(ABCOpcodeKind.isType(opcode.kind, ABCOpcodeKind.JUMP)) {
					continue;
				}
			}
			
			return JSIfStatementFactory.make(items);
		}
		
		private function parseInternalBlock(opcode:ABCOpcode, indent:uint):JSStack {
			const stack:JSStack = JSStack.create();
			const opcodes:ABCOpcodeSet = methodInfo.methodBody.opcode;
						
			_position++;
			recursive(stack, indent + 1, opcodes.getJumpTarget(opcode));
			_position--;
			
			return stack;
		}
		
		private function createLocalVariable(index:uint, opcodes:Vector.<ABCOpcode>, offset:uint):IABCVariableBuilder {
			const localQName:ABCQualifiedName = JSLocalVariableBuilder.createLocalQName(index);
			const localVariable:IABCVariableBuilder = JSLocalVariableBuilder.create(localQName, consume(opcodes, 0, offset));
			localVariable.includeKeyword = addLocal(localVariable);
						
			return localVariable;
		}
		
		public function get methodInfo():ABCMethodInfo { return _methodInfo; }
		public function set methodInfo(value:ABCMethodInfo):void { _methodInfo = value; }
		
		public function get traits():Vector.<ABCTraitInfo> { return _traits; }
		public function set traits(value:Vector.<ABCTraitInfo>):void { _traits = value; }
		
		public function get translateData():ABCOpcodeTranslateData { return _translateData; }
		public function set translateData(value:ABCOpcodeTranslateData):void { _translateData = value; }
			
		public function get name():String { return "JSMethodOpcodeBuilder"; }
		
		public function toString(indent:uint=0):String {
			return ABC.toStringCommon(name, indent);
		}
	}
}