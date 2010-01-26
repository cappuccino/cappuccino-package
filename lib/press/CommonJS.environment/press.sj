@STATIC;1.0;p;6;main.jc;198;
var OS=require("os");
if(system.engine!=="rhino"){
system.args.splice(1,2);
var _1="NARWHAL_ENGINE_HOME='' NARWHAL_ENGINE='rhino' "+system.args.map(OS.enquote).join(" ");
OS.exit(OS.system(_1));
}
I;23;Foundation/Foundation.ji;21;objj-analysis-tools.jc;10071;
var _1=require("args");
var _2=require("file");
var OS=require("os");
var _3=require("browser/dom");
var _4=require("interpreter");
var _5=new _3.XMLSerializer();
var _6=new _1.Parser();
_6.usage("INPUT_PROJECT OUTPUT_PROJECT");
_6.help("Optimizes Cappuccino applications for deployment to the web.");
_6.option("-m","--main","main").def("main.j").set().help("The relative path (from INPUT_PROJECT) to the main file (default: 'main.j')");
_6.option("-F","--framework","frameworks").def(["Frameworks"]).push().help("Add a frameworks directory, relative to INPUT_PROJECT (default: ['Frameworks'])");
_6.option("-E","--environment","environments").def(["W3C"]).push().help("Add a platform name (default: ['W3C', 'IE7', 'IE8'])");
_6.option("-l","--flatten","flatten").def(false).set(true).help("Flatten all code into a single Application.js file and attempt add script tag to index.html (useful for Adobe AIR and CDN deployment)");
_6.option("-f","--force","force").def(false).set(true).help("Force overwriting OUTPUT_PROJECT if it exists");
_6.option("-n","--nostrip","strip").def(true).set(false).help("Do not strip any files");
_6.option("-p","--pngcrush","png").def(false).set(true).help("Run pngcrush on all PNGs (pngcrush must be installed!)");
_6.option("-v","--verbose","verbose").def(false).set(true).help("Verbose logging");
_6.helpful();
main=function(_7){
var _8=_6.parse(_7);
if(_8.args.length<2){
_6.printUsage(_8);
return;
}
CPLogRegister(CPLogPrint);
var _9=_2.path(_8.args[0]).join("").absolute();
var _a=_2.path(_8.args[1]).join("").absolute();
if(_a.exists()){
if(_8.force){
_a.rmtree();
}else{
CPLog.error("OUTPUT_PROJECT "+_a+" exists. Use -f to overwrite.");
OS.exit(1);
}
}
press(_9,_a,_8);
};
press=function(_b,_c,_d){
CPLog.info("===========================================");
CPLog.info("Application root:    "+_b);
CPLog.info("Output directory:    "+_c);
var _e={};
_d.environments.forEach(function(_f){
pressEnvironment(_b,_e,_f,_d);
});
CPLog.error("PHASE 4: copy to output ("+_b+" to "+_c+")");
_2.copyTree(_b,_c);
for(var _10 in _e){
var _11=_c.join(_b.relative(_10));
var _12=_11.dirname();
if(!_12.exists()){
CPLog.warn(_12+" doesn't exist, creating directories.");
_12.mkdirs();
}
if(typeof _e[_10]!=="string"){
_e[_10]=_e[_10].join("");
}
CPLog.info((_11.exists()?"Overwriting: ":"Writing:     ")+_11);
_2.write(_11,_e[_10],{charset:"UTF-8"});
}
if(_d.png){
pngcrushDirectory(_c);
}
};
pressEnvironment=function(_13,_14,_15,_16){
var _17=String(_13.join(_16.main));
var _18=_16.frameworks.map(function(_19){
return _13.join(_19);
});
CPLog.info("===========================================");
CPLog.info("Main file:           "+_17);
CPLog.info("Frameworks:          "+_18);
CPLog.info("Environment:         "+_15);
var _1a=new _4.Context();
var _1b=setupObjectiveJ(_1a);
_1b.OBJJ_INCLUDE_PATHS=_18;
_1b.OBJJ_ENVIRONMENTS=[_15,"ObjJ"];
var _1c=[];
var _1d=[];
var _1e=[];
functionHookBefore(_1b.objj_search.prototype,"didReceiveBundleResponse",function(_1f){
var _20={success:_1f.success,filePath:_13.relative(_1f.filePath).toString()};
if(_1f.success){
var _21=_5.serializeToString(_1f.xml);
_20.text=CPPropertyListCreate280NorthData(CPPropertyListCreateFromXMLData({string:_21})).string;
}
_1c.push(_20);
});
functionHookBefore(_1b.objj_search.prototype,"didReceiveExecutableResponse",function(_22){
_1d.push(_22);
});
_1a.rootPath=_13;
_1a.scope=_1b;
CPLog.error("PHASE 1: Loading application...");
var _23=findGlobalDefines(_1a,_17,_1e);
var _24=coalesceGlobalDefines(_23);
CPLog.trace("Global defines:");
Object.keys(_24).sort().forEach(function(_25){
CPLog.trace("    "+_25+" => "+_13.relative(_24[_25]));
});
CPLog.error("PHASE 2: Walk dependency tree...");
var _26={};
if(_16.nostrip){
_26=_1b.objj_files;
}else{
if(!_1b.objj_files[_17]){
CPLog.error("Root file not loaded!");
return;
}
CPLog.warn("Analyzing dependencies...");
_1a.dependencies=_24;
_1a.ignoreFrameworkImports=true;
_1a.importCallback=function(_27,_28){
_26[_28]=true;
};
_1a.referenceCallback=function(_29,_2a){
_26[_2a]=true;
};
_26[_17]=true;
traverseDependencies(_1a,_1b.objj_files[_17]);
var _2b=0,_2c=0;
for(var _2d in _1b.objj_files){
if(/\.keyedtheme$/.test(_2d)){
_26[_2d]=true;
}
if(_26[_2d]){
CPLog.debug("Included: "+_13.relative(_2d));
_2b++;
}else{
CPLog.info("Excluded: "+_13.relative(_2d));
}
_2c++;
}
CPLog.warn("Total required files: "+_2b+" out of "+_2c);
}
if(_16.flatten){
CPLog.error("PHASE 3a: Flattening...");
var _2e="Application-"+_15+".js";
var _2f="index-"+_15+".html";
var _30=function(_31){
var _32=new objj_bundle();
_32.path=_31.filePath;
if(_31.success){
var _33=new objj_data();
_33.string=_31.text;
_32.info=CPPropertyListCreateFrom280NorthData(_33);
}else{
_32.info=new objj_dictionary();
}
objj_bundles[_31.filePath]=_32;
};
var _34=function(_35){
var _36=function(_37){
return (_37).substr(0,(_37).lastIndexOf("/")+1);
};
for(var _38 in _35){
if(objj_bundles[_38]){
var _39=_35[_38];
objj_bundles[_38]._URIMap={};
for(var _3a in _39){
var URI=_39[_3a];
if(URI.toLowerCase().indexOf("mhtml:")===0){
objj_bundles[_38]._URIMap[_3a]="mhtml:"+_36(window.location.href)+"/"+URI.substr("mhtml:".length);
}
}
}else{
console.log("no bundle for "+_38);
}
}
};
var _3b=[];
var _3c={};
Object.keys(_1b.objj_bundles).forEach(function(_3d){
var _3e=_1b.objj_bundles[_3d];
var _3f=_13.relative(_3e.path);
if(_3e._URIMap){
_3c[_3f]={};
Object.keys(_3e._URIMap).forEach(function(_40){
var _41=_3e._URIMap[_40];
var _42;
if(_42=_41.match(/^mhtml:[^!]*!(.*)$/)){
_41="mhtml:"+_2e+"!"+_42[1];
}
_3c[_3f][_40]=_41;
});
}
});
_3b.push("(function() {");
_3b.push("    var didReceiveBundleResponse = "+String(_30));
_3b.push("    var setupURIMaps = "+String(_34));
_3b.push("    var bundleArchiveResponses = "+JSON.stringify(_1c)+";");
_3b.push("    for (var i = 0; i < bundleArchiveResponses.length; i++)");
_3b.push("        didReceiveBundleResponse(bundleArchiveResponses[i]);");
_3b.push("    var URIMaps = "+JSON.stringify(_3c)+";");
_3b.push("    setupURIMaps(URIMaps);");
_3b.push("})();");
_1e.forEach(function(_43){
if(_26[_43.file.path]){
_3b.push("(function(OBJJ_CURRENT_BUNDLE) {");
_3b.push(_43.info);
_3b.push("})(objj_bundles['"+_13.relative(_43.bundle.path)+"']);");
}else{
CPLog.info("Stripping "+_13.relative(_43.file.path));
}
});
_3b.push("if (window.addEventListener)");
_3b.push("    window.addEventListener('load', main, false);");
_3b.push("else if (window.attachEvent)");
_3b.push("    window.attachEvent('onload', main);");
_1d.forEach(function(_44){
var _45=_44.text.lastIndexOf("/*");
var _46=_44.text.lastIndexOf("*/");
if(_45>=0&&_46>_45){
_3b.push(_44.text.slice(_45,_46+2));
}
});
var _47=_2.read(_2.join(_13,"index.html"),{charset:"UTF-8"});
_47=_47.replace(/(\bOBJJ_MAIN_FILE\s*=|\bobjj_import\s*\()/g,"//$&");
_47=_47.replace(/([ \t]*)(<\/head>)/,"$1    <script src = \""+_2e+"\" type = \"text/javascript\"></script>\n$1$2");
_14[_13.join(_2e)]=_3b.join("\n");
_14[_13.join(_2f)]=_47;
}else{
CPLog.error("PHASE 3b: Rebuild .sj");
var _48={};
for(var _2d in _26){
var _49=_1b.objj_files[_2d],_4a=_2.basename(_2d),_4b=_2.dirname(_2d);
if(_49.path!=_2d){
CPLog.warn("Sanity check failed (file path): "+_49.path+" vs. "+_2d);
}
if(_49.bundle){
var _4c=_2.path(_49.bundle.path).dirname();
if(!_48[_49.bundle.path]){
_48[_49.bundle.path]=_49.bundle;
}
if(_4c!=_4b){
CPLog.warn("Sanity check failed (directory path): "+_4b+" vs. "+_4c);
}
var _4d=_49.bundle.info,_4e=objj_msgSend(_4d,"objectForKey:","CPBundlePlatforms"),_4f=objj_msgSend(_4d,"objectForKey:","CPBundleReplacedFiles");
var _50="";
if(_4e){
_50=objj_msgSend(_4e,"firstObjectCommonWithArray:",_1b.OBJJ_PLATFORMS);
}
var _51=objj_msgSend(_4f,"objectForKey:",_50);
if(_51&&objj_msgSend(_51,"containsObject:",_4a)){
var _52=_4c.join(_50+".platform",objj_msgSend(_4d,"objectForKey:","CPBundleExecutable"));
if(!_14[_52]){
_14[_52]=[];
_14[_52].push("@STATIC;1.0;");
}
_14[_52].push("p;");
_14[_52].push(_4a.length+";");
_14[_52].push(_4a);
for(var i=0;i<_49.fragments.length;i++){
if(_49.fragments[i].type&FRAGMENT_CODE){
_14[_52].push("c;");
_14[_52].push(_49.fragments[i].info.length+";");
_14[_52].push(_49.fragments[i].info);
}else{
if(_49.fragments[i].type&FRAGMENT_FILE){
var _53=false;
if(_49.fragments[i].conditionallyIgnore){
var _54=findImportInObjjFiles(_1b,_49.fragments[i]);
if(!_54||!_26[_54]){
_53=true;
}
}
if(!_53){
if(_49.fragments[i].type&FRAGMENT_LOCAL){
var _55=pathRelativeTo(_49.fragments[i].info,_4b);
_14[_52].push("i;");
_14[_52].push(_55.length+";");
_14[_52].push(_55);
}else{
_14[_52].push("I;");
_14[_52].push(_49.fragments[i].info.length+";");
_14[_52].push(_49.fragments[i].info);
}
}else{
CPLog.info("Ignoring import fragment "+_49.fragments[i].info+" in "+_13.relative(_2d));
}
}else{
CPLog.error("Unknown fragment type");
}
}
}
}else{
_14[_2d]=_49.contents;
}
}else{
CPLog.warn("No bundle for "+_13.relative(_2d));
}
}
CPLog.error("PHASE 3.5: fix bundle plists");
for(var _2d in _48){
var _4b=_2.dirname(_2d),_4d=_48[_2d].info,_51=objj_msgSend(_4d,"objectForKey:","CPBundleReplacedFiles");
CPLog.info("Modifying .sj: "+_13.relative(_2d));
if(_51){
var _56=[];
objj_msgSend(_4d,"setObject:forKey:",_56,"CPBundleReplacedFiles");
for(var i=0;i<_51.length;i++){
var _57=_4b+"/"+_51[i];
if(!_26[_57]){
CPLog.info("Removing: "+_51[i]);
}else{
_56.push(_51[i]);
}
}
}
_14[_2d]=CPPropertyListCreateXMLData(_4d).string;
}
}
};
pngcrushDirectory=function(_58){
var _59=_2.path(_58);
var _5a=_59.glob("**/*.png");
system.stderr.print("Running pngcrush on "+_5a.length+" pngs:");
_5a.forEach(function(dst){
var _5b=_59.join(dst);
var _5c=_2.path(_5b+".tmp");
var p=OS.popen(["pngcrush","-rem","alla","-reduce",_5b,_5c]);
if(p.wait()){
CPLog.warn("pngcrush failed. Ensure it's installed and on your PATH.");
}else{
_2.move(_5c,_5b);
system.stderr.write(".").flush();
}
});
system.stderr.print("");
};
functionHookBefore=function(_5d,_5e,_5f){
var _60=_5d[_5e];
_5d[_5e]=function(){
_5f.apply(this,arguments);
var _61=_60.apply(this,arguments);
return _61;
};
};
pathRelativeTo=function(_62,_63){
return _2.relative(_2.join(_63,""),_62);
};
p;21;objj-analysis-tools.jc;6496;
var _1=require("file");
traverseDependencies=function(_2,_3){
if(!_2.processedFiles){
_2.processedFiles={};
}
if(_2.processedFiles[_3.path]){
return;
}
_2.processedFiles[_3.path]=true;
var _4=false;
if(_2.ignoreAllImports){
CPLog.warn("Ignoring all import fragments. ("+_2.rootPath.relative(_3.path)+")");
_4=true;
}else{
if(_2.ignoreFrameworkImports){
var _5=_3.path.match(new RegExp("([^\\/]+)\\/([^\\/]+)\\.j$"));
if(_5&&_5[1]===_5[2]){
CPLog.warn("Framework import file! Ignoring all import fragments. ("+_2.rootPath.relative(_3.path)+")");
_4=true;
}
}
}
if(!_3.fragments){
if(_3.included){
CPLog.warn(_2.rootPath.relative(_3.path)+" is included but missing fragments");
}else{
CPLog.warn("Preprocessing "+_2.rootPath.relative(_3.path));
}
_3.fragments=objj_preprocess(_3.contents,_3.bundle,_3);
}
if(!_2.bundleImages){
_2.bundleImages={};
}
if(!_2.bundleImages[_3.bundle.path]){
var _6=_1.path(_3.bundle.path).dirname().join("/Resources");
if(_6.exists()){
_2.bundleImages[_3.bundle.path]={};
_6.glob("**/*.png").forEach(function(_7){
var _8=_6.join(_7);
var _9=pathRelativeTo(_8.absolute(),_6.absolute());
_2.bundleImages[_3.bundle.path][_9]=1;
});
}
}
var _a=_2.bundleImages[_3.bundle.path];
var _b={},_c={};
CPLog.debug("Processing "+_3.fragments.length+" fragments in "+_2.rootPath.relative(_3.path));
for(var i=0;i<_3.fragments.length;i++){
var _d=_3.fragments[i];
if(_d.type&FRAGMENT_CODE){
var _e=new objj_lexer(_d.info,NULL);
var _f;
while(_f=_e.skip_whitespace()){
if(_2.dependencies.hasOwnProperty(_f)){
var _10=_2.dependencies[_f];
for(var j=0;j<_10.length;j++){
if(_10[j]!=_3.path){
if(!_b[_10[j]]){
_b[_10[j]]={};
}
_b[_10[j]][_f]=true;
}
}
}
var _5=_f.match(new RegExp("^['\"](.*)['\"]$"));
if(_5&&_a&&_a[_5[1]]){
_a[_5[1]]=(_a[_5[1]]|2);
}
}
}else{
if(_d.type&FRAGMENT_FILE){
if(_4){
_d.conditionallyIgnore=true;
}else{
var _11=findImportInObjjFiles(_2.scope,_d);
if(_11){
if(_11!=_3.path){
_c[_11]=true;
}else{
CPLog.error("Ignoring self import (why are you importing yourself?!): "+_2.rootPath.relative(_3.path));
}
}else{
CPLog.error("Couldn't find file for import "+_d.info+" ("+_d.type+")");
}
}
}
}
}
for(var _11 in _c){
if(_11!=_3.path){
if(_2.importCallback){
_2.importCallback(_3.path,_11);
}
if(_2.scope.objj_files[_11]){
traverseDependencies(_2,_2.scope.objj_files[_11]);
}else{
CPLog.error("Missing imported file: "+_11);
}
}
}
if(_2.importedFiles){
_2.importedFiles[_3.path]=_c;
}
for(var _12 in _b){
if(_12!=_3.path){
if(_2.referenceCallback){
_2.referenceCallback(_3.path,_12,_b[_12]);
}
if(_2.scope.objj_files.hasOwnProperty(_12)){
traverseDependencies(_2,_2.scope.objj_files[_12]);
}else{
CPLog.error("Missing referenced file: "+_12);
}
}
}
if(_2.referencedFiles){
_2.referencedFiles[_3.path]=_b;
}
};
findImportInObjjFiles=function(_13,_14){
var _15=null;
if(_14.type&FRAGMENT_LOCAL){
var _16=_14.info;
if(_13.objj_files[_16]){
_15=_16;
}
}else{
var _17=_13.OBJJ_INCLUDE_PATHS.length;
while(_17--){
var _16=_13.OBJJ_INCLUDE_PATHS[_17].replace(new RegExp("\\/$"),"")+"/"+_14.info;
if(_13.objj_files[_16]){
_15=_16;
break;
}
}
}
return _15;
};
var _18=objj_allocateClassPair(CPObject,"PressBundleDelgate"),_19=_18.isa;
class_addIvars(_18,[new objj_ivar("didFinishLoadingCallback")]);
objj_registerClassPair(_18);
objj_addClassForBundle(_18,objj_getBundleWithPath(OBJJ_CURRENT_BUNDLE.path));
class_addMethods(_18,[new objj_method(sel_getUid("initWithCallback:"),function(_1a,_1b,_1c){
with(_1a){
if(_1a=objj_msgSendSuper({receiver:_1a,super_class:objj_getClass("CPObject")},"init")){
didFinishLoadingCallback=_1c;
}
return _1a;
}
}),new objj_method(sel_getUid("bundleDidFinishLoading:"),function(_1d,_1e,_1f){
with(_1d){
print("didFinishLoading: "+_1f);
if(didFinishLoadingCallback){
didFinishLoadingCallback(_1f);
}
}
})]);
findGlobalDefines=function(_20,_21,_22,_23){
var _24=cloneProperties(_20.scope,true);
_24["bundle"]=true;
var _25={};
var _26=_20.scope.fragment_evaluate_file;
_20.scope.fragment_evaluate_file=function(_27){
return _26(_27);
};
var _28=_20.scope.fragment_evaluate_code;
_20.scope.fragment_evaluate_code=function(_29){
CPLog.debug("Evaluating "+_20.rootPath.relative(_29.file.path)+" ("+_20.rootPath.relative(_29.bundle.path)+")");
var _2a=cloneProperties(_20.scope);
if(_22){
_22.push(_29);
}
var _2b=_28(_29);
var _2c={};
diff(_2a,_20.scope,_24,_2c,_2c,null);
_25[_29.file.path]=_2c;
return _2b;
};
var _2d=objj_msgSend(objj_msgSend(PressBundleDelgate,"alloc"),"initWithCallback:",_23);
var _2e=[];
(_20.eval("("+(function(_2f,_30,_31){
with(require("objective-j").window){
objj_import(_2f,true,function(){
_31=_31||[];
var _32=objj_msgSend(objj_msgSend(CPBundle,"bundleForClass:",objj_msgSend(CPApplication,"class")),"pathForResource:",objj_msgSend(CPApplication,"defaultThemeName"));
var _33=objj_msgSend(objj_msgSend(CPBundle,"alloc"),"initWithPath:",_32+"/Info.plist");
objj_msgSend(_33,"loadWithDelegate:",_30);
_31.forEach(function(_34){
var _35=objj_msgSend(objj_msgSend(CPBundle,"alloc"),"initWithPath:",_34);
objj_msgSend(_35,"loadWithDelegate:",_30);
});
});
}
})+")"))(_21,_2d,_2e);
_20.scope.require("browser/timeout").serviceTimeouts();
return _25;
};
coalesceGlobalDefines=function(_36){
var _37={};
for(var _38 in _36){
var _39=_36[_38];
for(var _3a in _39){
if(!_37[_3a]){
_37[_3a]=[];
}
_37[_3a].push(_38);
}
}
return _37;
};
setupObjectiveJ=function(_3b,_3c){
_3b.global.NARWHAL_HOME=system.prefix;
_3b.global.NARWHAL_ENGINE_HOME=_1.join(system.prefix,"engines","rhino");
var _3d=_1.join(_3b.global.NARWHAL_ENGINE_HOME,"bootstrap.js");
_3b.evalFile(_3d);
var _3e=_3b.global.require("objective-j");
addMockBrowserEnvironment(_3e.window);
return _3e.window;
};
addMockBrowserEnvironment=function(_3f){
if(!_3f.window){
_3f.window=_3f;
}
if(!_3f.location){
_3f.location={};
}
if(!_3f.location.href){
_3f.location.href="";
}
if(!_3f.Element){
_3f.Element=function(){
this.style={};
};
}
if(!_3f.document){
_3f.document={createElement:function(){
return new _3f.Element();
}};
}
};
cloneProperties=function(_40,_41){
var _42={};
for(var _43 in _40){
_42[_43]=_41?true:_40[_43];
}
return _42;
};
diff=function(_44,_45,_46,_47,_48,_49){
for(var i in _45){
if(_47&&!_46[i]&&typeof _44[i]=="undefined"){
_47[i]=true;
}
}
for(var i in _45){
if(_48&&!_46[i]&&typeof _44[i]!="undefined"&&typeof _45[i]!="undefined"&&_44[i]!==_45[i]){
_48[i]=true;
}
}
for(var i in _44){
if(_49&&!_46[i]&&typeof _45[i]=="undefined"){
_49[i]=true;
}
}
};
allKeys=function(_4a){
var _4b=[];
for(var i in _4a){
_4b.push(i);
}
return _4b.sort();
};
e;