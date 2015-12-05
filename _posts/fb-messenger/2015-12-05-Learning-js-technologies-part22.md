---
layout: post
title:  "Learning reactjs flux, node, electron ... (Part-22)"
date:   2015-12-05 6:00:00
description: Running unit test inside electron
categories:
- fb-messenger
tags : [fb-messenger, node.js, io.js, es6, npm, typescript, gulp, atom-electron, unit-testing-with-electron]
---
{% include JB/setup %}
{% include fb-messenger/Learning-js-technologies-parts.md %}

#Running unit test inside electron

<p class="first" markdown="1">
    If you are following this series, you may already know that I have been using 
    <a href="https://github.com/tmpvar/jsdom">jsdom</a> for the purpose of mocking DOM. But the experience hasn't 
    been very smooth. Although jsdom itself is quite great project, React doesn't play well with jsdom. It's quite 
    funny since they themselves use jsdom as part of their jest framework (official testing framework from React).
</p>

I had been working around the incompatibilities and quirks between React and jsdom since quite the 
[beginning](https://github.com/facebook/react/issues/4740). Recently when I couldn't write test for one of my 
[feature](https://github.com/nripendra/fb-messenger/issues/17) because jsdom didn't support CustomEvent, I started 
to have serious thought about changing my test approach. I finally had enough when React again started giving 
"dangerouslyReplaceNodeWithMarkup" exception whenever re-rendering got triggered. Basically it worked find on first 
render, but when I simulated some event like click that caused the DOM to change, it threw this exception. Initially 
I was thinking about monkey patching things by avoiding re-rendering, and dividing test into 2-3 tests. With 
combination of these tests I could assert that things would turn out well.

Meanwhile  I began searching if electron can have headless mode. The answer as of now: 
[No Not YET!](https://github.com/atom/electron/issues/228). Second thought was to use 
[PhantomJS](http://phantomjs.org/), but I didn't have really nice experience with PhantomJS when working in past, 
so was reluctantly trying to figure out if there is something that could be done with it. But with every articles I 
came across, it looked like quite a major shift in paradigm from what I had been doing so far.

After my anger for Reactjs - jsdom incompatibility cooled down a bit, I was about to go with initial plan of 
dividing tests so that re-rendering wouldn't have to be triggered. Before I could begin I stumbled upon
[electron launcher for karma](https://github.com/lele85/karma-electron-launcher). Hmm! so I thought I could use 
karma if it would help me to run my test in electron. So, I created a new branch named "karma-electron". Well, I 
installed npm packages, and was trying to get things running but without success. Once again I gave up, and was 
again about to re-organize my tests to not have to re-render. Well luckily I found 
[this article](http://rhysd.hatenablog.com/entry/2015/08/07/181418). Hmm so seems like I can finally run my test in 
electron, and the author did claimed to have managed to get it running under travis! Super!!

I went to the [github repository of Shiba project](https://github.com/rhysd/Shiba), and straight away went to the 
[tests](https://github.com/rhysd/Shiba/tree/master/tests) folder and began copying files to my
[tests](https://github.com/nripendra/fb-messenger/tree/develop/tests) folder. I started the run.js from command 
line: ```node .\tests\run.js```, and tried understanding and fixing errors, resolving package dependencies for like 
next 2-3 hours. Unfortunately Shiba was using mocha framework while I was using jasmine, so I installed mocha + 
chai and got up to the point where test cases were running and failing. Once I reached to that point, where running 
inside electron, now I had to change the code from Shiba to suit my case.

I converted all the mocha related code into jasmine code. My 'runner\index.html' now looked something like this:

```html
<html>
<head>
    <meta charset="utf-8">
    <title>Shiba Test</title>
    <script>
        var path = require('path');
        var Jasmine = require('jasmine');
        var electronRequire = require;
    </script>
</head>
<body>
    <div id="fb-messenger"></div>
    <script>
        var jasmine = new Jasmine();
        jasmine.addSpecFile(path.resolve("./tests/out/tests/specs/login.spec.js"));
        jasmine.execute();
    </script>
</body>
</html>
```

This is the original Shiba runner code:

```html
<html>
<head>
    <meta charset="utf-8">
    <title>Shiba Test</title>
    <link rel="stylesheet" href="./bower_components/mocha/mocha.css" />
</head>
<body>
    <div id="mocha"></div>
    <script src="./bower_components/chai/chai.js"></script>
    <script src="./bower_components/mocha/mocha.js"></script>
    <script>
    var assert = chai.assert;
    </script>
    <script>mocha.setup('bdd')</script>
    <script src="../renderer/index.js"></script>
    <script>
    mocha.run();
    </script>
</body>
</html>
```

The test started to run, but there was no output from test. I did not want to loose the functionality I already 
have. Currently I do get a very nice detailed output from 
[jasmine-spec-reporter](https://github.com/bcaudan/jasmine-spec-reporter), with all meaningful coloring
and symbols for passed/failed tests. It also gives summary of failed tests at the end, and has proper indentation 
based on the nesting level of the test suite.

I started with creating a custom reporter, and tried console.log, but all the output was redirected
to electron's dev console, which would be of no use in travis. I tried using npmlog package as I have known it to
[print things to stdout of the process](https://github.com/Schmavery/facebook-chat-api/issues/103). And with npmlog
it actually started giving some messages on screen. It could be integrated into jasmine as follows.

```html
<script>
  var jasmine = new Jasmine();
  jasmine.addReporter(reporter);
  jasmine.addSpecFile(path.resolve("./tests/out/tests/specs/login.spec.js"));
  jasmine.execute();
</script>
```
I noticed a new problem immediately after being happy for a brief moment, instead of printing messages in nice colors,
it was giving me ansi color code + the message. Now, my next mission was to fix the coloring. After digging a lot 
into the nodejs documentations and a lot of googling and hair pulling, I came up with something  that worked! 
Basically instead of the reporter printing the output to the console, reporter would pass the data to parent 
process and the parent process would then print the message. And yeah! That's it!! There's all the rich colors 
you'd ever want **<span style="color:green">green</span>** and **<span style="color:red">red</span>**.

So, it would be a multiple hops until the things finally gets displayed on screen. The very basic flow would look 
like this:

```js
// inside the reporter which runs inside the renderer process of electron,
// we simply send the message to the browser process using ipc
ipc.send('renderer-print-message', str);

// Inside the browser process of electron (tests/runner/main.js),
// we will send our message to the parent process which spawned
// this electron process (i.e. tests/run.js)
ipc.on('renderer-print-message', function (event, message) {
    // pass the message to run.js which started electron process.
    process.send(message);
});


// Inside the node process that spawns electron process(tests/run.js),
// we do actual printing.
proc.on('message', function (e) {
    // print on the screen.
    console.log(e || "");
});
```
The reporter which is running inside the renderer process of electron, would inform about the message to be 
printed to the browser process through ipc. The browser process it self will do a process.send() to send the 
message back to the parent process which finally will do actual printing to the screen. Phew!! After all these 
trouble I had it working the way I wanted. Unlike original shiba testrunner which simply returned number of failed 
tests, it could now give me details about what is passing/failing.

Finally, now instead of using my custom built reporter I wanted to use
[jasmine-spec-reporter](https://github.com/bcaudan/jasmine-spec-reporter).
Which had all the complex logic for printing, coloring, indenting and summarizing the test results. But difficult 
part was, I couldn't use it "as is", since it directly printed to console.log. And requesting for this feature to 
original author would be a long trip, and its not even sure if my request would be accepted, or by when I'd get 
this feature if accepted. I need something right now!

So, I [forked the project](https://github.com/nripendra/jasmine-spec-reporter) and changed couple of lines. Now, 
instead of doing a hard-coded console.log() it takea a function "consoleWrite", in it's constructor, and uses it 
to print the log message. After these changes to the SpecReporter I could do this:

```html
<script>
  var SpecReporter = require('jasmine-spec-reporter');
  var jasmine = new Jasmine();
  jasmine.addReporter(new SpecReporter({consoleWrite: function(str) {
      ipc.send('renderer-print-message', str);
  }}));
  jasmine.addSpecFile(path.resolve("./tests/out/tests/specs/login.spec.js"));
  jasmine.execute();
</script>
```
And everything was good, with an added bonus! With this setup in place it solve a [problem I had with my previous 
setup](https://github.com/bcaudan/jasmine-spec-reporter/issues/45). Now, all the console.logs inside the renderer 
process would go directly to the electron console, and only the test result was shown on the screen :)

Next thing that needed to be solved was closing window when all the test finished running. For this I made another 
brief change in the jasmine-spec-reporter. With this change in place now my index.html code would look like this:

```html
<script>
    var SpecReporter = require('jasmine-spec-reporter');
    var jasmine = new Jasmine();
    jasmine.addReporter(new SpecReporter({
        consoleWrite: function(str){
            ipc.send('renderer-print-message', str);
        },
        jasmineDone : function(failedSpecs) {
            ipc.send('renderer-test-result', failedSpecs);
        }
    }));
    jasmine.addSpecFile(path.resolve("./tests/out/tests/specs/login.spec.js"));
    jasmine.execute();
</script>
```

And the browser process would respond to it by quitting the application:

```js
var renderer_test_exit_status = 0;
w.on('closed', function () {
    process.exit(renderer_test_exit_status)
});

ipc.on('renderer-test-result', function (event, exit_status) {
    renderer_test_exit_status = exit_status;
    app.quit();
});
```

The idea is that it would quit with exit code 0 (success) if there are no failedSpecs, or else its exit code would 
be number of failed tests.

After this setup worked in command line, now it was finally time to integrate into my test system, i.e. gulp build 
system. In this project, I do run test using following command ```gulp test```, also **test** task is one of the 
things that gets executed on every build. So, my gulp task:

```js

gulp.task('test', ['compile-test'], function (done) {
    process.env.NODE_ENV = 'development';
    global.electronRequire = require;
    var child = require('child_process').fork('./tests/run.js', [], { stdio: [null, null, null, 'ipc'] });

    child.on('exit', function (code) {
        if (code > 0) {
            done('Unit test failed');
        } else {
            done();
        }
     });
});
```

Well nothing much! It just forks the run.js (which in turn will spawn electron process), and waits for it to exit. 
Once the forked process exits then it checks for exit code to decide whether or not this task is successful.

Finally now I have my tests running inside electron environment, which is the target environment where my actual 
application is intended to run. This does give me much more confidence in my tests than just running it in jsdom 
context. With added bonus I'm getting detailed report of my tests in travis. On top of that, there is no noise from 
console.log from my application.

![testoutput.png](/assets/posts/fb-messenger-22/testoutput.png)

Please feel free to take up code and hack it to your content. The codes are here:

- [Test runner](https://github.com/nripendra/fb-messenger/tree/develop/tests)
- [My hacked version of jasmine-spec-reporter](https://github.com/nripendra/jasmine-spec-reporter)

##Limitations

Unlike the original author, I don't have much code in my browser process yet, so I just removed everything related 
to testing browser process. Probably in future if I have to add any logic in the browser process then I'll rework 
on it.


I'm quite happy with the final result! I'm already dreaming to make this a new project and deploy it in npm. 
Probably sometime in near future.