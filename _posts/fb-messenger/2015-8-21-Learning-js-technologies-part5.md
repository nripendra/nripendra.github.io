---
layout: post
title:  "Learning reactjs flux, node, electron ... (Part-5)"
date:   2015-8-21 6:00:00
description: A series titled "Learning reactjs flux, node, electron ...", with four posts already published nothing much has been done yet about ReactJs or flux. That's abscurd right? Yes, I also can feel that. Now is the time to change this.
categories:
- fb-messenger
tags : [fb-messenger, node.js, io.js, es6, npm, typescript, gulp, atom-electron.]  
---
{% include JB/setup %}

A series titled "Learning reactjs flux, node, electron ...", with four posts already published nothing much has been done yet about ReactJs or flux. That's absurd right? Yes,
I too am with you. Now is the time to do some justice to the title. So, lets get started with ReactJs.

Well this isn't supposed to be a tutorial about ReactJs, so if you are looking for tutorial about how to get started or working philosophy of reactjs, you may want to visit some
other blog. In this series we will take more practical stance. In my opinion this approach would be helpful for someone who has gone through such tutorials and knows a thing or 
two about react already, but want to know what all those theories means when writing down code. I'll try to explain some of my design choice though. Probably also share links to 
blogs based on which I make some decission. I may be mis-understanding the intension of original author, if anyone points out my mistakes I would be really grateful.

So, let's being with installing react first.

```
npm install react --save-dev
```

Since we are using typescript, we will do one more npm install:

```
npm install tsd -g
```

"tsd" is a command line tool that installs typescript defination for various js libraries. Typescript defination file ending with .d.ts extension is similar concept to header 
file in 'c'. They are used by typescript compiler to understand the usage of various classes and functions. Once we have tsd installed, we can now install the react defination.

```
tsd install react
```

It will be installed insde fb-messenger/tools/typings/react folder. If you remember our first post in series, we have configured the tsd.json file to set ./tools/typings as the
path for definations.

Lets add a file named "App.tsx" in fb-messenger/src/components folder.

```ts
import * as React from 'react';

export default class App extends React.Component<any, any> {
  render(){
    return (<span>Hello from React!!</span>);
  }
}
```
Now modify the content of program.tsx (we have already created this file in previous series) as follows:

```ts
import * as React from 'react';
import App from './components/app';

export default class Program {
    static main() {
        React.render(<App />, document.body);
    }
}
```

In terminal window execute the command "gulp", you should see something like this:
<img src="/assets/posts/fb-messenger-5/1.png" alt="Hello from React window" />
(note that in previous series I mentioned that I have added few more task to run electron automatically)

Congratulations!! After all these setup process finally something tangible, instead of something printing in developer console we have something that prints in the visible area.