---
layout: post
title:  "Learning reactjs flux, node, electron ... (Part-4)"
date:   2015-8-21 6:00:00
description: Finally we now have a basic structure of folders, configurations files, build system and a minimal running program in place, after these excruciating long process.
categories:
- fb-messenger
tags : [fb-messenger, node.js, io.js, es6, npm, typescript, gulp, atom-electron.]  
---
{% include JB/setup %}

Finally we now have a basic structure of folders, configurations files, build system and a minimal running program in place, after these excruciating long process. Now, its time
to commit things to git and sync with github. If you have followed throughly, I haven't created a repository in github. We do have a local git repository but it isn't cloned
from github. At this point, my initial thought was something on this line:

- Rename local folder.
- Goto to github.com.
- Create repository there.
- Clone the repository (using clone to desktop button).
- Copy all the files/folders to this cloned repository.
- commit and Sync.

Phew! quite a process. Luckily I didn't do it! I wanted to investigate if github for desktop had easier way. Well thanks to github, it does have that feature. Heres how I did it:

- Open github for windows and click on the "+" icon.
- Choose "Add" tab 
- Type name of repository and paste the path of repository (D:\Projects\Node\fb-messenger for me), then click "Create repository" button
- Now commit the files, and click on "publish"

Thats it!!

This is how dialog for adding existing repository looks like.
<img src="/assets/posts/fb-messenger-1/git01.png" alt="Add existing repository to Github for desktop" />

Once repository is added, you will now get option to commit and publish.
<img src="/assets/posts/fb-messenger-1/git02.png" alt="Commit/publish options.." />

Hmm.. there is one small detail that I skiped. I also have added a readme.md file. Haven't added a license file yet, but will do it. This whole code will be in MIT license, 
so that everybody has full freedom with the code. But be cautious, npm packages that we are installing with "npm install xxx --save-dev" command do have their own licenses.

Well thats it folks! a comparatively short post in the whole series :D

By the way the project is at [https://github.com/nripendra/fb-messenger](https://github.com/nripendra/fb-messenger)