<div id="table-of-contents">
<h2>Table of Contents</h2>
<div id="text-table-of-contents">
<ul>
<li><a href="#sec-1">1. Ruboto Benchmark</a>
<ul>
<li><a href="#sec-1-1">1.1. Purpose</a></li>
<li><a href="#sec-1-2">1.2. Enable JRuby load timer</a></li>
<li><a href="#sec-1-3">1.3. Enable JRuby load timer on Dalvik</a></li>
<li><a href="#sec-1-4">1.4. Access loadtime data with java code.</a></li>
<li><a href="#sec-1-5">1.5. Customize JRuby</a>
<ul>
<li><a href="#sec-1-5-1">1.5.1. Test the new JRuby</a></li>
<li><a href="#sec-1-5-2">1.5.2. Usage in Ruboto apps</a></li>
</ul>
</li>
</ul>
</li>
</ul>
</div>
</div>
# Ruboto Benchmark

## Purpose

We already have had a [Ruboto benchmark client](https://github.com/ruboto/ruboto_benchmark_client), however as we want to know some more details about JRuby libraries loading process. We're going to implement a more detailed benchmark client based on the existing one.

## Enable JRuby load timer

We can make it on PC directly by run `jruby -J-Djruby.debug.loadService=true -J-Djruby.debug.loadService.timing=true /path/to/script.rb`. Then we will get JRuby's LoadService log, here's an example

> &#x2026;   
> 2013-06-19T19:29:58.278+08:00: LoadService:         <- jruby/java/java<sub>module</sub> - 32ms   
> 2013-06-19T19:29:58.307+08:00: LoadService:         <- jruby/java/java<sub>package</sub><sub>module</sub><sub>template</sub> - 28ms   
> 2013-06-19T19:29:58.329+08:00: LoadService:         <- jruby/java/java<sub>utilities</sub> - 21ms   
> 2013-06-19T19:29:59.333+08:00: LoadService:   <- classloader:jruby/kernel.rb - 376ms   
> &#x2026;   

## Enable JRuby load timer on Dalvik

We can enable it similarly on Dalvik by uncomment two lines of code in `org.ruboto.JRubyAdapater`

    System.setProperty("jruby.debug.loadService", "true");
    System.setProperty("jruby.debug.loadService.timing", "true");

After that, we can see similar log in Logcat tagged System.err.

## Access loadtime data with java code.

When the property `jruby.debug.loadService.timing` is true, JRuby sets a constant named `DEBUG_LOAD_TIMINGS`. Then it will enable `TracingLoadTimer` in `org.jruby.runtime.load.LoadService` which extents the default `LoadTimer`.

Maybe we should add something here to access the loading time in Ruboto.

    public void endLoad(String file, long startTime) {
        LOG.info(getIndentString() + "<- " + file + " - "
                + (System.currentTimeMillis() - startTime) + "ms");
        indent.decrementAndGet();
    }

## Customize JRuby

We can use a HashMap to store the load times and declare it `public static` to make it accessible outside the class.

    // org.jruby.runtime.load.LoadService
        public static Map<String, Long> loadTimes = new HashMap<String, Long>();
    //...
        public void endLoad(String file, long startTime) {
            long loadTime = System.currentTimeMillis() - startTime;
            loadTimes.put(file,loadTime);
            indent.decrementAndGet();
        }

### Test the new JRuby

Write a simple ruby script to test out new feature.

    import org.jruby.runtime.load.LoadService
    LoadService.loadTimes.each do |pair|
      p pair
    end

Run `jruby -J-Djruby.debug.loadService.timing=true profile.rb` and we can find that we've successfully stored the detailed load times in the hashmap.

> ["thread.jar", 1]
> ["jruby/kernel/jruby/generator.rb", 114]
> ["jruby/java/java<sub>ext</sub>/java.util.regex", 51]
> ["etc", 15]
> ["rubygems/version", 24]
> ["jruby/java/java<sub>ext</sub>/java.io", 39]
> ["rubygems/config<sub>file</sub>", 58]
> ["rubygems/specification", 316]
> ["jruby/java/java<sub>ext</sub>/java.lang", 164]
> ["classloader:jruby/kernel.rb", 147]
> ["jruby/kernel19/encoding/converter.rb", 1]
> &#x2026;&#x2026;
> ["jruby/util", 4]
> ["jruby/java/java<sub>ext</sub>/java.util", 30]
> ["rubygems/platform", 41]
> ["jruby/kernel19/gc.rb", 47]
> ["jruby/java/core<sub>ext</sub>/object", 39]
> ["rbconfig", 19]
> ["jruby/kernel/signal.rb", 21]
> ["jruby/kernel19/rubygems.rb", 638]
> ["rubygems", 636]
> ["classloader:jruby/kernel19.rb", 806]
> ["classloader:jruby/jruby.rb", 22]
> ["rubygems/requirement", 20]
> ["jruby", 738]
> ["rubygems/deprecate", 4]
> ["jruby/java", 604]
> ["jruby/kernel19/proc.rb", 12]

### Usage in Ruboto apps

As we enable this feature by customizing JRuby, we will have to compile a new ruboto apk with JRuby-customized.jar.   

1.  Construct jruby-core.jar

    We can directly run `ruboto gen jruby` to generate simplified jruby-core.jar and jruby-stdlib.jar. Our modification is in `org.jruby.runtime.load.LoadService`, so what we need to do is extracting the customized jruby-core.jar and just replace the different files.

2.  Run it

    After excuting `rake debug` , `rake install` . Our app with a customized JRuby should be working.
