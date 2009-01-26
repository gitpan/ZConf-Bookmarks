package ZConf::Bookmarks;

use warnings;
use strict;

=head1 NAME

ZConf::Bookmarks - ZConf backed bookmark storage system.

=head1 VERSION

Version 0.0.0

=cut

our $VERSION = '0.0.0';


=head1 SYNOPSIS

    use ZConf::Bookmarks;

    my $zbm = ZConf::Bookmarks->new();

=head1 METHODES

=head2 new

This initializes it.

One arguement is taken and that is a hash value.

=head3 hash values

=head2 autoinit

If this is set to true, it will automatically call
init the set and config. If this is set to false or
not defined, besure to check '$zbm->{init}' to see
if the config/module has been initiated or not.

=head2 set

This is the set to load initially.

=head4 zconf

If this key is defined, this hash will be passed to ZConf->new().

    my $zbm=ZConf::Runner->new();
    if($zbm->{error}){
        print "Error!\n";
    }

=cut

sub new{
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	}

	my $self={error=>undef, errorString=>undef};
	bless $self;

	#this sets the set to undef if it is not defined
	if (!defined($args{set})) {
		$self->{set}=undef;
	}else {
		$self->{set}=$args{set};
	}

	#this sets the set to undef if it is not defined
	if (!defined($args{autoinit})) {
		$self->{autoinit}=undef;
	}else {
		$self->{autoinit}=$args{set};
	}

	#this is done to keep from throwing an error when we try to pass it to ZConf->new
	if (!defined($args{zconf})) {
		$args{zconf}={};
	}

	#creates the ZConf object
	$self->{zconf}=ZConf->new(%{$args{zconf}});
	if(defined($self->{zconf}->{error})){
		warn("ZConf-Bookmarks new:1: Could not initiate ZConf. It failed with '"
			 .$self->{zconf}->{error}."', '".$self->{zconf}->{errorString}."'");
		$self->{error}=1;
		$self->{errorString}="Could not initiate ZConf. It failed with '"
		                      .$self->{zconf}->{error}."', '".
							  $self->{zconf}->{errorString}."'";
		return $self;
	}


	#create the config if it does not exist
	#if it does exist, make sure the set we are using exists
    $self->{init} = $self->{zconf}->configExists("bookmarks");
	if($self->{zconf}->{error}){
		warn("ZConf-Bookmarks new:2: Could not check if the config 'bookmarks' exists.".
			 " It failed with '".$self->{zconf}->{error}."', '"
			 .$self->{zconf}->{errorString}."'");
		$self->{error}=2;
		$self->{errorString}="Could not check if the config 'bookmarks' exists.".
	   		                 " It failed with '".$self->{zconf}->{error}."', '"
			                 .$self->{zconf}->{errorString}."'";
		return $self;
	}

	#if it is not inited, check to see if it needs to do so
	if (!$self->{init} && $self->{autoinit}) {
		$self->init($self->{set});
		if ($self->{error}) {
			warn('ZConf-Bookmarks new:4: Autoinit failed.');
		}else {
			#if init works, it is now inited and thus we set it to one
			$self->{init}=1;
		}
		#we don't set any error stuff here even if the above action failed...
		#it will have been set any ways by init methode
		return $self;
	}

	#checks it is set to use the default set
	#use defined as '0' is a legit set name and is a perl boolean for false
	if (!defined($self->{set})) {
		$self->{init}=$self->{zconf}->defaultSetExists('bookmarks');
		if($self->{zconf}->{error}){
			warn("ZConf-Bookmarks new:2: defaultSetExists failed for 'bookmarks'.".
				 " It failed with '".$self->{zconf}->{error}."', '"
				 .$self->{zconf}->{errorString}."'");
			$self->{error}=2;
			$self->{errorString}="defaultSetExists failed for 'bookmarks'.".
	   		                 " It failed with '".$self->{zconf}->{error}."', '"
			                 .$self->{zconf}->{errorString}."'";
			return $self;
		}
	}

	#check it if it set to use a specific set
	#use defined as '0' is a legit set name and is a perl boolean for false
	if (defined($self->{set})) {
		$self->{init}=$self->{zconf}->setExists('bookmarks', $self->{set});
		if($self->{zconf}->{error}){
			warn("ZConf-Bookmarks new:2: defaultSetExists failed for 'bookmarks'.".
				 " It failed with '".$self->{zconf}->{error}."', '"
				 .$self->{zconf}->{errorString}."'");
			$self->{error}=2;
			$self->{errorString}="defaultSetExists failed for 'bookmarks'.".
	   		                 " It failed with '".$self->{zconf}->{error}."', '"
			                 .$self->{zconf}->{errorString}."'";
			return $self;
		}
	}

	#the first one does this if the config has not been done yet
	#this one does it if the set has not been done yet
	#if it is not inited, check to see if it needs to do so
	if (!$self->{init} && $self->{autoinit}) {
		$self->init($self->{set});
		if ($self->{error}) {
			warn('ZConf-Bookmarks new:4: Autoinit failed.');
		}else {
			#if init works, it is now inited and thus we set it to one
			$self->{init}=1;
		}
		#we don't set any error stuff here even if the above action failed...
		#it will have been set any ways by init methode
		return $self;
	}

	#reads it if it does not need to be initiated
	if ($self->{init}) {
		$self->{zconf}->read({set=>$self->{set}, config=>'bookmarks'});
	}

	return $self;
}

=head2 addBookmark

This adds a bookmark for a specified scheme.

Only one arguement is accepted and that is a hash. Please
see the below for a list of keys.

=head3 hash args

=head4 name

This is name for a book mark.

=head4 description

This is a description for the bookmark.

=head4 link

This is the URI, minus scheme. Thus 'http://vvelox.net/' would become
'vvelox.net'.

=head4 scheme

This is the scheme it should be added it.

    my %newBM;
    $newBM{description}='VVelox.net';
    $newBM{name}='VVelox.net';
    $newBM{link}='vvelox.net';
    $newBM{scheme}='http';
    $zbm->modBookmark(%newBM);
    if($zbm->{error}){
        print "Error!\n";
    }

=cut

sub addBookmark{
	my $self=$_[0];
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	}

	#blanks any previous errors
	$self->errorblank;

	if (!defined($args{scheme})) {
		warn("ZConf-Bookmarks addBookmark:3: No scheme type specified");
		$self->{error}=3;
		$self->{errorString}="No scheme type specified";
		return undef;
	}

	#makes sure a name is specified
	if (!defined($args{name})) {
		warn('ZConf-Bookmarks addBookmark:3: No name, $args{name}, type specified');
		$self->{error}=3;
		$self->{errorString}="No name, $args{name}, type specified'";
		return undef;
	}

	#makes sure a URI scheme type is specified
	if (!defined($args{scheme})) {
		warn('ZConf-Bookmarks addBookmark:3: No URI scheme, $args{name}, specified');
		$self->{error}=3;
		$self->{errorString}="No URI scheme, $args{URI}, specified'";
		return undef;
	}

	#makes sure a description is specified
	if (!defined($args{description})) {
		warn('ZConf-Bookmarks addBookmark:3: No description, $args{description}, specified');
		$self->{error}=3;
		$self->{errorString}="No description, $args{description}, specified'";
		return undef;
	}

	#makes sure a link is specified
	if (!defined($args{'link'})) {
		warn('ZConf-Bookmarks addBookmark:3: No link, $args{description}, specified');
		$self->{error}=3;
		$self->{errorString}='No link, $args{"link"}, specified';
		return undef;
	}

	#sets the ID
	$args{bmid}=`hostname`.':'.time.':'.rand;

	my $bookmarkExists=undef;
	my $schemeExists=$self->schemeExists($args{scheme});
	if ($self->{error}) {
		warn('ZConf-Bookmarks addBookmark: schemeExists errored');
		return undef;
	}

	if ($schemeExists) {
		my $max=3;
		my $int=0;
		my $exists=1;
		#loop till it does not exists or has tried three times...
		#it is unlikely a hit will ever be found... this exists
		#just to prevent the very rare circumstance that one may
		#exist already
		while (($int <= $max) && $exists) {
			#check if it exists
			$exists=$self->bookmarkExists($args{bmid});
			if ($self->{error}) {
				warn('ZConf-Bookmarks addBookmark: bookmarkExists errored');
				return undef;
			}

			#if it exists regen the ID and try again
			if ($exists) {
				$args{bmid}=`hostname`.':'.time.':'.rand;
			}

			$int++;
		}

		#error if a new ID could not be found
		if ($exists) {
			warn('ZConf-Bookmarks addBookmark:4: Could not generate a new ID');
			$self->{error}=4;
			$self->{errorString}='Could not generate a new ID.';
			return undef;
		}

	}

	my $bmVar='schemes/'.$args{scheme}.'/'.$args{bmid}.'/';

	$self->{zconf}->setVar('bookmarks', $bmVar.'name', $args{name});
	#if for some uber unlikely this fails, error
	if ($self->{zconf}->{error}) {
		warn('ZConf-Bookmarks addBookmark:5: setVar failed... var="'.$bmVar.'name"'.
			 ' value="'.$args{name}.'"');
		$self->{error}=5;
		$self->{errorString}='setVar failed... var="'.$bmVar.'name"'.
		                     ' value="'.$args{name}.'"';
		return undef;
	}

	#this adds the rest
	$self->{zconf}->setVar('bookmarks', $bmVar.'link', $args{link});
	$self->{zconf}->setVar('bookmarks', $bmVar.'description', $args{description});
	$self->{zconf}->setVar('bookmarks', $bmVar.'created', gmtime());
	$self->{zconf}->setVar('bookmarks', $bmVar.'lastModified', gmtime());

	$self->{zconf}->writeSetFromLoadedConfig({config=>'bookmarks'});
	if ($self->{zconf}->{error}) {
		warn('ZConf-Bookmarks modBookmark:2: writeSetFromLoadedConfig failed. '.
			 'error="'.$self->{zconf}->{error}.'" errorString="'.
			 $self->{zconf}->{errorString}.'"');
		$self->{error}=2;
		$self->{errorString}='writeSetFromLoadedConfig failed. '.
			                 'error="'.$self->{zconf}->{error}.
                             '" errorString="'.
			                  $self->{zconf}->{errorString}.'"';
		return undef;
	}

	return 1;
}

=head2 bookmarkExists

This verifies a bookmark ID exists.

You do have to check the return value as it will contain if it
exists or not. $zbm->{error} is only true if there is an error
and for this the bookmark ID not existing is not considered an
error.

    my $returned=$zbm->bookmarkExists($bmid);
    if($zbm->{error}){
        print "Error!\n";
    }else{
        if($returned){
            print "It does exist.\n";
        }else{
            print "It does not exist.\n";
       }
    }

=cut

sub bookmarkExists{
	my $self=$_[0];
	my $scheme=$_[1];
	my $bmid=$_[2];

	#blanks any previous errors
	$self->errorblank;

	#make s
	if (!defined($scheme)) {
		warn("ZConf-Bookmarks bookmarkExists:3: No scheme type specified");
		$self->{error}=3;
		$self->{errorString}="No scheme type specified";
		return undef;
	}

	#make sure a scheme is specified
	if (!defined($bmid)) {
		warn("ZConf-Bookmarks bookmarkExists:3: No bmid specified");
		$self->{error}=3;
		$self->{errorString}="No bmid specified";
		return undef;
	}

	my @bmids=$self->listBookmarks($scheme);

	#go through each one looking for a match
	my $int=0;
	while (defined($bmids[$int])) {
		if ($scheme eq $bmids[$int]) {
			return 1;
		}

		$int++;
	}

	#return undef if it is not found
	return undef;
}

=head2 delBookmark

This removes a bookmark.

Only one arguement is accepted and that is the bookmark ID.

    $zbm->delBookmark($bmid);
    if($zbm->{error}){
        print "Error\n";
    }

=cut

sub delBookmark{
	my $self=$_[0];
	my $scheme=$_[1];
	my $bmid=$_[2];

	#blanks any previous errors
	$self->errorblank;

	#make s
	if (!defined($scheme)) {
		warn("ZConf-Bookmarks delBookmark:3: No scheme type specified");
		$self->{error}=3;
		$self->{errorString}="No scheme type specified";
		return undef;
	}

	#make sure a scheme is specified
	if (!defined($bmid)) {
		warn("ZConf-Bookmarks delBookmark:3: No bmid specified");
		$self->{error}=3;
		$self->{errorString}="No bmid specified";
		return undef;
	}

	#the path that will be removed
	my $path='scheme/'.$scheme.'/'.$bmid.'/';

	#delete them and check for any errors
	my @deleted=$self->{zconf}->regexVarDel('bookmarks', '^'.$path);
	if ($self->{zconf}->{error}) {
		warn('ZConf-Bookmarks delBookmark:2: regexVarDel errored. '.
			 'error="'.$self->{zconf}->{error}.'" errorString="'.
			 $self->{zconf}->{errorString}.'"');
		$self->{error}=2;
		$self->{errorString}='regexVarDel errored. '.
			                 'error="'.$self->{zconf}->{error}.'" errorString="'.
			                 $self->{zconf}->{errorString}.'"';
		return undef;
	}

	return 1;
}

=head2 init

This initializes it or a new set.

If the specified set already exists, it will be reset.

One arguement is required and it is the name of the set. If
it is not defined, ZConf will use the default one.

    #creates a new set named foo
    $zbm->init('foo');
    if($zbm->{error}){
        print "Error!\n";
    }

    #creates a new set with ZConf choosing it's name
    $zbg->init();
    if($zbm->{error}){
        print "Error!\n";
    }

=cut

sub init{
	my $self=$_[0];
	my $set=$_[1];

	#blanks any previous errors
	$self->errorblank;

	my $returned = $self->{zconf}->configExists("bookmarks");
	if(defined($self->{zconf}->{error})){
		warn("ZConf-Bookmarks init:2: Could not check if the config 'bookmarks' exists.".
			 " It failed with '".$self->{zconf}->{error}."', '"
			 .$self->{zconf}->{errorString}."'");
		$self->{error}=2;
		$self->{errorString}="Could not check if the config 'bookmarks' exists.".
		                     " It failed with '".$self->{zconf}->{error}."', '"
			                 .$self->{zconf}->{errorString}."'";
		return undef;
	}

	#create the config if it does not exist
	if (!$returned) {
		$self->{zconf}->createConfig("bookmarks");
		if ($self->{zconf}->{error}) {
			warn("ZConf-Bookmarks init:2: Could not create the ZConf config 'bookmarks'.".
				 " It failed with '".$self->{zconf}->{error}."', '"
				 .$self->{zconf}->{errorString}."'");
			$self->{error}=2;
			$self->{errorString}="Could not create the ZConf config 'bookmarks'.".
			                 " It failed with '".$self->{zconf}->{error}."', '"
			                 .$self->{zconf}->{errorString}."'";
			return undef;
		}
	}

	#create the new set
	$self->{zconf}->writeSetFromHash({config=>"bookmarks", set=>$set},{});
	#error if the write failed
	if ($self->{zconf}->{error}) {
		warn("ZConf-Bookmarks init:2: writeSetFromHash failed.".
			 " It failed with '".$self->{zconf}->{error}."', '"
			 .$self->{zconf}->{errorString}."'");
		$self->{error}=2;
		$self->{errorString}="writeSetFromHash failed.".
			                 " It failed with '".$self->{zconf}->{error}."', '"
			                 .$self->{zconf}->{errorString}."'";
		return undef;
	}

	return 1;
}

=head2 listBookmarks

This lists the currently setup bookmark IDs for a scheme.

Only one arguement is accepted and that is the scheme to look under.

    my @bookmarkIDs=$zbm->listBookmarks('http');
    if($zbm->{error}){
        print "Error!\n";
    }

=cut

sub listBookmarks{
	my $self=$_[0];
	my $scheme=$_[1];

	#blanks any previous errors
	$self->errorblank;

	if (!defined($scheme)) {
		warn("ZConf-Bookmarks listBookmarks:3: No scheme type specified");
		$self->{error}=3;
		$self->{errorString}="No scheme type specified";
		return undef;
	}

	#check if it exists
	my $returned=$self->schemeExists($scheme);
	if ($self->{error}) {
		warn('ZConf-Bookmarks listBookmarks: schemeExists errored');
		return undef;
	}

	#error if it does not exist
	if (!$returned) {
		warn('ZConf-Bookmarks listbookmarks:7: The scheme "'.$scheme.'" does not exist');
		$self->{error}=7;
		$self->{errorString}='The scheme "'.$scheme.'" does not exist';
	}

	my @bookmarks=$self->{zconf}->regxexVarGet('bookmarks', '^schemes/'.$scheme);
	if ($self->{zconf}->{error}) {
		warn("ZConf-Bookmarks listBookmarks:2: regexVarGet failed.".
			 " It failed with '".$self->{zconf}->{error}."', '"
			 .$self->{zconf}->{errorString}."'");
		$self->{error}=2;
		$self->{errorString}="writeSetFromHash failed.".
			                 " It failed with '".$self->{zconf}->{error}."', '"
			                 .$self->{zconf}->{errorString}."'";
		return undef;
	}

	my %newBookmarks;

	my $int=0;
	while (defined($bookmarks[$int])) {
		my @bookmark=split(/\//, $bookmarks[$int]);
		$newBookmarks{$bookmark[1]}='';
		$int++;
	}

	return keys(%newBookmarks);
}

=head2 listSchemss

This lists the current schemes available to choose from.

    my @schemes=$zbm->listSchemes();
    if($zbm->{error}){
        print "Error!\n";
    }

=cut

sub listSchemes{
	my $self=$_[0];

	#blanks any previous errors
	$self->errorblank;

	my @schemes=$self->{zconf}->regexVarGet('bookmarks', '^schemes/');
	if ($self->{zconf}->{error}) {
		warn("ZConf-Bookmarks listSchemes:2: regexVarGet failed.".
			 " It failed with '".$self->{zconf}->{error}."', '"
			 .$self->{zconf}->{errorString}."'");
		$self->{error}=2;
		$self->{errorString}="writeSetFromHash failed.".
			                 " It failed with '".$self->{zconf}->{error}."', '"
			                 .$self->{zconf}->{errorString}."'";
		return undef;
	}

	my %newSchemes;

	my $int=0;
	while (defined($schemes[$int])) {
		my @scheme=split(/\//, $schemes[$int]);
		$newSchemes{$scheme[1]}='';
		$int++;
	}

	return keys(%newSchemes);
}

=head2 modBookmark

Modify a bookmark.

Only one arguement is accepted and it is a hash. Please see
the hash information below for the required keys.

=head3 hash args

=head4 bmid

The bookmark ID to be changed.

=head4 name

This is name for a book mark.

=head4 description

This is a description for the bookmark.

=head4 link

This is the URI, minus scheme. Thus 'http://vvelox.net/' would become
'vvelox.net'.

=head4 scheme

This is the scheme it should be added it.

    my %newBM;
    $newBM{bmid}=$bmid;
    $newBM{description}='VVelox.net';
    $newBM{name}='VVelox.net';
    $newBM{link}='vvelox.net';
    $newBM{scheme}='http';
    $zbm->modBookmark(%newBM);
    if($zbm->{error}){
        print "Error!\n";
    }

=cut

sub modBookmark{
	my $self=$_[0];
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	}

	#blanks any previous errors
	$self->errorblank;

	if (!defined($args{scheme})) {
		warn("ZConf-Bookmarks modBookmark:3: No scheme type specified");
		$self->{error}=3;
		$self->{errorString}="No scheme type specified";
		return undef;
	}

	#makes sure a name is specified
	if (!defined($args{name})) {
		warn('ZConf-Bookmarks modBookmark:3: No name, $args{name}, type specified');
		$self->{error}=3;
		$self->{errorString}="No name, $args{name}, type specified'";
		return undef;
	}

	#makes sure a URI scheme type is specified
	if (!defined($args{scheme})) {
		warn('ZConf-Bookmarks modBookmark:3: No URI scheme, $args{name}, specified');
		$self->{error}=3;
		$self->{errorString}="No URI scheme, $args{URI}, specified'";
		return undef;
	}

	#makes sure a description is specified
	if (!defined($args{description})) {
		warn('ZConf-Bookmarks modBookmark:3: No description, $args{description}, specified');
		$self->{error}=3;
		$self->{errorString}="No description, $args{description}, specified'";
		return undef;
	}

	#makes sure a link is specified
	if (!defined($args{'link'})) {
		warn('ZConf-Bookmarks modBookmark:3: No link, $args{description}, specified');
		$self->{error}=3;
		$self->{errorString}='No link, $args{"link"}, specified';
		return undef;
	}

	#makes sure a link is specified
	if (!defined($args{'bmid'})) {
		warn('ZConf-Bookmarks modBookmark:3: No bookmark ID, $args{bmid}, specified');
		$self->{error}=3;
		$self->{errorString}='No bookmark ID, $args{"bmid"}, specified';
		return undef;
	}


	my $bookmarkExists=undef;
	my $schemeExists=$self->schemeExists($args{scheme});
	if ($self->{error}) {
		warn('ZConf-Bookmarks addBookmark: schemeExists errored');
		return undef;
	}

	if (!$bookmarkExists) {
		warn('ZConf-Bookmarks modBookark:6: The bookmark ID "'.$args{bmid}.
			 '" does not exist');
		$self->{error}=6;
		$self->{errorString}='The bookmark ID "'.$args{bmid}.'" does not exist';
		return undef;
	}

	my $bmVar='schemes/'.$args{scheme}.'/'.$args{bmid}.'/';

	$self->{zconf}->setVar('bookmarks', $bmVar.'name', $args{name});
	#if for some uber unlikely this fails, error
	if ($self->{zconf}->{error}) {
		warn('ZConf-Bookmarks addBookmark:5: setVar failed... var="'.$bmVar.'name"'.
			 ' value="'.$args{name}.'"');
		$self->{error}=5;
		$self->{errorString}='setVar failed... var="'.$bmVar.'name"'.
		                     ' value="'.$args{name}.'"';
		return undef;
	}

	#this changes the rest
	$self->{zconf}->setVar('bookmarks', $bmVar.'link', $args{link});
	$self->{zconf}->setVar('bookmarks', $bmVar.'description', $args{description});
	$self->{zconf}->setVar('bookmarks', $bmVar.'lastModified', gmtime());

	$self->{zconf}->writeSetFromLoadedConfig({config=>'bookmarks'});
	if ($self->{zconf}->{error}) {
		warn('ZConf-Bookmarks modBookmark:2: writeSetFromLoadedConfig failed. '.
			 'error="'.$self->{zconf}->{error}.'" errorString="'.
			 $self->{zconf}->{errorString}.'"');
		$self->{error}=2;
		$self->{errorString}='writeSetFromLoadedConfig failed. '.
			                 'error="'.$self->{zconf}->{error}.
                             '" errorString="'.
			                  $self->{zconf}->{errorString}.'"';
		return undef;
	}

	return 1;
}

=head2 schemeExists

This checks if a scheme has any thing setup or not.

Only one option is accepted and that is the scheme to check for.

You do have to check the return value as it will contain if it
exists or not. $zbm->{error} is only true if there is an error
and for this the scheme not existing is not considered an error.

    my $returned=$zbm->schemeExists('http');
    if($zbm->{error}){
        print "Error!\n";
    }else{
        if($returned){
            print "It exists.\n";
        }else{
            print "It does not exists.\n";
        }
    }

=cut

sub schemeExists{
	my $self=$_[0];
	my $scheme=$_[1];

	#blanks any previous errors
	$self->errorblank;

	if (!defined($scheme)) {
		warn("ZConf-Bookmarks schemeExists:3: No scheme type specified");
		$self->{error}=3;
		$self->{errorString}="No scheme type specified";
		return undef;
	}

	my @schemes=$self->listSchemes();
	if ($self->{error}) {
		warn("ZConf-Bookmarks schemeExists:3: listSchemes errored");
		return undef;
	}

	#go through each one looking for matches
	my $int=0;
	while (defined($schemes[$int])) {
		if ($scheme eq $schemes[$int]) {
			return 1;
		}

		$int++;
	}

	return undef;
}

=head2 errorblank

This blanks the error storage and is only meant for internal usage.

It does the following.

    $self->{error}=undef;
    $self->{errorString}="";

=cut

#blanks the error flags
sub errorblank{
        my $self=$_[0];

        $self->{error}=undef;
        $self->{errorString}="";

        return 1;
}

=head2 ERROR CODES

=head2 1

Could not initialize ZConf.

=head2 2

ZConf error.

=head2 3

Missing a required arguement.

=head2 4

The highly unlikely event that there a duplicate bookmark ID exists after three
attempts to generate one has happened. If this happens, it means your the local time
function, or your system clock, and rand number generator are fragged.

=head2 5

For some uber add the use of setVar here failed.

=head2 6

Bookmark does not exist.

=head2 7

Scheme does not exist.

=head1 AUTHOR

Zane C. Bowers, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-zconf-bookmarks at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=ZConf-Bookmarks>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc ZConf::Bookmarks


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=ZConf-Bookmarks>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/ZConf-Bookmarks>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/ZConf-Bookmarks>

=item * Search CPAN

L<http://search.cpan.org/dist/ZConf-Bookmarks>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Zane C. Bowers, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of ZConf::Bookmarks
