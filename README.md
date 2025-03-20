I wanted to create a mobile app off a hobby project I was doing in python that originally was intended to iterate the code as I was learning more of the language. I had been listening to a few episodes of the real python podcast and had heard the term “vibe coding” mentioned. 

I wasn’t aware that I was doing that for a while now (I didn’t know there was a term for it). Coming from a QA centric perspective most automation tools were some sort of distilled version of a language. (at least what I had been using) Unless there was something the framework couldn’t do out of the box, it usually wasn’t necessary to dig into depths of the native language to create what you needed, but it did happen from time to time.

I decided to ride the vibe and see what I could do with moving a simple python project that calculated macros based off a defined goal weight, into a full fledged mobile app, all using Gemini 2.0 Pro experimental as my primary AI uber if you will.

My first instinct was a simple prompt:
“ I'd like to make an iOS and android app from this repo https://github.com/MatthewEngman/macro_calculator”

What’s interesting about this first part is that there are no explicit inputs other than a goal weight in the python code. Gemini is hallucinating (I’m guessing) or implying that this is the goal of the code? I’m not sure. I at least had intended in my mind that I would one day add these other inputs though. 

After that it gave me some Language and Framework choices with options like rewriting it into native code (Swift/Kotlin), Cross-platform using React, Flutter, Kivy, BeeWare, and Hybrid options. Staying with the Google theme and its description of Flutter: “Flutter (Dart): Developed by Google, excellent performance, growing community, beautiful UI.” I prompted it to create the steps using only Flutter.

The steps for the initial setup of Flutter using VS Code (that was recommended) were straightforward and took me a little time to setup and configure it properly (needing to download and install some dependencies). 

I followed the project creation steps line by line learning a little dart along the way with its explanation of project structure, flutter widgets, and implemented the sample code it generated into the specified files, with only one file that I needed to create with manual intervention. It also gave me some tips on adding input validation that was deemed important, but not implemented in the sample code. Other enhancements to consider like Improved UI, Data persistence, Unit conversion, Customizable macro ratios, History tracking, Charts and Graphs, and dark mode support. Also Testing considerations and deployment instructions. This gave me a MVP base product that I could use those suggestions later to refactor and use as learning opportunities.

Spending some time reviewing and trying to understand the new language I noticed that where it was building the input form that only one input was actually implemented and there was a commented line about implementing the rest of the inputs


Interestingly enough, even though it initially identified multiple inputs in the original python code (which it didn’t) it gave me sample code with only the one input the python code had, weight. 

I prompted it then to finish the code for the form input and it actually refactored it not with all the additional inputs it actually implemented the input validation too, bonus!

Feeling pretty confident at this point I think I was ready to run it, and after failing to configure any emulators for VS Code and just trying to run it in a browser, I decided to just swap over to Android Studio where I had some familiarity with running emulators since this was a mobile app after all.

At this point I decided to continue using Gemini in Android studio since it was easier to use the integrated IDE version now that I had my MVP code. One little issue I was working through when trying to build was easily resolved with Gemini, and using some QA intuition of “Hey what’s this button do” referring to the Flutter attach button for the emulator and viola! A working “beautiful UI” of my macro calculator!



This entire process took me about 2.5 hours. It does have bugs, it definitely needs some polish, and it’s definitely not beautiful, but it’s my little frankenstein project that I look forward to making better.

