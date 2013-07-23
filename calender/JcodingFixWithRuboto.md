<div id="table-of-contents">
<h2>Table of Contents</h2>
<div id="text-table-of-contents">
<ul>
<li><a href="#sec-1">1. rscottm's fix of Jcodings</a></li>
<li><a href="#sec-2">2. Benchmark measurement</a></li>
</ul>
</div>
</div>
# rscottm's fix of Jcodings

Inspired by [<https://github.com/jruby/jcodings/pull/6>]. I cloned the fixed version from [<https://github.com/ruboto/jcodings>] and build it on my PC. Then directly replaced the `org.jcodings` with files from this building.

# Benchmark measurement

The time data is an average of about 10 startups.

-   JRuby version: 1.7.4

-   Device: Sony LT26ii, Android-17

<table border="2" cellspacing="0" cellpadding="6" rules="groups" frame="hsides">


<colgroup>
<col class="left"/>

<col class="right"/>

<col class="right"/>
</colgroup>
<tbody>
<tr>
<td class="left">Compat version & Compile mode</td>
<td class="right">1.8</td>
<td class="right">1.9</td>
</tr>


<tr>
<td class="left">off</td>
<td class="right">6745</td>
<td class="right">7403</td>
</tr>


<tr>
<td class="left">offir</td>
<td class="right">6832</td>
<td class="right">7447</td>
</tr>
</tbody>
</table>

-   Jcodings replaced JRuby

<table border="2" cellspacing="0" cellpadding="6" rules="groups" frame="hsides">


<colgroup>
<col class="left"/>

<col class="right"/>

<col class="right"/>
</colgroup>
<tbody>
<tr>
<td class="left">Compat version & Compile mode</td>
<td class="right">1.8</td>
<td class="right">1.9</td>
</tr>


<tr>
<td class="left">off</td>
<td class="right">6634</td>
<td class="right">7379</td>
</tr>


<tr>
<td class="left">offir</td>
<td class="right">6653</td>
<td class="right">7303</td>
</tr>
</tbody>
</table>

According to the charts above.It seem that Scott's optimization quite make jruby/ruboto startup faster for about 50-150ms. Of course, the data is just for reference because of the low testing times and few versions of devices and JRuby.
