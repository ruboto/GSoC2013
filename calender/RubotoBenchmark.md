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
</ul>
</li>
</ul>
</div>
</div>


\## Purpose

We already have had a [Ruboto benchmark client](<https://github.com/ruboto/ruboto_benchmark_client>), however as we want to know some more details about JRuby libraries loading process. We're going to implement a more detailed benchmark client based on the existing one.

\## Enable JRuby load timer

We can make it on PC directly by run \`jruby -J-Djruby.debug.loadService=true -J-Djruby.debug.loadService.timing=true /path/to/script.rb\`. Then we will get JRuby's LoadService log, here's an example

> &#x2026;
> 2013-06-19T19:29:58.278+08:00: LoadService:         <- jruby/java/java<sub>module</sub> - 32ms
> 2013-06-19T19:29:58.307+08:00: LoadService:         <- jruby/java/java<sub>package</sub><sub>module</sub><sub>template</sub> - 28ms
> 2013-06-19T19:29:58.329+08:00: LoadService:         <- jruby/java/java<sub>utilities</sub> - 21ms
> 2013-06-19T19:29:59.333+08:00: LoadService:   <- classloader:jruby/kernel.rb - 376ms
> &#x2026;

\## Enable JRuby load timer on Dalvik

We can enable it similarly on Dalvik by uncomment two lines of code in \`org.ruboto.JRubyAdapater\`

System.setProperty("jruby.debug.loadService", "true");
System.setProperty("jruby.debug.loadService.timing", "true");

After that, we can see similar log in Logcat tagged System.err.

\## Access loadtime data with java code.

When the property \`jruby.debug.loadService.timing\` is true, JRuby sets a constant named \`DEBUG<sub>LOAD</sub><sub>TIMINGS\`</sub>. Then it will enable \`TracingLoadTimer\` in \`org.jruby.runtime.load.LoadService\` which extents the default \`LoadTimer\`.

Maybe we should add something here to access the loading time in Ruboto.

public void endLoad(String file, long startTime) {
    LOG.info(getIndentString() + "<- " + file + " - "

-   (System.currentTimeMillis() - startTime) + "ms");

    indent.decrementAndGet();
}
