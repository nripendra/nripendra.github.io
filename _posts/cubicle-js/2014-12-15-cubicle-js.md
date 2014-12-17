---
layout: post
title:  "Cubicle.js"
date:   2014-12-16 6:00:00
description: Cubical.Js is a small light-weight javascript library for defining modular components. Released under MIT license, it is my yet another opensource project that I published this year. This year I'm quite happy to be able to release couple of my projects into opensource world. Cubicle.js is one of such projects. Many times when working on larger projects we need a way to organize our javascript codes into multiple files/classes/modules. In past I normally used to create javascript classes, either using some sort of frameworks or using vanilla-js. No matter what, I would end up with a lot of classes that clutter up the global namespace.
categories:
- Cubicle-js
tags : [Cubicle-js, javascript, modules]  
---
{% include JB/setup %}

[Cubical.Js](https://github.com/nripendra/Cubicle.js) is a small light-weight javascript library for defining modular components. Released under [MIT](https://github.com/nripendra/Cubicle.js/blob/master/LICENSE) license,
it is my yet another opensource project that I published this year. This year I'm quite happy to be able to release 
couple of my projects into opensource world. Cubicle.js is one of such projects. Many times when working on larger 
projects we need a way to organize our javascript codes into multiple files/classes/modules. In past I normally used 
to create javascript classes, either using some sort of frameworks or using vanilla-js. No matter what, I would end up 
with a lot of classes that clutter up the global namespace.

One of my project used [requirejs](http://requirejs.org/) framework which is quite nice framework that loads desired modules asynchronously at the run
time. But whole loading javascript asynchronously didn't fit well with this particular project, where javascript was
spread across a lot of pages. Having to require jquery each time just to use some "$" magic was also not very comfy. We couldn't help much as this project
was a jumbled mess of CMS and dynamic server-side code. We decided to remove requirejs. When I began with refactoring, I got into a situation, a
lot of our code was defined as requirejs [modules](http://requirejs.org/docs/api.html#define). I didn't wanted to
move away from this approach, so I created my own "define" function. It worked very similar to requirejs's "define". But unlike requirejs, 
it was fully synchronous. Hence we had to properly bundle each module in correct sequence.

Need less to say I was quite happy with what the define function did. I could move all 74 requirejs modules in couple
of hours which, I was expecting to take at least couple of weeks, if I had to entirely create separate vanilla js classes
for each modules.

#Time to open it up

You can get the source for cubicle.js [here](https://github.com/nripendra/Cubicle.js) at github. Although the function it self is quite small one, and doesn't have a lot of fancy magic going on. It seems to be very helpful 
in organizing javascript code, breaking them into small modules that work together to achieve higher goals. So, I decided 
to open the source of this function.

My first instinct was to publish the code as it is, without any modification. But after some consideration, I decided that having
a function named "define" in global namespace was not right approach, how much ever I liked it. At least requirejs has already reserved this 
function name. Creating another function with same name would make these two library mutually exclusive, which shouldn't be the case. 
So, I began to hunt for a name. Decided to rename function to "module", but there were couple of frameworks that already
used that name. After toying with couple of ideas, I did settle down for the name "cubicle".

It wasn't random that I settled down for the name "cubicle". Cubicles are popular structure used to partition offices, allowing
people to work together while providing certain amount of privacy to the worker. Cubical.js does the same, it partitions our
js code into small sections, and allows modules to work in certain level of isolation, while still being able to work with
each other when necessary.

#Save global namespace

The very important principle that cubicle.js is based upon is "Don't clutter global namespace". So, if you follow proper programming 
rules of javascript like using "var" keywords, then each cubicle becomes a black box which offers a set of apis that can be accessed 
only inside other cubicles. However at some point we'll need to provide something in global namespace to serve as an entry point for
the programmers to code against. "cubicle" function stays in the global namespace.

#Show me

Ok enough of talks, lets see how it works in action. First include cubicle.js in your html. You can do it by downloading the js from github, or hot link it from rawgit cdn like this:

```html
<script type="application/javascript" src="https://cdn.rawgit.com/nripendra/Cubicle.js/v0.1.0/Cubicle.js"></script>
```

Now you can define cubicle as such:

```javascript
cubicle(function(invite, announce){

});
```
So, above code defines a simple cubicle that does nothing. Cubicle can be thought as a scope inside function that gives context to all
the related variables and functions. Important thing to notice here is "invite" and "announce" parameters. What are these? you say. These
are functions. As already mentioned the principle on which Cubicle.js has its foundation is the idea to minimize variables/functions in the 
global namespace as much as possible. So, we don't provide global invite and announce functions. Instead we pass them as parameter to the cubicle
function. What does these do? Names themselves are quite clear, "invite" function invites worker in another cubicle, and using "announce" 
function, a worker in one cubicle provides a way for other cubicles to invite it. What? Where did worker came from? Well, as I named the function
cubicle, I decided to name the module that cubicle actually envelopes as "worker". Don't be confused with Web-Workers of HTML5. Here comes worker:

```javascript
cubicle(function(invite, announce){
    return {
        sayHi: function(){
            alert("Hi!");
        }
    };
});
```
So, this cubicle has a worker that provides a function named "sayHi", which when called will alert "Hi!". Now, problem is how should I even be able to
use this worker at all? We don't have a reference to this worker through which we could call it's sayHi method. That's where announce function comes in.
"announce" function basically allows worker to advertise itself.

```javascript
cubicle(function(invite, announce){
    return announce("worker1", {
        sayHi: function(){
            alert("Hi!");
        }
    });
});
```

Now, we have registered the previous worker under the name "worker1", but there is still no direct way to gain access to the worker in cubicle. It can be
done inside another cubicle only! like this:

```javascript
cubicle(function(invite, announce){
    
    var worker1 = invite("worker1");
    
    return {
        init: function(){
            worker1.sayHi();
        }
    };
});
```
Here we are creating another cubicle that uses worker1 annouced in previous cubicle.

Hey! Where did that "init" function come from? Well, it can be thought of as a constructor 
for a worker. Any worker can have a speciall function named "init" that will be called first time
cubicle is created.

#Global worker

Yes, it is entirely possible to create a global woker! just pass "true" as the last parameter of the "announce" function. Lets
take same example above.

```javascript
cubicle(function(invite, announce){
    return announce("worker1", {
        sayHi: function(){
            alert("Hi!");
        }
    }, true);
});
```
Now, worker1 is available in global namespace, which means you can simply do this:

```javascript
worker1.sayHi();
```

Without creating another cubicle, as there is no need to invite this worker. 

Caution!! use this technique carefully. Official guideline would be to avoid this type of coding
as far as possible and try to follow sandboxed worker approach.

#What are the benifits?

The idea is not very new, it is already common in js world to use this type so techniques for modular
programming, and uncluttered global namespace. Cubicle.Js just tries to give a named library for a 
pattern that everyone is reinventing. If it isn't already clear yet:

* Divides javascript code into smaller modules.
* Keeps global namespace clean.
* Small in size.
* No dependency.
* Should work well with any other library.

#Future?

Well for immediate future I have only one idea in mind, i.e. to support "Promise" objects so that the
worker can it self be initiated late. Should be helpful for situations where worker depends upon some
ajax calls to be fulfilled first, or some event like document-ready to be fired first. I'll keep improving
as new ideas come across my mind while using it in other projects. Or, if someone requests for some feature,
I can consider adding the feature depending upon the complexity and my availability.

