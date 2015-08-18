---
layout: post
title:  "Portable Jekyll setup"
date:   2015-8-18 17:05:00
description: It has been sometime since I wrote my last post. I have switched couple of different machines in this period of time. I was trying to write a post, but then it occured to me that I have forgotten how I used to do it...
categories:
- meta
tags : [portable-jekyll-setup, portable-jekyll, visualstudio]
og:
  image: 
    url: http://www.gravatar.com/avatar/f686aaaf192af2dde05e60c4370bd2a0?s=400&d=identicon&r=PG
    secure_url: https://www.gravatar.com/avatar/f686aaaf192af2dde05e60c4370bd2a0?s=400&d=identicon&r=PG
    
---
It has been sometime since I wrote my last post. I have switched couple of different machines in this period of time. I was trying to write a post, but then it occured to me that I have forgotten how I used to do it :laughing:

In this post I'll try to outline the steps for my own future reference, someone else may find it helpful too.

- Go to https://github.com/madhur/PortableJekyll click "Download Zip" button.
- For more setup instruction look at https://github.com/madhur/PortableJekyll/wiki
- Create a file named **set_JEKYLL_PATH.cmd** with following content:

```bat 
SETX JEKYLL_PATH %~dp0
```
 
Save this file in same directory where you have portable jekyll, i.e. this file and protable jekyll's **setpath.cmd** should be on same level (in my case I have it at E:\portable-softwares\PortableJekyll), and double click the file.
This is one time setup, until you change the machine, once this file is double clicked it sets an environment variable named JEKYLL_PATH.

In the jekyll blog root path I have a file jekyllhelper.bat with following content.

```bat
ECHO Setting env variables...

ECHO %1

if "%1"=="-d" (
	CALL %JEKYLL_PATH%setpath.cmd
	START jekyll serve & ping 1.1.1.1 -n 1 -w 10000 > nul  & START http://localhost:4000/ & EXIT
	EXIT
) else (
	CALL %JEKYLL_PATH%setpath.cmd
	jekyll %1
)
```

- ref:
	- https://github.com/nripendra/nripendra.github.io (see there is Jekyllhelper.bat file)
	- https://github.com/nripendra/nripendra.github.io/blob/master/Jekyllhelper.bat (refer it's content.)

Open command window in root path of your blog project (in my case it is at D:\Git\nripendra.github.io), type 'Jekyllhelper build'. This compiles the md files into html and opens the homepage in the default browser. Sometimes the serving process may not be
completed withing 10 seconds, in that case wait for sometime and then refresh the browser.

If you look carefully my blog has visual studio project file. In this project file I have removed all other targets and added following custom target:

```xml
<Target Name="Jekyll">
    <Exec Command="Jekyllhelper.bat build" />
</Target>
```

And set the project default target to the custom "Jekyll"  we have created as shown :

```xml
<Project ToolsVersion="12.0" DefaultTargets="Jekyll"...>
...
</Project>
```

- ref:
	- https://github.com/nripendra/nripendra.github.io/blob/master/nripendra.github.io.csproj

With all above mentioned setup my process would be:
	
- Run set_JEKYLL_PATH.cmd (one time operation).
- Make changes to posts (Add/edit posts and save) in visualstudio.
- In visual studio press F5
- Once jekyll server is running it watches for changes itself, from this time forward all I need to do is make changes to posts and refresh the browser.

Note to self:

- Posts must be saved without BOM 
- Refer (http://blogs.nnn.ninja.np/meta/2014/11/01/about-myfavicon/) to remove BOM in visualstudio.


