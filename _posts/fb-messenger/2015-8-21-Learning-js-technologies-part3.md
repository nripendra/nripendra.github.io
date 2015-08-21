---
layout: post
title:  "Learning reactjs flux, node, electron ... (Part-3)"
date:   2015-8-21 6:00:00
description: In previous post we did write some simple code, whose expected output is to print "Hello from electron!" into the console when we run the program.
categories: 
- fb-messenger
tags : [fb-messenger, node.js, io.js, es6, npm, typescript, gulp, atom-electron.]  
---
{% include JB/setup %}

In previous post we did write some simple code, whose expected output is to print "Hello from electron!" into the console when we run the program. Now the thing remaining is
to actually run the program. But to run program we will have to build first.
 
## Building javascript!!

Hmm.. yes, we will build javascript, the basic building will involve compiling typescript code to es6 code, and further transpile es6 code to es5 (js) code, and combile all the
modules into single file. Normally it is good idea to write various modules in seperate files for maintainability, but when deploying it is easier if all modules reside in one
file. In case of normal browser application we can further opt to minify and gzip the content.

## Lets begin

We will be using [gulp](http://gulpjs.com/) as our build tool. Actually it is a task runner similar to rake in Ruby world. We can create a list of tasks and decide the sequence
of task we would like to run to achieve our final output. To be able to create we will have to install gulp first. It is easy just open console and type following:

```
npm install gulp --save-dev
```
This will install gulp in node_modules folder. Now add another module:

```
npm install del --save-dev
```
This module will help in deleting files. Next create a file named gulpfile.config.js in project root folder (i.e. fb-messenger if you are following the same convention) 
and paste following content:

```js
'use strict';
var GulpConfig = (function () {
    function GulpConfig() {
        this.source = './src/';

        this.tsOutputPath = './out/js/';
        this.allTypeScript = this.source + '/**/*.{ts,tsx}';

        this.typings = './tools/typings/';
        this.libraryTypeScriptDefinitions = './tools/typings/**/*.ts';
        this.appTypeScriptReferences = this.typings + 'fbMessengerApp.d.ts';

        this.compiled = './out/compile'
    }
    return GulpConfig;
})();
module.exports = GulpConfig;
```

Next add a file named gulpfile.js in project root folder.

```js
'use strict';


var Config = require('./gulpfile.config'),
	del = require('del'),
	gulp = require('gulp');

var config = new Config();

gulp.task('clean-ts', function (cb) {
    var typeScriptGenFiles = [config.tsOutputPath + '**/*.*'];

    // delete the files
    del(typeScriptGenFiles, cb);
});
```
Congratulations!! we have created our first gulp task. The name of our task is 'clean-ts', and all it does is delete all files from the out/js/ folder. Not much usefull at this
point, since the folder in question is already empty as of now. Anyways, to run the desired task just goto to command line and type following:

```
gulp clean-ts
```
You should see something like this in output:

```
[17:56:43] Using gulpfile D:\Projects\Node\fb-messenger\gulpfile.js
[17:56:43] Starting 'clean-ts'...
[17:56:43] Finished 'clean-ts' after 4.86 ms
```

Now lets add another task. The goal of this task will be to generate typescript references automatically so that we don't have to type in the reference everytime we add a new
file. To do this lets first add a file "fbMessengerApp.d.ts" in the path "fb-messenger/tools/typings/", and add following content:

```js
//{

//}
```
I know, I know this doesn't make any sense yet. I too had found this in some other blog post, [http://weblogs.asp.net/dwahlin/creating-a-typescript-workflow-with-gulp](http://weblogs.asp.net/dwahlin/creating-a-typescript-workflow-with-gulp). 
You'll see how these comments are being used to insert references in between using "gulp-inject" recipe. I think same thing can be achieved using "gulp-insert" recipe. 
But I'll be following (rather blindly) same thing that is suggested in the above post, as its tried and tested technique.

Install one more npm module now:

```
npm install gulp-inject --save-dev
```
Add following line to gulpfile.js:

```js
inject = require('gulp-inject');
```

And now add one more task as:

```js
gulp.task('gen-ts-refs', ['clean-ts'], function () {
    var target = gulp.src(config.appTypeScriptReferences);
    var sources = gulp.src(config.allTypeScript, {read: false});
    return target.pipe(inject(sources, {
        starttag: '//{',
        endtag: '//}',
        transform: function (filepath) {
            return '/// <reference path="../..' + filepath + '" />';
        }
    })).pipe(gulp.dest(config.typings));
});
```
Done! Now we have two tasks in the gulpfile.js. Over all content should look something like this:

```js
'use strict';
var Config = require('./gulpfile.config'),
	del = require('del'),
	gulp = require('gulp');

var config = new Config();

gulp.task('clean-ts', function (cb) {
    var typeScriptGenFiles = [config.tsOutputPath + '**/*.*'];

    // delete the files
    del(typeScriptGenFiles, cb);
});

gulp.task('gen-ts-refs', ['clean-ts'], function () {
    var target = gulp.src(config.appTypeScriptReferences);
    var sources = gulp.src(config.allTypeScript, {read: false});
    return target.pipe(inject(sources, {
        starttag: '//{',
        endtag: '//}',
        transform: function (filepath) {
            return '/// <reference path="../..' + filepath + '" />';
        }
    })).pipe(gulp.dest(config.typings));
});
```
Lets now add task to compile typescript. For that we will add two more npm packages.

```
npm install gulp-sourcemaps --save-dev
npm install gulp-typescript --save-dev
npm install https://github.com/Microsoft/TypeScript.git --save-dev
```

Notice we are installing typescript directly from github. Since, we want to use some features that are not yet released in stable version. With these two packages installed,
we are ready to compile our typescript code. Add following lines to the require section:

```js
sourcemaps = require('gulp-sourcemaps'),
tsc = require('gulp-typescript'),
typescript = require('typescript');
```
And now add another line:

```js
var tsconfig = tsc.createProject('tsconfig.json', {typescript: typescript});
```
This will read typescript configuration we had created in part-1 of the series. Once we have this setup in place, now w are ready to write task:

```js
gulp.task('compile-ts', ['gen-ts-refs'], function () {
    var sourceTsFiles = [config.allTypeScript,	//path to typescript files
        config.libraryTypeScriptDefinitions,	//reference to library .d.ts files
        config.appTypeScriptReferences];		//reference to fbMessengerApp.d.ts files

    var tsResult = gulp.src(sourceTsFiles)
        .pipe(sourcemaps.init())
        .pipe(tsc(tsconfig));

    tsResult.dts.pipe(gulp.dest(config.tsOutputPath));

    return tsResult.js
        .pipe(sourcemaps.write('.'))
        .pipe(gulp.dest(config.tsOutputPath));
});
```
Well this task will now compile the typescript code and generate javascript code, and put the code into the "out/js" folder. Meanwhile it will also create sourcemaps.
You may have noticed, array of previous task being passed as parameter of task, it signifies dependencies. It means 'compile-ts' is dependent on 'gen-ts-refs', and 
'gen-ts-refs' is dependent on 'clean-ts'.

Next step is to browserify/babelify the generated js code.

```
npm install browserify --save-dev
npm install babelify --save-dev
npm install vinyl-source-stream --save-dev
npm install glob --save-dev
```

Require the packages:

```js
babelify = require("babelify"),
Browserify = require('browserify'),
glob = require('glob'),
source = require('vinyl-source-stream'),
```

The task:

```js
gulp.task('browserify', ['compile-ts'], function () {
    var babelifyStep = babelify.configure({stage: 0});

    var allFiles = glob.sync(config.tsOutputPath + "**/*.js", {ignore: config.tsOutputPath + 'index.js'});
    var bundler = new Browserify({
        entries: allFiles,
        transform: [ babelifyStep ]
    });
    return bundler
        .bundle()
        .pipe(source('program.js'))
        .pipe(gulp.dest(config.compiled));
});
```

Browserify is responsible for crawling all the module dependencies and concatinating them into single file. Bable is responsible for converting es6/7 code to es5 code. 
The above task will work, but we also explicitly need to call Program.main() function to get our programming running. We can do that directly in program.tsx file. But 
I wanted to follow the idiom that we follow when writing c or c# applications. We don't explicitly call the main function, we just write the function and leave it to be,
called automatically when program gets executed. Javascript doesn't work that way, so we need to add some magic to get this working. Lets add one more task:

npm:

```
npm install gulp-insert --save-dev
```

require:

```js
insert = require('gulp-insert'),
```

the actual task:

```js
gulp.task('append-runner', ['compile-ts'], function () {
    return gulp.src(config.tsOutputPath + "program.js")
        .pipe(insert.append('\n\ndocument.addEventListener("DOMContentLoaded", function(e){require("./Program").main();});'))
        .pipe(gulp.dest(config.tsOutputPath))
});
```

So, this file will add one extra line at the end of program.js file when program.tsx has been compiled, as we can see 'append-runner' task depends upon 'compile-ts' to finish first.
Now, we will change the browserify to depend on 'append-runner' instead of 'compile-ts' as such:

```js
gulp.task('browserify', ['append-runner'], function () {
    ...
});
```

Let's add one more task:

npm:

```
npm install babel --save-dev
```

require:

```js
babel = require("gulp-babel"),
```

task:

```js
gulp.task('copy-static', ['compile-ts'], function () {
    gulp.src('./out/js/index.js')
        .pipe(babel({stage: 0}))
        .pipe(sourcemaps.write('.'))
        .pipe(gulp.dest(config.compiled));

    return gulp.src(['./src/index.html', './package.json'])
        .pipe(gulp.dest(config.compiled));
});
```

Well this task transpiles index.js (compiled output of index.ts) using bable, and saves output in same folder where browserify task saves it's output (i.e. /out/compiled). Along
with index.js it also copies, index.html and package.json files to same directory.

Now let's look into generating electron application.

npm:

```
npm install gulp-atom --save-dev
```

require:

```js
atom = require('gulp-atom'),
```

task:

```js
gulp.task('atom', ['browserify', 'copy-static'], function () {
    return atom({
        srcPath: './out/compile',
        releasePath: './electron/build',
        cachePath: './electron/cache',
        version: 'v0.26.1',
        rebuild: false,
        asar: true,
        platforms: ['win32-ia32']
    });
});
```

That's all! Yeah, it was quite easy. Now all we need to do is run the 'atom' task, and wait for it to generate the output at "/electron/build" directory. Let's put together what
has been achieved till now:

```js
var atom = require('gulp-atom'),
    babel = require("gulp-babel"),
    babelify = require("babelify"),
    Browserify = require('browserify'),
    Config = require('./gulpfile.config'),
    del = require('del'),
    glob = require('glob'),
    gulp = require('gulp'),
    inject = require('gulp-inject'),
    insert = require('gulp-insert'),
    source = require('vinyl-source-stream'),
    sourcemaps = require('gulp-sourcemaps'),
    tsc = require('gulp-typescript'),
    typescript = require('typescript');

var config = new Config();
var tsconfig = tsc.createProject('tsconfig.json', {typescript: typescript});

gulp.task('clean-ts', function (cb) {
    var typeScriptGenFiles = [config.tsOutputPath + '**/*.*'];

    // delete the files
    del(typeScriptGenFiles, cb);
});

gulp.task('gen-ts-refs', ['clean-ts'], function () {
    var target = gulp.src(config.appTypeScriptReferences);
    var sources = gulp.src(config.allTypeScript, {read: false});
    return target.pipe(inject(sources, {
        starttag: '//{',
        endtag: '//}',
        transform: function (filepath) {
            return '/// <reference path="../..' + filepath + '" />';
        }
    })).pipe(gulp.dest(config.typings));
});

gulp.task('compile-ts', ['gen-ts-refs'], function () {
    var sourceTsFiles = [config.allTypeScript,                //path to typescript files
        config.libraryTypeScriptDefinitions, //reference to library .d.ts files
        config.appTypeScriptReferences];     //reference to app.d.ts files

    var tsResult = gulp.src(sourceTsFiles)
        .pipe(sourcemaps.init())
        .pipe(tsc(tsconfig));

    tsResult.dts.pipe(gulp.dest(config.tsOutputPath));

    return tsResult.js
        .pipe(sourcemaps.write('.'))
        .pipe(gulp.dest(config.tsOutputPath));
});

gulp.task('append-runner', ['compile-ts'], function () {
    return gulp.src(config.tsOutputPath + "program.js")
        .pipe(insert.append('\n\ndocument.addEventListener("DOMContentLoaded", function(e){require("./Program").main();});'))
        .pipe(gulp.dest(config.tsOutputPath))
});

gulp.task('browserify', ['append-runner'], function () {
    var babelifyStep = babelify.configure({stage: 0});

    var allFiles = glob.sync(config.tsOutputPath + "**/*.js", {ignore: config.tsOutputPath + 'index.js'});
    var bundler = new Browserify({
        entries: allFiles,
        transform: [ babelifyStep ]
    });
    return bundler
        .bundle()
        .pipe(source('program.js'))
        .pipe(gulp.dest(config.compiled));
});

gulp.task('copy-static', ['compile-ts'], function () {
    gulp.src('./out/js/index.js')
        .pipe(babel({stage: 0}))
        .pipe(sourcemaps.write('.'))
        .pipe(gulp.dest(config.compiled));

    return gulp.src(['./src/index.html', './package.json'])
        .pipe(gulp.dest(config.compiled));
});

gulp.task('atom', ['browserify', 'copy-static'], function () {
    return atom({
        srcPath: './out/compile',
        releasePath: './electron/build',
        cachePath: './electron/cache',
        version: 'v0.26.1',
        rebuild: false,
        asar: true,
        platforms: ['win32-ia32']
    });
});

gulp.task('default', ['atom']);
```

Notice the task "default". It is the default task as its name suggest. This task gets executed when running gulp command without any argument. Now in console try this:

```
gulp
```

This should get everything nicely compiled and electron prebuild package downloaded and out application bound with electron. In my case I can get the electron application
at "D:\Projects\Node\fb-messenger\electron\build\v0.26.1\win32-ia32". All it remains to do is double click the electron.exe file there. Go ahead do it!

Well nothing much, you will see a blank electron window:
<img src="/assets/posts/fb-messenger-2/out.png" />

**What!! that's it??**

Yes, thats almost it. But there is one more thing, the "Hello from electron!" message we wrote from program.tsx, where's it? To see that let's open developer tools.
<img src="/assets/posts/fb-messenger-2/3.png" />

<img src="/assets/posts/fb-messenger-2/4.png" />

Yeah! There it is!

**Wait!! but what's that error?**

Oh! don't worry, that error is just saying that it cannot find main.css file we are referencing. If you remember our index.html from previous post:

```html
<link href="./styles/main.css" rel="stylesheet" />
```

Let's fix the error. Add new file named "main.less" in the "src/styles" folder.

```css
body{
  maring:0;
  padding:0;
}
```

Now lets add task to build less file into css.

npm:

```
npm install gulp-less --save-dev
```

require:

```js
less = require('gulp-less'),
```

task:

```js
gulp.task('less', function () {
    return gulp.src(config.source + 'styles/**/*.less')
        .pipe(less())
        .pipe(gulp.dest(config.compiled + '/styles'));
});
```

Change the default task as follows:

```js
gulp.task('default', ['less', 'atom']);
```

Now, run "gulp" command again. Once gulp is done, goto the electron window and refresh application by pressing "ctrl+R". So, that error is gone:

<img src="/assets/posts/fb-messenger-2/5.png" />

**Are we done yet?**

Yes, finally! After this very long list of coding and npm installs we finally have this awesome running program that prints "Hello from electron!"

But there are few more modifications to gulpfile that I did. I have added a task that starts the electron automatically (yay!!), 
and also another watcher task that will watch for file changes and automatically compile (double yay!!). Since this post is already very long I'm not
adding more details for them.

