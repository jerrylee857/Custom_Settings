# -*- mode: zsh; sh-indentation: 2; indent-tabs-mode: nil; sh-basic-offset: 2; -*-
# vim: ft=zsh sw=2 ts=2 et
#
# -------------------------------------------------------------------------------------------------
# Copyright (c) 2018 Sebastian Gniazdowski
# Copyright (C) 2019 by Philippe Troin (F-i-f on GitHub)
# All rights reserved.
#
# The only licensing for this file follows.
#
# Redistribution and use in source and binary forms, with or without modification, are permitted
# provided that the following conditions are met:
#
#  * Redistributions of source code must retain the above copyright notice, this list of conditions
#    and the following disclaimer.
#  * Redistributions in binary form must reproduce the above copyright notice, this list of
#    conditions and the following disclaimer in the documentation and/or other materials provided
#    with the distribution.
#  * Neither the name of the zsh-syntax-highlighting contributors nor the names of its contributors
#    may be used to endorse or promote products derived from this software without specific prior
#    written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
# FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
# IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT
# OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# -------------------------------------------------------------------------------------------------

builtin setopt extended_glob warn_create_global typeset_silent no_short_loops rc_quotes no_auto_pushd

# Keep chroma-takever state meaning: until ;, handle highlighting via chroma.
# So the below 8192 assignment takes care that next token will be routed to chroma.
(( next_word = 2 | 8192 ))

local __first_call="$1" __wrd="$2" __start_pos="$3" __end_pos="$4"
local __style option_start=0 option_end=0 number_start=0 number_end=0
local -a match mbegin mend

(( __first_call )) && {
    # Called for the first time - new command.
    # FAST_HIGHLIGHT is used because it survives between calls, and
    # allows to use a single global hash only, instead of multiple
    # global string variables.
    FAST_HIGHLIGHT[nice-arg-count]=0
    FAST_HIGHLIGHT[nice-increment-argument]=0

    # Set style for region_highlight entry. It is used below in
    # '[[ -n "$__style" ]] ...' line, which adds highlight entry,
    # like "10 12 fg=green", through `reply' array.
    #
    # Could check if command `example' exists and set `unknown-token'
    # style instead of `command'
    __style=${FAST_THEME_NAME}precommand

} || {
    # Following call, i.e. not the first one

    # Check if chroma should end – test if token is of type
    # "starts new command", if so pass-through – chroma ends
    [[ "$__arg_type" = 3 ]] && return 2

    if (( in_redirection > 0 || this_word & 128 )) || [[ $__wrd == "<<<" ]]; then
        return 1
    fi

    if (( FAST_HIGHLIGHT[nice-increment-argument] )); then
        (( FAST_HIGHLIGHT[nice-increment-argument] = 0 ))
        [[ $__wrd = (-|+|)[0-9]## ]] \
            && __style=${FAST_THEME_NAME}mathnum \
            || __style=${FAST_THEME_NAME}incorrect-subtle
    else
        case $__wrd in
            -(-|+|)[0-9]##)
               (( option_start = __start_pos-${#PREBUFFER} ,
                  option_end   = option_start+1 ,
                  number_start = option_end ,
                  number_end   = __end_pos-${#PREBUFFER} ))
               option_style=${FAST_THEME_NAME}single-hyphen-option
               ;;
            (#b)(--adjustment)(=(-|+|)[0-9]#|))
                (( option_start = __start_pos-${#PREBUFFER} ,
                   option_end   = option_start+mend[1] ))
                option_style=${FAST_THEME_NAME}double-hyphen-option
                [[ -z $match[2] ]] \
                    && (( FAST_HIGHLIGHT[nice-increment-argument] = 1 )) \
                    || (( option_end  += 1 ,
                          number_start = option_start+mbegin[2]-mbegin[1]+1 ,
                          number_end   = __end_pos-${#PREBUFFER} ))
                ;;
            -n)
                 __style=${FAST_THEME_NAME}double-hyphen-option
                 FAST_HIGHLIGHT[nice-increment-argument]=1
                 ;;
            --*)
                __style=${FAST_THEME_NAME}double-hyphen-option
                ;;
            -*)
                __style=${FAST_THEME_NAME}single-hyphen-option
                ;;
            *)
                this_word=1
                next_word=2
                return 1
                ;;
        esac

        (( option_start > 0 && option_end )) \
            && reply+=("$option_start $option_end ${FAST_HIGHLIGHT_STYLES[$option_style]}")
        ((  number_start > 0 && number_end  )) \
            && reply+=("$number_start $number_end ${FAST_HIGHLIGHT_STYLES[${FAST_THEME_NAME}mathnum]}")
    fi
}

# Add region_highlight entry (via `reply' array).
# If 1 will be added to __start_pos, this will highlight "oken".
# If 1 will be subtracted from __end_pos, this will highlight "toke".
# $PREBUFFER is for specific situations when users does command \<ENTER>
# i.e. when multi-line command using backslash is entered.
#
# This is a common place of adding such entry, but any above code can do
# it itself (and it does in other chromas) and skip setting __style to
# this way disable this code.
[[ -n "$__style" ]] && (( __start=__start_pos-${#PREBUFFER}, __end=__end_pos-${#PREBUFFER}, __start >= 0 )) && reply+=("$__start $__end ${FAST_HIGHLIGHT_STYLES[$__style]}")

# We aren't passing-through, do obligatory things ourselves.
# _start_pos=$_end_pos advances pointers in command line buffer.
#
# To pass through means to `return 1'. The highlighting of
# this single token is then done by fast-syntax-highlighting's
# main code and chroma doesn't have to do anything.
(( this_word = next_word ))
_start_pos=$_end_pos

return 0
