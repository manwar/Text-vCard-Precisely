use strict;
use warnings;
use Path::Tiny;

use Test::More tests => 7;
use Data::Section::Simple qw(get_data_section);

use lib qw(./lib);
use Encode qw(encode_utf8 decode_utf8);

BEGIN { use_ok ('Text::vCard::Precisely::V3') };        #1

my $vc = Text::vCard::Precisely::V3->new();
is 'Text::vCard::Precisely::V3', ref($vc), 'new()';     #2

$vc = Text::vCard::Precisely::V3->new({});
is 'Text::vCard::Precisely::V3', ref($vc), 'new({})';   #3

my $hashref = {
    N   => ['Gump','Forrest','','Mr.',''],
    FN  => 'Forrest Gump',
    SORT_STRING => 'Forrest Gump',
    ORG => 'Bubba Gump Shrimp Co.',
    TITLE => 'Shrimp Man',
    PHOTO => { media_type => 'image/gif', value => 'http://www.example.com/dir_photos/my_photo.gif' },
    TEL => [
        { types => ['WORK','VOICE'], value => '(111) 555-1212' },
        { types => ['HOME','VOICE'], value => '(404) 555-1212' },
    ],
    ADR =>[{
        types       => ['work'],
        pref        => 1,
        extended    => 100,
        street      => 'Waters Edge',
        city        => 'Baytown',
        region      => 'LA',
        post_code   => '30314',
        country     => 'United States of America'
    },{
        types       => ['home'],
        extended    => 42,
        street      => 'Plantation St.',
        city        => 'Baytown',
        region      => 'LA',
        post_code   => '30314',
        country     => 'United States of America'
    }],
#    LABEL => {
#        types => ['WORK'],
#        pref  => 1,
#        value => "100 Waters Edge\nBaytown\, LA 30314\nUnited States of America"
#    },
#    URL => { value => 'http://www.example.com/dir_photos/my_photo.gif' },
    URL => 'http://www.example.com/dir_photos/my_photo.gif',
    EMAIL => 'forrestgump@example.com',
    REV => '2008-04-24T19:52:43Z',
};

my $data = get_data_section('data.vcf');
$data =~ s/\n/\r\n/g;
my $string = $vc->load_hashref($hashref)->as_string();
is $string, $data, 'as_string()';                       #4


my $in_file = path( 't', 'expected.vcf' );
$string = $vc->load_file($in_file)->as_string();
my $expected_content = $in_file->slurp_utf8;
is $string, $expected_content, 'load_file()';           #5

my $load_s = $vc->load_string($data);
is $load_s->as_string(), $data, 'load_string()';        #6

TODO: {
    local $TODO = "it doesn't support parsing vCard4.0 yet";
    my $in_file = path( 't', 'vcard4.vcf' );
    $string = $vc->load_file($in_file)->as_string();
    my $expected_content = $in_file->slurp_utf8;
    is $string, $expected_content, 'parsing vCard4';    #7
}

done_testing;

__DATA__

@@ data.vcf
BEGIN:VCARD
VERSION:3.0
N:Gump;Forrest;;Mr.;
SORT-STRING:Forrest Gump
FN:Forrest Gump
ADR;TYPE=WORK;PREF=1:;100;Waters Edge;Baytown;LA;30314;United States of
 America
ADR;TYPE=HOME:;42;Plantation St.;Baytown;LA;30314;United States of America
TEL;TYPE=WORK,VOICE:111 555 1212
TEL;TYPE=HOME,VOICE:404 555 1212
EMAIL:forrestgump@example.com
ORG:Bubba Gump Shrimp Co.
TITLE:Shrimp Man
URL:http://www.example.com/dir_photos/my_photo.gif
PHOTO;MEDIATYPE=image/gif:http://www.example.com/dir_photos/my_photo.gif
REV:2008-04-24T19:52:43Z
END:VCARD
