require 'rltk'

module FlavourSaver
  class Lexer < RLTK::Lexer
    match_first

    # DEFAULT

    rule /\\{{/, :default do |output|
      [ :OUT, "{{" ]
    end

    rule /{{\s*(else|\^)\s*}}/, :default do
      :EXPRELSE
    end

    rule /{{{{#\s*raw\s*}}}}/, :default do
      push_state :raw
      :RAWST
    end

    rule /{{{\s*/, :default do
      push_state :expression
      :TEXPRST
    end

    rule /{{!/, :default do
      push_state :comment
    end

    rule /{{#\s*/, :default do
      push_state :expression
      :EXPRSTHASH
    end

    rule /{{\^\s*/, :default do
      push_state :expression
      :EXPRSTHAT
    end

    rule /{{\/\s*/, :default do
      push_state :expression
      :EXPRSTFWSL
    end

    rule /{{&\s*/, :default do
      push_state :expression
      :EXPRSTAMP
    end

    rule /{{\s*>\s*/, :default do # the original FlavourSaver allows a space between {{ and > so this regex does too
      push_state :expression
      :EXPRSTGT
    end

    rule /{{\s*/, :default do
      push_state :expression
      :EXPRST
    end

    rule /([^{\\]|{(?!{)|\\(?!{{))+/m, :default do |output|
      [ :OUT, output ]
    end

    # EXPRESSION

    rule /\s*}}}/, :expression do
      pop_state
      :TEXPRE
    end

    rule /\s*}}/, :expression do
      pop_state
      :EXPRE
    end

    rule /\s+/, :expression do
      :WHITE
    end

    rule /\.\.\//, :expression do
      :DOTDOTSLASH
    end

    rule /\//, :expression do
      :FWSL
    end

    rule /@/, :expression do
      :AT
    end

    rule /\./, :expression do
      :DOT
    end

    rule /\=/, :expression do
      :EQ
    end

    rule /""/, :expression do # special rule because empty doesn't trigger token otherwise
      [ :STRING, '' ]
    end

    rule /"/, :expression do
      push_state :string
    end

    rule /''/, :expression do # special rule because empty doesn't trigger token otherwise
      [ :S_STRING, '' ]
    end

    rule /'/, :expression do
      push_state :s_string
    end

    rule /\[\]/, :expression do # special rule because empty doesn't trigger token otherwise
      [ :LITERAL, '' ]
    end

    rule /\[/, :expression do
      push_state :segment_literal
    end

    rule /true/, :expression do |i|
      [ :BOOL, true ]
    end

    rule /false/, :expression do |i|
      [ :BOOL, false ]
    end

    rule /(0|-?[1-9][0-9]*(?:\.[0-9]+)?)/, :expression do |n|
      [ :NUMBER, n ]
    end

    rule /[A-Za-z_\-][A-Za-z0-9_\-]*/, :expression do |name|
      # this is a divergence from FlavourSaver by Dokio -- even the dashed things are treated as methods
      [ :IDENT, name ]
    end

    # COMMENT

    rule /}}/, :comment do
      pop_state
    end

    rule /([^}]|}(?!}))+/m, :comment do |comment|
      [ :COMMENT, comment ]
    end

    # RAW BLOCK

    rule /{{{{\/\s*raw\s*}}}}/, :raw do
      pop_state
      :RAWE
    end

    rule /([^{]|{(?!{{{\/\s*raw\s*}}}}))+/m, :raw do |output|
      [ :OUT, output ]
    end

    # STRING

    rule /"/, :string do
      pop_state
    end

    rule /(\\"|[^"])+/, :string do |str|
      [ :STRING, str ]
    end

    # SINGLE-QUOTED STRING

    rule /'/, :s_string do
      pop_state
    end

    rule /(\\'|[^'])+/, :s_string do |str|
      [ :S_STRING, str ]
    end

    # SEGMENT LITERAL

    rule /]/, :segment_literal do
      pop_state
    end

    rule /[^\]]+/, :segment_literal do |l|
      [ :LITERAL, l ]
    end
  end
end
