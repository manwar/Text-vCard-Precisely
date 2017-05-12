# ABSTRACT: turns baubles into trinkets
package Text::vCard::Precisely::V4;

use 5.12.5;
use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Types::DateTime qw(TimeZone);

extends 'Text::vCard::Precisely::V3';

use Carp;
use Encode;

=encoding utf8

=head1 NAME

Text::vCard::Precisely::V4 - Read, Write and Edit B<vCards 4.0>

=head2 SYNOPSIS
 
You can unlock types that will be available from vCard 4.0

 my $vc = Text::vCard::Precisely->new( version => '4.0' );
 # Or you can write like bellow:
 #my $vc = Text::vCard::Precisely::V4->new();

The Usage is same with L<Text::vCard::Precisely::V3|https://github.com/worthmine/Text-vCard-Precisely/blob/master/lib/Text/vCard/Precisely/V3.pm>

=head2 DESCRIPTION

This module is an additional version for reading/writing for vCard 4.0. it's just a wrapper of L<Text::vCard::Precisely::V3|https://github.com/worthmine/Text-vCard-Precisely/blob/master/lib/Text/vCard/Precisely/V3.pm> with Moose.

B<Caution!> It's NOT be recommended because some reasons bellow:

=over

=item

Mac OS X and iOS can't parse vCard4.0 with UTF-8 precisely.

=item

Android 4.4.x can't parse vCard4.0.

=back

Note that the vCard RFC requires FN type.
And this module does not check or warn if these conditions have not been met.

=cut

use Text::vCard::Precisely::V4::Node;
use Text::vCard::Precisely::V4::Node::N;
use Text::vCard::Precisely::V4::Node::Phone;
use Text::vCard::Precisely::V4::Node::Related;

has version => ( is => 'ro', isa => 'Str', default => '4.0' );

=head2 Constructors

=head3 load_hashref($HashRef)

SAME as 3.0

=head3 loadI<file($file>name)

SAME as 3.0

=head3 load_string($vCard)

SAME as 3.0
 
=head2 METHODS

=head3 as_string()

Returns the vCard as a string.
You HAVE TO use encode_utf8() if your vCard is written in utf8

=cut

my $cr = "\x0D\x0A";
my @nodes = qw(
    FN N NICKNAME
    ADR TEL EMAIL IMPP LANG GEO
    ORG TITLE ROLE CATEGORIES RELATED
    NOTE SOUND UID URL FBURL CALADRURI CALURI
    XML KEY SOCIALPROFILE PHOTO LOGO SOURCE
);

# ToDo: to accept SORT-AS param in FN,N,ORG

sub as_string {
    my ($self) = @_;
    my $str = $self->_header();
    $str .= $self->_make_nodes(@nodes);

    $str .= 'KIND:' . $self->kind . $cr if $self->kind;
    $str .= 'BDAY:' . $self->bday . $cr if $self->bday;
    $str .= 'ANNIVERSARY:' . $self->anniversary . $cr if $self->anniversary;
    $str .= 'GENDER:' . $self->gender . $cr if $self->gender;
    $str .= 'UID:' . $self->uid . $cr if $self->uid;
    map { $str .= "MEMBER:$_" . $cr } @{ $self->member || [] } if $self->member;
    map { $str .= "CLIENTPIDMAP:$_" . $cr } @{ $self->clientpidmap || [] } if $self->clientpidmap;

    $str .= $self->_footer();
    $str = $self->_fold($str);
    return decode( $self->encoding_out, $str ) unless $self->encoding_out eq 'none';
    return $str;
}

=head3 as_file($filename)

Write data in vCard format to $filename.
Dies if not successful.

=head2 SIMPLE GETTERS/SETTERS

These methods accept and return strings.

=head3 version()

Returns Version number of the vcard. Defaults to B<'3.0'>
It is B<READONLY> method. So you can NOT downgrade it to 3.0

=head3 rev()

To specify revision information about the current vCard
The format in as_string() is B<different from 3.0>, but the interface is SAME

=head2 COMPLEX GETTERS/SETTERS

They are based on Moose with coercion
So these methods accept not only ArrayRef[HashRef] but also ArrayRef[Str], single HashRef or single Str
Read source if you were confused

=head3 n()

The format is SAME as 3.0

=cut

subtype 'v4N'
    => as 'Text::vCard::Precisely::V4::Node::N';
coerce 'v4N'
    => from 'HashRef[Maybe[Ref]|Maybe[Str]]'
    => via {
        my %param;
        while( my ($key, $value) = each %$_ ) {
            $param{$key} = $value if $value;
        }
        return Text::vCard::Precisely::V4::Node::N->new(\%param);
    };
coerce 'v4N'
    => from 'HashRef[Maybe[Str]]'
    => via { Text::vCard::Precisely::V4::Node::N->new({ value => $_ }) };
coerce 'v4N'
    => from 'ArrayRef[Maybe[Str]]'
    => via { Text::vCard::Precisely::V4::Node::N->new({ value => {
        family      => $_->[0] || '',
        given       => $_->[1] || '',
        additional  => $_->[2] || '',
        prefixes    => $_->[3] || '',
        suffixes    => $_->[4] || '',
} }) };
coerce 'v4N'
    => from 'Str'
    => via { Text::vCard::Precisely::V4::Node::N->new({ value => [split /(?<!\\);/, $_] }) };
has n => ( is => 'rw', isa => 'v4N', coerce => 1 );

=head3 tel()

The format in as_string() is B<different from 3.0>, but the interface is SAME
 
=cut

subtype 'v4Tel' => as 'ArrayRef[Text::vCard::Precisely::V4::Node::Phone]';
coerce 'v4Tel'
    => from 'Str'
    => via { [ Text::vCard::Precisely::V4::Node::Phone->new({ value => $_ }) ] };
coerce 'v4Tel'
    => from 'HashRef'
    => via { [ Text::vCard::Precisely::V4::Node::Phone->new($_) ] };
coerce 'v4Tel'
    => from 'ArrayRef[HashRef]'
    => via { [ map { Text::vCard::Precisely::V4::Node::Phone->new($_) } @$_ ] };
has tel => ( is => 'rw', isa => 'v4Tel', coerce => 1 );

=head3 adr(), address()

Both are same method with Alias
The format is SAME as 3.0

=head2 email()

The format is SAME as 3.0

=head3 url()

The format is SAME as 3.0

=head3 photo(), logo()

The format is SAME as 3.0

=head3 note()

The format is SAME as 3.0

=head3 org(), title(), role(), categories()

The format is SAME as 3.0

=head3 fn(), full_name(), fullname()

They are same method at all with Alias
The format is SAME as 3.0

=head3 nickname()

The format is SAME as 3.0
 
=head3 lang()

To specify the language(s) that may be used for contacting the entity associated with the vCard
It's the B<new method from 4.0>

=head3 impp(), xml()

I don't think they are so popular paramater, but here are the methods!
They are the B<new method from 4.0>

=head3 geo(), key()

The format is SAME as 3.0

=cut

subtype 'v4Node' => as 'ArrayRef[Text::vCard::Precisely::V4::Node]';
coerce 'v4Node'
    => from 'Str'
    => via {
        my $name = uc [split( /::/, [caller(2)]->[3] )]->[-1];
        return [ Text::vCard::Precisely::V4::Node->new( { name => $name, value => $_ } ) ]
    };
coerce 'v4Node'
    => from 'HashRef'
    => via {
        my $name = uc [split( /::/, [caller(2)]->[3] )]->[-1];
        return [ Text::vCard::Precisely::V4::Node->new({
                name => $_->{'name'} || $name,
                types => $_->{'types'} || [],
                value => $_->{'value'} || croak "No value in HashRef!",
        }) ]
 };
coerce 'v4Node'
    => from 'ArrayRef[HashRef]'
    => via {
     my $name = uc [split( /::/, [caller(2)]->[3] )]->[-1];
         return [ map { Text::vCard::Precisely::V4::Node->new({
         name => $_->{'name'} || $name,
         types => $_->{'types'} || [],
         value => $_->{'value'} || croak "No value in HashRef!",
     }) } @$_ ]
};
has [qw|note org title role categories fn nickname lang impp xml geo key|]
    => ( is => 'rw', isa => 'v4Node', coerce => 1 );

=head3 source(), sound()

The formats are SAME as 3.0

=head3 fburl(), caladruri(), caluri()

I don't think they are so popular types, but here are the methods!
They are the B<new method from 4.0>

=cut

has [qw|source sound url fburl caladruri caluri|]
    => ( is => 'rw', isa => 'URLs', coerce => 1 );

subtype 'Related' => as 'ArrayRef[Text::vCard::Precisely::V4::Node::Related]';
coerce 'Related'
    => from 'HashRef'
    => via { [ Text::vCard::Precisely::V4::Node::Related->new($_) ] };
    coerce 'Related'
    => from 'ArrayRef[HashRef]'
    => via { [ map { Text::vCard::Precisely::V4::Node::Related->new($_) } @$_ ] };
has related => ( is => 'rw', isa => 'Related', coerce => 1 );

=head3 kind()

To specify the kind of object the vCard represents
It's the B<new method from 4.0>
 
=cut

subtype 'KIND'
    => as 'Str'
    => where { m/^(:?individual|group|org|location|[a-z0-9\-]+|X-[a-z0-9\-]+)$/s }
    => message { "The KIND you provided, $_, was not supported" };
has kind => ( is => 'rw', isa => 'KIND' );


subtype 'v4TimeStamp'
    => as 'Str'
    => where { m/^\d{8}T\d{6}(:?Z(:?-\d{2}(:?\d{2})?)?)?$/is  }
    => message { "The TimeStamp you provided, $_, was not correct" };
coerce 'v4TimeStamp'
    => from 'Str'
    => via { m/^(\d{4})-?(\d{2})-?(\d{2})(:?T(\d{2}):?(\d{2}):?(\d{2})Z)?$/is;
    return sprintf '%4d%02d%02dT%02d%02d%02dZ', $1, $2, $3, $4, $5, $6
};
coerce 'v4TimeStamp'
    => from 'Int'
    => via {
        my ( $s, $m, $h, $d, $M, $y ) = gmtime($_);
        return sprintf '%4d%02d%02dT%02d%02d%02dZ', $y + 1900, $M + 1, $d, $h, $m, $s
    };
coerce 'v4TimeStamp'
    => from 'ArrayRef[HashRef]'
    => via { $_->[0]{value} };
has rev => ( is => 'rw', isa => 'v4TimeStamp', coerce => 1  );

=head3 member(), clientpidmap()

I don't think they are so popular types, but here are the methods!
It's the B<new method from 4.0>

=cut

subtype 'MEMBER'
    => as 'ArrayRef[UID]';
coerce 'MEMBER'
    => from 'UID'
    => via { [$_] };
has member => ( is => 'rw', isa => 'MEMBER', coerce => 1 );

subtype 'CLIENTPIDMAP'
    => as 'Str'
    => where { m/^\d+;urn:uuid:[A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12}$/is }
    => message { "The CLIENTPIDMAP you provided, $_, was not correct" };
subtype 'CLIENTPIDMAPs'
    => as 'ArrayRef[CLIENTPIDMAP]';
coerce 'CLIENTPIDMAPs'
    => from 'Str'
    => via { [$_] };
has clientpidmap => ( is => 'rw', isa => 'CLIENTPIDMAPs', coerce => 1 );

=head3 tz(), timezone()

Both are same method with Alias
The format is SAME as 3.0
 
=head3 bday(), birthday()

Both are same method with Alias
The format is SAME as 3.0

=head3 anniversary()

The date of marriage, or equivalent, of the object the vCard represents
It's the B<new method from 4.0>

=head3 gender()

To specify the components of the sex and gender identity of the object the vCard represents
It's the B<new method from 4.0>

=head3 prodid()

The format is SAME as 3.0

=cut

has [qw|bday anniversary gender prodid|] => ( is => 'rw', isa => 'Str' );

__PACKAGE__->meta->make_immutable;
no Moose;

=head3 sort_string()

B<It's DEPRECATED from 4.0> Use SORT-AS param instead of it

=cut

sub sort_string {
    my ($self) = @_;
    croak "'SORT-STRING' type is DEPRECATED! Use 'SORT-AS' param instead of it.";
}

=head3 label()

B<It's DEPRECATED from 4.0> Use LABEL param in ADR instead of it

=cut

sub label {
    my ($self) = @_;
    croak "'LABEL' type is DEPRECATED! Use 'LABEL' param in ADR instead of it.";
}

1;

=head2 TODO
 
=over

=item 

SORT-AS param in N,FN,ORG is NOT available

=item
 
LABEL param in ADR is NOT available

=back

=head2 aroud UTF-8

If you want to send precisely the vCard with UTF-8 characters to the B<ALMOST> of smartphones, Use 3.0
It seems to be TOO EARLY to use 4.0

=head2 for under perl-5.12.5

This module uses \P{ascii} in regexp so You have to use 5.12.5 and later
And this module uses Data::Validate::URI and it has bug on 5.8.x. so I can't support them

=head2 SEE ALOSO

=over

=item

L<Text::vCard::Precisely::V3|https://github.com/worthmine/Text-vCard-Precisely/blob/master/lib/Text/vCard/Precisely/V3.pm>

=item

L<RFC 6350|https://tools.ietf.org/html/rfc6350>
 
=item

L<Wikipedia|https://en.wikipedia.org/wiki/VCard>
 
=back
 
=head2 AUTHOR
 
L<Yuki Yoshida(worthmine)|https://github.com/worthmine>
