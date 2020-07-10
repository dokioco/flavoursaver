require 'rltk'

module FlavourSaver
  class Lexer < RLTK::Lexer
    rule /{{{/, :default do
      push_state :expression
      :TEXPRST
    end

    rule /{{/, :default do
      push_state :expression
      :EXPRST
    end

    rule /#/, :expression do
      :HASH
    end

    rule /\//, :expression do
      :FWSL
    end

    rule /&/, :expression do
      :AMP
    end

    rule /\^/, :expression do
      :HAT
    end

    rule /@/, :expression do
      :AT
    end

    rule />/, :expression do
      :GT
    end

    rule /([1-9][0-9]*(\.[0-9]+)?)/, :expression do |n|
      [ :NUMBER, n ]
    end

    rule /true/, :expression do |i|
      [ :BOOL, true ]
    end

    rule /false/, :expression do |i|
      [ :BOOL, false ]
    end

    rule /\!/, :expression do
      push_state :comment
      :BANG
    end

    rule /([^}}]*)/, :comment do |comment|
      pop_state
      [ :COMMENT, comment ]
    end

    rule /else/, :expression do
      :ELSE
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

    rule /(\\"|[^"])*/, :string do |str|
      [ :STRING, str ]
    end

    rule /"/, :string do
      pop_state
    end

    rule /'/, :expression do
      push_state :s_string
    end

    rule /(\\'|[^'])*/, :s_string do |str|
      [ :S_STRING, str ]
    end

    rule /'/, :s_string do
      pop_state
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

    rule /\[/, :expression do
      push_state :segment_literal
    end

    rule /([^\]]+)/, :segment_literal do |l|
      [ :LITERAL, l ]
    end

    rule /]/, :segment_literal do
      pop_state
    end

    rule /\s+/, :expression do
      :WHITE
    end

    rule /}}}/, :expression do
      pop_state
      :TEXPRE
    end

    rule /}}/, :expression do
      pop_state
      :EXPRE
    end

    rule /[^{]+|{/m, :default do |output|
      [ :OUT, output ]
    end
  end
end
