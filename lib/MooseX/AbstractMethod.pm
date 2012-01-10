package MooseX::AbstractMethod;

# ABSTRACT: Declare methods requirements that must be satisfied

use Moose 0.94 ();
use namespace::autoclean;
use Moose::Exporter;
use Moose::Util::MetaRole;

# debugging...
#use Smart::Comments;

{
    package MooseX::AbstractMethod::Trait::Class;
    use Moose::Role;
    use namespace::autoclean;
    use Moose::Util qw{ does_role english_list };

    sub abstract_method_metaclass {
        my $self = shift @_;

        return Moose::Meta::Class
            ->create_anon_class(
                # XXX should this just be Moose::Meta::Method as the superclass??
                superclasses => [ $self->method_metaclass           ],
                roles        => [ 'MooseX::AbstractMethod::Trait::Method' ],
                cache        => 1,
            )
            ->name
            ;
    }

    sub add_abstract_method {
        my ($self, @names) = @_;

        my $abstract_meta = $self->abstract_method_metaclass;

        for my $name (@names) {

            my $method = $abstract_meta->wrap(
                sub { Moose->throw_error("Method $name is not implemented!") },
                name         => $name,
                package_name => $self->name,
            );

            $self->add_method($name => $method);
        }

        return;
    }

    # blow up if we're being asked to become immutable, we're a subclasss,
    # and we don't implement an abstract method

    before make_immutable => sub {
        my $self = shift @_;

        my @abstract_methods = sort
            map  { $_->name . ' (from ' . $_->original_package_name . ')' }
            grep { $_->original_package_name ne $self->name               }
            grep { does_role($_, 'MooseX::AbstractMethod::Trait::Method') }
            $self->get_all_methods
            ;

        Moose->throw_error(
            'These abstract methods have not been implemented in '
            . $self->name . ': '
            . english_list(@abstract_methods)
        ) if @abstract_methods;

        return;
    };

}
{
    package MooseX::AbstractMethod::Trait::Method;
    use Moose::Role;
    use namespace::autoclean;

    # well, hello there handsome :)
}

sub abstract { _abstract(@_) }
sub requires { _abstract(@_) }

sub _abstract {

    ### meta isa: ref $_[0]
    return shift->add_abstract_method(@_)
        unless $_[0]->isa('Moose::Meta::Role');

    goto \&Moose::Role::requires;
}

Moose::Exporter->setup_import_methods(
    with_meta => [ qw{ abstract requires } ],

    trait_aliases => [
        [ 'MooseX::AbstractMethod::Trait::Method' => 'AbstractMethod' ],
    ],
    class_metaroles => {
        class => [ 'MooseX::AbstractMethod::Trait::Class' ],
    },
);

!!42;

__END__

=head1 SYNOPSIS

    use Moose;
    use MooseX::Abstract;

    requires 'bar';

    # synonm to 'requires'
    abstract 'foo';


=head1 DESCRIPTION

This extensions allows classes to flag certain methods as being required to be
implemented by a subclass, much as a L<Moose::Role> does with 'requires'.

=head1 USAGE

As in the synopsis, simply mark certain methods as being required by
subclasses by passing their names to "abstract" or "requires".  This will
cause a method of the same name to be installed in the class that will die
horribly if it's ever called.  Additionally, when a class is made immutable,
all of its methods are checked to see if they're marked as abstract; if any
abstract methods exists that were not created in the current class, we die
horribly.

Checking for method satisfaction on make_immutable isn't perfect, but AFAICT
it's the most reasonable approach possible at the moment.  (Corrections
welcome.)

=head1 NEW SUGAR

=head2 abstract

abstract() allows one to declare a method dependency that must be satisfied by a
subclass before it is invoked, and before the subclass is made immutable.

    abstract 'method_name_that_must_be_satisfied';

=head2 requires

requires() is a synonym for abstract() and works in the way you'd expect.

=head1 SEE ALSO



=head1 BUGS

All complex software has bugs lurking in it, and this module is no exception.

Bugs, feature requests and pull requests through GitHub are most welcome; our
page and repo (same URI):

    https://github.com/RsrchBoy/moosex-abstractmethod

=cut
