---
layout: post
title:  "Learning reactjs flux, node, electron ... (Part-11)"
date:   2015-9-19 6:00:00
description: So far the chat interface has been intangible, we have console logs but the front interface itself doesn't do anything at all. Lets change this lets make it display list of our friends. We will start by doing this in the chat component itself and then refactor various functionalities of the chat component into their own component as required.
categories:
- fb-messenger
tags : [fb-messenger, node.js, io.js, es6, npm, typescript, gulp, atom-electron, hbox, vbox]
---
{% include JB/setup %}
{% include fb-messenger/Learning-js-technologies-parts.md %}
<p class="first">
    So far the chat interface has been intangible, we have console logs but the front interface itself doesn't do anything at all. Lets change this
    lets make it display list of our friends. We will start by doing this in the chat component itself and then refactor various functionalities of
    the chat component into their own component as required.
</p>
After looking at the log it is quite clear that the friend list is returned as key value pair of userId and user details. One thing that seems to be 
missing though is the user's online status. It does seem like online status can be updated through the use of presence events, but doesn't look very
promising to me, as it will take sometime to get the list updated, till then we will have to assume all friends offline.


```ts
import * as React from 'react';
import ChatStore from '../stores/chatstore';
import ChatActions from '../actions/chatactions';
import {Hbox, Vbox} from './layout';
import AppStores from '../appstores';
import connectToStore from '../decorators/connectToStores';

export class ChatProps {
    api: any;
    store: ChatStore
}

@connectToStore(['chatStore'])
export default class Chat extends React.Component<ChatProps, any> {
    constructor(props: ChatProps) {
        super();
        this.props = props;
        ChatActions.initApi(this.props.api);
    }

    render() {
        var state = {
            'online': {
                border: '1px solid gray',
                borderLeft: '3px solid green'
            },
            'offline': {
                border: '1px solid gray',
                borderLeft: '3px solid gray'
            }
        };
        var friendList = Object.keys(AppStores.chatStore.friendList || []).map(id => AppStores.chatStore.friendList[id]);
        return (<Hbox>
                  <Vbox>
                  {friendList.map(function(friend) {
                      return (<Hbox>
                                <img src={friend.thumbSrc} style={state[friend.onlineState || 'offline']} />
                                {friend.name}
                          </Hbox>);
                  }) }
                      </Vbox>
                  <Vbox></Vbox>
            </Hbox>);
    }
}
```

Note that not much has changed so far. Only the render method has been modified to show the list of friends from the chat store. Notice that 
before user logs in the App component did serve as the controller component, but after login I'm assigining this role to Chat component. This
may not be the best practise, as I'm fairly new to flux, I'll try to change these codes into what is recommended practise in the industry in 
future.

<aside>
On a side note, vs-code now has support for configuring the bleeding age typescript lib, so I've started using vs-code too. But the support for 
latest typescript features including tsx still seems to be premature. Hence I'm still prefering atom.io as my editor (I've moved away from 
webstorm too). I'm hopeful that in comming versions vs-code will be more stablized. Another thing I'm waiting is typescript itself, a lot of 
latest features like async/await, generators etc doesn't get compiled to Es5. Hence we are having to recompile the js generated by ts using 
babel. I mean I'm okay with this too, but the problem is with the sourcemap. I'd like source map to dirrectly point to my original ts code. 
Currently source map shows intermediate js code that is the output of ts compiler and input to babel. If someone could point a way to generate
source map that directly points to ts source then I'm pretty happy with this setup too.
</aside>