---
layout: post
title:  "Learning reactjs flux, node, electron ... (Part-2)"
date:   2015-8-20 6:00:00
description: In previous post we created project's folder structure and wrote some json config files. In this post we will continue on that and write some code.
categories:
- fb-messenger
tags : [fb-messenger, node.js, io.js, es6, npm, typescript, gulp, atom-electron.]  
---
{% include JB/setup %}

{% include fb-messenger/Learning-js-technologies-parts.md %}
<p class="first">
In previous post we created project's folder structure and wrote some json config files. In this post we will continue on that and write some code.
</p>
 
## About the folder structure

Lets get started by explaining about how I plan to use the folders.

- electron: this folder will be used to save electron files, cache folder will be used by gulp-atom package to download and cache the prebuilt electron files, and in build folder we will have our final product.
- out: this folder will contain compiled output. In js we will have the output of typescript compilation, and in compile we will further compile the files in the js folder using babel and browserify to create single js file.
- src: this folder is where we will have all our codes. Since I'm planning to use Flux pattern, I'm already dividing this folder into several part like actions, stores etc.
- tests: this is where we will have our unit tests. We will write unit test in js + jsx probably using few es6/es7 features, so even test will require build step. The compiled test will be stored in tests/out folder
- tools/typings: this is where typescript definitions will reside.

## Lets begin

In src folder add a new file named "program.tsx". Now add following content:

```ts
export default class Program {
    static main() {
        console.log("Hello from electron!");
    }
}
```

This file is going to serve as the entry point for our application.

Add another file index.ts (in src folder) with following content:

```ts
/// <reference path="../tools/typings/node/node.d.ts"/>
//@nrip - this is the browser side code for electron.
//view component folder for renderer side codes.
(function () {
    "use strict";

    let app = require('app'),
        Menu = require('menu'),
        BrowserWindow = require('browser-window');

    require('crash-reporter').start();

    var mainWindow:any = null;

    app.on('window-all-closed', function () {
        if (process.platform !== 'darwin') {
            app.quit();
        }
    });

    app.on('ready', function () {
        app.commandLine.appendSwitch("js-flags", "--harmony");
        mainWindow = new BrowserWindow({
            width: 300,
            height: 360,
            'min-width': 300,
            'min-height': 360,
            frame: true
        });
        mainWindow.loadUrl('file://' + __dirname + '/index.html');
        mainWindow.on('closed', function () {
            mainWindow = null;
        });

        var template:any;
        // Example of menu from official sample
        // https://github.com/atom/electron/blob/master/atom/browser/default_app/default_app.js
        template = [{
                label: '&File',
                submenu: [{
                    label: '&Close',
                    accelerator: 'Ctrl+W',
                    click: function () {
                        mainWindow.close();
                    }
                },]
            }, {
                label: '&View',
                submenu: [{
                    label: '&Reload',
                    accelerator: 'Ctrl+R',
                    click: function () {
                        mainWindow.restart();
                    }
                }, {
                    label: 'Toggle &Full Screen',
                    accelerator: 'F11',
                    click: function () {
                        mainWindow.setFullScreen(!mainWindow.isFullScreen());
                    }
                }, {
                    label: 'Toggle &Developer Tools',
                    accelerator: 'Alt+Ctrl+I',
                    click: function () {
                        mainWindow.toggleDevTools();
                    }
                },]
            }, {
                label: 'Help',
                submenu: [{
                    label: 'Learn More',
                    click: function () {
                        require('shell').openExternal('http://electron.atom.io')
                    }
                }, {
                    label: 'Documentation',
                    click: function () {
                        require('shell').openExternal('https://github.com/atom/electron/tree/master/docs#readme')
                    }
                }, {
                    label: 'Community Discussions',
                    click: function () {
                        require('shell').openExternal('https://discuss.atom.io/c/electron')
                    }
                }, {
                    label: 'Search Issues',
                    click: function () {
                        require('shell').openExternal('https://github.com/atom/electron/issues')
                    }
                }]
            }];

        var menu = Menu.buildFromTemplate(template);
        mainWindow.setMenu(menu);
    });

}());
```

Well a long one but pretty standard stuff, this is going to be mostly same for any electron project.

Remember that electron runs in two processes, the main process and the renderer process. The main process is the entry point that starts renderer process, most of user interaction happens in the renderer process. 
The index.ts is the code for main process and program.tsx is the code for renderer process. 

While the main process in electron starts with a javascript, the renderer process must start with html file, so lets add a file named "index.html" (in src folder), with following content:

```html

<!DOCTYPE html>
<html lang="en">
	<head>
		<meta charset="UTF-8">
		<title>Facebook messenger</title>
		<link href="./styles/main.css" rel="stylesheet" />
		<script type="text/javascript">
		var electronRequire = require;
		</script>
		<script src="./program.js" type="text/javascript"></script>
	</head>
	<body>
	</body>
</html>

```

Yup, that's it!!

We have 2 scripts. In first script I'm putting...

```js
var electronRequire = require;
```
This line is required since I'm planning to use browserify. Browserify will replace the original "require" method with it's own, so we do preserve the orginal require method and call electronRequire where ever we need the electron's native require method.

Another script includes "program.js", this is the compiled form of program.tsx, we will come to it in future posts.

Our src folder should look something like this:

<img src="/assets/posts/fb-messenger-2/1.png" alt="src folder" />


Done!! Yeah! We now have a fantastic program that prints "Hello from electron!" into the browser console when it runs. But how to run it?

Well! I lied, we are not done yet. We need to build this program to get it running. We will get this thing running in the next post. Oh common!!!