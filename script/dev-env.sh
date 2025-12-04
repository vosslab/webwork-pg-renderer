#!/usr/bin/env bash
# Source this to set up a sane local Perl environment for this repo.

export PERL5LIB="lib:lib/WeBWorK:lib/WeBWorK/lib:lib/PG:lib/PG/lib:local/lib/perl5:${PERL5LIB:-}"
export PERL_CPANM_HOME="${PERL_CPANM_HOME:-"$(pwd)/.cpanm"}"
export PERL_CPANM_OPT=${PERL_CPANM_OPT:--L local}
export PERL_CPANM_WORK=${PERL_CPANM_WORK:-$PERL_CPANM_HOME/work}
mkdir -p "$PERL_CPANM_HOME/work"

echo "Perl env set:"
echo "  PERL5LIB=$PERL5LIB"
echo "  PERL_CPANM_HOME=$PERL_CPANM_HOME"
echo "  PERL_CPANM_WORK=$PERL_CPANM_WORK"
