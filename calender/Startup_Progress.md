<div id="table-of-contents">
<h2>Table of Contents</h2>
<div id="text-table-of-contents">
<ul>
<li><a href="#sec-1">1. Purpose</a></li>
<li><a href="#sec-2">2. Read</a>
<ul>
<li><a href="#sec-2-1">2.1. JRuby Hacking Guide by nahi</a></li>
<li><a href="#sec-2-2">2.2. Copy of JRuby Source Code Reading Guide by nahi</a></li>
<li><a href="#sec-2-3">2.3. Ruboto Startup by donV</a></li>
</ul>
</li>
<li><a href="#sec-3">3. Conclusion</a>
<ul>
<li><a href="#sec-3-1">3.1. Ruboto</a></li>
<li><a href="#sec-3-2">3.2. JRuby</a>
<ul>
<li><a href="#sec-3-2-1">3.2.1. org.jruby.*</a></li>
</ul>
</li>
</ul>
</li>
</ul>
</div>
</div>
# Purpose

Figure out Ruboto startup & JRuby initialization on Dalvik

# Read

## [JRuby Hacking Guide by nahi](http://prezi.com/tsuouxb3z4ln/jruby-hacking-guide/)

## [Copy of JRuby Source Code Reading Guide by nahi](http://prezi.com/n7jlwvldnfyu/copy-of-jruby-source-code-reading-guide/)

## [Ruboto Startup by donV](https://github.com/ruboto/ruboto/wiki/Ruboto-startup)

# Conclusion

## Ruboto

LauncherActivity -> EntryPointActivity -> RubotoActivity -> android.app.Activity   

JRuby is initialized in the EntryPointActivity class.   

## JRuby

### org.jruby.\*

1.  Main

    Create JRuby instance, Entry
    
            public static void main(String[] args) {
                doGCJCheck();
        
                Main main;
        
                if (DripMain.DRIP_RUNTIME != null) {
                    main = new Main(DripMain.DRIP_CONFIG, true);
                } else {
                    main = new Main(true);
                }
        
                try {
                    Status status = main.run(args);
                    if (status.isExit()) {
                        System.exit(status.getStatus());
                    }
                } catch (RaiseException rj) {
                    System.exit(handleRaiseException(rj));
                } catch (Throwable t) {
                    // print out as a nice Ruby backtrace
        //...
                }
            }
        
            public Status run(String[] args) {
                try {
                    config.processArguments(args);
                    return internalRun(); \\Here a JRuby VM is started
                } catch (MainExitException mee) {
                    return handleMainExit(mee);
                } catch (OutOfMemoryError oome) {
                    return handleOutOfMemory(oome);
                }
        //...
        }
        
            private Status internalRun() {
        //...        
                doProcessArguments(in);
        //...        
                Ruby runtime;
        //...
            }

2.  Ruby

    Run JRuby VM and evaluate scripts
    
    -   evaluateScript
    
            public IRubyObject evalScriptlet(String script, DynamicScope scope) {
                ThreadContext context = getCurrentContext();
                Node node = parseEval(script, "<script>", scope, 0);
        
                try {
                    context.preEvalScriptlet(scope);
                    return ASTInterpreter.INTERPRET_ROOT(this, context, node, context.getFrameSelf(), Block.NULL_BLOCK);
                } catch (JumpException.ReturnJump rj) {
                    throw newLocalJumpError(RubyLocalJumpError.Reason.RETURN, (IRubyObject)rj.getValue(), "unexpected return");
                } catch (JumpException.BreakJump bj) {
        //...
                }
            }
    
    
    -   executeScript
    
        public IRubyObject executeScript(String script, String filename) {
            byte[] bytes = script.getBytes();
        
            Node node = parseInline(new ByteArrayInputStream(bytes), filename, null);
            ThreadContext context = getCurrentContext();
        
            String oldFile = context.getFile();
            int oldLine = context.getLine();
            try {
                context.setFileAndLine(node.getPosition());
                return runInterpreter(node);
            } finally {
                context.setFileAndLine(oldFile, oldLine);
            }
        }

3.  How a JRuby VM started

    1.  The object constructor
    
        Set up a new JRuby runtime according to the properties of a specific RubyInstanceConfig object. I only leave lines with object initializing below.
        
                private Ruby(RubyInstanceConfig config) {
            //...
                    this.threadService      = new ThreadService(this);
                    if(config.isSamplingEnabled()) {
                        org.jruby.util.SimpleSampler.registerThreadContext(threadService.getCurrentContext());
                    }
            
                    getJRubyClassLoader(); // force JRubyClassLoader to init if possible
            
                    if (config.getCompileMode() == CompileMode.OFFIR ||
                            config.getCompileMode() == CompileMode.FORCEIR) {
                        this.staticScopeFactory = new IRStaticScopeFactory(this);
                    } else {
                        this.staticScopeFactory = new StaticScopeFactory(this);
                    }
            
                    this.beanManager        = BeanManagerFactory.create(this, config.isManagementEnabled());
                    this.jitCompiler        = new JITCompiler(this);
                    this.parserStats        = new ParserStats(this);
            
            //...Random 
            
                    this.beanManager.register(new Config(this));
                    this.beanManager.register(parserStats);
                    this.beanManager.register(new ClassCache(this));
                    this.beanManager.register(new org.jruby.management.Runtime(this));
            
                    this.runtimeCache = new RuntimeCache();
                    runtimeCache.initMethodCache(ClassIndex.MAX_CLASSES * MethodNames.values().length - 1);
            
                    constantInvalidator = OptoFactory.newConstantInvalidator();
                    checkpointInvalidator = OptoFactory.newConstantInvalidator();
            //...
                    reinitialize(false);
                }
    
    2.  init()
    
        It seems that core classes and libraries are loaded from here. Maybe this could be a key entry for speeding up JRuby on Dalvik.
        
                private void init() {
                    // Construct key services
            //...
                    // initialize the root of the class hierarchy completely
                    initRoot();
                    // Set up the main thread in thread service
                    threadService.initMainThread();
                    // Get the main threadcontext (gets constructed for us)
                    ThreadContext tc = getCurrentContext();
                    // Construct the top-level execution frame and scope for the main thread
                    tc.prepareTopLevel(objectClass, topSelf);
                    // Initialize all the core classes
                    bootstrap();
                    // set up defined messages
                    initDefinedMessages();
                    irManager = new IRManager();
                    // Initialize the "dummy" class used as a marker
                    dummyClass = new RubyClass(this, classClass);
                    dummyClass.freeze(tc);
            
                    // Create global constants and variables
                    RubyGlobal.createGlobals(tc, this);
            
                    // Prepare LoadService and load path
                    getLoadService().init(config.getLoadPaths());
            
                    // initialize builtin libraries
                    initBuiltins();
            
                    // load JRuby internals, which loads Java support
                    // if we can't use reflection, 'jruby' and 'java' won't work; no load.
                    boolean reflectionWorks;
                    try {
                        ClassLoader.class.getDeclaredMethod("getResourceAsStream", String.class);
                        reflectionWorks = true;
                    } catch (Exception e) {
                        reflectionWorks = false;
                    }
            
                    if (!RubyInstanceConfig.DEBUG_PARSER && reflectionWorks) {
                        loadService.require("jruby");
                    }
            
                    // out of base boot mode
                    booting = false;
            
                    // init Ruby-based kernel
                    initRubyKernel();
            //..        
                }
        
        We can see that JRuby loads all core classes and builtin libs by invoking `bootstrap()` `initBuiltins()`
        
        1.  bootstrap()
        
            It loads all ruby core classes, so we can't try to reduce its size.
        
        2.  initBuiltins()
        
            When we go into the codes of `initBuiltins()`, we can find that JRuby loads quite a lot of ext libraries. Maybe there's something we can do with it.
            
                addLazyBuiltin("java.rb", "java", "org.jruby.javasupport.Java");
                addLazyBuiltin("jruby.rb", "jruby", "org.jruby.ext.jruby.JRubyLibrary");
                addLazyBuiltin("jruby/util.rb", "jruby/util", "org.jruby.ext.jruby.JRubyUtilLibrary");
                addLazyBuiltin("jruby/type.rb", "jruby/type", "org.jruby.ext.jruby.JRubyTypeLibrary");
                addLazyBuiltin("iconv.jar", "iconv", "org.jruby.ext.iconv.IConvLibrary");
                addLazyBuiltin("nkf.jar", "nkf", "org.jruby.ext.nkf.NKFLibrary");
                addLazyBuiltin("stringio.jar", "stringio", "org.jruby.ext.stringio.StringIOLibrary");
                addLazyBuiltin("strscan.jar", "strscan", "org.jruby.ext.strscan.StringScannerLibrary");
                addLazyBuiltin("zlib.jar", "zlib", "org.jruby.ext.zlib.ZlibLibrary");
                addLazyBuiltin("enumerator.jar", "enumerator", "org.jruby.ext.enumerator.EnumeratorLibrary");
                addLazyBuiltin("readline.jar", "readline", "org.jruby.ext.readline.ReadlineService");
                addLazyBuiltin("thread.jar", "thread", "org.jruby.ext.thread.ThreadLibrary");
                addLazyBuiltin("thread.rb", "thread", "org.jruby.ext.thread.ThreadLibrary");
                addLazyBuiltin("digest.jar", "digest.so", "org.jruby.ext.digest.DigestLibrary");
                addLazyBuiltin("digest/md5.jar", "digest/md5", "org.jruby.ext.digest.MD5");
                addLazyBuiltin("digest/rmd160.jar", "digest/rmd160", "org.jruby.ext.digest.RMD160");
                addLazyBuiltin("digest/sha1.jar", "digest/sha1", "org.jruby.ext.digest.SHA1");
                addLazyBuiltin("digest/sha2.jar", "digest/sha2", "org.jruby.ext.digest.SHA2");
                addLazyBuiltin("bigdecimal.jar", "bigdecimal", "org.jruby.ext.bigdecimal.BigDecimalLibrary");
                addLazyBuiltin("io/wait.jar", "io/wait", "org.jruby.ext.io.wait.IOWaitLibrary");
                addLazyBuiltin("etc.jar", "etc", "org.jruby.ext.etc.EtcLibrary");
                addLazyBuiltin("weakref.rb", "weakref", "org.jruby.ext.weakref.WeakRefLibrary");
                addLazyBuiltin("delegate_internal.jar", "delegate_internal", "org.jruby.ext.delegate.DelegateLibrary");
                addLazyBuiltin("timeout.rb", "timeout", "org.jruby.ext.timeout.Timeout");
                addLazyBuiltin("ripper.jar", "ripper", "org.jruby.ext.ripper.RipperLibrary");
                addLazyBuiltin("socket.jar", "socket", "org.jruby.ext.socket.SocketLibrary");
                addLazyBuiltin("rbconfig.rb", "rbconfig", "org.jruby.ext.rbconfig.RbConfigLibrary");
                addLazyBuiltin("jruby/serialization.rb", "serialization", "org.jruby.ext.jruby.JRubySerializationLibrary");
                addLazyBuiltin("ffi-internal.jar", "ffi-internal", "org.jruby.ext.ffi.FFIService");
                addLazyBuiltin("tempfile.jar", "tempfile", "org.jruby.ext.tempfile.TempfileLibrary");
                addLazyBuiltin("fcntl.rb", "fcntl", "org.jruby.ext.fcntl.FcntlLibrary");
                addLazyBuiltin("rubinius.jar", "rubinius", "org.jruby.ext.rubinius.RubiniusLibrary");
                addLazyBuiltin("yecht.jar", "yecht", "YechtService");
                addLazyBuiltin("io/try_nonblock.jar", "io/try_nonblock", "org.jruby.ext.io.try_nonblock.IOTryNonblockLibrary");
                if (is1_9()) {
                    addLazyBuiltin("mathn/complex.jar", "mathn/complex", "org.jruby.ext.mathn.Complex");
                    addLazyBuiltin("mathn/rational.jar", "mathn/rational", "org.jruby.ext.mathn.Rational");
                    addLazyBuiltin("fiber.rb", "fiber", "org.jruby.ext.fiber.FiberExtLibrary");
                    addLazyBuiltin("psych.jar", "psych", "org.jruby.ext.psych.PsychLibrary");
                    addLazyBuiltin("coverage.jar", "coverage", "org.jruby.ext.coverage.CoverageLibrary");
            
            Tracing back along the load chain, `org.jruby.runtime.load.LoadService#addBuiltinLibrary` -> `org.jruby.runtime.load.Library#load`   
            `Library#load` is an interface and `LoadService` implemented it:
            
                public void load(String file, boolean wrap) {
                    long startTime = loadTimer.startLoad(file);
                    try {
                        if(!runtime.getProfile().allowLoad(file)) {
                            throw runtime.newLoadError("no such file to load -- " + file, file);
                        }
                
                        SearchState state = new SearchState(file);
                        state.prepareLoadSearch(file);
                
                        Library library = findBuiltinLibrary(state, state.searchFile, state.suffixType);
                        if (library == null) library = findLibraryWithoutCWD(state, state.searchFile, state.suffixType);
                
                        if (library == null) {
                            library = findLibraryWithClassloaders(state, state.searchFile, state.suffixType);
                            if (library == null) {
                                throw runtime.newLoadError("no such file to load -- " + file, file);
                            }
                        }
                        try {
                            library.load(runtime, wrap);
                        } catch (IOException e) {
                            if (runtime.getDebug().isTrue()) e.printStackTrace(runtime.getErr());
                            throw newLoadErrorFromThrowable(runtime, file, e);
                        }
                    } finally {
                        loadTimer.endLoad(file, startTime);
                    }
                }
            
            It seems that JRuby has a loadTimer but without displaying library loadtime in default. I'm going to find how to get the loadtime of every library and decide which could be reduced or just optimized.
