<div id="table-of-contents">
<h2>Table of Contents</h2>
<div id="text-table-of-contents">
<ul>
<li><a href="#sec-1">1. Retrive data from mobile device</a></li>
<li><a href="#sec-2">2. Analysis data</a></li>
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

# Analysis data

For a intuitive understanding, I draw 4 pictures to compare the benchmark differences between 4 combinations of compat version and compile mode. The pictures are in `jruby_loading_logs`.

According to the 4 pictures. There's not too much differences between Ruby1.9 or Ruby1.8. And the compile mode seems not important either. Of cource, above-mentioned contents are only about the startup progress.

What should be done next step? Trying to dive into the libs and evaluate its necessity for Ruboto?
