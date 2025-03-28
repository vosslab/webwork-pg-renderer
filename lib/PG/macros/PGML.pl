######################################################################
######################################################################

package PGML;

sub show {
  ClearWarnings();
  my $parser = PGML::Parse->new(shift);
  warn join("\n","==================","Errors parsing PGML:",@warnings,"==================\n") if scalar(@warnings);
  return $parser->{root}->show;
}

our @warnings = ();
our $warningsFatal = 0;
sub Warning {
  my $warning = join("",@_);
  $warning =~ s/ at line \d+ of \(eval \d+\)//;
  $warning =~ s/ at \(eval \d+\) line \d+//;
  $warning =~ s/, at EOF$//;
  die $warning if $warningsFatal;
  push @warnings,$warning;
}
sub ClearWarnings {@warnings = ()};

sub Eval {main::PG_restricted_eval(@_)}

sub Sort {return main::lex_sort(@_)}

######################################################################

package PGML::Parse;

my $wordStart = qr/[^a-z0-9]/;

my $indent = '^(?:\t|    )+';
my $lineend = '\n+';
my $linebreak = '   ?(?=\n)';
my $heading = '#+';
my $rule = '(?:---+|===+)';
my $list = '(?:^|(?<=[\t ]))(?:[-+o*]|(?:\d|[ivxl]+|[IVXL]+|[a-zA-Z])[.)]) +';
my $align = '>> *| *<<';
my $code = '```';
my $pre = ':   ';
my $emphasis = '\*+|_+';
my $chars = '\\\\.|[{}[\]\'"]';
my $ansrule = '\[(?:_+|[ox^])\]\*?';
my $open = '\[(?:[!<%@$]|::?:?|``?`?|\|+ ?)';
my $close = '(?:[!>%@$]|::?:?|``?`?| ?\|+)\]';
my $noop = '\[\]';

my $splitPattern =
  qr/($indent|$open|$ansrule|$close|$linebreak|$lineend|$heading|$rule|$list|$align|$code|$pre|$emphasis|$noop|$chars)/m;

my %BlockDefs;

sub new {
  my $self = shift; my $class = ref($self) || $self;
  my $string = shift;
  my $parser = bless {
    string => $string,
    indent => 0, actualIndent => 0,
    atLineStart => 1, atBlockStart => 1
  }, $class;
  $parser->Parse($parser->Split($string));
  return $parser;
}

sub Split {
  my $self = shift; my $string = shift;
  $string =~ s!^(?:\t* +|\t+ *)$!!gm;                 # make blank lines blank
  return split($splitPattern,$string);
}

sub Error {
  my $self = shift; my $message = shift;
  my $name = $self->{block}{token}; $name =~ s/^\s+|\s+$//g;
  $message = sprintf($message,$name);
  PGML::Warning $message;
}

sub Unwind {
  my $self = shift;;
  my $block = $self->{block}; $self->{block} = $block->{prev};
  $self->{block}->popItem;
  $self->Text($block->{token});
  $self->{block}->pushItem(@{$block->{stack}});
  $self->Text($block->{terminator}) if $block->{terminator} && ref($block->{terminator}) ne 'Regexp';
  $self->{atBlockStart} = 0;
}

sub blockError {
  my $self = shift; my $message = shift;
  $self->Error($message);
  $self->Unwind;
}

sub isLineEnd {
  my $self = shift; my $block = shift;
  $block = $block->{prev}; my $i = $self->{i};
  while ($i < scalar(@{$self->{split}})) {
    return 0 unless $self->{split}[$i++] eq '';
    my $token = $self->{split}[$i++];
    last if $token =~ m/^\n+$/;
    next if $token =~ m/^   ?$/;
    return 0 unless $token =~ m/^ +<<$/ && $block->{align};
    $block = $block->{prev};
  }
  return 1;
}

sub nextChar {
  my $self = shift; my $default = shift; $default = '' unless defined $default;
  return substr(($self->{split}[$self->{i}] || $self->{split}[$self->{i}+1] || $default),0,1);
}

sub prevChar {
  my $self = shift; my $default = shift; $default = '' unless defined $default;
  my $i2 = $self->{i}-2; $i2 = 0 if $i2 < 0;
  my $i3 = $self->{i}-3; $i3 = 0 if $i3 < 0;
  return substr(($self->{split}[$i2] || $self->{split}[$i3] || $default),-1,1);
}

sub Parse {
  my $self = shift; my $block;
  $self->{split} = [@_]; $self->{i} = 0;
  $self->{block} = $self->{root} = PGML::Root->new($self);
  while ($self->{i} < scalar(@{$self->{split}})) {
    $block = $self->{block};
    $self->Text($self->{split}[($self->{i})++]);
    my $token = $self->{split}[($self->{i})++]; next unless defined $token && $token ne '';
    for ($token) {
      $block->{terminator} && /^$block->{terminator}\z/                    && do {$self->Terminate($token); last};
      /^\[[@\$]/  && ($block->{parseAll} || $block->{parseSubstitutions})  && do {$self->Begin($token); last};
      /^\[%/      && ($block->{parseAll} || $block->{parseComments})       && do {$self->Begin($token); last};
      /^\\./      && ($block->{parseAll} || $block->{parseSlashes})        && do {$self->Slash($token); last};
      /^\n\z/     && do {$self->Break($token); last};
      /^\n\n+\z/  && do {$self->Par($token); last};
      /^\*\*?$/   && (!$block->{parseAll} && $block->{parseSubstitutions}) && do {$self->Star($token); last};
      $block->{balance} && /^$block->{balance}/ && do {$self->Begin($token,substr($token,0,1)); last};
      $block->{balance} && /$block->{balance}$/ && do {$self->Begin($token,substr($token,-1,1)); last};
      $block->{parseAll} && do {$self->All($token); last};
      /^[\}\]]\z/ && do {$self->Unbalanced($token); last};
      $self->Text($token);
    }
  }
  $self->End("END_PGML");
  delete $self->{root}{parser};
}

sub All {
  my $self = shift; my $token = shift;
  return $self->Begin($token) if substr($token,0,1) eq "[" && $BlockDefs{$token};
  for ($token) {
    /^(?:\t|    )/ && do {return $self->Indent($token)};
    /\d+\. /       && do {return $self->Bullet($token,"numeric")};
    /[ivxl]+[.)] / && do {return $self->Bullet($token,"roman")};
    /[a-z][.)] /   && do {return $self->Bullet($token,"alpha")};
    /[IVXL]+[.)] / && do {return $self->Bullet($token,"Roman")};
    /[A-Z][.)] /   && do {return $self->Bullet($token,"Alpha")};
    /[-+o*] /      && do {return $self->Bullet($token,"bullet")};
    /\{/           && do {return $self->Brace($token)};
    /\[]/          && do {return $self->NOOP($token)};
    /\[\|/         && do {return $self->Verbatim($token)};
    /\[./          && do {return $self->Answer($token)};
    /_/            && do {return $self->Emphasis($token)};
    /\*/           && do {return $self->Star($token)};
    /[\"\']/       && do {return $self->Quote($token)};
    /^   ?$/       && do {return $self->ForceBreak($token)};
    /#/            && do {return $self->Heading($token)};
    /-|=/          && do {return $self->Rule($token)};
    /<</           && do {return $self->Center($token)};
    />>/           && do {return $self->Align($token)};
    /```/          && do {return $self->Code($token)};
    /:   /         && do {return $self->Preformatted($token)};
    $self->Text($token);
  }
}

sub Begin {
  my $self = shift; my $token = shift; my $id = shift || $token;
  my $options = shift || {};
  my $def = {%{$BlockDefs{$id}},%$options, token => $token};
  my $type = $def->{type}; delete $def->{type};
  my $block = PGML::Block->new($type,$def);
  $self->{block}->pushItem($block); $block->{prev} = $self->{block};
  $self->{block} = $block;
  $self->{atLineStart} = 0; $self->{atBlockStart} = 1;
}

sub End {
  my $self = shift; my $action = shift || "paragraph ends"; my $endAt = shift;
  my $block = $self->{block};
  $block->popItem if $block->topItem->{type} eq 'break' && $block->{type} ne 'align';
  while ($block->{type} ne 'root') {
    if (ref($block->{terminator}) eq 'Regexp' || $block->{cancelPar}) {
      $self->blockError("'%s' was not closed before $action");
    } else {
      $self->Terminate;
    }
    return if $endAt && $endAt == $block;
    $block = $self->{block};
  }
}

sub Terminate {
  my $self = shift; my $token = shift;
  my $block = $self->{block}; my $prev = $block->{prev};
  if (defined($token)) {
    $block->{terminator} = $token;
    my $method = $block->{terminateMethod};
    $self->$method($token) if defined $method;
  }
  foreach my $field ("prev","parseComments","parseSubstitutions","parseSlashes",
                     "parseAll","cancelUnbalanced","cancelNL","cancelPar","balance",
		     "terminateMethod","noIndent") {delete $block->{$field}}
  $self->{block} = $prev;
  if ($block->{stack}) {
    if (scalar(@{$block->{stack}}) == 0) {$prev->popItem}
    elsif ($block->{combine}) {$prev->combineTopItems}
  }
}

sub Unbalanced {
  my $self = shift; my $token = shift;
  $self->blockError("parenthesis mismatch: %s terminated by $token") if $self->{block}{cancelUnbalanced};
  $self->Text($token);
}

sub Text {
  my $self = shift; my $text = shift; my $force = shift;
  if ($text ne "" || $force) {
    $self->{block}->pushText($text,$force);
    $self->{atLineStart} = $self->{atBlockStart} = $self->{ignoreNL} = 0;
  }
}

sub Item {
  my $self = shift; my $type = shift; my $token = shift;
  my $def = {%{shift || {}}, token => $token};
  $self->{block}->pushItem(PGML::Item->new($type,$def));
  $self->{atBlockStart} = 0;
}


sub Break {
  my $self = shift; my $token = shift;
  if ($self->{ignoreNL}) {
    $self->{ignoreNL} = 0;
  } else {
    $self->blockError("%s was not closed before line break") while $self->{block}{cancelNL};
    my $top = $self->{block}->topItem;
    if ($top->{breakInside}) {$top->pushText($token)} else {$self->Text($token)}
    $self->{ignoreNL} = 1;
  }
  $self->{atLineStart} = 1;
  $self->{actualIndent} = 0;
}

sub ForceBreak {
  my $self = shift; my $token = shift;
  $self->blockError("%s was not closed before forced break") while $self->{block}{cancelNL};
  if ($token eq '   ') {
    $self->End("forced break");
    $self->Item("forced",$token,{noIndent => 1});
    $self->{indent} = 0;
  } else {
    my $top = $self->{block}->topItem;
    if ($top->{breakInside}) {$top->pushItem(PGML::Item->new("break",{token=>$token}))}
    else {$self->Item("break",$token,{noIndent => 1})}
  }
  $self->{atLineStart} = $self->{ignoreNL} = 1;
  $self->{actualIndent} = 0;
}

sub Par {
  my $self = shift; my $token = shift;
  if ($self->{block}{allowPar}) {
    $self->Text("\n\n");
  } else {
    $self->End(undef, shift);
    $self->Item("par",$token,{noIndent => 1});
    $self->{atLineStart} = $self->{ignoreNL} = 1;
    $self->{indent} = $self->{actualIndent} = 0;
  }
}

sub Indent {
  my $self = shift; my $token = shift;
  if ($self->{atLineStart}) {
    my $tabs = $token;
    $tabs =~ s/    /\t/g;  # turn spaces into tabs
    my $indent = $self->{actualIndent} = length($tabs);
    if ($indent != $self->{indent}) {
      $self->End("indentation change");
      $self->{indent} = $indent;
    }
  } else {
    $self->Text($token);
  }
}

sub Slash {
  my $self = shift; my $token = shift;
  $self->Text(substr($token,1));
}

sub Brace {
  my $self = shift; my $token = shift;
  my $top = $self->{block}->topItem;
  if ($top->{options}) {$self->Begin($token,' {')} else {$self->Text($token)}
}

sub Verbatim {
  my $self = shift; my $token = shift;
  my $bars = $token; $bars =~ s/[^|]//g;
  $bars = "\\".join("\\",split('',$bars));
  $self->Begin($token,' [|',{terminator => qr/ ?$bars\]/});
}

sub Answer {
  my $self = shift; my $token = shift;
  my $def = {options => ["answer","width","name","array"]};
  $def->{hasStar} = 1 if $token =~ m/\*$/;
  $self->Item("answer",$token,$def);
}

sub Emphasis {
  my $self = shift; my $token = shift;
  my $type = $BlockDefs{substr($token,0,1)}->{type};
  my $block = $self->{block};
  return $self->Terminate if $block->{type} eq $type;
  while ($block->{type} ne 'root') {
    if ($block->{prev}{type} eq $type) {
      $self->End("end of $type",$block);
      $self->Terminate();
      return;
    }
    $block = $block->{prev};
  }
  if ($self->nextChar(' ') !~ m/\s/ && $self->prevChar(' ') !~ m/[a-z0-9]/i)
    {$self->Begin($token,substr($token,0,1))} else {$self->Text($token)}
}

sub Star {
  my $self = shift; my $token = shift;
  return if $self->StarOption($token);
  if ($self->{block}{parseAll}) {$self->Emphasis($token)} else {$self->Text($token)}
}

sub Rule {
  my $self = shift; my $token = shift;
  if ($self->{atLineStart}) {
### check for line end or braces
    $self->Item("rule",$token,{options => ["width","size"]});
    $self->{ignoreNL} = 1;
  } else {
    $self->Text($token);
  }
}

sub Bullet {
  my $self = shift; my $token = shift; my $bullet = shift;
  return $self->Text($token) unless $self->{atLineStart};
  $bullet = {'*'=>'disc', '+'=>'square', 'o'=>'circle', '-'=>'bullet'}->{substr($token,0,1)} if $bullet eq 'bullet';
  my $block = $self->{block};
  if ($block->{type} ne 'root' && !$block->{align}) {
    while ($block->{type} ne 'root' && !$block->{prev}{align}) {$block = $block->{prev}}
    $self->End("start of list item",$block);
  }
  $self->{indent} = $self->{actualIndent};
  $self->Begin("","list",{bullet => $bullet});
  $self->Begin($token,"bullet");
}

sub Heading {
  my $self = shift; my $token = shift;
  my $n = length($token);
  return $self->Text($token) if $n > 6;
  my $block = $self->{block};
  if ($self->{atLineStart}) {
    if ($block->{type} ne 'root' && $block->{type} ne 'align') {
      while ($block->{type} ne 'root' && $block->{prev}{type} ne 'align') {$block = $block->{prev}}
      $self->End("start of heading",$block);
    }
    $self->Begin($token,"#",{n => $n});
  } else {
    while ($block->{type} ne 'heading' || $block->{n} != $n) {
      return $self->Text($token) if $block->{type} eq 'root';
      $block = $block->{prev};
    }
    if ($self->isLineEnd($block)) {
      $self->End("end of heading",$block);
      $block->{terminator} = $token;
      $self->{indent} = 0;
    } else {$self->Text($token)}
  }
}

sub Center {
  my $self = shift; my $token = shift;
  my $block = $self->{block};
  while (!$block->{align} || $block->{align} ne 'right') {
    return $self->Text($token) if $block->{type} eq 'root';
    $block = $block->{prev};
  }
  if ($self->isLineEnd($block)) {
    $block->{align} = 'center';
    $block->{terminator} = $token;
    $self->End("end of centering",$block);
  } else {$self->Text($token)}
}

sub Align {
  my $self = shift;  my $token = shift;
  return $self->Text($token) if !$self->{atLineStart} ||
    ($self->{block}{type} eq 'align' && $self->{atBlockStart});
  $self->End("start of aligned text");
  $self->{indent} = $self->{actualIndent};
  $self->Begin($token,">>");
  $self->{atLineStart} = $self->{ignoreNL} = 1;
}

sub Code {
  my $self = shift; my $token = shift;
  return $self->Text($token) if !$self->{atLineStart} ||
    ($self->{block}{type} eq 'code' && $self->{atBlockStart});
  $self->End("start of preformatted code");
  $self->{indent} = $self->{actualIndent};
  $self->Begin($token,"```");
}

sub Preformatted {
  my $self = shift; my $token = shift;
  return $self->Text($token) if !$self->{atLineStart} ||
    ($self->{block}{type} eq 'pre' && $self->{atBlockStart});
  $self->End("start of preformatted text");
  $self->{indent} = $self->{actualIndent};
  $self->Begin($token,':   ');
}

sub Quote {
  my $self = shift; my $token = shift;
  $self->Item("quote",$token);
}

sub NOOP {
  my $self = shift;
  $self->Text("",1);
}

######################################################################

my $balanceAll = qr/[\{\[\'\"]/;

%BlockDefs = (
  "[:"   => {type=>'math', parseComments=>1, parseSubstitutions=>1,
               terminator=>qr/:\]/, terminateMethod=>'terminateGetString',
	       parsed=>1, allowStar=>1, allowDblStar=>1, allowTriStar=>1, options=>["context","reduced"]},
  "[::"  => {type=>'math', parseComments=>1, parseSubstitutions=>1,
               terminator=>qr/::\]/, terminateMethod=>'terminateGetString',
	       parsed=>1, allowStar=>1, allowDblStar=>1, allowTriStar=>1, displaystyle=>1, options=>["context","reduced"]},
  "[:::"  => {type=>'math', parseComments=>1, parseSubstitutions=>1,
               terminator=>qr/:::\]/, terminateMethod=>'terminateGetString',
	       parsed=>1, allowStar=>1, allowDblStar=>1, allowTriStar=>1, display=>1, options=>["context","reduced"]},
  "[`"   => {type=>'math', parseComments=>1, parseSubstitutions=>1,
               terminator=>qr/\`\]/, terminateMethod=>'terminateGetString',},
  "[``"  => {type=>'math', parseComments=>1, parseSubstitutions=>1,
               terminator=>qr/\`\`\]/, terminateMethod=>'terminateGetString', displaystyle=>1},
  "[```"  => {type=>'math', parseComments=>1, parseSubstitutions=>1,
               terminator=>qr/\`\`\`\]/, terminateMethod=>'terminateGetString', display=>1},
  "[!"   => {type=>'image', parseComments=>1, parseSubstitutions=>1,
               terminator=>qr/!\]/, terminateMethod=>'terminateGetString',
               cancelNL=>1, options=>["title"]},
  "[<"   => {type=>'link', parseComments=>1, parseSubstitutions=>1,
               terminator=>qr/>\]/, terminateMethod=>'terminateGetString',
               cancelNL=>1, options=>["text","title"]},
  "[%"   => {type=>'comment', parseComments=>1, terminator=>qr/%\]/, allowPar=>1},
  "[\@"  => {type=>'command', parseComments=>1, parseSubstitutions=>1,
               terminator=>qr/@\]/, terminateMethod=>'terminateGetString',
               balance=>qr/[\'\"]/, allowStar=>1, allowDblStar=>1, allowTriStar=>1},
  "[\$"  => {type=>'variable', parseComments=>1, parseSubstitutions=>0,
               terminator=>qr/\$?\]/, terminateMethod=>'terminateGetString',
	       balance=>$balanceAll, cancelUnbalanced=>1, cancelNL=>1, allowStar=>1, allowDblStar=>1, allowTriStar=>1},
  ' [|'  => {type=>'verbatim', cancelNL=>1, allowStar=>1, terminateMethod=>'terminateGetString'},
  " {"   => {type=>'options', parseComments=>1, parseSubstitutions=>0, terminator=>qr/\}/,
	       balance=>$balanceAll, cancelUnbalanced=>1, terminateMethod => 'terminateOptions'},
  "{"    => {type=>'balance', parseComments=>1, parseSubstitutions=>1, terminator=>qr/\}/,
	       balance=>$balanceAll, cancelUnbalanced=>1},
  "["    => {type=>'balance', parseComments=>1, parseSubstitutions=>1, terminator=>qr/\]/,
	       balance=>$balanceAll, cancelUnbalanced=>1},
  "'"    => {type=>'balance', terminator=>qr/\'/, terminateMethod=>'terminateBalance'},
  '"'    => {type=>'balance', terminator=>qr/\"/, terminateMethod=>'terminateBalance'},
  "```"  => {type=>'code', terminator=>qr/```/, terminateMethod=>'terminateCode', allowPar=>1},
  ":   " => {type=>'pre', parseAll=>1, terminator=>qr/\n+/, terminateMethod=>'terminatePre',
               combine=>{pre=>"type"}, noIndent=>-1},
  ">>"   => {type=>'align', parseAll=>1, align=>"right", breakInside=>1,
	       combine=>{align=>"align",par=>1}, noIndent=>-1},
  "#"    => {type=>'heading', parseAll=>1, breakInside=>1, combine=>{heading=>"n"}},
  "*"    => {type=>'bold', parseAll=>1, cancelPar=>1},
  "_"    => {type=>'italic', parseAll=>1, cancelPar=>1},
  "bullet" => {type=>'bullet', parseAll=>1},
  "list" => {type=>'list', parseAll=>1, combine=>{list=>"bullet",par=>1}, noIndent=>-1},
);

######################################################################

sub terminateGetString {
  my $self = shift; my $token = shift;
  my $block = $self->{block};
  $block->{text} = $self->stackString;
  delete $block->{stack};
}

sub terminateBalance {
  my $self = shift; my $token = shift;
  my $block = $self->{block};
  if (!$block->{stack} || scalar(@{$block->{stack}}) == 0) {$self->Text("",1)}
  my $stackString = $self->stackString;
  $self->{block} = $block->{prev}; $self->{block}->popItem;
  if ($block->{token} eq '"' || $block->{token} eq "'") {
    $self->Item("quote",$block->{token});
    $self->Text($stackString);
    $self->Item("quote",$block->{terminator});
  } else {
    $self->Text($block->{token}.$stackString.$block->{terminator});
  }
}

sub terminateCode {
  my $self = shift; my $token = shift;
  my $top = $self->{block}->topItem;
  if ($top->{type} eq "text") {
    if (($top->{stack}[0]||"") =~ m/^ *[a-z0-9]+$/ && ($top->{stack}[1]||"") =~ m/^\n+$/) {
      $self->{block}{class} = $top->{stack}[0]; $self->{block}{class} =~ s/^ +//;
      shift(@{$top->{stack}});
    }
  }
}

sub terminatePre {
  my $self = shift; my $token = shift;
  $self->{block}{terminator} = ''; # we add the ending token to the text below
  if ($token =~ m/\n\n/) {
    $self->Par($token, $self->{block});
    $self->{block} = $self->{block}{prev};
  } else {
    $self->Text($token);
    $self->{atLineStart} = 1;
    $self->{actualIndent} = 0;
  }
}

sub terminateOptions {
  my $self = shift; my $token = shift;
  my $options = $self->stackString;
  $self->{block} = $self->{block}{prev}; $self->{block}->popItem;
  $block = $self->{block}->topItem;
  if ($options =~ m/^[a-z_][a-z0-9_]*=>/i) {
    my %allowed = (map {$_ => 1} (@{$block->{options}}));
    my ($options,$error) = PGML::Eval("{$options}");
    $options={},PGML::Warning "Error evaluating options: $error" if $error;
    foreach my $option (keys %{$options}) {
      if ($allowed{$option}) {$block->{$option} = $options->{$option}}
        else {PGML::Warning "Unknown $self->{type} option '$option'"}
    }
  } else {
    foreach my $option (@{$block->{options}}) {
      if (!defined($block->{$option})) {
	if (!ref($options)) {
	  my ($value,$error) = PGML::Eval($options);
	  $options = $value unless $error; ### should give warning? only evaluate some options?
	}
	$block->{$option} = $options;
	return;
      }
    }
    PGML::Warning "Error: extra option '$options'";
  }
}

sub StarOption {
  my $self = shift; my $token = shift;
  my $top = $self->{block}->topItem;
  if ($token eq '*' && $top->{allowStar}) {
    $top->{hasStar} = 1;
    return 1;
  }
  if ($token eq '***' && $top->{allowTriStar}) {
    $top->{hasStar} = 3;
    return 1;
  }
  if ($token eq '**' && $top->{allowDblStar}) {
    if ($top->{type} eq "math") {$top->{hasDblStar} = 1; return 1}
    $self->{block}->popItem;
    my $string;
    for ($top->{type}) {
      /variable/ && do {$string = $self->replaceVariable($top); last;};
      /command/  && do {$string = $self->replaceCommand($top); last;};
      PGML::Warning "Unexpected type '$top->{type}' in ".ref($self)."->StarOption";
    }
    my @split = $self->Split($string);
    push(@split,undef) if scalar(@split) % 2 == 1;
    splice(@{$self->{split}},$self->{i},0,@split);
    return 1;
  }
  return 0;
}

sub stackText {
  my $self = shift; my $stack = shift;
  my @strings = ();
  foreach my $item (@{$stack}) {
    for ($item->{type}) {
      /text/     && do {push(@strings,$self->replaceText($item)); last};
      /quote/    && do {push(@strings,$self->replaceQuote($item)); last};
      /variable/ && do {push(@strings,$self->replaceVariable($item)); last};
      /command/  && do {push(@strings,$self->replaceCommand($item)); last};
      /balance/  && do {push(@strings,$self->replaceBalance($item)); last};
      PGML::Warning "Warning: unexpected type '$item->{type}' in stackText\n";
    }
  }
  return join('',@strings);
}

sub stackString {
  my $self = shift; my $block = $self->{block};
  return $self->stackText($block->{stack});
}

sub replaceBalance {
  my $self = shift; my $item = shift;
  return $item->{token}.$self->stackText($item->{stack}).$item->{terminator};
}

sub replaceText {
  my $self = shift; my $item = shift;
  return join('',@{$item->{stack}});
}

sub replaceQuote {
  my $self = shift; my $item = shift;
  return $item->{token};
}

sub replaceVariable {
  my $self = shift; my $item = shift;
  my $block = $self->{block};
  my $var = "\$main::" . $item->{text};
  ### check $var for whether it looks like a variable reference
  my ($result,$error) = PGML::Eval($var);
  PGML::Warning "Error evaluating variable \$$item->{text}: $error" if $error;
  $result = "" unless defined $result;
  if ($block->{type} eq 'math' && Value::isValue($result)) {
    if ($block->{parsed}) {$result = $result->string} else {$result = '{'.$result->TeX.'}'}
  }
  return $result;
}

sub replaceCommand {
  my $self = shift; my $item = shift;
  my $cmd = $item->{text};
  my ($result,$error) = PGML::Eval($cmd);
  PGML::Warning "Error evaluating command: $error" if $error;
  $result = "" unless defined $result;
  return $result;
}

######################################################################
######################################################################

package PGML::Item;

sub new {
  my $self = shift; my $class = ref($self) || $self;
  my $type = shift; my $fields = shift || {};
  bless {type => $type, %$fields}, $class;
}

sub show {
  my $self = shift; my $indent = shift || "";
  my @strings = ();
  foreach my $id (PGML::Sort(keys %$self)) {
    next if $id eq "stack";
    if (ref($self->{$id}) eq 'ARRAY') {
      push(@strings,$indent.$id.": [".join(',',map {"'".$self->quote($_)."'"} @{$self->{$id}})."]");
    } else {
      push(@strings,$indent.$id.": '".$self->quote($self->{$id})."'");
    }
  }
  return join("\n",@strings);
}

sub quote {
  my $self = shift;
  my $string = shift;
  $string =~ s/\n/\\n/g;
  $string =~ s/\t/\\t/g;
  return $string;
}

######################################################################

package PGML::Block;
our @ISA = ('PGML::Item');

sub new {
  my $self = shift; my $type = shift; my $fields = shift || {};
  $self->SUPER::new($type, {
    %$fields,
    stack => [],
  });
}

sub pushText {
  my $self = shift; my $text = shift; my $force = shift;
  return if $text eq "" && !$force;
  my $top = $self->topItem;
  if ($top->{type} ne "text") {$self->pushItem(PGML::Text->new($text))}
                         else {$top->pushText($text)}
}

sub pushItem {
  my $self = shift;
  push(@{$self->{stack}},@_);
}

sub topItem {
  my $self = shift; my $i = shift || -1;
  return $self->{stack}[$i] || PGML::Block->new("null");
}

sub popItem {
  my $self = shift;
  pop(@{$self->{stack}});
}

sub combineTopItems {
  my $self = shift; my $i = shift; $i = -1 unless defined $i;
  my $top = $self->topItem($i); my $prev = $self->topItem($i-1); my $par;
  for (my $j = $i-1; $prev->{type} eq 'par' && $top->{combine}{par}; $j--) {$par = $prev; $prev = $self->topItem($j)}
  my $id = $top->{combine}{$prev->{type}}; my $value; my $inside = 0;
  if ($id) {
    if (ref($id) eq 'HASH') {($id,$value) = %$id; $inside = 1} else {$value = $prev->{$id}}
    my $topList = (Value::isa($top,'PGML::Block') ? substr(($top->topItem || {})->{token} || '',0,2) : '');
    my $prevList = (Value::isa($prev,'PGML::Block') ? substr(($prev->topItem || {})->{token} || '',0,2) : '');
    if (
        $top->{$id} eq $value ||
        ($top->{type} eq 'list' && $top->{bullet} eq 'roman' &&
         $prev->{type} eq 'list' && $prev->{bullet} eq 'alpha' &&
         (($topList eq 'i.' && $prevList eq 'h.') || ($topList eq 'v.' && $prevList eq 'u.') ||
          ($topList eq 'x.' && $prevList eq 'w.') || ($topList eq 'l.' && $prevList eq 'k.'))) ||
        ($top->{type} eq 'list' && $top->{bullet} eq 'Roman' &&
         $prev->{type} eq 'list' && $prev->{bullet} eq 'Alpha' &&
         (($topList eq 'I.' && $prevList eq 'H.') || ($topList eq 'V.' && $prevList eq 'U.') ||
          ($topList eq 'X.' && $prevList eq 'W.') || ($topList eq 'L.' && $prevList eq 'K.')))
       ) {
      #
      #  Combine identical blocks
      #
      $prev = $prev->topItem if $inside;
      splice(@{$self->{stack}},$i,1);
      if ($par) {splice(@{$self->{stack}},$i,1); $prev->pushItem($par)}
      $i = -scalar(@{$top->{stack}});
      $prev->pushItem(@{$top->{stack}});
      $prev->combineTopItems($i) if $prev->{type} ne 'text' && $prev->topItem($i)->{combine};
      return;
    } elsif ($top->{type} eq 'indent' && $prev->{type} eq 'indent' &&
	     $top->{indent} > $prev->{indent} && $prev->{indent} > 0) {
      #
      #  Move larger indentations into smaller ones
      #
      splice(@{$self->{stack}},$i,1);
      if ($par) {splice(@{$self->{stack}},$i,1); $prev->pushItem($par)}
      $top->{indent} -= $prev->{indent};
      $prev->pushItem($top);
      $prev->combineTopItems;
      return;
    } elsif ($id eq 'indent' && $top->{type} eq 'indent' && $prev->{type} eq 'list') {
      $prev = $prev->topItem;
      if ($top->{indent} > $value && $value > 0) {
        splice(@{$self->{stack}},$i,1);
        if ($par) {splice(@{$self->{stack}},$i,1); $prev->pushItem($par)}
        $top->{indent} -= $value;
        $prev->pushItem($top);
        $prev->combineTopItems;
      }
    }
  }
return;
  #
  #  Remove unneeded zero indents
  #
  if ($top->{type} eq 'indent' && $top->{indent} == 0) {
    splice(@{$self->{stack}},$i,1,@{$top->{stack}});
    $top = $self->topItem($i);
    $self->combineTopItems($i) if $top->{combine};
  }
}

sub show {
  my $self = shift; my $indent = shift || "";
  my @strings = ($self->SUPER::show($indent));
  if ($self->{stack}) {
    push(@strings,$indent."stack: [");
    foreach my $i (0..scalar(@{$self->{stack}})-1) {
      my $item = $self->{stack}[$i];
      if (ref($item)) {
	push(@strings,"$indent  [ # $i");
	push(@strings,$item->show($indent."    "));
	push(@strings,"$indent  ]");
      } else {
	push(@strings,"$indent  $i: '$item',");
      }
    }
    push(@strings,$indent."]");
  }
  return join("\n",@strings);
}

######################################################################

package PGML::Root;
our @ISA = ('PGML::Block');

sub new {
  my $self = shift; my $parser = shift;
  return $self->SUPER::new("root",{parseAll => 1, parser => $parser});
}

sub pushItem {
  my $self = shift; my $item;
  while ($item = shift) {
    my $parser = $self->{parser};
    if (!$item->{noIndent} || ($parser->{indent} && $item->{noIndent} < 0)) {
      $parser->{block} = PGML::Block->new("indent",{
	 prev => $self, indent => $parser->{indent}, parseAll => 1,
	 combine => {indent => "indent", list => {indent => 1}, par => 1}
      });
      $parser->{block}->pushItem($item,@_); @_ = ();
      $item = $parser->{block};
    }
    push(@{$self->{stack}},$item);
  }
}


######################################################################
######################################################################

package PGML::Text;
our @ISA = ('PGML::Item');

sub new {
  my $self = shift;
  $self->SUPER::new("text",{stack=>[@_], combine => {text => "type"}});
}

sub pushText {
  my $self = shift;
  foreach my $text (@_) {
    if ($text ne "") {
      push(@{$self->{stack}},$text);
    }
  }
}

sub pushItem {
  my $self = shift;
  $self->pushText(@_);
}

sub show {
  my $self = shift; my $indent = shift;
  my @strings = ($self->SUPER::show($indent));
  push(@strings,$indent."stack: ['".join("','",map {$self->quote($_)} @{$self->{stack}})."']");
  return join("\n",@strings);
}

######################################################################
######################################################################

package PGML::Format;

sub new {
  my $self = shift; my $class = ref($self) || $self;
  my $parser = shift;
  bless {parser => $parser}, $class;
}

sub format {
  my $self = shift;
  return $self->string($self->{parser}{root});
}

sub string {
  my $self = shift; my $block = shift;
  my @strings = (); my $string;
  foreach my $item (@{$block->{stack}}) {
    $self->{item} = $item;
    $self->{nl} = (!defined($strings[-1]) || $strings[-1] =~ m/\n$/ ? "" : "\n");
# warn "type: $item->{type}";
    for ($item->{type}) {
      /indent/   && do {$string = $self->Indent($item); last};
      /align/    && do {$string = $self->Align($item); last};
      /par/      && do {$string = $self->Par($item); last};
      /list/     && do {$string = $self->List($item); last};
      /bullet/   && do {$string = $self->Bullet($item); last};
      /text/     && do {$string = $self->Text($item); last};
      /variable/ && do {$string = $self->Variable($item,$block); last};
      /command/  && do {$string = $self->Command($item); last};
      /math/     && do {$string = $self->Math($item); last};
      /answer/   && do {$string = $self->Answer($item); last};
      /bold/     && do {$string = $self->Bold($item); last};
      /italic/   && do {$string = $self->Italic($item); last};
      /heading/  && do {$string = $self->Heading($item); last};
      /quote/    && do {$string = $self->Quote($item,$strings[-1] || ''); last};
      /rule/     && do {$string = $self->Rule($item); last};
      /code/     && do {$string = $self->Code($item); last};
      /pre/      && do {$string = $self->Pre($item); last};
      /verbatim/ && do {$string = $self->Verbatim($item); last};
      /break/    && do {$string = $self->Break($item); last};
      /forced/   && do {$string = $self->Forced($item); last};
      /comment/  && do {$string = $self->Comment($item); last};
      PGML::Warning "Warning: unknown block type '$item->{type}' in ".ref($self)."::format\n";
    }
    push(@strings,$string) unless $string eq '';
  }
  $self->{nl} = (!defined($strings[-1]) || $strings[-1] =~ m/\n$/ ? "" : "\n");
  return join('',@strings);
}

sub nl {
  my $self = shift;
  my $nl = $self->{nl}; $self->{nl} = "";
  return $nl;
}

sub Escape   {shift; shift}


sub Indent   {return ""}
sub Align    {return ""}
sub Par      {return ""}
sub List     {return ""}
sub Bullet   {return ""}
sub Bold     {return ""}
sub Italic   {return ""}
sub Heading  {return ""}
sub Quote    {return ""}
sub Rule     {return ""}
sub Code     {return ""}
sub Pre      {return ""}
sub Verbatim {return ""}
sub Break    {return ""}
sub Forced   {return ""}
sub Comment  {return ""}

sub Math {
  my $self = shift; my $item = shift; my $math = $item->{text};
  if ($item->{parsed}) {
    my $context = $main::context{Typeset};
    $context = $main::context{current} if $item->{hasStar};
    $item->{reduced} = 1 if $item->{hasDblStar} || ($item->{hasStar}||0) == 3;
    if ($item->{context}) {
      if (Value::isContext($item->{context})) {$context = $item->{context}}
      else {$context = Parser::Context->getCopy(undef,$item->{context})}
    }
    $context->clearError;
    my $obj = Parser::Formula($context,$math);
    if ($context->{error}{flag}) {
      PGML::Warning "Error parsing mathematics: $context->{error}{message}";
      return "\\text{math error}";
    }
    $obj = $obj->reduce if $item->{reduced};
    $math = $obj->TeX;
  }
  $math = "\\displaystyle{$math}" if $item->{displaystyle};
  my $mathmode = ($item->{display}) ? 'display' : 'inline' ;
  return ($math,$mathmode);
}

sub Answer {
  my $self = shift; my $item = shift;
  my $ans = $item->{answer}; my $rule;
  $item->{width} = length($item->{token})-2 if (!defined($item->{width}));
  if (defined($ans)) {
    if (ref($ans) =~ /CODE|AnswerEvaluator/) {
      if (defined($item->{name})) {
	$rule = main::NAMED_ANS_RULE($item->{name},$item->{width});
	main::NAMED_ANS($item->{name} => $ans);
      } else {
	$rule = main::ans_rule($item->{width});
	main::ANS($ans);
      }
    } else {
      unless (Value::isValue($ans)) {
        $ans = Parser::Formula($item->{answer});
        if (defined($ans)) {
	  my $context = $ans->context;
	  my $flags = Value::contextSet($context,reduceConstants=>0,reduceConstantFunctions=>0);
	  my $f = Parser::Formula($item->{answer});
	  Value::contextSet($context,%{$flags});
	  $ans = $ans->eval if $ans->isConstant;
	  $ans->{correct_ans} = $f->string;
          $ans->{correct_ans_latex_string} = $f->TeX;
	  $item->{answer} = $ans;
        } else {
	  PGML::Warning "Error parsing answer: ".Value->context->{error}{message};
	  $ans = main::String("");  ### use something else?
        }
      }
      my @options = ($item->{width});
      my $method = ($item->{hasStar} ? "ans_array" : "ans_rule");
      if ($item->{name}) {
        unshift(@options,$item->{name});
        $method = "named_".$method;
      }
      $rule = $ans->$method(@options);
      $rule = PGML::LaTeX($rule);
      if (!(ref($ans) eq 'parser::MultiAnswer' && $ans->{part} > 1)) {
        if (defined($item->{name})) {
          main::NAMED_ANS($item->{name} => $ans->cmp);
        } else {
          main::ANS($ans->cmp);
        }
      }
    }
  } else {
    if (defined($item->{name})) {
      $rule = main::NAMED_ANS_RULE($item->{name},$item->{width});
    } else {
      $rule = main::ans_rule($item->{width});
    }
  }
  return $rule;
}

sub Command {
  my $self = shift; my $item = shift;
  my $text = $self->{parser}->replaceCommand($item);
  $text = PGML::LaTeX($text) if ($item->{hasStar}||0) == 3;
  $text = $self->Escape($text) unless $item->{hasStar};
  return $text;
}

sub Variable {
  my $self = shift; my $item = shift; my $cur = shift;
  my $text = $self->{parser}->replaceVariable($item,$cur);
  $text = PGML::LaTeX($text) if ($item->{hasStar}||0) == 3;
  $text = $self->Escape($text) unless $item->{hasStar};
  return $text;
}

sub Text {
  my $self = shift; my $item = shift;
  my $text = $self->{parser}->replaceText($item);
  $text =~ s/^\n+// if substr($text,0,1) eq "\n" && $self->nl eq "";
  return $self->Escape($text);
}

######################################################################
######################################################################

package PGML::Format::html;
our @ISA = ('PGML::Format');

sub Escape {
  my $self = shift;
  my $string = shift; return "" unless defined $string;
  $string =~ s/&/\&amp;/g;
  $string =~ s/</&lt;/g;
  $string =~ s/>/&gt;/g;
  $string =~ s/"/&quot;/g;
  return $string;
}

sub Indent {
  my $self = shift; my $item = shift;
  return $self->string($item) if $item->{indent} == 0;
  my $em = 2.25 * $item->{indent};
  return
    $self->nl .
    '<div style="margin:0 0 0 '.$em.'em">'."\n" .
    $self->string($item) .
    $self->nl .
    "</div>\n";
}

sub Align {
  my $self = shift; my $item = shift;
  return
    $self->nl .
    '<div style="text-align:'.$item->{align}.'; margin:0">'."\n" .
    $self->string($item) .
    $self->nl .
    "</div>\n";
}

our %bullet = (
  bullet  => 'ul type="disc"',
  numeric => 'ol type="1"',
  alpha   => 'ol type="a"',
  Alpha   => 'ol type="A"',
  roman   => 'ol type="i"',
  Roman   => 'ol type="I"',
  disc    => 'ul type="disc"',
  circle  => 'ul type="circle"',
  square  => 'ul type="square"',
);
sub List {
  my $self = shift; my $item = shift;
  my $list = $bullet{$item->{bullet}};
  return
    $self->nl .
    '<'.$list.' style="margin:0; padding-left:2.25em">'."\n" .
    $self->string($item) .
    $self->nl .
    "</".substr($list,0,2).">\n";
}

sub Bullet {
  my $self = shift; my $item = shift;
  return $self->nl.'<li>'.$self->string($item)."</li>\n";
}

sub Code {
  my $self = shift; my $item = shift;
  my $class = ($item->{class} ? ' class="'.$item->{class}.'"' : "");
  return $self->nl .
    '<pre style="margin:0"><code'.$class.'>' .
    $self->string($item) .
    "</code></pre>\n";
}

sub Pre {
  my $self = shift; my $item = shift;
  return
    $self->nl .
    '<pre style="margin:0"><code>' .
    $self->string($item) .
    "</code></pre>\n";
}

sub Heading {
  my $self = shift; my $item = shift;
  my $n = $item->{n};
  my $text = $self->string($item);
  $text =~ s/^ +| +$//gm; $text =~ s! +(<br />)!$1!g;
  return '<h'.$n.' style="margin:0">'.$text."</h$n>\n";
}

sub Par {
  my $self = shift; my $item = shift;
  return $self->nl.'<div style="margin-top:1em"></div>'."\n";
}

sub Break {"<br />\n"}

sub Bold {
  my $self = shift; my $item = shift;
  return '<b>'.$self->string($item).'</b>';
}

sub Italic {
  my $self = shift; my $item = shift;
  return '<i>'.$self->string($item).'</i>';
}

our %openQuote = ('"' => "&#x201C;", "'" => "&#x2018;");
our %closeQuote = ('"' => "&#x201D;", "'" => "&#x2019;");
sub Quote {
  my $self = shift; my $item = shift; my $string = shift;
  return $openQuote{$item->{token}} if $string eq "" || $string =~ m/(^|[ ({\[\s])$/;
  return $closeQuote{$item->{token}};
}

sub Rule {
  my $self = shift; my $item = shift;
  my $width = " width:100%; "; my $size = "";
  $width = ' width:'.$item->{width}.'; ' if defined $item->{width};
  $size = ' size="'.$item->{size}.'"' if defined $item->{size};
  my $html = '<hr'.$size.' style="margin:.3em auto" />';
  $html = '<div>'.
          '<span style="'.$width.'display:-moz-inline-box; display:inline-block; margin:.3em auto">'.
             $html.
          '</span>'.
          '</div>'; # if $width ne '' && $item->{width} !~ m/%/;
  return $self->nl.$html."\n";
}

sub Verbatim {
  my $self = shift; my $item = shift;
  my $text = $self->Escape($item->{text});
  $text = "<code>$text</code>" if $item->{hasStar};
  return $text;
}

sub Math {
  my $self = shift;
  return main::general_math_ev3($self->SUPER::Math(@_));
}

######################################################################
######################################################################

package PGML::Format::tex;
our @ISA = ('PGML::Format');

my %escape = (
  '"'  => '{\ttfamily\char34}',
  "\#" => '{\ttfamily\char35}',
  '$'  => '\$',
  '%'  => '\%',
  '&'  => '\&',
  '<'  => '{\ttfamily\char60}',
  '>'  => '{\ttfamily\char62}',
  '\\' => '{\ttfamily\char92}',
  '^'  => '{\ttfamily\char94}',
  '_'  => '\_',
  '{'  => '{\ttfamily\char123}',
  '|'  => '{\ttfamily\char124}',
  '}'  => '{\ttfamily\char125}',
  '~'  => '{\ttfamily\char126}',
);

sub Escape {
  my $self = shift;
  my $string = shift; return "" unless defined($string);
  $string =~ s/(["\#\$%&<>\\^_\{|\}~])/$escape{$1}/eg;
  return $string;
}

sub Indent {
  my $self = shift; my $item = shift;
  return $self->string($item) if $item->{indent} == 0;
  my $em = 2.25 * $item->{indent};
  return
    $self->nl .
    "{\\pgmlIndent\n" .
    $self->string($item) .
    $self->nl .
    "\\par}%\n";
}

sub Align {
  my $self = shift; my $item = shift;
  my $align = uc(substr($item->{align},0,1)).substr($item->{align},1);
  return
    $self->nl .
    "{\\pgml${align}{}" .
    $self->string($item) .
    $self->nl .
    "\\par}%\n";
}

sub List {
  my $self = shift; my $item = shift;
  return
    $self->nl .
    "{\\pgmlIndent\\let\\pgmlItem=\\pgml$item->{bullet}Item\n".
    $self->string($item) .
    $self->nl .
    "\\par}%\n";
}

sub Bullet {
  my $self = shift; my $item = shift;
  return $self->nl."\\pgmlItem{}".$self->string($item)."\n";
}

sub Code {
  my $self = shift; my $item = shift;
  return
    $self->nl .
    "{\\pgmlPreformatted\\ttfamily%\n" .
    $self->string($item) .
    "\\par}%\n";
}

sub Pre {
  my $self = shift; my $item = shift;
  return
    $self->nl .
    "{\\pgmlPreformatted%\n" .
    $self->string($item) .
    "\\par}%\n";
}

sub Heading {
  my $self = shift; my $item = shift;
  my $n = $item->{n};
  my $text = $self->string($item);
  $text =~ s/^ +| +$//gm; $text =~ s/ +(\\pgmlBreak)/$1/g;
  return "{\\pgmlHeading{$n}$text\\par}%\n";
}

sub Par {
  my $self = shift; my $item = shift;
  return $self->nl."\\vskip\\baselineskip\n";
}

sub Break {"\\pgmlBreak\n"}

sub Bold {
  my $self = shift; my $item = shift;
  return "{\\bfseries{}".$self->string($item)."}";
}

sub Italic {
  my $self = shift; my $item = shift;
  return "{\\itshape{}".$self->string($item)."}";
}

our %openQuote = ('"' => "``", "'" => "`");
our %closeQuote = ('"' => "''", "'" => "'");
sub Quote {
  my $self = shift; my $item = shift; my $string = shift;
  return $openQuote{$item->{token}} if $string eq "" || $string =~ m/(^|[ ({\[\s])$/;
  return $closeQuote{$item->{token}};
}

sub Rule {
  my $self = shift; my $item = shift;
  my $width = "100%"; my $size = "1";
  $width = $item->{width} if defined $item->{width};
  $size = $item->{size} if defined $item->{size};
  $width =~ s/%/\\pgmlPercent/; $size =~ s/%/\\pgmlPercent/;
  $width .= "\\pgmlPixels" if $width =~ m/^\d+$/;
  $size .= "\\pgmlPixels" if $size =~ m/^\d+$/;
  return $self->nl."\\pgmlRule{$width}{$size}%\n";
}

sub Verbatim {
  my $self = shift; my $item = shift;
  my $text = $self->Escape($item->{text});
  $text = "{\\tt{}$text}" if $item->{hasStar};
  return $text;
}


sub Math {
  my $self = shift;
  return main::general_math_ev3($self->SUPER::Math(@_));
}

######################################################################
######################################################################

package PGML::Format::ptx;
our @ISA = ('PGML::Format');

sub Escape {
  my $self = shift;
  my $string = shift; return "" unless defined $string;
  $string =~ s/&/&amp;/g;
  $string =~ s/</&lt;/g;
  $string =~ s/>/&gt;/g;
  return $string;
}

# No indentation for PTX
sub Indent {
  my $self = shift; my $item = shift;
  return $self->string($item);
}

# No align for PTX
sub Align {
  my $self = shift; my $item = shift;
  return "<!-- PTX:WARNING: PGML wanted to " . $item->{align} . " align here. -->\n" . $self->string($item);
}

our %bullet = (
  bullet  => 'ul',
  numeric => 'ol label="1."',
  alpha   => 'ol label="a."',
  Alpha   => 'ol label="A."',
  roman   => 'ol label="i."',
  Roman   => 'ol label="I."',
  disc    => 'ul label="disc"',
  circle  => 'ul label="circle"',
  square  => 'ul label="square"',
);
sub List {
  my $self = shift; my $item = shift;
  my $list = $bullet{$item->{bullet}};
  return
    $self->nl .
    '<'.$list.'>'."\n" .
    $self->string($item) .
    $self->nl .
    "</".substr($list,0,2).">\n";
}

sub Bullet {
  my $self = shift; my $item = shift;
  return $self->nl.'<li>'.$self->string($item).'</li>';
}

sub Code {
  my $self = shift; my $item = shift;
  my $code = ($self->string($item) =~ /\n/)
    ?
      $self->nl .
      "<pre>\n<cline>" .
      join("<\/cline>\n<cline>", split(/\n/,$self->string($item))) .
      "<\/cline>\n<\/pre>\n"
    :
      $self->nl .
      "<pre>" . $self->string($item) . "<\/pre>\n";
  ## Restore escaped characters
  $code =~ s/<ampersand\/>/&amp;/g;
  $code =~ s/<less\/>/&lt;/g;
  $code =~ s/<greater\/>/>/g;
  return $code;
}

sub Pre {
  my $self = shift; my $item = shift;
  ## PGML pre can have stylized contents like bold,
  ## and PTX pre cannot have element children
  return "<!-- PTX:WARNING: PGML wanted to make preformatted text here. -->\n";
}

# PreTeXt can't use headings.
sub Heading {
  my $self = shift; my $item = shift;
  return "<!-- PTX:WARNING: PGML wanted to make this a level " . $item->{n} . " header. -->\n" . $self->string($item);
}

sub Par {
  my $self = shift; my $item = shift;
  return $self->nl."\n";
}

sub Break {"\n\n"}

sub Bold {
  my $self = shift; my $item = shift;
  return '<alert>'.$self->string($item).'</alert>';
}

sub Italic {
  my $self = shift; my $item = shift;
  return '<em>'.$self->string($item).'</em>';
}

our %openQuote = ('"' => "<lq/>", "'" => "<lsq/>");
our %closeQuote = ('"' => "<rq/>", "'" => "<rsq/>");
sub Quote {
  my $self = shift; my $item = shift; my $string = shift;
  return $openQuote{$item->{token}} if $string eq "" || $string =~ m/(^|[ ({\[\s])$/;
  return $closeQuote{$item->{token}};
}

# No rule for PTX
sub Rule {
  my $self = shift; my $item = shift;
  return "<!-- PTX:WARNING: PGML wanted to place a horizontal rule here. -->\n";
}

sub Verbatim {
  my $self = shift; my $item = shift;
  my $text = $item->{text};
  if ($item->{hasStar}) {
    #Don't escape most content. Just < and &
    $text =~ s/&/&amp;/g;
    $text =~ s/</&lt;/g;
    $text = "<c>$text</c>";
  }
  else {
    $text =~ s/</<less\/>/g;
    $text =~ s/(?<!<less\\)>/<greater\/>/g;
    $text =~ s/&/<ampersand\/>/g;
  }
  return $text;
}

sub Math {
  my $self = shift;
  return main::general_math_ev3($self->SUPER::Math(@_));
}


######################################################################
######################################################################

package PGML;

sub Format {
  ClearWarnings;
  my $parser = PGML::Parse->new(shift);
  my $format;
  if ($main::displayMode eq 'TeX') {
    $format = "\n{\\pgmlSetup\n" . PGML::Format::tex->new($parser)->format . "\\par}%\n";
  } elsif ($main::displayMode eq 'PTX') {
    $format = PGML::Format::ptx->new($parser)->format."\n";
    $format = main::PTX_cleanup($format);
  } else {
    $format = '<div class="PGML">'."\n".PGML::Format::html->new($parser)->format.'</div>'."\n";
  }
  main::WARN_MESSAGE("==================","Errors parsing PGML:",@warnings,"==================") if scalar(@warnings);
  return $format;
}

sub Format2 {
  my $string = shift;
  $string =~ s/\\\\/\\/g;
  PGML::Format($string);
}

sub LaTeX {
  my $text = shift;
  $text =~ s/\\/\\\\/g;
  main::EV3P({
    processCommands => 0,
    processVariables => 0,
    processParser => 0,
    processMath => 1,
    fixDollars => 0,
  },$text);
}

######################################################################

package main;

sub _PGML_init {
  PG_restricted_eval('sub PGML {PGML::Format2(@_)}');
  loadMacros("MathObjects.pl");
  my $context = Context(); # prevent Typeset context from becoming active
  loadMacros("contextTypeset.pl");
  Context($context);
}

######################################################################

1;
