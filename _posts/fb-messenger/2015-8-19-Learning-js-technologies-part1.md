---
layout: post
title:  "Learning reactjs flux, node, electron ... (Part-1)"
date:   2015-8-19 6:00:00
description: Its been a while since I last worked on big enough javascript project. Javascript landscape has changed a lot since then. Es6, Es7 are now hot topics, so are the technologies like gulp/grunt nodejs and npm. I have been learning about these technologies through various sources, but haven't been able practically apply what I have learned.
categories:
- fb-messenger
tags : [fb-messenger, node.js, io.js, es6, npm, typescript, gulp, atom-electron.]  
---
{% include JB/setup %}
{% include fb-messenger/Learning-js-technologies-parts.md %}
<p class="first">
Its been a while since I last worked on big enough javascript project. Javascript landscape has changed a lot since then. 
Es6, Es7 are now hot topics, so are the technologies like gulp/grunt nodejs and npm.
I have been learning about these technologies through various sources, but haven't been able practically apply what I have learned.
So I came up with this plan to get my hands dirty by writing some code using these technologies. I'm planning this post to be a series, where I'll track my progress. 
To get started, I'll be setting up a project and commit it to github.
</p>

(Be warned!! It is a project to get my hands dirty on, it may never be completed. Also, be warned that I'm in no way authority over these topics.)
 
## About the project

This is going to be github's [electron](http://electron.atom.io/) based desktop application. Windows will be used as primary target, as I have easy access to windows machine, 
but hopefully it will be cross platform due to the technology being used. 
I'll try to build it for mac once I get hold of a mac machine. 

I've been hearing quite nice thing about [React.js](http://facebook.github.io/react/) by Facebook, so I started learning it, and I'm liking it. 
The UI will be built using Facebook's [React.js](http://facebook.github.io/react/), hence JSX syntax will be used a lot. 
I'm also learning [Flux](https://facebook.github.io/flux/) as the recommended (by Facebook) way to structure code in big projects. 
Planning to use [Delorean-js](http://deloreanjs.com/) for Flux.

I'm also thinking that this would be good place to get started with typescript. Hence the code will be written in typescript and compiled to es6, 
and then the es6 output further compiled to es5 using browserify and babel. 
Why would we do that? Why doubly compile? It is because I'd like to use latest features like async/await which would be supported only when targeted to es6, 
but es6 is not yet fully supported by chrome, hence not fully supported by electron either. Choice of my build script is gulp. 

There is one problem with using reactjs and typescript together. JSX is not supported by the current stable version of typescript (i.e. v1.5). 
To get around this issue we will get typescript directly from the github.

## Requirements

- [Node.js](https://nodejs.org/) or [Io.js](https://iojs.org/en/index.html), I'm using Io.js since jsdom requires it, and I'm planning to use jsdom for testing purpose.
- IDE/Editor with good js support. I'll be looking into using webstorm and may be [atom](https://atom.io/) 
with [atom-typescript](https://atom.io/packages/atom-typescript) plugin.
- Some knowledge of how various technologies involved works. For example, this is not going to be a tutorial on how nodejs, reactjs, flux, gulp or electron works.
I may point out to the tutorials I have gone through (i.e. if I remember the links).
- Git will be used for version control, and github will be used for sharing the code + collaboration (if anyone is interested). 
As I already have installed and correctly setup [github for desktop](https://desktop.github.com/) to [my github account](https://github.com/nripendra), I'll be using it.

## Goal

The goal is to create a messenger application that can be used to communicate with Facebook chat. Once again be warned, that this project may never be completed.

## So let's get started...

### Create folder named "fb-messenger"

Do this where you want your create your project, for my case I'm doing it inside D:\Projects\Node\. Hence full path of my project is D:\Projects\Node\fb-messenger.
You can choose your own location.

### Open webstorm

You'll have to download and setup the webstorm editor first. This is not mandatory, you can choose to use any text editor or IDE of your choice (including notepad).
But I would recommend editors with good Js support notepad++, atom, vscode etc. should do fine.
Open the project folder (i.e. "fb-messenger")
<img src="/assets/posts/fb-messenger-1/2.2.png" alt="Open project in webstorm..." />

As expected, it is an empty project. Now in the terminal window, execute command "git init".
<img src="/assets/posts/fb-messenger-1/2.3.png" alt="Empty project..." />

Of course you can do it in window's own command window. But don't forget to install git first.

Now execute this command "npm init". Few questions will be asked by npm about your project, 
answer the questions and you will have a file named "package.json" in the fb-messenger folder. 
I'm setting to following values (You can choose your own values):

```json
{
  "name": "fb-messenger",
  "version": "1.0.0",
  "description": "facebook messenger",
  "main": "index.js",
  "scripts": {
    "test": "gulp test"
  },
  "keywords": [
    "facebook",
    "desktop",
    "messenger"
  ],
  "author": "Nripendra",
  "license": "MIT"
}
```

Note: npm is part of io.js, make sure you have installed io.js before trying npm command. Also remember that npm also works if you have node.js installed.

Now add a new file named ".gitignore" in "fb-messenger" folder, 
and paste content from here [https://github.com/github/gitignore/blob/master/Node.gitignore](https://github.com/github/gitignore/blob/master/Node.gitignore), 
and then paste following lines at the end of the file.

```
electron
out
tests/out
.idea
```

These are the additional folders that we want to ignore in git, along with the standard node.js specific ignores.

Next step is to add tsconfig.json in "fb-messenger" folder. Add following content to tsconfig.json

```json
{
	"compilerOptions": {
	"noImplicitAny": true,
	"target": "es6",
	"isolatedModules": false,
	"jsx": "react",
	"experimentalDecorators": true,
	"experimentalAsyncFunctions": true,
	"emitDecoratorMetadata": true,
	"preserveConstEnums": true,
	"declaration": true,
	"sourceMap": true,
	"outDir": "./out/js",
	"suppressImplicitAnyIndexErrors": true
	},
	"filesGlob": [
	"./src/**/*.ts",
	"./src/**/*.tsx",
	"./tools/typings/**/*.d.ts",
	"!./node_modules/**/*",
	"!./out/**/*",
	"!./tests/out/**/*",
	"!./electron/**/*"
	]
}
```
tsconig.json is the project file for typescript, compilerOptions are command line switches for the typescript compiler. 
And filesGlob specify the files to include or exclude while compiling (*note lines starting with exclamation (!) means exclude*).

Now add another file named "tsd.json" in "fb-messenger" folder, with following content:

```json
{
	"version": "v4",
	"repo": "borisyankov/DefinitelyTyped",
	"ref": "master",
	"path": "tools/typings",
	"bundle": "tools/typings/tsd.d.ts"
}
```

Now create following folder structure:

- fb-messenger
	- electron
		- cache
		- build
	- node_modules
	- out
		- js
		- compile
	- src
		- actions
		- components
		- decorators
		- services
		- stores
		- styles
	- tests
		- specs
		- helpers
		- out
	- tools
		- typings

Your overall folder structure should look something like this:
<img src="/assets/posts/fb-messenger-1/2.9.png" alt="Tree structure of project..." />

Phew!! These were some handful steps, but we are quite done with setting up the project structure. We will now begin writing various codes.

This post turned out to be quite a long one, so I'll split this post into two. In the next post, I'll show you how I wrote initial code and committed to github.
