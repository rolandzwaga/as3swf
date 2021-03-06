package com.codeazur.as3swf.data.abc.bytecode
{
	import com.codeazur.as3swf.data.abc.bytecode.multiname.ABCMultinameKind;
	import com.codeazur.as3swf.SWFData;
	import com.codeazur.as3swf.data.abc.ABC;
	import com.codeazur.as3swf.data.abc.bytecode.multiname.ABCMultiname;
	import com.codeazur.as3swf.data.abc.bytecode.multiname.ABCMultinameGeneric;
	import com.codeazur.as3swf.data.abc.bytecode.multiname.ABCMultinameLate;
	import com.codeazur.as3swf.data.abc.bytecode.multiname.ABCNamedMultiname;
	import com.codeazur.as3swf.data.abc.bytecode.multiname.ABCNamespace;
	import com.codeazur.as3swf.data.abc.bytecode.multiname.ABCNamespaceSet;
	import com.codeazur.as3swf.data.abc.bytecode.multiname.ABCNamespaceType;
	import com.codeazur.as3swf.data.abc.bytecode.multiname.ABCQualifiedName;
	import com.codeazur.as3swf.data.abc.bytecode.multiname.ABCRuntimeQualifiedName;
	import com.codeazur.as3swf.data.abc.bytecode.multiname.ABCRuntimeQualifiedNameLate;
	import com.codeazur.as3swf.data.abc.io.ABCScanner;
	import com.codeazur.utils.StringUtils;
	/**
	 * @author Simon Richardson - stickupkid@gmail.com
	 */
	public class ABCConstantsPool
	{
		
		public var integerPool:Vector.<int>;
		public var unsignedIntegerPool:Vector.<uint>;
		public var doublePool:Vector.<Number>;
		public var stringPool:Vector.<String>;
		public var namespacePool:Vector.<ABCNamespace>;
		public var namespaceSetPool:Vector.<ABCNamespaceSet>;
		public var multinamePool:Vector.<IABCMultiname>;
		
		public function ABCConstantsPool() {
			integerPool = new Vector.<int>();
			integerPool.push(0);
			
			unsignedIntegerPool = new Vector.<uint>();
			unsignedIntegerPool.push(0);
			
			doublePool = new Vector.<Number>();
			doublePool.push(NaN);
			
			const asterisk : ABCNamespace = ABCNamespace.getType(ABCNamespaceType.ASTERISK);
			
			stringPool = new Vector.<String>();
			stringPool.push(asterisk.value);
			
			namespacePool = new Vector.<ABCNamespace>();
			namespacePool.push(asterisk);
			
			namespaceSetPool = new Vector.<ABCNamespaceSet>();
			namespaceSetPool.push(ABCNamespaceSet.create(new <ABCNamespace>[asterisk]));
			
			multinamePool = new Vector.<IABCMultiname>();
			multinamePool.push(ABCQualifiedName.create(asterisk.value, asterisk));
		}
		
		public function read(data:SWFData, scanner:ABCScanner) : void {
			
			var ref:uint = 0;
			var index:int = 0;
			var sIndex:uint = 0;
			
			index = data.readEncodedU32();
			sIndex = 1;
			while(--index > 0){
				data.position = scanner.getConstantIntegerAtIndex(sIndex++);
				
				integerPool.push(data.readEncodedU32());
			}
			
			index = data.readEncodedU32();
			sIndex = 1;
			while(--index > 0){
				data.position = scanner.getConstantUnsignedIntegerAtIndex(sIndex++);
				
				unsignedIntegerPool.push(data.readEncodedU32());	
			}
			
			index = data.readEncodedU32();
			sIndex = 1;
			while(--index > 0){
				data.position = scanner.getConstantDoubleAtIndex(sIndex++);
				
				doublePool.push(data.readDouble());
			}
			
			index = data.readEncodedU32();
			sIndex = 1;
			while(--index > 0){
				data.position = scanner.getConstantStringAtIndex(sIndex++);
				
				const strLength:uint = data.readEncodedU32();
				const str:String = data.readUTFBytes(strLength);
				if (strLength != str.length) {
					throw new Error("String length mismatch (expected=" + strLength + ", recieved=" + str.length + ")");	
				}
				stringPool.push(str);
			}
			
			data.position = scanner.getConstantNamespace();
			index = data.readEncodedU32();
			sIndex = 1;
			while(--index > 0){
				data.position = scanner.getConstantNamespaceAtIndex(sIndex++); 
				
				const nsByte:int = data.readByte();
				const nsKind:uint = 255 & nsByte;
				const strPoolIndex:uint = data.readEncodedU32();
				if(strPoolIndex >= stringPool.length){
					throw new Error();
				}
				const nsName:String = getStringByIndex(strPoolIndex);
				
				const abcNamespace:ABCNamespace = ABCNamespace.create(nsKind, nsName);
				abcNamespace.byte = nsByte;
				
				namespacePool.push(abcNamespace);
			}
			
			data.position = scanner.getConstantNamespaceSet();
			index = data.readEncodedU32();
			sIndex = 1;
			while(--index > 0){
				data.position = scanner.getConstantNamespaceSetAtIndex(sIndex++); 
				
				const nsSet:ABCNamespaceSet = ABCNamespaceSet.create();
				
				const nsIndex:uint = data.readEncodedU32(); 
				while(--nsIndex > -1){
					const nsPoolIndex:uint = data.readEncodedU32();
					if(nsPoolIndex > namespacePool.length){
						throw new Error();
					}
					nsSet.namespaces.push(getNamespaceByIndex(nsPoolIndex));
				}
				
				namespaceSetPool.push(nsSet);
			}

			data.position = scanner.getConstantMultiname();
			index = data.readEncodedU32();
			sIndex = 1;
			while(--index > 0) {
				data.position = scanner.getConstantMultinameAtIndex(sIndex++); 
				
				var multiname:IABCMultiname;
				const multinameByte:int = data.readByte();
				
				const kind : uint = 255 & multinameByte;
				if(kind == 0x07 || kind == 0x0D){
					
					ref = data.readEncodedU32();
					const ns:ABCNamespace = getNamespaceByIndex(ref);
					ref = data.readEncodedU32();
					const name:String = getStringByIndex(ref);
					multiname = ABCQualifiedName.create(name, ns, kind);
					
				} else if(kind == 0x0f || kind == 0x10){
					
					ref = data.readEncodedU32();
					const strRQname:String = getStringByIndex(ref);
					multiname = ABCRuntimeQualifiedName.create(strRQname, kind);
					
				} else if(kind == 0x11 || kind == 0x12){
					
					multiname = ABCRuntimeQualifiedNameLate.create(kind);
					
				} else if(kind == 0x09 || kind == 0x0E){
					
					ref = data.readEncodedU32();
					const strMName:String = getStringByIndex(ref);
					ref = data.readEncodedU32();
					const namespaces:ABCNamespaceSet = getNamespaceSetByIndex(ref);
					multiname = ABCMultiname.create(strMName, namespaces, kind);
					
				} else if(kind == 0x1B || kind == 0x1C){
					
					ref = data.readEncodedU32();
					const namespacesLate:ABCNamespaceSet = getNamespaceSetByIndex(ref);
					multiname = ABCMultinameLate.create(namespacesLate, kind);
					
				} else if(kind == 0x1D){
					
					ref = data.readEncodedU32();
					const qname:IABCMultiname = getMultinameByIndex(ref);
					ref = data.readEncodedU32();
					var paramIndex:int = ref;
					const params:Vector.<IABCMultiname> = new Vector.<IABCMultiname>();
					
					while(--paramIndex > -1){
						ref = data.readEncodedU32();
						const param:IABCMultiname = getMultinameByIndex(ref);
						params.push(param);
					}
					multiname = ABCMultinameGeneric.create(qname, params);
					
				} else {
					throw new Error();
				}
				
				multiname.byte = multinameByte;
				multinamePool.push(multiname);
			}
		}
		
		public function write(bytes:SWFData):void {
			
			var i:int = 0;
			var total:int = 0;
			
			total = integerPool.length;
			bytes.writeEncodedU32(calculatePoolTotal(total));
			
			for(i=1; i<total; i++) {
				bytes.writeEncodedU32(integerPool[i]);
			}
			
			total = unsignedIntegerPool.length;
			bytes.writeEncodedU32(calculatePoolTotal(total));
			
			for(i=1; i<total; i++) {
				bytes.writeEncodedU32(unsignedIntegerPool[i]);
			}
			
			total = doublePool.length;
			bytes.writeEncodedU32(calculatePoolTotal(total));
			
			for(i=1; i<total; i++) {
				bytes.writeDouble(doublePool[i]);
			}
			
			total = stringPool.length;
			bytes.writeEncodedU32(calculatePoolTotal(total));
			
			for(i=1; i<total; i++) {
				const string:String = stringPool[i];
				bytes.writeEncodedU32(string.length);
				bytes.writeUTFBytes(string);
			}
						
			total = namespacePool.length;
			bytes.writeEncodedU32(calculatePoolTotal(total));
			
			for(i=1; i<total; i++) {
				const ns:ABCNamespace = namespacePool[i];
				bytes.writeUI8(ns.byte);
				bytes.writeEncodedU32(getStringIndex(ns.value));
			}
				
			total = namespaceSetPool.length;
			bytes.writeEncodedU32(calculatePoolTotal(total));
			for(i=1; i<total; i++) {
				const nsSet:ABCNamespaceSet = namespaceSetPool[i];
				const nsSetTotal:int = nsSet.length;
				bytes.writeEncodedU32(nsSetTotal);
				
				for(var j:int=0; j<nsSetTotal; j++) {
					const index:int = getNamespaceIndex(nsSet.getAt(j));
					bytes.writeEncodedU32(index);
				}
			}
									
			total = multinamePool.length;
			bytes.writeEncodedU32(calculatePoolTotal(total));
			
			for(i=1; i<total; i++) {
				const abcMultiname:IABCMultiname = multinamePool[i];
				
				bytes.writeByte(abcMultiname.byte);
				
				switch(abcMultiname.kind) {
					case ABCMultinameKind.QNAME:
					case ABCMultinameKind.QNAME_A:
						
						const qname:ABCQualifiedName = abcMultiname.toQualifiedName();
						bytes.writeEncodedU32(getNamespaceIndex(qname.ns));
						bytes.writeEncodedU32(getStringIndex(qname.label));
						break;
					
					case ABCMultinameKind.RUNTIME_QNAME:
					case ABCMultinameKind.RUNTIME_QNAME_A:
						const runtime:ABCRuntimeQualifiedName = ABCRuntimeQualifiedName(abcMultiname);
						bytes.writeEncodedU32(getStringIndex(runtime.label));
						break;
						
					case ABCMultinameKind.RUNTIME_QNAME_LATE:
					case ABCMultinameKind.RUNTIME_QNAME_LATE_A:
						// does nothing.
						break;
						
					case ABCMultinameKind.MULTINAME:
					case ABCMultinameKind.MULTINAME_A:
						
						const multiname:ABCMultiname = ABCMultiname(abcMultiname);
						bytes.writeEncodedU32(getStringIndex(multiname.label));
						bytes.writeEncodedU32(getNamespaceSetIndex(multiname.namespaces));
						break;
					
					case ABCMultinameKind.MULTINAME_LATE:
					case ABCMultinameKind.MULTINAME_LATE_A:
						
						const multinameLate:ABCMultinameLate = ABCMultinameLate(abcMultiname);
						bytes.writeEncodedU32(getNamespaceSetIndex(multinameLate.namespaces));
						break;
						
					case ABCMultinameKind.GENERIC:
						const generic:ABCMultinameGeneric = ABCMultinameGeneric(abcMultiname);
						
						bytes.writeEncodedU32(getMultinameIndex(generic.qname));
						
						const multinameTotal:int = generic.params.length;
						bytes.writeEncodedU32(multinameTotal);
						
						for(var k:int=0; k<multinameTotal; k++) {
							bytes.writeEncodedU32(getMultinameIndex(generic.params[k]));
						}
						break;
					
					default:	
						throw new Error();
				}
			}
		}
		
		public function getIntegerIndex(integer:int):int {
			return integerPool.indexOf(integer);
		}
		
		public function getIntegerByIndex(index:uint):int {
			return integerPool[index];
		}
		
		public function getUnsignedIntegerIndex(unsignedInteger:uint):int {
			return unsignedIntegerPool.indexOf(unsignedInteger);
		}
		
		public function getUnsignedIntegerByIndex(index:uint):uint {
			return unsignedIntegerPool[index];
		}
		
		public function getDoubleIndex(double:Number):int {
			return doublePool.indexOf(double);
		}
		
		public function getDoubleByIndex(index:uint):Number {
			return doublePool[index];
		}
		
		public function addString(string:String):void {
			if(stringPool.indexOf(string) < 0) {
				stringPool.push(string);
			}
		}
		
		public function getStringIndex(string:String):int {
			return stringPool.indexOf(string);
		}
		
		public function getStringByIndex(index:uint):String {
			return stringPool[index];
		}
		
		public function addMultiname(multiname:IABCMultiname):void {
			if(multiname is ABCNamedMultiname) {
				const nmname:ABCNamedMultiname = ABCNamedMultiname(multiname);
				addString(nmname.label);
			}
			
			if(multiname is ABCQualifiedName) {
				const qname:ABCQualifiedName = multiname.toQualifiedName();
				addNamespace(qname.ns);
			}
			
			if(multiname is ABCMultinameGeneric) {
				const gmname:ABCMultinameGeneric = ABCMultinameGeneric(multiname);
				addMultiname(gmname.qname);
				
				const total:uint = gmname.params.length;
				for(var i:uint=0; i<total; i++) {
					const qnameParam:ABCQualifiedName = gmname.params[i].toQualifiedName();
					addMultiname(qnameParam);
				}
			}
		}
		
		public function getMultinameIndex(multiname:IABCMultiname):int {
			var index:int = -1;
			
			const total:uint = multinamePool.length;
			for(var i:uint=0; i<total; i++) {
				const m:IABCMultiname = multinamePool[i];
				if(m.byte == multiname.byte && m.fullName == multiname.fullName) {
					index = i;
					break;
				}
			}
			
			return index;
		}
		
		public function getMultinameByIndex(index:uint):IABCMultiname {
			return multinamePool[index];
		}
		
		public function addNamespace(ns:ABCNamespace):void {
			if(namespacePool.indexOf(ns) < 0) {
				namespacePool.push(ns);
			}
		}
		
		public function getNamespaceIndex(ns:ABCNamespace):int {
			var index:int = -1;
			
			const total:uint = namespacePool.length;
			for(var i:uint=0; i<total; i++) {
				const n:ABCNamespace = namespacePool[i];
				
				if(n.byte == ns.byte && n.value == ns.value) {
					index = i;
					break;
				}
			}
			
			return index;
		}
		
		public function getNamespaceByIndex(index:uint):ABCNamespace {
			return namespacePool[index];
		}
		
		public function addNamespaceSet(ns:ABCNamespaceSet):void {
			if(namespaceSetPool.indexOf(ns) < 0) {
				namespaceSetPool.push(ns);
			}
		}
		
		public function getNamespaceSetIndex(ns:ABCNamespaceSet):int {
			var index:int = 0;
			
			const total:uint = namespaceSetPool.length;
			for(var i:uint=0; i<total; i++) {
				const n:ABCNamespaceSet = namespaceSetPool[i];
				const nsTotal:uint = ns.length;
				if(n.length == nsTotal) {
					// deep match
					var contains:Boolean = true;
					for(var j:uint=0; j<nsTotal; j++) {
						const s:ABCNamespace = ns.getAt(j);
						if(getNamespaceIndex(s) < 0) {
							contains = false;
							break;
						}
					}
					
					if(contains) {
						index = i;
						break;
					}
				}
			}
			
			return index;
		}
		
		public function getNamespaceSetByIndex(index:uint):ABCNamespaceSet {
			return namespaceSetPool[index];
		}
		
		public function getPoolItemByKindAtIndex(kind:ABCConstantKind, index:uint):* {
			var item:*;
			switch(kind) {
				case ABCConstantKind.INT:
					item = getIntegerByIndex(index);
					break;
					
				case ABCConstantKind.UINT:
					item = getUnsignedIntegerByIndex(index);
					break;	
				
				case ABCConstantKind.DOUBLE:
					item = getDoubleByIndex(index);
					break;
				
				case ABCConstantKind.UTF8:
					item = getStringByIndex(index);
					break;
				
				case ABCConstantKind.NAMESPACE:
				case ABCConstantKind.PACKAGE_NAMESPACE:
				case ABCConstantKind.PACKAGE_INTERNAL_NAMESPACE:
				case ABCConstantKind.PROTECTED_NAMESPACE:
				case ABCConstantKind.EXPLICIT_NAMESPACE:
				case ABCConstantKind.STATIC_PROTECTED_NAMESPACE:
				case ABCConstantKind.PRIVATE_NAMESPACE:
					item = getNamespaceByIndex(index);
					break;
				
				case ABCConstantKind.TRUE:
					item = true;
					break;
				
				case ABCConstantKind.FALSE:
					item = false;
					break;
				
				case ABCConstantKind.NULL:
					item = null;
					break;
				
				case ABCConstantKind.UNDEFINED:
					item = undefined;
					break;
			}
			
			return item;
		}
		
		private function calculatePoolTotal(value:uint):uint {
			return value <= 1 ? 0 : value;
		}
		
		public function get name():String { return "ABCConstantsPool"; }
		
		public function toString(indent:uint = 0) : String {
			var i:uint;
			var str:String = ABC.toStringCommon(name, indent);
			
			if(integerPool.length > 0) { 
				str += "\n" + StringUtils.repeat(indent + 2) + "IntegerPool:";
				for(i = 0; i < integerPool.length; i++) {
					str += "\n" + StringUtils.repeat(indent + 4) + integerPool[i].toString();
				}
			}
			if(unsignedIntegerPool.length > 0) { 
				str += "\n" + StringUtils.repeat(indent + 2) + "UnsignedIntegerPool:";
				for(i = 0; i < unsignedIntegerPool.length; i++) {
					str += "\n" + StringUtils.repeat(indent + 4) + unsignedIntegerPool[i].toString();
				}
			}
			if(doublePool.length > 0) { 
				str += "\n" + StringUtils.repeat(indent + 2) + "DoublePool:";
				for(i = 0; i < doublePool.length; i++) {
					str += "\n" + StringUtils.repeat(indent + 4) + doublePool[i].toString();
				}
			}
			if(stringPool.length > 0) { 
				str += "\n" + StringUtils.repeat(indent + 2) + "StringPool:";
				for(i = 0; i < stringPool.length; i++) {
					str += "\n" + StringUtils.repeat(indent + 4) + stringPool[i].toString();
				}
			}
			if(namespacePool.length > 0) { 
				str += "\n" + StringUtils.repeat(indent + 2) + "NamespacePool:";
				for(i = 0; i < namespacePool.length; i++) {
					str += "\n" + namespacePool[i].toString(indent + 4);
				}
			}
			if(namespaceSetPool.length > 0) { 
				str += "\n" + StringUtils.repeat(indent + 2) + "NamespaceSetPool:";
				for(i = 0; i < namespaceSetPool.length; i++) {
					str += "\n" + namespaceSetPool[i].toString(indent + 4);
				}
			}
			
			if(multinamePool.length > 0) { 
				str += "\n" + StringUtils.repeat(indent + 2) + "MultinamePool:";
				for(i = 0; i < multinamePool.length; i++) {
					str += "\n" + multinamePool[i].toString(indent + 4);
				}
			}
			
			return str;
		}
	}
}
