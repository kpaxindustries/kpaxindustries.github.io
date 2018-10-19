---
layout: post
title:  "Poison"
date:   2018-09-08 09:17:00 +0100
categories: hackthebox
---
* TOC
{:toc}
# Introduction
* Name of Box : Poison
* IP Address : 10.10.10.84

A fun little box where if you overthink things you could really make things difficult for yourself. Enumeration is key

### Further Reading
* SSH port forwarding : <https://www.ssh.com/ssh/tunneling/example>

{% highlight plaintext %}
vncviewer -passwd secret 127.0.0.1:5901
{% endhighlight %}
![]({{ "assets/screen4.png" | absolute_url }})
