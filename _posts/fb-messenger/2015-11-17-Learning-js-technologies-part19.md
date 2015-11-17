---
layout: post
title:  "Learning reactjs flux, node, electron ... (Part-19)"
date:   2015-11-17 6:00:00
description: A lot of things has been changed since the last post. Few more features has been added into the application, new icon has been created, started working with inno-setup to create setup files, changed from gulp-atom to gulp-electron for packaging the application with electron shell...
categories:
- fb-messenger
tags : [fb-messenger, node.js, io.js, es6, npm, typescript, gulp, atom-electron, hbox, vbox]
---
{% include JB/setup %}
{% include fb-messenger/Learning-js-technologies-parts.md %}
<p class="first" markdown="1">
    A lot of things has been changed since the last post. Few more features has been added into the application, new icon has been created,
    started working with inno-setup to create setup files, integrated into [travis-ci](https://travis-ci.org/nripendra/fb-messenger/)
    Changed from gulp-atom to gulp-electron for packaging the application with electron shell...
</p>

Instead of trello I've decided to use [waffle.io](https://waffle.io/nripendra/fb-messenger/), since it gives board view while making it easy to track issues in github.
Trying to get more formalized with my approach. I haved divided issues into milestones, and now planning to follow proper git-flow for version control, and semver for 
versioning application.

Will discuss about most of these in this and future posts. Let's continue with one additional feature added to the application. Now the application is able to receive
stickers, although animated stickers are still not supported. The change itself was quite simple:

In message-item.tsx, change the render method of **MessageContent** class as follows:

```ts
render() {
		if((this.props.message.attachments || []).length == 0) {
			let justify = {'textAlign':'justify'};
			return (<div className={this.props.className} style={justify}>{this.props.message.body}</div>);
		} else {
			return (<div>
				{this.props.message.attachments.map((attachment:any) => {
					if(attachment.type == "sticker") {
						return (<img src={attachment.url} height={attachment.height} width={attachment.width} />);	
					}
					//empty div for now..
					return <div />
				})}
			</div>);
		}
	}
```

That's it!!

The full file looks like this:

```ts
import * as React from 'react';

import {Hbox, Vbox} from './layout';

const Avatar = require('material-ui/lib/avatar');

export class MessageItemProps {
    message: any;
    currentFriend: any;
	currentUser: any;
}

export class MessageContentProps {
	message: any;
	className: string;
}

export class MessageContent extends React.Component<MessageContentProps, any> {
	constructor(props: MessageContentProps) {
        super();
        this.props = props;
    }
	
	render() {
		if((this.props.message.attachments || []).length == 0) {
			let justify = {'textAlign':'justify'};
			return (<div className={this.props.className} style={justify}>{this.props.message.body}</div>);
		} else {
			return (<div>
				{this.props.message.attachments.map((attachment:any) => {
					if(attachment.type == "sticker") {
						return (<img src={attachment.url} height={attachment.height} width={attachment.width} />);	
					}
					//empty div for now..
					return <div />
				})}
			</div>);
		}
	}
}

export default class MessageItem extends React.Component<MessageItemProps, any> {
    constructor(props: MessageItemProps) {
        super();
        this.props = props;
    }

    render() {
        var currentFriend = this.props.currentFriend;
        var currentUser = this.props.currentUser;
        var message = this.props.message;
        
		var threadID = (message.senderID || "").toString();
		var leftAvatar:any = null;
		var rightAvatar:any = null;
		var rightAvatarStyle = {'marginLeft':'1.2em', 'marginRight':'-5px'};
		var leftAvatarStyle = {'marginRight':'1.2em', 'marginLeft':'-5px'};
		var className = '';
		var justifyContent = '';
		
		if(threadID == currentUser.id) {
			className = 'callout right';
			justifyContent = 'flex-end';
			rightAvatar = <div style={rightAvatarStyle}><Avatar size={32} src={currentUser.thumbSrc} /></div>;
		} else {
			className = 'callout left';
			justifyContent = 'flex-start';
			leftAvatar = <div style={leftAvatarStyle}><Avatar size={32} src={currentFriend.thumbSrc} /></div>;
		}
		
		return (<Hbox style={{'justifyContent':justifyContent}}>
					{leftAvatar}
					<MessageContent className={className} message={message}  />
					{rightAvatar}
				</Hbox>);
    }
}
```

#Travis-ci

Travis ci allows continious integration, meaning it continiously builds the code that is pushed to github and provides feed back whether the pushed code was
good or not. It was quite a breedge to setup travis, all I had to do was login into travis using my github credential, and authorize travis to get my
repositories. Then I setup fb-messenger repo in travis.

For controlling ci, travis provides us facility to add travis configuration in the git repository it self. The name of travis configuration file must be
'.travis.yml'.

My travis.yml looks like this:

```yaml
language: node_js
before_script:
  - npm install -g gulp
node_js:
  - "iojs"
script:
  - gulp build
```

Quite simple! All it says is our project is a nodejs project, and nodejs version we are using is io.js. The script to build the project is gulp build, and before
the build script is executed, execute npm install -g gulp.


<h2>Innosetup</h2>

One of the promient feature in windows application distribution is the installer. Installer application helps to bundle the application and setup all the desired
artifacts in the end user's machine so that the application can function smoothly. There are many ways to build installer for windows the major options are:

- wix
- innosetup
- nsis etc.

Well I cannot talk about nsis, but wix was quite pain when I tried it the last time. In comparision to wix innosetup has been quite a relief. It is very easy to get
started with, and provides so much programatic control without going through much hoops, that almost anything becomes possible.

To work with setup, I have created separate branch named "[innosetup](https://github.com/nripendra/fb-messenger/tree/innosetup)".

#Icon


To create the icon I just merged two images:

- [![Fb](https://cdn2.iconfinder.com/data/icons/neon-line-social-circles/100/Neon_Line_Social_Circles_50Icon_10px_grid-13-256.png)](https://www.iconfinder.com/icons/657794/chat_circles_facebook_line_neon_share_social_icon#size=256)
- [![chat](https://cdn0.iconfinder.com/data/icons/kameleon-free-pack-rounded/110/Chat-2-128.png)](https://www.iconfinder.com/icons/379512/2_chat_icon#size=128)

And the final result:

[![Fb-messenger](https://cloud.githubusercontent.com/assets/1594619/11169678/693dda52-8be6-11e5-9289-a0f144817188.png)](https://github.com/nripendra/fb-messenger/issues/31)

#Deployment

I'm planning to use travis-ci's deploy feature, in combination with github's releases feature to deploy the application.