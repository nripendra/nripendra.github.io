---
layout: post
title:  "Introducing xGherkin.net"
date:   2014-11-23 7:35:00
description: Test Driven Development (TDD) is the current norm in industry. It refers to design of software product based on series of Tests. Tests in TDD are not essentially unit tests, but unit test frameworks and concepts are primarily in use.
categories:
- xGherkin.net
tags : [bdd, xspec, xgherkin.net]  
---
{% include JB/setup %}

Test Driven Development (TDD) is the current norm in industry. It refers to design of software product based 
on series of Tests. Tests in TDD are not essentially unit tests, but unit test frameworks and concepts are 
primarily in use. The **Red-Green-Refactor** flow is at the heart of TDD, it basically means write a failing 
test first (which test tools generally denotes in Red), then make it pass (Green) and then refactor the code. 
Which implies that we should write  test even before writing actual code. Also a rule of thumb for compiled 
language like c# would be to consider compilation failures as a Red.

## What is BDD?

BDD is new style of doing TDD, it maintains same Red-Green-Refactor flow and can be done with same frameworks 
and tools used for TDD. The difference being its ultimate focus on human beings, rather than machine. BDD 
encourages writing test such that it is easy to read for humans. This human focus does turn out to be very 
important aspect of BDD, so much so that people like me who are wary of writting Tests can now turn their 
mind towards writing tests.

Writing tests in BDD mostly seems like explaining what software should do in very human language, that's 
exactly the intended purpose of TDD! But "T" in TDD didn't do it any justice. Programmers who were already 
writing unit tests, integration tests etc continued on their path, and new entrants to TDD domain were rather 
perplexed at the complexity. **How would I even write test without any code to 'test'?** This was exactly my 
question for quite some 'years' when I first got introduced to TDD! Finally figured out  after going throug 
a lots of article and trying things myself. But still today when I know at least basics of how to to TDD, I 
still write code first and then think about testing it.

Enter BDD, it is something that we as a programmer always do, albeit in our minds. Before writing any code we
 try to envision what functions should be there? what it should do? and what it shouldn't etc. Now BDD
encourages joting those thoughts into a program instead of just forming ideas in mind. Once we think in 
terms of behaviour the the flow becomes quite natural, we just specify what our program should do or shouldn't
 do and then write them down in form of code. Basically as we already have some idea in mind about how we will 
approach a problem, writting specification wouldn't be so difficult.

## What is Gherkin?

Gherkin is a DSL (Domain Specific Language) geared towards writing software specification. It is very similar 
to our natural language like english, making it quite friendly for non-programmers to approach. Although 
Gherkin looks like english, it follow certain pattern and syntax, such that it is possible to generate some 
code based on the Gherkin itself (Cucumber and Specflow does this). Gherkin has a very powerful set of 
keywords that can be used to describe most of the software behaviour (if not all). Some of the gherkin 
keywords include (Feature, Scenario, Background, Example, Given, When, Then, And, But etc).

Lets have a look at an example. Lets say we want to describe a software feature for login. Let's first define in 
simple English.

* User must be able to login, giving their credentials (username and password).
    * If wrong username is provided then error message must be shown.
    * If wrong password is provided then error message must be shown.
    * If both username and password is correct then they must be authenticated.

How is it done in gherkin?

```gherkin
Feature: User login
  Provided that a person's username and password is available in the system.
  The person should be able to login providing correct username and password.
  If wrong username or password is provided then that pershon shouldn't be allowed to login.

Background:
  Given that following users exist in the system:
     |username     |password|
     ------------------------
     |bob@gmail.com|   pass1|
     |sam@gmail.com|   pass2|

Scenario : Successfull login
    Given that I set username to 'bob@gmail.com' and password to 'pass1'
    When I try to login
    Then I should be able to login.

Scenario: Unsuccessful login due to wrong password
    Given that I set username to 'bob@gmail.com' and password to 'xyz'
    When I try to login
    Then I should not be able to login.

Scenario: Unsuccessful login due to wrong username
    Given that I set username to 'abc@gmail.com' and password to 'pass1'
    When I try to login
    Then I should not be able to login.            
```

Well quite verbose but very specific, this is what I'd prefer to call 'Example driven development' 
:stuck_out_tongue_closed_eyes:. And this is something we as a developer have been doing for very long. 
When ever I discuss with my colleagues about certain features that needs to be implemented, but we 
are having difficulty wrapping our heads arround, we fallback for an example "for example, let's say..."

Now we come to the main part "xgherkin.net".

# Tell me about xgherkin.net already!

Thanks for your patience upto now. Let me point to the [source](https://github.com/nripendra/xGherkin.net) 
directly, go ahead have a look, I'll be waiting... :smiley:

Ok, for all lazy people who didn't bother to click the link, let me quote

> xGherkin.net is a xspec flavored BDD framework, which tries to strike balance between xspec and xbehave 
nature. The basic goal of this project is to remain close to plain gherkin as much as feasible given the 
language constrain (given that we are using c# to write gherkin).

So, basically xGherkin.net is an extension over xunit.net testing framework, which tries to mimic plain 
gherkin as nearly as possible in c#. 

Generally xbehave flavour is used for writing 
acceptance test being more friendly towards business people, while xspec is more prefered for more core 
unit/integration test works. It's not that xbehave cannot be used for unit test or integration and xspec 
for acceptance test, but this has been the perceived industry standard since BDD was coined.

Being a code person I like xspec more, but most of xspec framework out there doesn't support gherkin, or 
supports only a limited gherkin namely Given-When-Then flow, that too not in strict sense. I like Gherkin as 
a language for software specification. It is short conscise and less ambiguious, while suits for many 
software specification scenario. It even suits case when requirement is vague, remember 'Example driven 
development'? So, here comes [xGherkin.net](https://github.com/nripendra/xGherkin.net).

This post is already getting very long, so with brief introduction to xgherkin.net, I'll plan other posts to 
talk more about it, mostly about its design decissions and internals.
