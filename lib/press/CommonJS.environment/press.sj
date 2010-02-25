@STATIC;1.0;p;6;main.jt;8382;@STATIC;1.0;I;23;Foundation/Foundation.jI;15;AppKit/AppKit.ji;21;objj-analysis-tools.ji;20;cib-analysis-tools.jt;8264;
require("narwhal").ensureEngine("rhino");
objj_executeFile("Foundation/Foundation.j",false);
objj_executeFile("AppKit/AppKit.j",false);
objj_executeFile("objj-analysis-tools.j",true);
objj_executeFile("cib-analysis-tools.j",true);
var _1=require("file");
var OS=require("os");
var _2=require("term").stream;
var _3=new (require("args").Parser)();
_3.usage("INPUT_PROJECT OUTPUT_PROJECT");
_3.help("Analyze and strip unused files from a Cappuccino project's .sj bundles.");
_3.option("-m","--main","main").def("main.j").set().help("The relative path (from INPUT_PROJECT) to the main file (default: 'main.j')");
_3.option("-F","--framework","frameworks").def(["Frameworks"]).push().help("Add a frameworks directory, relative to INPUT_PROJECT (default: ['Frameworks'])");
_3.option("-E","--environment","environments").def(["Browser"]).push().help("Add a platform name (default: ['Browser'])");
_3.option("-f","--force","force").def(false).set(true).help("Force overwriting OUTPUT_PROJECT if it exists");
_3.option("-p","--pngcrush","png").def(false).set(true).help("Run pngcrush on all PNGs (pngcrush must be installed!)");
_3.option("-v","--verbose","verbose").def(false).set(true).help("Verbose logging");
_3.helpful();
main=function(_4){
var _5=_3.parse(_4);
if(_5.args.length<2){
_3.printUsage(_5);
return;
}
CPLogRegister(CPLogPrint);
var _6=_1.path(_5.args[0]).absolute().join("");
var _7=_1.path(_5.args[1]).absolute().join("");
if(_7.exists()){
if(_5.force){
OS.system(["rm","-rf",_7]);
}else{
CPLog.error("OUTPUT_PROJECT "+_7+" exists. Use -f to overwrite.");
OS.exit(1);
}
}
press(_6,_7,_5);
};
press=function(_8,_9,_a){
_2.print("\x00yellow("+Array(81).join("=")+"\x00)");
_2.print("Application root:    \x00green("+_8+"\x00)");
_2.print("Output directory:    \x00green("+_9+"\x00)");
var _b={},_c={executable:0,data:0,mhtml:0};
_a.environments.forEach(function(_d){
var _e=pressEnvironment(_8,_b,_d,_a);
for(var i in _e){
_c[i]+=_e[i];
}
});
_2.print("\x00red(PHASE 4:\x00) copy to output \x00green("+_8+"\x00) => \x00green("+_9+"\x00)");
_1.copyTree(_8,_9);
for(var _f in _b){
var _10=_9.join(_8.relative(_f));
var _11=_10.dirname();
if(!_11.exists()){
CPLog.warn(_11+" doesn't exist, creating directories.");
_11.mkdirs();
}
if(typeof _b[_f]!=="string"){
_b[_f]=_b[_f].join("");
}
_2.print((_10.exists()?"\x00red(Overwriting:\x00) ":"\x00green(Writing:\x00)     ")+_10);
_1.write(_10,_b[_f],{charset:"UTF-8"});
}
_2.print("\x00red(PHASE 4a:\x00) Add application size data to Info.plist");
var _12=_1.join(_9,"Info.plist"),_13=_1.read(_12,{charset:"UTF-8"}),_14=CFPropertyList.sniffedFormatOfString(_13),_15=CFPropertyList.propertyListFromString(_13);
var _16=_15.valueForKey("CPDefaultTheme")||"Aristo",_17=_1.join(_9,_a.frameworks,"AppKit","Resources",_16+".blend");
if(_1.exists(_17)){
var _18=_1.join(_17,_a.environments[0]+".environment"),_19=_1.join(_18,_16+".blend.sj"),_1a=_1.join(_18,"dataURLs.txt"),_1b=_1.join(_18,"MHTMLPaths.txt");
_c.executable+=_1.read(_19,{charset:"UTF-8"}).length;
_c.data+=_1.read(_1a,{charset:"UTF-8"}).length;
_c.mhtml+=_1.read(_1b,{charset:"UTF-8"}).length;
}
_15.setValueForKey("CPApplicationSize",objj_msgSend(CPDictionary,"dictionaryWithJSObject:",_c));
_1.write(_12,CFPropertyList.stringFromPropertyList(_15,_14),{charset:"UTF-8"});
if(_a.png){
pngcrushDirectory(_9);
}
};
pressEnvironment=function(_1c,_1d,_1e,_1f){
var _20=String(_1c.join(_1f.main));
var _21=_1f.frameworks.map(function(_22){
return _1c.join(_22);
});
_2.print("\x00yellow("+Array(81).join("=")+"\x00)");
_2.print("Main file:           \x00green("+_20+"\x00)");
_2.print("Frameworks:          \x00green("+_21+"\x00)");
_2.print("Environment:         \x00green("+_1e+"\x00)");
var _23=new ObjectiveJRuntimeAnalyzer(_1c);
var _24=_23.require("objective-j");
_23.setIncludePaths(_21);
_23.setEnvironments([_1e,"ObjJ"]);
var _25=_1.glob(_1c.join("**","*.cib")).filter(function(_26){
return !(/Frameworks/).test(_26);
});
_2.print("\x00red(PHASE 1:\x00) Loading application...");
_23.initializeGlobalRecorder();
_23.load(_20);
_23.finishLoading();
var _27=_23.mapGlobalsToFiles();
_2.print("Global defines:");
Object.keys(_27).sort().forEach(function(_28){
_2.print("\x00blue("+_28+"\x00) => \x00cyan("+_27[_28].map(_1c.relative.bind(_1c))+"\x00)");
});
_2.print("\x00red(PHASE 2:\x00) Traverse dependency graph...");
var _29={};
_29[_20]=true;
var _2a={ignoreFrameworkImports:true,importCallback:function(_2b,_2c){
_29[_2c]=true;
},referenceCallback:function(_2d,_2e){
_29[_2e]=true;
},progressCallback:function(_2f){
_2.print("Processing \x00cyan("+_2f+"\x00)");
},ignoreFrameworkImportsCallback:function(_30){
_2.print("\x00yellow(Ignoring imports in "+_30+"\x00)");
}};
mainExecutable=_23.executableForImport(_20);
_23.traverseDependencies(mainExecutable,_2a);
var _31=_23.mapGlobalsToFiles();
_25.forEach(function(_32){
var _33=findCibClassDependencies(_32);
_2.print("Cib: \x00green("+_1c.relative(_32)+"\x00) => \x00cyan("+_33+"\x00)");
var _34={};
markFilesReferencedByTokens(_33,_31,_34);
_23.checkReferenced(_2a,null,_34);
});
var _35=0,_36=0;
var _37=0,_38=0,_39=0,_3a=0;
_24.FileExecutable.allFileExecutables().forEach(function(_3b){
var _3c=_3b.path();
if(/\.keyedtheme$/.test(_3c)){
_29[_3c]=true;
}
if(_29[_3c]){
_2.print("Included: \x00green("+_1c.relative(_3c)+"\x00)");
_35++;
_37+=_3b.code().length;
}else{
_2.print("Excluded: \x00red("+_1c.relative(_3c)+"\x00)");
}
_36++;
_38+=_3b.code().length;
},this);
_2.print(sprintf("Saved \x00green(%f%%\x00) (\x00blue(%s\x00)); Total required files: \x00magenta(%d\x00) (\x00blue(%s\x00)) of \x00magenta(%d\x00) (\x00blue(%s\x00));",Math.round(((_37-_38)/_38)*-100),bytesToString(_38-_37),_35,bytesToString(_37),_36,bytesToString(_38)));
_2.print("\x00red(PHASE 3b:\x00) Rebuild .sj files");
var _3d={};
for(var _3e in _29){
var _3f=_23.executableForImport(_3e),_40=_23.context.global.CFBundle.bundleContainingPath(_3f.path()),_41=_1.relative(_1.join(_40.path(),""),_3f.path());
if(_3f.path()!==_3e){
CPLog.warn("Sanity check failed (file path): "+_3f.path()+" vs. "+_3e);
}
if(_40&&_40.infoDictionary()){
var _42=_40.executablePath();
if(_42){
if(_2a.ignoredImports[_3e]){
_2.print("Stripping extra imports from \x00blue("+_3e+"\x00)");
var _43=_3f.code();
var _27=_3f.fileDependencies();
for(var i=0;i<_27.length;i++){
var _44=_27[i];
var _45=new _24.FileExecutableSearch(_44.isLocal()?_1.join(_1.dirname(_3e),_44.path()):_44.path(),_44.isLocal()).result();
var _46=_45.path();
if(!_29[_46]){
_2.print(" -> \x00red("+_46+"\x00)");
var _47=new RegExp([RegExp.escape("objj_executeFile"),RegExp.escape("("),"[\"']"+RegExp.escape(_44.path())+"[\"']",RegExp.escape(","),RegExp.escape(_44.isLocal()?"true":"false"),RegExp.escape(")")].join("\\s*"),"g");
_43=_43.replace(_47,"/* $& */ (undefined)");
_27.splice(i--,1);
}
}
if(_43!==_3f.code()){
_3f.setCode(_43);
}
}
if(!_1d[_42]){
_1d[_42]=[];
_1d[_42].push("@STATIC;1.0;");
}
var _48=_3f.toMarkedString();
_1d[_42].push("p;"+_41.length+";"+_41);
_1d[_42].push("t;"+_48.length+";"+_48);
_2.print("Adding \x00green("+_1c.relative(_3e)+"\x00) to \x00cyan("+_1c.relative(_42)+"\x00)");
}else{
_2.print("Passing .j through: \x00green("+_1c.relative(_3e)+"\x00)");
}
if(!_3d[_40.path()]&&_40.hasSpritedImages()){
_3d[_40.path()]=_40;
_2.print("Sizing bundle's sprited resources \x00green("+_40.path()+"\x00)");
var _49=_1.join(_40.path(),_1e+".environment"),_4a=_1.join(_49,"dataURLs.txt"),_4b=_1.join(_49,"MHTMLPaths.txt");
_39+=_1.read(_4a,{charset:"UTF-8"}).length;
_3a+=_1.read(_4b,{charset:"UTF-8"}).length;
}
}else{
CPLog.warn("No bundle (or info dictionary for) "+_1c.relative(_3e));
}
}
return {executable:_37,data:_39,mhtml:_3a};
};
pngcrushDirectory=function(_4c){
var _4d=_1.path(_4c);
var _4e=_4d.glob("**/*.png");
system.stderr.print("Running pngcrush on "+_4e.length+" pngs:");
_4e.forEach(function(dst){
var _4f=_4d.join(dst);
var _50=_1.path(_4f+".tmp");
var p=OS.popen(["pngcrush","-rem","alla","-reduce",_4f,_50]);
if(p.wait()){
CPLog.warn("pngcrush failed. Ensure it's installed and on your PATH.");
}else{
_1.move(_50,_4f);
system.stderr.write(".").flush();
}
});
system.stderr.print("");
};
bytesToString=function(_51){
var n=0;
while(_51>1024){
_51/=1024;
n++;
}
return Math.round(_51*100)/100+" "+["","K","M"][n]+"B";
};
p;21;objj-analysis-tools.jt;6710;@STATIC;1.0;t;6691;
var _1=require("file");
var _2=require("objective-j");
var _3=require("interpreter").Context;
ObjectiveJRuntimeAnalyzer=function(_4){
this.rootPath=_4;
this.context=new _3();
this.scope=setupObjectiveJ(this.context);
this.require=this.context.global.require;
};
ObjectiveJRuntimeAnalyzer.prototype.setIncludePaths=function(_5){
this.context.global.OBJJ_INCLUDE_PATHS=_5;
};
ObjectiveJRuntimeAnalyzer.prototype.setEnvironments=function(_6){
this.context.global.CFBundle.environments=function(){
return _6;
};
};
ObjectiveJRuntimeAnalyzer.prototype.initializeGlobalRecorder=function(){
this.initializeGlobalRecorder=function(){
};
this.ignore=cloneProperties(this.scope,true);
this.files={};
var _7=[];
var _8=null;
var _9=null;
var _a=this;
recordAndReset=function(){
var _b=cloneProperties(_a.scope);
if(_8){
_a.files[_9]=_a.files[_9]||{};
_a.files[_9].globals=_a.files[_9].global||{};
diff({before:_8,after:_b,ignore:_a.ignore,added:_a.files[_9].globals,changed:_a.files[_9].globals});
}
_8=_b;
};
var _c=this.require("objective-j");
var _d=_c.Executable.fileExecuterForPath;
_c.Executable.fileExecuterForPath=function(_e){
var _f=_d.apply(this,arguments);
return function(_10,_11,_12){
recordAndReset();
_7.push(_9);
if(_11&&!_1.isAbsolute(_10)){
_9=_1.normal(_1.join(_e,_10));
}else{
_9=_10;
}
system.stderr.write(">").flush();
_f.apply(this,arguments);
system.stderr.write("<").flush();
recordAndReset();
_9=_7.pop();
};
};
};
ObjectiveJRuntimeAnalyzer.prototype.load=function(_13){
this.require("objective-j").objj_eval("("+(function(_14){
objj_importFile(_14,true,function(){
print("Done importing and evaluating: "+_14);
});
})+")")(_13);
};
ObjectiveJRuntimeAnalyzer.prototype.finishLoading=function(_15){
this.require("browser/timeout").serviceTimeouts();
};
ObjectiveJRuntimeAnalyzer.prototype.mapGlobalsToFiles=function(){
this.mergeLibraryImports();
var _16={};
for(var _17 in this.files){
for(var _18 in this.files[_17].globals){
(_16[_18]=_16[_18]||[]).push(_17);
}
}
return _16;
};
ObjectiveJRuntimeAnalyzer.prototype.mapFilesToGlobals=function(){
this.mergeLibraryImports();
var _19={};
for(var _1a in this.files){
_19[_1a]={};
for(var _1b in this.files[_1a].globals){
_19[_1a][_1b]=true;
}
}
return _19;
};
ObjectiveJRuntimeAnalyzer.prototype.mergeLibraryImports=function(){
for(var _1c in this.files){
if(_1.isRelative(_1c)){
var _1d=this.executableForImport(_1c,false).path();
this.files[_1d]=this.files[_1d]||{};
this.files[_1d].globals=this.files[_1d].globals||{};
for(var _1e in this.files[_1c].globals){
this.files[_1d].globals[_1e]=true;
}
delete this.files[_1c];
}
}
};
ObjectiveJRuntimeAnalyzer.prototype.executableForImport=function(_1f,_20){
if(_20===undefined){
_20=true;
}
var _21=this.require("objective-j");
return new _21.FileExecutableSearch(_1f,_20).result();
};
ObjectiveJRuntimeAnalyzer.prototype.traverseDependencies=function(_22,_23){
_23=_23||{};
_23.processedFiles=_23.processedFiles||{};
_23.importedFiles=_23.importedFiles||{};
_23.referencedFiles=_23.referencedFiles||{};
_23.ignoredImports=_23.ignoredImports||{};
var _24=_22.path();
if(_23.processedFiles[_24]){
return;
}
_23.processedFiles[_24]=true;
var _25=false;
if(_23.ignoreAllImports){
_25=true;
}else{
if(_23.ignoreFrameworkImports){
var _26=_24.match(new RegExp("([^\\/]+)\\/([^\\/]+)\\.j$"));
if(_26&&_26[1]===_26[2]){
_25=true;
}
}
}
var _27={},_28={};
if(_23.progressCallback){
_23.progressCallback(this.rootPath.relative(_24),_24);
}
var _29=_22.code();
var _2a=uniqueTokens(_29);
markFilesReferencedByTokens(_2a,this.mapGlobalsToFiles(),_27);
delete _27[_24];
if(_25){
if(_23.ignoreImportsCallback){
_23.ignoreImportsCallback(this.rootPath.relative(_24),_24);
}
_23.ignoredImports[_24]=true;
}else{
_22.fileDependencies().forEach(function(_2b){
var _2c=null;
if(_2b.isLocal()){
_2c=this.executableForImport(_1.normal(_1.join(_1.dirname(_24),_2b.path())),true);
}else{
_2c=this.executableForImport(_2b.path(),false);
}
if(_2c){
var _2d=_2c.path();
if(_2d!==_24){
_28[_2d]=true;
}else{
CPLog.error("Ignoring self import (why are you importing yourself?!): "+this.rootPath.relative(_2d));
}
}else{
CPLog.error("Couldn't find file for import "+_2b.path()+" ("+_2b.isLocal()+")");
}
},this);
}
this.checkImported(_23,_24,_28);
_23.importedFiles[_24]=_28;
this.checkReferenced(_23,_24,_27);
_23.referencedFiles[_24]=_27;
return _23;
};
ObjectiveJRuntimeAnalyzer.prototype.checkImported=function(_2e,_2f,_30){
for(var _31 in _30){
if(_31!==_2f){
if(_2e.importCallback){
_2e.importCallback(_2f,_31);
}
var _32=this.executableForImport(_31,true);
if(_32){
this.traverseDependencies(_32,_2e);
}else{
CPLog.error("Missing imported file: "+_31);
}
}
}
};
ObjectiveJRuntimeAnalyzer.prototype.checkReferenced=function(_33,_34,_35){
for(var _36 in _35){
if(_36!==_34){
if(_33.referenceCallback){
_33.referenceCallback(_34,_36,_35[_36]);
}
var _37=this.executableForImport(_36,true);
if(_37){
this.traverseDependencies(_37,_33);
}else{
CPLog.error("Missing referenced file: "+_36);
}
}
}
};
ObjectiveJRuntimeAnalyzer.prototype.fileExecutables=function(){
var _38=this.require("objective-j");
return _38.FileExecutablesForPaths;
};
uniqueTokens=function(_39){
var _3a=new _2.Lexer(_39,null);
var _3b,_3c={};
while(_3b=_3a.skip_whitespace()){
_3c[_3b]=true;
}
return Object.keys(_3c);
};
markFilesReferencedByTokens=function(_3d,_3e,_3f){
_3d.forEach(function(_40){
if(_3e.hasOwnProperty(_40)){
var _41=_3e[_40];
for(var i=0;i<_41.length;i++){
_3f[_41[i]]=_3f[_41[i]]||{};
_3f[_41[i]][_40]=true;
}
}
});
};
setupObjectiveJ=function(_42){
_42.global.NARWHAL_HOME=system.prefix;
_42.global.NARWHAL_ENGINE_HOME=_1.join(system.prefix,"engines","rhino");
var _43=_1.join(_42.global.NARWHAL_ENGINE_HOME,"bootstrap.js");
_42.evalFile(_43);
_42.global.require("browser");
var _44=_42.global.require("objective-j");
addMockBrowserEnvironment(_44.window);
return _44.window;
};
addMockBrowserEnvironment=function(_45){
if(!_45.window){
_45.window=_45;
}
if(!_45.location){
_45.location={};
}
if(!_45.location.href){
_45.location.href="";
}
if(!_45.Element){
_45.Element=function(){
this.style={};
};
}
if(!_45.document){
_45.document={createElement:function(){
return new _45.Element();
}};
}
};
cloneProperties=function(_46,_47){
var _48={};
for(var _49 in _46){
_48[_49]=_47?true:_46[_49];
}
return _48;
};
diff=function(o){
for(var i in o.after){
if(o.added&&!o.ignore[i]&&typeof o.before[i]=="undefined"){
o.added[i]=true;
}
}
for(var i in o.after){
if(o.changed&&!o.ignore[i]&&typeof o.before[i]!="undefined"&&typeof o.after[i]!="undefined"&&o.before[i]!==o.after[i]){
o.changed[i]=true;
}
}
for(var i in o.before){
if(o.deleted&&!o.ignore[i]&&typeof o.after[i]=="undefined"){
o.deleted[i]=true;
}
}
};
p;20;cib-analysis-tools.jt;1634;@STATIC;1.0;I;23;Foundation/Foundation.jI;15;AppKit/AppKit.jt;1567;
objj_executeFile("Foundation/Foundation.j",false);
objj_executeFile("AppKit/AppKit.j",false);
findCibClassDependencies=function(_1){
var _2=objj_msgSend(objj_msgSend(CPCib,"alloc"),"initWithContentsOfURL:",_1);
var _3={};
var _4=CPClassFromString;
CPClassFromString=function(_5){
var _6=_4(_5);
_3[_5]=true;
return _6;
};
objj_msgSend(CPApplication,"sharedApplication");
try{
var x=objj_msgSend(_2,"pressInstantiate");
}
catch(e){
CPLog.warn("Exception thrown when instantiating "+_1+": "+e);
}
finally{
CPClassFromString=_4;
}
return Object.keys(_3);
};
var _7=objj_getClass("CPCib");
if(!_7){
throw new SyntaxError("*** Could not find definition for class \"CPCib\"");
}
var _8=_7.isa;
class_addMethods(_7,[new objj_method(sel_getUid("pressInstantiate"),function(_9,_a){
with(_9){
var _b=_bundle,_c=nil;
if(!_b&&_c){
_b=objj_msgSend(CPBundle,"bundleForClass:",objj_msgSend(_c,"class"));
}
var _d=objj_msgSend(objj_msgSend(_CPCibKeyedUnarchiver,"alloc"),"initForReadingWithData:bundle:awakenCustomResources:",_data,_b,_awakenCustomResources),_e=nil;
if(_e){
var _f=nil,_10=objj_msgSend(_e,"keyEnumerator");
while(_f=objj_msgSend(_10,"nextObject")){
objj_msgSend(_d,"setClass:forClassName:",objj_msgSend(_e,"objectForKey:",_f),_f);
}
}
objj_msgSend(_d,"setExternalObjectsForProxyIdentifiers:",nil);
var _11=objj_msgSend(_d,"decodeObjectForKey:","CPCibObjectDataKey");
if(!_11||!objj_msgSend(_11,"isKindOfClass:",objj_msgSend(_CPCibObjectData,"class"))){
return NO;
}
var _12=nil;
objj_msgSend(_11,"instantiateWithOwner:topLevelObjects:",_c,_12);
return YES;
}
})]);
e;