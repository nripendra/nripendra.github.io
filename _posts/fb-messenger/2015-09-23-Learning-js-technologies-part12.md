---
layout: post
title:  "Learning reactjs flux, node, electron ... (Part-12)"
date:   2015-9-23 6:00:00
description: In this post we will divide the chat component, abstracting the task of listing friends to a separate component. And we will also add some styling to the component. Let's name the component that lists friends as "FriendList".
categories:
- fb-messenger
tags : [fb-messenger, node.js, io.js, es6, npm, typescript, gulp, atom-electron, hbox, vbox]
---
{% include JB/setup %}
{% include fb-messenger/Learning-js-technologies-parts.md %}
<p class="first">
    In this post we will divide the chat component, abstracting the task of listing friends to a separate component. And we will also add some
    styling to the component. Let's name the component that lists friends as "FriendList".
</p>
To get started we will add a file named "friendlist.tsx" in src/components folder.


```ts
import * as React from 'react';
import {Hbox, Vbox} from './layout';

export class FriendListProps {
    friendList: { [id: string] : any; } = {};//Dictionary<string, any>;
}

export default class FriendList extends React.Component<FriendListProps, any> {
    constructor(props: FriendListProps) {
        super();
        this.props = props;
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
        
        var friendlistStyle = {
            'overflow':'auto',
            'maxHeight':'calc(100vh - 8px)'
        };
        
        var friendList = Object.keys(this.props.friendList || []).map(id => this.props.friendList[id]);
        return (<div style={friendlistStyle}>
                  {friendList.map(function(friend) {
                      return (<Hbox>
                                <img src={friend.thumbSrc} style={state[friend.onlineState || 'offline']} />
                                {friend.name}
                          </Hbox>);
                  }) }
                  </div>);
    }
}
```

Hmm... nothing much! Just copied the section that rendered friend list in the chat component, with some extra styling. This styling will be 
responsible for making the friend list section scrollable, also the section will fit to the viewport height (note 100vh). With these change
now chat component looks like this:

```ts
import * as React from 'react';
import ChatStore from '../stores/chatstore';
import ChatActions from '../actions/chatactions';
import {Hbox, Vbox} from './layout';
import AppStores from '../appstores';
import connectToStore from '../decorators/connectToStores';
import FriendList from './friendlist';

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
        var friendList = AppStores.chatStore.friendList;
        return (<Hbox>
                  <Vbox>
                    <FriendList friendList={friendList} />
                  </Vbox>
                  <Vbox></Vbox>
                </Hbox>);
    }
}
```

Well it does look cleaner!! This change actually showed up a small bug in chatstore.ts file. Now, instead of:

```ts
friendList: Array<any>;
```
I'm using:

```ts
friendList: { [id: string] : any; };//Dictionary<string, any>;
```
Since, friendList as returned by facebook-chat-api is a dictionary not array.