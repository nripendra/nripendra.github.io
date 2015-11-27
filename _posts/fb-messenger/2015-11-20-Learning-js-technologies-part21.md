---
layout: post
title:  "Learning reactjs flux, node, electron ... (Part-21)"
date:   2015-11-27 6:00:00
description: Adding support for receiving emoji and emoticons.
categories:
- fb-messenger
tags : [fb-messenger, node.js, io.js, es6, npm, typescript, gulp, atom-electron, hbox, vbox]
---
{% include JB/setup %}
{% include fb-messenger/Learning-js-technologies-parts.md %}

#The release.

<p class="first" markdown="1">
    Finally I have released the fb-messenger as v0.1.0. Not quite usable at this time since we can just view conversation.
    That too just for the current session, nothing that happened before logging in to the app is showin right now. There are a lot of things remaining
    to accomplish to make it even an usable application, let alone feature rich like the ones from facebook themself.
</p>

#The journey.

It was quite a pain to get it released. First of all I had to setup travsi ci to deploy to github releases. Configuration wasn't much difficult.
But after configuring found a [bug in travis](https://github.com/travis-ci/travis-ci/issues/5145). Finally after the workarround suggested in the issue itself got it working.

Now the next trouble started... Avira was detecting the electron exe file built on travis as a virus! I was quite worried at this point, so tested it using 
[Virustotal](https://www.virustotal.com/). A sigh of relief! it was a false alarm. I then submitted the report to Avira, they have confirmed about the false alarm and have mentioned
that their virus database will be updated.

Then this another trouble followed! The application wasn't working! The console log showed missing package. So, I thought hey lets update to latest version of nodejs hence npm, to 
reflect the build technology of travis. There you go, uninstalled io.js got latest nodejs installed it and fired up my gulp task to build the package. And thus opened the can of worms.
The build was quite complicated since npm has changed how it structures the packages. Rather than hierarchical structure, it has now started following flat structure. Earlier all I had
to do was copy facebook-chat-api to node_modules folder of my released application, now I had to track all the dependencies and copy each of them. I finally came up with a solution...

I did ```npm ls```, which listed all the packages in the tree structure. Then copied it to notepad++, and just kept the hierarchy of facebook-chat-api removing everything else. Then with
the regular expression search and replace feature removed all those lines that showed the tree hierarch. Finally I had the list of desired packages. Now I replaced all "\n\r" characters
with comma ",". With this I opened up dev console in chrome browser and pasted the list of packages enclosed with double code and typed following:

```js
"...list of packages separated by commas...".split(",").sort();
```
This gave me the array of packages names in alphabetical order. And finally used the array in my gulp task as such:

```js
gulp.task('browserify-copy_node_modules', function () {
    var modules = ["ansi", "are-we-there-yet", "asn1", "assert-plus", "assert-plus", "async", "aws-sign2", 
    "bl", "bluebird", "boolbase", "boom", 
    "caseless", "cheerio", "combined-stream", "core-util-is", "cryptiles", "css-select", "css-what", 
    "dashdash", "delayed-stream", "delegates", "dom-serializer", "domelementtype","domhandler", "domutils", 
    "ecc-jsbn", "entities", "extend", "extsprintf", 
    "facebook-chat-api", "fast-download", "forever-agent", "form-data", "form-data-rc3", 
    "gauge", "generate-function", 
    "generate-object-property", 
    "har-validator", "has-unicode", "hawk", "hoek", "htmlparser2", "http-signature", 
    "inherits", "isarray", "is-my-json-valid", "is-property", "is-typedarray", "isstream", 
    "jodid25519", "jsbn", "json-schema", "json-stringify-safe", "jsonpointer", "jsprim", 
    "lodash", "lodash._basetostring", "lodash._createpadding", "lodash.pad", "lodash.padleft", "lodash.padright", "lodash.repeat", 
    "mime-db", "mime-types", 
    "node-uuid", "npmlog", "nth-check", 
    "oauth-sign", 
    "pinkie-promise", "process-nextick-args",
    "qs", 
    "readable-stream", "request", 
    "sntp", "sshpk", "string_decoder", "stringstream", 
    "tough-cookie", "tunnel-agent", "tweetnacl", 
    "util-deprecate", 
    "verror", 
    "xtend"].map(function(x){return './node_modules/' + x + '/**/*'; });
    return gulp.src(modules, { "base" : "." })
               .pipe(gulp.dest('./out/compile/'));
});
```
Hurray! it started working on my machine after that! I pushed to github, tagged it and pushed the tag. Once the application was built and send to github
releases, downloaded the installer and ran the application, and.... it didn't work. Still showing packages missing. So, I added the package name to the
list in gulp file each time and repeated the whole process. Was quite tired after 3 rounds, and on 4th round travis server's IP had exceeded the download limit.
Then another idea shined upon me! I built the installer copied to another machine and tried installing on it. And it worked :(

This Github rate limit was quite disturbing since it meant my release could get stuck on travis. Upon searching found that travis has caching facility too. So,
I enabled caching for this electron cache folder. And waited for couple of hours to get the rate limit reset.

After building it again, the application wasn't working! At this time I was really frustrated! upto a point where I was even thinking to do away with the release, or
even project, suddenly another "IDEA"!! I set asar property of gulp-electron task to false and triggred the travis build by pushing new tag. Again I installed the application
and started it. As expected same package missing exception welcomed me. But this time I just copied the missing node-module to the installed application's node_module folder.
After just 2 packages it started working! Finally I updated the gulp task to include these two packages and triggred travis build. This time it started working. Phew!!

Till date I'm still not sure why when built on my machine it just worked but from travis all these packages was necessary. But anyway I had a workig solution for
automated build and deployment.

#Another can of worm

At arround same time I updated nodejs/npm, I also had idea of updating facebook-chat-api. In the above story I didn't include this story because it would be confusing. Because I
was trying to solve these two problems in parallel. The story begins with this [issue](https://github.com/Schmavery/facebook-chat-api/issues/104). 
On receiving reply from [Avery Morin Schmavery](https://github.com/Schmavery), I decided that waiting for npm release wasn't ideal, I wanted to be on as current code as possible.

So, I forked the original "facebook-chat-api", and added my fork as a submodule to the project. And installed npm package from that local folder. The basic idea is
I will periodically update my fork from upstream.

The trouble almost began immediately, a lot of api surface had changed from what it used to be when I last took the npm package. I had to modify a lot of files to finally get
it to the state from where I updated the package.

#In to the future

I'm currently working on the tasks listed for v0.2.0 release (completed two of them). With this 2nd release I'm thinking this application will be usable enough chat application, 
as it will allow to send message too. Everything after that would be enhancements to make as much friendly as I can.