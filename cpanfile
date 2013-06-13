requires 'perl', '5.010';
requires 'POE::Component::IRC::Plugin', '0';
requires 'Mojo::UserAgent', '4.14';

on test => sub {
    requires 'Test::More', '0.88';
};
