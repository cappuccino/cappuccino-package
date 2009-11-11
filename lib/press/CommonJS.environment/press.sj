@STATIC;1.0;p;6;main.jI;23;Foundation/Foundation.ji;21;objj-analysis-tools.jc;10290;
var _1="main.j",_2="Frameworks";
var _3="Usage: press root_directory output_directory [options]\n        --main path         The relative path (from root_directory) to the main file (default: 'main.j')\n        --frameworks path   The relative path (from root_directory) to the frameworks directory (default: 'Frameworks')\n        --platforms         Platform names, colon separated (default: 'browser:objj')\n        --png               Run pngcrush on all PNGs (pngcrush must be installed!)\n        --flatten           Flatten all code into a single Application.js file and attempt add script tag to index.html (useful for Adobe AIR and CDN deployment)\n        --nostrip           Don't strip any files\n        --v                 Verbose";
main=function(){
var _4=null,_5=null,_6=null,_7=null,_8=["browser","objj"],_9=false,_a=false,_b=false,_c=false;
var _d=false;
while(system.args.length&&!_d){
var _e=system.args.shift();
switch(_e){
case "--main":
if(system.args.length){
_6=system.args.shift();
}else{
_d=true;
}
break;
case "--frameworks":
if(system.args.length){
_7=system.args.shift().replace(/\/$/,"");
}else{
_d=true;
}
break;
case "--platforms":
if(system.args.length){
_8=system.args.shift().split(":");
}else{
_d=true;
}
break;
case "--png":
_9=true;
break;
case "--flatten":
_a=true;
break;
case "--nostrip":
_b=true;
break;
case "--v":
_c=true;
break;
default:
if(_4==null){
_4=_e.replace(/\/$/,"");
}else{
if(_5==null){
_5=_e.replace(/\/$/,"");
}else{
_d=true;
}
}
}
}
if(_c){
CPLogRegister(CPLogPrint);
}else{
CPLogRegisterRange(CPLogPrint,"fatal","info");
}
if(_d||_4==null||_5==null||!_8.length){
print(_3);
return;
}
_4=absolutePath(_4);
var _f=_4+"/"+(_6||_1),_10=_4+"/"+(_7||_2);
CPLog.info("Application root:    "+_4);
CPLog.info("Output directory:    "+_5);
CPLog.info("Main file:           "+_f);
CPLog.info("Frameworks:          "+_10);
var cx=Packages.org.mozilla.javascript.Context.getCurrentContext(),_11=makeObjjScope(cx);
_11.OBJJ_INCLUDE_PATHS=[_10];
_11.OBJJ_PLATFORMS=_8;
var _12=[],_13=[];
_11.objj_search.prototype.didReceiveBundleResponseOriginal=_11.objj_search.prototype.didReceiveBundleResponse;
_11.objj_search.prototype.didReceiveBundleResponse=function(_14){
var _15={success:_14.success,filePath:pathRelativeTo(_14.filePath,_4)};
if(_14.success){
var _16=new Packages.java.io.ByteArrayOutputStream();
outputTransformer(_16,_14.xml,"UTF-8");
_15.text=CPPropertyListCreate280NorthData(CPPropertyListCreateFromXMLData({string:String(_16.toString())})).string;
}
_12.push(_15);
this.didReceiveBundleResponseOriginal.apply(this,arguments);
};
CPLog.error("PHASE 1: Loading application...");
var _17=findGlobalDefines(cx,_11,_f,_13);
var _18=coalesceGlobalDefines(_17);
CPLog.trace("Global defines:");
for(var i in _18){
CPLog.trace("    "+i+" => "+_18[i]);
}
CPLog.error("PHASE 2: Walk dependency tree...");
var _19={};
if(_b){
_19=_11.objj_files;
}else{
if(!_11.objj_files[_f]){
CPLog.error("Root file not loaded!");
return;
}
CPLog.warn("Analyzing dependencies...");
var _1a={scope:_11,dependencies:_18,processedFiles:{},ignoreFrameworkImports:true,importCallback:function(_1b,_1c){
_19[_1c]=true;
},referenceCallback:function(_1d,_1e){
_19[_1e]=true;
}};
_19[_f]=true;
traverseDependencies(_1a,_11.objj_files[_f]);
var _1f=0,_20=0;
for(var _21 in _11.objj_files){
if(_19[_21]){
CPLog.debug("Included: "+_21);
_1f++;
}else{
CPLog.info("Excluded: "+_21);
}
_20++;
}
CPLog.warn("Total required files: "+_1f+" out of "+_20);
}
var _22={};
if(_a){
CPLog.error("PHASE 3a: Flattening...");
var _23=[],_24=readFile(_4+"/index.html");
var _25=function(_26){
var _27=new objj_bundle();
_27.path=_26.filePath;
if(_26.success){
var _28=new objj_data();
_28.string=_26.text;
_27.info=CPPropertyListCreateFrom280NorthData(_28);
}else{
_27.info=new objj_dictionary();
}
objj_bundles[_26.filePath]=_27;
};
_23.push("var __fakeDidReceiveBundleResponse = "+String(_25));
_23.push("var __fakeBundleArchives = "+JSON.stringify(_12)+";");
_23.push("for (var i = 0; i < __fakeBundleArchives.length; i++) __fakeDidReceiveBundleResponse(__fakeBundleArchives[i]);");
for(var i=0;i<_13.length;i++){
if(_19[_13[i].file.path]){
_23.push("(function() {");
_23.push("var OBJJ_CURRENT_BUNDLE = objj_bundles['"+pathRelativeTo(_13[i].bundle.path,_4)+"'];");
_23.push(_13[i].info);
_23.push("})();");
}else{
CPLog.info("Stripping "+_13[i].file.path);
}
}
_23.push("if (window.addEventListener)                 window.addEventListener('load', function(){main()}, false);             else if (window.attachEvent)                 window.attachEvent('onload', function(){main()});");
_24=_24.replace(/(\bOBJJ_MAIN_FILE\s*=|\bobjj_import\s*\()/g,"//$&");
_24=_24.replace(/([ \t]*)(<\/head>)/,"$1    <script src = \"Application.js\" type = \"text/javascript\"></script>\n$1$2");
_22[_4+"/Application.js"]=_23.join("\n");
_22[_4+"/index.html"]=_24;
}else{
CPLog.error("PHASE 3b: Rebuild .sj");
var _29={};
for(var _21 in _19){
var _2a=_11.objj_files[_21],_2b=basename(_21),_2c=dirname(_21);
if(_2a.path!=_21){
CPLog.warn("Sanity check failed (file path): "+_2a.path+" vs. "+_21);
}
if(_2a.bundle){
var _2d=dirname(_2a.bundle.path);
if(!_29[_2a.bundle.path]){
_29[_2a.bundle.path]=_2a.bundle;
}
if(_2d!=_2c){
CPLog.warn("Sanity check failed (directory path): "+_2c+" vs. "+_2d);
}
var _2e=_2a.bundle.info,_2f=objj_msgSend(_2e,"objectForKey:","CPBundleReplacedFiles");
if(_2f&&objj_msgSend(_2f,"containsObject:",_2b)){
var _30="",_31=objj_msgSend(_2e,"objectForKey:","CPBundlePlatforms");
if(_31){
_30=objj_msgSend(_31,"firstObjectCommonWithArray:",_11.OBJJ_PLATFORMS);
if(_30){
_30=_30+".platform/";
}
}
var _32=_2d+"/"+_30+objj_msgSend(_2e,"objectForKey:","CPBundleExecutable");
if(!_22[_32]){
_22[_32]=[];
_22[_32].push("@STATIC;1.0;");
}
_22[_32].push("p;");
_22[_32].push(_2b.length+";");
_22[_32].push(_2b);
for(var i=0;i<_2a.fragments.length;i++){
if(_2a.fragments[i].type&FRAGMENT_CODE){
_22[_32].push("c;");
_22[_32].push(_2a.fragments[i].info.length+";");
_22[_32].push(_2a.fragments[i].info);
}else{
if(_2a.fragments[i].type&FRAGMENT_FILE){
var _33=false;
if(_2a.fragments[i].conditionallyIgnore){
var _34=findImportInObjjFiles(_11,_2a.fragments[i]);
if(!_34||!_19[_34]){
_33=true;
}
}
if(!_33){
if(_2a.fragments[i].type&FRAGMENT_LOCAL){
var _35=pathRelativeTo(_2a.fragments[i].info,_2c);
_22[_32].push("i;");
_22[_32].push(_35.length+";");
_22[_32].push(_35);
}else{
_22[_32].push("I;");
_22[_32].push(_2a.fragments[i].info.length+";");
_22[_32].push(_2a.fragments[i].info);
}
}else{
CPLog.info("Ignoring import fragment "+_2a.fragments[i].info+" in "+_21);
}
}else{
CPLog.error("Unknown fragment type");
}
}
}
}else{
_22[_21]=_2a.contents;
}
}else{
CPLog.warn("No bundle for "+_21);
}
}
CPLog.error("PHASE 3.5: fix bundle plists");
for(var _21 in _29){
var _2c=dirname(_21),_2e=_29[_21].info,_2f=objj_msgSend(_2e,"objectForKey:","CPBundleReplacedFiles");
CPLog.info("Modifying .sj: "+_21);
if(_2f){
var _36=[];
objj_msgSend(_2e,"setObject:forKey:",_36,"CPBundleReplacedFiles");
for(var i=0;i<_2f.length;i++){
var _37=_2c+"/"+_2f[i];
if(!_19[_37]){
CPLog.info("Removing: "+_2f[i]);
}else{
_36.push(_2f[i]);
}
}
}
_22[_21]=CPPropertyListCreateXMLData(_2e).string;
}
}
CPLog.error("PHASE 4: copy to output");
var _38=new Packages.java.io.File(_4),_39=new Packages.java.io.File(_5);
copyDirectory(_38,_39,_9);
for(var _21 in _22){
var _2a=new java.io.File(_39,pathRelativeTo(_21,_4));
var _3a=_2a.getParentFile();
if(!_3a.exists()){
CPLog.warn(_3a+" doesn't exist, creating directories.");
_3a.mkdirs();
}
CPLog.info("Writing out "+_2a);
var _3b=new java.io.BufferedWriter(new java.io.FileWriter(_2a));
if(typeof _22[_21]=="string"){
_3b.write(_22[_21]);
}else{
_3b.write(_22[_21].join(""));
}
_3b.close();
}
};
copyDirectory=function(src,dst,_3c){
CPLog.trace("Copying directory "+src);
dst.mkdirs();
var _3d=src.listFiles();
for(var i=0;i<_3d.length;i++){
if(_3d[i].isFile()){
copyFile(_3d[i],new Packages.java.io.File(dst,_3d[i].getName()),_3c);
}else{
if(_3d[i].isDirectory()){
copyDirectory(_3d[i],new Packages.java.io.File(dst,_3d[i].getName()),_3c);
}
}
}
};
copyFile=function(src,dst,_3e){
if(_3e&&(/.png$/).test(src.getName())){
CPLog.warn("Optimizing .png "+src);
exec(["pngcrush","-rem","alla","-reduce",src.getAbsolutePath(),dst.getAbsolutePath()]);
}else{
CPLog.trace("Copying file "+src);
var _3f=(new Packages.java.io.FileInputStream(src)).getChannel(),_40=(new Packages.java.io.FileOutputStream(dst)).getChannel();
_3f.transferTo(0,_3f.size(),_40);
_3f.close();
_40.close();
}
};
dirname=function(_41){
return _41.substring(0,_41.lastIndexOf("/"));
};
basename=function(_42){
return _42.substring(_42.lastIndexOf("/")+1);
};
absolutePath=function(_43){
return String((new Packages.java.io.File(_43)).getCanonicalPath());
};
pathRelativeTo=function(_44,_45){
var _46=[],_47=_44.split("/"),_48=_45?_45.split("/"):[];
var i=0;
while(i<_47.length){
if(_47[i]!=_48[i]){
break;
}
i++;
}
for(var j=i;j<_48.length;j++){
_46.push("..");
}
for(var j=i;j<_47.length;j++){
_46.push(_47[j]);
}
var _49=_46.join("/");
return _49;
};
exec=function(){
var _4a=false;
var _4b=Packages.java.lang.Runtime.getRuntime();
var p=_4b.exec.apply(_4b,arguments);
var _4c=new Packages.java.io.BufferedReader(new Packages.java.io.InputStreamReader(p.getInputStream())),_4d="",_4e=new Packages.java.io.BufferedReader(new Packages.java.io.InputStreamReader(p.getErrorStream())),_4f="";
var _50=false;
while(!_50){
_50=true;
if(s=_4c.readLine()){
_4d+=s;
if(_4a){
CPLog.info("exec: "+s);
}
_50=false;
}
if(s=_4e.readLine()){
_4f+=s;
CPLog.warn("exec: "+s);
_50=false;
}
}
var _51=p.waitFor();
return {code:_51,stdout:_4d,stderr:_4f};
};
outputTransformer=function(os,_52,_53,_54){
var _55=new Packages.javax.xml.transform.dom.DOMSource(_52);
var _56=new Packages.javax.xml.transform.stream.StreamResult(os);
var tf=Packages.javax.xml.transform.TransformerFactory.newInstance();
var _57=tf.newTransformer();
_57.setOutputProperty(Packages.javax.xml.transform.OutputKeys.VERSION,"1.0");
_57.setOutputProperty(Packages.javax.xml.transform.OutputKeys.INDENT,"yes");
if(_53){
_57.setOutputProperty(Packages.javax.xml.transform.OutputKeys.ENCODING,_53);
}
if(_54){
_57.setOutputProperty(Packages.javax.xml.transform.OutputKeys.STANDALONE,(_54?"yes":"no"));
}
String(_57.transform(_55,_56));
};
p;21;objj-analysis-tools.jc;5537;
var _1=OBJJ_HOME+"/lib/Frameworks/Objective-J/rhino.platform/Objective-J.js",_2=OBJJ_HOME+"/lib/press/bridge.js",_3="/Users/tlrobinson/280North/git/cappuccino/Tools/press/env.js";
traverseDependencies=function(_4,_5){
if(_4.processedFiles[_5.path]){
return;
}
_4.processedFiles[_5.path]=true;
var _6=false;
if(_4.ignoreAllImports){
CPLog.warn("Ignoring all import fragments. ("+_5.path+")");
_6=true;
}else{
if(_4.ignoreFrameworkImports){
var _7=_5.path.match(new RegExp("([^\\/]+)\\/([^\\/]+)\\.j$"));
if(_7&&_7[1]===_7[2]){
CPLog.warn("Framework import file! Ignoring all import fragments. ("+_5.path+")");
_6=true;
}
}
}
if(!_5.fragments){
if(_5.included){
CPLog.warn(_5.path+" is included but missing fragments");
}else{
CPLog.warn("Preprocessing "+_5.path);
}
_5.fragments=objj_preprocess(_5.contents,_5.bundle,_5);
}
if(!_4.bundleImages){
_4.bundleImages={};
}
if(!_4.bundleImages[_5.bundle.path]){
var _8=new java.io.File(dirname(_5.bundle.path)+"/Resources");
if(_8.exists()){
_4.bundleImages[_5.bundle.path]={};
var _9=find(_8,(new RegExp("\\.png$")));
for(var i=0;i<_9.length;i++){
var _a=pathRelativeTo(_9[i].getCanonicalPath(),_8.getCanonicalPath());
_4.bundleImages[_5.bundle.path][_a]=1;
}
}
}
var _b=_4.bundleImages[_5.bundle.path];
var _c={},_d={};
CPLog.debug("Processing "+_5.path+" fragments ("+_5.fragments.length+")");
for(var i=0;i<_5.fragments.length;i++){
var _e=_5.fragments[i];
if(_e.type&FRAGMENT_CODE){
var _f=new objj_lexer(_e.info,NULL);
var _10;
while(_10=_f.skip_whitespace()){
if(_4.dependencies.hasOwnProperty(_10)){
var _11=_4.dependencies[_10];
for(var j=0;j<_11.length;j++){
if(_11[j]!=_5.path){
if(!_c[_11[j]]){
_c[_11[j]]={};
}
_c[_11[j]][_10]=true;
}
}
}
var _7=_10.match(new RegExp("^['\"](.*)['\"]$"));
if(_7&&_b&&_b[_7[1]]){
_b[_7[1]]=(_b[_7[1]]|2);
}
}
}else{
if(_e.type&FRAGMENT_FILE){
if(_6){
_e.conditionallyIgnore=true;
}else{
var _12=findImportInObjjFiles(_4.scope,_e);
if(_12){
if(_12!=_5.path){
_d[_12]=true;
}else{
CPLog.error("Ignoring self import (why are you importing yourself!?): "+_5.path);
}
}else{
CPLog.error("Couldn't find file for import "+_e.info+"("+_e.type+")");
}
}
}
}
}
for(var _12 in _d){
if(_12!=_5.path){
if(_4.importCallback){
_4.importCallback(_5.path,_12);
}
if(_4.scope.objj_files[_12]){
traverseDependencies(_4,_4.scope.objj_files[_12]);
}else{
CPLog.error("Missing imported file: "+_12);
}
}
}
if(_4.importedFiles){
_4.importedFiles[_5.path]=_d;
}
for(var _13 in _c){
if(_13!=_5.path){
if(_4.referenceCallback){
_4.referenceCallback(_5.path,_13,_c[_13]);
}
if(_4.scope.objj_files.hasOwnProperty(_13)){
traverseDependencies(_4,_4.scope.objj_files[_13]);
}else{
CPLog.error("Missing referenced file: "+_13);
}
}
}
if(_4.referencedFiles){
_4.referencedFiles[_5.path]=_c;
}
};
findImportInObjjFiles=function(_14,_15){
var _16=null;
if(_15.type&FRAGMENT_LOCAL){
var _17=_15.info;
if(_14.objj_files[_17]){
_16=_17;
}
}else{
var _18=_14.OBJJ_INCLUDE_PATHS.length;
while(_18--){
var _17=_14.OBJJ_INCLUDE_PATHS[_18].replace(new RegExp("\\/$"),"")+"/"+_15.info;
if(_14.objj_files[_17]){
_16=_17;
break;
}
}
}
return _16;
};
findGlobalDefines=function(_19,_1a,_1b,_1c){
addMockBrowserEnvironment(_1a);
var _1d=cloneProperties(_1a,true);
_1d["bundle"]=true;
var _1e={};
var _1f=_1a.fragment_evaluate_file;
_1a.fragment_evaluate_file=function(_20){
return _1f(_20);
};
var _21=_1a.fragment_evaluate_code;
_1a.fragment_evaluate_code=function(_22){
CPLog.debug("Evaling "+_22.file.path+" / "+_22.bundle.path);
var _23=cloneProperties(_1a);
if(_1c){
_1c.push(_22);
}
var _24=_21(_22);
var _25={};
diff(_23,_1a,_1d,_25,_25,null);
_1e[_22.file.path]=_25;
return _24;
};
runWithScope(_19,_1a,function(_26){
objj_import(_26,true,NULL);
},[_1b]);
return _1e;
};
coalesceGlobalDefines=function(_27){
var _28={};
for(var _29 in _27){
var _2a=_27[_29];
for(var _2b in _2a){
if(!_28[_2b]){
_28[_2b]=[];
}
_28[_2b].push(_29);
}
}
return _28;
};
makeObjjScope=function(_2c,_2d){
var _2e=_2c.initStandardObjects();
if(_2d){
_2e.objj_alert=print;
_2e.debug=true;
}
_2e.print=function(_2f){
Packages.java.lang.System.out.println(String(_2f));
};
var _30=readFile(_2);
if(_30){
_2c.evaluateString(_2e,_30,"bridge.js",1,null);
}else{
CPLog.warn("Missing bridge.js");
}
var _31=readFile(_1);
if(_31){
_2c.evaluateString(_2e,_31,"Objective-J.js",1,null);
}else{
CPLog.warn("Missing Objective-J.js");
}
return _2e;
};
runWithScope=function(_32,_33,_34,_35){
_33.__runWithScopeArgs=_35||[];
var _36="("+_34+").apply(this, this.__runWithScopeArgs); serviceTimeouts();";
return _32.evaluateString(_33,_36,"<cmd>",1,null);
};
addMockBrowserEnvironment=function(_37){
_37.Element=function(){
this.style={};
};
_37.document={createElement:function(){
return new _37.Element();
}};
};
cloneProperties=function(_38,_39){
var _3a={};
for(var _3b in _38){
_3a[_3b]=_39?true:_38[_3b];
}
return _3a;
};
diff=function(_3c,_3d,_3e,_3f,_40,_41){
for(var i in _3d){
if(_3f&&!_3e[i]&&typeof _3c[i]=="undefined"){
_3f[i]=true;
}
}
for(var i in _3d){
if(_40&&!_3e[i]&&typeof _3c[i]!="undefined"&&typeof _3d[i]!="undefined"&&_3c[i]!==_3d[i]){
_40[i]=true;
}
}
for(var i in _3c){
if(_41&&!_3e[i]&&typeof _3d[i]=="undefined"){
_41[i]=true;
}
}
};
allKeys=function(_42){
var _43=[];
for(var i in _42){
_43.push(i);
}
return _43.sort();
};
find=function(src,_44){
var _45=[];
var _46=src.listFiles();
for(var i=0;i<_46.length;i++){
if(_46[i].isFile()&&_44.test(_46[i].getAbsolutePath())){
_45.push(_46[i]);
}else{
if(_46[i].isDirectory()){
_45=Array.prototype.concat.apply(_45,find(_46[i],_44));
}
}
}
return _45;
};
e;