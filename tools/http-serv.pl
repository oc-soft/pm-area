#! /usr/bin/env perl

use IO::Socket;
use Getopt::Std;
use Cwd;
use strict;

$Getopt::Std::STANDARD_HELP_VERSION = 1;

my $eol = "\r\n";

our $VERSION = '0.1';

sub HELP_MESSAGE
{
    use Pod::Text::Termcap;
    my $parser = Pod::Text::Termcap->new();
    $parser->parse_from_file(__FILE__);     
}


sub create_header
{
    my %args = @_;
    my @result;
    push @result, join(':', 'Cache-Control', 'no-cache');
    if ($args{content_type}) {
        push @result, join(':', 'Content-Type', $args{content_type});
    }
    if ($args{content_length}) {
        push @result, join(':', 'Content-Length', $args{content_length});
    }
    push @result, '';

    \@result;
}

sub parse_request
{
    my $req = shift;

    my $idx = index($req, $eol . $eol);
    my $body;
    my $state_headers = $req;
    if ($idx != -1) {
        $body = substr $req, $idx;
        $state_headers = substr $req, 0, $idx;
    }
    my @state_headers = split($eol, $state_headers);

    my %res;
    
    if (scalar(@state_headers)) {
        my ($method, $path) = split(' ', $state_headers[0]);

        $res{method} = $method;
        $res{path} = $path;

        my @headers;
        for (1 .. scalar(@state_headers)) {
            my $header = $state_headers[$_];
            $idx = index(':', $header);
            if ($idx) {
                my @type_value = (
                    substr($header, 0, $idx),
                    substr($header, $idx));
                for (0 .. scalar(@type_value)) {
                    $type_value[$_] =~ s/^\s+|\s+$//g;
                }
                push @headers, \@type_value;
            }
        }
        $res{headers} = \@headers; 
    }
    $res{body} = $body if $body;
    
    \%res;
}

sub create_status_line
{
    my ($code, $msg) = @_; 
    join(' ', 'HTTP/1.1', $code, $msg);
}

sub create_response
{
    my %args = @_;
    
    my $status_code = $args{status_code} || 200;
    my $status_message = $args{stauts_message} || 'OK';
    my $content_type = $args{content_type};
    my $content = $args{content};


    
    my $status_line = create_status_line($status_code, $status_message);
    my $header = create_header(
        content_type => $content_type
    );
    join($eol, $status_line, @$header, $content);
}

sub create_page_not_found_content
{
    my $path = shift;
    my $res = <<EOL
<!doctype html>
<head>
    <title>Page not found</title>
    <meta charset="UTF-8">
</head>
<body>
    <p>Your request page is not found.</p> 
    <p>request: <span>$path</span></p>
</body>
EOL
}

sub create_not_implement_content
{
    my $method = shift;
    my $res = <<EOL
<!doctype html>
<head>
    <title>The method is not implemented</title>
    <meta charset="UTF-8">
</head>
<body>
    <p>Your request method is not implementd.</p> 
    <p>method: <span>$method</span></p>
</body>
EOL
}


sub ext_to_content_type
{
    my %res = (
        'html' => 'text/html',
        'css' => 'text/css',
        'csv' => 'text/csv',
        'js' => 'text/javascript',
        'json' => 'application/joson',
        'mjs' => 'text/javascript',
        'png' => 'image/png',
        'pdf' => 'application/pdf',
        'svg' => 'image/svg+xml',
        'txt' => 'text/plain',
        'jpeg' => 'image/jpg',
        'jpg' => 'image/jpg'
    );
    \%res;
}


sub path_to_content_type
{
    use File::Basename;
    my $path = shift;

    my $name = basename($path);

    my $idx = rindex $name, '.';

    my $res;
    if ($idx != -1) {
        my $ext = substr $name, $idx + 1;
        my $ext_content = ext_to_content_type;
        $res = $ext_content->{$ext};
    }
    
    $res;
}


sub read_file_contents
{
    my $file_path = shift;
    my %res;
    if (open FH, '<:raw', $file_path) {
        my $content;
        
        my $offset = 0;
        while (1) {
            my $read_size = read FH, $content, 1024, $offset;
            $offset += $read_size;
            last if !$read_size;
        }
        close FH;
        if (!$!) {
            $res{content} = $content;
            $res{succeeded} = 1;
        } else {
            $res{succeeded} = -1;
        }
    } else {
        $res{succeeded} = 0;
    }
    \%res;
}

sub handle_request
{
    my ($req, $doc_root) = @_;
    my $res;

    if ($req->{method} eq 'GET') {
        use File::Spec;
        my $path = $req->{path} || '/';
         
        $path .= 'index.html' if $path =~ /\/$/;

        my $file_path = File::Spec->catfile($doc_root, $path);
        
        my $content_and_state = read_file_contents $file_path;
        if ($content_and_state->{succeeded} == 1) {
            my $content_type = path_to_content_type $file_path;
            $res = create_response(
                status_code => 200,
                status_message => 'OK',
                content_type => $content_type,
                content => $content_and_state->{content}
            );
        } else {
            $res = create_response(
                status_code => 404,
                status_message => 'Not Found',
                content_type => 'text/html',
                content => create_page_not_found_content($req->{method}));
        }
    } else {
        $res = create_response(
            status_code => 501,
            status_message => 'Not Implemented',
            content_type => 'text/html',
            content => create_not_implement_content($req->{method}));
    }
    $res;
}

sub run_server
{
    my ($socket, $doc_root) = @_;

    while (1) {
        my $client = $socket->accept();
        my $buf = '';
        my $buf_size = 1024 * 1024;
        $client->recv($buf, $buf_size, 0);

        my $response = handle_request(parse_request($buf), $doc_root);

        $client->send($response);
        $client->shutdown(SHUT_WR);
    }
}

my %opts;
getopts('p:d:', \%opts);

my $port = $opts{p} || 8080;
my $doc_root = $opts{d} || getcwd;



my $sock = IO::Socket->new(
    Domain => IO::Socket::AF_INET,
    Type => IO::Socket::SOCK_STREAM,
    Proto => 'tcp',
    LocalHost => '0.0.0.0',
    LocalPort =>$port,
    Listen => 0) || die "Can not open socket $IO::Socket::errorstr";

run_server $sock, $doc_root;

__END__

=pod

=head1 Simple http server

simple http server


 perl http-server.pl [OPTION]

 -p [PORT]       specify port number to listen to. default is 8080.
 -d [DOCROOT]    specify document root to serve some files. 
                 default is current woring directory  

=cut
# vi: se ts=4 sw=4 et:
