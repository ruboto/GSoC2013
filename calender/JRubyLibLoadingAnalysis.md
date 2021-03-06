<div id="table-of-contents">
<h2>Table of Contents</h2>
<div id="text-table-of-contents">
<ul>
<li><a href="#sec-1">1. Retrive data from mobile device</a></li>
<li><a href="#sec-2">2. Analyse data</a></li>
<li><a href="#sec-3">3. High time-consuming tasks</a>
<ul>
<li><a href="#sec-3-1">3.1. About Ruboto classes</a></li>
<li><a href="#sec-3-2">3.2. About JRuby</a>
<ul>
<li><a href="#sec-3-2-1">3.2.1. BeanManager</a></li>
<li><a href="#sec-3-2-2">3.2.2. BaseBodyCompiler</a></li>
<li><a href="#sec-3-2-3">3.2.3. non-linux posix</a></li>
<li><a href="#sec-3-2-4">3.2.4. Section conclusion</a></li>
</ul>
</li>
</ul>
</li>
</ul>
</div>
</div>
# Retrive data from mobile device

As we have finished modifying the Ruboto Benchmark Client with the customized JRuby-core. It has been possible to get a full list of load times as everything loaded with `org.jruby.runtime.load.LoadService`. So, for further analysis, I slightly changed the code to write the load times into a file in external storage.

            jruby_benchmark = ""
            LoadService.loadTimes.each do |k,v|
              jruby_benchmark += k + " " + v.to_s + "\n"
            end
            compat = System.getProperty("jruby.compat.version").capitalize
            compile = System.getProperty("jruby.compile.mode").downcase
    # Need help!
    # something strange happens here. The code
    # logfile = "/sdcard/rbc/#{compat}-#{compile}.log" would just make the app crash 
    # ... syntax error: unexpected kDO_BLOCK ... Why? What's the difference?
            logfile = "/sdcard/rbc/"+compat+"-"+compile+".log"
            File.open(logfile, "w+") do |writer|
              writer << jruby_benchmark
            end
            toast "Wrote to #{logfile}"

# Analyse data

For a intuitive understanding, I draw 4 pictures to compare the benchmark differences between 4 combinations of compat version and compile mode. The pictures are in `jruby_loading_logs`.

According to the 4 pictures. There's not too much differences between Ruby1.9 or Ruby1.8. And the compile mode seems not important either. Of cource, above-mentioned contents are only about the startup progress.

What should be done next step? Trying to dive into the libs and evaluate its necessity for Ruboto?

# High time-consuming tasks

According to the 4 graphs, we can select a list of libs whose loading times are more than 150ms. If we could do something to optimize some of them, it could help with speeding up the startup process. They should be inspected in code detail.   
Some of the libs only exist in Ruboto not JRuby.

-   ruboto/widget (about 280ms)

-   ruboto/activity (about 600ms)

-   ruboto/base (about 500ms)

-   report.rb(Only in RBC) (about 450ms)

-   jruby/java/core<sub>ext</sub> (about 250ms)

-   jruby/java/java<sub>ext</sub> (about 700ms)

-   jruby/java/java<sub>ext</sub>/java.lang (about 350ms)

-   jruby/kernel.rb (about 250ms)

## About Ruboto classes

After reading the code in `src/ruboto`. I think it is really concise to make much optimization. The high time-consuming mainly caused by JRuby's performance but not the ruby scripts themselves.

## About JRuby

Thanks to @donV's excellent findings, [issue#435](https://github.com/ruboto/ruboto/issues/435) of ruboto/ruboto lists many possible candidates to avoid loading as they're quite useless on the Dalvik platform, such as the POSIX classes or some other stuff. Here I will try to remove them and make sure they're really removable one by one.

-   org.jruby.runtime.opto.OptoFactory

-   org.jruby.compiler.impl.BaseBodyCompiler

-   org.jruby.management.BeanManagerImpl

-   javax/management/InstanceAlreadyExistsException

-   jnr.posix.FreeBSDPOSIX

-   jnr.posix.MacOSPOSIX

-   jnr.posix.OpenBSDPOSIX

-   jnr.posix.SolarisPOSIX

-   jnr.posix.WindowsPOSIX

-   sun.misc.Unsafe

-   org.jruby.util.unsafe.UnsafeHolder

-   java.lang.management.ManagementFactory.getGarbageCollectorMXBeans, referenced from method org.jruby.RubyGC.count

-   sun.misc.Signal referenced from method org.jruby.util.SunSignalFacade.trap

-   org.jruby.util.SunSignalFacade$JRubySignalHandler

### BeanManager

<p class="verse">
modified:   src/org/jruby/management/BeanManagerFactory.java <br/>
deleted:    src/org/jruby/management/BeanManagerImpl.java <br/>
</p>

### BaseBodyCompiler

<p class="verse">
deleted:    src/org/jruby/compiler/impl/BaseBodyCompiler.java <br/>
</p>

### non-linux posix

These classes have been removed by `Ruboto::Util::Update.reconfigure_jruby_core(stdlib)` since 1.7.0 or earlier.

### Section conclusion

After removing the above classes from jruby. We still could not get a visible performance promotion as they're quite not responsible to the high time-consuming.
