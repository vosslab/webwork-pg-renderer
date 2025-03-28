#use AnswerEvaluator;


# provided by the translator
# initialize PGcore and PGrandom


sub _PG_init{
  $main::VERSION ="PG-2.15";

  #
  #  Set up MathObject context for use in problems
  #  that don't load MathObjects.pl
  #
  %main::context = ();
  Parser::Context->current(\%main::context);
}

our $PG;

sub not_null {$PG->not_null(@_)};

sub pretty_print {$PG->pretty_print(shift,$main::displayMode)};

sub encode_pg_and_html {PGcore::encode_pg_and_html(@_)};

sub DEBUG_MESSAGE {
    my @msg = @_;
	$PG->debug_message("---- ".join(" ",caller())." ------", @msg,"__________________________");
}

sub WARN_MESSAGE{
    my @msg = @_;
	$PG->warning_message("---- ".join(" ",caller())." ------", @msg,"__________________________");
}

sub DOCUMENT {

	# get environment
	$rh_envir = \%envir;  #KLUDGE FIXME
	# warn "rh_envir is ",ref($rh_envir);
	$PG = new PGcore($rh_envir,	# can add key/value options to modify
	);
	$PG->clear_internal_debug_messages;
	# initialize main:: variables

	$ANSWER_PREFIX         		= $PG->{ANSWER_PREFIX};
	$QUIZ_PREFIX           		= $PG->{QUIZ_PREFIX};
	$showPartialCorrectAnswers 	= $PG->{flags}->{showPartialCorrectAnswers};
	$showHint                   = $PG->{flags}->{showHint};
	$solutionExists        		= $PG->{flags}->{solutionExists};
	$hintExists            		= $PG->{flags}->{hintExists};
	$pgComment                  = '';
	%external_refs         		= %{ $PG->{external_refs}};

	@KEPT_EXTRA_ANSWERS =();   #temporary hack

	my %envir              =   %$rh_envir;
	# Save the file name for use in error messages

	#no strict;
	foreach  my  $var (keys %envir) {
   		PG_restricted_eval(qq!\$main::$var = \$envir{$var}!);  #whew!! makes sure $var is interpolated but $main:: is evaluated at run time.
	    warn "Problem defining $var  while initializing the PG problem: $@" if $@;
	}

	$displayMode           = $PG->{displayMode};
	$problemSeed           = $PG->{problemSeed};
	$PG_random_generator   = $PG->{PG_random_generator};
	#warn "{inputs_ref}->{problemSeed} =",$inputs_ref->{problemSeed} if $inputs_ref->{problemSeed};
	#warn "{inputs_ref}->{displayMode} =",$inputs_ref->{displayMode} if $inputs_ref->{displayMode};
	#warn "displayMode $displayMode";
	#warn "problemSeed $problemSeed";
	$inputs_ref->{problemSeed}='';   #this version of the problemSeed is tainted. It can be set by a student
	$inputs_ref->{displayMode}='';   # not sure whether this should ever by used or not.

	load_css();
	load_js();
}

$main::displayMode = $PG->{displayMode};
$main::PG = $PG;
sub TEXT {
	 $PG->TEXT(@_) ;
}

sub HEADER_TEXT {
	$PG->HEADER_TEXT(@_);
}

sub POST_HEADER_TEXT {
	$PG->POST_HEADER_TEXT(@_);
}

# We expect valid HTML language codes, but there can also include a region code, or other
# settings.
#    See https://www.w3.org/International/questions/qa-choosing-language-tags
# Example settings: en-US, en-UK, he-IL
# Some special language codes (zh-Hans) are longer
#    http://www.rfc-editor.org/rfc/bcp/bcp47.txt
#    https://www.w3.org/International/articles/language-tags/
#    https://www.w3.org/International/questions/qa-lang-2or3.en.html
#    http://www.iana.org/assignments/language-subtag-registry/language-subtag-registry
#    https://www.w3schools.com/tags/ref_language_codes.asp
#    https://www.w3schools.com/tags/ref_country_codes.asp
# Tester at https://r12a.github.io/app-subtags/

sub SET_PROBLEM_LANGUAGE {
  my $requested_lang = shift;

  # Clean it up for safety
  my $selected_lang = $requested_lang;
  $selected_lang =~ s/[^a-zA-Z0-9-]//g ; # Drop any characters not permitted.

  if ( $selected_lang ne $requested_lang ) {
    warn "PROBLEM_LANGUAGE was edited. Requested: $requested_lang which was replaced by $selected_lang";
  }
  $PG->{flags}->{"language"} = $selected_lang;
}

# SET_PROBLEM_TEXTDIRECTION to set the HTML DIRection attribute to be applied
# to the DIV element containing this problem.

# We only permit valid settings for the HTML direction attribute:
#      dir="ltr|rtl|auto"
# https://www.w3schools.com/tags/att_global_dir.asp

# It is likely that only problems written in RTL scripts
# will need to call the following function to set the base text direction
# for the problem.

# Note the flag may not be set, and then webwork2 will use default behavior.

sub SET_PROBLEM_TEXTDIRECTION {
  my $requested_dir = shift;

  # Only allow valid values:

  if ( $requested_dir =~ /^ltr$/i ) {
    $PG->{flags}->{"textdirection"} = "ltr";
  } elsif ( $requested_dir =~ /^rtl$/i ) {
    $PG->{flags}->{"textdirection"} = "rtl";
  } elsif ( $requested_dir =~ /^auto$/i ) {
    $PG->{flags}->{"textdirection"} = "auto"; # NOT RECOMMENDED
  } else {
    warn " INVALID setting for PROBLEM_TEXTDIRECTION: $requested_dir was DROPPED.";
  }
}

=head4 ADD_CSS_FILE

Request that the problem HTML page also include additional CSS files
from the webwork2/htdocs/ directory or from an external location.

	ADD_CSS_FILE($file, $external);

If external is 1, it is assumed the full url is provided.  If external is 0 or
not given, then file name will be prefixed with the webwork2/htdocs/ directory.
For example:

	ADD_CSS_FILE("css/rtl.css");
	ADD_CSS_FILE("https://external.domain.com/path/to/file.css", 1);

=cut

sub ADD_CSS_FILE {
  my ($file, $external) = @_;
  push(@{$PG->{flags}{extra_css_files}}, { file => $file, external => $external });
}

# This loads the basic css needed by pg.
# It is expected that the requestor will also load the styles for Bootstrap.
# Some problems use jquery-ui still, and so the requestor should also load the css for that if those problems are used,
# although those problems should also be rewritten to not use jquery-ui.
sub load_css() {
	ADD_CSS_FILE('js/apps/Problem/problem.css');
	ADD_CSS_FILE('js/apps/Knowls/knowl.css');
	ADD_CSS_FILE('js/apps/ImageView/imageview.css');

	if ($envir{useMathQuill}) {
		ADD_CSS_FILE('node_modules/mathquill/dist/mathquill.css');
		ADD_CSS_FILE('js/apps/MathQuill/mqeditor.css');
	} elsif ($envir{useMathView}) {
		ADD_CSS_FILE('js/apps/MathView/mathview.css');
	}
}

=head4 ADD_JS_FILE

Request that the problem HTML page also include additional JS files
from the webwork2/htdocs/ directory or from an external location.

	ADD_JS_FILE($file, $external);

If external is 1, it is assumed the full url is provided.  If external is 0 or
not given, then file name will be prefixed with the webwork2/htdocs/ directory.

Additional attributes can be passed as a hash reference in the optional third
argument.  These attributes will be added as attributes to the script tag.

For example:

	ADD_JS_FILE("js/apps/Base64/Base64.js");
	ADD_JS_FILE("//web.geogebra.org/4.4/web/web.nocache.js", 1);
	ADD_JS_FILE("js/apps/GraphTool/graphtool.js", 0, { id => "gt_script", defer => undef });

=cut

sub ADD_JS_FILE {
	my ($file, $external, $attributes) = @_;
	push(@{$PG->{flags}{extra_js_files}}, { file => $file, external => $external, attributes => $attributes });
}

# This loads the basic javascript needed by pg.
# It is expected that the requestor will also load MathJax, Bootstrap, and jquery.
# Some problems use jquery-ui still, and so the requestor should also load the js for that if those problems are used,
# although those problems should also be rewritten to not use jquery-ui.
sub load_js() {
	ADD_JS_FILE('js/apps/InputColor/color.js',    0, { defer => undef });
	ADD_JS_FILE('js/apps/Base64/Base64.js',       0, { defer => undef });
	ADD_JS_FILE('js/apps/Knowls/knowl.js',        0, { defer => undef });
	ADD_JS_FILE('js/apps/ImageView/imageview.js', 0, { defer => undef });

	if ($envir{useMathQuill}) {
		ADD_JS_FILE('node_modules/mathquill/dist/mathquill.js', 0, { defer => undef });
		ADD_JS_FILE('js/apps/MathQuill/mqeditor.js',            0, { defer => undef });
	} elsif ($envir{useMathView}) {
		ADD_JS_FILE("js/apps/MathView/$envir{mathViewLocale}");
		ADD_JS_FILE('js/apps/MathView/mathview.js');
	} elsif ($envir{useWirisEditor}) {
		ADD_JS_FILE('js/apps/WirisEditor/quizzes.js');
		ADD_JS_FILE('js/apps/WirisEditor/wiriseditor.js');
		ADD_JS_FILE('js/apps/WirisEditor/mathml2webwork.js');
	}
}

sub AskSage {
    my $python = shift;
    my $options = shift;
    WARN_MESSAGE("the second argument to AskSage should be a hash of options") unless $options =~/HASH/;
	$PG->AskSage($python, $options);
}

# sageReturnedFail checks to see if the return from Sage indicates some kind of failure
# undefined means old style return (a simple string) failed
# $obj->{success} defined but equal to zero means that the failed return and error
# messages are encoded in the $obj hash.
sub sageReturnedFail {
        my $obj = shift;
       return ( not defined($obj) or ( defined($obj->{success}) and $obj->{success}==0 ));
}
sub LABELED_ANS {
  my @in = @_;
  my @out = ();
  while (@in ) {
  	my $label    = shift @in;
  	$ans_eval = shift @in;
  	push @out, $label, $ans_eval;
  }
  $PG->LABELED_ANS(@out); # returns pointer to the labeled answer group
}

sub NAMED_ANS {
	&LABELED_ANS(@_); # returns pointer to the labeled answer group
}

sub ANS {
    #warn "using PGnew for ANS";
	$PG->ANS(@_);     # returns pointer to the labeled answer group
}

sub RECORD_ANS_NAME {
	$PG->record_ans_name(@_);
}

sub inc_ans_rule_count {
   #$PG->{unlabeled_answer_blank_count}++;
   #my $num = $PG->{unlabeled_answer_blank_count};
   DEBUG_MESSAGE( " No increment done. Using PG to inc_ans_rule_count = $num ", caller(2));
   warn " using PG to inc_ans_rule_count = $num ", caller(2);
   $PG->{unlabeled_answer_blank_count};
}
sub ans_rule_count {
	$PG->{unlabeled_answer_blank_count};
}
sub NEW_ANS_NAME {
     return "" if $PG_STOP_FLAG;
	#my $number=shift;
    # we have an internal count so the number not actually used.
	my $name =$PG->record_unlabeled_ans_name();
	$name;
}
sub NEW_ARRAY_NAME {
     return "" if $PG_STOP_FLAG;
	my $name =$PG->record_unlabeled_array_name();
	$name;
}

# new subroutine
sub NEW_ANS_BLANK {
    return "" if $PG_STOP_FLAG;
	$PG->record_unlabeled_ans_name(@_);
}

sub ANS_NUM_TO_NAME {
	$PG->new_label(@_);  # behaves as in PG.pl
}

sub store_persistent_data {
		$PG->store_persistent_data(@_); #needs testing
}
sub RECORD_FORM_LABEL {              # this stores form data (such as sticky answers), but does nothing more
                                     # it's a bit of hack since we are storing these in the
                                     # KEPT_EXTRA_ANSWERS queue even if they aren't answers per se.
    #FIXME
    # warn "Using RECORD_FORM_LABEL -- deprecated? use $PG->store_persistent_data instead.";
	RECORD_EXTRA_ANSWERS(@_);
}

sub RECORD_EXTRA_ANSWERS {
	return "" if $PG_STOP_FLAG;
	my $label   = shift;             # the label of the input box or textarea
    eval(q!push(@main::KEPT_EXTRA_ANSWERS, $label)!); #put the labels into the hash to be caught later for recording purposes
    $label;

}


sub NEW_ANS_ARRAY_NAME {  # this keeps track of the answers within an array which are entered implicitly,
                          # rather than with a specific label
        return "" if $PG_STOP_FLAG;
		my $number=shift;
		$main::vecnum = -1;
		my $row = shift;
		my $col = shift;
#       my $array_ans_eval_label = "ArRaY"."$number"."__"."$vecnum".":";
		my $label = $PG->{QUIZ_PREFIX}.$PG->{ARRAY_PREFIX}."$number"."__"."$vecnum"."-"."$row"."-"."$col"."__";
#		my $response_group = new PGresponsegroup($label,undef);
#		$PG->record_ans_name($array_ans_eval_label, $response_group);
#       What does vecnum do?
#       The name is simply so that it won't conflict when placed on the HTML page
#       my $array_label = shift;
		$PG->record_array_name($label);  # returns $array_label, $ans_label
}

sub NEW_ANS_ARRAY_NAME_EXTENSION {
	NEW_ANS_ARRAY_ELEMENT_NAME(@_);
}

sub NEW_ANS_ARRAY_ELEMENT_NAME {   # creates a new array element answer name and records it

        return "" if $PG_STOP_FLAG;
		my $number=shift;
		my $row_num = shift;
		my $col_num = shift;
		if( $row_num == 0 && $col_num == 0 ){
			$main::vecnum += 1;
		}
#		my $ans_label = "ArRaY".sprintf("%04u", $number);
		my $ans_label = $PG->new_array_label($number);
		my $element_ans_label = $PG->new_array_element_label($ans_label,$row_num, $col_num,vec_num=>$vecnum);
		my $response = new PGresponsegroup($ans_label,$element_ans_label, undef);
		$PG->extend_ans_group($ans_label,$response);
		$element_ans_label;
}
sub NEW_LABELED_ANS_ARRAY {    #not in PG_original
		my $ans_label = shift;
		my @response_list = @_;
		#$PG->extend_ans_group($ans_label,@response_list);
		$PG->{PG_ANSWERS_HASH}->{$ans_label}->insert_responses(@response_list);
		# should this return an array of labeled answer blanks???
}
sub     EXTEND_ANS_ARRAY {    #not in PG_original
		my $ans_label = shift;
		my @response_list = @_;
		#$PG->extend_ans_group($ans_label,@response_list);
		$PG->{PG_ANSWERS_HASH}->{$ans_label}->append_responses(@response_list);
}
sub CLEAR_RESPONSES {
	my $ans_label  = shift;
#	my $response_label = shift;
#	my $ans_value  = shift;
	if (defined ($PG->{PG_ANSWERS_HASH}->{$ans_label}) ) {
		my $responsegroup = $PG->{PG_ANSWERS_HASH}->{$ans_label}->{response};
		if ( ref($responsegroup) ) {
			$responsegroup->clear;
		} else {
			$responsegroup = $PG->{PG_ANSWERS_HASH}->{$ans_label}->{response} = new PGresponsegroup($label);
		}
	}
	'';
}

#FIXME -- examine the difference between insert_response and extend_response
sub INSERT_RESPONSE {
	my $ans_label  = shift;
	my $response_label = shift;
	my $ans_value  = shift;
	my $selected   = shift;
	# warn "\n\nin PG.pl\nanslabel $ans_label responselabel $response_label value $ans_value";
	if (defined ($PG->{PG_ANSWERS_HASH}->{$ans_label}) ) {
		my $responsegroup = $PG->{PG_ANSWERS_HASH}->{$ans_label}->{response};
		$responsegroup->append_response($response_label, $ans_value, $selected);
		# warn "There are  ", scalar($responsegroup->responses), " $responsegroup responses." ;
	}
    '';
}

sub EXTEND_RESPONSE { # for radio buttons and checkboxes
	my $ans_label  = shift;
	my $response_label = shift;
	my $ans_value  = shift;
	my $selected   = shift;
	# warn "\n\nin PG.pl \nanslabel $ans_label responselabel $response_label value $ans_value";
	if (defined ($PG->{PG_ANSWERS_HASH}->{$ans_label}) ) {
		my $responsegroup = $PG->{PG_ANSWERS_HASH}->{$ans_label}->{response};
		$responsegroup->extend_response($response_label, $ans_value,$selected);
		# warn "\n$responsegroup responses are now ", pretty_print($response_group);
	}
    '';
}

sub ENDDOCUMENT {
	# Insert MathQuill responses if MathQuill is enabled.  Add responses to each answer's response group that store the
	# latex form of the students' answers and add corresponding hidden input boxes to the page.
	if ($envir{useMathQuill}) {
		for my $answerLabel (keys %{$PG->{PG_ANSWERS_HASH}}) {
			my $answerGroup = $PG->{PG_ANSWERS_HASH}{$answerLabel};
			my $mq_opts = $answerGroup->{ans_eval}{rh_ans}{mathQuillOpts} // {};

			# This is a special case for multi answers.  This is used to obtain mathQuillOpts set
			# specifically for individual parts.
			my $multiAns;
			my $part;
			if ($answerGroup->{ans_eval}{rh_ans}{type} =~ /MultiAnswer(?:\((\d*)\))?/) {
				# This will only be set if singleResult is not enabled.
				$part = $1;
				# The MultiAnswer object passes itself as the first optional argument to the evaluator it creates.
				# Loop through the evaluators to find it.
				for (@{$answerGroup->{ans_eval}{evaluators}}) {
					$multiAns = $_->[1] if (ref($_->[1]) && ref($_->[1]) eq "parser::MultiAnswer");
				}
				# Pass the mathQuillOpts of the main MultiAnswer object on to each part
				# (unless the part already has the option set).
				if (defined $multiAns) {
					for (@{$multiAns->{cmp}}) {
						$_->rh_ans(mathQuillOpts => $mq_opts) unless defined $_->{rh_ans}{mathQuillOpts};
					}
				}
			}

			next if $mq_opts =~ /^\s*disabled\s*$/i;

			my $response_obj = $answerGroup->response_obj;
			my $responseCount = -1;
			for my $response ($response_obj->response_labels) {
				++$responseCount;
				next if ref($response_obj->{responses}{$response});

				my $ansHash = defined $multiAns
					? $multiAns->{cmp}[$part // $responseCount]{rh_ans}
					: $answerGroup->{ans_eval}{rh_ans};
				my $mq_part_opts = $ansHash->{mathQuillOpts} // $mq_opts;
				next if $mq_part_opts =~ /^\s*disabled\s*$/i;

				my $context = $ansHash->{correct_value}->context if $ansHash->{correct_value};
				$mq_part_opts->{rootsAreExponents} = 0
					if $context && $context->functions->get('root') && !defined $mq_part_opts->{rootsAreExponents};

				my $name = "MaThQuIlL_$response";
				my $answer_value = '';
				$answer_value = $inputs_ref->{$name} if defined($inputs_ref->{$name});
				RECORD_EXTRA_ANSWERS($name);
				$answer_value = encode_pg_and_html($answer_value);
				my $data_mq_opts = scalar(keys %$mq_part_opts)
					? qq!data-mq-opts="@{[encode_pg_and_html(JSON->new->encode($mq_part_opts))]}"!
					: "";
				TEXT(MODES(
					TeX => "",
					PTX => "",
					HTML => qq!<input type=hidden name="$name" id="$name" value="$answer_value" $data_mq_opts>!
				));
			}
		}
	}

	# check that answers match
	# gather up PG_FLAGS elements

    $PG->{flags}->{showPartialCorrectAnswers}      = defined($showPartialCorrectAnswers)?  $showPartialCorrectAnswers : 1 ;
	$PG->{flags}->{recordSubmittedAnswers}         = defined($recordSubmittedAnswers)?     $recordSubmittedAnswers    : 1 ;
	$PG->{flags}->{refreshCachedImages}            = defined($refreshCachedImages)?        $refreshCachedImages       : 0 ;
	$PG->{flags}->{hintExists}                     = defined($hintExists)?                 $hintExists                : 0 ;
	$PG->{flags}->{solutionExists}                 = defined($solutionExists)?             $solutionExists            : 0 ;
	$PG->{flags}->{comment}                        = defined($pgComment)?                  $pgComment                 :'' ;
    $PG->{flags}->{showHintLimit}                  = defined($showHint)?                   $showHint                  : 0 ;


	# install problem grader
	if (defined($PG->{flags}->{PROBLEM_GRADER_TO_USE})  ) {
		# problem grader defined within problem -- no further action needed
	} elsif ( defined( $rh_envir->{PROBLEM_GRADER_TO_USE} ) ) {
		if (ref($rh_envir->{PROBLEM_GRADER_TO_USE}) eq 'CODE' ) {         # user defined grader
			$PG->{flags}->{PROBLEM_GRADER_TO_USE} = $rh_envir->{PROBLEM_GRADER_TO_USE};
		} elsif ($rh_envir->{PROBLEM_GRADER_TO_USE} eq 'std_problem_grader' ) {
			if (defined(&std_problem_grader) ){
				$PG->{flags}->{PROBLEM_GRADER_TO_USE} = \&std_problem_grader; # defined in PGanswermacros.pl
			} # std_problem_grader is the default in any case so don't give a warning.
		} elsif ($rh_envir->{PROBLEM_GRADER_TO_USE} eq 'avg_problem_grader' ) {
			if (defined(&avg_problem_grader) ){
				$PG->{flags}->{PROBLEM_GRADER_TO_USE} = \&avg_problem_grader; # defined in PGanswermacros.pl
			}
		} else {
			warn "Error:  ". $PG->{flags}->{PROBLEM_GRADER_TO_USE} . "is not a known program grader.";
		}
	} elsif (defined(&std_problem_grader)) {
		$PG->{flags}->{PROBLEM_GRADER_TO_USE} = \&std_problem_grader; # defined in PGanswermacros.pl
	} else {
		# PGtranslator will install its default problem grader
	}

	# add javaScripts
	if ($rh_envir->{displayMode} eq 'HTML_jsMath') {
		TEXT('<script> jsMath.wwProcess() </script>');
	} elsif ($rh_envir->{displayMode} eq 'HTML_asciimath') {
		TEXT('<script> translate() </script>');
		my $STRING = join("", @{$PG->{HEADER_ARRAY} });
		unless ($STRING =~ m/mathplayer/) {
			HEADER_TEXT('<object id="mathplayer" classid="clsid:32F66A20-7614-11D4-BD11-00104BD3F987">' . "\n" .
						'</object><?import namespace="mml" implementation="#mathplayer"?>'
			);
		}

	}
	TEXT( MODES(%{$rh_envir->{problemPostamble}}) );





	@PG_ANSWERS=();
	if ( 0 or # allow one to force debug output  manually
		($inputs_ref->{showResourceInfo})//'' and ($rh_envir->{permissionLevel})>= 5) {
		my %resources = %{$PG->{PG_alias}->{resource_list}};
		my $str = '';
		my @resource_names=();
		foreach my $key (keys %resources) {
			$str .= knowlLink("$key$BR", value=>"$key$BR".pretty_print($resources{$key})."$BR$BR", base64=>0);
			push @resource_names, $key;
		}
		if ($str eq '') {
			$str = "No auxiliary resources<br/>";
		} else {
			my $summary = "## RESOURCES('".join("','", @resource_names)."')$BR\n";
			$PG->debug_message($summary.$str) ;
		}
	}
	if ( 0 or # allow one to force debug output  manually
	    ($inputs_ref->{showPGInfo} and ($permissionLevel >=10)) ){
 	     my $context = $$Value::context->{flags};
 	     $PG->debug_message("PGbasicmacros.pl 2184: ",
 	   			$HR,"Form variables",$BR,
 	   			pretty_print($inputs_ref),
				$HR,"Environment variables", $BR,
				pretty_print(\%envir),
                $HR,"Context flags",$BR,
				pretty_print($context),
		  ) ;
 	}


	#warn keys %{ $PG->{PG_ANSWERS_HASH} };
	@PG_ANSWER_ENTRY_ORDER = ();
	my $ans_debug = 0;
	foreach my $key (keys %{ $PG->{PG_ANSWERS_HASH} }) {
	        $answergroup = $PG->{PG_ANSWERS_HASH}->{$key};
	        #warn "$key is defined =", defined($answergroup), "PG object is $PG";
	        #################
	        # EXTRA ANSWERS KLUDGE
	        #################
	        # The first response in each answer group is placed in @PG_ANSER_ENTRY_ORDER and %PG_ANSWERS_HASH
	        # The remainder of the response keys are placed in the EXTRA ANSWERS ARRAY
	        if (defined($answergroup)) {
	            my @response_keys = $answergroup->{response}->response_labels;
	            if ( 0 or # allow one to force debug output  manually
	               ($inputs_ref->{showAnsGroupInfo})//0 and ($rh_envir->{permissionLevel})>= 5) {
	            	$PG->debug_message("PG.pl 418: ", pretty_print($answergroup) ) ;
	            	$PG->debug_message("PG.pl 389: ", pretty_print($answergroup->{response}));
	            }
	            my $response_key = $response_keys[0];
	            my $answer_key = $answergroup->{ans_label};
	            #unshift @response_keys, $response_key unless ($response_key eq $answer_group->{ans_label});
	            # don't save the first response key if it is the same as the ans_label
	            # maybe we should insure that the first response key is always the same as the answer label?
	  #          warn "first response key label and answer key label don't agree"
	  #                 unless ($response_key eq $answer_key);

	            # even if no answer blank is printed for it? or a hidden answer blank?
	            # this is still a KLUDGE
	            # for compatibility the first response key is closer to the old method than the $ans_label
	            # this is because a response key might indicate an array but an answer label won't
	            #push @PG_ANSWERS, $response_key,$answergroup->{ans_eval};
	            $PG_ANSWERS_HASH{$answer_key} = $answergroup->{ans_eval};
	            push @PG_ANSWER_ENTRY_ORDER, $answer_key;
	            # @KEPT_EXTRA_ANSWERS could be replaced by saving all of the responses for this answergroup
	            push @KEPT_EXTRA_ANSWERS, @response_keys;
			} else {
			    warn "$key is ", join("|",%{$PG->{PG_ANSWERS_HASH}->{$key}});
			}
	}
	push @KEPT_EXTRA_ANSWERS, keys %{$PG->{PERSISTENCE_HASH}};
	#Hackish way to store other persistence data
	$PG->{flags}->{KEPT_EXTRA_ANSWERS} = \@KEPT_EXTRA_ANSWERS;
	$PG->{flags}->{ANSWER_ENTRY_ORDER} = \@PG_ANSWER_ENTRY_ORDER;

	# these should not be needed any longer since PG_alias warning queue is attached to PGcore's
	# $PG->warning_message( @{ $PG->{PG_alias}->{flags}->{WARNING_messages}} );
	# $PG->debug_message( @{ $PG->{PG_alias}->{flags}->{DEBUG_messages}}   );


    warn "KEPT_EXTRA_ANSWERS", join(" ", @KEPT_EXTRA_ANSWERS), $BR     if $ans_debug==1;
    warn "PG_ANSWER_ENTRY_ORDER",join(" ",@PG_ANSWER_ENTRY_ORDER), $BR if $ans_debug==1;
    # not needed for the moment:
    # warn "DEBUG messages", join( "$BR",@{$PG->get_debug_messages} ) if $ans_debug==1;
    warn "INTERNAL_DEBUG messages", join( "$BR",@{$PG->get_internal_debug_messages} ) if $ans_debug==1;
	$STRINGforOUTPUT      = join("", @{$PG->{OUTPUT_ARRAY} });
	$STRINGforHEADER_TEXT = join("", @{$PG->{HEADER_ARRAY} });
    $STRINGforPOSTHEADER_TEXT = join("", @{$PG->{POST_HEADER_ARRAY} });
	# warn pretty_print($PG->{PG_ANSWERS_HASH});
	#warn "printing another warning";

	(\$STRINGforOUTPUT, \$STRINGforHEADER_TEXT,\$STRINGforPOSTHEADER_TEXT,\%PG_ANSWERS_HASH,  $PG->{flags} , $PG   );
}


sub alias {
    #warn "alias called ",@_;
    $PG->{PG_alias}->make_alias(@_)  ;
}

sub get_resource {
	$PG->{PG_alias}->get_resource(@_);
}

sub maketext {
    $PG->maketext(@_);
}

sub insertGraph {
	$PG->insertGraph(@_);
}

sub findMacroFile {
	$PG->{PG_alias}->findMacroFile(@_);
}

sub check_url {
	$PG->{PG_alias}->check_url(@_);
}

sub findAppletCodebase {
    my $appletName = shift;
	my $url = eval{$PG->{PG_alias}->findAppletCodebase($appletName)};
	# warn is already trapped under the old system
	$PG->warning_message("While using findAppletCodebase  to search for applet$appletName:  $@") if $@;
	$url;
}

sub loadMacros {
	$PG->{PG_loadMacros}->loadMacros(@_);
}


=head2 Problem Grader Subroutines

=cut

## Problem Grader Subroutines

#####################################
# This is a model for plug-in problem graders
#####################################
# ^function install_problem_grader
# ^uses PG_restricted_eval
# ^uses %PG_FLAGS{PROBLEM_GRADER_TO_USE}
sub install_problem_grader {
	my $rf_problem_grader =	shift;
	my $rh_flags = $PG->{flags};
	$rh_flags->{PROBLEM_GRADER_TO_USE} = $rf_problem_grader if not_null($rf_problem_grader) ;
	$rh_flags->{PROBLEM_GRADER_TO_USE};
}

sub current_problem_grader {
	install_problem_grader(@_);
}

#  FIXME? The following functions were taken from the former
#  dangerousMacros.pl file and might have issues when placed here.
#
#  Some constants that can be used in perl expressions
#

# ^function i
# ^uses $_parser_loaded
# ^uses &Complex::i
# ^uses &Value::Package
sub i () {
  #  check if Parser.pl is loaded, otherwise use Complex package
  if (!eval(q!$main::_parser_loaded!)) {return Complex::i}
  return Value->Package("Formula")->new('i')->eval;
}

# ^function j
# ^uses $_parser_loaded
# ^uses &Value::Package
sub j () {
  if (!eval(q!$main::_parser_loaded!)) {return 'j'}
  Value->Package("Formula")->new('j')->eval;
}

# ^function k
# ^uses $_parser_loaded
# ^uses &Value::Package
sub k () {
  if (!eval(q!$main::_parser_loaded!)) {return 'k'}
  Value->Package("Formula")->new('k')->eval;
}

# ^function pi
# ^uses $_parser_loaded
# ^uses &Value::Package
sub pi () {
  if (!eval(q!$main::_parser_loaded!)) {return 4*atan2(1,1)}
  Value->Package("Formula")->new('pi')->eval;
}

# ^function Infinity
# ^uses $_parser_loaded
# ^uses &Value::Package
sub Infinity () {
  if (!eval(q!$main::_parser_loaded!)) {return 'Infinity'}
  Value->Package("Infinity")->new();
}


# ^function abs
# ^function sqrt
# ^function exp
# ^function log
# ^function sin
# ^function cos
# ^function atan2
#
#  Allow these functions to be overridden without complaint.
#  (needed for log() to implement $useBaseTenLog)
#
use subs 'abs', 'sqrt', 'exp', 'log', 'sin', 'cos', 'atan2', 'ParserDefineLog';
sub abs($)  {return CORE::abs($_[0])};
sub sqrt($) {return CORE::sqrt($_[0])};
sub exp($)  {return CORE::exp($_[0])};
#sub log($)  {return CORE::log($_[0])};
sub sin($)  {return CORE::sin($_[0])};
sub cos($)  {return CORE::cos($_[0])};
sub atan2($$) {return CORE::atan2($_[0],$_[1])};

# used to be Parser::defineLog -- but that generated redefined notices
sub ParserDefineLog {eval {sub log($) {CommonFunction->Call("log",@_)}}};

=head2 Filter utilities

These two subroutines can be used in filters to set default options.  They
help make filters perform in uniform, predictable ways, and also make it
easy to recognize from the code which options a given filter expects.


=head4 assign_option_aliases

Use this to assign aliases for the standard options.  It must come before set_default_options
within the subroutine.

		assign_option_aliases(\%options,
				'alias1'	=> 'option5'
				'alias2'	=> 'option7'
		);


If the subroutine is called with an option  " alias1 => 23 " it will behave as if it had been
called with the option " option5 => 23 "

=cut


# ^function assign_option_aliases
sub assign_option_aliases {
	my $rh_options = shift;
	warn "The first entry to set_default_options must be a reference to the option hash" unless ref($rh_options) eq 'HASH';
	my @option_aliases = @_;
	while (@option_aliases) {
		my $alias = shift @option_aliases;
		my $option_key = shift @option_aliases;

		if (defined($rh_options->{$alias} )) {                       # if the alias appears in the option list
			if (not defined($rh_options->{$option_key}) ) {          # and the option itself is not defined,
				$rh_options->{$option_key} = $rh_options->{$alias};  # insert the value defined by the alias into the option value
				                                                     # the FIRST alias for a given option takes precedence
				                                                     # (after the option itself)
			} else {
				warn "option $option_key is already defined as", $rh_options->{$option_key}, "<br>\n",
				     "The attempt to override this option with the alias $alias with value ", $rh_options->{$alias},
				     " was ignored.";
			}
		}
		delete($rh_options->{$alias});                               # remove the alias from the initial list
	}

}

=head4 set_default_options

		set_default_options(\%options,
				'_filter_name'	=>	'filter',
				'option5'		=>  .0001,
				'option7'		=>	'ascii',
				'allow_unknown_options	=>	0,
		}

Note that the first entry is a reference to the options with which the filter was called.

The option5 is set to .0001 unless the option is explicitly set when the subroutine is called.

The B<'_filter_name'> option should always be set, although there is no error if it is missing.
It is used mainly for debugging answer evaluators and allows
you to keep track of which filter is currently processing the answer.

If B<'allow_unknown_options'> is set to 0 then if the filter is called with options which do NOT appear in the
set_default_options list an error will be signaled and a warning message will be printed out.  This provides
error checking against misspelling an option and is generally what is desired for most filters.

Occasionally one wants to write a filter which accepts a long list of options, not all of which are known in advance,
but only uses a subset of the options
provided.  In this case, setting 'allow_unkown_options' to 1 prevents the error from being signaled.

=cut

# ^function set_default_options
# ^uses pretty_print
sub set_default_options {
	my $rh_options = shift;
	warn "The first entry to set_default_options must be a reference to the option hash" unless ref($rh_options) eq 'HASH';
	my %default_options = @_;
	unless ( defined($default_options{allow_unknown_options}) and $default_options{allow_unknown_options} == 1 ) {
		foreach  my $key1 (keys %$rh_options) {
			warn "This option |$key1| is not recognized in this subroutine<br> ", pretty_print($rh_options) unless exists($default_options{$key1});
		}
	}
	foreach my $key (keys %default_options) {
		if  ( not defined($rh_options->{$key} ) and defined( $default_options{$key} )  ) {
			$rh_options->{$key} = $default_options{$key};  #this allows     tol   => undef to allow the tol option, but doesn't define
			                                               # this key unless tol is explicitly defined.
		}
	}
}

=over

=item includePGproblem($filePath)

 includePGproblem($filePath);

 Essentially runs the pg problem specified by $filePath, which is
 a path relative to the top of the templates directory.  The output
 of that problem appears in the given problem.

=back

=cut

# ^function includePGproblem
# ^uses %envir
# ^uses &read_whole_problem_file
# ^uses &includePGtext
sub includePGproblem {
    my $filePath = shift;
    my %save_envir = %main::envir;
    my $fullfilePath = $PG->envir("templateDirectory").$filePath;
    my $r_string    =  $PG->read_whole_problem_file($fullfilePath);
    if (ref($r_string) eq 'SCALAR') {
        $r_string = $$r_string;
    }

	# The problem calling this should provide DOCUMENT and ENDDOCUMENT,
	# so we remove them from the included file.
    $r_string=~ s/^\s*(END)?DOCUMENT(\(\s*\));?//gm;

	# Reset the problem path so that static images can be found via
	# their relative paths.
    eval('$main::envir{probFileName} = $filePath');
    eval('$main::envir{fileName} = $filePath');
    # now update the PGalias object
    my $save_PGalias = $PG->{PG_alias};
    my $temp_PGalias = PGalias ->new( \%main::envir,
                                      WARNING_messages => $PG->{WARNING_messages},
                                      DEBUG_messages  => $PG->{DEBUG_messages},
    );
    $PG->{PG_alias}=$temp_PGalias;
    $PG->includePGtext($r_string);
    # Reset the environment to what it was before.
    %main::envir = %save_envir;
    $PG->{PG_alias}=$save_PGalias;
}

sub beginproblem;  # announce that beginproblem is a macro

1;
__END__

################################################################################
# WeBWorK Online Homework Delivery System
# Copyright &copy; 2000-2022 The WeBWorK Project, https://github.com/openwebwork
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of either: (a) the GNU General Public License as published by the
# Free Software Foundation; either version 2, or (at your option) any later
# version, or (b) the "Artistic License" which comes with this package.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See either the GNU General Public License or the
# Artistic License for more details.
################################################################################

=head1 NAME

PG.pl - Provides core Program Generation Language functionality.

=head1 SYNPOSIS

In a PG problem:

	DOCUMENT();             # should be the first statment in the problem

	loadMacros(.....);      # (optional) load other macro files if needed.

	HEADER_TEXT(...);       # (optional) used only for inserting javaScript into problems.

	TEXT(                   # insert text of problems
		"Problem text to be displayed. ",
		"Enter 1 in this blank:",
		ANS_RULE(1,30)      # ANS_RULE() defines an answer blank 30 characters long.
 		                	# It is defined in F<PGbasicmacros.pl>
	);

	ANS(answer_evalutors);  # see F<PGanswermacros.pl> for examples of answer evaluatiors.

	ENDDOCUMENT()           # must be the last statement in the problem

=head1 DESCRIPTION

This file provides the fundamental macros that define the PG language. It
maintains a problem's text, header text, and answers:

=over

=item *

Problem text: The text to appear in the body of the problem. See TEXT()
below.

=item *

Header text: When a problem is processed in an HTML-based display mode,
this variable can contain text that the caller should place in the HEAD of the
resulting HTML page. See HEADER_TEXT() below.

=item *

Implicitly-labeled answers: Answers that have not been explicitly
assigned names, and are associated with their answer blanks by the order in
which they appear in the problem. These types of answers are designated using
the ANS() macro.

=item *

Explicitly-labeled answers: Answers that have been explicitly assigned
names with the LABELED_ANS() macro, or a macro that uses it. An explicitly-
labeled answer is associated with its answer blank by name.

=item *

"Extra" answers: Names of answer blanks that do not have a 1-to-1
correspondance to an answer evaluator. For example, in matrix problems, there
will be several input fields that correspond to the same answer evaluator.

=back

=head1 USAGE

This file is automatically loaded into the namespace of every PG problem. The
macros within can then be called to define the structure of the problem.

DOCUMENT() should be the first executable statement in any problem. It
initializes vriables and defines the problem environment.

ENDDOCUMENT() must be the last executable statement in any problem. It packs
up the results of problem processing for delivery back to WeBWorK.

The HEADER_TEXT(), TEXT(), and ANS() macros add to the header text string,
body text string, and answer evaluator queue, respectively.

=over

=item HEADER_TEXT()

 HEADER_TEXT("string1", "string2", "string3");

HEADER_TEXT() concatenates its arguments and appends them to the stored header
text string. It can be used more than once in a file.

The macro is used for material which is destined to be placed in the HEAD of
the page when in HTML mode, such as JavaScript code.

Spaces are placed between the arguments during concatenation, but no spaces are
introduced between the existing content of the header text string and the new
content being appended.



=item TEXT()

 TEXT("string1", "string2", "string3");

TEXT() concatenates its arguments and appends them to the stored problem text
string. It is used to define the text which will appear in the body of the
problem. It can be used more than once in a file.

This macro has no effect if rendering has been stopped with the STOP_RENDERING()
macro.

This macro defines text which will appear in the problem. All text must be
passed to this macro, passed to another macro that calls this macro, or included
in a BEGIN_TEXT/END_TEXT block, which uses this macro internally. No other
statements in a PG file will directly appear in the output. Think of this as the
"print" function for the PG language.

Spaces are placed between the arguments during concatenation, but no spaces are
introduced between the existing content of the header text string and the new
content being appended.



=item ANS()

 TEXT(ans_rule(), ans_rule(), ans_rule());
 ANS($answer_evaluator1, $answer_evaluator2, $answer_evaluator3);

Adds the answer evaluators listed to the list of unlabeled answer evaluators.
They will be paired with unlabeled answer rules (a.k.a. answer blanks) in the
order entered. This is the standard method for entering answers.

In the above example, answer_evaluator1 will be associated with the first
answer rule, answer_evaluator2 with the second, and answer_evaluator3 with the
third. In practice, the arguments to ANS() will usually be calls to an answer
evaluator generator such as the cmp() method of MathObjects or the num_cmp()
macro in L<PGanswermacros.pl>.



=item LABELED_ANS()

 TEXT(labeled_ans_rule("name1"), labeled_ans_rule("name2"));
 LABELED_ANS(name1 => answer_evaluator1, name2 => answer_evaluator2);

Adds the answer evaluators listed to the list of labeled answer evaluators.
They will be paired with labeled answer rules (a.k.a. answer blanks) in the
order entered. This allows pairing of answer evaluators and answer rules that
may not have been entered in the same order.




=item STOP_RENDERING()

 STOP_RENDERING() unless all_answers_are_correct();

Temporarily suspends accumulation of problem text and storing of answer blanks
and answer evaluators until RESUME_RENDERING() is called.



=item RESUME_RENDERING()

 RESUME_RENDERING();

Resumes accumulating problem text and storing answer blanks and answer
evaluators. Reverses the effect of STOP_RENDERING().



=item ENDDOCUMENT()

 ENDDOCUMENT();

When PG problems are evaluated, the result of evaluating the entire problem is
interpreted as the return value of ENDDOCUMENT(). Therefore, ENDDOCUMENT() must
be the last executable statement of every problem. It can only appear once. It
returns a list consisting of:

=back

=over

=item *

A reference to a string containing the rendered text of the problem.

=item *

A reference to a string containing text to be placed in the HEAD block
when in and HTML-based mode (e.g. for JavaScript).

=item *

A reference to the hash mapping answer labels to answer evaluators.

=item *

A reference to a hash containing various flags:



=item *

C<showPartialCorrectAnswers>: determines whether students are told which of their answers in a problem are wrong.

=item *

C<recordSubmittedAnswers>: determines whether students submitted answers are saved.

=item *

C<refreshCachedImages>: determines whether the cached image of the problem in typeset mode is always refreshed
(i.e. setting this to 1 means cached images are not used).

=item *

C<solutionExits>: indicates the existence of a solution.

=item *

C<hintExits>: indicates the existence of a hint.

=item *

C<comment>: contents of COMMENT commands if any.

=item *

C<showHintLimit>: determines the number of attempts after which hint(s) will be shown

=item *

C<PROBLEM_GRADER_TO_USE>: a reference to the chosen problem grader.
ENDDOCUMENT chooses the problem grader as follows:

=over

=item *

If a problem grader has been chosen in the problem by calling
C<install_problem_grader(\&grader)>, it is used.

=item *

Otherwise, if the C<PROBLEM_GRADER_TO_USE> PG environment variable
contains a reference to a subroutine, it is used.

=item *

Otherwise, if the C<PROBLEM_GRADER_TO_USE> PG environment variable
contains the string C<std_problem_grader> or the string C<avg_problem_grader>,
C<&std_problem_grader> or C<&avg_problem_grader> are used. These graders are defined
in L<PGanswermacros.pl>.

=item *

Otherwise, the PROBLEM_GRADER_TO_USE flag will contain an empty value
and the PG translator should select C<&std_problem_grader>.

=back

=back



=cut


################################################################################

=head1 PRIVATE MACROS

These macros should only be used by other macro files. In practice, they are
used exclusively by L<PGbasicmacros.pl>.

=over

=item inc_ans_rule_count()

DEPRECATED

Increments the internal count of the number of answer blanks that have been
defined ($ans_rule_count) and returns the new count. This should only be used
when one is about to define a new answer blank, for example with NEW_ANS_NAME().

=cut

=item RECORD_ANS_NAME()

 RECORD_ANS_NAME("label", "VALUE");

Records the label for an answer blank. Used internally by L<PGbasicmacros.pl>
to record the order of explicitly-labelled answer blanks.

=cut

=item NEW_ANS_NAME()

 NEW_ANS_NAME();

Generates an anonymous answer label from the internal count The label is
added to the list of implicity-labeled answers. Used internally by
L<PGbasicmacros.pl> to generate labels for unlabeled answer blanks.

=cut

=item ANS_NUM_TO_NAME()

 ANS_NUM_TO_NAME($num);

Generates an answer label from the supplied answer number, but does not add it
to the list of inplicitly-labeled answers. Used internally by
L<PGbasicmacros.pl> in generating answers blanks that use radio buttons or
check boxes. (This type of answer blank uses multiple HTML INPUT elements with
the same label, but the label should only be added to the list of implicitly-
labeled answers once.)

=cut

=item RECORD_FROM_LABEL()

 RECORD_FORM_LABEL("label");

Stores the label of a form field in the "extra" answers list. This is used to
keep track of answer blanks that are not associated with an answer evaluator.

=cut

=item NEW_ANS_ARRAY_NAME()

 NEW_ANS_ARRAY_NAME($num, $row, $col);

Generates a new answer label for an array (vector) element and adds it to the
list of implicitly-labeled answers.

=cut

=item NEW_ANS_ARRAY_NAME_EXTENSION()

 NEW_ANS_ARRAY_NAME_EXTENSION($num, $row, $col);

Generate an additional answer label for an existing array (vector) element and
add it to the list of "extra" answers.

=cut

=item get_PG_ANSWERS_HASH()

 get_PG_ANSWERS_HASH();
 get_PG_ANSWERS_HASH($key);



=cut

=item includePGproblem($filePath)

 includePGproblem($filePath);

 Essentially runs the pg problem specified by $filePath, which is
 a path relative to the top of the templates directory.  The output
 of that problem appears in the given problem.

=cut

=back

=head1 SEE ALSO

L<PGbasicmacros.pl>, L<PGanswermacros.pl>.

=cut




1;
