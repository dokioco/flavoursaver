require 'rltk'

module FlavourSaver
  class Lexer < RLTK::Lexer
    match_first

    # DEFAULT

    rule /{{{\s*/, :default do
      push_state :expression
      :TEXPRST
    end

    rule /{{!/, :default do
      push_state :comment
    end

    rule /{{#/, :default do
      push_state :expression
      :EXPRSTHASH
    end

    rule /{{\^/, :default do
      push_state :expression
      :EXPRSTHAT
    end

    rule /{{\//, :default do
      push_state :expression
      :EXPRSTFWSL
    end

    rule /{{&\s*/, :default do
      push_state :expression
      :EXPRSTAMP
    end

    rule /{{\s*>/, :default do # the original FlavourSaver allows a space between {{ and > so this regex does too
      push_state :expression
      :EXPRSTGT
    end

    rule /{{\s*/, :default do
      push_state :expression
      :EXPRST
    end

    rule /([^{]|{(?!{))+/m, :default do |output|
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

    rule /\.\./, :expression do
      :DOTDOT
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

    rule /"/, :expression do
      push_state :string
    end

    rule /'/, :expression do
      push_state :s_string
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

    rule /else/, :expression do
      :ELSE
    end

    rule /[A-Za-z_\-][A-Za-z0-9_\-]*/, :expression do |name|
      # Handlebars allows methods with hyphens in them. Ruby doesn't, so
      # we'll assume you're trying to index the context with the identifier
      # and call the result.

      if name.include?('-')
        [ :LITERAL, name ]
      else
        [ :IDENT, name ]
      end
    end

    rule /([1-9][0-9]*(\.[0-9]+)?)/, :expression do |n|
      [ :NUMBER, n ]
    end

    # COMMENT

    rule /}}/, :comment do
      pop_state
    end

    rule /([^}]|}(?!}))+/m, :comment do |comment|
      [ :COMMENT, comment ]
    end

    # STRING

    rule /"/, :string do
      pop_state
    end

    rule /(\\"|[^"])*/, :string do |str|
      [ :STRING, str ]
    end

    # SINGLE-QUOTED STRING

    rule /'/, :s_string do
      pop_state
    end

    rule /(\\'|[^'])*/, :s_string do |str|
      [ :S_STRING, str ]
    end

    # SEGMENT LITERAL

    rule /]/, :segment_literal do
      pop_state
    end

    rule /([^\]]+)/, :segment_literal do |l|
      [ :LITERAL, l ]
    end
  end
end
