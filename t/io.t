use strict;
use warnings;
use Path::Tiny;

use Test::More tests => 6;
use Data::Section::Simple qw(get_data_section);

use lib qw(./lib);

BEGIN { use_ok ('Text::vCard::Precisely::V3') };

my $vc = Text::vCard::Precisely::V3->new();
is 'Text::vCard::Precisely::V3', ref($vc), 'new()';

$vc = Text::vCard::Precisely::V3->new({});
is 'Text::vCard::Precisely::V3', ref($vc), 'new({})';

my $hashref = {
    N   => ['Gump','Forrest','','Mr.',''],
    FN  => 'Forrest Gump',
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

    EMAIL => { value => 'forrestgump@example.com' },
    REV => '2008-04-24T19:52:43Z',
};

my $data = get_data_section('data.vcf');
$data =~ s/\n/\r\n/g;
my $string = $vc->load_hashref($hashref)->as_string();
is $string, $data, 'as_string()';


my $in_file = path( 't', 'expected.vcf' );
$string = $vc->load_file($in_file)->as_string();
my $expected_content = $in_file->slurp_utf8;
is $string, $expected_content, 'load_file()';

TODO: {
    local $TODO = "Text::vCard::Addressbook dones't parse MEDIATYPE around PHOTO";
}

my $load_s = $vc->load_string($data);
is $load_s->as_string(), $data, 'load_string()';

done_testing;

__DATA__

@@ data.vcf
BEGIN:VCARD
VERSION:3.0
N:Gump;Forrest;;Mr.;
FN:Forrest Gump
ADR;TYPE=WORK;PREF=1:;100;Waters Edge;Baytown;LA;30314;United States of
 America
ADR;TYPE=HOME:;42;Plantation St.;Baytown;LA;30314;United States of America
TEL;TYPE=WORK,VOICE:111 555 1212
TEL;TYPE=HOME,VOICE:404 555 1212
EMAIL:forrestgump@example.com
ORG:Bubba Gump Shrimp Co.
TITLE:Shrimp Man
PHOTO;MEDIATYPE=image/gif:http://www.example.com/dir_photos/my_photo.gif
REV:2008-04-24T19:52:43Z
END:VCARD
