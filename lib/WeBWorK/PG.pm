package WeBWorK::PG;

use strict;
use warnings;

use YAML::XS qw(LoadFile);

my $TRANSLATOR_LOADED = 0;
my $ANSWERHASH_PATCHED = 0;

sub _patch_answerhash {
    return if $ANSWERHASH_PATCHED;
    eval { require AnswerHash; 1 } or return;

    no warnings 'redefine';
    my $orig = \&AnswerHash::stringify_hash;
    *AnswerHash::stringify_hash = sub {
        my $self = shift;
        if ($self->{correct_value}
            && !(ref($self->{correct_value}) && eval { $self->{correct_value}->can('context') })) {
            local $self->{correct_value} = undef;
            return $orig->($self);
        }
        return $orig->($self);
    };
    $ANSWERHASH_PATCHED = 1;
}

sub _wrap_safety_filter {
    my ($translator) = @_;
    return if $translator->{render_app_safety_filter_wrapped};

    my $orig_filter = $translator->rf_safety_filter;
    return unless $orig_filter && ref($orig_filter) eq 'CODE';

    $translator->rf_safety_filter(sub {
        my $answer = shift;
        if (ref($answer) eq 'HASH') {
            my @tmp = ();
            foreach my $key (sort keys %{$answer}) {
                push @tmp, $key if defined $answer->{$key} && $answer->{$key} eq 'CHECKED';
            }
            $answer = join("\0", @tmp);
        }
        return $orig_filter->($answer);
    });

    $translator->{render_app_safety_filter_wrapped} = 1;
}

sub _require_translator {
    return if $TRANSLATOR_LOADED;

    my $have_course_env = 0;
    eval {
        require WeBWorK::CourseEnvironment;
        $have_course_env = 1;
    };

    if (!$have_course_env && exists $ENV{MOJO_MODE}) {
        local $ENV{MOJO_MODE};
        delete $ENV{MOJO_MODE};
        require WeBWorK::PG::Translator;
    } else {
        require WeBWorK::PG::Translator;
    }

    _patch_answerhash();

    $TRANSLATOR_LOADED = 1;
}

sub DISPLAY_MODES {
    return {
        tex       => 'TeX',
        plainText => 'HTML',
        images    => 'HTML_dpng',
        MathJax   => 'HTML_MathJax',
        PTX       => 'PTX',
    };
}

sub new {
    my ($invocant, %options) = @_;
    _require_translator();
    my $class = ref($invocant) || $invocant;
    my $pg = eval { $class->new_helper(%options) };
    die $@ if $@;
    return $pg;
}

sub new_helper {
    my ($invocant, %options) = @_;
    my $class = ref($invocant) || $invocant;

    my $pg_envir = _load_pg_config();

    $options{sourceFilePath}    //= '';
    $options{templateDirectory} //= '';
    $options{inputs_ref}        //= {};

    my $warning_messages = '';
    if ($pg_envir->{options}{catchWarnings}) {
        local $SIG{__WARN__} = sub { $warning_messages .= shift; return; };
    }

    my $image_generator;
    if (($options{displayMode} // '') eq 'images') {
        require WeBWorK::PG::ImageGenerator;
        $image_generator = WeBWorK::PG::ImageGenerator->new(
            tempDir         => $pg_envir->{directories}{tmp},
            latex           => $pg_envir->{externalPrograms}{latex},
            dvipng          => $pg_envir->{externalPrograms}{dvipng},
            useCache        => 1,
            cacheDir        => $pg_envir->{directories}{equationCache},
            cacheURL        => $pg_envir->{URLs}{equationCache},
            cacheDB         => $pg_envir->{equationCacheDB},
            useMarkers      => 1,
            dvipng_align    => $pg_envir->{displayModeOptions}{images}{dvipng_align},
            dvipng_depth_db => $pg_envir->{displayModeOptions}{images}{dvipng_depth_db},
        );
    }

    my $translator;
    {
        local $ENV{MOJO_MODE};
        delete $ENV{MOJO_MODE};

        $translator = WeBWorK::PG::Translator->new;
        _wrap_safety_filter($translator);

        if (ref($pg_envir->{modules}) eq 'ARRAY') {
            for my $module_packages_ref (@{ $pg_envir->{modules} }) {
                my ($module, @extra_packages) = @$module_packages_ref;
                $translator->evaluate_modules($module);
                $translator->load_extra_packages(@extra_packages) if @extra_packages;
            }
        }

        $translator->environment(defineProblemEnvironment($pg_envir, \%options, $image_generator));
        $translator->initialize;

        my $macro_err = $translator->unrestricted_load($pg_envir->{directories}{root} . '/macros/PG.pl');
        warn "Error while loading macros/PG.pl: $macro_err" if $macro_err;

        $translator->set_mask;
    }

    if (ref $options{r_source}) {
        $translator->source_string(${ $options{r_source} });
    } elsif ($options{sourceFilePath}) {
        my $sourceFilePath =
            $options{sourceFilePath} =~ /^\//
            ? $options{sourceFilePath}
            : "$options{templateDirectory}$options{sourceFilePath}";

        eval { $translator->source_file($sourceFilePath) };
        if ($@) {
            return bless {
                translator       => $translator,
                head_text        => '',
                post_header_text => '',
                body_text        => "Unabled to read problem source file:\n$@\n",
                answers          => {},
                result           => {},
                state            => {},
                errors           => 'Failed to read the problem source file.',
                warnings         => $warning_messages,
                flags            => { error_flag => 1 },
                pgcore           => $translator->{rh_pgcore},
            }, $class;
        }
    }

    $translator->translate;

    my ($result, $state);
    if ($options{processAnswers}) {
        $translator->process_answers;

        $translator->rh_problem_state({
            recorded_score       => $options{recorded_score}       // 0,
            num_of_correct_ans   => $options{num_of_correct_ans}   // 0,
            num_of_incorrect_ans => $options{num_of_incorrect_ans} // 0
        });

        my @answerOrder =
            $translator->rh_flags->{ANSWER_ENTRY_ORDER}
            ? @{ $translator->rh_flags->{ANSWER_ENTRY_ORDER} }
            : keys %{ $translator->rh_evaluated_answers };

        my $grader = $translator->rh_flags->{PROBLEM_GRADER_TO_USE} || 'avg_problem_grader';
        $grader = $translator->rf_std_problem_grader if $grader eq 'std_problem_grader';
        $grader = $translator->rf_avg_problem_grader if $grader eq 'avg_problem_grader';
        die "Problem grader $grader is not a CODE reference." unless ref $grader eq 'CODE';
        $translator->rf_problem_grader($grader);

        ($result, $state) = $translator->grade_problem(
            answers_submitted  => 1,
            ANSWER_ENTRY_ORDER => \@answerOrder,
            %{ $options{inputs_ref} }
        );
    }

    if ($image_generator) {
        $image_generator->render(
            refresh   => $options{refreshMath2img} // 0,
            body_text => $translator->r_text,
        );
    }

    $translator->stringify_answers;

    return bless {
        translator       => $translator,
        head_text        => ${ $translator->r_header },
        post_header_text => ${ $translator->r_post_header },
        body_text        => ${ $translator->r_text },
        answers          => $translator->rh_evaluated_answers,
        result           => $result,
        state            => $state,
        errors           => $translator->errors,
        warnings         => $warning_messages,
        flags            => $translator->rh_flags,
        pgcore           => $translator->{rh_pgcore}
    }, $class;
}

sub free {
    my ($pg) = @_;
    $pg->{pgcore}{OUTPUT_ARRAY} = [] if ref($pg->{pgcore}) eq 'PGcore';
    $pg->{answers} = {};
    undef $pg->{translator};
    if (ref($pg->{pgcore}) eq 'PGcore') {
        undef $pg->{pgcore}{PG_ANSWERS_HASH}{$_} for (keys %{ $pg->{pgcore}{PG_ANSWERS_HASH} });
    }
    return;
}

sub defineProblemEnvironment {
    my ($pg_envir, $options, $image_generator) = @_;
    $options ||= {};

    my $ansEvalDefaults = $pg_envir->{ansEvalDefaults} ? { %{ $pg_envir->{ansEvalDefaults} } } : {};
    $ansEvalDefaults->{$_} = $options->{ansEvalDefaults}{$_}
        for keys %{ $options->{ansEvalDefaults} // {} };

    my $specialPGEnvironmentVars =
        $pg_envir->{specialPGEnvironmentVars}
        ? { %{ $pg_envir->{specialPGEnvironmentVars} } }
        : {};
    $specialPGEnvironmentVars->{$_} = $options->{specialPGEnvironmentVars}{$_}
        for keys %{ $options->{specialPGEnvironmentVars} // {} };

    my $language = $options->{language} // 'en';
    my $language_subroutine = $options->{language_subroutine};
    if (!defined $language_subroutine) {
        eval { require WeBWorK::Localize; };
        $language_subroutine = WeBWorK::Localize::getLoc($language);
    }

    return {
        %$options,

        probFileName       => $options->{sourceFilePath}                                // '',
        displayMode        => DISPLAY_MODES()->{ $options->{displayMode} || 'MathJax' } // 'HTML_MathJax',
        problemSeed        => $options->{problemSeed} || 1234,
        psvn               => $options->{psvn}               // 1,
        problemUUID        => $options->{problemUUID}        // 0,
        probNum            => $options->{probNum}            // 1,
        showHints          => $options->{showHints}          // 1,
        showSolutions      => $options->{showSolutions}      // 0,
        forceScaffoldsOpen => $options->{forceScaffoldsOpen} // 0,
        setOpen            => $options->{setOpen}            // 1,
        pastDue            => $options->{pastDue}            // 0,
        answersAvailable   => $options->{answersAvailable}   // 0,
        isInstructor       => $options->{isInstructor}       // 0,
        PERSISTENCE_HASH   => $options->{PERSISTENCE_HASH}   // {},

        showFeedback            => $options->{showFeedback}            // 0,
        showAttemptAnswers      => $options->{showAttemptAnswers}      // 1,
        showAttemptPreviews     => $options->{showAttemptPreviews}     // 1,
        forceShowAttemptResults => $options->{forceShowAttemptResults} // 0,
        showAttemptResults      => $options->{showAttemptResults}      // 0,
        showMessages            => $options->{showMessages}            // 1,
        showCorrectAnswers      => $options->{showCorrectAnswers}      // 0,

        PERSISTENCE_HASH_UPDATED => {},

        inputs_ref => $options->{inputs_ref},

        (map { $_ => $ansEvalDefaults->{$_} } keys %$ansEvalDefaults),

        QUIZ_PREFIX           => $options->{answerPrefix} // '',
        PROBLEM_GRADER_TO_USE => $options->{grader}       // $pg_envir->{options}{grader},

        useMathQuill   => $options->{useMathQuill}   // $pg_envir->{options}{useMathQuill},
        useMathView    => $options->{useMathView}    // $pg_envir->{options}{useMathView},
        mathViewLocale => $options->{mathViewLocale} // $pg_envir->{options}{mathViewLocale},

        language            => $language,
        language_subroutine => $language_subroutine,

        pgMacrosDir       => "$pg_envir->{directories}{root}/macros",
        macrosPath        => $options->{macrosPath}        // $pg_envir->{directories}{macrosPath},
        htmlPath          => $options->{htmlPath}          // $pg_envir->{URLs}{htmlPath},
        imagesPath        => $options->{imagesPath}        // $pg_envir->{URLs}{imagesPath},
        htmlDirectory     => $options->{htmlDirectory}     // "$pg_envir->{directories}{html}/",
        htmlURL           => $options->{htmlURL}           // "$pg_envir->{URLs}{html}/",
        templateDirectory => $options->{templateDirectory} // '',
        tempDirectory     => $options->{tempDirectory}     // "$pg_envir->{directories}{html_temp}/",
        tempURL           => $options->{tempURL}           // "$pg_envir->{URLs}{tempURL}/",
        localHelpURL      => $options->{localHelpURL}      // "$pg_envir->{URLs}{localHelpURL}/",

        imagegen => $image_generator,

        use_site_prefix   => $options->{use_site_prefix}   // '',
        use_opaque_prefix => $options->{use_opaque_prefix} // 0,

        __files__ => $options->{__files__} // {
            root => $pg_envir->{directories}{root},
            pg   => $pg_envir->{directories}{root},
            tmpl => $pg_envir->{directories}{root}
        },

        (map { $_ => $specialPGEnvironmentVars->{$_} } keys %$specialPGEnvironmentVars),

        (map { $_ => $options->{debuggingOptions}{$_} } keys %{ $options->{debuggingOptions} // {} }),

        courseName   => $options->{courseName}   // 'pg_local',
        setNumber    => $options->{setNumber}    // 1,
        studentLogin => $options->{studentLogin} // 'pg_local',
        studentName  => $options->{studentName}  // 'pg_local',
        studentID    => $options->{studentID}    // 'pg_local',
    };
}

sub _load_pg_config {
    my $pg_root = $ENV{PG_ROOT} // '';
    my $render_root = $ENV{RENDER_ROOT} // $pg_root;

    my $config_file = "$pg_root/conf/pg_config.yml";
    my $config = -r $config_file ? LoadFile($config_file) : {};
    $config = {} unless ref($config) eq 'HASH';

    $config->{directories} //= {};
    $config->{URLs} //= {};
    $config->{options} //= {};
    $config->{ansEvalDefaults} //= {};
    $config->{specialPGEnvironmentVars} //= {};
    $config->{displayModeOptions} //= {};
    $config->{displayModeOptions}{images} //= {};
    $config->{externalPrograms} //= {};
    $config->{modules} //= [];

    $config->{directories}{root}      //= $pg_root;
    $config->{directories}{html}      //= "$pg_root/htdocs";
    $config->{directories}{tmp}       //= "$render_root/tmp";
    $config->{directories}{html_temp} //= "$render_root/tmp";
    $config->{directories}{equationCache} //= "$render_root/tmp/equations";
    $config->{directories}{permitted_read_dir} //= $render_root;

    $config->{URLs}{html}      //= ($ENV{baseURL} // '') . '/pg_files';
    $config->{URLs}{tempURL}   //= ($ENV{baseURL} // '') . '/pg_files/tmp';
    $config->{URLs}{localHelpURL} //= ($ENV{baseURL} // '') . '/pg_files/helpFiles';
    $config->{URLs}{equationCache} //= ($ENV{baseURL} // '') . '/pg_files/tmp/equations';
    $config->{URLs}{htmlPath}  //= ['.', ($ENV{baseURL} // '') . '/pg_files'];
    $config->{URLs}{imagesPath} //= ['.', ($ENV{baseURL} // '') . '/pg_files/images'];

    $config->{options}{grader}        //= 'avg_problem_grader';
    $config->{options}{useMathQuill}  //= 1;
    $config->{options}{useMathView}   //= 0;
    $config->{options}{mathViewLocale} //= 'mv_locale_us.js';
    $config->{options}{catchWarnings} //= 1;

    $config->{displayModeOptions}{images}{dvipng_align} //= 'baseline';
    $config->{displayModeOptions}{images}{dvipng_depth_db} //= {
        dbsource => '',
        user     => '',
        passwd   => ''
    };

    my $pg_root_url = defined $ENV{baseURL} ? $ENV{baseURL} : '';

    for (1 .. 2) {
        $config = _replace_placeholders(
            $config,
            {
                pg_root     => $pg_root,
                render_root => $render_root,
                pg_root_url => $pg_root_url,
                OPL_dir     => $config->{directories}{OPL},
                Contrib_dir => $config->{directories}{Contrib}
            }
        );
    }

    return $config;
}

sub _replace_placeholders {
    my ($input, $values) = @_;
    if (ref $input eq 'HASH') {
        for (keys %$input) {
            $input->{$_} = _replace_placeholders($input->{$_}, $values);
        }
    } elsif (ref $input eq 'ARRAY') {
        for (0 .. $#$input) {
            $input->[$_] = _replace_placeholders($input->[$_], $values);
        }
    } else {
        $input =~ s/\$(\w+)/defined $values->{$1} ? $values->{$1} : ''/gex;
    }
    return $input;
}

1;
