package POE::Component::IRC::Plugin::WWW::Weather::US;

use 5.008_005;
use strict;
use warnings;

use POE::Component::IRC::Plugin qw( :ALL );
use HTML::TreeBuilder::XPath;
use LWP::Simple qw(get);
use URI;

our $VERSION = '0.01';

sub new {
    my $package = shift;
    return bless {}, $package;
}

sub PCI_register {
    my ($self, $irc) = splice @_, 0, 2;

    $irc->plugin_register($self, 'SERVER', qw(public));
    return 1;
}

# This is method is mandatory but we don't actually have anything to do.
sub PCI_unregister {
    return 1;
}

sub S_public {
    my ($self, $irc) = splice @_, 0, 2;

    # Parameters are passed as scalar-refs including arrayrefs.
    my $nick    = (split /!/, ${$_[0]})[0];
    my $channel = ${$_[1]}->[0];
    my $msg     = ${$_[2]};

    if ($msg =~ /^!weather\s+(\d{5})/i) {
        my $reply = $self->_get_weather($1);
        $irc->yield(privmsg => $channel => "$nick: $reply") if $reply;
        return PCI_EAT_PLUGIN;
    }

    # Default action is to allow other plugins to process it.
    return PCI_EAT_NONE;
}

sub _get_weather {
    my ($self, $zip) = @_ or return;
    my $uri = URI->new('http://forecast.weather.gov/zipcity.php');
    $uri->query_form({inputstring => $zip});

    my $content = get($uri->as_string);
    my $tree    = HTML::TreeBuilder::XPath->new;
    $tree->parse($content);

    # for now, just get the first day listed
    my ($day) = $tree->findnodes(    #
        './/ul[@class="point-forecast-7-day"][1]/li[@class=~/^row-(?:odd|even)$/]'
    ) or return;
    $_->push_content(': ') for $day->findnodes('span');
    return $day->as_trimmed_text;
}

1;
__END__

=encoding utf-8

=head1 NAME

POE::Component::IRC::Plugin::WWW::Weather::US - IRC plugin to weather US weather by zip code

=head1 SYNOPSIS

  use strict;
  use warnings;

  use POE qw(Component::IRC  Component::IRC::Plugin::WWW::Weather::US);

  my $irc = POE::Component::IRC->spawn(
      nick    => 'nickname',
      server  => 'irc.freenode.net',
      port    => 6667,
      ircname => 'ircname',
  );

  POE::Session->create(package_states => [main => [qw(_start irc_001)]]);

  $poe_kernel->run;

  sub _start {
      $irc->yield(register => 'all');

      $irc->plugin_add(Weather => POE::Component::IRC::Plugin::WWW::Weather::US->new);

      $irc->yield(connect => {});
  }

  sub irc_001 {
      $irc->yield(join => '#channel');
  }

=head1 DESCRIPTION

type !weather 91202 to get the current weather for a location, currenly fetched from L<http://forecast.weather.gov/zipcity.php>

=head1 AUTHOR

Curtis Brandt E<lt>curtis@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2013- Curtis Brandt

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
