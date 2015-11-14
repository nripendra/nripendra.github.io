---
layout: post
title:  "Learning reactjs flux, node, electron ... (Part-18)"
date:   2015-11-14 6:00:00
description: As of now the chat thread does get updated when we send or receive message, but we need to scroll to bottom to see the latest message. In this post we will make the chat thread scroll to end automatically.
categories:
- fb-messenger
tags : [fb-messenger, node.js, io.js, es6, npm, typescript, gulp, atom-electron, hbox, vbox]
---
{% include JB/setup %}
{% include fb-messenger/Learning-js-technologies-parts.md %}
<p class="first" markdown="1" >
    As of now the chat thread does get updated when we send or receive message, but we need to scroll to bottom to see the latest message. In this post we will make the chat thread scroll to end automatically. I'm feeling
    lucky as I found a <a href="http://blog.vjeux.com/2013/javascript/scroll-position-with-react.html">blog entry</a> explaining exactly how to do it...
</p>

For our purpose, we will add a private member in "ConversationHistory" class named "shouldScrollBottom". This flag is used to determine if we should automatically scroll to bottom or not. In case user is scrolling upwards to
view old messages it will be rather irritating to scroll them down. And in constructor we set the default value to false (which I don't think is mandatory).

```ts
private shouldScrollBottom: boolean;
constructor(props: ConversationHistoryProps){
    super();
    this.props = props;
    this.shouldScrollBottom = false;
}
```

Now we will tap into two of the react lifecycle methods:

- componentWillUpdate and
- componentDidUpdate

```ts
componentWillUpdate() {
    var currentNode = ReactDom.findDOMNode(this) as any;
    this.shouldScrollBottom = (currentNode.scrollTop + currentNode.clientHeight) >= currentNode.scrollHeight;
}
     
componentDidUpdate() {
    if (this.shouldScrollBottom) {
        var node = ReactDom.findDOMNode(this);
        node.scrollTop = node.scrollHeight
    }
}
```
Yup that's it!! We are done!! If you compare the code from the original code from which I'm refering then you'll find
subtle differences, like use of clientHeight instead of offsetHeight, and ">=" instead of "===". Now the final
code for "conversation-history.tsx" looks like this:

```ts
iimport * as React from 'react';
import * as ReactDom from 'react-dom';

import {Hbox, Vbox} from './layout';
import MessageItem from './message-item';

const Cards = require('material-ui/lib/card');
const Card = Cards.Card;
const CardHeader = Cards.CardHeader;
const CardActions = Cards.CardActions;
const CardText = Cards.CardText;
const CardMedia = Cards.CardMedia;

export class ConversationHistoryProps {
    messages: any;
    currentFriend: any;
	currentUser: any;
}

export default class ConversationHistory extends React.Component<ConversationHistoryProps, any> {
    private shouldScrollBottom: boolean;
    constructor(props: ConversationHistoryProps){
        super();
        this.props = props;
        this.shouldScrollBottom = false;
    }
    
    //@ref: http://blog.vjeux.com/2013/javascript/scroll-position-with-react.html
    componentWillUpdate() {
        var currentNode = ReactDom.findDOMNode(this) as any;
        this.shouldScrollBottom = (currentNode.scrollTop + currentNode.clientHeight) >= currentNode.scrollHeight;
    }
     
    componentDidUpdate() {
        if (this.shouldScrollBottom) {
            var node = ReactDom.findDOMNode(this);
            node.scrollTop = node.scrollHeight
        }
    }
    
    render() {
        var styles = {
            messageListScrollPane: {
                padding: '0 1.5em', 
                overflowX:'hidden',
                overflowY:'auto',
                height:'calc(100vh - 150px)', 
                maxHeight:'calc(100vh - 150px)',
                borderTop:'1px solid #ccc'
            },
            messageList: {
                minHeight: 'calc(100vh - 155px)',
                justifyContent: 'flex-end'
            }
        };
        
        return (<CardText style={styles.messageListScrollPane}>
                    <Vbox style={styles.messageList}>{this.renderMessages()}</Vbox>
                </CardText>);
    }
    
    renderMessages(){
        var messages = this.props.messages;
        return messages.map((message: any) => this.renderMessageItem(message));
    }
    
    renderMessageItem(message: any) {
        var currentFriend = this.props.currentFriend;
        var currentUser = this.props.currentUser;
        return (<MessageItem message={message} currentUser={currentUser} currentFriend={currentFriend} />);
    }
}
```
And finally the link to diff, goes [here](https://github.com/nripendra/fb-messenger/commit/fb8248cd844ae5e3c8a25bbadba958edbf0fcf11).