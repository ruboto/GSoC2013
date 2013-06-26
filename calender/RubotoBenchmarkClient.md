<div id="table-of-contents">
<h2>Table of Contents</h2>
<div id="text-table-of-contents">
<ul>
<li><a href="#sec-1">1. Ruboto Benchmark Client</a>
<ul>
<li><a href="#sec-1-1">1.1. Modify the app for detailed JRuby benchmark</a>
<ul>
<li><a href="#sec-1-1-1">1.1.1. Change the layout</a></li>
</ul>
</li>
<li><a href="#sec-1-2">1.2. Create a button to report all benchmarks</a></li>
<li><a href="#sec-1-3">1.3. Make the starting mode predictable</a></li>
</ul>
</li>
</ul>
</div>
</div>
# Ruboto Benchmark Client

We have had a benchmark tool [Ruboto Benchmark Client](https://github.com/ruboto/ruboto_benchmark_client) running on Android devices, you can directly download it from Google Play.

## Modify the app for detailed JRuby benchmark

Last time, I've customized a new jruby with a map storing the loading times of jruby libraries. What we need to do now is to change the layout to reflect the new feature of `org.jruby.runtime.load.LoadService.loadTimes`.

### Change the layout

Add a button for jruby loading details. Temporarily use a toast to display the JRuby lib loading details. As there're quite too many entries to display. Maybe we can find a better solution.

    button :id => 57, :text => 'JRuby Libs', :text_size => button_size, :layout => button_layout,
           :on_click_listener => proc { 
    jruby_benchmark = ""
    LoadService.loadTimes.each do |k,v|
      jruby_benchmark += k + " " + v.to_s + "ms\n"
    end
    toast jruby_benchmark

## Create a button to report all benchmarks

Modify the code of button "Report" to provide a function to report all measurements already exist. Now, there's a problem that the code of open the benchmark webpage is written in `Report#send_report`. I'm going to add a `send_all_reports` method and make some modification on `send_report` so that the browser would be opened after all benchmarks been reported.

      button :id => 44, :text => 'Report All', :text_size => button_size, :layout => button_layout,
             :on_click_listener => proc { 
      $benchmarks.each do |k,v|
        Report.send_report(self, k, v)
      end  
    }

## Make the starting mode predictable
