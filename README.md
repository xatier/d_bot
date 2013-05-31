d_bot
======================
My [freenode](http://webchat.freenode.net/) IRC bot

Usage
------
Just run the Perl script

### Requirement ###
    Perl 5.014
    IO::Socket
    XML::Feed
    WWW::Shorten::TinyURL
    Digest::MD5
    WWW::Mechanize


[ydict](https://code.google.com/p/ydict/) dictionary tools

### RSS ###
the bot can fetch RSS subscriptions and post on IRC channel

you can modify these part of code for other RSS

    # rss subscriptions
    my @urls = (
        "http://feeds2.feedburner.com/solidot",
        "http://www.36kr.com/feed",
        "http://pansci.tw/feed",
        "http://feeds.feedburner.com/thehackersnews",
        "http://feeds2.feedburner.com/thenextweb",
        "http://blog.gslin.org/feed",
        "http://feeds.feedburner.com/xxddite",
        "http://xdite-smalltalk.tumblr.com/rss",
        "https://www.linux.com/rss/feeds.php",
        "http://coolshell.cn/feed",
    );

Screenshot
--------
![Imgur](http://i.imgur.com/pWML48q.png)



Licensed
----------
Licensed under the [GPL license][GPL].

[ydict](https://code.google.com/p/ydict/) is under GPLv3

[GPL]: http://www.gnu.org/licenses/gpl.html
