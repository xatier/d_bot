#!/usr/bin/perl

###############################################
# Reference: http://oreilly.com/pub/h/1964    #
# modified by xatier                          #
###############################################

use 5.014;
use IO::Socket;
use XML::Feed;
use WWW::Shorten::TinyURL;
use Digest::MD5;
use WWW::Mechanize;
no warnings 'utf8';

# no buffering
$|++;


# configuration
my $server = "irc.freenode.net";
my $nick = "";
my $login = "";
my $channel = "#channel";
my $password = "password";


# color codes from IRC::Utils
use constant {
    # cancel all formatting and colors
    NORMAL      => "\x0f",

    # formatting
    BOLD        => "\x02",
    UNDERLINE   => "\x1f",
    REVERSE     => "\x16",
    ITALIC      => "\x1d",
    FIXED       => "\x11",
    BLINK       => "\x06",

    # mIRC colors
    WHITE       => "\x0300",
    BLACK       => "\x0301",
    BLUE        => "\x0302",
    GREEN       => "\x0303",
    RED         => "\x0304",
    BROWN       => "\x0305",
    PURPLE      => "\x0306",
    ORANGE      => "\x0307",
    YELLOW      => "\x0308",
    LIGHT_GREEN => "\x0309",
    TEAL        => "\x0310",
    LIGHT_CYAN  => "\x0311",
    LIGHT_BLUE  => "\x0312",
    PINK        => "\x0313",
    GREY        => "\x0314",
    LIGHT_GREY  => "\x0315",
};


# rss subscriptions
my @urls = (
    "http://feeds2.feedburner.com/solidot",
    "http://rss.slashdot.org/Slashdot/slashdot",
    "http://www.36kr.com/feed",
    "http://feeds.feedburner.com/Pansci",
    "http://feeds.feedburner.com/thehackersnews",
    "http://feeds2.feedburner.com/thenextweb",
    "http://security-sh3ll.blogspot.com/feeds/posts/default",
    "http://blog.xuite.net/big.max/Polo/rss.xml",
    "http://blog.gslin.org/feed",
    "http://feeds.feedburner.com/xxddite",
    "http://xdite-smalltalk.tumblr.com/rss",
    "https://www.linux.com/rss/feeds.php",
    "http://coolshell.cn/feed",
);



my %rss_collected = ();
# initialize the RSS bot
rss_init();


# connect to the IRC server.
my $sock = new IO::Socket::INET(PeerAddr => $server,
                                PeerPort => 6667,
                                Proto => 'tcp',
                                Blocking  => 1) or die "Can't connect\n";


# login to the server.
print $sock "NICK $nick\r\n";
print $sock "USER $login  8 * : darkx's Perl IRC Robot greetings!\r\n";



# read lines from the server until it tells us we have connected.
while (<$sock>) {
    print "--> $_";
    # check the numerical responses from the server.
    if (/004/) { # we are now logged in.
        last;
    }
    elsif (/433/) {
        die "Nickname is already in use.";
    }
}



# okay, we've logined to the server
say "login successed!";

# join the channel.
print $sock "JOIN $channel $password\r\n";
say "after join the channel $channel";


# skip /MOTD command
while (<$sock>) {
    print;
    last if /End of \/MOTD command/;
}


# greetings!
says(BLINK . LIGHT_BLUE . "hey, this is darkx's bot ._./" . NORMAL);

# set nonblocking IO
$sock->blocking(0);
# Keep reading lines from the server.
while (1) {

    rss_handler($sock) if (time % 300 < 3);

    my $input = <$sock>;
    if ($input eq "") {
        select undef, undef, undef, 0.05;
        next;
    }

    chomp $input;
    # print the raw line received by the bot.
    say "--> $input" if $input;
    if ($input =~ /^PING(.*)$/i) {
        # We must respond to PINGs to avoid being disconnected.
        print $sock "PONG $1\r\n";
    }
    elsif($input =~ /^:([^!]*)!(\S*) PRIVMSG (#\S+) :(.*)$/) {
        # PRIVMSG format:
        # /:(darkx)!(~x4r@140.113.27.40) PRIVMSG (#xxxtest) :(dakx_bot: ping)/
        # user, host, channel, message
        privmsg_handler($sock, $1, $2, $3, $4);
    }
}


# send PRIVMSG to the IRC server
sub says {
    my $str = shift;
    print $sock "PRIVMSG $channel :" . $str . "\r\n";
}

# handle messages whatever you want
sub privmsg_handler {
    my ($sock, $user, $host, $channel, $message) = @_;
    if ($message =~ /$nick:\s+ping/i) {
        says("$user: pong");
    }
    elsif ($message =~ /$nick:\s+die/i and $user =~ "darkx") {
        says("$user: Boodbye, everyone");
        die "shutdown by my master";
    }
    elsif ($message =~ /^(dict|yd):?\s*(.*)$/i) {
        Dict($2, $user);
    }
    # Youtube
    elsif ($message =~ /^((點歌)|(想聽))/ ) {
        Youtube($message, $user);
    }
}


# initialize RSS collected
sub rss_init {
    # initialization
    say "rss initing...";
    for my $url (@urls) {
        say "fetching $url";
        my $feed = XML::Feed->parse(URI->new($url)) or die XML::Feed->errstr;
        my $entry = shift [$feed->entries];
        my $digest = Digest::MD5::md5_hex($url);
        $rss_collected{$digest} = [$feed->title, $entry->title, $entry->link];
        say $feed->title . "\t-> " . $entry->title;
    }
    say "rss init done.";
}


sub rss_handler {
    say "in rss_handler";

    my $sock = shift;
    my $count = 0;
    my $flag = 0;

    # fetch again
    for my $url (@urls) {
        print "looking $url ...";
        my $feed = XML::Feed->parse(URI->new($url)) or warn XML::Feed->errstr;
        # fetch okay
        if ($feed) {
            my $entry = shift [$feed->entries];
            # new feed, update the latest
            my $digest = Digest::MD5::md5_hex($url);
            if ($rss_collected{$digest}->[1] ne $entry->title) {
                say "on update";
                my $short =  makeashorterlink($entry->link);

                says(RED . BLINK . "New RSS feed " . NORMAL .
                     "@" . scalar localtime);
                says(LIGHT_CYAN . "[ " . $feed->title . " ]" . YELLOW .
                     "[ " . $entry->title . " ] " . NORMAL . $short);

                $rss_collected{$digest} = [$feed->title, $entry->title, $entry->link];

                $flag++;
            }
            $count++;
        }
        say "done.";
    }
    say "no update" . scalar localtime if ($flag == 0);
}



# look up ydict
sub Dict {

    my ($msg, $user) = @_;

    say "Dict: $msg";

    # get the string which our user want to lookup
    my $lookup = "\'$msg\'";
    say "$lookup";

    # chect it in ydict
    my $result = `./ydict -c $lookup`;

    # grep what i really want (Chinese part)
    my $r = flter($result);

    # find nothing: $r = []
    if (!defined $r->[0]) {
        say "nothing";
        says("$user: No reslut. for $lookup  :'(");
    }
    else {
        say @$r;
        # results in ydict
        my $ret = "";
        for (@$r) {
            says("$user: $_");
        }
    }
}

sub flter {
    # original result in ydict
    my $res = shift;
    my @lines = split /\n/, $res;
    my @ret;
    my $j;
    my $ok = 0;
    for (@lines) {
        # n / v / vt / vi / prep / ad / a / pron
        if(/^n\./ or /^v[it]?\./ or /^prep\./ or /^ad\./ or /^a\./ or /^pron\./) {
            if ($ok >= 1) {
                push @ret, $j;
                $j = "";
                $ok = 0;
            }
            $j .= "$_";
        }
        elsif (/\s\s\d+/) {
            $j .= "$_";
            $ok++;
        }
    }
    push @ret, $j;
    return \@ret;
}



# youtube search
sub Youtube {

    my $mech = WWW::Mechanize->new();
    $_[0] =~ s/想聽//;
    $_[0] =~ s/點歌//;
    my $url = "https://www.youtube.com/results?hl=en&search_query=$_[0]";
    say $url;

    $mech->get( $url );

    my $ref = $mech->find_all_links( url_regex => qr/watch\?v=/i );

    my @playlist = ();
    for (@$ref) {
        if ($_->url() =~ /watch\?v=.{11}/ and $_->text() =~ /Watch Later/) {
            my $song_url = $_->url_abs();
            $mech->get( $song_url );
            my $song_title = $mech->title;
            push @playlist, $song_url . LIGHT_GREEN . " [ $song_title ]" . NORMAL;
        }
        last if (@playlist == 3);
    }

    if (@playlist > 0) {
        says("$_[1]: 為您帶來");
        says("$_") for (@playlist);
    }
}


sub get_title {
    my $url = shift;
    my $mech = WWW::Mechanize->new();
    $mech->get( $url );
    return $mech->title;
}
